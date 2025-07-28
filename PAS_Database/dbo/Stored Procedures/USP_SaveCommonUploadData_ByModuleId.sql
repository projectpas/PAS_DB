/***************************************************************  
 ** File:   [USP_SaveCommonUploadData_ByModuleId]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to add upload Data
 ** Date:  23-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    23-Dec-2024		Devendra Shekh			Created
	2    06-Jan-2025		Devendra Shekh			Added MasterCompanyId for Delete [UploadModuleData]
	3    24-01-2025         Shrey Chandegara        Modify due to add functionality for Alternate Part
	4    12-03-2025         Abhishek Jirawla        Update LedgerId for GLAccount
	5	 28-July-2025		Ayushi Patel			Added Defaul value to NotNullable Fields of ItemMaster Table
exec USP_SaveCommonUploadData_ByModuleId @ModuleId=4,@UserName=N'VICTOR ADMAS',@MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveCommonUploadData_ByModuleId]
	@ModuleId BIGINT = NULL,    
	@MasterCompanyId INT = NULL, 
	@UserName VARCHAR(256) = NULL
AS    
BEGIN    
	SET NOCOUNT ON;    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	BEGIN TRY    
	
	BEGIN TRANSACTION

		IF OBJECT_ID('tempdb..#uploadDataResults') IS NOT NULL
			DROP TABLE #uploadDataResults

		IF OBJECT_ID('tempdb..#DynamicKeyValue') IS NOT NULL
			DROP TABLE #DynamicKeyValue

		IF OBJECT_ID('tempdb..#ImportFields') IS NOT NULL
			DROP TABLE #ImportFields

		IF OBJECT_ID('tempdb..#tmpCodePrefix') IS NOT NULL
			DROP TABLE #tmpCodePrefix

		DECLARE @FieldValue AS VARCHAR(MAX);   
		DECLARE @RefFieldName AS VARCHAR(MAX);
		DECLARE @RefQuery AS NVARCHAR(MAX) = '';
		DECLARE @ReferenceTable VARCHAR(100) = NULL;
		DECLARE @TotalRow BIGINT, @CurrentRow BIGINT;

		DECLARE @IsAutoGenerate BIT = 0;
		DECLARE @CodeTypeId BIGINT = 0;
		DECLARE @CurrentNumber BIGINT;
		DECLARE @AutoGenerateNumber NVARCHAR(50);
		DECLARE @ModuleTableId BIGINT, @TotalRecords BIGINT = 0, @CurrentRecord BIGINT = 0;
		DECLARE @UploadRecord VARCHAR(MAX) = NULL;
		DECLARE @ChildTable VARCHAR(100) = NULL, @ReferenceColumnName VARCHAR(100) = NULL;
		DECLARE @AlterModule AS BIGINT, @GLModule AS BIGINT, @ItemMasterModule AS BIGINT;
    
		SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
		SET @GLModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'GLAccount');
		SET @ItemMasterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemMaster');
		CREATE TABLE #uploadDataResults (
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[UploadModuleDataId] [bigint] NOT NULL,
			[ModuleId] [bigint] NOT NULL,
			[RecordData] [varchar](MAX) NOT NULL,
			[Description] [varchar](500) NULL,
			[RecordStatus] [varchar](MAX) NOT NULL,
			[IsAdded] [bit] NULL,
			[IsError] [bit] NULL,
			[MasterCompanyId] [int] NOT NULL,
			[CreatedBy] [varchar](50) NOT NULL,
			[CreatedDate] [datetime2](7) NOT NULL,
			[UpdatedBy] [varchar](50) NOT NULL,
			[UpdatedDate] [datetime2](7) NOT NULL,
			[IsActive] [bit] NOT NULL,
			[IsDeleted] [bit] NOT NULL,
		)

		CREATE TABLE #DynamicKeyValue (
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[FieldName] VARCHAR(100) NULL, 
			[FieldValue] VARCHAR(100) NULL, 
			[RecordStatus] [varchar](max) NULL
		);

		SELECT @ReferenceTable = ReferenceTable, @CodeTypeId = CodeTypeId, @ChildTable = ChildTable, @ReferenceColumnName = ReferenceColumnName  
		FROM [dbo].[ImportModule] WITH(NOLOCK) WHERE [ImportModuleId] = @ModuleId;

		INSERT INTO #uploadDataResults ([UploadModuleDataId], [ModuleId], [RecordData], [Description], [RecordStatus], [IsAdded], [IsError], [MasterCompanyId], 
										[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]) 
		SELECT	[UploadModuleDataId], [ModuleId], [RecordData], [Description], [RecordStatus], [IsAdded], [IsError], [MasterCompanyId], [CreatedBy],
				[CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
		FROM [dbo].[UploadModuleData] WHERE [ModuleId] = @ModuleId;

		SELECT @TotalRecords = MAX([RecordId]), @CurrentRecord = MIN([RecordId]) FROM #uploadDataResults;

		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecord, 0))
		BEGIN

			TRUNCATE TABLE #DynamicKeyValue;

			SELECT @UploadRecord = [RecordData] FROM #uploadDataResults WHERE [RecordId] = @CurrentRecord;

			SELECT [key], [value] INTO #TempDynamicData FROM OPENJSON(@UploadRecord);

			INSERT INTO #DynamicKeyValue (FieldName, FieldValue) SELECT [key], [value] FROM #TempDynamicData;

			SELECT	IMF.ImportModuleFieldMasterId, IMF.ModuleId, IMF.FieldName, IMF.HeaderName, IMF.FieldType, IMF.IsRequired,  IMF.IsAutoGenerate, IMF.IsModuleTableColumn,
						IMF.DropdownListType, IMF.DropdownListTable, IMF.DropdownListId, IMF.DropdownListValue, IMF.DropdownListValueId,
						IMF.IsMultiValue, TMP.RecordId, TMP.FieldValue, TMP.RecordStatus 
			INTO #ImportFields
			FROM [DBO].[ImportModuleFieldMaster] IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			
			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;

			WHILE(@TotalRow >= @CurrentRow)
			BEGIN

				SELECT	@IsAutoGenerate = IsAutoGenerate FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;

				IF(ISNULL(@CodeTypeId, 0) > 0 AND ISNULL(@IsAutoGenerate, 0) = 1)
				BEGIN
					-- Fetch CodeTypeData
					SELECT TOP 1 * INTO #tmpCodePrefix	FROM DBO.CodePrefixes WITH (NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;
				
					-- Determine the current number
					IF EXISTS (SELECT 1 FROM #tmpCodePrefix)
					BEGIN
						IF (SELECT CurrentNummber FROM #tmpCodePrefix) > 0
						BEGIN
							SET @CurrentNumber = (SELECT CurrentNummber FROM #tmpCodePrefix) + 1;
						END
						ELSE
						BEGIN
							SET @CurrentNumber = (SELECT StartsFrom FROM #tmpCodePrefix) + 1;
						END

						 --Update CodeData with new current number
						UPDATE CodePrefixes
						SET CurrentNummber = @CurrentNumber
						WHERE CodePrefixId = (SELECT CodePrefixId FROM #tmpCodePrefix);

						-- Generate AutoGenerateNumber
						SET @AutoGenerateNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNumber, (SELECT CodePrefix FROM #tmpCodePrefix), (SELECT CodeSufix FROM #tmpCodePrefix)));
					END
					ELSE
					BEGIN
						-- Generate AutoGenerateNumber without prefix/suffix
						SET @AutoGenerateNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(0, '', ''));
					END

					IF(ISNULL(@AutoGenerateNumber, '') != '')
					BEGIN
						UPDATE #ImportFields SET FieldValue = @AutoGenerateNumber WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
				END

				SET @CurrentRow += 1;
			END

			SET @FieldValue = '';
			SET @RefFieldName = '';

			SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 1;

			SELECT @FieldValue = COALESCE(@FieldValue + ' ' +        
				(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
						WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
						WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'        
						WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','   
						WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
						WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),      
						
				(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
						WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
						WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'        
						WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','  
						WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
						WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))        
			FROM #ImportFields        
			WHERE ISNULL(IsModuleTableColumn, 0) = 1 

			IF(@ModuleId = @AlterModule)
			BEGIN
				SET @RefFieldName += ' , MappingType, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += '1, '
			END
			ELSE IF(@ModuleId = @ItemMasterModule)
			BEGIN
				SET @RefFieldName += ' , ItemTypeId,IsHazardousMaterial,IsExpirationDateAvailable,IsReceivedDateAvailable,DaysReceived,IsManufacturingDateAvailable,
				ManufacturingDays,IsTagDateAvailable,TagDays,IsOpenDateAvailable,OpenDays,IsShippedDateAvailable,ShippedDays,IsOtherDateAvailable,
				OtherDays,IsSchematic,OverhaulHours,RPHours,TestHours,RFQTracking,GLAccountId,LeadTimeDays,ReorderPoint,ReorderQuantiy,MinimumOrderQuantity,
				TurnTimeOverhaulHours,TurnTimeRepairHours,isTimeLife,isSerialized,ShelfLife,StockLevel,ShelfLifeAvailable,mfgHours,turnTimeMfg,turnTimeBenchTest,
				ItemMasterAssetTypeId,IsHotItem,IsAcquiredMethodBuy,MTBUR,NE,NS,OH,REP,SVC,MasterCompanyId,CreatedBy, UpdatedBy'
				SET @FieldValue += '1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,13,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, '
			END
			ELSE
			BEGIN
				SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'
			END
			print @RefFieldName;
			SET @FieldValue += ' ' + CAST(@MasterCompanyId AS VARCHAR) + ',''' + @UserName + ''',''' + @UserName + '''' 

			SET @RefFieldName = ISNULL(STUFF(@RefFieldName, CHARINDEX(',', @RefFieldName), 1, ''), '')
			SET @RefQuery = 'INSERT INTO ' + @ReferenceTable + ' (' + @RefFieldName + ' )' + ' VALUES (' + @FieldValue + ');' + ' SET @ModuleTableId = SCOPE_IDENTITY()';

			--select * from #ImportFields

			PRINT @RefQuery

			EXEC sp_executesql @RefQuery, N'@ModuleTableId BIGINT OUTPUT', @ModuleTableId OUTPUT;

			IF(@ModuleId = @ItemMasterModule)
			BEGIN
				DECLARE @PartSourceVal AS VARCHAR(200);

				SET @PartSourceVal = (select FieldValue from #DynamicKeyValue where FieldName = 'PartSource')

				EXEC usp_UpdateItemMasterWithGLAccountNames @ModuleTableId ,@PartSourceVal, @MasterCompanyId
			END

			IF(ISNULL(@ChildTable, '') != '')
			BEGIN
				SET @RefFieldName = ''+ @ReferenceColumnName + '';
				SET @FieldValue = '' + CAST(@ModuleTableId AS VARCHAR) + ',';

				SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 0

				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +        
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
							WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'        
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','   
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),      
						
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
							WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'        
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','  
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))        
				FROM #ImportFields        
				WHERE ISNULL(IsModuleTableColumn, 0) = 0
	  
				SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += ' ' + CAST(@MasterCompanyId AS VARCHAR) + ',''' + @UserName + ''',''' + @UserName + '''' 
				--SET @RefFieldName = ISNULL(STUFF(@RefFieldName, CHARINDEX(',', @RefFieldName), 1, ''), '')

				SET @RefQuery = 'INSERT INTO ' + @ChildTable + ' (' + @RefFieldName + ' )' + ' VALUES (' + @FieldValue + ');'
				PRINT @RefQuery
				EXEC (@RefQuery)  
			END

			-- Need to update ledger
			IF(@ModuleId = @GLModule)
			BEGIN
				DECLARE @setLedgerId INT = 0;

				IF EXISTS(SELECT TOP 1 * FROM [DBO].[GLAccountLadgerMapping] WITH(NOLOCK) WHERE GlAccountId = @ModuleTableId)
				BEGIN
					SELECT TOP 1 @setLedgerId = LedgerId FROM [DBO].[GLAccountLadgerMapping] WITH(NOLOCK) WHERE GlAccountId = @ModuleTableId
				END

				UPDATE GLAccount
				SET LedgerId = @setLedgerId
				WHERE GlAccountId = @ModuleTableId
			END

			--SELECT * FROM #ImportFields

			IF OBJECT_ID('tempdb..#TempDynamicData') IS NOT NULL
				DROP TABLE #TempDynamicData

			IF OBJECT_ID('tempdb..#ImportFields') IS NOT NULL
				DROP TABLE #ImportFields

			SET @CurrentRecord += 1;
		END

		--SELECT * FROM #uploadDataResults;

		DELETE FROM [dbo].[UploadModuleData] WHERE [ModuleId] = @ModuleId AND [MasterCompanyId] = @MasterCompanyId;

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
			,@AdhocComments varchar(150) = 'USP_SaveCommonUploadData_ByModuleId',    
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