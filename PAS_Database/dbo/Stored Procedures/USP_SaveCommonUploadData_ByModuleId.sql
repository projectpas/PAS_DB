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
	8	 01-Aug-2025		Bhargav Saliya			Added New Module "Vendor"
	9	 06-Aug-2025		RAJESH GAMI				Stockline Module : Insert QuantityAvailable as same as QunatityOnHand
	10	 07-Aug-2025		RAJESH GAMI				Fixed: Datetime upload issue
	11	 11-Aug-2025		Ayushi Patel			inserted auto generate field into stockline
	12	 12-Aug-2025		Ayushi Patel			Receive Date Changes
	13	 12-Aug-2025		Ayushi Patel			ObtainFromType, OwnerType, TraceableToType Inserted as otherModuleType
	14	 13-Aug-2025		Ayushi Patel			Handle Manufacturer based on PartNumber for stockline
	15 	 26-Aug-2025        Divyesh Kathiriya		Added New Module "Publication"
	16 	 26-Aug-2025        Rajesh Gami				Price Master Implemented &Resolved issue
	17	 04-Sep-2025        Divyesh Kathitiya		Added Customer Default Settings And Set Customer and Vendor: IsAddress For Billing & Shipping.
	18	 11-Sep-2025        Rajesh Gami				Update CodePrefixCode for the stockline module.
	19	 16-Sep-2025        Rajesh Gami				Price Master/Purchase and Sales: Calculate the Discount and related changes
	20	 10-Oct-2025        Priyansh Patel			MRO Price Master Implemented
	21	 14-OCT-2025        Rajesh Gami				Added validation
	22   29-OCT-2025        Priyansh Patel          Added MRO Price Master List Module Validation
	23 	 03-Nov-2025        Divyesh Kathiriya		Added New Module "Employee"
	24	 10-Nov-2025	    Priyansh Patel			Updated column name UnitPrice to FlatRatePrice
	25 	 20-Nov-2025        Divyesh Kathiriya		Added new field for "ItemMaster"
	26   26-Nov-2025        Ayushi Patel            Updated dynamic INSERT/UPDATE queries to wrap ReferenceTable, ParentTable, and ChildTable names in [ ] to prevent syntax errors when table names are reserved keywords (e.g., Percent).
	27	 02-DEC-2025        Ayushi Patel			Added New SingleScreen Modules
	28	 04-Dec-2025        Divyesh Kathiriya		Handle new line "/r/n" in All Filed
	29	 08-Dec-2025        Divyesh Kathiriya		Handle new tab "\", "\t" in All Filed
	30	 17-DEC-2025        Nakul Chandigra  		Added New SingleScreen Modules
	31	 02-Feb-2026        Nakul Chandigra  		Added New SingleScreen Modules
	32   09-APR-2026		Ayushi Patel			PN-15988 Handled QuantityOnHand As decimal
	33   22-APR-2026		Nakul Chandigra			Removed Handled Description code for  Item Classification and  Item Group (PN-15952)
	34   13-MAY-2026		Ayushi Patel			PN-16321 handled new WorkOrderMaterial module
	35   05-JUN-2026        Ayushi Patel            PN-15888 Fixed PriceMaster/PurchaseSales upload: PP_PurchaseDiscPerc and SP_CalSPByPP_MarkUpPercOnListPrice were storing PercentId instead of PercentValue. Resolved actual percent values from [Percent] table before discount and markup calculations.
	36   05-JUN-2026        Ayushi Patel            Added ParentTable insted of ParentTableRereneceTypeId for IsModuleTableColumn = 0 to support dynamic parent table insert functionality for upload module.
	37   19-JUN-2026		Moin Bloch			    Fixed Error Log Error For Address PN-16924
	38   22-JUN-2026		Ayushi Patel			Set The Default GLAccountID For ItemMaster Module
	39    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	40	 02-JULY-2026       Ayushi Patel            Generate vendorCode and CustomerCode dynamically
	41	 18-Aug-2026        Ayushi Patel            [PN-17672] Handle 'Y'/'N' values along with 'YES'/'NO' to store corresponding 0/1 values for all modules.
	42	 27-Aug-2026        Ayushi Patel			Added ItemMasterNonStock module 
	43   28/08/2026         Ayushi Patel            [PN-16987] added effective date
  exec USP_SaveCommonUploadData_ByModuleId @ModuleId=4,@UserName=N'VICTOR ADMAS',@MasterCompanyId=1, @EmployeeId = 236;
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveCommonUploadData_ByModuleId]
	@ModuleId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@UserName VARCHAR(256) = NULL,
	@EmployeeId BIGINT = NULL
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

		DECLARE @ItemMasterModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'ItemMaster')
		DECLARE @FieldValue AS VARCHAR(MAX);
		DECLARE @RefFieldName AS VARCHAR(MAX);
		DECLARE @RefQuery AS NVARCHAR(MAX) = '';
		DECLARE @ReferenceTable VARCHAR(100) = NULL;
		DECLARE @ModuleParentTable VARCHAR(100) = NULL;
		DECLARE @TotalRow BIGINT, @CurrentRow BIGINT;
		DECLARE @ReceivedDate DATETIME = 0;
		DECLARE @UtcNow DATETIME2(7) = GETUTCDATE();
		DECLARE @GetDate DATE = GETDATE();
		DECLARE @PublicationMSId BIGINT;
		DECLARE @EmployeeMSId BIGINT;
		DECLARE @LegalEntityId BIGINT;
		DECLARE @EmpUserName VARCHAR(256);
		DECLARE @EmpFirstName VARCHAR(256);
		DECLARE @EmpLastName VARCHAR(256);
		DECLARE @EmpFullName VARCHAR(256);
		DECLARE @EmpEmail VARCHAR(256);
		DECLARE @IsEnabled BIT;
		DECLARE @isPriceDataExist BIT = 0, @ItemMasterPurchaseSaleId BIGINT = 0
		DECLARE @IsAutoGenerate BIT = 0;
		DECLARE @CodeTypeId BIGINT = 0;
		DECLARE @CurrentNumber BIGINT;
		DECLARE @AutoGenerateNumber NVARCHAR(50),@PartNumber NVARCHAR(150) ='';
		DECLARE @ModuleTableId BIGINT,@ParentModuleTableId BIGINT, @TotalRecords BIGINT = 0, @CurrentRecord BIGINT = 0;
		DECLARE @UploadRecord VARCHAR(MAX) = NULL;
		DECLARE @ChildTable VARCHAR(100) = NULL, @ReferenceColumnName VARCHAR(100) = NULL, @ParentPrimaryColumnName VARCHAR(100) = NULL;
		DECLARE @AlterModule AS BIGINT, @GLModule AS BIGINT, @ItemMasterModule AS BIGINT, @StocklineModule AS BIGINT, @CustomerModule AS BIGINT,@VendorModule AS BIGINT, @PublicationModule AS BIGINT, @EmployeeModule AS BIGINT, @ItemMasterAccountingModuleId AS INT, @chargeModule AS BIGINT;
		DECLARE @PriceMasterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'PriceMaster');
		DECLARE @PurchaseSalesModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseSales');
		DECLARE @MROPriceMasterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MROPriceMaster');
		DECLARE @DefaultMessageModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'DefaultMessage');
		DECLARE @isMROPriceDataExist BIT = 0;
		DECLARE @EmployeeExpertiseModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeExpertise');
		DECLARE @MROPriceMasterListModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MROPriceMasterList');
		DECLARE @ItemMasterId BIGINT = 0;
		DECLARE @IsAddressForBilling VARCHAR(50);
		DECLARE @IsAddressForShipping VARCHAR(50);
		DECLARE @SalePriceSelectId Varchar(30)= '';
		DECLARE @SP_CalSPByPP_MarkUpPercOnListPriceValue DECIMAL(18,2) =0;
		DECLARE @SP_CalSPByPP_MarkUpPercOnListPrice DECIMAL(18,2) = 0
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		DECLARE @EnumEmployeeGeneralInfo INT;
		DECLARE @ItemMasterAssetTypeId INT;
		DECLARE @PriorityId AS BIGINT, @Priority AS BIGINT, @PurchaseUnitOfMeasureId AS BIGINT, @StockUnitOfMeasureId AS BIGINT,@ConsumeUnitOfMeasureId AS BIGINT;

		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK)
					LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE E.EmployeeId = @EmployeeId;
		DECLARE @employeeGetDate   DATE = CASE WHEN ISNULL(@CurrntEmpTimeZoneDesc,'') = '' THEN GETDATE() ELSE Cast(DBO.ConvertUTCtoLocal(GETDATE(), @CurrntEmpTimeZoneDesc) as Date) END
		SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
		SET @GLModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'GLAccount');
		SET @ItemMasterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemMaster');
		DECLARE @ItemMasterNonStockModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemMasterNonStock');
		SET @StocklineModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline');
		SET @CustomerModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Customer');
		SET @VendorModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Vendor');
		SET @PublicationModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Publication');
		SET @EmployeeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Employee');
		SET @chargeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'charge');
		SET @EnumEmployeeGeneralInfo = (SELECT [ManagementStructureModuleId] FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeGeneralInfo');
		SET @ItemMasterAccountingModuleId = (SELECT [AccountingModuleId] FROM [DBO].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'ITEMMASTER');
		DECLARE @LotCostSourceReference AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'LotCostSourceReference');
		DECLARE @ItemGroupModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemGroup');
		DECLARE @ItemClassificationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemClassification');
		DECLARE @SiteModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Site');
		DECLARE @POROCategory AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'POROCategory');
		DECLARE @InventoryGLSettingModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'InventoryGLSetting');
		DECLARE @WorkOrderStageModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderStage');
		DECLARE @CommonTeardownTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CommonTeardownType');
		DECLARE @LocationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Location');
		DECLARE @ShelfModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Shelf');
		DECLARE @BinModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Bin');
		DECLARE @WorkOrderMaterialsModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMaterials');
		DECLARE @YesValues TABLE (Value VARCHAR(10));
		INSERT INTO @YesValues VALUES ('yes'), ('y');
		DECLARE @NoValues TABLE (Value VARCHAR(10));
		INSERT INTO @NoValues VALUES ('no'), ('n');
		SET @EmployeeMSId = (SELECT [ManagementStructureId] FROM [DBO].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId);
		SET @PublicationMSId = (SELECT [ManagementStructureId] FROM DBO.[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId);
			DECLARE @WarehouseId BIGINT = NULL;
			DECLARE @SiteId BIGINT;
			DECLARE @SiteName VARCHAR(MAX);
			DECLARE @WarehouseName VARCHAR(MAX);

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
			[FieldValue] VARCHAR(MAX) NULL,
			[RecordStatus] [varchar](max) NULL
		);

		SELECT @ReferenceTable = ReferenceTable, @CodeTypeId = CodeTypeId, @ChildTable = ChildTable, @ReferenceColumnName = ReferenceColumnName , @ModuleParentTable = ModuleParentTable , @ParentPrimaryColumnName = ParentPrimaryColumnName
		FROM [dbo].[ImportModule] WITH(NOLOCK) WHERE [ImportModuleId] = @ModuleId;
		INSERT INTO #uploadDataResults ([UploadModuleDataId], [ModuleId], [RecordData], [Description], [RecordStatus], [IsAdded], [IsError], [MasterCompanyId],
										[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
		SELECT	[UploadModuleDataId], [ModuleId], [RecordData], [Description], [RecordStatus], [IsAdded], [IsError], [MasterCompanyId], [CreatedBy],
				[CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
		FROM [dbo].[UploadModuleData] WHERE [ModuleId] = @ModuleId AND MasterCompanyId = @MasterCompanyId	;
		SELECT @TotalRecords = MAX([RecordId]), @CurrentRecord = MIN([RecordId]) FROM #uploadDataResults;

		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecord, 0))
		BEGIN

			TRUNCATE TABLE #DynamicKeyValue;
			SELECT @UploadRecord = [RecordData] FROM #uploadDataResults WHERE [RecordId] = @CurrentRecord;
			------------START: Handle new line, new tab "/r", "/n", "\", "\t" ------------
			--SET @UploadRecord = REPLACE(@UploadRecord, '\', '\\');
			SET @UploadRecord = REPLACE(@UploadRecord, CHAR(13) + CHAR(10), '\r\n');
			SET @UploadRecord = REPLACE(@UploadRecord, CHAR(13), '\r\n');
			SET @UploadRecord = REPLACE(@UploadRecord, CHAR(10), '\n');
			SET @UploadRecord = REPLACE(@UploadRecord, CHAR(9), '\t');
------------END: Handle new line, new tab "/r", "/n", "\", "\t"------------

			SET @UploadRecord = CASE WHEN @ModuleId = @PriceMasterModule OR @ModuleId = @PurchaseSalesModule  OR @ModuleId = @MROPriceMasterModule   OR @ModuleId = @MROPriceMasterListModule THEN  JSON_MODIFY(@UploadRecord, '$.ManufacturerId', NULL) ELSE @UploadRecord END;

			IF(@ModuleId = @StocklineModule)
			BEGIN
				SET @UploadRecord = JSON_MODIFY(
							JSON_MODIFY(
								JSON_MODIFY(@UploadRecord, '$.stocklinenumber', ''),
								'$.controlnumber', ''
							),
							'$.IdNumber', ''
						);
			END
			SELECT [key], [value] INTO #TempDynamicData FROM OPENJSON(@UploadRecord);

			INSERT INTO #DynamicKeyValue (FieldName, FieldValue) SELECT [key], TRIM([value]) FROM #TempDynamicData;
			SELECT	IMF.ImportModuleFieldMasterId, IMF.ModuleId, IMF.FieldName, IMF.HeaderName, IMF.FieldType, IMF.IsRequired,  IMF.IsAutoGenerate, IMF.IsModuleTableColumn,
						IMF.DropdownListType, IMF.DropdownListTable, IMF.DropdownListId, IMF.DropdownListValue, IMF.DropdownListValueId,
						IMF.IsMultiValue, TMP.RecordId, TMP.FieldValue, TMP.RecordStatus, IMF.ParentTableRereneceTypeId , IMF.ParentTable
			INTO #ImportFields
			FROM [DBO].[ImportModuleFieldMaster] IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId  AND NOT ((@ModuleId = @PriceMasterModule OR @ModuleId = @PurchaseSalesModule OR @ModuleId = @MROPriceMasterModule  OR @ModuleId = @MROPriceMasterListModule) AND IMF.FieldName = 'ManufacturerId' );

			IF (@ModuleId = @ItemMasterNonStockModule)
			BEGIN
				-- IsService / IsAcquiredMethodBuy are optional: default to Yes when the user left them blank
				IF (ISNULL(LTRIM(RTRIM((SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'IsService'))), '') = '')
				BEGIN
					UPDATE #DynamicKeyValue SET FieldValue = 'Yes' WHERE FieldName = 'IsService';
					UPDATE #ImportFields SET FieldValue = 'Yes' WHERE FieldName = 'IsService';
				END
				IF (ISNULL(LTRIM(RTRIM((SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'IsAcquiredMethodBuy'))), '') = '')
				BEGIN
					UPDATE #DynamicKeyValue SET FieldValue = 'Yes' WHERE FieldName = 'IsAcquiredMethodBuy';
					UPDATE #ImportFields SET FieldValue = 'Yes' WHERE FieldName = 'IsAcquiredMethodBuy';
				END
			END
			--DECLARE @Qty AS INT;
			DECLARE @Qty AS DECIMAL(18,6);
			DECLARE @PurchaseUOMId AS BIGINT;
			DECLARE @ManagementStructureId AS BIGINT;

			IF (@ModuleId = @StocklineModule) -- Stockline
			BEGIN
				DECLARE @StockLineNumber VARCHAR(100);
				DECLARE @currentNo AS BIGINT = 0;
				DECLARE @stockLineCurrentNo AS BIGINT;
				DECLARE @CNCurrentNumber BIGINT;
				DECLARE @ControlNumber VARCHAR(50);
				DECLARE @IDNumber VARCHAR(50);
				DECLARE @ManufacturerId AS BIGINT;
				DECLARE @isSerialized VARCHAR(50);
				DECLARE @SerialNumber VARCHAR(50);

				SELECT @isSerialized = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isSerialized';
				SELECT @SerialNumber = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'SerialNumber';
				SELECT @ItemMasterId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ItemMasterId';
				SELECT @ManufacturerId = ManufacturerId from Manufacturer where Name = (select FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ManufacturerId') and MasterCompanyId=@MasterCompanyId;
					IF @ManufacturerId IS NOT NULL
				BEGIN
					-- Update the ManufacturerId in #DynamicKeyValue
					UPDATE #DynamicKeyValue
					SET FieldValue = @ManufacturerId
					WHERE FieldName = 'ManufacturerId';

				END
				IF LOWER(@isSerialized) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = ' '  -- Set SerialNumber to blank
					WHERE FieldName = 'SerialNumber';
				END
				IF LOWER(@isSerialized) IN (SELECT Value FROM @YesValues) and ISNULL(@SerialNumber,'') = ''
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = 'Default'  -- Set Default serialNumber
					WHERE FieldName = 'SerialNumber';
				END
				IF LOWER(@isSerialized) IN (SELECT Value FROM @YesValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '1'  -- Set isSerialized to 1
					WHERE FieldName = 'isSerialized';
				END
				ELSE IF LOWER(@isSerialized) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '0'  -- Set isSerialized to 0
					WHERE FieldName = 'isSerialized';
				END
				SELECT @ManufacturerId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ManufacturerId';
				--SELECT @Qty = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'QuantityOnHand';
				SELECT @Qty = TRY_CAST(FieldValue AS DECIMAL(18,6))FROM #DynamicKeyValue WHERE FieldName = 'QuantityOnHand';
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

				 WHERE ISNULL(IM.IsNonStock,0) = 0
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
					update dbo.CodePrefixes set CurrentNummber = @CNCurrentNumber where MasterCompanyId=@MasterCompanyId AND CodeTypeId = 9
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
				IF (ISNULL(@ManufacturerId, '') != '')
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = @ManufacturerId
					WHERE FieldName = 'ManufacturerId';

				END
				IF LOWER(@isSerialized) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = ' '  -- Set SerialNumber to blank
					WHERE FieldName = 'SerialNumber';
				END
				IF LOWER(@isSerialized) IN (SELECT Value FROM @YesValues) and ISNULL(@SerialNumber,'') = ''
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = 'Default'  -- Set Default serialNumber
					WHERE FieldName = 'SerialNumber';
				END
				IF LOWER(@isSerialized) IN (SELECT Value FROM @YesValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '1'  -- Set isSerialized to 1
					WHERE FieldName = 'isSerialized';
				END
				ELSE IF LOWER(@isSerialized) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '0'  -- Set isSerialized to 0
					WHERE FieldName = 'isSerialized';
				END
				SELECT @PurchaseUOMId = PurchaseUnitOfMeasureId FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;
				SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM DBO.ManagementStructure WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;
			END
			IF(@ModuleId = @ItemMasterModule)
			BEGIN
				SELECT @ItemMasterAssetTypeId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ItemMasterAssetTypeId';
				SELECT @Priority = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'PriorityId';
				SELECT @PurchaseUnitOfMeasureId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'PurchaseUnitOfMeasureId';
				SELECT @StockUnitOfMeasureId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'StockUnitOfMeasureId';
				SELECT @ConsumeUnitOfMeasureId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ConsumeUnitOfMeasureId';
				SELECT @PriorityId = [PriorityId] FROM [PRIORITY] WITH (NOLOCK) WHERE [Description] = 'ROUTINE' AND [MasterCompanyId] = @MasterCompanyId;
				IF(@ItemMasterAssetTypeId IS NULL OR @ItemMasterAssetTypeId = '')
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = 1
					WHERE FieldName = 'ItemMasterAssetTypeId';
				END
				IF(@Priority IS NULL OR @Priority = '')
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = @PriorityId
					WHERE FieldName = 'PriorityId';
				END
				IF(@StockUnitOfMeasureId IS NULL OR @StockUnitOfMeasureId = '')
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = @PurchaseUnitOfMeasureId
					WHERE FieldName = 'StockUnitOfMeasureId';
				END
				IF(@ConsumeUnitOfMeasureId IS NULL OR @ConsumeUnitOfMeasureId = '')
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = @PurchaseUnitOfMeasureId
					WHERE FieldName = 'ConsumeUnitOfMeasureId';
				END
			END
			IF(@ModuleId = @POROCategory)
			BEGIN
				UPDATE #ImportFields
				SET FieldValue =
					CASE
						WHEN LOWER(LTRIM(RTRIM(FieldValue))) IN (SELECT Value FROM @YesValues) THEN '1'
						ELSE '0'
					END
				WHERE FieldName IN ('IsPo', 'IsRo');
			END
			DECLARE @IsDefault VARCHAR(50);
			declare @FieldModuleID bigint;
		SELECT @IsDefault = FieldValue 	FROM #ImportFields 	WHERE FieldName = 'IsDefault';
		SET @FieldModuleID = (select FieldValue from #ImportFields  where FieldName = 'ModuleID')
			IF(@ModuleId = @DefaultMessageModule)
			BEGIN

			    IF (LOWER(LTRIM(RTRIM(ISNULL(@IsDefault, '')))) IN (SELECT Value FROM @YesValues))
			    BEGIN
			        UPDATE DefaultMessage
			        SET IsDefault = 0
			        WHERE IsDefault = 1
			          AND ModuleID = @FieldModuleID
			          AND MasterCompanyId = @MasterCompanyId;
			    END
				UPDATE #ImportFields
				SET FieldValue = CASE
									WHEN LOWER(LTRIM(RTRIM(ISNULL(FieldValue, '')))) IN (SELECT Value FROM @YesValues) THEN '1'
									ELSE '0'
								 END
				WHERE FieldName = 'IsDefault';
			END
			IF(@ModuleId = @EmployeeExpertiseModule)
			BEGIN
				UPDATE #ImportFields
				SET FieldValue =
					CASE
						WHEN LOWER(LTRIM(RTRIM(FieldValue))) IN (SELECT Value FROM @YesValues) THEN '1'
						ELSE '0'
					END
				WHERE FieldName = 'IsWorksInShop';
			END
			IF(@ModuleId = @WorkOrderStageModule)
			BEGIN
				UPDATE #ImportFields
				SET FieldValue =
					CASE
						WHEN LOWER(LTRIM(RTRIM(FieldValue))) IN (SELECT Value FROM @YesValues) THEN '1'
						ELSE '0'
					END
				WHERE FieldName in ( 'IsCustAlerts', 'IncludeInDashboard', 'IncludeInStageReport', 'WorkableBacklog', 'IncludeInTAT', 'QuoteDays', 'ShippedDays','ApprovedDays' )
			END
			IF(@ModuleId = @CommonTeardownTypeModule)
			BEGIN
				UPDATE #ImportFields
				SET FieldValue =
					CASE
						WHEN LOWER(LTRIM(RTRIM(FieldValue))) IN (SELECT Value FROM @YesValues) THEN '1'
						ELSE '0'
					END
				WHERE FieldName in ( 'IsDocument', 'IsInspectorDate', 'IsInspector', 'IsDate', 'IsTechnician' )
			END
		    IF (@ModuleId = @LocationModule)
			BEGIN
				SELECT @SiteName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'SiteId';
				SELECT @WarehouseId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'WarehouseId';

				UPDATE #ImportFields
				SET FieldValue = @WarehouseId
				WHERE FieldName = 'WarehouseId'

				delete #ImportFields where FieldName = 'SiteId'
				delete #DynamicKeyValue where FieldName = 'SiteId'
			END
			IF (@ModuleId = @ShelfModule)
			BEGIN
				delete #ImportFields where FieldName = 'SiteId'
				delete #ImportFields where FieldName ='WarehouseId'
				delete #DynamicKeyValue where FieldName = 'WarehouseId'
				delete #DynamicKeyValue where FieldName = 'SiteId'
			END
			IF (@ModuleId = @BinModule)
			BEGIN
				delete #ImportFields where FieldName = 'SiteId'
				delete #ImportFields where FieldName ='WarehouseId'
				delete #ImportFields where FieldName = 'LocationId'
				delete #DynamicKeyValue where FieldName = 'SiteId'
				delete #DynamicKeyValue where FieldName ='WarehouseId'
				delete #DynamicKeyValue where FieldName = 'LocationId'
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
						WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
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
			UPDATE #ImportFields SET FieldValue = GETDATE() WHERE FieldName = 'ReceivedDate' AND ISNULL(FieldValue,'') = '';

			-----parent table insert Start-----

			IF(ISNULL(@ModuleParentTable, '') != '')
			BEGIN
				-- Default Address Line1 if not provided
				IF @ModuleParentTable = 'Address'
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = ISNULL(NULLIF(LTRIM(RTRIM([FieldValue])), ''), 'N/A')
					WHERE [FieldName] = 'Line1'
					  AND ISNULL(LTRIM(RTRIM(FieldValue)), '') = '';
				END
				SET @RefFieldName = '' -- reset for parent
				SET @FieldValue = ''   -- reset for parent

				-- Add FK reference to main record
				--SET @RefFieldName = @ReferenceColumnName -- FK field for parent
				--SET @FieldValue = CAST(@ModuleTableId AS VARCHAR) + ','
				-- Add fields where IsModuleTableColumn is NULL or something specific for parent (adjust condition if needed)
				SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 0 AND  ParentTable = @ModuleParentTable;
				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE  'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 0 AND  ParentTable = @ModuleParentTable
				-- Add audit trail
				SET @RefFieldName += ', MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += CAST(@MasterCompanyId AS VARCHAR) + ',''' + @UserName + ''',''' + @UserName + ''''
				SET @RefFieldName = ISNULL(STUFF(@RefFieldName, CHARINDEX(',', @RefFieldName), 1, ''), '')
				-- Final dynamic insert
				SET @RefQuery = 'INSERT INTO [' + @ModuleParentTable + '] (' + @RefFieldName + ') VALUES (' + @FieldValue + ');'+ ' SET @ParentModuleTableId = SCOPE_IDENTITY()';

				EXEC sp_executesql @RefQuery, N'@ParentModuleTableId BIGINT OUTPUT',@ParentModuleTableId OUTPUT;
				--EXEC (@RefQuery)
			END
			-----parent table insert End-----
			SET @FieldValue = '';
			SET @RefFieldName = '';
			SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 1;
			IF(@ModuleId = @PriceMasterModule OR @ModuleId = @PurchaseSalesModule)
			BEGIN
				UPDATE #DynamicKeyValue	SET FieldValue = 'Flat'	WHERE FieldName = 'SalePriceSelectName'  AND ISNULL(LTRIM(RTRIM(FieldValue)), '') = '';
				DECLARE @PP_UnitPurchasePrice DECIMAL(10,2) = 0;
				IF(@PP_UnitPurchasePrice = 0)
				BEGIN
					DECLARE @PP_VendorListPrice VARCHAR(20) = CASE WHEN (SELECT ISNULL(FieldValue,0) FROM #DynamicKeyValue WHERE FieldName = 'PP_VendorListPrice') = '' THEN '0' ELSE (SELECT ISNULL(FieldValue,0) FROM #DynamicKeyValue WHERE FieldName = 'PP_VendorListPrice') END;
					UPDATE #ImportFields SET FieldValue = @PP_VendorListPrice WHERE FieldName = 'PP_UnitPurchasePrice'
				END
				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number'  THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number'  THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 1

			END
			ELSE IF(@ModuleId = @CustomerModule)
			BEGIN
			SELECT @IsAddressForBilling = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForBilling';
			SELECT @IsAddressForShipping = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForShipping';
			IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @YesValues) OR @IsAddressForBilling = ''
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '1'  -- Set isAddressForBilling to 1
					WHERE FieldName = 'isAddressForBilling';
				END
				ELSE IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '0'  -- Set isAddressForBilling to 0
					WHERE FieldName = 'isAddressForBilling';
				END

				IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @YesValues) OR @IsAddressForShipping = ''
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '1'  -- Set isAddressForShipping to 1
					WHERE FieldName = 'isAddressForShipping';
				END
				ELSE IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '0'  -- Set isAddressForShipping to 0
					WHERE FieldName = 'isAddressForShipping';
				END

				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number'  THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number'  THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 1

			END
			ELSE IF(@ModuleId = @VendorModule)
			BEGIN
			SELECT @IsAddressForBilling = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForBilling';
			SELECT @IsAddressForShipping = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForShipping';
			IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @YesValues) OR @IsAddressForBilling = ''
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '1'  -- Set isAddressForBilling to 1
					WHERE FieldName = 'isAddressForBilling';
				END
				ELSE IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '0'  -- Set isAddressForBilling to 0
					WHERE FieldName = 'isAddressForBilling';
				END

				IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @YesValues) OR @IsAddressForShipping = ''
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '1'  -- Set isAddressForShipping to 1
					WHERE FieldName = 'isAddressForShipping';
				END
				ELSE IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #ImportFields
					SET FieldValue = '0'  -- Set isAddressForShipping to 0
					WHERE FieldName = 'isAddressForShipping';
				END

				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number'  THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number'  THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 1

			END
			ELSE IF  (@ModuleId = @MROPriceMasterModule OR @ModuleId = @MROPriceMasterListModule)
			BEGIN
			SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','  ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(REPLACE(FieldValue, ',', ''),'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(REPLACE(FieldValue, ',', ''),'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 1
			END
			ELSE
			BEGIN
					SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 1
			END

			IF(@ModuleId = @AlterModule)
			BEGIN
				SET @RefFieldName += ' , MappingType, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += '1, '
			END
			ELSE IF(@ModuleId = @ItemMasterModule)
			BEGIN
				DECLARE @DefaultGLId varchar (100) = 	(SELECT TOP 1 GLAccountId FROM DBO.GLACCOUNT WITH(NOLOCK) WHERE MasterCompanyId =@MasterCompanyId AND ISNULL(ISDELETED,0) = 0 AND ISNULL(ISACTIVE,0) = 1)
				--SET @RefFieldName += ' , ItemTypeId,IsHazardousMaterial,IsExpirationDateAvailable,IsReceivedDateAvailable,DaysReceived,IsManufacturingDateAvailable,
				--ManufacturingDays,IsTagDateAvailable,TagDays,IsOpenDateAvailable,OpenDays,IsShippedDateAvailable,ShippedDays,IsOtherDateAvailable,
				--OtherDays,IsSchematic,OverhaulHours,RPHours,TestHours,RFQTracking,GLAccountId,LeadTimeDays,ReorderPoint,ReorderQuantiy,MinimumOrderQuantity,
				--TurnTimeOverhaulHours,TurnTimeRepairHours,isTimeLife,isSerialized,ShelfLife,StockLevel,ShelfLifeAvailable,mfgHours,turnTimeMfg,turnTimeBenchTest,
				--ItemMasterAssetTypeId,IsHotItem,IsAcquiredMethodBuy,MTBUR,NE,NS,OH,REP,SVC,MasterCompanyId,CreatedBy, UpdatedBy'
				--SET @FieldValue += '1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,13,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, '
				SET @RefFieldName += ' ,ItemTypeId, IsReceivedDateAvailable, DaysReceived, IsManufacturingDateAvailable, ManufacturingDays,
										IsTagDateAvailable, TagDays, IsOpenDateAvailable, OpenDays, IsShippedDateAvailable,
										ShippedDays, IsOtherDateAvailable, OtherDays, IsSchematic, OverhaulHours,
										RPHours, TestHours, GLAccountId,
										TurnTimeOverhaulHours, TurnTimeRepairHours, ShelfLife,
										ShelfLifeAvailable, mfgHours, turnTimeMfg, turnTimeBenchTest,
										IsAcquiredMethodBuy, NE, NS, OH,
										REP, SVC, CreatedDate, UpdatedDate, WorkOrderFormTypeId, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += '1, 0, 0, 0, 0,
									0, 0, 0, 0, 0,
									0, 0, 0, 0, 0,
									0, 0, '+@DefaultGLId+',
									0, 0, 0,
									0, 0, 0, 0,
									0, 0, 0, 0,
									0, 0, @UtcNow, @UtcNow, 3,'
			END
			ELSE IF(@ModuleId = @ItemMasterNonStockModule)
			BEGIN
				DECLARE @NonStockCurrencyId VARCHAR(50) = (SELECT TOP 1 FieldValue FROM #DynamicKeyValue WHERE FieldName = 'CurrencyId');
				IF (ISNULL(@NonStockCurrencyId, '') = '')
				BEGIN
					-- PurchaseCurrencyId/SalesCurrencyId are NOT NULL with no default: fall back to the
					-- company's first active currency when Purchase Currency is left blank (it's optional).
					SET @NonStockCurrencyId = CAST(ISNULL((SELECT TOP 1 CurrencyId FROM DBO.Currency WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1), 0) AS VARCHAR(50));
				END

				-- GL/accounting details are never asked from the user; derive them from the
				-- "Default Non-Stock Inventory GL Setting" record, same as manual Non-Stock item creation.
				DECLARE @NSInventoryGLSettingId BIGINT = (
					SELECT TOP 1 InventoryGLSettingId FROM DBO.InventoryGLSetting WITH(NOLOCK)
					WHERE ISNULL(IsStock, 1) = 0 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1
					  AND MasterCompanyId = @MasterCompanyId
					  AND StockInventoryName = 'Default Non-Stock Inventory GL Setting'
				);
				DECLARE @NSGLAccountId VARCHAR(20) = 'NULL', @NSGoodsReceivedNotInvoicesGLAccId VARCHAR(20) = 'NULL', @NSWorkInProgressGLAccId VARCHAR(20) = 'NULL',
						@NSInventoryToBillGLAccId VARCHAR(20) = 'NULL', @NSFinishedGoodsGLAccId VARCHAR(20) = 'NULL', @NSInventoryExchAgreementGLAccId VARCHAR(20) = 'NULL',
						@NSInventoryReserveGLAccId VARCHAR(20) = 'NULL', @NSCOGS_WorkOrderGLAccId VARCHAR(20) = 'NULL', @NSCOGS_SalesOrderGLAccId VARCHAR(20) = 'NULL',
						@NSCOGS_QtyVarianceGLAccId VARCHAR(20) = 'NULL', @NSCOGS_UnitCostVarianceGLAccId VARCHAR(20) = 'NULL', @NSRevenueMroGLAccId VARCHAR(20) = 'NULL',
						@NSRevenueSoGLAccId VARCHAR(20) = 'NULL', @NSRevenueExchGLAccId VARCHAR(20) = 'NULL', @NSCOGS_ExchSalesOrderGLAccId VARCHAR(20) = 'NULL',
						@NSInventoryGLSettingIdStr VARCHAR(20) = 'NULL';

				IF (@NSInventoryGLSettingId IS NOT NULL)
				BEGIN
					SET @NSInventoryGLSettingIdStr = CAST(@NSInventoryGLSettingId AS VARCHAR(20));
					SELECT
						@NSGLAccountId = ISNULL(CAST(InventoryGLAccId AS VARCHAR(20)), 'NULL'),
						@NSGoodsReceivedNotInvoicesGLAccId = ISNULL(CAST(GoodsReceivedNotInvoicesGLAccId AS VARCHAR(20)), 'NULL'),
						@NSWorkInProgressGLAccId = ISNULL(CAST(WorkInProgressGLAccId AS VARCHAR(20)), 'NULL'),
						@NSInventoryToBillGLAccId = ISNULL(CAST(InventoryToBillGLAccId AS VARCHAR(20)), 'NULL'),
						@NSFinishedGoodsGLAccId = ISNULL(CAST(FinishedGoodsGLAccId AS VARCHAR(20)), 'NULL'),
						@NSInventoryExchAgreementGLAccId = ISNULL(CAST(InventoryExchAgreementGLAccId AS VARCHAR(20)), 'NULL'),
						@NSInventoryReserveGLAccId = ISNULL(CAST(InventoryReserveGLAccId AS VARCHAR(20)), 'NULL'),
						@NSCOGS_WorkOrderGLAccId = ISNULL(CAST(COGS_WorkOrderGLAccId AS VARCHAR(20)), 'NULL'),
						@NSCOGS_SalesOrderGLAccId = ISNULL(CAST(COGS_SalesOrderGLAccId AS VARCHAR(20)), 'NULL'),
						@NSCOGS_QtyVarianceGLAccId = ISNULL(CAST(COGS_QtyVarianceGLAccId AS VARCHAR(20)), 'NULL'),
						@NSCOGS_UnitCostVarianceGLAccId = ISNULL(CAST(COGS_UnitCostVarianceGLAccId AS VARCHAR(20)), 'NULL'),
						@NSRevenueMroGLAccId = ISNULL(CAST(RevenueMroGLAccId AS VARCHAR(20)), 'NULL'),
						@NSRevenueSoGLAccId = ISNULL(CAST(RevenueSoGLAccId AS VARCHAR(20)), 'NULL'),
						@NSRevenueExchGLAccId = ISNULL(CAST(RevenueExchGLAccId AS VARCHAR(20)), 'NULL'),
						@NSCOGS_ExchSalesOrderGLAccId = ISNULL(CAST(COGS_ExchSalesOrderGLAccId AS VARCHAR(20)), 'NULL')
					FROM DBO.InventoryGLSetting WITH(NOLOCK)
					WHERE InventoryGLSettingId = @NSInventoryGLSettingId;
				END

				-- GLAccountId has no default and is NOT NULL: fall back to the company's first active GL
				-- account if the Non-Stock default GL setting hasn't been configured for this company.
				IF (@NSGLAccountId = 'NULL')
				BEGIN
					SET @NSGLAccountId = ISNULL((SELECT TOP 1 CAST(GLAccountId AS VARCHAR(20)) FROM DBO.GLAccount WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1), 'NULL');
				END

				DECLARE @NSItemClassificationId VARCHAR(50) = (SELECT TOP 1 FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ItemNonStockClassificationId');
				SET @NSItemClassificationId = CASE WHEN ISNULL(@NSItemClassificationId, '') = '' THEN '0' ELSE @NSItemClassificationId END;

				SET @RefFieldName += ' ,ItemTypeId, IsNonStock, ItemClassificationId, IsReceivedDateAvailable, DaysReceived, IsManufacturingDateAvailable, ManufacturingDays,
										IsTagDateAvailable, TagDays, IsOpenDateAvailable, OpenDays, IsShippedDateAvailable,
										ShippedDays, IsOtherDateAvailable, OtherDays, IsSchematic, OverhaulHours,
										RPHours, TestHours,
										TurnTimeOverhaulHours, TurnTimeRepairHours, ShelfLife,
										ShelfLifeAvailable, mfgHours, turnTimeMfg, turnTimeBenchTest,
										NE, NS, OH,
										REP, SVC, PurchaseCurrencyId, SalesCurrencyId,
										InventoryGLSettingId, GLAccountId, GoodsReceivedNotInvoicesGLAccId, WorkInProgressGLAccId, InventoryToBillGLAccId, FinishedGoodsGLAccId,
										InventoryExchAgreementGLAccId, InventoryReserveGLAccId, COGS_WorkOrderGLAccId, COGS_SalesOrderGLAccId, COGS_QtyVarianceGLAccId,
										COGS_UnitCostVarianceGLAccId, RevenueMroGLAccId, RevenueSoGLAccId, RevenueExchGLAccId, COGS_ExchSalesOrderGLAccId,
										CreatedDate, UpdatedDate, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += '2, 1, '+@NSItemClassificationId+', 0, 0, 0, 0,
									0, 0, 0, 0, 0,
									0, 0, 0, 0, 0,
									0, 0,
									0, 0, 0,
									0, 0, 0, 0,
									0, 0, 0,
									0, 0, '+@NonStockCurrencyId+', '+@NonStockCurrencyId+',
									'+@NSInventoryGLSettingIdStr+', '+@NSGLAccountId+', '+@NSGoodsReceivedNotInvoicesGLAccId+', '+@NSWorkInProgressGLAccId+', '+@NSInventoryToBillGLAccId+', '+@NSFinishedGoodsGLAccId+',
									'+@NSInventoryExchAgreementGLAccId+', '+@NSInventoryReserveGLAccId+', '+@NSCOGS_WorkOrderGLAccId+', '+@NSCOGS_SalesOrderGLAccId+', '+@NSCOGS_QtyVarianceGLAccId+',
									'+@NSCOGS_UnitCostVarianceGLAccId+', '+@NSRevenueMroGLAccId+', '+@NSRevenueSoGLAccId+', '+@NSRevenueExchGLAccId+', '+@NSCOGS_ExchSalesOrderGLAccId+',
									GETUTCDATE(), GETUTCDATE(),'
			END
			ELSE IF(@ModuleId = @StocklineModule)
			BEGIN

				DECLARE @OtherModuleTypeId BIGINT = (select ModuleId from dbo.Module WITH (NOLOCK) where ModuleName = 'Others');
				SET @RefFieldName += ' , PartNumber,Quantity,QuantityAvailable,PurchaseUnitOfMeasureId,ManagementStructureId,QuantityReserved,QuantityTurnIn,QuantityIssued,QuantityToReceive,PurchaseOrderUnitCost,RepairOrderUnitCost,RepairOrderExtendedCost,WorkOrderExtendedCost,ParentId,StockLineNumber,ControlNumber,IdNumber,ObtainFromType,OwnerType,TraceableToType,MasterCompanyId,CreatedBy,UpdatedBy'
				SET @FieldValue += ''''','+ CAST(@Qty AS VARCHAR(50)) +','+ CAST(@Qty AS VARCHAR(50)) +','+ CAST(@PurchaseUOMId AS VARCHAR(50)) +','+ CAST(@ManagementStructureId AS VARCHAR(50)) +',0,0,0,0,0,0,0,0,0,'+
				 '''' + CAST(@StockLineNumber AS VARCHAR(50)) + ''',' +
				'''' + CAST(@ControlNumber AS VARCHAR(50)) + ''',' +
				'''' + CAST(@IDNumber AS VARCHAR(50)) + ''','+
				CAST(@OtherModuleTypeId AS VARCHAR(50)) +','+
				CAST(@OtherModuleTypeId AS VARCHAR(50)) +','+
				CAST(@OtherModuleTypeId AS VARCHAR(50)) +','

			END
			ELSE IF(@ModuleId = @CustomerModule)
			BEGIN
				/*************** Prefixes ***************/
				-- Declare variables
				DECLARE @CustomerCodePrefix INT, @CustomerNum NVARCHAR(100);
				DECLARE @cCodePrefix NVARCHAR(50), @cCodeSuffix NVARCHAR(50);

				SET @CurrentNo = 0;
				-- Code Types Of CodePrefix
				SELECT @CustomerCodePrefix = [CodeTypeId] FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Customer';
				SELECT TOP 1 @cCodePrefix = [CodePrefix], @cCodeSuffix = [CodeSufix] FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @CustomerCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				IF (@cCodePrefix IS NOT NULL AND @cCodePrefix <> '')
				BEGIN
					SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @cCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					IF (@CurrentNo > 0)
					BEGIN
						SET @CurrentNo = @CurrentNo + 1;
						UPDATE [DBO].[CodePrefixes]
						SET [CurrentNummber] = @CurrentNo
						WHERE [CodePrefix] = @cCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					END
					ELSE
					BEGIN
						SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @cCodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
						UPDATE [DBO].[CodePrefixes]
						SET [CurrentNummber] = @CurrentNo
						WHERE [CodePrefix] = @cCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					END
					-- Generate Customer Number
					SET @CustomerNum = (SELECT * FROM DBO.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@cCodePrefix,''),ISNULL(@cCodeSuffix, '')))
				END
				ELSE
				BEGIN
					-- Generate Customer Number
					SET @CustomerNum = (SELECT * FROM DBO.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
				END
			/*****************End Prefixes*******************/
				DECLARE @CustomerCode VARCHAR(120) = 'C-NEW';
				--SET @RefFieldName += ' , CustomerCode,IsParent,AddressId,IsAddressForBilling,IsAddressForShipping,IsCustomerAlsoVendor,IsPBHCustomer,RestrictPMA,RestrictDER,
				--IsCRMCustomer,Ismiscellaneous,MasterCompanyId,CreatedBy, UpdatedBy'
				--SET @FieldValue += '''' + @CustomerCode + ''', 0, ' + CAST(@ParentModuleTableId AS VARCHAR(20)) + ', 1, 1, 0, 0, 1, 1, 0, 0, ';
				SET @RefFieldName += ' , CustomerCode,IsParent,AddressId,IsCustomerAlsoVendor,IsPBHCustomer,RestrictPMA,RestrictDER,
				IsCRMCustomer,Ismiscellaneous,MasterCompanyId,CreatedBy, UpdatedBy'
				SET @FieldValue += '''' + @CustomerNum + ''', 0, ' + CAST(@ParentModuleTableId AS VARCHAR(20)) + ', 0, 0, 1, 1, 0, 0, ';
			END
			ELSE IF(@ModuleId = @VendorModule)
			BEGIN
				/*************** Prefixes ***************/
					-- Declare variables
					DECLARE @VendorCodePrefix INT, @VendorNum NVARCHAR(100);
					DECLARE @vCodePrefix NVARCHAR(50), @vCodeSuffix NVARCHAR(50);

					SET @CurrentNo = 0;
					-- Code Types Of CodePrefix
					SELECT @VendorCodePrefix = [CodeTypeId] FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Vendor';
					SELECT TOP 1 @vCodePrefix = [CodePrefix], @vCodeSuffix = [CodeSufix] FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @VendorCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					IF (@vCodePrefix IS NOT NULL AND @vCodePrefix <> '')
					BEGIN
						SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @vCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
						IF (@CurrentNo > 0)
						BEGIN
							SET @CurrentNo = @CurrentNo + 1;
							UPDATE [DBO].[CodePrefixes]
							SET [CurrentNummber] = @CurrentNo
							WHERE [CodePrefix] = @vCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
						END
						ELSE
						BEGIN
							SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @vCodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
							UPDATE [DBO].[CodePrefixes]
							SET [CurrentNummber] = @CurrentNo
							WHERE [CodePrefix] = @vCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
						END
						-- Generate Vendor Number
						SET @VendorNum = (SELECT * FROM DBO.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@vCodePrefix,''),ISNULL(@vCodeSuffix, '')))
					END
					ELSE
					BEGIN
						-- Generate Vendor Number
						SET @VendorNum = (SELECT * FROM DBO.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
					END
				/*****************End Prefixes*******************/
				--DECLARE @VendorCode VARCHAR(120) = 'Creating';
				--SET @RefFieldName += ' , VendorCode,IsParent,AddressId,IsAddressForBilling,IsAddressForShipping,IsVendorAlsoCustomer,IsAllowNettingAPAR,IsPreferredVendor,IsCertified,
				--VendorAudit,EDI,AeroExchange,Is1099Required,IsAllow,IsWarning,IsRestrict,IsWarningRestriction,MasterCompanyId,CreatedBy, UpdatedBy'
				--SET @FieldValue += '''' + @VendorCode + ''', 0, ' + CAST(@ParentModuleTableId AS VARCHAR(20)) + ', 1, 1, 0, 0, 0, 0, 0, 0,0,0,1,0,0,0, ';
				SET @RefFieldName += ' , VendorCode,IsParent,AddressId,IsVendorAlsoCustomer,IsAllowNettingAPAR,IsPreferredVendor,IsCertified,
				VendorAudit,EDI,AeroExchange,Is1099Required,IsAllow,IsWarning,IsRestrict,IsWarningRestriction,MasterCompanyId,CreatedBy, UpdatedBy'
				SET @FieldValue += '''' + @VendorNum + ''', 0, ' + CAST(@ParentModuleTableId AS VARCHAR(20)) + ', 0, 0, 0, 0, 0, 0,0,0,1,0,0,0, ';
			END
			ELSE IF(@ModuleId = @SiteModule)
			BEGIN
				SET @RefFieldName += ' , AddressId, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += '' + CAST(@ParentModuleTableId AS VARCHAR(20)) + ',';
			END
			ELSE IF(@ModuleId = @PublicationModule)
			BEGIN
				SET @RefFieldName += ' , Description, EntryDate, CreatedDate, UpdatedDate, EmployeeId, VerifiedStatus, Sequence, PublishedById, PublishedByRefId, PublishedByOthers, ManagementStructureIds, MasterCompanyId, CreatedBy, UpdatedBy ';
				SET @FieldValue   += ''''', @GetDate, @UtcNow, @UtcNow, @EmployeeId, 0, 1, 4, 0, ''Others'', ' + CAST(@PublicationMSId AS VARCHAR(50)) + ',';
			END
			ELSE IF(@ModuleId = @PriceMasterModule OR @ModuleId = @PurchaseSalesModule)
			BEGIN
				DECLARE @SP_FSP_UOMId BIGINT = (SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'PP_UOMId')
				DECLARE @SP_FSP_CurrencyId BIGINT = (SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'PP_CurrencyId');
				SET @SP_CalSPByPP_MarkUpPercOnListPriceValue = (SELECT ISNULL(TRY_CAST(NULLIF(FieldValue, '') AS DECIMAL(18,2)), 0) FROM #DynamicKeyValue WHERE FieldName = 'SP_CalSPByPP_MarkUpPercOnListPrice');

				--IF @SP_CalSPByPP_MarkUpPercOnListPriceValue > 0
				--BEGIN
				--	SET @SP_CalSPByPP_MarkUpPercOnListPrice =(SELECT TOP 1 PercentId FROM DBO.[Percent] WITH(NOLOCK) WHERE PercentValue = CAST(@SP_CalSPByPP_MarkUpPercOnListPrice as DECIMAL(10,2)) AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1)
				--	Update #DynamicKeyValue  SET FieldValue = @SP_CalSPByPP_MarkUpPercOnListPrice WHERE FieldName = 'SP_CalSPByPP_MarkUpPercOnListPrice';
				--END
				--DECLARE @SP_FSP_FlatPriceAmount DECIMAL(10,2) = CASE WHEN (SELECT ISNULL(FieldValue,0) FROM #DynamicKeyValue WHERE FieldName = 'SP_CalSPByPP_UnitSalePrice') = '' THEN '0' ELSE (SELECT ISNULL(FieldValue,0) FROM #DynamicKeyValue WHERE FieldName = 'SP_CalSPByPP_UnitSalePrice') END;
				--SET @SalePriceSelectId = (CASE WHEN (SELECT ISNULL(FieldValue,0) FROM #DynamicKeyValue WHERE FieldName = 'SalePriceSelectName') = 'Flat' THEN '1' WHEN (SELECT ISNULL(FieldValue,0) FROM #DynamicKeyValue WHERE FieldName = 'SalePriceSelectName') = 'Calculated' THEN '2' ELSE '0' END);
				SET @SalePriceSelectId = (CASE
				WHEN LOWER((SELECT ISNULL(FieldValue,'') FROM #DynamicKeyValue WHERE FieldName = 'SalePriceSelectName')) = 'flat' THEN '1'
				WHEN LOWER((SELECT ISNULL(FieldValue,'') FROM #DynamicKeyValue WHERE FieldName = 'SalePriceSelectName')) = 'calculated' THEN '2'
				ELSE '0' END);
				DECLARE @PC_ConditionId BIGINT = (SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ConditionId');
				SET @ItemMasterId = (SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ItemMasterId')
				SELECT TOP 1 @PartNumber =  ISNULL(partnumber,'') FROM ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId
				 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
				SET @ItemMasterPurchaseSaleId = ISNULL((SELECT TOP  1 ItemMasterPurchaseSaleId FROM dbo.ItemMasterPurchaseSale WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @PC_ConditionId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0),0)
				SET @isPriceDataExist = (CASE WHEN @ItemMasterPurchaseSaleId > 0 THEN 1 ELSE 0 END);
				SET @RefFieldName += ' , PartNumber,IsActive, IsDeleted,SP_CalSPByPP_SaleDiscAmount,SP_CalSPByPP_BaseSalePrice,PP_PurchaseDiscAmount,SP_FSP_FXRatePerc, PP_FXRatePerc,PP_LastListPriceDate,PP_LastPurchaseDiscDate, CreatedDate, UpdatedDate,SP_FSP_UOMId,SP_FSP_CurrencyId,SalePriceSelectId,SP_FSP_LastFlatPriceDate, MasterCompanyId, CreatedBy, UpdatedBy ';
				SET @FieldValue += '''' + @PartNumber + ''',1,0,0,0,0,1.00,1.00, '''
										+ CONVERT(VARCHAR(30), @GetDate, 126) + ''','''
										+ CONVERT(VARCHAR(30), @GetDate, 126) + ''','''
										+ CONVERT(VARCHAR(30), @UtcNow, 126) + ''','''
										+ CONVERT(VARCHAR(30), @UtcNow, 126) + ''','
										+ CAST(@SP_FSP_UOMId AS VARCHAR(50)) + ','
										+ CAST(@SP_FSP_CurrencyId AS VARCHAR(50)) + ','
										+ CAST(@SalePriceSelectId AS VARCHAR(30)) + ','
										+ '''' + CONVERT(VARCHAR(30), @UtcNow, 126) + '''' + ',';
			END
			ELSE IF (@ModuleId = @WorkOrderMaterialsModule)
			BEGIN
			DECLARE @WMItemMasterId BIGINT;
			DECLARE @WMWorkOrderId BIGINT , @WMWorkFlowWorkOrderId BIGINT ;
			DECLARE @WMExtendedCost DECIMAL(18,2);
			SELECT @ItemMasterId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ItemMasterId';
			SELECT @WMWorkOrderId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'WorkOrderId';
			SELECT @WMWorkFlowWorkOrderId = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'WorkFlowWorkOrderId';
			SELECT @WMExtendedCost = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ExtendedCost';

			DECLARE @ItemClassificationId BIGINT;
			DECLARE @UomId BIGINT;
			SELECT TOP 1 @ItemClassificationId = IM.ItemClassificationId,@UomId = IM.PurchaseUnitOfMeasureId FROM dbo.ItemMaster IM WITH(NOLOCK) WHERE IM.ItemMasterId=@ItemMasterId

				 AND ISNULL(IM.IsNonStock,0) = 0
				SET @RefFieldName += ',MaterialMandatoriesId, ItemClassificationId, UnitOfMeasureId,WorkOrderId,WorkFlowWorkOrderId,ExtendedCost,MasterCompanyId, CreatedBy, UpdatedBy';
				SET @FieldValue += '1'+',' + CAST(ISNULL(@ItemClassificationId,0) AS VARCHAR(20)) + ',' + CAST(ISNULL(@UomId,0) AS VARCHAR(20)) + ',' + CAST(ISNULL(@WMWorkOrderId,0) AS VARCHAR(20)) + ',' + CAST(ISNULL(@WMWorkFlowWorkOrderId,0) AS VARCHAR(20)) + ','+ CAST(ISNULL(@WMExtendedCost,0) AS VARCHAR(20)) + ','
			END
			ELSE IF(@ModuleId = @MROPriceMasterModule OR @ModuleId = @MROPriceMasterListModule )
			BEGIN
				DECLARE @MROWhereClause NVARCHAR(MAX) = '';
				DECLARE @MROSQL NVARCHAR(MAX);
				DECLARE @MatchedId BIGINT = NULL;
				DECLARE @MRORefFieldName VARCHAR(MAX) = '';
				SELECT @MRORefFieldName = STRING_AGG(FieldName, ',')
				FROM ImportModuleFieldMaster IMF
				WHERE IMF.ModuleId = @ModuleId
				  AND IMF.FieldName IN ('ItemMasterId', 'CustomerId', 'WorkScopeId', 'MasterCompanyId');
				WITH Fields AS (
					SELECT
						LTRIM(RTRIM(value)) AS FieldName,
						ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
					FROM STRING_SPLIT(@MRORefFieldName, ',')
				),
				Vals AS (
					SELECT
						LTRIM(RTRIM(value)) AS FieldValue,
						ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
					FROM STRING_SPLIT(@FieldValue, ',')
				),
				FieldTypes AS (
					SELECT IMF.FieldName, IMF.FieldType
					FROM ImportModuleFieldMaster IMF
					WHERE IMF.ModuleId = @ModuleId
					  AND IMF.FieldName IN ('ItemMasterId', 'CustomerId', 'WorkScopeId')
				),
				Pairs AS (
					SELECT f.FieldName, v.FieldValue, ft.FieldType
					FROM Fields f
					JOIN Vals v ON f.rn = v.rn
					LEFT JOIN FieldTypes ft ON ft.FieldName = f.FieldName
				)

				SELECT @MROWhereClause = STRING_AGG(
						CASE
							WHEN FieldValue IS NULL OR UPPER(FieldValue) = 'NULL'
								THEN FieldName + ' IS NULL'
							ELSE
								FieldName + ' = ' +
								CASE
									WHEN FieldType = 'string' THEN QUOTENAME(FieldValue, '''')
									WHEN FieldType = 'boolean' THEN CASE WHEN LOWER(FieldValue) IN ('yes', 'y', 'true') THEN '1' ELSE '0' END
									WHEN FieldType IN ('datetime', 'date') THEN
										CASE WHEN ISNULL(FieldValue, '') <> ''
											 THEN 'CONVERT(DATETIME, ' + QUOTENAME(FieldValue, '''') + ', 101)'
											 ELSE 'NULL'
										END
									WHEN FieldType = 'number' THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END
									WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN 'NULL' ELSE FieldValue END
									ELSE QUOTENAME(FieldValue, '''')  -- default to quoting just in case
								END
						END
					, ' AND ')
					+ ' AND isDeleted = 0'
					FROM Pairs;
				SET @MROSQL = '
				BEGIN
					IF EXISTS (SELECT 1 FROM MROPriceMaster WHERE ' + @MROWhereClause + ')
					BEGIN
						SELECT TOP 1 @isExistOut = 1, @matchedIdOut = MROPriceMasterId FROM MROPriceMaster WHERE ' + @MROWhereClause + '
					END
					ELSE
					BEGIN
						SET @isExistOut = 0;
						SET @matchedIdOut = NULL;
					END
				END
				';
				EXEC sp_executesql
					@MROSQL,
					N'@isExistOut BIT OUTPUT, @matchedIdOut BIGINT OUTPUT',
					@isMROPriceDataExist OUTPUT,
					@MatchedId OUTPUT;
			SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'
			END
			ELSE IF(@ModuleId = @EmployeeModule)
			BEGIN
				/*************** Prefixes ***************/
				-- Declare variables
				DECLARE @EmployeeCodePrefix INT, @EmployeeNum NVARCHAR(100);
				DECLARE @CodePrefix NVARCHAR(50), @CodeSuffix NVARCHAR(50);
				DECLARE @Level1Id INT;
				SELECT @Level1Id = Level1Id FROM [DBO].[EntityStructureSetup] WITH(NOLOCK) WHERE [EntityStructureId] = @EmployeeMSId;
				SELECT @LegalEntityId = [LegalEntityId] FROM [DBO].[ManagementStructureLevel] WITH(NOLOCK) WHERE [ID] = @Level1Id;
				SET @CurrentNo = 0;
				-- Code Types Of CodePrefix
				SELECT @EmployeeCodePrefix = [CodeTypeId] FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Employee';
				SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @EmployeeCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				IF (@CodePrefix IS NOT NULL AND @CodePrefix <> '')
				BEGIN
					SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					IF (@CurrentNo > 0)
					BEGIN
						SET @CurrentNo = @CurrentNo + 1;
						UPDATE [DBO].[CodePrefixes]
						SET [CurrentNummber] = @CurrentNo
						WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					END
					ELSE
					BEGIN
						SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
						UPDATE [DBO].[CodePrefixes]
						SET [CurrentNummber] = @CurrentNo
						WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					END
					-- Generate Employee Number
					SET @EmployeeNum = (SELECT * FROM DBO.udfGenerateCodeNumber(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
				END
				ELSE
				BEGIN
					-- Generate Employee Number
					SET @EmployeeNum = (SELECT * FROM DBO.udfGenerateCodeNumber(@CurrentNo, '',''))
				END
			/*****************End Prefixes*******************/
				SET @RefFieldName += ' , EmployeeCode, LegalEntityId, EmployeeExpertiseId, CreatedDate, UpdatedDate, ManagementStructureId, MasterCompanyId, CreatedBy, UpdatedBy ';
				SET @FieldValue += '''' + @EmployeeNum  + '''' + ','  + CAST(@LegalEntityId AS VARCHAR(50)) + ', 0, @UtcNow, @UtcNow,' + CAST(@EmployeeMSId AS VARCHAR(50)) + ' , ';
			END
			ELSE IF(@ModuleId = @LotCostSourceReference)
			BEGIN
				SET @RefFieldName += ' , IsDeleted,IsActive,CreatedDate,UpdatedDate, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += '0,1,GETUTCDATE(),GETUTCDATE(), '
			END
			ELSE IF(@ModuleId = @InventoryGLSettingModule)
			BEGIN
				SET @RefFieldName += ' , CreatedDate,UpdatedDate, MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += 'GETUTCDATE(),GETUTCDATE(), '
			END
			ELSE
			BEGIN
				SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'

			END
			--IF(@ModuleId = @PublicationModule)
			--	BEGIN
			--		SET @RefFieldName += ' ,ManagementStructureId, IsActive, IsDeleted, CreatedDate, UpdatedDate';
			--		SET @FieldValue += CAST(@PublicationMSId AS VARCHAR(50)) + ',1,0,@UtcNow,@UtcNow,';
			--	END
			SET @FieldValue += ' ' + CAST(@MasterCompanyId AS VARCHAR) + ',''' + @UserName + ''',''' + @UserName + ''''
			SET @RefFieldName = ISNULL(STUFF(@RefFieldName, CHARINDEX(',', @RefFieldName), 1, ''), '')
			IF((@ModuleId = @PriceMasterModule  OR @ModuleId = @PurchaseSalesModule) AND @isPriceDataExist = 1 )
			BEGIN
					DECLARE @UpdateFields NVARCHAR(MAX) = '';

					-- Built directly from #ImportFields (one row per field, raw value) rather than by
					-- re-splitting the already-built @FieldValue string on commas: a 'datetime'/'date'
					-- field's value fragment (e.g. CONVERT(VARCHAR(10), CAST(REPLACE('08/30/2026', 'Z', ''), 101))
					-- itself contains commas, which desynced the old STRING_SPLIT-based Fields/Vals row
					-- pairing and produced invalid SQL ("Incorrect syntax near '='") whenever a date field
					-- was present on the update path. The per-row value expression is materialized in the
					-- Vals CTE first (STRING_AGG can't take an argument that itself contains a subquery,
					-- which the 'boolean' branch below needs).
					;WITH Vals AS (
						SELECT
							FieldName,
							CASE
								WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''''
								WHEN FieldType = 'boolean' THEN (CASE WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1' ELSE '0' END)
								WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101)' ELSE 'NULL' END
								WHEN FieldType = 'number' THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END
								WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN 'NULL' ELSE FieldValue END
								ELSE ISNULL(FieldValue, '0')
							END AS ValueExpr
						FROM #ImportFields
						WHERE ISNULL(IsModuleTableColumn, 0) = 1 AND FieldName NOT IN ('CreatedDate','CreatedBy')
					)
					SELECT @UpdateFields = STRING_AGG(FieldName + ' = ' + ValueExpr, ', ') FROM Vals;
					SET @RefQuery = 'UPDATE [' + @ReferenceTable + '] SET ' + @UpdateFields + ' WHERE ItemMasterPurchaseSaleId = ' + CAST(@ItemMasterPurchaseSaleId AS VARCHAR(20)) + ';';
			END
			ELSE IF( (@ModuleId = @MROPriceMasterModule OR @ModuleId = @MROPriceMasterListModule )  AND @isMROPriceDataExist = 1 AND @MatchedId IS NOT NULL)
			BEGIN
						DECLARE @MROUpdateFields NVARCHAR(MAX) = '';
							SELECT @MRORefFieldName = STRING_AGG(FieldName, ',')
						FROM ImportModuleFieldMaster IMF
						WHERE IMF.ModuleId = @ModuleId
						  AND IMF.FieldName IN ('ItemMasterId', 'CustomerId', 'WorkScopeId', 'MasterCompanyId','FlatRatePrice','CurrencyId','EffectiveDate');
								;WITH Fields AS (
									SELECT LTRIM(RTRIM(value)) AS FieldName,
										   ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
									FROM STRING_SPLIT(@RefFieldName, ',')
								),
								Vals AS (
									SELECT LTRIM(RTRIM(value)) AS FieldValue,
										   ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
									FROM STRING_SPLIT(@FieldValue, ',')
								),
								FieldTypes AS (
									SELECT IMF.FieldName, IMF.FieldType
									FROM ImportModuleFieldMaster IMF
									WHERE IMF.ModuleId = @ModuleId
									  AND IMF.FieldName IN (SELECT FieldName FROM Fields)
								),
								Pairs AS (
									SELECT f.FieldName, v.FieldValue, ft.FieldType
									FROM Fields f
									JOIN Vals v ON f.rn = v.rn
									LEFT JOIN FieldTypes ft ON ft.FieldName = f.FieldName
									WHERE f.FieldName NOT IN ('CreatedDate', 'CreatedBy','UpdatedBy')
								)
						SELECT @MROUpdateFields = STRING_AGG(
							FieldName + ' = ' +
							CASE
								WHEN FieldValue IS NULL OR UPPER(FieldValue) = 'NULL' THEN 'NULL'
								ELSE
									CASE
										WHEN FieldType = 'string' THEN QUOTENAME(FieldValue, '''')
										WHEN FieldType = 'boolean' THEN CASE WHEN LOWER(FieldValue) IN ('yes', 'y', 'true') THEN '1' ELSE '0' END
										WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(' + FieldValue + ', ''Z'', '''') AS DATETIME), 101)' ELSE 'NULL,' END
										WHEN FieldType = 'number' THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN '0' ELSE FieldValue END
										WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue, '') = '' THEN 'NULL' ELSE FieldValue END
										ELSE QUOTENAME(FieldValue, '''')
									END
							END
						, ', ')
						FROM Pairs;
						--SET @RefQuery = 'UPDATE ' + @ReferenceTable + ' SET ' + @MROUpdateFields + ' WHERE MROPriceMasterId = ' + CAST(@MatchedId AS bigint) + ';';
							BEGIN
								SET @RefQuery = 'UPDATE [' + @ReferenceTable + '] SET ' + @MROUpdateFields + ' WHERE MROPriceMasterId = ' + CAST(@MatchedId AS varchar(20)) + ';';
							END
					END

			ELSE
			BEGIN
				SET @RefQuery = 'INSERT INTO [' + @ReferenceTable + '] (' + @RefFieldName + ' )' + ' VALUES (' + @FieldValue + ');' + ' SET @ModuleTableId = SCOPE_IDENTITY()';
			END
			IF(@ModuleId = @PublicationModule)
			BEGIN
				EXEC sp_executesql @RefQuery, N'@GetDate DATE, @UtcNow DATETIME2(7), @EmployeeId BIGINT, @ModuleTableId BIGINT OUTPUT', @GetDate = @GetDate, @UtcNow = @UtcNow, @EmployeeId = @EmployeeId, @ModuleTableId = @ModuleTableId OUTPUT;
			END
			ELSE IF(@ModuleId = @EmployeeModule)
			BEGIN
				EXEC sp_executesql @RefQuery, N'@UtcNow DATETIME2(7), @ModuleTableId BIGINT OUTPUT', @UtcNow = @UtcNow, @ModuleTableId = @ModuleTableId OUTPUT;
			END
			IF(@ModuleId = @ItemMasterModule)
			BEGIN
				EXEC sp_executesql @RefQuery, N'@UtcNow DATETIME2(7), @ModuleTableId BIGINT OUTPUT', @UtcNow = @UtcNow, @ModuleTableId = @ModuleTableId OUTPUT;
			END
			ELSE
			BEGIN
				IF(@ModuleId = @PriceMasterModule  OR @ModuleId = @PurchaseSalesModule)
				BEGIN
					IF(@isPriceDataExist = 1)
					BEGIN
						EXEC sp_executesql @RefQuery
						SET @ModuleTableId = @ItemMasterPurchaseSaleId;
						--exec [dbo].[USP_AddUpdatePriceMasterHistory] @ItemMasterPurchaseSaleId=@ItemMasterPurchaseSaleId,@ModuleId=@ItemMasterModuleId,@MasterCompanyId=@MasterCompanyId,@RefferenceId=@ItemMasterPurchaseSaleId
					END
					ELSE
					BEGIN
						EXEC sp_executesql @RefQuery, N'@ModuleTableId BIGINT OUTPUT', @ModuleTableId OUTPUT;
					END
					DECLARE @PP_DiscPercId BIGINT = (
						SELECT ISNULL(TRY_CAST(NULLIF(FieldValue, '') AS BIGINT), 0)
						FROM #DynamicKeyValue
						WHERE FieldName = 'PP_PurchaseDiscPerc'
					);
					DECLARE @PP_DiscPercValue DECIMAL(18,2) = ISNULL((
						SELECT PercentValue
						FROM DBO.[Percent] WITH(NOLOCK)
						WHERE PercentId = @PP_DiscPercId
						  AND MasterCompanyId = @MasterCompanyId
						  AND ISNULL(IsDeleted,0) = 0
						  AND ISNULL(IsActive,1) = 1
					), 0);
					if(@ModuleTableId > 0)
					BEGIN
					    SET  @SP_CalSPByPP_MarkUpPercOnListPrice = (SELECT TOP 1 PercentValue FROM DBO.[Percent] WITH(NOLOCK) WHERE PercentValue = CAST(@SP_CalSPByPP_MarkUpPercOnListPriceValue as DECIMAL(10,2)) AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1);

						UPDATE DBO.ItemMasterPurchaseSale
							SET PP_PurchaseDiscAmount = CAST((ISNULL(PP_VendorListPrice, 0) * @PP_DiscPercValue / 100.00) AS DECIMAL(18, 2)),
								PP_UnitPurchasePrice  = ISNULL(PP_VendorListPrice,0) - (CAST((ISNULL(PP_VendorListPrice, 0) * @PP_DiscPercValue / 100.00) AS DECIMAL(18, 2))),
								PP_PurchaseDiscPercValue = @PP_DiscPercValue,
								PP_PurchaseDiscPerc = @PP_DiscPercValue,
								SP_CalSPByPP_MarkUpPercOnListPriceValue = @SP_CalSPByPP_MarkUpPercOnListPriceValue,
								SP_CalSPByPP_MarkUpPercOnListPrice = @SP_CalSPByPP_MarkUpPercOnListPrice,
								PP_LastListPriceDate = @employeeGetDate,
								PP_LastPurchaseDiscDate = @employeeGetDate
						WHERE ItemMasterPurchaseSaleId = @ModuleTableId;
						if(@SalePriceSelectId = '1' OR @SalePriceSelectId = 1)
						BEGIN
							UPDATE DBO.ItemMasterPurchaseSale
								SET SP_CalSPByPP_MarkUpPercOnListPrice = 0,SP_CalSPByPP_MarkUpAmount =0,SP_CalSPByPP_MarkUpPercOnListPriceValue=0,SP_CalSPByPP_UnitSalePrice = CASE WHEN ISNULL(SP_FSP_FlatPriceAmount,0) = 0 THEN ISNULL(PP_UnitPurchasePrice,0) ELSE ISNULL(SP_FSP_FlatPriceAmount,0) END
								,SP_CalSPByPP_LastSalesDiscDate = NULL, SP_FSP_LastFlatPriceDate = @employeeGetDate

							WHERE ItemMasterPurchaseSaleId = @ModuleTableId;
						END
						else if (@SalePriceSelectId = '2' OR @SalePriceSelectId = 2)
						BEGIN
							--DECLARE @percentValue DECIMAL(10,2) = ISNULL((SELECT PercentValue FROM DBO.[PERCENT] WITH(NOLOCK) WHERE PercentId = ISNULL((SELECT TOP 1 SP_CalSPByPP_MarkUpPercOnListPrice FROM DBO.ItemMasterPurchaseSale WITH(NOLOCK) WHERE ItemMasterPurchaseSaleId = @ModuleTableId),0) ),0)
							UPDATE DBO.ItemMasterPurchaseSale
								SET SP_CalSPByPP_MarkUpAmount =CAST((ISNULL(PP_UnitPurchasePrice, 0) * ISNULL(@SP_CalSPByPP_MarkUpPercOnListPriceValue, 0) / 100.00) AS DECIMAL(18, 2)),
									SP_CalSPByPP_MarkUpPercOnListPriceValue=@SP_CalSPByPP_MarkUpPercOnListPriceValue,
									SP_CalSPByPP_UnitSalePrice = ISNULL(PP_UnitPurchasePrice, 0) + CAST((ISNULL(PP_UnitPurchasePrice, 0) * ISNULL(@SP_CalSPByPP_MarkUpPercOnListPriceValue, 0) / 100.00) AS DECIMAL(18, 2)),
									SP_FSP_FlatPriceAmount = 0, SP_CalSPByPP_LastSalesDiscDate = @employeeGetDate, SP_FSP_LastFlatPriceDate=NULL
							WHERE ItemMasterPurchaseSaleId = @ModuleTableId;
						END
						ELSE
						BEGIN
							UPDATE DBO.ItemMasterPurchaseSale
								SET SP_CalSPByPP_MarkUpAmount =0,
									SP_CalSPByPP_MarkUpPercOnListPriceValue=0,
									SP_CalSPByPP_UnitSalePrice = 0,
									SP_CalSPByPP_LastSalesDiscDate = NULL, SP_FSP_LastFlatPriceDate=NULL,
									SP_FSP_FlatPriceAmount = 0
							WHERE ItemMasterPurchaseSaleId = @ModuleTableId;
						END
						--exec [dbo].[USP_AddUpdatePriceMasterHistory] @ItemMasterPurchaseSaleId=@ModuleTableId,@ModuleId=@ItemMasterModuleId,@MasterCompanyId=@MasterCompanyId,@RefferenceId=@ModuleTableId
					END

				END
				ELSE
				BEGIN
					EXEC sp_executesql @RefQuery, N'@ModuleTableId BIGINT OUTPUT', @ModuleTableId OUTPUT;
				END
			END

			IF((@ModuleId = @PriceMasterModule OR @ModuleId = @PurchaseSalesModule) AND @ItemMasterId >0 )
			BEGIN
				EXEC UpdateItemMasterPurchaseSaleDetails @ItemMasterId
				exec [dbo].[USP_AddUpdatePriceMasterHistory] @ItemMasterPurchaseSaleId=@ModuleTableId,@ModuleId=@ItemMasterModuleId,@MasterCompanyId=@MasterCompanyId,@RefferenceId=@ModuleTableId
			END

			IF(@ModuleId = @ItemMasterModule)
			BEGIN
				DECLARE @PartSourceVal AS VARCHAR(200);
				SET @PartSourceVal = (select FieldValue from #DynamicKeyValue where FieldName = 'PartSource')
				EXEC [DBO].[usp_UpdateItemMasterWithGLAccountNames] @ModuleTableId, @PartSourceVal, @MasterCompanyId;
				EXEC [DBO].[UpdateItemMasterDetail] @ModuleTableId;
				EXEC [DBO].[QuickBooks_UpdateModuleCountDetails] @MasterCompanyId, @ItemMasterAccountingModuleId;
			END
			IF(@ModuleId = @ItemMasterNonStockModule)
			BEGIN
				EXEC [DBO].[UpdateItemMasterDetail] @ModuleTableId;

				UPDATE IM SET
					GoodsReceivedNotInvoicesGLAccName = CASE WHEN GL2.GLAccountId IS NOT NULL THEN CONCAT(GL2.AccountCode, '-', GL2.AccountName) ELSE NULL END,
					WorkInProgressGLAccName = CASE WHEN GL3.GLAccountId IS NOT NULL THEN CONCAT(GL3.AccountCode, '-', GL3.AccountName) ELSE NULL END,
					InventoryToBillGLAccName = CASE WHEN GL4.GLAccountId IS NOT NULL THEN CONCAT(GL4.AccountCode, '-', GL4.AccountName) ELSE NULL END,
					FinishedGoodsGLAccName = CASE WHEN GL5.GLAccountId IS NOT NULL THEN CONCAT(GL5.AccountCode, '-', GL5.AccountName) ELSE NULL END,
					InventoryExchAgreementGLAccName = CASE WHEN GL6.GLAccountId IS NOT NULL THEN CONCAT(GL6.AccountCode, '-', GL6.AccountName) ELSE NULL END,
					InventoryReserveGLAccName = CASE WHEN GL7.GLAccountId IS NOT NULL THEN CONCAT(GL7.AccountCode, '-', GL7.AccountName) ELSE NULL END,
					COGS_WorkOrderGLAccName = CASE WHEN GL8.GLAccountId IS NOT NULL THEN CONCAT(GL8.AccountCode, '-', GL8.AccountName) ELSE NULL END,
					COGS_SalesOrderGLAccName = CASE WHEN GL9.GLAccountId IS NOT NULL THEN CONCAT(GL9.AccountCode, '-', GL9.AccountName) ELSE NULL END,
					COGS_QtyVarianceGLAccName = CASE WHEN GL10.GLAccountId IS NOT NULL THEN CONCAT(GL10.AccountCode, '-', GL10.AccountName) ELSE NULL END,
					COGS_UnitCostVarianceGLAccName = CASE WHEN GL11.GLAccountId IS NOT NULL THEN CONCAT(GL11.AccountCode, '-', GL11.AccountName) ELSE NULL END,
					RevenueMroGLAccName = CASE WHEN GL12.GLAccountId IS NOT NULL THEN CONCAT(GL12.AccountCode, '-', GL12.AccountName) ELSE NULL END,
					RevenueSoGLAccName = CASE WHEN GL13.GLAccountId IS NOT NULL THEN CONCAT(GL13.AccountCode, '-', GL13.AccountName) ELSE NULL END,
					RevenueExchGLAccName = CASE WHEN GL14.GLAccountId IS NOT NULL THEN CONCAT(GL14.AccountCode, '-', GL14.AccountName) ELSE NULL END,
					COGS_ExchSalesOrderGLAccName = CASE WHEN GL15.GLAccountId IS NOT NULL THEN CONCAT(GL15.AccountCode, '-', GL15.AccountName) ELSE NULL END
				FROM DBO.ItemMaster IM
				LEFT JOIN DBO.GLAccount GL2 WITH(NOLOCK) ON GL2.GLAccountId = IM.GoodsReceivedNotInvoicesGLAccId
				LEFT JOIN DBO.GLAccount GL3 WITH(NOLOCK) ON GL3.GLAccountId = IM.WorkInProgressGLAccId
				LEFT JOIN DBO.GLAccount GL4 WITH(NOLOCK) ON GL4.GLAccountId = IM.InventoryToBillGLAccId
				LEFT JOIN DBO.GLAccount GL5 WITH(NOLOCK) ON GL5.GLAccountId = IM.FinishedGoodsGLAccId
				LEFT JOIN DBO.GLAccount GL6 WITH(NOLOCK) ON GL6.GLAccountId = IM.InventoryExchAgreementGLAccId
				LEFT JOIN DBO.GLAccount GL7 WITH(NOLOCK) ON GL7.GLAccountId = IM.InventoryReserveGLAccId
				LEFT JOIN DBO.GLAccount GL8 WITH(NOLOCK) ON GL8.GLAccountId = IM.COGS_WorkOrderGLAccId
				LEFT JOIN DBO.GLAccount GL9 WITH(NOLOCK) ON GL9.GLAccountId = IM.COGS_SalesOrderGLAccId
				LEFT JOIN DBO.GLAccount GL10 WITH(NOLOCK) ON GL10.GLAccountId = IM.COGS_QtyVarianceGLAccId
				LEFT JOIN DBO.GLAccount GL11 WITH(NOLOCK) ON GL11.GLAccountId = IM.COGS_UnitCostVarianceGLAccId
				LEFT JOIN DBO.GLAccount GL12 WITH(NOLOCK) ON GL12.GLAccountId = IM.RevenueMroGLAccId
				LEFT JOIN DBO.GLAccount GL13 WITH(NOLOCK) ON GL13.GLAccountId = IM.RevenueSoGLAccId
				LEFT JOIN DBO.GLAccount GL14 WITH(NOLOCK) ON GL14.GLAccountId = IM.RevenueExchGLAccId
				LEFT JOIN DBO.GLAccount GL15 WITH(NOLOCK) ON GL15.GLAccountId = IM.COGS_ExchSalesOrderGLAccId
				WHERE IM.ItemMasterId = @ModuleTableId;
			END


			IF(@ModuleId = @StocklineModule)
			BEGIN
				DECLARE @StkManagementStructureModuleId BIGINT = 2;
				DECLARE @ManagementStructureEntityId BIGINT = 0;
				DECLARE @StockLineModuleId BIGINT = (select ModuleId from dbo.Module WITH (NOLOCK) where ModuleName = 'StockLine');
				DECLARE @StocklineHistoryActionId BIGINT = 1;
                SELECT @ManagementStructureEntityId = [ManagementStructureId] FROM DBO.Stockline WITH (NOLOCK) WHERE StocklineId = @ModuleTableId;
				--DECLARE @QuantityOnHand BIGINT = 0;
				DECLARE @QuantityOnHand DECIMAL(18,6) = 0;
				--SET @QuantityOnHand = (select FieldValue from #DynamicKeyValue where FieldName = 'QuantityOnHand')
				SET @QuantityOnHand = TRY_CAST((SELECT FieldValue FROM #DynamicKeyValue WHERE FieldName = 'QuantityOnHand') AS DECIMAL(18,6))
				DECLARE @UpdatedBy AS VARCHAR(200);
				SET @UpdatedBy = (select FieldValue from #DynamicKeyValue where FieldName = 'UpdatedBy')

				EXEC UpdateStocklineColumnsWithId @ModuleTableId;
				EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId, @ModuleTableId, @ManagementStructureEntityId, @MasterCompanyId, @UserName;
				EXEC USP_AddUpdateStocklineHistory @ModuleTableId,@StockLineModuleId,@ModuleTableId, NULL, NULL,@StocklineHistoryActionId,@QuantityOnHand,@UserName;
			END
			IF(@ModuleId = @CustomerModule)
			BEGIN
				DECLARE @CustomerClassificationVal AS VARCHAR(200);
				DECLARE @CustomerAffiliationVal AS VARCHAR(200);

				SET @CustomerClassificationVal = (select FieldValue from #DynamicKeyValue where FieldName = 'CustomerClassificationId')
				SET @CustomerAffiliationVal = (select FieldValue from #DynamicKeyValue where FieldName = 'CustomerAffiliationId')
				SELECT @IsAddressForBilling = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForBilling';
				SELECT @IsAddressForShipping = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForShipping';

				IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @YesValues) OR @IsAddressForBilling = ''
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '1'  -- Set isAddressForBilling to 1
					WHERE FieldName = 'isAddressForBilling';
				END
				ELSE IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '0'  -- Set isAddressForBilling to 0
					WHERE FieldName = 'isAddressForBilling';
				END
				IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @YesValues) OR @IsAddressForShipping = ''
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '1'  -- Set isAddressForShipping to 1
					WHERE FieldName = 'isAddressForShipping';
				END
				ELSE IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '0'  -- Set isAddressForShipping to 0
					WHERE FieldName = 'isAddressForShipping';
				END
				SELECT @IsAddressForBilling = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForBilling';
				SELECT @IsAddressForShipping = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForShipping';
				--EXEC USP_UpdateCustomerDetails @ModuleTableId,@ModuleId,@CustomerClassificationVal,@CustomerAffiliationVal,@MasterCompanyId,@EmployeeId,@IsAddressForBillingBit,@IsAddressForShippingBit
				EXEC USP_UpdateCustomerDetails @ModuleTableId,@ModuleId,@CustomerClassificationVal,@CustomerAffiliationVal,@MasterCompanyId,@EmployeeId,@IsAddressForBilling,@IsAddressForShipping;
			END
			IF(@ModuleId = @VendorModule)
			BEGIN
				DECLARE @VendorClassificationVal AS VARCHAR(200);

				SET @VendorClassificationVal = (select FieldValue from #DynamicKeyValue where FieldName = 'ClasificationId')
				SELECT @IsAddressForBilling = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForBilling';
				SELECT @IsAddressForShipping = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForShipping';

				IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @YesValues) OR @IsAddressForBilling = ''
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '1'  -- Set isAddressForBilling to 1
					WHERE FieldName = 'isAddressForBilling';
				END
				ELSE IF LOWER(@IsAddressForBilling) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '0'  -- Set isAddressForBilling to 0
					WHERE FieldName = 'isAddressForBilling';
				END
				IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @YesValues) OR @IsAddressForShipping = ''
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '1'  -- Set isAddressForShipping to 1
					WHERE FieldName = 'isAddressForShipping';
				END
				ELSE IF LOWER(@IsAddressForShipping) IN (SELECT Value FROM @NoValues)
				BEGIN
					UPDATE #DynamicKeyValue
					SET FieldValue = '0'  -- Set isAddressForShipping to 0
					WHERE FieldName = 'isAddressForShipping';
				END
				SELECT @IsAddressForBilling = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForBilling';
				SELECT @IsAddressForShipping = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'isAddressForShipping';
				--EXEC USP_UpdateVendorDetails @ModuleTableId, @MasterCompanyId,@VendorClassificationVal
				EXEC USP_UpdateVendorDetails @ModuleTableId, @MasterCompanyId, @VendorClassificationVal, @IsAddressForBilling, @IsAddressForShipping;
			END
			IF(@ModuleId = @EmployeeModule)
			BEGIN
				DECLARE @MasterCompanyCode VARCHAR(255);
				DECLARE @EMPCode VARCHAR(255);
				EXEC [DBO].[PROCAddModuleWiseMSData] @EmployeeId = @ModuleTableId, @EntityMSID = @EmployeeMSId, @MasterCompanyId = @MasterCompanyId, @CreatedBy = @UserName, @UpdatedBy = @UserName, @ModuleId = @EnumEmployeeGeneralInfo, @Opr = 1;
				SELECT @EmpFirstName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'FirstName';
				SELECT @EmpLastName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'LastName';
				SELECT @EmpEmail = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'email';
				INSERT INTO #DynamicKeyValue (FieldName, FieldValue) SELECT [key], TRIM([value]) FROM #TempDynamicData;
				SELECT @MasterCompanyCode = [MasterCompanyCode] FROM [DBO].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
				SELECT @EmpUserName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'userName';
				SET @EMPCode = @MasterCompanyCode + '-' + @EmpUserName;
				EXEC [DBO].[sp_SaveMSByEmployee] @MSID = @EmployeeMSId, @EmployeeID = @ModuleTableId, @UserName = @UserName, @MasterCompanyId = @MasterCompanyId;
				UPDATE [DBO].[Employee]
				SET [IsUploadEmployee] = 1, [UserName] = @EMPCode
				WHERE [EmployeeId] = @ModuleTableId;
			END



			IF(ISNULL(@ChildTable, '') != '')
			BEGIN
				SET @RefFieldName = ''+ @ReferenceColumnName + '';
				SET @FieldValue = '' + CAST(@ModuleTableId AS VARCHAR) + ',';
				SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM #ImportFields WHERE ISNULL(IsModuleTableColumn, 0) = 0
				SELECT @FieldValue = COALESCE(@FieldValue + ' ' +
					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN ISNULL(FieldValue,'0') + ',' END),

					(CASE	WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','
							WHEN FieldType = 'boolean' THEN (CASE	WHEN (LOWER(REPLACE(FieldValue, '''', '''''')) IN (SELECT Value FROM @YesValues) OR LOWER(REPLACE(FieldValue, '''', '''''')) = 'true') THEN '1,' ELSE '0,' END)
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'
							--WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),'
							WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN CASE WHEN ISNULL(FieldValue, '') <> '' THEN 'CONVERT(VARCHAR(10), CAST(REPLACE(''' + REPLACE(FieldValue, '''', '''''') + ''', ''Z'', '''') AS DATETIME), 101),' ELSE 'NULL,' END
							WHEN FieldType = 'number' THEN ISNULL(FieldValue,'NULL') + ','
							WHEN FieldType = 'dropdown' THEN CASE WHEN ISNULL(FieldValue,'') = '' THEN 'NULL' ELSE FieldValue END + ','
							WHEN ISNULL(FieldType,'') = '' THEN FieldValue + ',' END))
				FROM #ImportFields
				WHERE ISNULL(IsModuleTableColumn, 0) = 0
				IF(@ModuleId = @PublicationModule)
				BEGIN
					SET @RefFieldName += ' ,ManagementStructureId, IsActive, IsDeleted, CreatedDate, UpdatedDate';
					SET @FieldValue += CAST(@PublicationMSId AS VARCHAR(50)) + ',1,0,@UtcNow,@UtcNow,';
				END

				SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'
				SET @FieldValue += ' ' + CAST(@MasterCompanyId AS VARCHAR) + ',''' + @UserName + ''',''' + @UserName + ''''
				--SET @RefFieldName = ISNULL(STUFF(@RefFieldName, CHARINDEX(',', @RefFieldName), 1, ''), '')
				SET @RefQuery = 'INSERT INTO [' + @ChildTable + '] (' + @RefFieldName + ' )' + ' VALUES (' + @FieldValue + ');'

				IF(@ModuleId = @PublicationModule)
				BEGIN
					EXEC sp_executesql @RefQuery, N'@UtcNow datetime2(7)', @UtcNow = @UtcNow;
				END
				Else
				BEGIN
					EXEC (@RefQuery)
				END
			END

------------START: Save Mapping Data Of Multiple DropDownl List------------
			DECLARE @MappingFields NVARCHAR(MAX) = '', @MappingValues NVARCHAR(MAX) = '' , @ExpCsv NVARCHAR(MAX), @MappingQuery NVARCHAR(MAX);
			SET @ExpCsv = CASE
						  WHEN @ModuleId = @EmployeeModule THEN JSON_VALUE(@UploadRecord, '$.employeeExpIds')
						  WHEN @ModuleId = @GLModule THEN JSON_VALUE(@UploadRecord, '$.ledgerId')
						  WHEN @ModuleId = @ItemMasterModule THEN JSON_VALUE(@UploadRecord, '$.RankingId')
						  ELSE '' END;
			IF(ISNULL(@ExpCsv, '') <> '')
			BEGIN
				-- remove spaces
				SET @ExpCsv = REPLACE(@ExpCsv, ' ', '');
				-- strip outer single quotes if the JSON held "'2,3,4,5'"
				IF (@ExpCsv IS NOT NULL AND LEN(@ExpCsv) >= 2 AND LEFT(@ExpCsv,1) = '''' AND RIGHT(@ExpCsv,1) = '''')
				BEGIN
					SET @ExpCsv = SUBSTRING(@ExpCsv, 2, LEN(@ExpCsv)-2);
				END
				IF(@ModuleId = @GLModule)
				BEGIN
					SET @MappingFields = '[GlAccountId], [LedgerId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]'
					SET @MappingValues =  N' SELECT ' + CAST(@ModuleTableId AS VARCHAR) + ', value, ' + CAST(@MasterCompanyId AS VARCHAR) + ', @UserName, @UserName, @UtcNow, @UtcNow, 1, 0 FROM STRING_SPLIT(@ExpCsv, '','')';
					SET @MappingQuery = N'INSERT INTO [DBO].[GLAccountLadgerMapping] ' + N' (' + @MappingFields + N') ' + @MappingValues + N';';
					EXEC sp_executesql @MappingQuery, N'@UtcNow datetime2(7), @UserName nvarchar(max), @ExpCsv nvarchar(max)', @UtcNow = @UtcNow, @UserName = @UserName, @ExpCsv = @ExpCsv;
				END
				IF(@ModuleId = @EmployeeModule)
				BEGIN
					SET @MappingFields = '[EmployeeId], [EmployeeExpertiseIds], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]'
					SET @MappingValues =  N' SELECT ' + CAST(@ModuleTableId AS VARCHAR) + ', value, ' + CAST(@MasterCompanyId AS VARCHAR) + ', @UserName, @UserName, @UtcNow, @UtcNow, 1, 0 FROM STRING_SPLIT(@ExpCsv, '','')';
					SET @MappingQuery = N'INSERT INTO [DBO].[EmployeeExpertiseMapping] ' + N' (' + @MappingFields + N') ' + @MappingValues + N';';
					EXEC sp_executesql @MappingQuery, N'@UtcNow datetime2(7), @UserName nvarchar(max), @ExpCsv nvarchar(max)', @UtcNow = @UtcNow, @UserName = @UserName, @ExpCsv = @ExpCsv;
				END
				IF(@ModuleId = @ItemMasterModule)
				BEGIN
					SET @MappingFields = '[ItemMasterId], [RankingId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]'
					SET @MappingValues =  N' SELECT ' + CAST(@ModuleTableId AS VARCHAR) + ', value, ' + CAST(@MasterCompanyId AS VARCHAR) + ', @UserName, @UserName, @UtcNow, @UtcNow, 1, 0 FROM STRING_SPLIT(@ExpCsv, '','')';
					SET @MappingQuery = N'INSERT INTO [DBO].[ItemMasterRanking] ' + N' (' + @MappingFields + N') ' + @MappingValues + N';';
					EXEC sp_executesql @MappingQuery, N'@UtcNow datetime2(7), @UserName nvarchar(max), @ExpCsv nvarchar(max)', @UtcNow = @UtcNow, @UserName = @UserName, @ExpCsv = @ExpCsv;
				END
			END
------------END: Save Mapping Data Of Multiple DropDownl List------------
			IF (@ModuleId = @WorkOrderMaterialsModule AND ISNULL(@ModuleTableId, 0) > 0)
			BEGIN
				DECLARE @WM_WorkOrderId    BIGINT;
				DECLARE @WM_WorkFlowWOId   BIGINT;
				DECLARE @WM_WorkOrderId2   BIGINT;
				SELECT
					@WM_WorkOrderId   = WorkOrderId,
					@WM_WorkFlowWOId  = WorkFlowWorkOrderId
				FROM dbo.WorkOrderMaterials WITH(NOLOCK)
				WHERE WorkOrderMaterialsId = @ModuleTableId;
				EXEC [dbo].[USP_AutoReserveIssueWorkOrderMaterials]
					@WM_WorkFlowWOId,
					@UserName;
				EXEC [dbo].[USP_UpdateWOMaterialsCost]
					@ModuleTableId,
					@WM_WorkFlowWOId;
				EXEC [dbo].[USP_UpdateWOTotalCostDetails]
					@WM_WorkOrderId,
					@WM_WorkFlowWOId,
					@UserName,
					@MasterCompanyId;
				EXEC [dbo].[USP_UpdateWOCostDetails]
					@WM_WorkOrderId,
					@WM_WorkFlowWOId,
					@UserName,
					@MasterCompanyId;
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
			IF OBJECT_ID('tempdb..#TempDynamicData') IS NOT NULL
				DROP TABLE #TempDynamicData
			IF OBJECT_ID('tempdb..#ImportFields') IS NOT NULL
				DROP TABLE #ImportFields
			SET @CurrentRecord += 1;
		END
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
			@ProcedureParameters varchar(3000) = '@ModuleId = ''' + CAST(ISNULL(@ModuleId, 0) AS varchar(100))
			+ '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS varchar(100)),
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