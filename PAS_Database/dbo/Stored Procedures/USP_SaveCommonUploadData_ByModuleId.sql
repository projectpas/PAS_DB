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
	6	 29-July-2025		Vishal Suthar			Added New Module "Stockline"
	7	 01-Aug-2025		Ayushi Patel			Added functionality to handle parent table , Added New Module "Customer"
	8	 06-Aug-2025		RAJESH GAMI				Stockline Module : Insert QuantityAvailable as same as QunatityOnHand
	8	 07-Aug-2025		RAJESH GAMI				Fixed: Datetime upload issue
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
		DECLARE @ModuleParentTable VARCHAR(100) = NULL;
		DECLARE @TotalRow BIGINT, @CurrentRow BIGINT;

		DECLARE @IsAutoGenerate BIT = 0;
		DECLARE @CodeTypeId BIGINT = 0;
		DECLARE @CurrentNumber BIGINT;
		DECLARE @AutoGenerateNumber NVARCHAR(50);
		DECLARE @ModuleTableId BIGINT,@ParentModuleTableId BIGINT, @TotalRecords BIGINT = 0, @CurrentRecord BIGINT = 0;
		DECLARE @UploadRecord VARCHAR(MAX) = NULL;
		DECLARE @ChildTable VARCHAR(100) = NULL, @ReferenceColumnName VARCHAR(100) = NULL, @ParentPrimaryColumnName VARCHAR(100) = NULL;
		DECLARE @AlterModule AS BIGINT, @GLModule AS BIGINT, @ItemMasterModule AS BIGINT, @StocklineModule AS BIGINT, @CustomerModule AS BIGINT;
    
		SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
		SET @GLModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'GLAccount');
		SET @ItemMasterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemMaster');
		SET @StocklineModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline');
		SET @CustomerModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Customer');
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

		SELECT @ReferenceTable = ReferenceTable, @CodeTypeId = CodeTypeId, @ChildTable = ChildTable, @ReferenceColumnName = ReferenceColumnName , @ModuleParentTable = ModuleParentTable , @ParentPrimaryColumnName = ParentPrimaryColumnName 
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
						IMF.IsMultiValue, TMP.RecordId, TMP.FieldValue, TMP.RecordStatus, IMF.ParentTableRereneceTypeId
			INTO #ImportFields
			FROM [DBO].[ImportModuleFieldMaster] IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			
			DECLARE @Qty AS INT;
			DECLARE @PurchaseUOMId AS BIGINT;
			DECLARE @ManagementStructureId AS BIGINT;

			IF (@ModuleId = 5) -- Stockline
			BEGIN
				DECLARE @StockLineNumber VARCHAR(100);
				DECLARE @currentNo AS BIGINT = 0;
				DECLARE @stockLineCurrentNo AS BIGINT;
				DECLARE @CNCurrentNumber BIGINT;
				DECLARE @ControlNumber VARCHAR(50);
				DECLARE @IDNumber VARCHAR(50);
				DECLARE @ItemMasterId AS BIGINT;
				DECLARE @ManufacturerId AS BIGINT;

				SELECT @ItemMasterId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ItemMasterId';
				SELECT @ManufacturerId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ManufacturerId';
				SELECT @Qty = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'QuantityOnHand';

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
                BEGIN
                    DROP TABLE #tmpCodePrefixes
                END

                CREATE TABLE #tmpCodePrefixes
                (
                    ID BIGINT NOT NULL IDENTITY,
                    CodePrefixId BIGINT NULL,
                    CodeTypeId BIGINT NULL,
                    CurrentNumber BIGINT NULL,
                    CodePrefix VARCHAR(50) NULL,
                    CodeSufix VARCHAR(50) NULL,
                    StartsFrom BIGINT NULL,
                )

                INSERT INTO #tmpCodePrefixes
                (
                    CodePrefixId,
                    CodeTypeId,
                    CurrentNumber,
                    CodePrefix,
                    CodeSufix,
                    StartsFrom
                )
                SELECT CodePrefixId,
                        CP.CodeTypeId,
                        CurrentNummber,
                        CodePrefix,
                        CodeSufix,
                        StartsFrom
                FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                WHERE CT.CodeTypeId = (@CodeTypeId)
                        AND CP.MasterCompanyId = @MasterCompanyId
                        AND CP.IsActive = 1
                        AND CP.IsDeleted = 0
				UNION
				SELECT CodePrefixId,
                        CP.CodeTypeId,
                        CurrentNummber,
                        CodePrefix,
                        CodeSufix,
                        StartsFrom
                FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                WHERE CT.CodeTypeId IN (17, 9)
                        AND CP.MasterCompanyId = @MasterCompanyId
                        AND CP.IsActive = 1
                        AND CP.IsDeleted = 0;

				IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL
                BEGIN
                    DROP TABLE #tmpPNManufacturer
                END

                CREATE TABLE #tmpPNManufacturer
                (
                    ID BIGINT NOT NULL IDENTITY,
                    ItemMasterId BIGINT NULL,
                    ManufacturerId BIGINT NULL,
                    StockLineNumber VARCHAR(100) NULL,
                    CurrentStlNo BIGINT NULL,
                    isSerialized BIT NULL
                );
                WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId)
                AS (SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId 
					FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1
                    CROSS JOIN (SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2
                    LEFT JOIN DBO.Stockline ac WITH (NOLOCK) ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId
                    WHERE ac.MasterCompanyId = @MasterCompanyId
                    GROUP BY ac.ItemMasterId, ac.ManufacturerId
                    HAVING COUNT(ac.ItemMasterId) > 0)

                INSERT INTO #tmpPNManufacturer
                (
                    ItemMasterId,
                    ManufacturerId,
                    StockLineNumber,
                    CurrentStlNo,
                    isSerialized
                )
                SELECT CSTL.ItemMasterId,
                    CSTL.ManufacturerId,
                    StockLineNumber,
                    ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo,
                    IM.isSerialized
                FROM CTE_Stockline CSTL
				INNER JOIN DBO.Stockline STL WITH (NOLOCK)
				INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId 
				ON CSTL.StockLineId = STL.StockLineId
                /* PN Manufacturer Combination Stockline logic */

				SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

				IF (@currentNo <> 0)
                BEGIN
                    SET @stockLineCurrentNo = @currentNo + 1;
                END
                ELSE
                BEGIN
                    SET @stockLineCurrentNo = 1;
                END

                IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 30))
                BEGIN
                    SET @StockLineNumber =
                    (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo, 
					(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30),
					(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))

                    UPDATE DBO.ItemMaster
                    SET CurrentStlNo = @stockLineCurrentNo
                    WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
                END

				IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
                BEGIN
                    SELECT @CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
                    FROM #tmpCodePrefixes WHERE CodeTypeId = 9;
                    SET @ControlNumber =
                    (
                        SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber, 
						(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 9),
						(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
                    )
                END

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 17))  
				BEGIN
					SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 17)))  
				END
				ELSE
				BEGIN
					ROLLBACK TRAN;
				END

				IF (ISNULL(@StockLineNumber, '') != '')
				BEGIN
					UPDATE #ImportFields SET FieldValue = @StockLineNumber WHERE FieldName = 'stocklinenumber';
				END

				IF (ISNULL(@ControlNumber, '') != '')
				BEGIN
					UPDATE #ImportFields SET FieldValue = @ControlNumber WHERE FieldName = 'controlnumber';
				END

				IF (ISNULL(@IDNumber, '') != '')
				BEGIN
					UPDATE #ImportFields SET FieldValue = @IDNumber WHERE FieldName = 'IdNumber';
				END

				SELECT @PurchaseUOMId = PurchaseUnitOfMeasureId FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId;
				SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM DBO.ManagementStructure WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;
			END

			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;

			WHILE(@TotalRow >= @CurrentRow)
			BEGIN

				SELECT	@IsAutoGenerate = IsAutoGenerate FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;

				IF(ISNULL(@CodeTypeId, 0) > 0 AND ISNULL(@IsAutoGenerate, 0) = 1 AND @ModuleId <> 5)
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
			
			UPDATE #ImportFields SET FieldValue = '0' WHERE FieldType = 'number' AND FieldValue = '';

			SELECT * FROM #ImportFields;

			-----parent table insert Start-----

			IF(ISNULL(@ModuleParentTable, '') != '')
			BEGIN
				SET @RefFieldName = '' -- reset for parent
				SET @FieldValue = ''   -- reset for parent
	
				-- Add FK reference to main record
				--SET @RefFieldName = @ReferenceColumnName -- FK field for parent
				--SET @FieldValue = CAST(@ModuleTableId AS VARCHAR) + ','

				-- Add fields where IsModuleTableColumn is NULL or something specific for parent (adjust condition if needed)
				SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 0 AND  ParentTableRereneceTypeId = @ModuleParentTable;

				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +        
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
							WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'   
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','   
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),      
						
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
							WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'  
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'							
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','  
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))        
				FROM #ImportFields        
				WHERE ISNULL(IsModuleTableColumn, 0) = 0 AND  ParentTableRereneceTypeId = @ModuleParentTable
				print(@FieldValue)
				-- Add audit trail
				SET @RefFieldName += ', MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += CAST(@MasterCompanyId AS VARCHAR) + ',''' + @UserName + ''',''' + @UserName + ''''
				SET @RefFieldName = ISNULL(STUFF(@RefFieldName, CHARINDEX(',', @RefFieldName), 1, ''), '')
				-- Final dynamic insert
				SET @RefQuery = 'INSERT INTO ' + @ModuleParentTable + ' (' + @RefFieldName + ') VALUES (' + @FieldValue + ');'+ ' SET @ParentModuleTableId = SCOPE_IDENTITY()'; 
				PRINT @RefQuery
				EXEC sp_executesql @RefQuery, N'@ParentModuleTableId BIGINT OUTPUT',@ParentModuleTableId OUTPUT;
				
				--EXEC (@RefQuery)
			END


			-----parent table insert End-----
			SET @FieldValue = '';
			SET @RefFieldName = '';

			SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 1;

			SELECT @FieldValue = COALESCE(@FieldValue + ' ' +        
				(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
						WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
						--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
						WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
					
						WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','   
						WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
						WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),      
						
				(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
						WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
						--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
						WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'					
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
			ELSE IF(@ModuleId = @StocklineModule)
			BEGIN
				SET @RefFieldName += ' , PartNumber,Quantity,QuantityAvailable,PurchaseUnitOfMeasureId,ManagementStructureId,QuantityReserved,QuantityTurnIn,QuantityIssued,QuantityToReceive,PurchaseOrderUnitCost,RepairOrderUnitCost,RepairOrderExtendedCost,WorkOrderExtendedCost,ParentId,MasterCompanyId,CreatedBy,UpdatedBy'
				SET @FieldValue += ''''','+ CAST(@Qty AS VARCHAR(50)) +','+ CAST(@Qty AS VARCHAR(50)) +','+ CAST(@PurchaseUOMId AS VARCHAR(50)) +','+ CAST(@ManagementStructureId AS VARCHAR(50)) +',0,0,0,0,0,0,0,0,0, '
			END
			ELSE IF(@ModuleId = @CustomerModule)
				BEGIN
					DECLARE @CustomerCode VARCHAR(120) = 'C-NEW';
					SET @RefFieldName += ' , CustomerCode,IsParent,AddressId,IsAddressForBilling,IsAddressForShipping,IsCustomerAlsoVendor,IsPBHCustomer,RestrictPMA,RestrictDER,
					IsCRMCustomer,Ismiscellaneous,MasterCompanyId,CreatedBy, UpdatedBy'
					SET @FieldValue += '''' + @CustomerCode + ''', 0, ' + CAST(@ParentModuleTableId AS VARCHAR(20)) + ', 1, 1, 0, 0, 1, 1, 0, 0, ';
				END
			ELSE
			BEGIN
				SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'
			END
			print @FieldValue;
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
			
			IF(@ModuleId = @StocklineModule)
			BEGIN
				DECLARE @StkManagementStructureModuleId BIGINT = 2;
				DECLARE @ManagementStructureEntityId BIGINT = 0;

                SELECT @ManagementStructureEntityId = [ManagementStructureId] FROM DBO.Stockline WITH (NOLOCK) WHERE StocklineId = @ModuleTableId;

				EXEC UpdateStocklineColumnsWithId @ModuleTableId;
				EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId, @ModuleTableId, @ManagementStructureEntityId, @MasterCompanyId, @UserName;
			END

			IF(@ModuleId = @CustomerModule)
			BEGIN
				DECLARE @CustomerClassificationVal AS VARCHAR(200);
				DECLARE @CustomerAffiliationVal AS VARCHAR(200);
	
				SET @CustomerClassificationVal = (select FieldValue from #DynamicKeyValue where FieldName = 'CustomerClassificationId')
				SET @CustomerAffiliationVal = (select FieldValue from #DynamicKeyValue where FieldName = 'CustomerAffiliationId')
				
				EXEC USP_UpdateCustomerDetails @ModuleTableId,@ModuleId,@CustomerClassificationVal,@CustomerAffiliationVal, @MasterCompanyId
			END

			IF(ISNULL(@ChildTable, '') != '')
			BEGIN
				SET @RefFieldName = ''+ @ReferenceColumnName + '';
				SET @FieldValue = '' + CAST(@ModuleTableId AS VARCHAR) + ',';

				SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 0

				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +        
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
							WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
						
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','   
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','   
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),      
						
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','        
							WHEN FieldType = 'boolean' THEN (CASE	WHEN LOWER(REPLACE(FieldValue, '''', '''''')) IN ('yes', 'true') THEN '1,' ELSE '0,' END)        
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),' 
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'							
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
	END CATCH    
END