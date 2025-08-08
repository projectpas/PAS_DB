/*******  
 ** File:   [USP_ValidateCommonUploadData_ByModuleId]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to add upload Data
 ** Date:  23-Dec-2024
            
  ** Change History             
 ********             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    23-Dec-2024		Devendra Shekh			Created
    2    06-Jan-2025		Devendra Shekh			Issue While Save Resolved
	3    04-02-2025         Shrey Chandegara        Modified due to ItemMaster AlternatePart
	4	 28-July-2025		Ayushi Patel			Check Duplicate Value Condition for ItemMasterModule too
	5	 01-Aug-2025		Ayushi Patel			Check Duplicate Value Condition for Customer too
	6	 05-Aug-2025		RAJESH GAMI				Fixed: Getting error when getting multiple values from [USP_GetDropdownValueId] 
	7    06-Aug-2025		Ayushi Patel			Added validation: Customer Phone must be at least 10 digits and digits only, Customer Email must be in valid format
declare @p4 dbo.UploadModuleDataTableType
insert into @p4 values(4,N'VICTOR ADMAS',1,N'{
  "partnumber": "AEIN122",
  "PartDescription": "Aein description",
  "IsOEM": "",
  "IsPma": "",
  "IsDER": "",
  "ItemClassificationId": "ROTABLE ",
  "ItemGroupId": "BRAKES ",
  "ManufacturerId": "ARMSTRONG ",
  "PurchaseUnitOfMeasureId": "KG",
  "PurchaseCurrencyId": "USD",
  "SalesCurrencyId": "USD",
  "SiteId": "MESA"
}')

exec USP_ValidateCommonUploadData_ByModuleId @ModuleId=4,@UserName=N'VICTOR ADMAS',@MasterCompanyId=1,@UploadData=@p4
********/
CREATE   PROCEDURE [dbo].[USP_ValidateCommonUploadData_ByModuleId]
	@ModuleId BIGINT = NULL,    
	@UserName VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL, 
	@UploadData [UploadModuleDataTableType] READONLY
