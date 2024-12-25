/***************************************************************  
 ** File:   [USP_ValidateCommonUploadData_ByModuleId]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to add upload Data
 ** Date:  23-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    23-Dec-2024		Devendra Shekh			Created

declare @p4 dbo.UploadModuleDataTableType
insert into @p4 values(2,N'DEVENDRASILVER MICKSILVER',1,N'{
  "oldAccountCode": "TestUploadOldCode",
  "accountCode": 50009,
  "accountName": "Test Account Name check",
  "accountDescription": "Checking Test Description",
  "allowManualJE": "yes",
  "glAccountTypeId": " ",
  "glClassFlowClassificationId": " ",
  "ledgerId": "Power Aero Suites - DEMO"
}')

exec USP_ValidateCommonUploadData_ByModuleId @ModuleId=2,@UserName=N'DEVENDRASILVER MICKSILVER',@MasterCompanyId=1,@UploadData=@p4
**************************************************************/
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
			[FieldValue] VARCHAR(100) NULL, 
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
		
		DELETE FROM [dbo].[UploadModuleData] WHERE [ModuleId] = @ModuleId;
		
		SELECT @GlImportModuleId = [ImportModuleId] FROM [dbo].[ImportModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'GLACCOUNT';

		INSERT INTO #uploadDataResults([ModuleId], [UserName], [MasterCompanyId], [UploadRecord], [OriginalRecordData])
		SELECT [ModuleId], [UserName], [MasterCompanyId], [UploadRecord], [UploadRecord] FROM @UploadData;

		SELECT @TotalRecords = MAX([RecordId]), @CurrentRecord = MIN([RecordId]) FROM #uploadDataResults;

		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecord, 0))
		BEGIN

			TRUNCATE TABLE #DynamicKeyValue;

			SET @Erorr = '';

			SELECT @UploadRecord = [UploadRecord] FROM #uploadDataResults WHERE [RecordId] = @CurrentRecord;

			SELECT [key], [value] INTO #TempDynamicData FROM OPENJSON(@UploadRecord);

			INSERT INTO #DynamicKeyValue (FieldName, FieldValue) SELECT [key], [value] FROM #TempDynamicData;

			SELECT	IMF.ImportModuleFieldMasterId, IMF.ModuleId, IMF.FieldName, IMF.HeaderName, IMF.FieldType, IMF.IsRequired,
						IMF.DropdownListType, IMF.DropdownListTable, IMF.DropdownListId, IMF.DropdownListValue, IMF.DropdownListValueId,
						IMF.IsMultiValue, TMP.RecordId, TMP.FieldValue, TMP.RecordStatus  
			INTO #ImportFields
			FROM [DBO].[ImportModuleFieldMaster] IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId

			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;

			WHILE(@TotalRow >= @CurrentRow)
			BEGIN

				SELECT	@DropdownListTable = DropdownListTable, @DropdownListId = DropdownListId, @DropdownListValue = DropdownListValue, @DropdownLFieldValue = FieldValue
				FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;

				IF(ISNULL(@DropdownListTable, '') != '' AND ISNULL(@DropdownLFieldValue, '') != '')
				BEGIN
					DECLARE @DropdownListValueId VARCHAR(100) = NULL;

					EXEC [dbo].[USP_GetDropdownValueId] @DropdownListTable, @DropdownListId, @DropdownListValue, @DropdownLFieldValue, @MasterCompanyId, @FieldValueId = @DropdownListValueId OUTPUT;
				
					IF(ISNULL(@DropdownListValueId, '') != '')
					BEGIN
						UPDATE #ImportFields SET DropdownListValueId = CAST(@DropdownListValueId AS VARCHAR) WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
				END

				SET @CurrentRow += 1;
			END

			UPDATE TMP
			SET TMP.[RecordStatus] =	CASE	WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(TMP.FieldValue, '') = '' THEN IMF.HeaderName + ' is Required'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != ''  AND ISNULL(IMF.DropdownListValueId, '') = '' THEN IMF.HeaderName + ' is Required'
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
				SELECT STRING_AGG(CONCAT('"', FieldName, '": "', FieldValue, '"'), ', ')
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

		SELECT * FROM [dbo].[UploadModuleData] WITH(NOLOCK) WHERE [ModuleId] = @ModuleId;

	COMMIT TRANSACTION
	 
	END TRY    
	BEGIN CATCH    
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
	END CATCH    
END