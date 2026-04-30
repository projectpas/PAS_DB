
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
	8	 08-Aug-2025		Ayushi Patel			Removed customer phone validation
	9	 11-Aug-2025		Ayushi Patel			Added validation for stockline : UnitSalesPrice , UnitCost , QuantityOnHand
	10	 13-Aug-2025		Ayushi Patel			Handle Manufacturer based on PartNumber for stockline
	11	 15-Aug-2025		Ayushi Patel			Handle Part with multiple Manufacturer for stockline
	12	 15-Aug-2025		Ayushi Patel			Qty OH must be one for Serialized Parts
	13	 26-Aug-2025		RAJESH GAMI				Validate the PRice Master
	14	 05-Sep-2025		RAJESH GAMI				Validate the PRice Master (Return message for valid price )
	15	 08-Sep-2025        Divyesh Kathitiya		Added validation for Customer and Vendor: IsAddress For Billing & Shipping.
	16	 15-Sep-2025        Rajesh Gami				Price Master: added new fields
	17	 09-Oct-2025        Priyansh Patel			MRO Price Master added Validation for Customer,Unit Price and StartDate
	18	 10-Oct-2025        Rajesh Gami				Disocunt does not allow mor than 100 (Validate the Purchase and Sales)
	19	 14-OCT-2025        Rajesh Gami				Remove Comma from the dicimal value 
	20   17-OCT-2025        Bhargav Saliya          Publication module :: Added case for 'VerifiedBy' Field 
	21	 28-OCT-2025        Divyesh Kathitiya		Fixed: Getting error when validate Item Masterdata.
	22   29-OCT-2025        Priyansh Patel          Added MRO Price Master List Module Validation
	23	 03-Nov-2025        Divyesh Kathitiya		Added New Module "Employee"
	24	 10-Nov-2025	    Priyansh Patel			Updated column name UnitPrice to FlatRatePrice
	25	 19-Nov-2025	    Devendra Shekh			added MasterCompanyId for [Employee] exists Check
	26 	 20-Nov-2025        Divyesh Kathiriya		Added Condition of multiple Dropdown value for "ItemMaster"
	27   26-Nov-2025        Ayushi Patel            Added common validation for FieldType = 'number' to allow only whole numeric values (no decimals, no alphabets), and return appropriate RecordStatus message.
	28   26-Nov-2025        Ayushi Patel            Added condition to skip duplicate validation SP when any RecordStatus contains error.
	29	 02-DEC-2025        Ayushi Patel			Added New SingleScreen Modules
	30	 17-DEC-2025        Nakul Chandigra  		Added New SingleScreen Modules
	31	 18-DEC-2025        Nakul Chandigra  		Added New SingleScreen Modules
	32   22-Dec-2025		Divyesh Kathiriya  		Added validation for Site,Warehouse,Location,Shelf,Bin
	33   13-Jan-2026		Divyesh Kathiriya  		Added validation for "ItemMaster" of Dropdown value.
	34	 02-Feb-2026        Nakul Chandigra  		Added New SingleScreen Modules
	35	 26-MAR-2026		Nakul Chandigra			Added Valiodation For  AircraftStatus And MaintenanceStatus
	36   30-MAR-2026		Ayushi Patel			PN-15831 Removed one unnecessary condition which was causing the issue 
	37   30-MAR-2026		Nakul Chandigra			Removed extra case from the validation for  @AircraftStatusModule And @MaintenanceStatusModule (PN-15874)
	38   02-APR-2026		Nakul Chandigra			Implemented maximum length validation for Name and Description fields in AircraftStatusModule and MaintenanceStatusModule (PN-15873).
	39   06-APR-2026		Nakul Chandigra			Add extra case of the validation for  @AircraftStatusModule And @MaintenanceStatusModule (PN-15945)
	40   07-APR-2026        Nakul Chandigra			Add a common case of validation for dropdown (PN-15950)
	41   09-APR-2026		Ayushi Patel			PN-15988 Excluded StocklineModule from restricting Decimal number
	42   13-APR-2026		Nakul Chandigra			added validation for TrainingName And PositionCode setup screen Upload (PN-15980)
	43   17-APR-2026		Nakul Chandigra			added validation for MaintenanceType  setup screen Upload (PN-16108)
	43   29-APR-2026		Nakul Chandigra			added validation for MaintenanceClass  setup screen Upload (PN-16200)

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
CREATE    PROCEDURE [dbo].[USP_ValidateCommonUploadData_ByModuleId]
	@ModuleId BIGINT = NULL,    
	@UserName VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL, 
	@UploadData [UploadModuleDataTableType] READONLY,
	@EmployeeId BIGINT = NULL
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
		DECLARE @SiteError BIT;
		DECLARE @WarehouseError BIT;
		DECLARE @LocationError BIT;
		DECLARE @ShelfError BIT;
		DECLARE @BinError BIT;
		DECLARE @SiteName varchar(255);
		DECLARE @WarehouseName varchar(255);
		DECLARE @LocationName varchar(255);
		DECLARE @ShelfName varchar(255);
		DECLARE @BinName varchar(255);
		DECLARE @SiteId BIGINT;
		DECLARE @WarehouseId BIGINT;
		DECLARE @LocationId BIGINT;
		DECLARE @ShelfId BIGINT;
		DECLARE @AlterModule AS BIGINT, @GLModule AS BIGINT, @ItemMasterModule AS BIGINT, @CustomerModule AS BIGINT,@StocklineModule AS BIGINT, @EmployeeModule AS BIGINT, @DiscountModule AS BIGINT;
		DECLARE @DefaultMessageModule AS BIGINT, @CertificationTypeModule AS BIGINT, @LeadSource AS BIGINT, @UnitOfMeasureModule AS BIGINT, @AssetAcquisitionTypeModule AS BIGINT, @DocumentTypeModule AS BIGINT , @ShippingViaModule AS BIGINT;
		DECLARE @AssetAttributeType AS BIGINT
	
		DECLARE @POROCategory AS BIGINT , @CapabilityTypeModule AS BIGINT , @VendorClassificationModule AS BIGINT , @chargeModule AS BIGINT;;
		DECLARE @PriceMasterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'PriceMaster');
		DECLARE @PurchaseSalesModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseSales');
		SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
		SET @GLModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'GLAccount');
		SET @ItemMasterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'itemMaster');
		SET @CustomerModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Customer');
		SET @StocklineModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline');
		SET @EmployeeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Employee');
		SET @DiscountModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Discount');
		SET @LeadSource = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'LeadSource');
		SET @CertificationTypeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CertificationType');
		SET @DefaultMessageModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'DefaultMessage');
		SET @AssetAcquisitionTypeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetAcquisitionType');
		SET @UnitOfMeasureModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'UnitOfMeasure');
		SET @DocumentTypeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'DocumentType');
		SET @ShippingViaModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ShippingVia');
		SET @CapabilityTypeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CapabilityType');
		SET @POROCategory = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'POROCategory');
		SET @VendorClassificationModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorClassification');
		SET @chargeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'charge');
		SET @AssetAttributeType = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetAttributeType');

		DECLARE @PriorityModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Priority');
		DECLARE @MROPriceMasterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MROPriceMaster');
		DECLARE @MROPriceMasterListModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MROPriceMasterList');
		DECLARE @CodePrefixesModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CodePrefixes'); 
		DECLARE @ContactTagModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ContactTag'); 
		DECLARE @wingtypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'wingtype');
		DECLARE @VendorRMAReturnReasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRMAReturnReason');
		DECLARE @ShippingTermsModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ShippingTerms');
		DECLARE @TermsConditionModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TermsCondition');
		DECLARE @InvoiceDeliveryPrefStatus AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'InvoiceDeliveryPrefStatus');
		DECLARE @ExchangeCoreLetterType AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeCoreLetterType');
		DECLARE @VendorAuditTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorAuditType');
		DECLARE @VendorStatusModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorStatus');
		DECLARE @RankingModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Ranking');
		DECLARE @CustomerSettingsModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerSettings');
		DECLARE @CustomerClassificationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerClassification');
		DECLARE @TaxTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TaxType');
		DECLARE @creditTermsModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'creditTerms');
		DECLARE @PercentModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Percent');
		DECLARE @CountriesModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'countries');
		DECLARE @TagTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TagType');
		DECLARE @CustomerTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerType');
		DECLARE @AircraftTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AircraftType');
		DECLARE @AircraftModelModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AircraftModel');
		DECLARE @AircraftDashNumber AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AircraftDashNumber');
		DECLARE @EccnDeterminationSource AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EccnDeterminationSource'); 
		DECLARE @LotCostSourceReference AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'LotCostSourceReference'); 
		DECLARE @StandardModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Standard'); 
		DECLARE @ItemGroupModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemGroup'); 
		DECLARE @ItemClassificationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ItemClassification'); 
		DECLARE @ManufacturerModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Manufacturer'); 
		DECLARE @ATAReferenceModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ATAReference'); 
		DECLARE @ATAChapterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ATAChapter'); 
		DECLARE @TangibleClassModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TangibleClass');  
		DECLARE @AssetIntangibleTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetIntangibleType'); 
		DECLARE @AssetStatusModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetStatus'); 
		DECLARE @AssetLocationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetLocation');
		DECLARE @AssetDisposalTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetDisposalType');
		DECLARE @AssetDepreciationMethodModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetDepreciationMethod');
		DECLARE @AssetDepConventionModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetDepConvention');
		DECLARE @AssetDepreciationFrequencyModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetDepreciationFrequency');
		DECLARE @AssetDepreciationIntervalModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetDepreciationInterval');
		DECLARE @AssetAttributeTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetAttributeType');
		DECLARE @AssetIntangibleAttributeTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetIntangibleAttributeType');
		DECLARE @SiteModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Site');
		DECLARE @WarehouseModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Warehouse');
		DECLARE @FindingModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Finding');
		DECLARE @InvoiceType AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'InvoiceType');
		DECLARE @OrganizationTagType AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'OrganizationTagType');
		DECLARE @ManagementStructureLevelModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ManagementStructureLevel');
		DECLARE @BalanceTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'BalanceType');
		DECLARE @LedgerModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Ledger');
		DECLARE @Master1099Module AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Master1099');
		DECLARE @RMAReasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'RMAReason');
		DECLARE @CreditMemoReasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CreditMemoReason');
		DECLARE @InventoryGLSettingModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'InventoryGLSetting');
		DECLARE @GLCashFlowClassificationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'GLCashFlowClassification');
		DECLARE @CurrencyModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Currency');
		DECLARE @MasterDiscountTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MasterDiscountType');
		DECLARE @MasterBankFeesTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MasterBankFeesType');
		DECLARE	@MasterAdjustReasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MasterAdjustReason');
		DECLARE	@JobTitleModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'JobTitle');
		DECLARE	@EmployeeLeaveTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeLeaveType');
		DECLARE	@EmployeeStationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeStation');
		DECLARE	@EmployeeCertificationTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeCertificationType');
		DECLARE	@EmployeeTrainingTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeTrainingType');
		DECLARE @EmployeeExpertiseModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'EmployeeExpertise');
		DECLARE @TaxRateModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TaxRate');
		DECLARE @stocklineadjustmentreasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'stocklineadjustmentreason');
		DECLARE @WorkOrderStageModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderStage');
		DECLARE @CommonTeardownTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'CommonTeardownType');
		DECLARE @TeardownReasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TeardownReason');
		DECLARE @WorkPerformedModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkPerformed');
		DECLARE @TaskStatusModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TaskStatus');
		DECLARE @ScrapreasonModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Scrapreason');
		DECLARE @EvidenceModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Evidence');
		DECLARE @LocationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Location');
		DECLARE @PublicationTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'PublicationType');
		DECLARE @ShelfModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Shelf');
		DECLARE @BinModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Bin');
		DECLARE @AircraftStatusModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AircraftStatus');
		DECLARE @MaintenanceStatusModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MaintenanceStatus');
		DECLARE @TrainingNameModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'TrainingName');
		DECLARE @PositionCodeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'PositionCode');
		DECLARE @MaintenanceTypeModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MaintenanceType');
		DECLARE @MaintenanceClassModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Maintenanceclass');

		DECLARE @DropdownListTable VARCHAR(100) = NULL, 
		@DropdownListId VARCHAR(100) = NULL, 
		@DropdownListValue VARCHAR(100) = NULL, 
		@DropdownLFieldValue VARCHAR(MAX) = NULL,
		@SelectFieldName VARCHAR(100) = NULL;
		DECLARE @PublicationModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Publication');
		DECLARE @IsMultiValue BIT = NULL;
		DECLARE @EmployeeMSId BIGINT;
		DECLARE @MasterCompanyCode VARCHAR(255);
		DECLARE @EmpUserName VARCHAR(255);
		DECLARE @EmpFirstName VARCHAR(255);
		DECLARE @EmpLastName VARCHAR(255);
		DECLARE @EMPCode VARCHAR(255);
		DECLARE @EmpId BIGINT;
		DECLARE @UserExits INT, @UserFirstLastExits INT;
		DECLARE @LegalEntityId BIGINT;
		DECLARE @Level1Id INT;

		SET @EmployeeMSId  = (SELECT [ManagementStructureId] FROM DBO.[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId);
		--SET @DropdownListTable = QUOTENAME(@DropdownListTable);

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

		UPDATE #uploadDataResults
		SET UploadRecord = JSON_MODIFY(
								JSON_MODIFY(
									JSON_MODIFY(
										JSON_MODIFY(
											UploadRecord,
											'$.PP_VendorListPrice',
											REPLACE(JSON_VALUE(UploadRecord, '$.PP_VendorListPrice'), ',', '')
										),
										'$.SP_FSP_FlatPriceAmount',
										REPLACE(JSON_VALUE(UploadRecord, '$.SP_FSP_FlatPriceAmount'), ',', '')
									),
									'$.SP_CalSPByPP_MarkUpPercOnListPrice',
									REPLACE(JSON_VALUE(UploadRecord, '$.SP_CalSPByPP_MarkUpPercOnListPrice'), ',', '')
								),
								'$.PP_PurchaseDiscPerc',
								REPLACE(JSON_VALUE(UploadRecord, '$.PP_PurchaseDiscPerc'), ',', '')
                    );
		SELECT @TotalRecords = MAX([RecordId]), @CurrentRecord = MIN([RecordId]) FROM #uploadDataResults;

		SELECT @ReferenceTable = ReferenceTable FROM [dbo].[ImportModule] WITH(NOLOCK) WHERE [ImportModuleId] = @ModuleId;

		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecord, 0))
		BEGIN
			TRUNCATE TABLE #DynamicKeyValue;

			SET @Erorr = '';
			SET @ColumnReferenceId = '';

			SELECT @UploadRecord = [UploadRecord] FROM #uploadDataResults WHERE [RecordId] = @CurrentRecord;
			
			SELECT [key], [value] INTO #TempDynamicData FROM OPENJSON(@UploadRecord);
			
			IF(@ModuleId=@ItemMasterModule)
			BEGIN
				UPDATE #TempDynamicData
				SET [value] = REPLACE([value], '"', '\"')
				WHERE [key] = 'partnumber';
			END

			IF (@ModuleId = @MROPriceMasterModule 
			 OR @ModuleId = @MROPriceMasterListModule)
			BEGIN
				UPDATE #TempDynamicData
				SET [value] = REPLACE([value], '''', '''''')
				WHERE [key] = 'CustomerId';
			END;


			INSERT INTO #DynamicKeyValue (FieldName, FieldValue) SELECT [key], TRIM([value]) FROM #TempDynamicData;

			SELECT	IMF.ImportModuleFieldMasterId, IMF.ModuleId, IMF.FieldName, IMF.HeaderName, IMF.FieldType, IMF.IsRequired,
						IMF.DropdownListType, IMF.DropdownListTable, IMF.DropdownListId, IMF.DropdownListValue, IMF.DropdownListValueId,
						IMF.IsMultiValue, TMP.RecordId, TMP.FieldValue, TMP.RecordStatus,IMF.IsChekColumnReference,IMF.ReferenceColumn,IMF.ChekDuplticateRef1,IMF.ChekDuplticateRef2, @DuplicateErroMsg AS DuplicateErrorMsg
			INTO #ImportFields
			FROM [DBO].[ImportModuleFieldMaster] IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			--ORDER BY IMF.DisplaySortOrder ASC
			--SELECT * FROM #ImportFields 
			SELECT @TotalRow = MAX(ImportModuleFieldMasterId), @CurrentRow = MIN(ImportModuleFieldMasterId) FROM #ImportFields;
			
			WHILE(@TotalRow >= @CurrentRow)
			BEGIN

				SELECT	@DropdownListTable = DropdownListTable, @DropdownListId = DropdownListId, @DropdownListValue = DropdownListValue, @DropdownLFieldValue = FieldValue, @IsChekColumnReference = IsChekColumnReference,@ReferenceColumn = '',@SelectFieldName = FieldName, @IsMultiValue = IsMultiValue
				FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;
				
				IF(ISNULL(@DropdownListTable, '') != '' AND ISNULL(@DropdownLFieldValue, '') != '')
				BEGIN
					DECLARE @DropdownListValueId VARCHAR(100) = NULL;
					SET @DropdownLFieldValue = UPPER(TRIM(@DropdownLFieldValue))
					
					IF(UPPER(@SelectFieldName) = 'VERIFIEDBY' AND UPPER(@DropdownLFieldValue) = 'NA' AND @ModuleId = @PublicationModule)
					BEGIN
						SET @DropdownListValueId = '0'
					END
					ELSE
					BEGIN
						IF (@DropdownListTable = 'Percent'
							AND TRY_CONVERT(DECIMAL(18,4), @DropdownLFieldValue) IS NULL)
						BEGIN
							-- Set output blank/null
							SET @DropdownListValueId = NULL;
						END
						ELSE
						BEGIN
							-- Execute SP normally
							EXEC [dbo].[USP_GetDropdownValueId] 
								@DropdownListTable, 
								@DropdownListId, 
								@DropdownListValue, 
								@DropdownLFieldValue, 
								@MasterCompanyId,
								@ModuleId,
								@ColumnReferenceId,
								@ReferenceColumn,
								@IsChekColumnReference, 
								@FieldValueId = @DropdownListValueId OUTPUT;
						END
					END
								
					--IF(ISNULL(@DropdownListValueId, '') != '')
					IF(ISNULL(@DropdownListValueId, '') != '' AND ISNULL(@IsMultiValue, 0) = 0)
					BEGIN
						SET @DropdownListValueId = (SELECT LEFT(@DropdownListValueId, CHARINDEX(',', @DropdownListValueId + ',') - 1))
						UPDATE #ImportFields SET DropdownListValueId = CAST(@DropdownListValueId AS VARCHAR) WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
					IF(ISNULL(@DropdownListValueId, '') != '' AND ISNULL(@IsMultiValue, 0) = 1)
					BEGIN
						SET @DropdownListValueId = '''' + @DropdownListValueId + '''';
						UPDATE #ImportFields SET DropdownListValueId = CAST(@DropdownListValueId AS VARCHAR) WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
					--SET @ColumnReferenceId = CASE WHEN ISNULL(@DropdownListValueId, '') != '' THEN  CAST(@DropdownListValueId AS BIGINT) ELSE 0 END;
				END
				
				SET @CurrentRow += 1;
			END
			
			DECLARE @ManufacturerId VARCHAR(255)
			DECLARE @ManufacturerName VARCHAR(255)
			DECLARE @Manufacture VARCHAR(255)
			if (@ModuleId = @StocklineModule  OR @ModuleId = @PriceMasterModule OR @ModuleId = @MROPriceMasterModule
			OR @ModuleId = @MROPriceMasterListModule
			)
			BEGIN
				SELECT @ManufacturerId = FieldValue 
				FROM #ImportFields 
				WHERE FieldName = 'ManufacturerId';

				--  Check if 'PartNumber' is present in ImportFields
				IF EXISTS (
					SELECT 1 
					FROM #ImportFields 
					WHERE DropdownListValue = 'PartNumber' AND ModuleId = @ModuleId
				)
				BEGIN
					--  Get all matching ManufacturerIds based on PartNumber(s)
					DECLARE @MatchingManufacturerIds TABLE (ManufacturerId BIGINT, ManufacturerName NVARCHAR(200),PartNumber NVARCHAR(Max), PartNumberId BIGINT);
					
				IF EXISTS (
								SELECT 1
								FROM ItemMaster IM
								WHERE IM.ManufacturerName = @ManufacturerId
									  AND ISNULL(IM.IsDeleted,0) = 0 
									  AND ISNULL(IM.IsActive,0) = 1
									  AND IM.MasterCompanyId = @MasterCompanyId
							)
							BEGIN
								-- Case 1: @ManufacturerId is actually a ManufacturerName
								INSERT INTO @MatchingManufacturerIds (ManufacturerId, ManufacturerName,PartNumber,PartNumberId)
								SELECT DISTINCT IM.ManufacturerId, IM.ManufacturerName, Im.partnumber, Im.ItemMasterId
								FROM ItemMaster IM
								JOIN #ImportFields IMF ON IMF.FieldValue = IM.PartNumber
								WHERE IMF.ModuleId = @ModuleId
								  AND IMF.DropdownListValue = 'PartNumber'
								  AND ISNULL(IM.IsDeleted,0) = 0
								  AND ISNULL(IM.IsActive,0) = 1
								  AND IM.MasterCompanyId = @MasterCompanyId
								  AND IM.ManufacturerName = @ManufacturerId;
							END
							ELSE
							BEGIN
								-- Case 2: @ManufacturerId is NOT a ManufacturerName (treat it as before)
								INSERT INTO @MatchingManufacturerIds (ManufacturerId, ManufacturerName,PartNumber,PartNumberId)
								SELECT DISTINCT IM.ManufacturerId, IM.ManufacturerName, Im.partnumber, Im.ItemMasterId
								FROM ItemMaster IM
								JOIN #ImportFields IMF ON IMF.FieldValue = IM.PartNumber
								WHERE IMF.ModuleId = @ModuleId
								  AND IMF.DropdownListValue = 'PartNumber'
								  AND ISNULL(IM.IsDeleted,0) = 0
								  AND ISNULL(IM.IsActive,0) = 1
								  AND IM.MasterCompanyId = @MasterCompanyId;
							END

							Update IMF SET IMF.DropdownListValueId = MNF.PartNumberId FROM #ImportFields IMF 
									INNER JOIN ItemMaster IM WITH(NOLOCK) ON IM.partnumber = IMF.FieldValue  
									INNER JOIN @MatchingManufacturerIds MNF ON IM.partnumber = MNF.PartNumber AND MNF.PartNumber = IMF.FieldValue
									WHERE IMF.ModuleId = @ModuleId
											  AND IMF.DropdownListValue = 'PartNumber'
											  AND ISNULL(IM.IsDeleted,0) = 0
											  AND ISNULL(IM.IsActive,0) = 1
											  AND IM.MasterCompanyId = @MasterCompanyId;
							
					--  Check how many different manufacturers were found
					IF ((SELECT COUNT(*) FROM @MatchingManufacturerIds) > 1)
					BEGIN
						--  If @ManufacturerId matches any from the list, do nothing
						IF EXISTS (
							SELECT 1 
							FROM @MatchingManufacturerIds 
							WHERE ManufacturerName = @ManufacturerId
						)
						BEGIN
							SET @ManufacturerName = @ManufacturerId;
						END
						ELSE
						BEGIN
							--  Pick first manufacturer and set @ManufacturerName
							SELECT TOP 1 
								--@ManufacturerId = ManufacturerName,
								@ManufacturerName = ManufacturerName
							FROM @MatchingManufacturerIds
							ORDER BY ManufacturerName ASC; 
						END
					END
					ELSE
					BEGIN
						-- Only one manufacturer found - assign directly
						SELECT TOP 1 
							--@ManufacturerId = ManufacturerName,
							@ManufacturerName = ManufacturerName
						FROM @MatchingManufacturerIds;
					END
				END

				--SET @Manufacture = @ManufacturerId;
				--SET @ManufacturerId = @ManufacturerName;
			END
			IF(@ModuleId = @EmployeeModule)
			BEGIN
				SET @UserExits = 0;
				SET @EmpId = 0;
				SET @UserFirstLastExits = 0;

				SELECT @MasterCompanyCode = [MasterCompanyCode] FROM [DBO].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
				SELECT @EmpUserName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'userName';
				SELECT @EmpFirstName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'firstName';
				SELECT @EmpLastName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'lastName';
				SET @EMPCode = @MasterCompanyCode + '-' + @EmpUserName;

				SELECT @EmpId = [EmployeeId] FROM [DBO].[AspNetUsers] WITH(NOLOCK) WHERE [UserName] = @EMPCode;

				IF EXISTS (SELECT 1 FROM [DBO].[AspNetUsers] WITH(NOLOCK) WHERE [UserName] = @EMPCode)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmpId AND [MasterCompanyId] = @MasterCompanyId)
					BEGIN
						SET @UserExits = 1;
					END
				END				

				SELECT @Level1Id = Level1Id FROM [DBO].[EntityStructureSetup] WITH(NOLOCK) WHERE [EntityStructureId] = @EmployeeMSId;
				SELECT @LegalEntityId = [LegalEntityId] FROM [DBO].[ManagementStructureLevel] WITH(NOLOCK) WHERE [ID] = @Level1Id;

				IF EXISTS (SELECT 1 FROM [DBO].[EntityStructureSetup] WITH(NOLOCK) WHERE [EntityStructureId] = @EmployeeMSId)
				BEGIN
					IF (@LegalEntityId IS NOT NULL AND @LegalEntityId > 0)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[Employee] e WITH(NOLOCK) WHERE e.[FirstName] = @EmpFirstName AND e.[LastName] = @EmpLastName AND e.[LegalEntityId] = @LegalEntityId AND e.[MasterCompanyId] = @MasterCompanyId)
						BEGIN
							SET @UserFirstLastExits = 1;
						END
					END
				END
			END
	
			IF(@ModuleId = @ItemMasterModule)
			BEGIN
				IF OBJECT_ID('tempdb..#ItemMasterFields') IS NOT NULL
				DROP TABLE #ItemMasterFields		

				CREATE TABLE #ItemMasterFields
				(
					WarehouseId BIGINT,
					WarehouseName VARCHAR(255),
					LocationName VARCHAR(255),
					ShelfName VARCHAR(255),
					BinName VARCHAR(255),
				)

				SELECT @SiteName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'SiteId';
				SELECT @WarehouseName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'WarehouseId';
				SELECT @LocationName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'LocationId';
				SELECT @ShelfName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'ShelfId';
				SELECT @BinName = FieldValue FROM #DynamicKeyValue WHERE FieldName = 'BinId';

				SELECT @SiteId = [SiteId] FROM [DBO].[Site] WITH(NOLOCK) WHERE [Name] = @SiteName AND [MasterCompanyId] = @MasterCompanyId;
				SELECT @WarehouseId = [WarehouseId] FROM [DBO].[Warehouse] WITH(NOLOCK) WHERE [Name] = @WarehouseName AND [MasterCompanyId] = @MasterCompanyId;
				SELECT @LocationId = [LocationId] FROM [DBO].[Location] WITH(NOLOCK) WHERE [Name] = @LocationName AND [MasterCompanyId] = @MasterCompanyId;
				SELECT @ShelfId = [ShelfId] FROM [DBO].[Shelf] WITH(NOLOCK) WHERE [Name] = @ShelfName AND [MasterCompanyId] = @MasterCompanyId;		

			    INSERT INTO #ItemMasterFields (WarehouseId, WarehouseName)
				SELECT [WarehouseId], [Name]
				FROM [DBO].[Warehouse] WITH(NOLOCK)
				WHERE [SiteId] = @SiteId AND [MasterCompanyId] = @MasterCompanyId;

				INSERT INTO #ItemMasterFields (LocationName)
				SELECT [Name]
				FROM [DBO].[Location] WITH(NOLOCK)
				WHERE [WarehouseId] = @WarehouseId AND [MasterCompanyId] = @MasterCompanyId;

				INSERT INTO #ItemMasterFields (ShelfName)
				SELECT [Name]
				FROM [DBO].[Shelf] WITH(NOLOCK)
				WHERE [LocationId] = @LocationId AND [MasterCompanyId] = @MasterCompanyId;

				INSERT INTO #ItemMasterFields (BinName)
				SELECT [Name]
				FROM [DBO].[Bin] WITH(NOLOCK)
				WHERE [ShelfId] = @ShelfId AND [MasterCompanyId] = @MasterCompanyId;

				IF (@SiteId IS NULL)
				BEGIN
					SET @SiteError = 1
				END
				ELSE
				BEGIN
					SET @SiteError = 0
				END	
				
				IF NOT EXISTS(SELECT WarehouseName FROM #ItemMasterFields WHERE TRIM(LOWER(WarehouseName)) = TRIM(LOWER(@WarehouseName)))
				BEGIN
					SET @WarehouseError = 1
				END
				ELSE
				BEGIN
					SET @WarehouseError = 0
				END			

				IF NOT EXISTS(SELECT LocationName FROM #ItemMasterFields WHERE TRIM(LOWER(LocationName)) = TRIM(LOWER(@LocationName)))
				BEGIN
					SET @LocationError = 1
				END
				ELSE
				BEGIN
					SET @LocationError = 0
				END

				IF NOT EXISTS(SELECT ShelfName FROM #ItemMasterFields WHERE TRIM(LOWER(ShelfName)) = TRIM(LOWER(@ShelfName)))
				BEGIN
					SET @ShelfError = 1
				END
				ELSE
				BEGIN
					SET @ShelfError = 0
				END

				IF NOT EXISTS(SELECT BinName FROM #ItemMasterFields WHERE TRIM(LOWER(BinName)) = TRIM(LOWER(@BinName)))
				BEGIN
					SET @BinError = 1
				END
				ELSE
				BEGIN
					SET @BinError = 0
				END	
			END			
			UPDATE TMP
			SET TMP.[RecordStatus] =	CASE	WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(TMP.FieldValue, '') = '' THEN IMF.HeaderName + ' is Required'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != ''  AND ISNULL(IMF.FieldValue, '') = '' THEN IMF.HeaderName + ' is Required'
												WHEN (@ModuleId = @ItemMasterModule) AND ISNULL(IMF.IsRequired, 0) = 0 AND ISNULL(IMF.DropdownListType, '') != '' AND ISNULL(IMF.FieldValue, '') = '' THEN ''
												WHEN (@ModuleId = @ItemMasterModule)
												THEN LTRIM(RTRIM(
															CASE 
															WHEN ISNULL(IMF.DropdownListType, '') != ''  AND ISNULL(IMF.DropdownListValueId, '') = '' 
																THEN 'Please Enter Correct  ' + IMF.HeaderName
																ELSE ''
															END
														+	CASE 
																WHEN (@SiteError = 1 AND [IMF].[FieldName] = 'SiteId')
																THEN 'Entered Site Not Exists. '
																ELSE ''
															END
														+	CASE 
																WHEN (@WarehouseError = 1 AND [IMF].[FieldName] = 'WarehouseId')
																THEN 'Entered Warehouse Not Exists In This Site. '
																ELSE ''
															END
														+	CASE 
																WHEN (@LocationError = 1 AND [IMF].[FieldName] = 'LocationId')
																THEN 'Entered Location Not Exists In This Warehouse. '
																ELSE ''
															END
														+	CASE 
																WHEN (@ShelfError = 1 AND [IMF].[FieldName] = 'ShelfId')
																THEN 'Entered Shelf Not Exists In This Location. '
																ELSE ''
															END
														+	CASE 
																WHEN (@BinError = 1 AND [IMF].[FieldName] = 'BinId')
																THEN 'Entered Bin Not Exists In This Shelf. '
																ELSE ''
															END	))
												--WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != ''  AND ISNULL(IMF.DropdownListValueId, '') = '' THEN 'Pleas Enter Correct ' + IMF.HeaderName
												WHEN ISNULL(TMP.FieldValue, '') <> ''
													 AND ISNULL(IMF.FieldType, '') = 'number'
													 AND (
															TRY_CAST(TMP.FieldValue AS INT) IS NULL 
															OR CHARINDEX('.', TMP.FieldValue) > 0  
														 )
													AND @ModuleId NOT IN (@PriceMasterModule, @StocklineModule)
												THEN IMF.HeaderName + ' must be a whole number (decimals not allowed)'
												WHEN (@ModuleId = @MROPriceMasterModule OR @ModuleId = @MROPriceMasterListModule)
													 AND IMF.FieldName = 'CustomerId' 
													 AND ISNULL(IMF.DropdownListType, '') != ''  
													 AND ISNULL(IMF.DropdownListValueId, '') = '' 
													 AND UPPER(TRIM(TMP.FieldValue)) = 'ALL'
												THEN
													' '	
												WHEN ISNULL(IMF.DropdownListType, '') != ''  
													 AND ISNULL(IMF.DropdownListValueId, '') = '' 
												THEN 
													'Please Enter Correct  ' + IMF.HeaderName 
												-- FlatRatePrice Validation (checking for numeric value and greater than 0)
												WHEN (@ModuleId = @MROPriceMasterModule OR @ModuleId = @MROPriceMasterListModule)
														AND ISNULL(TMP.FieldValue, '') != '' 
														AND IMF.FieldName = 'FlatRatePrice' 
														AND TMP.FieldValue LIKE '%[^0-9]%'
														And ( TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) IS NULL
														OR TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) <= TRY_CAST(0 AS DECIMAL(18,2)) )
												THEN 
													'Flat Rate Price  must be a whole number greater than 0' 

													WHEN ISNULL(TMP.FieldValue, '') != '' 
														 AND IMF.FieldName = 'PP_PurchaseDiscPerc' 
														 AND (
															 TRY_CAST(TMP.FieldValue AS INT) > 100
														 )
													THEN 
														'Purchase Discount percentage cannot exceed 100.'

												-- Date validation for StartDate field (MM/DD/YYYY format)
												WHEN IMF.FieldName = 'StartDate' 
													 AND ISNULL(TMP.FieldValue, '') != '' 
													 AND TRY_CONVERT(DATE, TMP.FieldValue, 101) IS NULL
												THEN 
													'Start Date must be in MM/DD/YYYY format'

												WHEN IMF.FieldName = 'EndDate' 
													 AND ISNULL(TMP.FieldValue, '') != '' 
													 AND TRY_CONVERT(DATE, TMP.FieldValue, 101) IS NULL
												THEN 
													'End Date must be in MM/DD/YYYY format'

												WHEN IMF.FieldName = 'EndDate'
													 AND EXISTS (
														 SELECT 1
														 FROM #DynamicKeyValue SD
														 WHERE SD.FieldName = 'StartDate'
														   AND ISNULL(SD.FieldValue, '') != ''
														   AND TRY_CONVERT(DATE, SD.FieldValue, 101) IS NOT NULL
														   AND TRY_CONVERT(DATE, TMP.FieldValue, 101) IS NOT NULL
														   AND TRY_CONVERT(DATE, TMP.FieldValue, 101) < TRY_CONVERT									(DATE, SD.FieldValue, 101)
													 )
												THEN 'End Date must be greater than Start Date'


												WHEN ISNULL(TMP.FieldValue, '') != '' AND (IMF.FieldName = 'Email' OR IMF.FieldName = 'VendorEmail')
													AND (
														TMP.FieldValue NOT LIKE '%@%._%' 
													)
													THEN 'Email is not in a valid format'
												WHEN ISNULL(TMP.FieldValue, '') != '' AND IMF.FieldName = 'QuantityOnHand'
													AND (
														--TRY_CAST(TMP.FieldValue AS INT) IS NULL OR TRY_CAST(TMP.FieldValue AS INT) <= 0
														TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) IS NULL 
														OR TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) <= 0
													)
													THEN 'QuantityOnHand must be a whole number greater than 0'
												WHEN IMF.FieldName = 'QuantityOnHand'
													 AND (
														 SELECT LOWER(FieldValue)
														 FROM #DynamicKeyValue
														 WHERE FieldName = 'isSerialized' 
													 ) = 'yes'
													 AND TRY_CAST(TMP.FieldValue AS INT) != 1
													 THEN 'Qty OH must be one for Serialized Parts'
												WHEN ISNULL(TMP.FieldValue, '') != '' 
													 AND IMF.FieldName IN ('UnitSalesPrice', 'UnitCost')
													 AND TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) IS NULL
												THEN IMF.FieldName + ' must be a valid number'
												WHEN  ISNULL(TMP.FieldValue, '') != ''  AND ((IMF.FieldName = 'PP_VendorListPrice' OR IMF.FieldName = 'PP_UnitPurchasePrice' OR IMF.FieldName = 'SP_CalSPByPP_UnitSalePrice'OR IMF.FieldName = 'PP_PurchaseDiscPerc' OR IMF.FieldName = 'SP_FSP_FlatPriceAmount' OR IMF.FieldName = 'SP_CalSPByPP_MarkUpPercOnListPrice' )
													AND (TRY_CAST(REPLACE(TMP.FieldValue, ',', '') AS DECIMAL(18,2)) IS NULL ) )
													THEN (CASE WHEN IMF.FieldName = 'PP_VendorListPrice' THEN 'Vendor List Price' WHEN IMF.FieldName = 'PP_UnitPurchasePrice' THEN 'Unit Purchase Price' WHEN IMF.FieldName = 'SP_CalSPByPP_UnitSalePrice' THEN 'Unit Sale Price' WHEN IMF.FieldName = 'PP_PurchaseDiscPerc' THEN 'Purchase Discount Percentage' WHEN IMF.FieldName = 'SP_FSP_FlatPriceAmount' THEN 'Flat Price Amount' WHEN IMF.FieldName = 'SP_CalSPByPP_MarkUpPercOnListPrice' THEN 'Markup Percentage' ELSE '' END  ) + ' must be a valid price (characters are not allowed)'
												WHEN ISNULL(TMP.FieldValue, '') != '' AND (IMF.FieldName = 'SalePriceSelectName') AND (LOWER(TMP.FieldValue) NOT IN ('Flat','Calculated'))
													THEN 'Sale Price must be FLAT OR CALCULATED'
												WHEN ISNULL(TMP.FieldValue, '') != '' AND (IMF.FieldName = 'isAddressForBilling' OR IMF.FieldName = 'isAddressForShipping') AND (LOWER(TMP.FieldValue) NOT IN ('yes','no'))
													THEN IMF.FieldName + ' must be YES OR NO'

												WHEN @ModuleId = @EmployeeModule AND IMF.FieldName = 'userName'
												THEN CASE 
														WHEN @UserExits = 1 AND @UserFirstLastExits = 1 
															THEN 'Employee UserName already exist.! Employee Firstname/Lastname with legal entity already exist.!'
														WHEN IMF.FieldName = 'userName' AND @UserExits = 1
															THEN 'Employee UserName already exist.!'
														WHEN IMF.FieldName = 'userName' AND @UserFirstLastExits = 1
															THEN 'Employee Firstname/Lastname with legal entity already exist.!'
														ELSE ''
													END	
												WHEN (@ModuleId = @DiscountModule)
													 AND ISNULL(TMP.FieldValue, '') <> '' 
													 AND IMF.FieldName = 'DiscontValue'  
													 AND (TRY_CAST(TMP.FieldValue AS INT) IS NULL
														 OR TRY_CAST(TMP.FieldValue AS INT) < 1  
														 OR TRY_CAST(TMP.FieldValue AS INT) > 100)

												THEN 'Discount Value must be a whole number between 1 and 100'
												--WHEN IMF.DropdownListValue = 'PartNumber' AND @ManufacturerId IS NOT NULL AND @ManufacturerName IS NOT NULL 
												--	AND LOWER(@ManufacturerId) != LOWER(@ManufacturerName) THEN 'Incorrect Manufacturer'
												WHEN ISNULL(IMF.DuplicateErrorMsg, '') != '' THEN IMF.DuplicateErrorMsg
												WHEN @ModuleId = @AircraftStatusModule 
													 AND IMF.FieldName = 'Name'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 100
												THEN '‘Name’ exceeds 100 characters limit.'
												WHEN @ModuleId = @MaintenanceStatusModule  
													 AND IMF.FieldName = 'Name'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 100
												THEN '‘Name’ exceeds 100 characters limit.'
												WHEN @ModuleId = @AircraftStatusModule 
													 AND IMF.FieldName = 'Name'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 100
												THEN '‘Name’ exceeds 100 characters limit.'
												WHEN @ModuleId = @MaintenanceStatusModule  
													 AND IMF.FieldName = 'Description'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 500
												THEN '‘Description’ exceeds 500 characters limit.'
												WHEN @ModuleId = @AircraftStatusModule  
													 AND IMF.FieldName = 'Description'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 500
												THEN '‘Description’ exceeds 500 characters limit.'
												WHEN @ModuleId = @MaintenanceTypeModule  
													 AND IMF.FieldName = 'MaintenanceType'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 500
												THEN '‘MaintenanceType’ exceeds 500 characters limit.'
												WHEN @ModuleId = @MaintenanceClassModule  
													 AND IMF.FieldName = 'Name'  
													 AND ISNULL(TMP.FieldValue, '') <> ''
													 AND LEN(TMP.FieldValue) > 256
												THEN '‘Name’ exceeds 256 characters limit.'
												
										ELSE ' '
										END,
				TMP.FieldValue = CASE WHEN ISNULL(IMF.DropdownListTable, '') != '' THEN IMF.DropdownListValueId ELSE TMP.FieldValue END
			FROM #ImportFields IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			
			if (@ModuleId = @StocklineModule OR @ModuleId = @PriceMasterModule) 
			BEGIN
				IF @Manufacture IS NOT NULL AND
				   LOWER(@ManufacturerId) <> LOWER(@ManufacturerName)
				BEGIN
					-- Update the ManufacturerId in #DynamicKeyValue
					UPDATE #DynamicKeyValue
					SET FieldValue = @ManufacturerName
					WHERE FieldName = 'ManufacturerId';
				
				END
			END
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
						UPDATE #ImportFields SET DropdownListValueId = '' WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
					
					--SET @ColumnReferenceId = CASE WHEN ISNULL(@RSDropdownListValueId, '') != '' THEN  CAST(@RSDropdownListValueId AS BIGINT) ELSE 0 END;
				END
				IF(@ModuleId != @GLModule AND @ModuleId != @EmployeeModule AND @ModuleId != @ItemMasterModule AND @ModuleId != @AssetAttributeTypeModule AND @ModuleId != @AssetIntangibleAttributeTypeModule)
				BEGIN
					SELECT @ColumnReferenceId =  DropdownListValueId FROM #ImportFields WHERE ImportModuleFieldMasterId = @CurrentRow;
				END
				
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
					IF(@ModuleId=@StocklineModule AND @ChekDuplticateRef2='PartNumber')
					BEGIN
						SELECT	@DuplicateRefeValue2 = CASE WHEN ISNULL(DropdownListTable, '') = '' THEN FieldValue ELSE DropdownListValueId END FROM #ImportFields WHERE FieldName = 'ItemMasterId';
						SELECT	@DuplicateRefeValue2 = partnumber FROM ItemMaster WHERE ItemMasterId = @DuplicateRefeValue2
					END
					SET @IsDuplicate = 0;
					IF(@ModuleId=@StocklineModule)
					BEGIN
						IF((ISNULL(@DuplicateRefeValue1, '') != '' AND ISNULL(@DuplicateRefeValue2, '') != ''))
						BEGIN
						EXEC [dbo].[USP_ChekDuplicateValueForUpload] @ChekDuplticateRef1, @ChekDuplticateRef2, @DuplicateRefeValue1, @DuplicateRefeValue2, @ReferenceTable, @MasterCompanyId, @ModuleId, @UploadData, @UploadRecord, @IsDuplicate = @IsDuplicate OUTPUT;
						END
					END
					ELSE
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM #DynamicKeyValue WHERE ISNULL(RecordStatus, '') <> '')
						BEGIN
							EXEC [dbo].[USP_ChekDuplicateValueForUpload] @ChekDuplticateRef1, @ChekDuplticateRef2, @DuplicateRefeValue1, @DuplicateRefeValue2, @ReferenceTable, @MasterCompanyId, @ModuleId, @UploadData, @UploadRecord, @IsDuplicate = @IsDuplicate OUTPUT;
						END
					END
					IF(ISNULL(@IsDuplicate, 0) = 1)
					BEGIN
						UPDATE #ImportFields 
						SET DuplicateErrorMsg = CASE	WHEN @ModuleId = @AlterModule THEN 'Entered PN and Alterate PN Already Exits!'
														WHEN @ModuleId = @GLModule THEN 'Entered Account Code Already Exits!'
														WHEN @ModuleId = @ItemMasterModule THEN 'Entered PN And Manufacturer Already Exits!'
														WHEN @ModuleId = @CustomerModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @StocklineModule THEN 'Entered Serial Number Already Exits for This PartNumber'
														WHEN @ModuleId = @PriceMasterModule THEN 'Part and Condition mapping already exists'
														WHEN @ModuleId = @EmployeeModule THEN 'Entered Email Already Exits!'
														WHEN @ModuleId = @DiscountModule THEN 'Entered Discount Value Already Exits!'
														WHEN @ModuleId = @DefaultMessageModule THEN 'Entered Module and Sequence Number Already Exits!'
														WHEN @ModuleId = @CertificationTypeModule THEN 'Entered Certification Type Already Exits!'
														WHEN @ModuleId = @LeadSource THEN 'Entered LeadSource Already Exits!'
														WHEN @ModuleId = @UnitOfMeasureModule THEN 'Entered Data Already Exits!'
														WHEN @ModuleId = @AssetAcquisitionTypeModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exits!'
														WHEN @ModuleId = @AssetAcquisitionTypeModule AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Acquisition Type Already Exits!'
														WHEN @ModuleId = @AssetAcquisitionTypeModule AND @ChekDuplticateRef1 = 'Code'
															THEN 'Entered Acquisition Code Already Exits!'
														WHEN @ModuleId = @DocumentTypeModule THEN 'Entered Document Type Already Exits!'
														WHEN @ModuleId = @ShippingViaModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @POROCategory THEN 'Entered PORO Category Name Already Exits!'
														WHEN @ModuleId = @CapabilityTypeModule AND @ChekDuplticateRef1 = 'CapabilityTypeDesc'
															THEN 'Entered Work scope/Cap Type Already Exits!'
														WHEN @ModuleId = @CapabilityTypeModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exits!'
														WHEN @ModuleId = @CapabilityTypeModule AND @ChekDuplticateRef1 = 'Description'
															THEN 'Entered Description Already Exits!'
														WHEN @ModuleId = @VendorClassificationModule THEN 'Entered Vendor Classification Name Already Exits!'
														WHEN @ModuleId = @chargeModule AND @ChekDuplticateRef1 = 'ChargeType'
															THEN 'Entered ChargeType Already Exits!'
														WHEN @ModuleId = @chargeModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered SequenceNo Already Exits!'
														WHEN @ModuleId = @PriorityModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @CodePrefixesModule THEN 'Entered Code Type Already Exits!'
														WHEN @ModuleId = @ContactTagModule THEN 'Entered Type Name Already Exits!'
														WHEN @ModuleId = @wingtypeModule THEN 'Entered Wing Type Already Exits!'
														WHEN @ModuleId = @VendorRMAReturnReasonModule THEN 'Entered Reason Already Exits!'
														WHEN @ModuleId = @ShippingTermsModule AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Shipping Term Name Already Exits!'
														WHEN @ModuleId = @ShippingTermsModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exits!'
														WHEN @ModuleId = @TermsConditionModule THEN 'Entered Template Name Already Exits!'
														WHEN @ModuleId = @InvoiceDeliveryPrefStatus AND @ChekDuplticateRef1 = 'Status'
															THEN 'Entered Status Already Exits!'
														WHEN @ModuleId = @InvoiceDeliveryPrefStatus AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exits!'
														WHEN @ModuleId = @ExchangeCoreLetterType AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @ExchangeCoreLetterType AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exits!'
														WHEN @ModuleId = @VendorAuditTypeModule THEN 'Entered Vendor Audit Type Already Exits!'
														WHEN @ModuleId = @VendorStatusModule THEN 'Entered Vendor Status Already Exits!'
														WHEN @ModuleId = @RankingModule THEN 'Entered Description Already Exits!'
														WHEN @ModuleId = @CustomerSettingsModule THEN 'Entered LegalEntity Already Exits!'
														WHEN @ModuleId = @CustomerClassificationModule AND @ChekDuplticateRef1 = 'Description'
															THEN 'Entered Classification name Already Exits!'
														WHEN @ModuleId = @CustomerClassificationModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exits!'
														WHEN @ModuleId = @TaxTypeModule THEN 'Entered Description Already Exits!'
														WHEN @ModuleId = @creditTermsModule THEN 'Entered Credit Term Name Already Exits!'
														WHEN @ModuleId = @PercentModule THEN 'Entered Percent Already Exits!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'countries_name'
															THEN 'Entered Country Name Already Exists!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'nice_name'
															THEN 'Entered Nice Name Already Exists!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'countries_iso_code'
															THEN 'Entered Country ISO Code Already Exists!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'countries_iso3'
															THEN 'Entered Country ISO3 Already Exists!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'countries_numcode'
															THEN 'Entered Country Number Code Already Exists!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'countries_isd_code'
															THEN 'Entered Country ISD Code Already Exists!'
														WHEN @ModuleId = @CountriesModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence Number Already Exists!'
														WHEN @ModuleId = @TagTypeModule THEN 'Entered Tag Type Already Exits!'
														WHEN @ModuleId = @CustomerTypeModule THEN 'Entered Customer Type Already Exits!'
														WHEN @ModuleId = @AircraftTypeModule THEN 'Entered AircraftType Already Exits!'
														WHEN @ModuleId = @AircraftModelModule THEN 'Entered Model Name Already Exits!'
														WHEN @ModuleId = @AircraftDashNumber THEN 'Entered Dash Number Already Exits!'
														WHEN @ModuleId = @EccnDeterminationSource THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @LotCostSourceReference AND @ChekDuplticateRef1 = 'SourceName'
															THEN 'Entered Source Name Already Exists!'
														WHEN @ModuleId = @LotCostSourceReference AND @ChekDuplticateRef1 = 'Code'
															THEN 'Entered Source Code Already Exists!'
														WHEN @ModuleId = @StandardModule THEN 'Entered Standard Name Already Exits!'
														WHEN @ModuleId = @ItemGroupModule THEN 'Entered Item Group Already Exits!'
														WHEN @ModuleId = @ItemClassificationModule THEN 'Entered Classification Code Already Exits!'
														WHEN @ModuleId = @ManufacturerModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @ATAReferenceModule THEN 'Entered ATAReference Already Exits!'
														WHEN @ModuleId = @ATAChapterModule THEN 'Entered Chapter Code Already Exits!'
														WHEN @ModuleId = @TangibleClassModule THEN 'Entered Tangible Class Name Already Exits!'
														WHEN @ModuleId = @AssetIntangibleTypeModule AND @ChekDuplticateRef1 = 'AssetIntangibleName'
															THEN 'Entered Intangible Asset Class Already Exists!'
														WHEN @ModuleId = @AssetIntangibleTypeModule AND @ChekDuplticateRef1 = 'AssetIntangibleCode'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetStatusModule THEN 'Entered Asset Status Name Already Exits!'
														WHEN @ModuleId = @AssetLocationModule AND @ChekDuplticateRef1 = 'Code'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetLocationModule AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Asset Location Already Exists!'
														WHEN @ModuleId = @AssetDisposalTypeModule AND @ChekDuplticateRef1 = 'AssetDisposalCode'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetDisposalTypeModule AND @ChekDuplticateRef1 = 'AssetDisposalName'
															THEN 'Entered Asset Disposal Type Name Already Exists!'
														WHEN @ModuleId = @AssetDepreciationMethodModule AND @ChekDuplticateRef1 = 'AssetDepreciationMethodCode'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetDepreciationMethodModule AND @ChekDuplticateRef1 = 'AssetDepreciationMethodName'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @AssetDepreciationMethodModule AND @ChekDuplticateRef1 = 'AssetDepreciationMethodBasis'
															THEN 'Entered Method Basis Already Exists!'
														WHEN @ModuleId = @AssetDepreciationMethodModule AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exists!'
														WHEN @ModuleId = @AssetDepConventionModule AND @ChekDuplticateRef1 = 'AssetDepConventionCode'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetDepConventionModule AND @ChekDuplticateRef1 = 'AssetDepConventionName'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @AssetDepreciationFrequencyModule AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @AssetDepreciationFrequencyModule AND @ChekDuplticateRef1 = 'Description'
															THEN 'Entered Description Already Exists!'
														WHEN @ModuleId = @AssetDepreciationIntervalModule AND @ChekDuplticateRef1 = 'AssetDepreciationIntervalCode'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetDepreciationIntervalModule AND @ChekDuplticateRef1 = 'AssetDepreciationIntervalName'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @AssetAttributeTypeModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @SiteModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @WarehouseModule THEN 'Entered Name Already Exits!'
														--WHEN @ModuleId = @LocationModule THEN 'Entered Name Already Exits!'
														WHEN @ModuleId = @FindingModule AND @ChekDuplticateRef1 = 'FindingCode'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @FindingModule AND @ChekDuplticateRef1 = 'Description'
															THEN 'Entered Description Already Exists!'
														WHEN @ModuleId = @InvoiceType AND @ChekDuplticateRef1 = 'Description'
															THEN 'Entered Description Already Exists!'
														WHEN @ModuleId = @OrganizationTagType AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @ManagementStructureLevelModule AND @ChekDuplticateRef1 = 'Code'
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @AssetAttributeType AND @ChekDuplticateRef1 = 'AssetAttributeTypeName'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @BalanceTypeModule AND @ChekDuplticateRef1 = 'BalanceTypeName'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @LedgerModule AND @ChekDuplticateRef1 = 'LedgerName'
															THEN 'Entered Ledger Name Already Exists!'
														WHEN @ModuleId = @Master1099Module AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @Master1099Module AND @ChekDuplticateRef1 = 'SequenceNo'
															THEN 'Entered Sequence No Already Exists!'
														WHEN @ModuleId = @Master1099Module AND @ChekDuplticateRef1 = 'Description'
															THEN 'Entered Description Already Exists!'
														WHEN @ModuleId = @RMAReasonModule AND @ChekDuplticateRef1 = 'Reason'  
															THEN 'Entered Reason Already Exists!'
														WHEN @ModuleId = @CreditMemoReasonModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Credit Memo Reason Already Exists!'
														WHEN @ModuleId = @InventoryGLSettingModule AND @ChekDuplticateRef1 = 'StockInventoryName'  
															THEN 'Entered Item Accounting Type Already Exists!'
														WHEN @ModuleId = @GLCashFlowClassificationModule AND @ChekDuplticateRef1 = 'GLClassFlowClassificationName'  
															THEN 'Entered Classification Already Exists!'
														WHEN @ModuleId = @CurrencyModule AND @ChekDuplticateRef1 = 'Code'  
															THEN 'Entered Code Already Exists!'
														WHEN @ModuleId = @MasterDiscountTypeModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Discount Type Already Exists!'
														WHEN @ModuleId = @MasterBankFeesTypeModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Bank Fees Type Already Exists!'
														WHEN @ModuleId = @MasterAdjustReasonModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Adjust Reason Already Exists!'
														WHEN @ModuleId = @JobTitleModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Job Title Name Already Exists!'
														WHEN @ModuleId = @EmployeeLeaveTypeModule AND @ChekDuplticateRef1 = 'LeaveType'  
															THEN 'Entered Employee Leave Type Already Exists!'
														WHEN @ModuleId = @EmployeeStationModule AND @ChekDuplticateRef1 = 'StationName'  
															THEN 'Entered Employee Station Name Already Exists!'
														WHEN @ModuleId = @EmployeeCertificationTypeModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Employee Certification Type Already Exists!'
														WHEN @ModuleId = @EmployeeTrainingTypeModule AND @ChekDuplticateRef1 = 'TrainingType'  
															THEN 'Entered Employee Training Type Already Exists!'
														WHEN @ModuleId = @EmployeeExpertiseModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Expertise Name Already Exists!'
														WHEN @ModuleId = @TaxRateModule AND @ChekDuplticateRef1 = 'TaxRate'  
															THEN 'Entered TaxRate Already Exists!'
														WHEN @ModuleId = @stocklineadjustmentreasonModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Adjustment Reason Already Exists!'
														WHEN @ModuleId = @WorkOrderStageModule AND @ChekDuplticateRef1 = 'Code'  
															THEN 'Entered Stage Code Already Exists!'
														WHEN @ModuleId = @WorkOrderStageModule AND @ChekDuplticateRef1 = 'Stage'  
															THEN 'Entered Stage Already Exists!'
														WHEN @ModuleId = @WorkOrderStageModule AND @ChekDuplticateRef1 = 'Sequence'  
															THEN 'Entered Sequence No Already Exists!'
														WHEN @ModuleId = @CommonTeardownTypeModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @CommonTeardownTypeModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Description Already Exists!'
														WHEN @ModuleId = @CommonTeardownTypeModule AND @ChekDuplticateRef1 = 'Sequence'  
															THEN 'Entered Sequence No Already Exists!'
														WHEN @ModuleId = @TeardownReasonModule AND @ChekDuplticateRef1 = 'Reason'  
															THEN 'Entered Default Entries Already Exists!'
														WHEN @ModuleId = @WorkPerformedModule AND @ChekDuplticateRef1 = 'WorkPerformedCode'  
															THEN 'Entered Work Performed Code Already Exists!'
														WHEN @ModuleId = @TaskStatusModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Task Status Already Exists!'
														WHEN @ModuleId = @ScrapreasonModule AND @ChekDuplticateRef1 = 'Reason'  
															THEN 'Entered Reason Already Exists!'
														WHEN @ModuleId = @EvidenceModule AND @ChekDuplticateRef1 = 'EvidenceName'  
															THEN 'Entered Evidence Already Exists!'
														WHEN @ModuleId = @LocationModule 
															THEN 'Entered Location Name Already Exists In This Warehouse !'
														WHEN @ModuleId = @PublicationTypeModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Pub Name Already Exists!'
														WHEN @ModuleId = @PublicationTypeModule AND @ChekDuplticateRef1 = 'Description'  
															THEN 'Entered Description Already Exists!'
														WHEN @ModuleId = @ShelfModule 
															THEN 'Entered Shelf Name Already Exists In This Location !'
														WHEN @ModuleId = @BinModule 
															THEN 'Entered Bin Name Already Exists In This Shelf !'
														WHEN @ModuleId = @AircraftStatusModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @MaintenanceStatusModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Name Already Exists!'
														WHEN @ModuleId = @AircraftStatusModule AND @ChekDuplticateRef1 = 'SequenceNo'  
															THEN 'Entered SequenceNo Already Exists!'
														WHEN @ModuleId = @MaintenanceStatusModule AND @ChekDuplticateRef1 = 'SequenceNo'  
															THEN 'Entered SequenceNo Already Exists!'
														WHEN @ModuleId = @TrainingNameModule AND @ChekDuplticateRef1 = 'Name'  
															THEN 'Entered Name Already Exists!'	
														WHEN @ModuleId = @PositionCodeModule AND @ChekDuplticateRef1 = 'Code'  
															THEN 'Entered Code Already Exists!'	
														WHEN @ModuleId = @MaintenanceTypeModule AND @ChekDuplticateRef1 = 'MaintenanceType'  
															THEN 'Entered Maintenance Type Already Exists!'	
														WHEN @ModuleId = @MaintenanceClassModule AND @ChekDuplticateRef1 = 'Name'
															THEN 'Entered Name Already Exists!'	
															
														ELSE '' END
						WHERE ImportModuleFieldMasterId = @CurrentRow;
					END
				END
				
				SET @CurrentRow += 1;
			END
			
			if (@ModuleId = @StocklineModule  OR @ModuleId = @PriceMasterModule OR @ModuleId = @MROPriceMasterModule   OR @ModuleId = @MROPriceMasterListModule )
			BEGIN
				SELECT @ManufacturerId = FieldValue 
				FROM #ImportFields 
				WHERE FieldName = 'ManufacturerId';
			
				--  Check if 'PartNumber' is present in ImportFields
				IF EXISTS (
					SELECT 1 
					FROM #ImportFields 
					WHERE DropdownListValue = 'PartNumber' AND ModuleId = @ModuleId
				)
				BEGIN
					--  Get all matching ManufacturerIds based on PartNumber(s)
					--DECLARE @MatchingManufacturerIds TABLE (ManufacturerId BIGINT, ManufacturerName NVARCHAR(200));

				IF EXISTS (
					SELECT 1
					FROM ItemMaster IM
					WHERE IM.ManufacturerName = @ManufacturerId
						  AND ISNULL(IM.IsDeleted,0) = 0 
						  AND ISNULL(IM.IsActive,0) = 1
						  AND IM.MasterCompanyId = @MasterCompanyId
				)
				BEGIN
					-- Case 1: @ManufacturerId is actually a ManufacturerName
					INSERT INTO @MatchingManufacturerIds (ManufacturerId, ManufacturerName, partnumber, PartNumberId)
					SELECT DISTINCT IM.ManufacturerId, IM.ManufacturerName, Im.partnumber, Im.ItemMasterId
					FROM ItemMaster IM
					JOIN #ImportFields IMF ON IMF.FieldValue = IM.PartNumber
					WHERE IMF.ModuleId = @ModuleId
					  AND IMF.DropdownListValue = 'PartNumber'
					  AND ISNULL(IM.IsDeleted,0) = 0
					  AND ISNULL(IM.IsActive,0) = 1
					  AND IM.MasterCompanyId = @MasterCompanyId
					  AND IM.ManufacturerName = @ManufacturerId;
				END
				ELSE
				BEGIN
					-- Case 2: @ManufacturerId is NOT a ManufacturerName (treat it as before)
					INSERT INTO @MatchingManufacturerIds (ManufacturerId, ManufacturerName, partnumber, PartNumberId)
					SELECT DISTINCT IM.ManufacturerId, IM.ManufacturerName, Im.partnumber, Im.ItemMasterId
					FROM ItemMaster IM
					JOIN #ImportFields IMF ON IMF.FieldValue = IM.PartNumber
					WHERE IMF.ModuleId = @ModuleId
					  AND IMF.DropdownListValue = 'PartNumber'
					  AND ISNULL(IM.IsDeleted,0) = 0
					  AND ISNULL(IM.IsActive,0) = 1
					  AND IM.MasterCompanyId = @MasterCompanyId;
				END

				
							Update IMF SET IMF.DropdownListValueId = MNF.PartNumberId FROM #ImportFields IMF 
									INNER JOIN ItemMaster IM WITH(NOLOCK) ON IM.partnumber = IMF.FieldValue  
									INNER JOIN @MatchingManufacturerIds MNF ON IM.partnumber = MNF.PartNumber AND MNF.PartNumber = IMF.FieldValue
									WHERE IMF.ModuleId = @ModuleId
											  AND IMF.DropdownListValue = 'PartNumber'
											  AND ISNULL(IM.IsDeleted,0) = 0
											  AND ISNULL(IM.IsActive,0) = 1
											  AND IM.MasterCompanyId = @MasterCompanyId;
							

					--  Check how many different manufacturers were found
					IF ((SELECT COUNT(*) FROM @MatchingManufacturerIds) > 1)
					BEGIN
					--  If @ManufacturerId matches any from the list, do nothing
						IF EXISTS (
							SELECT 1 
							FROM @MatchingManufacturerIds 
							WHERE ManufacturerName = @ManufacturerId
						)
						BEGIN
					
							SET @ManufacturerName = @ManufacturerId;
						END
						ELSE
						BEGIN
							--  Pick first manufacturer and set @ManufacturerName
							SELECT TOP 1 
								--@ManufacturerId = ManufacturerName,
								@ManufacturerName = ManufacturerName
							FROM @MatchingManufacturerIds
							ORDER BY ManufacturerName ASC;
						END
					END
					ELSE
					BEGIN
						-- Only one manufacturer found - assign directly
						SELECT TOP 1 
							--@ManufacturerId = ManufacturerName,
							@ManufacturerName = ManufacturerName
						FROM @MatchingManufacturerIds;
					END
				END

				--SET @Manufacture = @ManufacturerId;
				--SET @ManufacturerId = @ManufacturerName;
			END
			UPDATE TMP
			SET TMP.[RecordStatus] =	CASE	WHEN ISNULL(TMP.[RecordStatus], '') != '' THEN TMP.[RecordStatus]
												WHEN ISNULL(IMF.DuplicateErrorMsg, '') != '' THEN IMF.DuplicateErrorMsg
												
												WHEN ISNULL(TMP.FieldValue, '') != '' AND (IMF.FieldName = 'Email' OR IMF.FieldName = 'VendorEmail')
													AND (
														TMP.FieldValue NOT LIKE '%@%._%' 
													)
													THEN 'Email is not in a valid format'
												WHEN ISNULL(TMP.FieldValue, '') != '' AND IMF.FieldName = 'QuantityOnHand'
													AND (
														--TRY_CAST(TMP.FieldValue AS INT) IS NULL OR TRY_CAST(TMP.FieldValue AS INT) <= 0
														TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) IS NULL 
														OR TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) <= 0
													)
													THEN 'QuantityOnHand must be a whole number greater than 0'
												    WHEN IMF.FieldName = 'QuantityOnHand'
													 AND (
														 SELECT LOWER(FieldValue)
														 FROM #DynamicKeyValue
														 WHERE FieldName = 'isSerialized' 
													 ) = 'yes'
													 AND TRY_CAST(TMP.FieldValue AS INT) != 1
													 THEN 'Qty OH must be one for Serialized Parts'
												WHEN ISNULL(TMP.FieldValue, '') != '' 
													 AND IMF.FieldName IN ('UnitSalesPrice', 'UnitCost')
													 AND TRY_CAST(TMP.FieldValue AS DECIMAL(18,2)) IS NULL
												THEN IMF.FieldName + ' must be a valid number'

												WHEN ISNULL(TMP.FieldValue, '') != '' AND (IMF.FieldName = 'isAddressForBilling' OR IMF.FieldName = 'isAddressForShipping') AND (LOWER(TMP.FieldValue) NOT IN ('yes','no'))
													THEN IMF.FieldName + ' must be YES OR NO'
												WHEN (@ModuleId = @DiscountModule)
													 AND ISNULL(TMP.FieldValue, '') <> '' 
													 AND IMF.FieldName = 'DiscontValue' 
													 AND (TRY_CAST(TMP.FieldValue AS INT) IS NULL
														 OR TRY_CAST(TMP.FieldValue AS INT) < 1  
														 OR TRY_CAST(TMP.FieldValue AS INT) > 100)
												THEN 'Discount Value must be a whole number between 1 and 100'
												--WHEN IMF.DropdownListValue = 'PartNumber' AND @ManufacturerId IS NOT NULL AND @ManufacturerName IS NOT NULL 
												--	AND LOWER(@ManufacturerId) != LOWER(@ManufacturerName) THEN 'Incorrect Manufacturer'
												WHEN ISNULL(IMF.IsRequired, 0) = 1 AND ISNULL(IMF.DropdownListType, '') != '' 
													 AND ISNULL(IMF.DropdownListValueId, '') = '' AND ISNULL(IMF.ReferenceColumn, '') != '' THEN 'Pleas Enter Correct Pair of ' + IMF.HeaderName + ' ' + IMF.ReferenceColumn
										ELSE ''
										END,
				TMP.FieldValue = CASE WHEN ISNULL(IMF.DropdownListTable, '') != '' THEN IMF.DropdownListValueId ELSE TMP.FieldValue END
			FROM #ImportFields IMF WITH(NOLOCK)
			LEFT JOIN #DynamicKeyValue TMP ON TMP.FieldName = IMF.FieldName
			WHERE IMF.[ModuleId] = @ModuleId
			SELECT @Erorr = COALESCE(@Erorr + ',  ' + [RecordStatus], [RecordStatus]) FROM #DynamicKeyValue WHERE ISNULL([RecordStatus], '') != '';
			
			if (@ModuleId = @StocklineModule OR @ModuleId = @PriceMasterModule)  
			BEGIN
				IF @Manufacture IS NOT NULL AND
				   LOWER(@ManufacturerId) <> LOWER(@ManufacturerName)
				BEGIN
					-- Update the ManufacturerId in #DynamicKeyValue
					UPDATE #DynamicKeyValue
					SET FieldValue = @ManufacturerName
					WHERE FieldName = 'ManufacturerId';
				END
			END
			--SELECT * FROM #DynamicKeyValue
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

			if (@ModuleId = @StocklineModule OR @ModuleId = @PriceMasterModule)
			BEGIN
				UPDATE #uploadDataResults 
				SET 
					OriginalRecordData = JSON_MODIFY(OriginalRecordData, '$.ManufacturerId', @ManufacturerName) WHERE RecordId = @CurrentRecord;
			END
			
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
	END CATCH    
END