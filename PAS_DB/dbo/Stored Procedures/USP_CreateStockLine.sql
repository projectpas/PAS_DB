/*************************************************************           
 ** File:   [USP_CreateStockLine]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Stock Line
 ** Purpose:         
 ** Date:   10/12/2025   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author			Change Description            
 ** --   --------      -------			--------------------------------          
    1    10/12/2025    Moin Bloch		Created
	3    02/MAR/2026   Priyansh Patel	Added PoPartUnitCost param for po cost in stockline
	4    26/MAY/2026   Priyansh Patel 	Added new field 'TTSN, TCSN '(PN-16477)
	5    27/05/2026    Ayushi Patel     [PN-16476]Sync CSN, CSO, TSN, TSO in WorkOrderPartNumber on StockLine TimeLife update
	7    30/06/2026    Nakul Chandigra  Added new field 'Note' [Note] [PN-17012]
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	9    07/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory into Stockline : Accept and persist IsNonStock, Currency, CurrencyId on Insert/Update
	10    08/July/2026			 RAJESH GAMI						[PN-17009] - Accept and persist ItemNonStockClassificationId, NonStockClassification on Insert/Update
	11   29/July/2026  Ayushi Patel     Added new field 'IsService' for Non-Stock items (1=Service, 0=Non-Service)[PN-17470]
--   EXEC [USP_CreateStockLine]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateStockLine]
@StockLineId BIGINT = NULL,
@PartNumber VARCHAR(50) = NULL,
@StockLineNumber VARCHAR(50) = NULL,
@StocklineMatchKey VARCHAR(100) = NULL,
@ControlNumber VARCHAR(50) = NULL,
@ItemMasterId BIGINT = NULL,
@Quantity INT = NULL,
@ConditionId BIGINT,
@SerialNumber VARCHAR(30) = NULL,
@ShelfLife BIT = NULL,
@ShelfLifeExpirationDate DATETIME2(7) = NULL,
@WarehouseId BIGINT = NULL,
@LocationId BIGINT = NULL,
@ObtainFrom BIGINT = NULL,
@Owner BIGINT = NULL,
@TraceableTo BIGINT = NULL,
@ManufacturerId BIGINT = NULL,
@Manufacturer VARCHAR(50) = NULL,
@ManufacturerLotNumber VARCHAR(50) = NULL,
@ManufacturingDate DATETIME2(7) = NULL,
@ManufacturingBatchNumber VARCHAR(50) = NULL,
@PartCertificationNumber VARCHAR(50) = NULL,
@CertifiedBy VARCHAR(100) = NULL,
@CertifiedDate DATETIME2(7) = NULL,
@TagDate DATETIME2(7) = NULL,
@TagType VARCHAR(500) = NULL,
@CertifiedDueDate DATETIME2(7) = NULL,
@CalibrationMemo NVARCHAR(MAX) = NULL,
@OrderDate DATETIME2(7) = NULL,
@PurchaseOrderId BIGINT = NULL,
@PurchaseOrderUnitCost DECIMAL(18,2) = NULL,
@InventoryUnitCost DECIMAL(18,2) = NULL,
@RepairOrderId BIGINT = NULL,
@RepairOrderUnitCost DECIMAL(18,2) = NULL,
@ReceivedDate DATETIME2(7) = NULL,
@ReceiverNumber VARCHAR(50) = NULL,
@ReconciliationNumber VARCHAR(50) = NULL,
@UnitSalesPrice DECIMAL(18,2) = NULL,
@CoreUnitCost DECIMAL(18,2) = NULL,
@GLAccountId BIGINT = NULL,
@AssetId BIGINT = NULL,
@IsHazardousMaterial BIT = NULL,
@IsNonStock BIT = NULL,
@Currency VARCHAR(100) = NULL,
@CurrencyId BIGINT = NULL,
@ItemNonStockClassificationId BIGINT = NULL,
@NonStockClassification VARCHAR(100) = NULL,
@IsPMA BIT = NULL,
@IsDER BIT= NULL,
@OEM BIT= NULL,
@Memo NVARCHAR(MAX) = NULL,
@ManagementStructureId BIGINT = NULL,
@LegalEntityId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@CreatedDate DATETIME2(7) = NULL,
@UpdatedDate DATETIME2(7) = NULL,
@IsSerialized BIT = NULL,
@ShelfId BIGINT = NULL,
@BinId BIGINT = NULL,
@SiteId BIGINT = NULL,
@ObtainFromType INT = NULL,
@OwnerType INT = NULL,
@TraceableToType INT = NULL,
@UnitCostAdjustmentReasonTypeId INT = NULL,
@UnitSalePriceAdjustmentReasonTypeId INT = NULL,
@IdNumber VARCHAR(100) = NULL,
@QuantityToReceive INT = NULL,
@PurchaseOrderExtendedCost DECIMAL(18,0) = NULL,
@ManufacturingTrace NVARCHAR(200) = NULL,
@ExpirationDate DATETIME2(7) = NULL,
@AircraftTailNumber NVARCHAR(200) = NULL,
@ShippingViaId BIGINT = NULL,
@EngineSerialNumber NVARCHAR(200) = NULL,
@QuantityRejected INT = NULL,
@PurchaseOrderPartRecordId BIGINT = NULL,
@ShippingAccount NVARCHAR(200) = NULL,
@ShippingReference NVARCHAR(200) = NULL,
@TimeLifeCyclesId BIGINT = NULL,
@TimeLifeDetailsNotProvided BIT = NULL,
@WorkOrderId BIGINT = NULL,
@WorkOrderMaterialsId BIGINT = NULL,
@QuantityReserved INT = NULL,
@QuantityTurnIn INT = NULL,
@QuantityIssued INT = NULL,
@QuantityOnHand INT = NULL,
@QuantityAvailable INT = NULL,
@QuantityOnOrder INT = NULL,
@QtyReserved INT = NULL,
@QtyIssued INT = NULL,
@BlackListed BIT = NULL,
@BlackListedReason VARCHAR(MAX) = NULL,
@Incident BIT = NULL,
@IncidentReason VARCHAR(MAX) = NULL,
@Accident BIT = NULL,
@AccidentReason VARCHAR(MAX) = NULL,
@RepairOrderPartRecordId BIGINT = NULL,
@isActive BIT = NULL,
@isDeleted BIT = NULL,
@WorkOrderExtendedCost DECIMAL(20,2) = NULL,
@RepairOrderExtendedCost DECIMAL(18,2) = NULL,
@IsCustomerStock BIT = NULL,
@EntryDate datetime = NULL,
@LotCost DECIMAL(18,2) = NULL,
@NHAItemMasterId BIGINT = NULL,
@TLAItemMasterId BIGINT = NULL,
@ItemTypeId INT = NULL,
@AcquistionTypeId BIGINT = NULL,
@RequestorId BIGINT = NULL,
@LotNumber VARCHAR(50) = NULL,
@LotDescription VARCHAR(250) = NULL,
@TagNumber VARCHAR(50) = NULL,
@InspectionBy BIGINT = NULL,
@InspectionDate DATETIME2(7) = NULL,
@VendorId BIGINT = NULL,
@IsParent BIT = NULL,
@ParentId BIGINT = NULL,
@IsSameDetailsForAllParts BIT = NULL,
@WorkOrderPartNoId BIGINT = NULL,
@SubWorkOrderId BIGINT = NULL,
@SubWOPartNoId BIGINT = NULL,
@IsOemPNId BIGINT = NULL,
@PurchaseUnitOfMeasureId BIGINT = NULL,
@ObtainFromName VARCHAR(100) = NULL,
@OwnerName VARCHAR(100) = NULL,
@TraceableToName VARCHAR(50) = NULL,
@Level1 VARCHAR(100) = NULL,
@Level2 VARCHAR(100) = NULL,
@Level3 VARCHAR(100) = NULL,
@Level4 VARCHAR(100) = NULL,
@Condition VARCHAR(100) = NULL,
@GlAccountName VARCHAR(100) = NULL,
@Site VARCHAR(100) = NULL,
@Warehouse VARCHAR(100) = NULL,
@Location VARCHAR(100) = NULL,
@Shelf VARCHAR(100) = NULL,
@Bin VARCHAR(100) = NULL,
@UnitOfMeasure VARCHAR(100) = NULL,
@WorkOrderNumber VARCHAR(500) = NULL,
@itemGroup VARCHAR(256) = NULL,
@TLAPartNumber VARCHAR(100) = NULL,
@NHAPartNumber VARCHAR(100) = NULL,
@TLAPartDescription NVARCHAR(MAX) = NULL,
@NHAPartDescription NVARCHAR(MAX) = NULL,
@itemType VARCHAR(100) = NULL,
@CustomerId BIGINT = NULL,
@CustomerName VARCHAR(200) = NULL,
@isCustomerstockType BIT = NULL,
@PNDescription NVARCHAR(MAX) = NULL,
@RevicedPNId BIGINT = NULL,
@RevicedPNNumber NVARCHAR(50) = NULL,
@OEMPNNumber NVARCHAR(50) = NULL,
@TaggedBy BIGINT = NULL,
@TaggedByName NVARCHAR(50) = NULL,
@UnitCost DECIMAL(18,2) = NULL,
@TaggedByType INT = NULL,
@TaggedByTypeName VARCHAR(250) = NULL,
@CertifiedById BIGINT = NULL,
@CertifiedTypeId INT = NULL,
@CertifiedType VARCHAR(250) = NULL,
@CertTypeId VARCHAR(MAX) = NULL,
@CertType VARCHAR(MAX) = NULL,
@TagTypeId BIGINT = NULL,
@IsFinishGood BIT = NULL,
@IsTurnIn BIT = NULL,
@IsCustomerRMA BIT = NULL,
@RMADeatilsId BIGINT = NULL,
@DaysReceived INT = NULL,
@ManufacturingDays INT = NULL,
@TagDays INT = NULL,
@OpenDays INT = NULL,
@ExchangeSalesOrderId BIGINT = NULL,
@RRQty INT = NULL,
@SubWorkOrderNumber VARCHAR(50) = NULL,
@IsManualEntry BIT = NULL,
@WorkOrderMaterialsKitId BIGINT = NULL,
@LotId BIGINT = NULL,
@IsLotAssigned BIT = NULL,
@LOTQty INT = NULL,
@LOTQtyReserve INT = NULL,
@OriginalCost DECIMAL(18,2) = NULL,
@POOriginalCost DECIMAL(18,2) = NULL,
@ROOriginalCost DECIMAL(18,2) = NULL,
@VendorRMAId BIGINT = NULL,
@VendorRMADetailId BIGINT = NULL,
@LotMainStocklineId BIGINT = NULL,
@IsFromInitialPO BIT = NULL,
@LotSourceId INT = NULL,
@Adjustment DECIMAL(18,2) = NULL,
@SalesOrderPartId BIGINT = NULL,
@FreightAdjustment DECIMAL(18,2) = NULL,
@TaxAdjustment DECIMAL(18,2) = NULL,
@IsStkTimeLife BIT = NULL,
@SalesPriceExpiryDate DATETIME2(7) = NULL,
@SubWorkOrderMaterialsId BIGINT = NULL,
@SubWorkOrderMaterialsKitId BIGINT = NULL,
@EvidenceId INT = NULL,
@INTegrationPortal VARCHAR(50) = NULL,
@IsGenerateReleaseForm BIT = NULL,
@ExistingCustomerId BIGINT = NULL,
@RepairOrderNumber VARCHAR(100) = NULL,
@ExistingCustomer VARCHAR(200) = NULL,
@QuickBooksReferenceId VARCHAR(200) = NULL,
@IsUpdated BIT = NULL,
@LastSyncDate DATETIME2(7) = NULL,
@InventoryGLSettingId BIGINT = NULL,
@InventoryGLAccName VARCHAR(255) = NULL,
@GoodsReceivedNotInvoicesGLAccId BIGINT = NULL,
@GoodsReceivedNotInvoicesGLAccName VARCHAR(255) = NULL,
@WorkInProgressGLAccId BIGINT = NULL,
@WorkInProgressGLAccName VARCHAR(255) = NULL,
@InventoryToBillGLAccId BIGINT = NULL,
@InventoryToBillGLAccName VARCHAR(255) = NULL,
@FinishedGoodsGLAccId BIGINT = NULL,
@FinishedGoodsGLAccName VARCHAR(255) = NULL,
@InventoryExchAgreementGLAccId BIGINT = NULL,
@InventoryExchAgreementGLAccName VARCHAR(255) = NULL,
@InventoryReserveGLAccId BIGINT = NULL,
@InventoryReserveGLAccName VARCHAR(255) = NULL,
@COGS_WorkOrderGLAccId BIGINT = NULL,
@COGS_WorkOrderGLAccName VARCHAR(255) = NULL,
@COGS_SalesOrderGLAccId BIGINT = NULL,
@COGS_SalesOrderGLAccName VARCHAR(255) = NULL,
@COGS_QtyVarianceGLAccId BIGINT = NULL,
@COGS_QtyVarianceGLAccName VARCHAR(255) = NULL,
@COGS_UnitCostVarianceGLAccId BIGINT = NULL,
@COGS_UnitCostVarianceGLAccName VARCHAR(255) = NULL,
@RevenueMroGLAccId BIGINT = NULL,
@RevenueMroGLAccName VARCHAR(255) = NULL,
@RevenueSoGLAccId BIGINT = NULL,
@RevenueSoGLAccName VARCHAR(255) = NULL,
@RevenueExchGLAccId BIGINT = NULL,
@RevenueExchGLAccName VARCHAR(255) = NULL,
@COGS_ExchSalesOrderGLAccId BIGINT = NULL,
@COGS_ExchSalesOrderGLAccName VARCHAR(255) = NULL,
@QuantityAdjustment INT = NULL,
@IsPiecePart BIT = NULL,
@IsRepairManagement BIT = NULL,
@IsDocument BIT = NULL,
@PurchaseOrderNumber VARCHAR(50) = NULL,
@IsBatchStock BIT = NULL,
@BatchNumber VARCHAR(50) = NULL,
@NationalStockNumber VARCHAR(100) = NULL,
@ExportECCN VARCHAR(200) = NULL,
@ITARNumber VARCHAR(200) = NULL,
@AccountPayableglAccountId BIGINT = NULL,
@tbl_TimeLifeType TimeLifeType READONLY,
@PoPartUnitCost DECIMAL(18,2) = NULL,
@TotalTSN DECIMAL(18,2) = NULL,
@TotalCSN DECIMAL(18,2) = NULL,
@TotalTSNMM DECIMAL(18,6) = NULL,
@TotalCSNMM DECIMAL(18,6) = NULL,
@Note NVARCHAR(MAX) = NULL,
@IsService BIT = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
    -- Declare variables
	  DECLARE @ErrorMsg VARCHAR(100)='',@UniqStockLineId BIGINT=NULL,@StkManagementStructureModuleId BIGINT;
	  DECLARE @UniqItemMasterId BIGINT=NULL,@IsTimeLife BIT
	  DECLARE @ItemMasterExportInfoId BIGINT=NULL,@MSLegalEntityId BIGINT=NULL
	  DECLARE @StocklineCodeType INT=0,@ControlNumberCodeType INT=0,@IdNumberCodeType INT=0,@StockLineModuleID INT=0

	---- Code Types Of CodePrefix	
	  SELECT @StocklineCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Stock Line';	
	  SELECT @ControlNumberCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Control Number';
	  SELECT @IdNumberCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Id Number';	
		
	-- Modules
	  SELECT @StockLineModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='StockLine';

	-- Management Structure Module
	  SELECT @StkManagementStructureModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';
		
	  SET @CreatedDate = GETUTCDATE();
      SET @UpdatedDate = GETUTCDATE();


	  IF(ISNULL(@StockLineId,0) = 0)
	  BEGIN
		IF OBJECT_ID(N'tempdb..#TempPNManufacturerCombinationTable') IS NOT NULL
		BEGIN
			DROP TABLE #TempPNManufacturerCombinationTable
		END

		CREATE TABLE #TempPNManufacturerCombinationTable
		(
			[ItemMasterId] BIGINT NULL,
			[ManufacturerId] BIGINT NULL,
			[StockLineNumber] VARCHAR(50) NULL,
			[CurrentStlNo] BIGINT NULL,
			[isSerialized] BIT NULL
		)

	    DECLARE @StlCodePrefixId BIGINT,@StlCurrentNummber BIGINT=0,@StlCodePrefix VARCHAR(50),@StlCodeSufix VARCHAR(50);
		DECLARE @StlCNCodePrefixId BIGINT,@StlCNCurrentNummber BIGINT=0,@StlCNStartsFrom BIGINT= 0,@StlCNCodePrefix VARCHAR(50),@StlCNCodeSufix VARCHAR(50);
		DECLARE @StlIdCodePrefixId BIGINT,@StlIdCurrentNummber BIGINT=0,@StlIdStartsFrom BIGINT= 0,@StlIdCodePrefix VARCHAR(50),@StlIdCodeSufix VARCHAR(50);
		
		SELECT @UniqStockLineId = [StockLineId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId AND [PartNumber] = @PartNumber AND [ManufacturerId] = @ManufacturerId AND [SerialNumber] = @SerialNumber AND [ControlNumber] = @ControlNumber AND [IdNumber] = @IdNumber;
		
		IF(@UniqStockLineId > 0)
		BEGIN
			SET @ErrorMsg = 'Duplicate Records, Part Number, Manufacturer, SerialNumber, Master Company Atleast one Should Unique';
			SELECT @ErrorMsg AS ErrorMessage;  
			RETURN;
		END

		SELECT @UniqItemMasterId = [ItemMasterId],@IsTimeLife = [IsTimeLife] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;
		IF(@UniqItemMasterId > 0)
		BEGIN
			SET @IsStkTimeLife = @IsTimeLife;
			UPDATE [dbo].[ItemMaster]
			   SET [NationalStockNumber] = @NationalStockNumber,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
			 WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId;
		END

		SELECT @ItemMasterExportInfoId = [ItemMasterExportInfoId] FROM [dbo].[ItemMasterExportInfo] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId;
		IF(@ItemMasterExportInfoId > 0)
		BEGIN
			UPDATE [dbo].[ItemMasterExportInfo]
			   SET [ExportECCN] = @ExportECCN,
			       [ITARNumber] = @ITARNumber,
				   [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
			 WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId;
		END
		SELECT @MSLegalEntityId = [LegalEntityId] FROM [dbo].[ManagementStructure] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ManagementStructureId] = @ManagementStructureId;

		SELECT @StlCodePrefixId = [CodePrefixId], @StlCurrentNummber = [CurrentNummber],@StlCodePrefix = [CodePrefix],@StlCodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0
		SELECT @StlCNCodePrefixId = [CodePrefixId], @StlCNCurrentNummber = [CurrentNummber],@StlCNStartsFrom = ISNULL([StartsFrom],0), @StlCNCodePrefix = [CodePrefix],@StlCNCodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodeTypeId] = @ControlNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0
		SELECT @StlIdCodePrefixId = [CodePrefixId], @StlIdCurrentNummber = [CurrentNummber],@StlIdStartsFrom = ISNULL([StartsFrom],0), @StlIdCodePrefix = [CodePrefix],@StlIdCodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0
		
		DECLARE @iDcurrentNo BIGINT = 0;
		DECLARE @cncurrentNo BIGINT = 0;
		DECLARE @currentNo BIGINT = 0;

		-- Generate StockLine Number
		IF(@StlCodePrefixId > 0)
		BEGIN
			INSERT INTO #TempPNManufacturerCombinationTable([ItemMasterId],[ManufacturerId],[StockLineNumber],[CurrentStlNo],[isSerialized])
			EXEC [dbo].[GetPNManufacturerCombinationCreated] @MasterCompanyId
			
			DECLARE @foundItemCurrentStlNo BIGINT = 0;
			SELECT TOP 1 @foundItemCurrentStlNo = [CurrentStlNo] FROM #TempPNManufacturerCombinationTable WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId
			
			IF(@foundItemCurrentStlNo > 0)
			BEGIN
				SET @currentNo =  @foundItemCurrentStlNo + 1;
			END
			ELSE
			BEGIN
				SET @currentNo = 1;
			END
			SET @StlCurrentNummber = @currentNo;
			SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT) + 1, @StlCodePrefix, @StlCodeSufix));    
			
			UPDATE [dbo].[ItemMaster] 
			   SET [CurrentStlNo] = @StlCurrentNummber, 
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
			 WHERE [ItemMasterId] = @ItemMasterId 
			   AND [ManufacturerId] = @ManufacturerId
		END
		ELSE
		BEGIN
			ROLLBACK TRAN;
			SET @ErrorMsg = 'Code Prefix not Available.!';
			SELECT @ErrorMsg AS ErrorMessage;  
			RETURN;			
		END

		-- Generate Control Number
		IF(@StlCNCodePrefixId > 0)
		BEGIN
			IF(@StlCNCurrentNummber > 0)
			BEGIN
				SET @cncurrentNo = @StlCNCurrentNummber + 1;
			END
			ELSE
			BEGIN
				SET @cncurrentNo = @StlCNStartsFrom + 1;
			END
			SET @StlCNCurrentNummber = @cncurrentNo;

			SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@cncurrentNo,@StlCNCodePrefix,@StlCNCodeSufix))
		END	
		ELSE
		BEGIN
			ROLLBACK TRAN;
			SET @ErrorMsg = 'Code Prefix not Available.!';
			SELECT @ErrorMsg AS ErrorMessage;  
			RETURN;			
		END

		-- Generate ID Number
		IF(@StlIdCodePrefixId > 0)
		BEGIN
			IF(@StlIdCurrentNummber > 0)
			BEGIN
				SET @iDcurrentNo = @StlIdCurrentNummber + 1;
			END
			ELSE
			BEGIN
				SET @iDcurrentNo = @StlIdStartsFrom + 1;
			END
			SET @StlIdCurrentNummber = 1;
			SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@StlIdCurrentNummber,@StlIdCodePrefix,@StlIdCodeSufix))
		END	
		ELSE
		BEGIN
			ROLLBACK TRAN;
			SET @ErrorMsg = 'Code Prefix not Available.!';
			SELECT @ErrorMsg AS ErrorMessage;  
			RETURN;			
		END

		DECLARE @ExStockLineId BIGINT = 0;
		IF(@SerialNumber IS NOT NULL AND @SerialNumber <> '')
		BEGIN
			SELECT @ExStockLineId = [StockLineId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId AND [SerialNumber] = @SerialNumber;	
		END
		ELSE
		BEGIN
			SELECT @ExStockLineId = [StockLineId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId AND [StockLineNumber] = @StockLineNumber AND [SerialNumber] = @SerialNumber AND [ControlNumber] = @ControlNumber AND [IdNumber] = @IdNumber		  
		END

		IF(@ExStockLineId > 0)
		BEGIN
			ROLLBACK TRAN;
			SET @ErrorMsg = 'Record already Exist with these details !';
			SELECT @ErrorMsg AS ErrorMessage;  
			RETURN;	
		END
		ELSE
		BEGIN			
			INSERT INTO [dbo].[Stockline]([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate]
			   ,[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]			   
			   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost]			   
			   ,[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsNonStock],[Currency],[CurrencyId],[ItemNonStockClassificationId],[NonStockClassification],[IsService],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId]
			   ,[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId]
			   ,[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]			   
			   ,[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber]			   
			   ,[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]
			   ,[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident]			   
			   ,[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId],[TLAItemMasterId]			   
			   ,[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate],[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts]			   
			   ,[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]			   
			   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]
			   ,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName]			   
			   ,[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],[IsTurnIn],[IsCustomerRMA],[RMADeatilsId],[DaysReceived],[ManufacturingDays],[TagDays]			   
			   ,[OpenDays],[ExchangeSalesOrderId],[RRQty],[SubWorkOrderNumber],[IsManualEntry],[WorkOrderMaterialsKitId],[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost]			   
			   ,[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[SalesOrderPartId],[FreightAdjustment],[TaxAdjustment],[IsStkTimeLife]			   
			   ,[SalesPriceExpiryDate],[SubWorkOrderMaterialsId],[SubWorkOrderMaterialsKitId],[EvidenceId],[IntegrationPortal],[IsGenerateReleaseForm],[ExistingCustomerId],[RepairOrderNumber]			   
			   ,[ExistingCustomer],[QuickBooksReferenceId],[IsUpdated],[LastSyncDate],[InventoryGLSettingId],[InventoryGLAccName],[GoodsReceivedNotInvoicesGLAccId],[GoodsReceivedNotInvoicesGLAccName]
			   ,[WorkInProgressGLAccId],[WorkInProgressGLAccName],[InventoryToBillGLAccId],[InventoryToBillGLAccName],[FinishedGoodsGLAccId],[FinishedGoodsGLAccName],[InventoryExchAgreementGLAccId]			   
			   ,[InventoryExchAgreementGLAccName],[InventoryReserveGLAccId],[InventoryReserveGLAccName],[COGS_WorkOrderGLAccId],[COGS_WorkOrderGLAccName],[COGS_SalesOrderGLAccId]			  
			   ,[COGS_SalesOrderGLAccName],[COGS_QtyVarianceGLAccId],[COGS_QtyVarianceGLAccName],[COGS_UnitCostVarianceGLAccId],[COGS_UnitCostVarianceGLAccName],[RevenueMroGLAccId]
			   ,[RevenueMroGLAccName],[RevenueSoGLAccId],[RevenueSoGLAccName],[RevenueExchGLAccId],[RevenueExchGLAccName],[COGS_ExchSalesOrderGLAccId],[COGS_ExchSalesOrderGLAccName]			   
			   ,[QuantityAdjustment],[IsPiecePart],[IsRepairManagement],[IsDocument],[PurchaseOrderNumber],[IsBatchStock],[BatchNumber],[PoPartUnitCost]
			   ,[TotalTSN], [TotalCSN], [TotalTSNMM], [TotalCSNMM],[Note])
	     SELECT @PartNumber,@StockLineNumber,@StocklineMatchKey,@ControlNumber,@ItemMasterId,@QuantityOnHand,@ConditionId,@SerialNumber,@ShelfLife,@ShelfLifeExpirationDate
               ,@WarehouseId,@LocationId,@ObtainFrom,@Owner,@TraceableTo,@ManufacturerId,@Manufacturer,@ManufacturerLotNumber,@ManufacturingDate,@ManufacturingBatchNumber,@PartCertificationNumber
               ,@CertifiedBy,@CertifiedDate,@TagDate,@TagType,@CertifiedDueDate,@CalibrationMemo,@OrderDate,@PurchaseOrderId,@PurchaseOrderUnitCost,@InventoryUnitCost,@RepairOrderId,@RepairOrderUnitCost
               ,@ReceivedDate,@ReceiverNumber,@ReconciliationNumber,@UnitSalesPrice,@CoreUnitCost,@GLAccountId,@AssetId,@IsHazardousMaterial,@IsNonStock,@Currency,@CurrencyId,@ItemNonStockClassificationId,@NonStockClassification,@IsService,@IsPMA,@IsDER,@OEM,@Memo,@ManagementStructureId
               ,CASE WHEN @MSLegalEntityId > 0 THEN @MSLegalEntityId ELSE @LegalEntityId END,@MasterCompanyId ,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,@isSerialized,CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END
			   ,CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END,@SiteId,@ObtainFromType,@OwnerType,@TraceableToType,@UnitCostAdjustmentReasonTypeId
               ,@UnitSalePriceAdjustmentReasonTypeId,@IdNumber,@QuantityToReceive,(ISNULL(@QuantityOnHand,0) * ISNULL(@PurchaseOrderUnitCost,0)),@ManufacturingTrace,@ExpirationDate,@AircraftTailNumber,ISNULL(@ShippingViaId,0),@EngineSerialNumber
               ,ISNULL(@QuantityRejected,0),@PurchaseOrderPartRecordId,@ShippingAccount,@ShippingReference,CASE WHEN @TimeLifeCyclesId = 0 THEN NULL ELSE @TimeLifeCyclesId END,@TimeLifeDetailsNotProvided,@WorkOrderId,@WorkOrderMaterialsId
               ,ISNULL(@QuantityReserved,0),ISNULL(@QuantityTurnIn,0),@QuantityIssued,@QuantityOnHand,@QuantityAvailable,ISNULL(@QuantityOnOrder,0),ISNULL(@QtyReserved,0),ISNULL(@QtyIssued,0),@BlackListed,@BlackListedReason,@Incident,@IncidentReason,@Accident  
			   ,@AccidentReason,@RepairOrderPartRecordId,1,0,@WorkOrderExtendedCost,@RepairOrderExtendedCost,@IsCustomerStock,@EntryDate,@LotCost,@NHAItemMasterId,@TLAItemMasterId
               ,@ItemTypeId,CASE WHEN @AcquistionTypeId = 0 THEN NULL ELSE @AcquistionTypeId END,@RequestorId,@LotNumber,@LotDescription,@TagNumber,@InspectionBy,@InspectionDate,@VendorId,@IsParent,@ParentId,@IsSameDetailsForAllParts
			   ,@WorkOrderPartNoId,@SubWorkOrderId,@SubWOPartNoId,@IsOemPNId,@PurchaseUnitOfMeasureId,@ObtainFromName,@OwnerName,@TraceableToName,@Level1,@Level2,@Level3,@Level4,@Condition
               ,@GlAccountName,@Site,@Warehouse,@Location,@Shelf,@Bin,@UnitOfMeasure,@WorkOrderNumber,@itemGroup,@TLAPartNumber,@NHAPartNumber,@TLAPartDescription,@NHAPartDescription
			   ,@itemType,@CustomerId,@CustomerName,@isCustomerstockType,@PNDescription,@RevicedPNId,@RevicedPNNumber,@OEMPNNumber,@TaggedBy,@TaggedByName,@UnitCost,@TaggedByType,@TaggedByTypeName
               ,@CertifiedById,@CertifiedTypeId,@CertifiedType,@CertTypeId,@CertType,@TagTypeId,@IsFinishGood,@IsTurnIn,@IsCustomerRMA,@RMADeatilsId,@DaysReceived,@ManufacturingDays,@TagDays
               ,@OpenDays,@ExchangeSalesOrderId,@RRQty,@SubWorkOrderNumber,@IsManualEntry,@WorkOrderMaterialsKitId,@LotId,@IsLotAssigned,@LOTQty,@LOTQtyReserve,@OriginalCost,@POOriginalCost
			   ,@ROOriginalCost,@VendorRMAId,@VendorRMADetailId,@LotMainStocklineId,@IsFromInitialPO,@LotSourceId,@Adjustment,@SalesOrderPartId,@FreightAdjustment,@TaxAdjustment,@IsStkTimeLife
               ,@SalesPriceExpiryDate,@SubWorkOrderMaterialsId,@SubWorkOrderMaterialsKitId,@EvidenceId,@IntegrationPortal,@IsGenerateReleaseForm,@ExistingCustomerId,@RepairOrderNumber
               ,@ExistingCustomer,@QuickBooksReferenceId,@IsUpdated,@LastSyncDate,@InventoryGLSettingId,@InventoryGLAccName,@GoodsReceivedNotInvoicesGLAccId,@GoodsReceivedNotInvoicesGLAccName
               ,@WorkInProgressGLAccId,@WorkInProgressGLAccName,@InventoryToBillGLAccId,@InventoryToBillGLAccName,@FinishedGoodsGLAccId,@FinishedGoodsGLAccName,@InventoryExchAgreementGLAccId
               ,@InventoryExchAgreementGLAccName,@InventoryReserveGLAccId,@InventoryReserveGLAccName,@COGS_WorkOrderGLAccId,@COGS_WorkOrderGLAccName,@COGS_SalesOrderGLAccId
               ,@COGS_SalesOrderGLAccName,@COGS_QtyVarianceGLAccId,@COGS_QtyVarianceGLAccName,@COGS_UnitCostVarianceGLAccId,@COGS_UnitCostVarianceGLAccName,@RevenueMroGLAccId
               ,@RevenueMroGLAccName,@RevenueSoGLAccId,@RevenueSoGLAccName,@RevenueExchGLAccId,@RevenueExchGLAccName,@COGS_ExchSalesOrderGLAccId,@COGS_ExchSalesOrderGLAccName
               ,@QuantityAdjustment,@IsPiecePart,@IsRepairManagement,@IsDocument,@PurchaseOrderNumber,@IsBatchStock,@BatchNumber,@PoPartUnitCost,
			    @TotalTSN, @TotalCSN, @TotalTSNMM,@TotalCSNMM,@Note

			SELECT @StockLineId = SCOPE_IDENTITY();

			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @StlCurrentNummber WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId;

			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @StlCNCurrentNummber WHERE [CodeTypeId] = @ControlNumberCodeType AND [MasterCompanyId] = @MasterCompanyId;
			
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @StlIdCurrentNummber WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId;

			IF(@StockLineId > 0)
			BEGIN
				IF(@IsTimeLife = 1)
				BEGIN
					IF EXISTS(SELECT 1 FROM @tbl_TimeLifeType)
					BEGIN
						INSERT INTO [dbo].[TimeLife]([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining]
								   ,[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection]
								   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId]
								   ,[StockLineId],[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],[VendorRMAId],[VendorRMADetailId])
							 SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining]
								   ,[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection]
								   ,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,[PurchaseOrderId],[PurchaseOrderPartRecordId]
								   ,@StockLineId,[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],[VendorRMAId],[VendorRMADetailId]
							   FROM @tbl_TimeLifeType
						
						SELECT @TimeLifeCyclesId = SCOPE_IDENTITY();

						UPDATE [dbo].[Stockline] SET [TimeLifeCyclesId] = @TimeLifeCyclesId WHERE [StockLineId] = @StockLineId;
					END
				END
				
				EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId,@StockLineId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy;

				EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId;

				EXEC [dbo].[USP_PostManualStockLineBatchDetails] @StockLineId,@AccountPayableglAccountId

				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@StockLineModuleID,@StockLineId,NULL,NULL,1,@QuantityOnHand,@UpdatedBy;

			END
		END		
	  END
	  ELSE
	  BEGIN
	    DECLARE @OldUnitCost DECIMAL(18,2) = 0
        SELECT @OldUnitCost = ISNULL([UnitCost],0) FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId
		SELECT @UniqItemMasterId = [ItemMasterId],@IsTimeLife = [IsTimeLife] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;
		IF(@UniqItemMasterId > 0)
		BEGIN
			SET @IsStkTimeLife = CASE WHEN @IsStkTimeLife IS NOT NULL THEN @IsStkTimeLife ELSE @IsTimeLife END;
			UPDATE [dbo].[ItemMaster]
			   SET [NationalStockNumber] = @NationalStockNumber,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
			 WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId;
		END
		
		SELECT @ItemMasterExportInfoId = [ItemMasterExportInfoId] FROM [dbo].[ItemMasterExportInfo] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId;
		IF(@ItemMasterExportInfoId > 0)
		BEGIN
			UPDATE [dbo].[ItemMasterExportInfo]
			   SET [ExportECCN] = @ExportECCN,
			       [ITARNumber] = @ITARNumber,
				   [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
			 WHERE [MasterCompanyId] = @MasterCompanyId AND [ItemMasterId] = @ItemMasterId;
		END
		
		SELECT @MSLegalEntityId = [LegalEntityId] FROM [dbo].[ManagementStructure] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ManagementStructureId] = @ManagementStructureId;

		UPDATE [dbo].[Stockline]
		   SET [PartNumber] = @PartNumber,		                     
               [StocklineMatchKey] = @StocklineMatchKey,               
               [ItemMasterId] = @ItemMasterId,
               [BlackListed] = @BlackListed,
               [BlackListedReason] = @BlackListedReason,
               [Incident] = @Incident,
               [IncidentReason] = @IncidentReason,
               [Accident] = @Accident,
               [AccidentReason] = @AccidentReason,
			   [ConditionId] = @ConditionId,
			   [SerialNumber] = @SerialNumber,
			   [ShelfLife] = @ShelfLife,
			   [ShelfLifeExpirationDate] = @ShelfLifeExpirationDate,
			   [WarehouseId] = @WarehouseId,
			   [LocationId] = @LocationId,
			   [ObtainFromName] = @ObtainFromName,
			   [ObtainFrom] = @ObtainFrom,
			   [Owner] = @Owner,
			   [OwnerName] = @OwnerName,
			   [TraceableTo] = @TraceableTo,
			   [TraceableToName] = @TraceableToName,
			   [ManufacturerId] = @ManufacturerId,
			   [Manufacturer] = @Manufacturer,
			   [ManufacturerLotNumber] = @ManufacturerLotNumber,
			   [ManufacturingDate] = @ManufacturingDate,
			   [ManufacturingBatchNumber] = @ManufacturingBatchNumber,
			   [PartCertificationNumber] = @PartCertificationNumber,
			   [CertifiedBy] = @CertifiedBy,
               [CertifiedDate] = @CertifiedDate,
               [TagDate] = @TagDate,
               [TagTypeId] = @TagTypeId,
               [TagType] = @TagType,
               [CertifiedDueDate] = @CertifiedDueDate,
               [CalibrationMemo] = @CalibrationMemo,
               [OrderDate] = @OrderDate,
               [PurchaseOrderId] = @PurchaseOrderId,
               [PurchaseUnitOfMeasureId] = @PurchaseUnitOfMeasureId,
               [PurchaseOrderUnitCost] = ISNULL(@PurchaseOrderUnitCost,0),
               [InventoryUnitCost] = ISNULL(@InventoryUnitCost,0),
               [RepairOrderId] = @RepairOrderId,
               [RepairOrderNumber] = @RepairOrderNumber,
               [RepairOrderUnitCost] = ISNULL(@RepairOrderUnitCost,0),
               [ReceivedDate] = @ReceivedDate,
			   [ReceiverNumber] = @ReceiverNumber,
			   [ReconciliationNumber] = @ReconciliationNumber,
               [UnitSalesPrice] = @UnitSalesPrice,
               [SalesPriceExpiryDate] = @SalesPriceExpiryDate,
               [CoreUnitCost]= ISNULL(@CoreUnitCost,0),
               [AssetId] = @AssetId,
               [IsHazardousMaterial] = @IsHazardousMaterial,
               [IsNonStock] = @IsNonStock,
               [Currency] = @Currency,
               [CurrencyId] = @CurrencyId,
               [ItemNonStockClassificationId] = @ItemNonStockClassificationId,
               [NonStockClassification] = @NonStockClassification,
			   [IsService] = @IsService,
               [IsPMA] = @IsPMA,
               [IsDER] = @IsDER,
               [IsOemPNId] = @IsOemPNId,
               [OEM] = @OEM,
               [Memo] = @Memo,
               [ManagementStructureId] = @ManagementStructureId,
               [TimeLifeCyclesId] = CASE WHEN @TimeLifeCyclesId = 0 THEN NULL ELSE @TimeLifeCyclesId END,
               [MasterCompanyId] = @MasterCompanyId,
               [IsSerialized] = @IsSerialized,
               [ShelfId] =  CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END,
               [BinId] = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END,
               [SiteId] = @SiteId,
               [TaggedBy] = @TaggedBy,
               [TaggedByName] = @TaggedByName,
               [TaggedByType] = @TaggedByType,
               [RevicedPNId] = @RevicedPNId,
               [UnitCost] = ISNULL(@UnitCost,0),
               [CertifiedById] = @CertifiedById,
               [CertifiedTypeId] = @CertifiedTypeId,
               [CertifiedType] = @CertifiedType,               
               [CertType] = @CertType,
               [CertTypeId] = @CertTypeId,
			   [LegalEntityId] = CASE WHEN @MSLegalEntityId > 0 THEN @MSLegalEntityId ELSE @LegalEntityId END,
			   [ObtainFromType] = @ObtainFromType,
			   [OwnerType] = @OwnerType,
			   [TraceableToType] = @TraceableToType,
			   [UnitCostAdjustmentReasonTypeId] = @UnitCostAdjustmentReasonTypeId,
			   [UnitSalePriceAdjustmentReasonTypeId] = @UnitSalePriceAdjustmentReasonTypeId,			   	   
			   [PurchaseOrderExtendedCost] = ISNULL(@PurchaseOrderExtendedCost,0),
			   [ManufacturingTrace] = @ManufacturingTrace,
			   [ExpirationDate] = @ExpirationDate,
			   [AircraftTailNumber] = @AircraftTailNumber,
			   [ShippingViaId] = @ShippingViaId,
			   [EngineSerialNumber] = @EngineSerialNumber,			   
			   [PurchaseOrderPartRecordId] = @PurchaseOrderPartRecordId,
			   [ShippingAccount] = @ShippingAccount,
			   [ShippingReference] = @ShippingReference,
			   [TimeLifeDetailsNotProvided] = @TimeLifeDetailsNotProvided,
			   [LotCost] = ISNULL(@LotCost,0),
			   [EntryDate] = @EntryDate,
			   [UpdatedDate] = @UpdatedDate,
			   [UpdatedBy] = @UpdatedBy,
			   [NHAItemMasterId] = @NHAItemMasterId,
			   [TLAItemMasterId] = @TLAItemMasterId,
			   [AcquistionTypeId] = @AcquistionTypeId,
               [RequestorId] = @RequestorId,
               [LotNumber] = @LotNumber,
               [LotDescription] = @LotDescription,
               [TagNumber] = @TagNumber,
               [InspectionBy] = @InspectionBy,
               [InspectionDate] = @InspectionDate,
               [VendorId] = @VendorId,
               [WorkOrderId] = @WorkOrderId,
               [SubWorkOrderId] = @SubWorkOrderId,               
               [IsCustomerStock] = @IsCustomerStock,
               [isCustomerstockType] = @isCustomerstockType,
               [CustomerId] = @CustomerId,
               [ExchangeSalesOrderId] = @ExchangeSalesOrderId,
			   [InventoryGLSettingId] = @InventoryGLSettingId,
               [GLAccountId] = @GLAccountId,
               [InventoryGLAccName] = @InventoryGLAccName,
               [GoodsReceivedNotInvoicesGLAccId] = @GoodsReceivedNotInvoicesGLAccId,
               [GoodsReceivedNotInvoicesGLAccName] = @GoodsReceivedNotInvoicesGLAccName,
               [WorkInProgressGLAccId] = @WorkInProgressGLAccId,
               [WorkInProgressGLAccName] = @WorkInProgressGLAccName,
               [InventoryToBillGLAccId] = @InventoryToBillGLAccId,
               [InventoryToBillGLAccName] = @InventoryToBillGLAccName,
               [FinishedGoodsGLAccId] = @FinishedGoodsGLAccId,
               [FinishedGoodsGLAccName] = @FinishedGoodsGLAccName,
               [InventoryExchAgreementGLAccId] = @InventoryExchAgreementGLAccId,
               [InventoryExchAgreementGLAccName] = @InventoryExchAgreementGLAccName,
               [InventoryReserveGLAccId] = @InventoryReserveGLAccId,
               [InventoryReserveGLAccName] = @InventoryReserveGLAccName,
               [COGS_WorkOrderGLAccId] = @COGS_WorkOrderGLAccId,
               [COGS_WorkOrderGLAccName] = @COGS_WorkOrderGLAccName,
               [COGS_SalesOrderGLAccId] = @COGS_SalesOrderGLAccId,
               [COGS_SalesOrderGLAccName] = @COGS_SalesOrderGLAccName,
               [COGS_QtyVarianceGLAccId] = @COGS_QtyVarianceGLAccId,
               [COGS_QtyVarianceGLAccName] = @COGS_QtyVarianceGLAccName,
               [COGS_UnitCostVarianceGLAccId] = @COGS_UnitCostVarianceGLAccId,
               [COGS_UnitCostVarianceGLAccName] = @COGS_UnitCostVarianceGLAccName,
               [RevenueMroGLAccId] = @RevenueMroGLAccId,
               [RevenueMroGLAccName] = @RevenueMroGLAccName,
               [RevenueSoGLAccId] = @RevenueSoGLAccId,
               [RevenueSoGLAccName] = @RevenueSoGLAccName,
               [RevenueExchGLAccId] = @RevenueExchGLAccId,
               [RevenueExchGLAccName] = @RevenueExchGLAccName,
               [COGS_ExchSalesOrderGLAccId] = @COGS_ExchSalesOrderGLAccId,
               [COGS_ExchSalesOrderGLAccName] = @COGS_ExchSalesOrderGLAccName,
               [IntegrationPortal] = @IntegrationPortal,
               [Adjustment] = ISNULL(@UnitCost,0) - (ISNULL(@PurchaseOrderUnitCost,0) + ISNULL(@RepairOrderUnitCost,0)),
               [PoPartUnitCost] = ISNULL(@PoPartUnitCost,0),
			   [TotalTSN] = ISNULL(@TotalTSN,0),
			   [TotalCSN]= ISNULL(@TotalCSN,0),
			   [TotalTSNMM] = ISNULL(@TotalTSNMM ,0),
			   [TotalCSNMM] = ISNULL(@TotalCSNMM,0),
			   [Note] = @Note
	     WHERE [MasterCompanyId] = @MasterCompanyId AND [StockLineId] = @StockLineId
		 
		EXEC [dbo].[USP_UpdateSLMSDetails] @StkManagementStructureModuleId,@StockLineId,@ManagementStructureId,@UpdatedBy;

		IF(@IsStkTimeLife = 1)
		BEGIN
			IF EXISTS(SELECT 1 FROM @tbl_TimeLifeType)
			BEGIN
				IF EXISTS(SELECT 1 FROM @tbl_TimeLifeType WHERE [TimeLifeCyclesId] > 0 )
				BEGIN					
					UPDATE TLF
					   SET TLF.[CyclesRemaining] = TLT.[CyclesRemaining],
						   TLF.[CyclesSinceNew] = TLT.[CyclesSinceNew],
						   TLF.[CyclesSinceOVH] = TLT.[CyclesSinceOVH],
						   TLF.[CyclesSinceInspection] = TLT.[CyclesSinceInspection],
						   TLF.[CyclesSinceRepair] = TLT.[CyclesSinceRepair],
						   TLF.[TimeRemaining] = TLT.[TimeRemaining],
						   TLF.[TimeSinceNew] = TLT.[TimeSinceNew],
						   TLF.[TimeSinceOVH] = TLT.[TimeSinceOVH],
						   TLF.[TimeSinceInspection] = TLT.[TimeSinceInspection],
						   TLF.[TimeSinceRepair] = TLT.[TimeSinceRepair],
						   TLF.[LastSinceNew] = TLT.[LastSinceNew],
						   TLF.[LastSinceOVH] = TLT.[LastSinceOVH],
						   TLF.[LastSinceInspection] = TLT.[LastSinceInspection],
						   TLF.[UpdatedBy] = @UpdatedBy,
						   TLF.[UpdatedDate] = @UpdatedDate,
						   TLF.[StockLineId] = @StockLineId,
						   TLF.[DetailsNotProvided] = ISNULL(TLT.[DetailsNotProvided],0)
				   FROM @tbl_TimeLifeType AS TLT 
				  INNER JOIN [dbo].[TimeLife] TLF ON TLT.[TimeLifeCyclesId] = TLF.[TimeLifeCyclesId]
				END
				ELSE
				BEGIN
					INSERT INTO [dbo].[TimeLife]([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining]
								   ,[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection]
								   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId]
								   ,[StockLineId],[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],[VendorRMAId],[VendorRMADetailId])
							 SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining]
								   ,[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection]
								   ,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,[PurchaseOrderId],[PurchaseOrderPartRecordId]
								   ,@StockLineId,[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],[VendorRMAId],[VendorRMADetailId]
							   FROM @tbl_TimeLifeType
						
						SELECT @TimeLifeCyclesId = SCOPE_IDENTITY();

						UPDATE [dbo].[Stockline] SET [TimeLifeCyclesId] = @TimeLifeCyclesId WHERE [StockLineId] = @StockLineId;
				END				
			END
		END
		
		IF(@IsStkTimeLife = 1)
		BEGIN
			DECLARE @UpdatedCSN VARCHAR(50) = NULL,
					@UpdatedTSN VARCHAR(50) = NULL,
					@UpdatedCSO VARCHAR(50) = NULL,
					@UpdatedTSO VARCHAR(50) = NULL;

			SELECT TOP 1 
				@UpdatedCSN = CAST([CyclesSinceNew] AS VARCHAR(50)),
				@UpdatedCSO = CAST([CyclesSinceOVH] AS VARCHAR(50)),
				@UpdatedTSN = CAST([TimeSinceNew]   AS VARCHAR(50)),
				@UpdatedTSO = CAST([TimeSinceOVH]   AS VARCHAR(50))
			FROM [dbo].[TimeLife] WITH(NOLOCK)
			WHERE [StockLineId] = @StockLineId
			  AND ISNULL([IsActive], 0) = 1;

			IF (@UpdatedCSN IS NOT NULL OR @UpdatedTSN IS NOT NULL 
				OR @UpdatedCSO IS NOT NULL OR @UpdatedTSO IS NOT NULL)
			BEGIN
				UPDATE [dbo].[WorkOrderPartNumber]
				   SET [CSN]         = @UpdatedCSN,
					   [TSN]         = @UpdatedTSN,
					   [CSO]         = @UpdatedCSO,
					   [TSO]         = @UpdatedTSO,
					   [UpdatedDate] = @UpdatedDate,
					   [UpdatedBy]   = @UpdatedBy
				 WHERE [StockLineId] = @StockLineId
				   AND ISNULL([IsDeleted], 0) = 0;
			END
		END
		--Add a logic to handle Parent Child relationship for resialized stockline
		DECLARE @IsAddUpdate BIT = 0
		DECLARE @ExecuteParentChild BIT =1 
		DECLARE @UpdateQuantities BIT = 0 
		DECLARE @IsOHUpdated BIT = 0 
		DECLARE @AddHistoryForNonSerialized BIT = 0
		DECLARE @MainLotStocklineId BIGINT = 0
		DECLARE @WorkOrderMaterialsModule INT = 33,@SubReferenceId INT= 0
		    SET @IsFromInitialPO = 0
		    SET @LotSourceId = 0

		IF(ISNULL(@IsSerialized,0) = 0 AND (@QuantityAvailable > 1 OR @Quantity > 1))
		BEGIN
			EXEC [dbo].[USP_CreateChildStockline] @StockLineId,@MasterCompanyId,@StockLineModuleID,@StockLineId,@IsAddUpdate,@ExecuteParentChild,@UpdateQuantities,@IsOHUpdated,@AddHistoryForNonSerialized,@WorkOrderMaterialsModule,@SubReferenceId,@MainLotStocklineId,@IsFromInitialPO,@LotSourceId
		END
		ELSE IF(@IsSerialized =1 AND (@QuantityAvailable = 1 OR @Quantity = 1))
		BEGIN
		    SET @ExecuteParentChild = 0
			SET @AddHistoryForNonSerialized = 1

			EXEC [dbo].[USP_CreateChildStockline] @StockLineId,@MasterCompanyId,@StockLineModuleID,@StockLineId,
			@IsAddUpdate,@ExecuteParentChild,@UpdateQuantities,@IsOHUpdated,@AddHistoryForNonSerialized,@WorkOrderMaterialsModule,@SubReferenceId,@MainLotStocklineId,@IsFromInitialPO,@LotSourceId
        END
		EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId;

		EXEC [dbo].[USP_PostManualStockLine_NewBatchDetails] @StockLineId,@UpdatedBy,@OldUnitCost;

	  END

	  SELECT @StockLineId AS [StockLineId]

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
        ROLLBACK TRAN;
		 SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateStockLine' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END