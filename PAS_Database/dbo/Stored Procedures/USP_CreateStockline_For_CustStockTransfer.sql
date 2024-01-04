/*************************************************************             
 ** File:   [USP_CreateStockline_For_CustStockTransfer]            
 ** Author:   Bhargav Saliya  
 ** Description: This stored procedure is used to Crate stocklines for Customer stock transfer
 ** Purpose:           
 ** Date:   10/26/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    21 DEC 2023   BHARGAV SALIYA		Created
  

exec dbo.USP_CreateStockline_For_CustStockTransfer 59820,236,'Admin User',1,0;
**************************************************************/  
CREATE      PROCEDURE [dbo].[USP_CreateStockline_For_CustStockTransfer]
(  
	@StockLineId BIGINT = NULL,
	@BulkStockLineAdjustmentDetailsId BIGINT = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@Stockline BIGINT OUTPUT
)  
AS  
BEGIN  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON  
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @MainPartLoopID AS INT;
		DECLARE @LoopID AS INT;
		DECLARE @CurrentIndex BIGINT;

			DECLARE @ItemMasterId_Part BIGINT;
			DECLARE @IsSerializedPart BIT;
			DECLARE @SelectedPurchaseOrderPartRecordId BIGINT;
			DECLARE @QtyToReceive INT;
			DECLARE @MainPOPartBackOrderQty INT;
			DECLARE @ItemTypeId INT;

			SELECT @ItemMasterId_Part = ItemMasterId FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId;

			SELECT @IsSerializedPart = IM.isSerialized FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId_Part;

			IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
				BEGIN
					DROP TABLE #tmpStockline
				END

			CREATE TABLE #tmpStockline (
					ID BIGINT NOT NULL IDENTITY,   
					[StockLineId] [bigint] NOT NULL,
					[PartNumber] [varchar](50) NOT NULL,
					[StockLineNumber] [varchar](50) NULL,
					[StocklineMatchKey] [varchar](100) NULL,
					[ControlNumber] [varchar](50) NULL,
					[ItemMasterId] [bigint] NULL,
					[Quantity] [int] NULL,
					[ConditionId] [bigint] NOT NULL,
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
					[TagType] [varchar](500) NULL,
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
					[IsPMA] [bit] NOT NULL,
					[IsDER] [bit] NOT NULL,
					[OEM] [bit] NOT NULL,
					[Memo] [nvarchar](max) NULL,
					[ManagementStructureId] [bigint] NOT NULL,
					[LegalEntityId] [bigint] NULL,
					[MasterCompanyId] [int] NOT NULL,
					[CreatedBy] [varchar](256) NULL,
					[UpdatedBy] [varchar](256) NULL,
					[CreatedDate] [datetime2](7) NULL,
					[UpdatedDate] [datetime2](7) NULL,
					[isSerialized] [bit] NULL,
					[ShelfId] [bigint] NULL,
					[BinId] [bigint] NULL,
					[SiteId] [bigint] NOT NULL,
					[ObtainFromType] [int] NULL,
					[OwnerType] [int] NULL,
					[TraceableToType] [int] NULL,
					[UnitCostAdjustmentReasonTypeId] [int] NULL,
					[UnitSalePriceAdjustmentReasonTypeId] [int] NULL,
					[IdNumber] [varchar](100) NULL,
					[QuantityToReceive] [int] NULL,
					[PurchaseOrderExtendedCost] [decimal](18, 0) NOT NULL,
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
					[TimeLifeDetailsNotProvided] [bit] NOT NULL,
					[WorkOrderId] [bigint] NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[QuantityReserved] [int] NULL,
					[QuantityTurnIn] [int] NULL,
					[QuantityIssued] [int] NULL,
					[QuantityOnHand] [int] NOT NULL,
					[QuantityAvailable] [int] NULL,
					[QuantityOnOrder] [int] NULL,
					[QtyReserved] [int] NULL,
					[QtyIssued] [int] NULL,
					[BlackListed] [bit] NOT NULL,
					[BlackListedReason] [varchar](max) NULL,
					[Incident] [bit] NOT NULL,
					[IncidentReason] [varchar](max) NULL,
					[Accident] [bit] NOT NULL,
					[AccidentReason] [varchar](max) NULL,
					[RepairOrderPartRecordId] [bigint] NULL,
					[isActive] [bit] NOT NULL,
					[isDeleted] [bit] NOT NULL,
					[WorkOrderExtendedCost] [decimal](20, 2) NULL,
					[RepairOrderExtendedCost] [decimal](18, 2) NULL,
					[IsCustomerStock] [bit] NULL,
					[EntryDate] [datetime] NULL,
					[LotCost] [decimal](18, 2) NULL,
					[NHAItemMasterId] [bigint] NULL,
					[TLAItemMasterId] [bigint] NULL,
					[ItemTypeId] [int] NULL,
					[AcquistionTypeId] [bigint] NULL,
					[RequestorId] [bigint] NULL,
					[LotNumber] [varchar](50) NULL,
					[LotDescription] [varchar](250) NULL,
					[TagNumber] [varchar](50) NULL,
					[InspectionBy] [bigint] NULL,
					[InspectionDate] [datetime2](7) NULL,
					[VendorId] [bigint] NULL,
					[IsParent] [bit] NULL,
					[ParentId] [bigint] NULL,
					[IsSameDetailsForAllParts] [bit] NULL,
					[WorkOrderPartNoId] [bigint] NULL,
					[SubWorkOrderId] [bigint] NULL,
					[SubWOPartNoId] [bigint] NULL,
					[IsOemPNId] [bigint] NULL,
					[PurchaseUnitOfMeasureId] [bigint] NOT NULL,
					[ObtainFromName] [varchar](50) NULL,
					[OwnerName] [varchar](50) NULL,
					[TraceableToName] [varchar](50) NULL,
					[Level1] [varchar](100) NULL,
					[Level2] [varchar](100) NULL,
					[Level3] [varchar](100) NULL,
					[Level4] [varchar](100) NULL,
					[Condition] [varchar](100) NULL,
					[GlAccountName] [varchar](100) NULL,
					[Site] [varchar](100) NULL,
					[Warehouse] [varchar](100) NULL,
					[Location] [varchar](100) NULL,
					[Shelf] [varchar](100) NULL,
					[Bin] [varchar](100) NULL,
					[UnitOfMeasure] [varchar](100) NULL,
					[WorkOrderNumber] [varchar](500) NULL,
					[itemGroup] [varchar](256) NULL,
					[TLAPartNumber] [varchar](100) NULL,
					[NHAPartNumber] [varchar](100) NULL,
					[TLAPartDescription] [varchar](100) NULL,
					[NHAPartDescription] [nvarchar](max) NULL,
					[itemType] [varchar](100) NULL,
					[CustomerId] [bigint] NULL,
					[CustomerName] [varchar](200) NULL,
					[isCustomerstockType] [bit] NULL,
					[PNDescription] [nvarchar](max) NULL,
					[RevicedPNId] [bigint] NULL,
					[RevicedPNNumber] [nvarchar](50) NULL,
					[OEMPNNumber] [nvarchar](50) NULL,
					[TaggedBy] [bigint] NULL,
					[TaggedByName] [nvarchar](50) NULL,
					[UnitCost] [decimal](18, 2) NULL,
					[TaggedByType] [int] NULL,
					[TaggedByTypeName] [varchar](250) NULL,
					[CertifiedById] [bigint] NULL,
					[CertifiedTypeId] [int] NULL,
					[CertifiedType] [varchar](250) NULL,
					[CertTypeId] [varchar](max) NULL,
					[CertType] [varchar](max) NULL,
					[TagTypeId] [bigint] NULL,
					[IsFinishGood] [bit] NULL,
					[IsTurnIn] [bit] NULL,
					[IsCustomerRMA] [bit] NULL,
					[RMADeatilsId] [bigint] NULL,
					[DaysReceived] [int] NULL,
					[ManufacturingDays] [int] NULL,
					[TagDays] [int] NULL,
					[OpenDays] [int] NULL,
					[ExchangeSalesOrderId] [bigint] NULL,
					[RRQty] [int] NOT NULL,
					[SubWorkOrderNumber] [varchar](50) NULL,
					[IsManualEntry] [bit] NULL,
					[WorkOrderMaterialsKitId] [bigint] NULL,
					[LotId] [bigint] NULL,
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
					[SalesOrderPartId] [bigint] NULL,
					[FreightAdjustment] [decimal](18, 2) NULL,
					[TaxAdjustment] [decimal](18, 2) NULL,
					[IsStkTimeLife] [bit] NULL,
				)
				
			--INSERT INTO #tmpStockline SELECT * FROM DBO.Stockline Stk WITH(NOLOCK) WHERE Stk.StockLineId = @StockLineId;

			INSERT INTO #tmpStockline ([StockLineId],
						[PartNumber],
						[StockLineNumber],
						[StocklineMatchKey],
						[ControlNumber] ,
						[ItemMasterId] ,
						[Quantity],
						[ConditionId],
						[SerialNumber],
						[ShelfLife],
						[ShelfLifeExpirationDate],
						[WarehouseId],
						[LocationId],
						[ObtainFrom],
						[Owner],
						[TraceableTo],
						[ManufacturerId],
						[Manufacturer],
						[ManufacturerLotNumber],
						[ManufacturingDate],
						[ManufacturingBatchNumber],
						[PartCertificationNumber],
						[CertifiedBy],
						[CertifiedDate],
						[TagDate],
						[TagType],
						[CertifiedDueDate],
						[CalibrationMemo],
						[OrderDate],
						[PurchaseOrderId],
						[PurchaseOrderUnitCost],
						[InventoryUnitCost],
						[RepairOrderId],
						[RepairOrderUnitCost],
						[ReceivedDate],
						[ReceiverNumber],
						[ReconciliationNumber],
						[UnitSalesPrice],
						[CoreUnitCost],
						[GLAccountId],
						[AssetId],
						[IsHazardousMaterial],
						[IsPMA],
						[IsDER],
						[OEM],
						[Memo],
						[ManagementStructureId],
						[LegalEntityId],
						[MasterCompanyId],
						[CreatedBy],
						[UpdatedBy],
						[CreatedDate],
						[UpdatedDate],
						[isSerialized],
						[ShelfId],
						[BinId],
						[SiteId],
						[ObtainFromType],
						[OwnerType],
						[TraceableToType],
						[UnitCostAdjustmentReasonTypeId],
						[UnitSalePriceAdjustmentReasonTypeId],
						[IdNumber],
						[QuantityToReceive],
						[PurchaseOrderExtendedCost],
						[ManufacturingTrace],
						[ExpirationDate],
						[AircraftTailNumber],
						[ShippingViaId],
						[EngineSerialNumber],
						[QuantityRejected],
						[PurchaseOrderPartRecordId],
						[ShippingAccount],
						[ShippingReference],
						[TimeLifeCyclesId],
						[TimeLifeDetailsNotProvided],
						[WorkOrderId],
						[WorkOrderMaterialsId],
						[QuantityReserved],
						[QuantityTurnIn],
						[QuantityIssued],
						[QuantityOnHand],
						[QuantityAvailable],
						[QuantityOnOrder],
						[QtyReserved],
						[QtyIssued],
						[BlackListed],
						[BlackListedReason],
						[Incident],
						[IncidentReason],
						[Accident],
						[AccidentReason],
						[RepairOrderPartRecordId],
						[isActive],
						[isDeleted],
						[WorkOrderExtendedCost],
						[RepairOrderExtendedCost],
						[IsCustomerStock],
						[EntryDate],
						[LotCost],
						[NHAItemMasterId],
						[TLAItemMasterId],
						[ItemTypeId],
						[AcquistionTypeId],
						[RequestorId],
						[LotNumber],
						[LotDescription],
						[TagNumber],
						[InspectionBy],
						[InspectionDate],
						[VendorId],
						[IsParent],
						[ParentId],
						[IsSameDetailsForAllParts],
						[WorkOrderPartNoId],
						[SubWorkOrderId],
						[SubWOPartNoId],
						[IsOemPNId],
						[PurchaseUnitOfMeasureId],
						[ObtainFromName],
						[OwnerName],
						[TraceableToName],
						[Level1],
						[Level2],
						[Level3],
						[Level4],
						[Condition],
						[GlAccountName],
						[Site],
						[Warehouse],
						[Location],
						[Shelf],
						[Bin],
						[UnitOfMeasure],
						[WorkOrderNumber],
						[itemGroup],
						[TLAPartNumber],
						[NHAPartNumber],
						[TLAPartDescription],
						[NHAPartDescription],
						[itemType],
						[CustomerId],
						[CustomerName],
						[isCustomerstockType],
						[PNDescription],
						[RevicedPNId],
						[RevicedPNNumber],
						[OEMPNNumber],
						[TaggedBy],
						[TaggedByName],
						[UnitCost],
						[TaggedByType],
						[TaggedByTypeName],
						[CertifiedById],
						[CertifiedTypeId],
						[CertifiedType],
						[CertTypeId],
						[CertType],
						[TagTypeId],
						[IsFinishGood],
						[IsTurnIn],
						[IsCustomerRMA],
						[RMADeatilsId],
						[DaysReceived],
						[ManufacturingDays],
						[TagDays],
						[OpenDays],
						[ExchangeSalesOrderId],
						[RRQty],
						[SubWorkOrderNumber],
						[IsManualEntry],
						[WorkOrderMaterialsKitId],
						[LotId],
						[IsLotAssigned],
						[LOTQty],
						[LOTQtyReserve],
						[OriginalCost],
						[POOriginalCost],
						[ROOriginalCost],
						[VendorRMAId],
						[VendorRMADetailId],
						[LotMainStocklineId],
						[IsFromInitialPO],
						[LotSourceId],
						[Adjustment],
						[SalesOrderPartId],
						[FreightAdjustment],
						[TaxAdjustment],
						[IsStkTimeLife]
					) SELECT [StockLineId],
						[PartNumber],
						[StockLineNumber],
						[StocklineMatchKey],
						[ControlNumber] ,
						[ItemMasterId] ,
						[Quantity],
						[ConditionId],
						[SerialNumber],
						[ShelfLife],
						[ShelfLifeExpirationDate],
						[WarehouseId],
						[LocationId],
						[ObtainFrom],
						[Owner],
						[TraceableTo],
						[ManufacturerId],
						[Manufacturer],
						[ManufacturerLotNumber],
						[ManufacturingDate],
						[ManufacturingBatchNumber],
						[PartCertificationNumber],
						[CertifiedBy],
						[CertifiedDate],
						[TagDate],
						[TagType],
						[CertifiedDueDate],
						[CalibrationMemo],
						[OrderDate],
						[PurchaseOrderId],
						[PurchaseOrderUnitCost],
						[InventoryUnitCost],
						[RepairOrderId],
						[RepairOrderUnitCost],
						[ReceivedDate],
						[ReceiverNumber],
						[ReconciliationNumber],
						[UnitSalesPrice],
						[CoreUnitCost],
						[GLAccountId],
						[AssetId],
						[IsHazardousMaterial],
						[IsPMA],
						[IsDER],
						[OEM],
						[Memo],
						[ManagementStructureId],
						[LegalEntityId],
						[MasterCompanyId],
						[CreatedBy],
						[UpdatedBy],
						[CreatedDate],
						[UpdatedDate],
						[isSerialized],
						[ShelfId],
						[BinId],
						[SiteId],
						[ObtainFromType],
						[OwnerType],
						[TraceableToType],
						[UnitCostAdjustmentReasonTypeId],
						[UnitSalePriceAdjustmentReasonTypeId],
						[IdNumber],
						[QuantityToReceive],
						[PurchaseOrderExtendedCost],
						[ManufacturingTrace],
						[ExpirationDate],
						[AircraftTailNumber],
						[ShippingViaId],
						[EngineSerialNumber],
						[QuantityRejected],
						[PurchaseOrderPartRecordId],
						[ShippingAccount],
						[ShippingReference],
						[TimeLifeCyclesId],
						[TimeLifeDetailsNotProvided],
						[WorkOrderId],
						[WorkOrderMaterialsId],
						[QuantityReserved],
						[QuantityTurnIn],
						[QuantityIssued],
						[QuantityOnHand],
						[QuantityAvailable],
						[QuantityOnOrder],
						[QtyReserved],
						[QtyIssued],
						[BlackListed],
						[BlackListedReason],
						[Incident],
						[IncidentReason],
						[Accident],
						[AccidentReason],
						[RepairOrderPartRecordId],
						[isActive],
						[isDeleted],
						[WorkOrderExtendedCost],
						[RepairOrderExtendedCost],
						0, --[IsCustomerStock],	
						[EntryDate],
						[LotCost],
						[NHAItemMasterId],
						[TLAItemMasterId],
						[ItemTypeId],
						[AcquistionTypeId],
						[RequestorId],
						[LotNumber],
						[LotDescription],
						[TagNumber],
						[InspectionBy],
						[InspectionDate],
						[VendorId],
						[IsParent],
						[ParentId],
						[IsSameDetailsForAllParts],
						[WorkOrderPartNoId],
						[SubWorkOrderId],
						[SubWOPartNoId],
						[IsOemPNId],
						[PurchaseUnitOfMeasureId],
						[ObtainFromName],
						[OwnerName],
						[TraceableToName],
						[Level1],
						[Level2],
						[Level3],
						[Level4],
						[Condition],
						[GlAccountName],
						[Site],
						[Warehouse],
						[Location],
						[Shelf],
						[Bin],
						[UnitOfMeasure],
						[WorkOrderNumber],
						[itemGroup],
						[TLAPartNumber],
						[NHAPartNumber],
						[TLAPartDescription],
						[NHAPartDescription],
						[itemType],
						[CustomerId],
						[CustomerName],
						[isCustomerstockType],
						[PNDescription],
						[RevicedPNId],
						[RevicedPNNumber],
						[OEMPNNumber],
						[TaggedBy],
						[TaggedByName],
						[UnitCost],
						[TaggedByType],
						[TaggedByTypeName],
						[CertifiedById],
						[CertifiedTypeId],
						[CertifiedType],
						[CertTypeId],
						[CertType],
						[TagTypeId],
						[IsFinishGood],
						[IsTurnIn],
						[IsCustomerRMA],
						[RMADeatilsId],
						[DaysReceived],
						[ManufacturingDays],
						[TagDays],
						[OpenDays],
						[ExchangeSalesOrderId],
						[RRQty],
						[SubWorkOrderNumber],
						[IsManualEntry],
						[WorkOrderMaterialsKitId],
						[LotId],
						[IsLotAssigned],
						[LOTQty],
						[LOTQtyReserve],
						[OriginalCost],
						[POOriginalCost],
						[ROOriginalCost],
						[VendorRMAId],
						[VendorRMADetailId],
						[LotMainStocklineId],
						[IsFromInitialPO],
						[LotSourceId],
						[Adjustment],
						[SalesOrderPartId],
						[FreightAdjustment],
						[TaxAdjustment],
						[IsStkTimeLife]
					FROM DBO.Stockline Stk WITH(NOLOCK) WHERE Stk.StockLineId = @StockLineId;



			SET @CurrentIndex = 0;
			SELECT @LoopID = MAX(ID) FROM #tmpStockline;
			
			WHILE (@LoopID > 0)
				BEGIN 
					DECLARE @SelectedStockLineId BIGINT;
					DECLARE @CurrentIdNumber AS BIGINT;
					DECLARE @ReceiverNumber AS VARCHAR(50);
					DECLARE @IdCodeTypeId BIGINT;
					DECLARE @PORequestorId BIGINT;
					DECLARE @POVendorId BIGINT;
					DECLARE @NewStocklineId BIGINT;
					DECLARE @StockLineNumber VARCHAR(100);
					DECLARE @CNCurrentNumber BIGINT;
					DECLARE @ControlNumber VARCHAR(50);
					DECLARE @currentNo AS BIGINT = 0;  
					DECLARE @stockLineCurrentNo AS BIGINT;  
					DECLARE @ItemMasterId AS BIGINT;  
					DECLARE @ConditionId AS BIGINT;  
					DECLARE @StkPurchaseOrderUnitCost AS DECIMAL(18, 2) = 0;  
					DECLARE @ManufacturerId AS BIGINT;
					DECLARE @PreviousStockLineNumber VARCHAR(50);
					DECLARE @qtyonhand INT;
					DECLARE @ManagementStructureId BIGINT;

					SELECT @SelectedStockLineId = StockLineId FROM #tmpStockline WHERE ID = @LoopID;
					--SELECT @PORequestorId = RequestedBy, @POVendorId = VendorId FROM DBO.PurchaseOrder WHERE PurchaseOrderId = @PurchaseOrderId;

					SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Stock Line';

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

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					IF (@CurrentIndex = 0)
					BEGIN
						SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END   
						FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					END
					ELSE
					BEGIN
						SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
						FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					END
					
					SET @ReceiverNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber, 'RecNo', (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))  

					/* PN Manufacturer Combination Stockline logic */
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
					)  
  
					;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS  
					(
						SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId  
						FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1 CROSS JOIN  
						(SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2 LEFT JOIN  
						DBO.Stockline ac WITH (NOLOCK)  
						ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
						WHERE ac.MasterCompanyId = @MasterCompanyId  
						GROUP BY ac.ItemMasterId, ac.ManufacturerId  
						HAVING COUNT(ac.ItemMasterId) > 0  
					)
  
					INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)  
					SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized  
					FROM CTE_Stockline CSTL INNER JOIN DBO.Stockline STL WITH (NOLOCK)   
					INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId  
					ON CSTL.StockLineId = STL.StockLineId  
					/* PN Manufacturer Combination Stockline logic */

					DELETE FROM #tmpCodePrefixes;

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
					WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					SELECT @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StkPurchaseOrderUnitCost = PurchaseOrderUnitCost, @ManufacturerId = ManufacturerId, @PreviousStockLineNumber = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @SelectedStockLineId;
					SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

					IF (@currentNo <> 0)
					BEGIN
						SET @stockLineCurrentNo = @currentNo + 1;
					END
					ELSE
					BEGIN
						SET @stockLineCurrentNo = 1;
					END

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 30))
					BEGIN
						SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))  
				
						UPDATE DBO.ItemMaster
						SET CurrentStlNo = @stockLineCurrentNo
						WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
					END

					IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
					BEGIN
						SELECT @CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END FROM #tmpCodePrefixes WHERE CodeTypeId = 9;
						SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 9)))
					END					
					
					SELECT @qtyonhand = NewQty, @ManagementStructureId =ToManagementStructureId FROM BulkStockLineAdjustmentDetails WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
					INSERT INTO DBO.Stockline ([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber],[ShelfLife],
					[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],
					[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],
					[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],
					[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
					[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],
					[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],
					[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],[QuantityReserved],
					[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],
					[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],
					[NHAItemMasterId],[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate],[VendorId],[IsParent],
					[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],
					[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],
					[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],
					[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],
					[IsTurnIn],[IsCustomerRMA],[RMADeatilsId],[DaysReceived],[ManufacturingDays],[TagDays],[OpenDays],[ExchangeSalesOrderId],[RRQty],[SubWorkOrderNumber],[IsManualEntry],[WorkOrderMaterialsKitId],
					[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[IsStkTimeLife])
			
					SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],@ControlNumber,[ItemMasterId],@qtyonhand ,[ConditionId],[SerialNumber],[ShelfLife],
					[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],
					[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],
					[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],0,[ReceivedDate],@ReceiverNumber,[ReconciliationNumber],0,0,
					[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],@ManagementStructureId,[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),
					GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId],NULL,[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],
					[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],
					[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],0,
					0,0,@qtyonhand,@qtyonhand,0,0,0,[BlackListed],[BlackListedReason],[Incident],[IncidentReason],
					[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],0,[IsCustomerStock],GETUTCDATE(), 0,
					[NHAItemMasterId],[TLAItemMasterId],NULL,NULL, @PORequestorId, NULL, NULL, NULL, NULL, NULL, NULL, [IsParent],
					[ParentId],[IsSameDetailsForAllParts],0,[SubWorkOrderId],0,NULL, 0,[ObtainFromName],[OwnerName],[TraceableToName],
					[Level1],[Level2],[Level3],[Level4],[Condition],NULL,NULL,[Warehouse],[Location],NULL,NULL,[UnitOfMeasure],NULL,NULL,NULL,
					NULL,NULL,NULL,NULL,[CustomerId],NULL,ISNULL([isCustomerstockType], 0), '', NULL, NULL, NULL,
					[TaggedBy],[TaggedByName], (0 + 0 + 0)
					,[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0,
					0,NULL,NULL,NULL,NULL,NULL,NULL,[ExchangeSalesOrderId], @qtyonhand, NULL, 1, NULL,
					[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],0, [IsStkTimeLife]
					FROM #tmpStockline
					WHERE StockLineId = @SelectedStockLineId;

					DECLARE @QtyAdded INT = 0;
					DECLARE @PurchaseOrderUnitCostAdded DECIMAL(18, 2) = 0;
					DECLARE @SelectedIsSameDetailsForAllParts BIT = 0;
					DECLARE @IsTimeLIfe BIT

					SELECT @QtyAdded = CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
					@SelectedIsSameDetailsForAllParts = IsSameDetailsForAllParts, @PurchaseOrderUnitCostAdded = PurchaseOrderUnitCost, @IsTimeLIfe = [IsStkTimeLife] 
					FROM #tmpStockline 
					WHERE StockLineId = @SelectedStockLineId;

					SELECT @NewStocklineId = SCOPE_IDENTITY();

					IF(@IsTimeLIfe = 1)
					BEGIN
						INSERT INTO DBO.TimeLife ([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],
						[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
						[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],
						[VendorRMAId],[VendorRMADetailId])
						SELECT [CyclesRemaining], [CyclesSinceNew], [CyclesSinceOVH], [CyclesSinceInspection], [CyclesSinceRepair], [TimeRemaining], [TimeSinceNew],
						[TimeSinceOVH], [TimeSinceInspection], [TimeSinceRepair], [LastSinceNew], [LastSinceOVH], [LastSinceInspection], @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),
						GETUTCDATE(), 1, NULL, @SelectedPurchaseOrderPartRecordId, @NewStocklineId, [DetailsNotProvided], NULL, NULL,
						NULL, NULL
						FROM DBO.TimeLife WHERE StockLineId = @SelectedStockLineId;
					END

					DECLARE @OrderModule AS BIGINT = 22;
					DECLARE @ActionId as BIGINT = 0;
					SELECT @ActionId = ActionId FROM DBO.[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'Add-To-CustStock'
					EXEC USP_AddUpdateStocklineHistory @NewStocklineId, @OrderModule, NULL, NULL, NULL, @ActionId, @qtyonhand, @UpdatedBy;

					UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNumber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

					DECLARE @StkManagementStructureModuleId BIGINT = 2;
					DECLARE @ManagementStructureEntityId BIGINT = 0;

					SELECT @ManagementStructureEntityId = [ManagementStructureId] FROM DBO.Stockline WHERE StocklineId = @NewStocklineId;

					EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId, @NewStocklineId, @ManagementStructureEntityId, @MasterCompanyId, @UpdatedBy;
					
					--Return new stocklineid
					SET @Stockline = @NewStocklineId;
					SET @LoopID = @LoopID - 1;
				END

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
	  ,@AdhocComments varchar(150) = 'USP_CreateStockline_For_CustStockTransfer'  
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@StockLineId, '') + ''  
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