AS    
BEGIN    
	SET NOCOUNT ON;    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	BEGIN TRY    
	
	BEGIN TRANSACTION

		DECLARE @GlImportModuleId BIGINT = 0, @TotalRecords BIGINT = 0, @CurrentRecord BIGINT = 0;
		DECLARE @UploadRecord VARCHAR(MAX) = NULL;
		DECLARE @Erorr AS VARCHAR(MAX);   
		DECLARE @TotalRow BIGINT, @CurrentRow BIGINT;
		DECLARE @IsChekColumnReference BIT = NULL;
		DECLARE @ReferenceColumn AS VARCHAR(150);
		DECLARE @ColumnReferenceId BIGINT = NULL;
		DECLARE @ChekDuplticateRef1 AS VARCHAR(150);
		DECLARE @ChekDuplticateRef2 AS VARCHAR(150);
		DECLARE @DuplicateRefeValue1 AS VARCHAR(150);
		DECLARE @DuplicateRefeValue2 AS VARCHAR(150);
		DECLARE @DuplicateErroMsg AS VARCHAR(150);
		DECLARE @ReferenceTable AS VARCHAR(150);
		DECLARE @IsDuplicate BIT = NULL;
		DECLARE @AlterModule AS BIGINT, @GLModule AS BIGINT, @ItemMasterModule AS BIGINT, @CustomerModule AS BIGINT;
    
		SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
		SET @GLModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'GLAccount');
		SET @ItemMasterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'itemMaster');
		SET @CustomerModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Customer');

		DECLARE @DropdownListTable VARCHAR(100) = NULL, 
		@DropdownListId VARCHAR(100) = NULL, 
		@DropdownListValue VARCHAR(100) = NULL, 
		@DropdownLFieldValue VARCHAR(MAX) = NULL;

		IF OBJECT_ID('tempdb..#ImportFields') IS NOT NULL
			DROP TABLE #ImportFields

		IF OBJECT_ID('tempdb..#DynamicKeyValue') IS NOT NULL
			DROP TABLE #DynamicKeyValue

		IF OBJECT_ID('tempdb..#uploadDataResults') IS NOT NULL
			DROP TABLE #uploadDataResults


		CREATE TABLE #DynamicKeyValue
		(
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[FieldName] VARCHAR(100) NULL, 
			[FieldValue] VARCHAR(max) NULL, 
			[RecordStatus] [varchar](max) NULL
		);

		CREATE TABLE #uploadDataResults
		(
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[ModuleId] BIGINT NULL, 
			[UserName] VARCHAR(100) NULL, 
			[MasterCompanyId] INT NULL,  
			[UploadRecord] VARCHAR(MAX) NULL,
			[OriginalRecordData] VARCHAR(MAX) NULL,
			[IsError] [bit] NULL,
			[Status] [varchar](MAX) NULL
		);
		
		DELETE FROM [dbo].[UploadModuleData] WHERE [ModuleId] = @ModuleId AND [MasterCompanyId] = @MasterCompanyId;
		
		SELECT @GlImportModuleId = [ImportModuleId] FROM [dbo].[ImportModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'GLACCOUNT';

		INSERT INTO #uploadDataResults([ModuleId], [UserName], [MasterCompanyId], [UploadRecord], [OriginalRecordData])
		SELECT [ModuleId], [UserName], [MasterCompanyId], [UploadRecord], [UploadRecord] FROM @UploadData;
		
		SELECT @TotalRecords = MAX([RecordId]), @CurrentRecord = MIN([RecordId]) FROM #uploadDataResults;

		SELECT @ReferenceTable = ReferenceTable FROM [dbo].[ImportModule] WITH(NOLOCK) WHERE [ImportModuleId] = @ModuleId;

		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecord, 0))
		BEGIN
			TRUNCATE TABLE #DynamicKeyValue;

			SET @Erorr = '';
			SET @ColumnReferenceId = '';

			SELECT @UploadRecord = [UploadRecord] FROM #uploadDataResults WHERE [RecordId] = @CurrentRecord;

			SELECT [key], [value] INTO #TempDynamicData FROM OPENJSON(@UploadRecord);
			--SELECT * FROM #TempDynamicData -----R
			INSERT INTO #DynamicKeyValue (FieldName, FieldValue) SELECT [key], [value] FROM #TempDynamicData;

			SELECT	IMF.ImportModuleFieldMasterId, IMF.ModuleId, IMF.FieldName, IMF.HeaderName, IMF.FieldType, IMF.IsRequired,
						IMF.DropdownListType, IMF.DropdownListTable, IMF.DropdownListId, IMF.DropdownListValue, IMF.DropdownListValueId,
						IMF.IsMultiValue, TMP.RecordId, TMP.FieldValue, TMP.RecordStatus,IMF.IsChekColumnReference,IMF.ReferenceColumn,IMF.ChekDuplticateRef1,IMF.ChekDuplticateRef2, @DuplicateErroMsg AS DuplicateErrorMsg
			INTO #ImportFields
			FROM [DBO].[ImportModuleFieldMaster] IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			--ORDER BY IMF.DisplaySortOrder ASC
			--SELECT * FROM #ImportFields ----R
			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;
			
			WHILE(@TotalRow >= @CurrentRow)
			BEGIN

				SELECT	@DropdownListTable = DropdownListTable, @DropdownListId = DropdownListId, @DropdownListValue = DropdownListValue, @DropdownLFieldValue = FieldValue, @IsChekColumnReference = IsChekColumnReference,@ReferenceColumn = ''
				FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;

				IF(ISNULL(@DropdownListTable, '') != '' AND ISNULL(@DropdownLFieldValue, '') != '')
				BEGIN
					DECLARE @DropdownListValueId VARCHAR(100) = NULL;
					SET @DropdownLFieldValue = UPPER(TRIM(@DropdownLFieldValue))
					
					EXEC [dbo].[USP_GetDropdownValueId] @DropdownListTable, @DropdownListId, @DropdownListValue, @DropdownLFieldValue, @MasterCompanyId,@ModuleId,@ColumnReferenceId,@ReferenceColumn,@IsChekColumnReference, @FieldValueId = @DropdownListValueId OUTPUT;
					IF(ISNULL(@DropdownListValueId, '') != '')
					BEGIN
						SET @DropdownListValueId = (SELECT LEFT(@DropdownListValueId, CHARINDEX(',', @DropdownListValueId + ',') - 1))
						UPDATE #ImportFields SET DropdownListValueId = CAST(@DropdownListValueId AS VARCHAR) WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
					--SET @ColumnReferenceId = CASE WHEN ISNULL(@DropdownListValueId, '') != '' THEN  CAST(@DropdownListValueId AS BIGINT) ELSE 0 END;
				END

				SET @CurrentRow += 1;
			END
	
			UPDATE TMP
			SET TMP.[RecordStatus] =	CASE	WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(TMP.FieldValue, '') = '' THEN IMF.HeaderName + ' is Required'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != ''  AND ISNULL(IMF.FieldValue, '') = '' THEN IMF.HeaderName + ' is Required'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != ''  AND ISNULL(IMF.DropdownListValueId, '') = '' THEN 'Pleas Enter Correct ' + IMF.HeaderName
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND IMF.FieldName = 'CustomerPhone' 
													AND (
														TMP.FieldValue LIKE '%[^0-9]%' OR LEN(TMP.FieldValue) < 10
													)
													THEN 'Phone must be at least 10 digits and contain digits only'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND IMF.FieldName = 'Email' 
													AND (
														TMP.FieldValue NOT LIKE '%@%._%' 
													)
													THEN 'Email is not in a valid format'
												WHEN ISNULL(IMF.DuplicateErrorMsg, '') != '' THEN IMF.DuplicateErrorMsg
										ELSE ''
										END,
				TMP.FieldValue = CASE WHEN ISNULL(IMF.DropdownListTable, '') != '' THEN IMF.DropdownListValueId ELSE TMP.FieldValue END
			FROM #ImportFields IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			--SELECT @Erorr = COALESCE(@Erorr + ',  ' + [RecordStatus], [RecordStatus]) FROM #DynamicKeyValue WHERE ISNULL([RecordStatus], '') != '';
			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;
			WHILE(@TotalRow >= @CurrentRow)
			BEGIN
				SELECT	@DropdownListTable = DropdownListTable, @DropdownListId = DropdownListId, @DropdownListValue = DropdownListValue, @DropdownLFieldValue = FieldValue,@IsChekColumnReference = IsChekColumnReference,@ReferenceColumn = ReferenceColumn
				FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;
				IF(ISNULL(@DropdownListTable, '') != '' AND ISNULL(@DropdownLFieldValue, '') != '' AND ISNULL(@ColumnReferenceId, '') != '' AND ISNULL(@IsChekColumnReference, 0) = 1)
				BEGIN
					DECLARE @RSDropdownListValueId VARCHAR(100) = NULL;
					SET @DropdownLFieldValue = UPPER(TRIM(@DropdownLFieldValue))
					EXEC [dbo].[USP_GetDropdownValueId] @DropdownListTable, @DropdownListId, @DropdownListValue, @DropdownLFieldValue, @MasterCompanyId,@ModuleId,@ColumnReferenceId,@ReferenceColumn,@IsChekColumnReference, @FieldValueId = @RSDropdownListValueId OUTPUT;
					IF(ISNULL(@RSDropdownListValueId, '') != '')
					BEGIN
					SET @RSDropdownListValueId = (SELECT LEFT(@RSDropdownListValueId, CHARINDEX(',', @RSDropdownListValueId + ',') - 1))
						UPDATE #ImportFields SET DropdownListValueId = CAST(@RSDropdownListValueId AS VARCHAR) WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
					ELSE
					BEGIN
						UPDATE #ImportFields SET DropdownListValueId = '' WHERE ImportModuleFieldMasterId = @CurrentRow;;
					END
					
					--SET @ColumnReferenceId = CASE WHEN ISNULL(@RSDropdownListValueId, '') != '' THEN  CAST(@RSDropdownListValueId AS BIGINT) ELSE 0 END;
				END
				SELECT @ColumnReferenceId =  DropdownListValueId FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;
				SET @CurrentRow += 1;
			END
			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;
			WHILE(@TotalRow >= @CurrentRow)
			BEGIN
				SELECT	@ChekDuplticateRef1 = ChekDuplticateRef1, @ChekDuplticateRef2 = ChekDuplticateRef2, @DropdownListTable = DropdownListTable				
				FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;

				IF((ISNULL(@ChekDuplticateRef1, '') != '' OR ISNULL(@ChekDuplticateRef2, '') != ''))
				BEGIN
					SELECT	@DuplicateRefeValue1 = CASE WHEN ISNULL(DropdownListTable, '') = '' THEN FieldValue ELSE DropdownListValueId END FROM #ImportFields WHERE FieldName = @ChekDuplticateRef1;
					SELECT	@DuplicateRefeValue2 = CASE WHEN ISNULL(DropdownListTable, '') = '' THEN FieldValue ELSE DropdownListValueId END FROM #ImportFields WHERE FieldName = @ChekDuplticateRef2;
					
					EXEC [dbo].[USP_ChekDuplicateValueForUpload] @ChekDuplticateRef1, @ChekDuplticateRef2, @DuplicateRefeValue1, @DuplicateRefeValue2, @ReferenceTable, @MasterCompanyId, @ModuleId, @UploadData, @UploadRecord, @IsDuplicate = @IsDuplicate OUTPUT;
					
					IF(ISNULL(@IsDuplicate, 0) = 1)
					BEGIN
						UPDATE #ImportFields 
						SET DuplicateErrorMsg = CASE	WHEN @ModuleId = @AlterModule THEN 'Entered PN and Alterate PN Already Exits!'
														WHEN @ModuleId = @GLModule THEN 'Entered Account Code Already Exits!'
														WHEN @ModuleId = @ItemMasterModule THEN 'Entered PN And Manufacturer Already Exits!'
														WHEN @ModuleId = @CustomerModule THEN 'Entered Name Already Exits!'
														ELSE '' END
						WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
					

				END
				
				SET @CurrentRow += 1;
			END
			
			UPDATE TMP
			SET TMP.[RecordStatus] =	CASE	WHEN ISNULL(TMP.[RecordStatus], '') != '' THEN TMP.[RecordStatus]
												WHEN ISNULL(IMF.DuplicateErrorMsg, '') != '' THEN IMF.DuplicateErrorMsg
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND IMF.FieldName = 'CustomerPhone' 
													AND (
														TMP.FieldValue LIKE '%[^0-9]%' OR LEN(TMP.FieldValue) < 10
													)
													THEN 'Phone must be at least 10 digits and contain digits only'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND IMF.FieldName = 'Email' 
													AND (
														TMP.FieldValue NOT LIKE '%@%._%' 
													)
													THEN 'Email is not in a valid format'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != '' 
													 AND ISNULL(IMF.DropdownListValueId, '') = '' AND ISNULL(IMF.ReferenceColumn, '') != '' THEN 'Pleas Enter Correct Pair of ' + IMF.HeaderName + ' ' + IMF.ReferenceColumn
										ELSE ''
										END,
				TMP.FieldValue = CASE WHEN ISNULL(IMF.DropdownListTable, '') != '' THEN IMF.DropdownListValueId ELSE TMP.FieldValue END
			FROM #ImportFields IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			SELECT @Erorr = COALESCE(@Erorr + ',  ' + [RecordStatus], [RecordStatus]) FROM #DynamicKeyValue WHERE ISNULL([RecordStatus], '') != '';
			
			--IF(ISNULL(@GlImportModuleId, 0) = ISNULL(@ModuleId, 0))
			--BEGIN
			--	--select * from #DynamicKeyValue
			--END

			DECLARE @json VARCHAR(MAX);
			-- Use STRING_AGG to build a JSON-like string
			SET @json = (
					SELECT STRING_AGG(CONCAT('"', FieldName, '": "', ISNULL(FieldValue, ''), '"'), ', ')
					FROM #DynamicKeyValue
				);
			-- Wrap the result to form a valid JSON object
			SET @json = '{' + @json + '}';

			UPDATE #uploadDataResults 
			SET [Status] = ISNULL(STUFF(@Erorr, CHARINDEX(',', @Erorr), 1, ''), ''), [IsError] = CASE WHEN ISNULL(@Erorr, '') = '' THEN 0 ELSE 1 END,
				[UploadRecord] = @json
			WHERE RecordId = @CurrentRecord;
			
			INSERT INTO [dbo].[UploadModuleData] ([ModuleId], [OriginalRecordData], [RecordData], [Description], [RecordStatus], [IsAdded], [IsError], [MasterCompanyId], 
						[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT [ModuleId], [OriginalRecordData], [UploadRecord], '', [Status], 0, [IsError], [MasterCompanyId], [UserName], GETUTCDATE(), [UserName], GETUTCDATE(), 1, 0
			FROM #uploadDataResults WHERE RecordId = @CurrentRecord;
			
			IF OBJECT_ID('tempdb..#TempDynamicData') IS NOT NULL
				DROP TABLE #TempDynamicData

			IF OBJECT_ID('tempdb..#ImportFields') IS NOT NULL
				DROP TABLE #ImportFields

			SET @CurrentRecord += 1;
		END

		SELECT * FROM [dbo].[UploadModuleData] WITH(NOLOCK) WHERE [ModuleId] = @ModuleId AND [MasterCompanyId] = @MasterCompanyId;

	COMMIT TRANSACTION
	 
	END TRY    
	BEGIN CATCH  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'USP_ValidateCommonUploadData_ByModuleId',    
			@ProcedureParameters varchar(3000) = '@ModuleId = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))    
			+ '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),    
			@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
			EXEC spLogException @DatabaseName = @DatabaseName,    
				@AdhocComments = @AdhocComments,    
				@ProcedureParameters = @ProcedureParameters,    
				@ApplicationName = @ApplicationName,    
				@ErrorLogID = @ErrorLogID OUTPUT;    
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH    
END