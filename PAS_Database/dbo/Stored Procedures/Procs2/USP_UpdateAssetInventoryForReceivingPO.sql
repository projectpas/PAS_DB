/*************************************************************               
 ** File:   [USP_UpdateAssetInventoryForReceivingPO]              
 ** Author:   Vishal Suthar    
 ** Description: This stored procedure is used to Update stocklines for receiving PO  
 ** Purpose:             
 ** Date:   09/22/2023            
              
 ** PARAMETERS:    
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    09/22/2023   Vishal Suthar  Created  
    2    10/05/2023   Vishal Suthar  Modified to get parent stockline draft details to bind as parent record  
    
declare @p2 dbo.POPartsToReceive  
insert into @p2 values(1821,3412,5)  
  
exec dbo.USP_UpdateAssetInventoryForReceivingPO @PurchaseOrderId=1821,@tbl_POPartsToReceive=@p2,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1  
**************************************************************/    
CREATE   PROCEDURE [dbo].[USP_UpdateAssetInventoryForReceivingPO]
(    
	@PurchaseOrderId BIGINT = NULL,  
	@UpdatedBy VARCHAR(100) = NULL,  
	@MasterCompanyId BIGINT = NULL,  
	@tbl_UpdateStocklineReceivingPOType UpdateStocklineReceivingPOType READONLY,  
	@tbl_UpdateTimeLifeReceivingPOType UpdateTimeLifeReceivingPOType READONLY,
	@IsCreate BIT
)    
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  BEGIN TRY
  BEGIN TRANSACTION
  BEGIN
  DECLARE @LoopID AS INT;
  
  IF OBJECT_ID(N'tempdb..#UpdateStocklineReceivingPOType') IS NOT NULL  
  BEGIN  
	DROP TABLE #UpdateStocklineReceivingPOType   
  END  
     
  CREATE TABLE #UpdateStocklineReceivingPOType   
  (  
   ID BIGINT NOT NULL IDENTITY,  
   [StockLineDraftId] [bigint] NOT NULL,  
   [PartNumber] [varchar](50) NULL,  
   [StockLineNumber] [varchar](50) NULL,  
   [StocklineMatchKey] [varchar](100) NULL,  
   [ControlNumber] [varchar](50) NULL,  
   [ItemMasterId] [bigint] NULL,  
   [Quantity] [int] NULL,  
   [ConditionId] [bigint] NULL,  
   [SerialNumber] [varchar](30) NULL,  
   [ShelfLife] [bit] NULL,  
   [ShelfLifeExpirationDate] [datetime2](7) NULL,  
   [WarehouseId] [bigint] NULL,  
   [LocationId] [bigint] NULL,  
   [ObtainFrom] [bigint] NULL,  
   [Owner] [bigint] NULL,  
   [TraceableTo] [bigint] NULL,  
   [ManufacturerId] [bigint] NULL,  
   [Manufacturer] [varchar](50) NULL,  
   [ManufacturerLotNumber] [varchar](50) NULL,  
   [ManufacturingDate] [datetime2](7) NULL,  
   [ManufacturingBatchNumber] [varchar](50) NULL,  
   [PartCertificationNumber] [varchar](50) NULL,  
   [CertifiedBy] [varchar](100) NULL,  
   [CertifiedDate] [datetime2](7) NULL,  
   [TagDate] [datetime2](7) NULL,  
   [TagTypeIds] [varchar](max) NULL,  
   [TagType] [varchar](max) NULL,  
   [CertifiedDueDate] [datetime2](7) NULL,  
   [CalibrationMemo] [nvarchar](max) NULL,  
   [OrderDate] [datetime2](7) NULL,  
   [PurchaseOrderId] [bigint] NULL,  
   [PurchaseOrderUnitCost] [decimal](18, 2) NULL,  
   [InventoryUnitCost] [decimal](18, 2) NULL,  
   [RepairOrderId] [bigint] NULL,  
   [RepairOrderUnitCost] [decimal](18, 2) NULL,  
   [ReceivedDate] [datetime2](7) NULL,  
   [ReceiverNumber] [varchar](50) NULL,  
   [ReconciliationNumber] [varchar](50) NULL,  
   [UnitSalesPrice] [decimal](18, 2) NULL,  
   [CoreUnitCost] [decimal](18, 2) NULL,  
   [GLAccountId] [bigint] NULL,  
   [AssetId] [bigint] NULL,  
   [IsHazardousMaterial] [bit] NULL,  
   [IsPMA] [bit] NULL,  
   [IsDER] [bit] NULL,  
   [OEM] [bit] NULL,  
   [Memo] [nvarchar](max) NULL,  
   [ManagementStructureEntityId] [bigint] NULL,  
   [LegalEntityId] [bigint] NULL,  
   [MasterCompanyId] [int] NOT NULL,  
   [CreatedBy] [varchar](256) NULL,  
   [UpdatedBy] [varchar](256) NULL,  
   [CreatedDate] [datetime2](7) NULL,  
   [UpdatedDate] [datetime2](7) NULL,  
   [isSerialized] [bit] NULL,  
   [ShelfId] [bigint] NULL,  
   [BinId] [bigint] NULL,  
   [SiteId] [bigint] NULL,  
   [ObtainFromType] [int] NULL,  
   [OwnerType] [int] NULL,  
   [TraceableToType] [int] NULL,  
   [UnitCostAdjustmentReasonTypeId] [int] NULL,  
   [UnitSalePriceAdjustmentReasonTypeId] [int] NULL,  
   [IdNumber] [varchar](100) NULL,  
   [QuantityToReceive] [int] NULL,  
   [PurchaseOrderExtendedCost] [decimal](18, 0) NULL,  
   [ManufacturingTrace] [nvarchar](200) NULL,  
   [ExpirationDate] [datetime2](7) NULL,  
   [AircraftTailNumber] [nvarchar](200) NULL,  
   [ShippingViaId] [bigint] NULL,  
   [EngineSerialNumber] [nvarchar](200) NULL,  
   [QuantityRejected] [int] NOT NULL,  
   [PurchaseOrderPartRecordId] [bigint] NULL,  
   [ShippingAccount] [nvarchar](200) NULL,  
   [ShippingReference] [nvarchar](200) NULL,  
   [TimeLifeCyclesId] [bigint] NULL,  
   [TimeLifeDetailsNotProvided] [bit] NULL,  
   [WorkOrderId] [bigint] NULL,  
   [WorkOrderMaterialsId] [bigint] NULL,  
   [QuantityReserved] [int] NULL,  
   [QuantityTurnIn] [int] NULL,  
   [QuantityIssued] [int] NULL,  
   [QuantityOnHand] [int] NULL,  
   [QuantityAvailable] [int] NULL,  
   [QuantityOnOrder] [int] NULL,  
   [QtyReserved] [int] NULL,  
   [QtyIssued] [int] NULL,  
   [BlackListed] [bit] NULL,  
   [BlackListedReason] [varchar](500) NULL,  
   [Incident] [bit] NOT NULL,  
   [IncidentReason] [varchar](500) NULL,  
   [Accident] [bit] NOT NULL,  
   [AccidentReason] [varchar](500) NULL,  
   [RepairOrderPartRecordId] [bigint] NULL,  
   [isActive] [bit] NULL,  
   [isDeleted] [bit] NULL,  
   [WorkOrderExtendedCost] [decimal](20, 2) NULL,  
   [RepairOrderExtendedCost] [decimal](18, 2) NULL,  
   [NHAItemMasterId] [bigint] NULL,  
   [TLAItemMasterId] [bigint] NULL,  
   [IsParent] [bit] NULL,  
   [ParentId] [bigint] NULL,  
   [IsSameDetailsForAllParts] [bit] NULL,  
   [Level1] [varchar](200) NULL,  
   [Level2] [varchar](200) NULL,  
   [Level3] [varchar](200) NULL,  
   [Level4] [varchar](200) NULL,  
   [Condition] [varchar](250) NULL,  
   [Warehouse] [varchar](250) NULL,  
   [Location] [varchar](250) NULL,  
   [ObtainFromName] [varchar](250) NULL,  
   [OwnerName] [varchar](250) NULL,  
   [TraceableToName] [varchar](250) NULL,  
   [GLAccount] [varchar](250) NULL,  
   [AssetName] [varchar](250) NULL,  
   [LegalEntityName] [varchar](250) NULL,  
   [ShelfName] [varchar](250) NULL,  
   [BinName] [varchar](250) NULL,  
   [SiteName] [varchar](250) NULL,  
   [ObtainFromTypeName] [varchar](250) NULL,  
   [OwnerTypeName] [varchar](250) NULL,  
   [TraceableToTypeName] [varchar](250) NULL,  
   [UnitCostAdjustmentReasonType] [varchar](250) NULL,  
   [UnitSalePriceAdjustmentReasonType] [varchar](250) NULL,  
   [ShippingVia] [varchar](250) NULL,  
   [WorkOrder] [varchar](250) NULL,  
   [WorkOrderMaterialsName] [varchar](250) NULL,  
   [TagTypeId] [bigint] NULL,  
   [StockLineDraftNumber] [varchar](250) NULL,  
   [StockLineId] [bigint] NULL,  
   [TaggedBy] [bigint] NULL,  
   [TaggedByName] [varchar](250) NULL,  
   [UnitOfMeasureId] [bigint] NULL,  
   [UnitOfMeasure] [varchar](250) NULL,  
   [RevisedPartId] [bigint] NULL,  
   [RevisedPartNumber] [varchar](250) NULL,  
   [TaggedByType] [int] NULL,  
   [TaggedByTypeName] [varchar](250) NULL,  
   [CertifiedById] [bigint] NULL,  
   [CertifiedTypeId] [int] NULL,  
   [CertifiedType] [varchar](250) NULL,  
   [CertTypeId] [varchar](max) NULL,  
   [CertType] [varchar](max) NULL,  
   [IsCustomerStock] [bit] NULL,  
   [isCustomerstockType] [bit] NULL,  
   [CustomerId] [bigint] NULL,  
   [CalibrationVendorId] [bigint] NULL,  
   [PerformedById] [bigint] NULL,  
   [LastCalibrationDate] [datetime] NULL,  
   [NextCalibrationDate] [datetime] NULL,  
   [LotId] [bigint] NULL,  
   [SalesOrderId] [bigint] NULL,  
   [SubWorkOrderId] [bigint] NULL,  
   [ExchangeSalesOrderId] [bigint] NULL,  
   [WOQty] [int] NULL,  
   [SOQty] [int] NULL,  
   [ForStockQty] [int] NULL,  
   [IsLotAssigned] [bit] NULL,  
   [LOTQty] [int] NULL,  
   [LOTQtyReserve] [int] NULL,  
   [OriginalCost] [decimal](18, 2) NULL,  
   [POOriginalCost] [decimal](18, 2) NULL,  
   [ROOriginalCost] [decimal](18, 2) NULL,  
   [VendorRMAId] [bigint] NULL,  
   [VendorRMADetailId] [bigint] NULL,  
   [LotMainStocklineId] [bigint] NULL,  
   [IsFromInitialPO] [bit] NULL,  
   [LotSourceId] [int] NULL,  
   [Adjustment] [decimal](18, 2) NULL ,
   [SerialNumberNotProvided] [bit] NULL,
   [ShippingReferenceNumberNotProvided] [bit] NULL,
   [AssetAcquisitionTypeId] [bigint] NULL
  )  
  
  INSERT INTO #UpdateStocklineReceivingPOType ([StockLineDraftId],[PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],  
  [SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],  
  [ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagTypeIds],[TagType],[CertifiedDueDate],[CalibrationMemo],  
  [OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],  
  [CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],  
  [UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],  
  [UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],  
  [EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],  
  [WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],  
  [BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],  
  [NHAItemMasterId],[TLAItemMasterId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[Level1],[Level2],[Level3],[Level4],[Condition],[Warehouse],[Location],[ObtainFromName],  
  [OwnerName],[TraceableToName],[GLAccount],[AssetName],[LegalEntityName],[ShelfName],[BinName],[SiteName],[ObtainFromTypeName],[OwnerTypeName],[TraceableToTypeName],  
  [UnitCostAdjustmentReasonType],[UnitSalePriceAdjustmentReasonType],[ShippingVia],[WorkOrder],[WorkOrderMaterialsName],[TagTypeId],[StockLineDraftNumber],[StockLineId],  
  [TaggedBy],[TaggedByName],[UnitOfMeasureId],[UnitOfMeasure],[RevisedPartId],[RevisedPartNumber],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],  
  [CertTypeId],[CertType],[IsCustomerStock],[isCustomerstockType],[CustomerId],[CalibrationVendorId],[PerformedById],[LastCalibrationDate],[NextCalibrationDate],[LotId],  
  [SalesOrderId],[SubWorkOrderId],[ExchangeSalesOrderId],[WOQty],[SOQty],[ForStockQty],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],  
  [ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[SerialNumberNotProvided],[ShippingReferenceNumberNotProvided],[AssetAcquisitionTypeId])
  SELECT [StockLineDraftId],[PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],  
  [SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],  
  [ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagTypeIds],[TagType],[CertifiedDueDate],[CalibrationMemo],  
  [OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],  
  [CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],  
  [UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],  
  [UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],  
  [EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],  
  [WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],  
  [BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],  
  [NHAItemMasterId],[TLAItemMasterId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[Level1],[Level2],[Level3],[Level4],[Condition],[Warehouse],[Location],[ObtainFromName],  
  [OwnerName],[TraceableToName],[GLAccount],[AssetName],[LegalEntityName],[ShelfName],[BinName],[SiteName],[ObtainFromTypeName],[OwnerTypeName],[TraceableToTypeName],  
  [UnitCostAdjustmentReasonType],[UnitSalePriceAdjustmentReasonType],[ShippingVia],[WorkOrder],[WorkOrderMaterialsName],[TagTypeId],[StockLineDraftNumber],[StockLineId],  
  [TaggedBy],[TaggedByName],[UnitOfMeasureId],[UnitOfMeasure],[RevisedPartId],[RevisedPartNumber],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],  
  [CertTypeId],[CertType],[IsCustomerStock],[isCustomerstockType],[CustomerId],[CalibrationVendorId],[PerformedById],[LastCalibrationDate],[NextCalibrationDate],[LotId],  
  [SalesOrderId],[SubWorkOrderId],[ExchangeSalesOrderId],[WOQty],[SOQty],[ForStockQty],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],  
  [ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[SerialNumberNotProvided],[ShippingReferenceNumberNotProvided],[AssetAcquisitionTypeId] 
  FROM @tbl_UpdateStocklineReceivingPOType;
  
  DECLARE @QuantityBackOrdered INT = 0;  
  
  SELECT @LoopID = MAX(ID) FROM #UpdateStocklineReceivingPOType;  
  
  WHILE (@LoopID > 0)  
  BEGIN  
   DECLARE @SelectedStockLineDraftId BIGINT = 0;  
   DECLARE @SelectedPurchaseOrderPartRecordId BIGINT = 0;  
   DECLARE @ManagementStructureEntityId BIGINT = 0;  
   DECLARE @Quantity INT = 0;  
   DECLARE @CreatedBy VARCHAR(100) = '';  
   DECLARE @ManagementStructureModuleReceivingPODraft INT = 31;  
   DECLARE @StockLineDraftMSDetailsOpr INT = 0;  
   DECLARE @PrevIsSameDetailsForAllParts BIT = 0;  
   DECLARE @PrevIsSerialized BIT = 0;  
   DECLARE @PrevIsParent BIT = 0;  
   DECLARE @IsSameDetailsForAllParts BIT = 0;  
   DECLARE @IsSerialized BIT = 0;  
  
   SELECT @SelectedStockLineDraftId = StockLineDraftId, @SelectedPurchaseOrderPartRecordId = PurchaseOrderPartRecordId, @Quantity = Quantity, @IsSameDetailsForAllParts = IsSameDetailsForAllParts, @IsSerialized = IsSerialized  
   FROM #UpdateStocklineReceivingPOType WHERE ID = @LoopID;  
  
   SELECT @PrevIsSameDetailsForAllParts = IsSameDetailsForAllParts, @PrevIsSerialized = IsSerialized, @PrevIsParent = IsParent FROM DBO.AssetInventoryDraft StkDraft WHERE StkDraft.AssetInventoryDraftId = @SelectedStockLineDraftId;
  
   IF (@PrevIsSerialized = 1 AND @IsSerialized = 0)  
   BEGIN  
    IF (@PrevIsParent = 1 AND @IsSameDetailsForAllParts = 0)  
     SET @PrevIsParent = 0;  
    ELSE IF (@PrevIsParent = 0 AND @IsSameDetailsForAllParts = 0)  
     SET @PrevIsParent = 1;  
   END  
  
   IF (@IsCreate = 1)
   BEGIN
		IF (@IsSerialized = 0)  
		BEGIN  
			IF (@PrevIsSameDetailsForAllParts <> @IsSameDetailsForAllParts)  
			BEGIN  
				IF (@PrevIsParent = 1 AND (@PrevIsSameDetailsForAllParts = 1 AND @IsSameDetailsForAllParts = 0))  
					SET @PrevIsParent = 0;  
				ELSE IF (@PrevIsParent = 0 AND (@PrevIsSameDetailsForAllParts = 1 AND @IsSameDetailsForAllParts = 0))  
					SET @PrevIsParent = 1;  
				ELSE IF (@PrevIsParent = 0 AND (@PrevIsSameDetailsForAllParts = 0 AND @IsSameDetailsForAllParts = 1))  
					SET @PrevIsParent = 1;  
				ELSE IF (@PrevIsParent = 1 AND (@PrevIsSameDetailsForAllParts = 0 AND @IsSameDetailsForAllParts = 1))  
					SET @PrevIsParent = 0;  
			END  
		END  
	END
  
   UPDATE StkDraft  
   SET StkDraft.SiteId = CASE WHEN TmpStkDraft.SiteId > 0 THEN TmpStkDraft.SiteId ELSE NULL END,  
   StkDraft.WarehouseId = CASE WHEN TmpStkDraft.WarehouseId > 0 THEN TmpStkDraft.WarehouseId ELSE NULL END,  
   StkDraft.LocationId = CASE WHEN TmpStkDraft.LocationId > 0 THEN TmpStkDraft.LocationId ELSE NULL END,  
   StkDraft.ShelfId = CASE WHEN TmpStkDraft.ShelfId > 0 THEN TmpStkDraft.ShelfId ELSE NULL END,  
   StkDraft.BinId = CASE WHEN TmpStkDraft.BinId > 0 THEN TmpStkDraft.BinId ELSE NULL END,  
   StkDraft.UnitCost = TmpStkDraft.PurchaseOrderUnitCost,  
   StkDraft.AssetAcquisitionTypeId = TmpStkDraft.AssetAcquisitionTypeId,
   StkDraft.ManufacturedDate = TmpStkDraft.ManufacturingDate,
   StkDraft.LastCalibrationDate = TmpStkDraft.LastCalibrationDate,
   StkDraft.NextCalibrationDate = TmpStkDraft.NextCalibrationDate,
   StkDraft.ShippingViaId = CASE WHEN TmpStkDraft.ShippingViaId > 0 THEN TmpStkDraft.ShippingViaId ELSE NULL END,  
   StkDraft.ShippingReference = TmpStkDraft.ShippingReference,  
   StkDraft.ShippingAccount = TmpStkDraft.ShippingAccount,  
   StkDraft.SerialNo = TmpStkDraft.SerialNumber,
   StkDraft.TagDate = TmpStkDraft.TagDate,  
   StkDraft.ExpirationDate = TmpStkDraft.ExpirationDate,  
   StkDraft.UpdatedBy = TmpStkDraft.UpdatedBy,  
   StkDraft.UnitOfMeasureId = TmpStkDraft.UnitOfMeasureId,  
   StkDraft.GLAccountId = TmpStkDraft.GLAccountId,  
   StkDraft.UpdatedDate = GETUTCDATE(),  
   StkDraft.IsSameDetailsForAllParts = TmpStkDraft.IsSameDetailsForAllParts,  
   StkDraft.IsSerialized = TmpStkDraft.IsSerialized,  
   StkDraft.IsParent = @PrevIsParent,
   StkDraft.CalibrationDefaultVendorId = TmpStkDraft.CalibrationVendorId,
   StkDraft.PerformedById = TmpStkDraft.PerformedById,
   StkDraft.CalibrationMemo = TmpStkDraft.CalibrationMemo
   FROM DBO.AssetInventoryDraft StkDraft  
   INNER JOIN #UpdateStocklineReceivingPOType TmpStkDraft ON TmpStkDraft.StockLineDraftId = StkDraft.AssetInventoryDraftId
   WHERE StkDraft.AssetInventoryDraftId = @SelectedStockLineDraftId;  
  
   IF(@IsCreate = 0)
   BEGIN
		IF (@PrevIsSameDetailsForAllParts <> @IsSameDetailsForAllParts)
		BEGIN
			UPDATE StkDraft
			SET StkDraft.IsSameDetailsForAllParts = CASE WHEN TmpStkDraft.IsSameDetailsForAllParts = 1 THEN 0 ELSE 1 END
			FROM DBO.AssetInventoryDraft StkDraft
			INNER JOIN #UpdateStocklineReceivingPOType TmpStkDraft ON TmpStkDraft.StockLineDraftId = StkDraft.AssetInventoryDraftId
			WHERE StkDraft.AssetInventoryDraftId = @SelectedStockLineDraftId;
		END
	END

   SELECT @ManagementStructureEntityId = ManagementStructureEntityId, @CreatedBy = CreatedBy FROM DBO.StockLineDraft StkDraft WHERE StkDraft.StockLineDraftId = @SelectedStockLineDraftId;  
  
   SET @StockLineDraftMSDetailsOpr = 2;  
  
   EXEC dbo.[PROCAddStockLineDraftMSData] @SelectedStockLineDraftId, @ManagementStructureEntityId, @MasterCompanyId, @CreatedBy, @UpdatedBy, @ManagementStructureModuleReceivingPODraft, @StockLineDraftMSDetailsOpr; -- @MSDetailsId OUTPUT  
  
   SET @QuantityBackOrdered = @QuantityBackOrdered + @Quantity;  
  
   /* Insert/Update Stockline Timelife Info */  
   DECLARE @LoopIDTimelife INT = 0;  
  
   IF OBJECT_ID(N'tempdb..#UpdateTimeLifeReceivingPOType') IS NOT NULL  
   BEGIN  
    DROP TABLE #UpdateTimeLifeReceivingPOType   
   END  
     
   CREATE TABLE #UpdateTimeLifeReceivingPOType  
   (  
    ID BIGINT NOT NULL IDENTITY,  
    [TimeLifeDraftCyclesId] [bigint] NULL,  
    [StockLineDraftId] [bigint] NULL,  
    [CyclesRemaining] [varchar](20) NULL,  
    [CyclesSinceNew] [varchar](20) NULL,  
    [CyclesSinceOVH] [varchar](20) NULL,  
    [CyclesSinceInspection] [varchar](20) NULL,  
    [CyclesSinceRepair] [varchar](20) NULL,  
    [TimeRemaining] [varchar](20) NULL,  
    [TimeSinceNew] [varchar](20) NULL,  
    [TimeSinceOVH] [varchar](20) NULL,  
    [TimeSinceInspection] [varchar](20) NULL,  
    [TimeSinceRepair] [varchar](20) NULL,  
    [LastSinceNew] [varchar](20) NULL,  
    [LastSinceOVH] [varchar](20) NULL,  
    [LastSinceInspection] [varchar](20) NULL,  
    [DetailsNotProvided] [bit] NULL  
   )  
  
   INSERT INTO #UpdateTimeLifeReceivingPOType ([TimeLifeDraftCyclesId],[StockLineDraftId],[CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],  
   [CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[DetailsNotProvided])  
   SELECT [TimeLifeDraftCyclesId],[StockLineDraftId],[CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],  
   [CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[DetailsNotProvided]  
   FROM @tbl_UpdateTimeLifeReceivingPOType WHERE [StockLineDraftId] = @SelectedStockLineDraftId;  
  
   SELECT @LoopIDTimelife = MAX(ID) FROM #UpdateTimeLifeReceivingPOType;  
    
   WHILE (@LoopIDTimelife > 0)  
   BEGIN  
    DECLARE @SelectedTimeLifeDraftCyclesId BIGINT = 0;  
  
    SELECT @SelectedTimeLifeDraftCyclesId = TimeLifeDraftCyclesId FROM #UpdateTimeLifeReceivingPOType WHERE ID = @LoopIDTimelife;  
  
    IF (@SelectedTimeLifeDraftCyclesId = 0)  
    BEGIN  
     INSERT INTO DBO.TimeLifeDraft ([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],  
     [TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],  
     [UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineDraftId],[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],  
     [VendorRMAId],[VendorRMADetailId])  
     SELECT [CyclesRemaining], [CyclesSinceNew], [CyclesSinceOVH], [CyclesSinceInspection], [CyclesSinceRepair], [TimeRemaining], [TimeSinceNew],  
     [TimeSinceOVH], [TimeSinceInspection], [TimeSinceRepair], [LastSinceNew], [LastSinceOVH], [LastSinceInspection], @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),  
     GETUTCDATE(), 1, @PurchaseOrderId, @SelectedPurchaseOrderPartRecordId, [StockLineDraftId], [DetailsNotProvided], NULL, NULL,  
     NULL, NULL  
     FROM #UpdateTimeLifeReceivingPOType WHERE ID = @LoopIDTimelife;  
    END  
    ELSE  
    BEGIN  
     UPDATE TLDraft  
     SET TLDraft.CyclesRemaining = UTLDraft.CyclesRemaining,  
     TLDraft.[CyclesSinceNew] = UTLDraft.[CyclesSinceNew],  
     TLDraft.[CyclesSinceOVH] = UTLDraft.[CyclesSinceOVH],  
     TLDraft.[CyclesSinceInspection] = UTLDraft.[CyclesSinceInspection],  
     TLDraft.[CyclesSinceRepair] = UTLDraft.[CyclesSinceRepair],  
     TLDraft.[TimeRemaining] = UTLDraft.[TimeRemaining],  
     TLDraft.[TimeSinceNew] = UTLDraft.[TimeSinceNew],  
     TLDraft.[TimeSinceOVH] = UTLDraft.[TimeSinceOVH],  
     TLDraft.[TimeSinceInspection] = UTLDraft.[TimeSinceInspection],  
     TLDraft.[TimeSinceRepair] = UTLDraft.[TimeSinceRepair],  
     TLDraft.[LastSinceNew] = UTLDraft.[LastSinceNew],  
     TLDraft.[LastSinceOVH] = UTLDraft.[LastSinceOVH],  
     TLDraft.[LastSinceInspection] = UTLDraft.[LastSinceInspection],  
     TLDraft.[UpdatedBy] = @UpdatedBy,  
     TLDraft.UpdatedDate = GETUTCDATE()  
     FROM DBO.TimeLifeDraft TLDraft  
     INNER JOIN #UpdateTimeLifeReceivingPOType UTLDraft ON TLDraft.StockLineDraftId = UTLDraft.StockLineDraftId  
     WHERE TLDraft.TimeLifeDraftCyclesId = @SelectedTimeLifeDraftCyclesId  
    END  
  
    SET @LoopIDTimelife = @LoopIDTimelife - 1;  
   END  
  
   SET @LoopID = @LoopID - 1;  
  END  
  
  EXEC DBO.UpdateStocklineDraftDetail @PurchaseOrderId;  
 END    
    COMMIT TRANSACTION    
    
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
	
   DECLARE @ErrorLogID int    
   ,@DatabaseName varchar(100) = DB_NAME()    
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------    
   ,@AdhocComments varchar(150) = 'USP_UpdateAssetInventoryForReceivingPO'    
   ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@PurchaseOrderId, '') + ''    
   ,@ApplicationName varchar(100) = 'PAS'    
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
   EXEC spLogException @DatabaseName = @DatabaseName,    
    @AdhocComments = @AdhocComments,    
    @ProcedureParameters = @ProcedureParameters,    
    @ApplicationName = @ApplicationName,    
    @ErrorLogID = @ErrorLogID OUTPUT;    
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
   RETURN (1);    
  END CATCH    
END