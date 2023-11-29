/*************************************************************             
 ** File:   [USP_CreateStocklineForReceivingPO]            
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to Crate stocklines for receiving PO
 ** Purpose:           
 ** Date:   08/21/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    08/21/2023   Vishal Suthar		Created
  
declare @p2 dbo.POPartsToReceive
insert into @p2 values(1871,3471,2)

exec dbo.USP_CreateStocklineForReceivingPO @PurchaseOrderId=1871,@tbl_POPartsToReceive=@p2,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_CreateStocklineForReceivingPO]
(  
	@PurchaseOrderId BIGINT = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@tbl_POPartsToReceive POPartsToReceive READONLY
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

		IF OBJECT_ID(N'tempdb..#POPartsToReceive') IS NOT NULL
		BEGIN
			DROP TABLE #POPartsToReceive 
		END
			
		CREATE TABLE #POPartsToReceive 
		(
			ID BIGINT NOT NULL IDENTITY,
			[PurchaseOrderId] [bigint] NULL,
			[PurchaseOrderPartRecordId] [bigint] NULL,
			[QtyToReceive] [int] NULL
		)

		INSERT INTO #POPartsToReceive ([PurchaseOrderId],[PurchaseOrderPartRecordId],[QtyToReceive])
		SELECT [PurchaseOrderId],[PurchaseOrderPartRecordId],[QtyToReceive] FROM @tbl_POPartsToReceive;

		SELECT @MainPartLoopID = MAX(ID) FROM #POPartsToReceive;

		WHILE (@MainPartLoopID > 0)
		BEGIN
			DECLARE @ItemMasterId_Part BIGINT;
			DECLARE @IsSerializedPart BIT;
			DECLARE @SelectedPurchaseOrderPartRecordId BIGINT;
			DECLARE @QtyToReceive INT;
			DECLARE @MainPOPartBackOrderQty INT;

			SELECT @SelectedPurchaseOrderPartRecordId = [PurchaseOrderPartRecordId], @QtyToReceive = [QtyToReceive] FROM #POPartsToReceive WHERE ID = @MainPartLoopID;

			SELECT @ItemMasterId_Part = POP.ItemMasterId, @MainPOPartBackOrderQty = POP.QuantityBackOrdered FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE POP.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
			SELECT @IsSerializedPart = IM.isSerialized FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId_Part;

			IF OBJECT_ID(N'tempdb..#tmpStocklineDraft') IS NOT NULL
			BEGIN
				DROP TABLE #tmpStocklineDraft
			END

			CREATE TABLE #tmpStocklineDraft (
				ID BIGINT NOT NULL IDENTITY,   
				[StockLineDraftId] [bigint] NOT NULL,
				[PartNumber] [varchar](50) NOT NULL,
				[StockLineNumber] [varchar](50) NULL,
				[StocklineMatchKey] [varchar](100) NULL,
				[ControlNumber] [varchar](50) NULL,
				[ItemMasterId] [bigint] NULL,
				[Quantity] [int] NOT NULL,
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
				[CreatedBy] [varchar](256) NOT NULL,
				[UpdatedBy] [varchar](256) NOT NULL,
				[CreatedDate] [datetime2](7) NOT NULL,
				[UpdatedDate] [datetime2](7) NOT NULL,
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
				[QuantityToReceive] [int] NOT NULL,
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
				[QuantityOnHand] [int] NULL,
				[QuantityAvailable] [int] NULL,
				[QuantityOnOrder] [int] NULL,
				[QtyReserved] [int] NULL,
				[QtyIssued] [int] NULL,
				[BlackListed] [bit] NOT NULL,
				[BlackListedReason] [varchar](500) NULL,
				[Incident] [bit] NOT NULL,
				[IncidentReason] [varchar](500) NULL,
				[Accident] [bit] NOT NULL,
				[AccidentReason] [varchar](500) NULL,
				[RepairOrderPartRecordId] [bigint] NULL,
				[isActive] [bit] NOT NULL,
				[isDeleted] [bit] NOT NULL,
				[WorkOrderExtendedCost] [decimal](20, 2) NOT NULL,
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
				[Adjustment] [decimal](18, 2) NULL
			)

			INSERT INTO #tmpStocklineDraft SELECT * FROM DBO.StocklineDraft StkDraft WITH(NOLOCK) WHERE StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND StockLineNumber IS NULL ORDER BY CreatedDate;

			SET @CurrentIndex = 0;

			IF (@IsSerializedPart = 1)
			BEGIN
				SET @LoopID = @QtyToReceive;
			END
			ELSE
			BEGIN
				DECLARE @IsSameDetailsForAllParts BIT = 1;
				SELECT TOP 1 @IsSameDetailsForAllParts = StkDraft.IsSameDetailsForAllParts FROM DBO.StocklineDraft StkDraft WITH(NOLOCK) WHERE IsParent = 1 AND StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

				--SELECT * FROM DBO.StocklineDraft StkDraft WITH(NOLOCK) WHERE IsParent = 1 AND StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

				IF (@IsSameDetailsForAllParts = 0)
				BEGIN
					SET @LoopID = @QtyToReceive;
				END
				ELSE
				BEGIN
					SELECT @LoopID = MAX(ID) FROM #tmpStocklineDraft;
				END
			END

			WHILE (@LoopID > 0)
			BEGIN
				DECLARE @SelectedStockLineDraftId BIGINT;
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

				SELECT @SelectedStockLineDraftId = StockLineDraftId FROM #tmpStocklineDraft WHERE ID = @LoopID;
				SELECT @PORequestorId = RequestedBy, @POVendorId = VendorId FROM DBO.PurchaseOrder WHERE PurchaseOrderId = @PurchaseOrderId;

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

				SELECT @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StkPurchaseOrderUnitCost = PurchaseOrderUnitCost, @ManufacturerId = ManufacturerId, @PreviousStockLineNumber = StockLineNumber FROM dbo.StocklineDraft WITH(NOLOCK) WHERE StockLineDraftId = @SelectedStockLineDraftId;
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
				[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment])
			
				SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],@ControlNumber,[ItemMasterId], CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,[ConditionId],[SerialNumber],[ShelfLife],
				[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],
				[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],
				[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],ISNULL([RepairOrderUnitCost], 0),[ReceivedDate],@ReceiverNumber,[ReconciliationNumber],ISNULL([UnitSalesPrice], 0),ISNULL([CoreUnitCost], 0),
				[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),
				GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId],NULL,[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],
				[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],
				[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],ISNULL([QuantityReserved], 0),
				ISNULL([QuantityTurnIn], 0),ISNULL([QuantityIssued], 0),CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,ISNULL([QuantityOnOrder], 0),ISNULL([QtyReserved], 0),ISNULL([QtyIssued], 0),[BlackListed],[BlackListedReason],[Incident],[IncidentReason],
				[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],ISNULL([RepairOrderExtendedCost], 0),[IsCustomerStock],GETUTCDATE(), 0,
				[NHAItemMasterId],[TLAItemMasterId],NULL,NULL, @PORequestorId, NULL, NULL, NULL, NULL, NULL, @POVendorId, [IsParent],
				[ParentId],[IsSameDetailsForAllParts],0,[SubWorkOrderId],0,NULL, [UnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],
				[Level1],[Level2],[Level3],[Level4],[Condition],NULL,NULL,[Warehouse],[Location],NULL,NULL,[UnitOfMeasure],NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,[CustomerId],NULL,ISNULL([isCustomerstockType], 0), '', NULL, NULL, NULL,
				[TaggedBy],[TaggedByName], (ISNULL(PurchaseOrderUnitCost, 0) + ISNULL(RepairOrderUnitCost, 0) + ISNULL(Adjustment , 0))
				,[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0,
				0,NULL,NULL,NULL,NULL,NULL,NULL,[ExchangeSalesOrderId], CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE @QtyToReceive END, NULL, 1, NULL,
				[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],ISNULL(Adjustment , 0)
				FROM #tmpStocklineDraft 
				WHERE StockLineDraftId = @SelectedStockLineDraftId;

				DECLARE @QtyAdded INT = 0;
				DECLARE @PurchaseOrderUnitCostAdded DECIMAL(18, 2) = 0;
				DECLARE @SelectedIsSameDetailsForAllParts BIT = 0;

				SELECT @QtyAdded = CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
				@SelectedIsSameDetailsForAllParts = IsSameDetailsForAllParts, @PurchaseOrderUnitCostAdded = PurchaseOrderUnitCost
				FROM #tmpStocklineDraft 
				WHERE StockLineDraftId = @SelectedStockLineDraftId;

				SELECT @NewStocklineId = SCOPE_IDENTITY();

				INSERT INTO DBO.TimeLife ([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],
				[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
				[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],
				[VendorRMAId],[VendorRMADetailId])
				SELECT [CyclesRemaining], [CyclesSinceNew], [CyclesSinceOVH], [CyclesSinceInspection], [CyclesSinceRepair], [TimeRemaining], [TimeSinceNew],
				[TimeSinceOVH], [TimeSinceInspection], [TimeSinceRepair], [LastSinceNew], [LastSinceOVH], [LastSinceInspection], @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),
				GETUTCDATE(), 1, @PurchaseOrderId, @SelectedPurchaseOrderPartRecordId, @NewStocklineId, [DetailsNotProvided], NULL, NULL,
				NULL, NULL
				FROM DBO.TimeLifeDraft WHERE StockLineDraftId = @SelectedStockLineDraftId;

				/* Accounting Entry */
				DECLARE @p2 dbo.PostStocklineBatchType;

				INSERT INTO @p2 VALUES(@NewStocklineId, @QtyAdded, @PurchaseOrderUnitCostAdded, 'ReceivingPO', @UpdatedBy, @MasterCompanyId, 'STOCK')

				EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p2, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;

				DECLARE @ReceivingPurchaseOrderModule AS BIGINT = 28;

				EXEC USP_AddUpdateStocklineHistory @NewStocklineId, @ReceivingPurchaseOrderModule, @PurchaseOrderId, NULL, NULL, 11, @QtyAdded, @UpdatedBy;

				UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNumber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

				DECLARE @StkManagementStructureModuleId BIGINT = 2;
				DECLARE @ManagementStructureEntityId BIGINT = 0;

				SELECT @ManagementStructureEntityId = [ManagementStructureId] FROM DBO.Stockline WHERE StocklineId = @NewStocklineId;

				EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId, @NewStocklineId, @ManagementStructureEntityId, @MasterCompanyId, @UpdatedBy;

				IF (@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts = 1)
				BEGIN
					DECLARE @LoopID_QtyToReceive INT = 0;
					IF OBJECT_ID(N'tempdb..#StocklineDraftForQtyToReceive') IS NOT NULL
					BEGIN
						DROP TABLE #StocklineDraftForQtyToReceive 
					END
			
					CREATE TABLE #StocklineDraftForQtyToReceive 
					(
						ID BIGINT NOT NULL IDENTITY,
						[StocklineDraftId] [bigint] NULL
					)

					INSERT INTO #StocklineDraftForQtyToReceive ([StocklineDraftId])
					SELECT [StocklineDraftId] FROM DBO.StocklineDraft WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId
					AND IsParent = 0 AND isSerialized = 0 AND IsSameDetailsForAllParts = 1 AND StockLineId IS NULL
					ORDER BY StocklineDraftId DESC;

					SELECT @LoopID_QtyToReceive = MAX(ID) FROM #StocklineDraftForQtyToReceive;
					DECLARE @TotalQtyToTraverse INT = 0;

					SET @TotalQtyToTraverse = @QtyToReceive;

					WHILE (@LoopID_QtyToReceive > 0)
					BEGIN
						IF (@TotalQtyToTraverse > 0)
						BEGIN
							DECLARE @CurrentStocklineDraftId BIGINT = 0;

							SELECT @CurrentStocklineDraftId = StocklineDraftId FROM #StocklineDraftForQtyToReceive WHERE ID = @LoopID_QtyToReceive;

							UPDATE StocklineDraft SET StockLineId = @NewStocklineId, StockLineNumber = @StockLineNumber, ForStockQty = @QtyToReceive
							WHERE StockLineDraftId = @CurrentStocklineDraftId;

							SET @TotalQtyToTraverse = @TotalQtyToTraverse - 1;
						END
						SET @LoopID_QtyToReceive = @LoopID_QtyToReceive - 1;
					END



					IF ((@MainPOPartBackOrderQty - @QtyToReceive) > 0)
					BEGIN
						SET @StockLineNumber = NULL;
						SET @NewStocklineId = NULL;
					END

					UPDATE dstl
					SET dstl.StockLineId = @NewStocklineId,
					dstl.StockLineNumber = @StockLineNumber,
					dstl.ControlNumber = @ControlNumber,
					dstl.ReceiverNumber = @ReceiverNumber
					FROM DBO.StocklineDraft dstl
					WHERE StockLineDraftId = @SelectedStockLineDraftId;

					UPDATE DBO.StocklineDraft SET StockLineId = 0 
					WHERE StockLineDraftId = @SelectedStockLineDraftId AND isSerialized = 0 AND IsSameDetailsForAllParts = 1 AND IsParent = 1;
				END
				ELSE
				BEGIN
					UPDATE dstl
					SET dstl.StockLineId = @NewStocklineId,
					dstl.StockLineNumber = @StockLineNumber,
					dstl.ControlNumber = @ControlNumber,
					dstl.ReceiverNumber = @ReceiverNumber
					FROM DBO.StocklineDraft dstl
					WHERE StockLineDraftId = @SelectedStockLineDraftId;
				END

				/* Update ItemMasterPurchaseSale */
				IF EXISTS (SELECT TOP 1 1 FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE POP.PurchaseOrderId = @PurchaseOrderId AND POP.ItemMasterId = @ItemMasterId AND POP.ConditionId = @ConditionId)
				BEGIN
					DECLARE @POP_UnitCost DECIMAL(18, 2) = 0;
					DECLARE @POP_VendorListPrice DECIMAL(18, 2) = 0;
					DECLARE @POP_DiscountPerUnit DECIMAL(18, 2) = 0;
					DECLARE @POP_DiscountPercent BIGINT = 0;
					DECLARE @POP_DiscountPercentValue BIGINT = 0;
					DECLARE @POP_ConditionId BIGINT = 0;

					DECLARE @PP_VendorListPrice DECIMAL(18, 2) = 0;
					DECLARE @PP_PurchaseDiscAmount DECIMAL(18, 2) = 0;
					DECLARE @PP_UnitPurchasePrice DECIMAL(18, 2) = 0;
					DECLARE @PP_PurchaseDiscPerc DECIMAL(18, 2) = 0;

					SELECT @POP_UnitCost = POP.UnitCost, @POP_VendorListPrice = POP.VendorListPrice, @POP_DiscountPerUnit = POP.DiscountPerUnit, @POP_DiscountPercent = POP.DiscountPercent, @POP_DiscountPercentValue = POP.DiscountPercentValue,
					@POP_ConditionId = POP.ConditionId
					FROM dbo.PurchaseOrderPart POP WITH (NOLOCK) WHERE POP.PurchaseOrderId = @PurchaseOrderId AND POP.ItemMasterId = @ItemMasterId AND POP.ConditionId = @ConditionId;

					IF (@StkPurchaseOrderUnitCost = @POP_UnitCost)
					BEGIN
						SET @PP_VendorListPrice = ISNULL(@POP_VendorListPrice, 0);
						SET @PP_PurchaseDiscAmount = ISNULL(@POP_DiscountPerUnit, 0);
						SET @PP_UnitPurchasePrice = (ISNULL(@POP_VendorListPrice, 0) - ISNULL(@POP_DiscountPerUnit, 0));
						SET @PP_PurchaseDiscPerc = @POP_DiscountPercent;
					END
					ELSE
					BEGIN
						DECLARE @disamt AS DECIMAL(18, 2) = 0;
						SET @disamt = ((ISNULL(@StkPurchaseOrderUnitCost, 0) * (ISNULL(@POP_DiscountPercentValue, 0))) / 100);

						SET @PP_VendorListPrice = ISNULL(@StkPurchaseOrderUnitCost, 0) + @disamt;
						SET @PP_PurchaseDiscAmount = ISNULL(@disamt, 0);
						SET @PP_UnitPurchasePrice = ISNULL(@StkPurchaseOrderUnitCost, 0);
						SET @PP_PurchaseDiscPerc = @POP_DiscountPercent;
					END

					IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = @ItemMasterId AND IMPS.ConditionId = @ConditionId)
					BEGIN
						INSERT INTO DBO.ItemMasterPurchaseSale ([ItemMasterId],[PartNumber],[PP_UOMId],[PP_CurrencyId],[PP_FXRatePerc],[PP_VendorListPrice],[PP_LastListPriceDate],[PP_PurchaseDiscPerc],
						[PP_PurchaseDiscAmount],[PP_LastPurchaseDiscDate],[PP_UnitPurchasePrice],[SP_FSP_UOMId],[SP_FSP_CurrencyId],[SP_FSP_FXRatePerc],[SP_FSP_FlatPriceAmount],[SP_FSP_LastFlatPriceDate],
						[SP_CalSPByPP_MarkUpPercOnListPrice],[SP_CalSPByPP_MarkUpAmount],[SP_CalSPByPP_LastMarkUpDate],[SP_CalSPByPP_BaseSalePrice],[SP_CalSPByPP_SaleDiscPerc],[SP_CalSPByPP_SaleDiscAmount],
						[SP_CalSPByPP_LastSalesDiscDate],[SP_CalSPByPP_UnitSalePrice],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
						[ConditionId],[SalePriceSelectId],[ConditionName],[PP_UOMName],[SP_FSP_UOMName],[PP_CurrencyName],[SP_FSP_CurrencyName],[PP_PurchaseDiscPercValue],[SP_CalSPByPP_SaleDiscPercValue],
						[SP_CalSPByPP_MarkUpPercOnListPriceValue],[SalePriceSelectName])
						SELECT @ItemMasterId, POP.PartNumber, CASE WHEN IM.ItemMasterId IS NOT NULL THEN IM.PurchaseUnitOfMeasureId ELSE 0 END, CASE WHEN IM.ItemMasterId IS NOT NULL THEN IM.PurchaseCurrencyId ELSE 0 END, POP.ForeignExchangeRate, @PP_VendorListPrice, GETUTCDATE(), @PP_PurchaseDiscPerc,
						@PP_PurchaseDiscAmount, GETUTCDATE(), @PP_UnitPurchasePrice, NULL, NULL, 0, NULL, NULL,
						NULL, NULL, NULL, NULL, NULL, NULL,
						NULL, NULL, @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
						@POP_ConditionId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
						NULL, NULL
						FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) 
						LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON POP.ItemMasterId = IM.ItemMasterId
						WHERE POP.PurchaseOrderId = @PurchaseOrderId AND POP.ItemMasterId = @ItemMasterId AND POP.ConditionId = @ConditionId;

						EXEC dbo.UpdateItemMasterPurchaseSaleDetails @ItemMasterId;
					END
					ELSE
					BEGIN
						UPDATE IMPS
						SET IMPS.PP_VendorListPrice = @PP_VendorListPrice,
						IMPS.PP_PurchaseDiscAmount = @PP_PurchaseDiscAmount,
						IMPS.PP_UnitPurchasePrice = @PP_UnitPurchasePrice,
						IMPS.PP_PurchaseDiscPerc = @PP_PurchaseDiscPerc,
						IMPS.UpdatedBy = @UpdatedBy,
						IMPS.UpdatedDate = GETUTCDATE()
						FROM DBO.ItemMasterPurchaseSale IMPS
						WHERE IMPS.ItemMasterId = @ItemMasterId AND IMPS.ConditionId = @ConditionId;
					END
				END

				EXEC UpdateStocklineColumnsWithId @NewStocklineId;

				SET @LoopID = @LoopID - 1;
			END

			DECLARE @StocklineDraftToUpdateLoopID INT = 0;
			IF OBJECT_ID(N'tempdb..#StocklineDraftToUpdate') IS NOT NULL
			BEGIN
				DROP TABLE #StocklineDraftToUpdate 
			END
			
			CREATE TABLE #StocklineDraftToUpdate 
			(
				ID BIGINT NOT NULL IDENTITY,
				[StocklineDraftId] [bigint] NULL
			)

			INSERT INTO #StocklineDraftToUpdate ([StocklineDraftId])
			SELECT [StocklineDraftId] FROM DBO.StocklineDraft WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

			SELECT @StocklineDraftToUpdateLoopID = MAX(ID) FROM #StocklineDraftToUpdate;

			WHILE (@StocklineDraftToUpdateLoopID > 0)
			BEGIN
				DECLARE @StocklineDraftSelected BIGINT = 0;
				DECLARE @IsParentSelected BIGINT = 0;
				DECLARE @IsSerializedSelected BIGINT = 0;
				DECLARE @SelectedStocklineId BIGINT = 0;
				DECLARE @CurrentIsSameDetailsForAllParts BIGINT = 0;

				SELECT @StocklineDraftSelected = [StocklineDraftId] FROM #StocklineDraftToUpdate WHERE ID = @StocklineDraftToUpdateLoopID;

				SELECT @IsParentSelected = dstl.IsParent, @IsSerializedSelected = dstl.isSerialized, @SelectedStocklineId = ISNULL(dstl.StockLineId, 0),
				@CurrentIsSameDetailsForAllParts = dstl.IsSameDetailsForAllParts
				FROM DBO.StocklineDraft dstl WHERE dstl.StockLineDraftId = @StocklineDraftSelected;

				IF (@CurrentIsSameDetailsForAllParts = 0 AND @IsParentSelected = 0 AND @IsSerializedSelected = 0 AND @SelectedStocklineId = 0)
				BEGIN
					UPDATE dstl
					SET dstl.IsParent = 1, IsSameDetailsForAllParts = 1
					FROM DBO.StocklineDraft dstl 
					WHERE dstl.StockLineDraftId = @StocklineDraftSelected;
				END
				ELSE IF (@CurrentIsSameDetailsForAllParts = 0 AND @IsParentSelected = 1 AND @IsSerializedSelected = 0 AND @SelectedStocklineId = 0)
				BEGIN
					UPDATE dstl
					SET dstl.IsParent = 0, IsSameDetailsForAllParts = 1
					FROM DBO.StocklineDraft dstl 
					WHERE dstl.StockLineDraftId = @StocklineDraftSelected;
				END

				SET @StocklineDraftToUpdateLoopID = @StocklineDraftToUpdateLoopID - 1;
			END

			SET @MainPartLoopID = @MainPartLoopID - 1;
		END

		EXEC DBO.UpdateStocklineDraftDetail @PurchaseOrderId;
		--EXEC DBO.UpdateNonStockDraftDetail @PurchaseOrderId;
		--EXEC DBO.UpdateAssetInventoryDraftPoDetails @PurchaseOrderId;

		DECLARE @POPartLoopID AS INT;

		IF OBJECT_ID(N'tempdb..#POParts') IS NOT NULL
		BEGIN
			DROP TABLE #POParts 
		END
			
		CREATE TABLE #POParts 
		(
			ID BIGINT NOT NULL IDENTITY,
			[PurchaseOrderId] [bigint] NULL,
			[PurchaseOrderPartRecordId] [bigint] NULL,
			[QuantityOrdered] [int] NULL
		)

		INSERT INTO #POParts ([PurchaseOrderId],[PurchaseOrderPartRecordId],[QuantityOrdered])
		SELECT [PurchaseOrderId],[PurchaseOrderPartRecordId],[QuantityOrdered] FROM DBO.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;

		SELECT @POPartLoopID = MAX(ID) FROM #POParts;
		
		DECLARE @MainQuantityOrdered BIGINT = 0;
		DECLARE @MainStkQuantity BIGINT = 0;

		WHILE (@POPartLoopID > 0)
		BEGIN
			DECLARE @PurchaseOrderPartRecordId BIGINT = 0;
			DECLARE @QuantityOrdered BIGINT = 0;
			DECLARE @StkQuantity BIGINT = 0;

			SELECT @QuantityOrdered = [QuantityOrdered], @PurchaseOrderPartRecordId = [PurchaseOrderPartRecordId] FROM #POParts WHERE ID = @POPartLoopID;
			SELECT @StkQuantity = SUM([Quantity]) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND IsParent = 1;

			SET @MainQuantityOrdered = @MainQuantityOrdered + @QuantityOrdered;
			SET @MainStkQuantity = @MainStkQuantity + @StkQuantity;

			SET @POPartLoopID = @POPartLoopID - 1;
		END

		IF (@MainQuantityOrdered = @MainStkQuantity)
		BEGIN
			UPDATE PO
			SET PO.StatusId = 4, -- Closed
			PO.Status = 'Closed',
			PO.ClosedDate = GETUTCDATE()
			FROM DBO.PurchaseOrder PO 
			WHERE PO.PurchaseOrderId = @PurchaseOrderId
		END
		ELSE
		BEGIN
			UPDATE PO
			SET PO.StatusId = 3, -- Fulfilling
			PO.Status = 'Fulfilling',
			PO.ClosedDate = GETUTCDATE()
			FROM DBO.PurchaseOrder PO 
			WHERE PO.PurchaseOrderId = @PurchaseOrderId
		END
	END  
    COMMIT TRANSACTION  
  
  END TRY  
  BEGIN CATCH  
		PRINT ERROR_MESSAGE();
		IF @@trancount > 0  
		ROLLBACK TRAN;
	  DECLARE @ErrorLogID int  
	  ,@DatabaseName varchar(100) = DB_NAME()  
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------  
	  ,@AdhocComments varchar(150) = 'USP_CreateStocklineForReceivingPO'  
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