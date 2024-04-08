/*************************************************************             
 ** File:   [USP_UpdateStocklineForReceivingPO]            
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to Update stocklines for receiving PO
 ** Purpose:           
 ** Date:   09/22/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    09/22/2023   Vishal Suthar		Created
    2    10/05/2023   Vishal Suthar		Modified to get parent stockline draft details to bind as parent record
    3    04/08/2024   Vishal Suthar		Modified to update IsParent based on (Serialized) flag modified at the time of receiving
  
declare @p4 dbo.UpdateStocklineReceivingPOType
insert into @p4 values(28702,NULL,N'',NULL,NULL,NULL,0,7,N'',NULL,NULL,0,0,0,0,77,NULL,NULL,N'',NULL,N'',N'',N'',NULL,NULL,NULL,N'',NULL,NULL,NULL,2173,120.00,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,1,N'ADMIN User',N'ADMIN User','2024-04-08 12:49:10.1230932','2024-04-08 07:19:10.0400000',0,0,0,2,0,0,1,NULL,NULL,NULL,0,120.00,N'',NULL,NULL,5,N'',0,3797,N'DHFL-78978',N'asdada',NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,0,NULL,NULL,1,0,0,NULL,NULL,NULL,0,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',N'',N'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',1,NULL,NULL,NULL,0,NULL,0,0,NULL,N'',N'',0,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,1)
insert into @p4 values(28703,NULL,N'',NULL,NULL,NULL,0,7,N'',NULL,NULL,0,0,0,0,77,NULL,NULL,N'',NULL,N'',N'',N'',NULL,NULL,NULL,N'',NULL,NULL,NULL,2173,120.00,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,1,N'ADMIN User',N'ADMIN User','2024-04-08 12:49:10.1237397','2024-04-08 07:19:10.0410000',0,0,0,2,0,0,1,NULL,NULL,NULL,0,120.00,N'',NULL,NULL,5,N'',0,3797,N'DHFL-78978',N'asdada',NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,0,NULL,NULL,1,0,0,NULL,NULL,NULL,1,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',N'',N'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',1,NULL,NULL,NULL,0,NULL,0,0,NULL,N'',N'',0,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,1)
insert into @p4 values(28704,NULL,N'',NULL,NULL,NULL,0,7,N'',NULL,NULL,0,0,0,0,77,NULL,NULL,N'',NULL,N'',N'',N'',NULL,NULL,NULL,N'',NULL,NULL,NULL,2173,120.00,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,1,N'ADMIN User',N'ADMIN User','2024-04-08 12:49:10.1241075','2024-04-08 07:19:10.0410000',0,0,0,2,0,0,1,NULL,NULL,NULL,0,120.00,N'',NULL,NULL,5,N'',0,3797,N'DHFL-78978',N'asdada',NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,0,NULL,NULL,1,0,0,NULL,NULL,NULL,1,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',N'',N'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',1,NULL,NULL,NULL,0,NULL,0,0,NULL,N'',N'',0,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,1)
insert into @p4 values(28705,NULL,N'',NULL,NULL,NULL,0,7,N'',NULL,NULL,0,0,0,0,77,NULL,NULL,N'',NULL,N'',N'',N'',NULL,NULL,NULL,N'',NULL,NULL,NULL,2173,120.00,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,13,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,1,N'ADMIN User',N'ADMIN User','2024-04-08 12:49:10.1243795','2024-04-08 07:19:10.0410000',0,0,0,2,0,0,1,NULL,NULL,NULL,0,120.00,N'',NULL,NULL,5,N'',0,3797,N'DHFL-78978',N'asdada',NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,0,NULL,NULL,1,0,0,NULL,NULL,NULL,1,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'',N'',N'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',1,NULL,NULL,NULL,0,NULL,0,0,NULL,N'',N'',0,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,1)

declare @p5 dbo.UpdateTimeLifeReceivingPOType
insert into @p5 values(0,28702,N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',0)
insert into @p5 values(0,28703,N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',0)
insert into @p5 values(0,28704,N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',0)
insert into @p5 values(0,28705,N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',N'00:00',0)

exec dbo.USP_UpdateStocklineForReceivingPO @PurchaseOrderId=2173,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1,@tbl_UpdateStocklineReceivingPOType=@p4,@tbl_UpdateTimeLifeReceivingPOType=@p5,@IsCreate=1

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_UpdateStocklineForReceivingPO]
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
		DECLARE @LoopID AS INT = 0;

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
			[Adjustment] [decimal](18, 2) NULL,
			[SerialNumberNotProvided] [bit] NULL,
			[ShippingReferenceNumberNotProvided] [bit] NULL,
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
		[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],SerialNumberNotProvided,[ShippingReferenceNumberNotProvided])
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
		[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],SerialNumberNotProvided,ShippingReferenceNumberNotProvided FROM @tbl_UpdateStocklineReceivingPOType;

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

			SELECT @PrevIsSameDetailsForAllParts = IsSameDetailsForAllParts, @PrevIsSerialized = IsSerialized, @PrevIsParent = IsParent FROM DBO.StockLineDraft StkDraft WHERE StkDraft.StockLineDraftId = @SelectedStockLineDraftId;

			IF(@IsCreate = 1)
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

			IF ((@PrevIsSerialized = 1 AND @IsSerialized = 0) OR (@PrevIsSerialized = 0 AND @IsSerialized = 1))
			BEGIN
				IF (@PrevIsParent = 1)
				BEGIN
					SET @PrevIsParent = 0;
				END
				ELSE IF (@PrevIsParent = 0)
				BEGIN
					SET @PrevIsParent = 1;
				END
			END

			UPDATE StkDraft
			SET StkDraft.ManagementStructureEntityId = TmpStkDraft.ManagementStructureEntityId,
			StkDraft.SiteId = CASE WHEN TmpStkDraft.SiteId > 0 THEN TmpStkDraft.SiteId ELSE NULL END,
			StkDraft.WarehouseId = CASE WHEN TmpStkDraft.WarehouseId > 0 THEN TmpStkDraft.WarehouseId ELSE NULL END,
			StkDraft.LocationId = CASE WHEN TmpStkDraft.LocationId > 0 THEN TmpStkDraft.LocationId ELSE NULL END,
			StkDraft.ShelfId = CASE WHEN TmpStkDraft.ShelfId > 0 THEN TmpStkDraft.ShelfId ELSE NULL END,
			StkDraft.BinId = CASE WHEN TmpStkDraft.BinId > 0 THEN TmpStkDraft.BinId ELSE NULL END,
			StkDraft.PurchaseOrderUnitCost = TmpStkDraft.PurchaseOrderUnitCost,
			StkDraft.PurchaseOrderExtendedCost = TmpStkDraft.PurchaseOrderExtendedCost,
			StkDraft.ConditionId = TmpStkDraft.ConditionId,
			StkDraft.ManufacturingTrace = TmpStkDraft.ManufacturingTrace,
			StkDraft.ManufacturerLotNumber = TmpStkDraft.ManufacturerLotNumber,
			StkDraft.ManufacturingDate = TmpStkDraft.ManufacturingDate,
			StkDraft.ManufacturingBatchNumber = TmpStkDraft.ManufacturingBatchNumber,
			StkDraft.PartCertificationNumber = TmpStkDraft.PartCertificationNumber,
			StkDraft.EngineSerialNumber = TmpStkDraft.EngineSerialNumber,
			StkDraft.ShippingViaId = CASE WHEN TmpStkDraft.ShippingViaId > 0 THEN TmpStkDraft.ShippingViaId ELSE NULL END,
			StkDraft.ShippingReference = TmpStkDraft.ShippingReference,
			StkDraft.SerialNumber = TmpStkDraft.SerialNumber,
			StkDraft.ShippingAccount = TmpStkDraft.ShippingAccount,
			StkDraft.CertifiedDate = TmpStkDraft.CertifiedDate,
			StkDraft.CertifiedBy = TmpStkDraft.CertifiedBy,
			StkDraft.TagDate = TmpStkDraft.TagDate,
			StkDraft.ExpirationDate = TmpStkDraft.ExpirationDate,
			StkDraft.CertifiedDueDate = TmpStkDraft.CertifiedDueDate,
			StkDraft.UpdatedBy = TmpStkDraft.UpdatedBy,
			StkDraft.OwnerType = TmpStkDraft.OwnerType,
			StkDraft.[Owner] = TmpStkDraft.[Owner],
			StkDraft.OwnerName = TmpStkDraft.OwnerName,
			StkDraft.ObtainFromType = TmpStkDraft.ObtainFromType,
			StkDraft.ObtainFrom = TmpStkDraft.ObtainFrom,
			StkDraft.ObtainFromName = TmpStkDraft.ObtainFromName,
			StkDraft.TaggedBy = TmpStkDraft.TaggedBy,
			StkDraft.TaggedByType = TmpStkDraft.TaggedByType,
			StkDraft.TaggedByName = TmpStkDraft.TaggedByName,
			StkDraft.UnitOfMeasureId = TmpStkDraft.UnitOfMeasureId,
			StkDraft.TagType = TmpStkDraft.TagType,
			StkDraft.TagTypeId = TmpStkDraft.TagTypeId,
			StkDraft.CertifiedById = TmpStkDraft.CertifiedById,
			StkDraft.CertifiedTypeId = TmpStkDraft.CertifiedTypeId,
			StkDraft.CertType = TmpStkDraft.CertType,
			StkDraft.CertTypeId = TmpStkDraft.CertTypeId,
			StkDraft.GLAccountId = TmpStkDraft.GLAccountId,
			StkDraft.TraceableToType = TmpStkDraft.TraceableToType,
			StkDraft.TraceableTo = TmpStkDraft.TraceableTo,
			StkDraft.TraceableToName = TmpStkDraft.TraceableToName,
			StkDraft.UpdatedDate = GETUTCDATE(),
			StkDraft.LotId = TmpStkDraft.LotId,
			StkDraft.IsSameDetailsForAllParts = TmpStkDraft.IsSameDetailsForAllParts,
			StkDraft.IsSerialized = TmpStkDraft.IsSerialized,
			StkDraft.TimeLifeDetailsNotProvided = TmpStkDraft.TimeLifeDetailsNotProvided,
			StkDraft.SerialNumberNotProvided = TmpStkDraft.SerialNumberNotProvided,
			StkDraft.ShippingReferenceNumberNotProvided = TmpStkDraft.ShippingReferenceNumberNotProvided,
			StkDraft.IsParent = @PrevIsParent
			FROM DBO.StockLineDraft StkDraft
			INNER JOIN #UpdateStocklineReceivingPOType TmpStkDraft ON StkDraft.StockLineDraftId = TmpStkDraft.StockLineDraftId
			WHERE StkDraft.StockLineDraftId = @SelectedStockLineDraftId;

			IF(@IsCreate = 0)
			BEGIN
				IF (@PrevIsSameDetailsForAllParts <> @IsSameDetailsForAllParts)
				BEGIN
					UPDATE StkDraft
					SET StkDraft.IsSameDetailsForAllParts = CASE WHEN TmpStkDraft.IsSameDetailsForAllParts = 1 THEN 0 ELSE 1 END
					FROM DBO.StockLineDraft StkDraft
					INNER JOIN #UpdateStocklineReceivingPOType TmpStkDraft ON TmpStkDraft.StockLineDraftId = StkDraft.StockLineDraftId
					WHERE StkDraft.StockLineDraftId = @SelectedStockLineDraftId;
				END
			END

			SELECT @ManagementStructureEntityId = ManagementStructureEntityId, @CreatedBy = CreatedBy FROM DBO.StockLineDraft StkDraft WHERE StkDraft.StockLineDraftId = @SelectedStockLineDraftId;

			SET @StockLineDraftMSDetailsOpr = 2;

			EXEC dbo.[PROCAddStockLineDraftMSData] @SelectedStockLineDraftId, @ManagementStructureEntityId, @MasterCompanyId, @CreatedBy, @UpdatedBy, @ManagementStructureModuleReceivingPODraft, @StockLineDraftMSDetailsOpr; -- @MSDetailsId OUTPUT

			SET @QuantityBackOrdered = @QuantityBackOrdered + @Quantity;

			SET @LoopID = @LoopID - 1;
		END

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
		FROM @tbl_UpdateTimeLifeReceivingPOType --WHERE [StockLineDraftId] = @SelectedStockLineDraftId;

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

		EXEC DBO.UpdateStocklineDraftDetail @PurchaseOrderId;
	END  
    COMMIT TRANSACTION  
  
  END TRY  
  BEGIN CATCH  
    IF @@trancount > 0  
	  ROLLBACK TRAN;  
	  DECLARE @ErrorLogID int  
	  ,@DatabaseName varchar(100) = DB_NAME()  
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------  
	  ,@AdhocComments varchar(150) = 'USP_UpdateStocklineForReceivingPO'  
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