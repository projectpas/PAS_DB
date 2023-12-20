/*************************************************************           
 ** File:   [sp_UpdateStocklineDraftForPurchaseOrder]           
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to modify stockline draft entries based on modified qty ordered
 ** Purpose:         
 ** Date:   10/12/2023

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/12/2023   Vishal Suthar		Created
     
 -- EXEC [dbo].[sp_UpdateStocklineDraftForPurchaseOrder] 1950
**************************************************************/
CREATE   Procedure [dbo].[sp_UpdateStocklineDraftForPurchaseOrder]
	@PurchaseOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
		DECLARE @LoopID AS INT;

		IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderPart') IS NOT NULL
		BEGIN
			DROP TABLE #tmpPurchaseOrderPart
		END
			
		CREATE TABLE #tmpPurchaseOrderPart
		(
			ID BIGINT NOT NULL IDENTITY,
			[PurchaseOrderId] [bigint] NULL,
			[PurchaseOrderPartId] [bigint] NULL,
			[QuantityOrdered] [INT] NULL
		)

		INSERT INTO #tmpPurchaseOrderPart ([PurchaseOrderId],[PurchaseOrderPartId],[QuantityOrdered])
		SELECT [PurchaseOrderId],[PurchaseOrderPartRecordId],[QuantityOrdered] FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
		WHERE POP.PurchaseOrderId = @PurchaseOrderId;

		SELECT @LoopID = MAX(ID) FROM #tmpPurchaseOrderPart;
		
		WHILE (@LoopID > 0)
		BEGIN
			DECLARE @POPartOrderQty INT = 0;
			DECLARE @PODraftedQty INT = 0;
			DECLARE @SelectedPurchaseOrderPartId BIGINT = 0;

			SELECT @SelectedPurchaseOrderPartId = [PurchaseOrderPartId], @POPartOrderQty = [QuantityOrdered] FROM #tmpPurchaseOrderPart WHERE ID = @LoopID;

			SELECT @PODraftedQty = SUM(CASE WHEN isSerialized = 1 AND IsParent = 1 THEN 1 
					WHEN isSerialized = 0 AND IsParent = 0 THEN 1 
					ELSE 0 END) 
			FROM DBO.StocklineDraft WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartId;

			IF (@POPartOrderQty > @PODraftedQty) -- Need to Increase Stockline Draft entries
			BEGIN
				DECLARE @QtyToCreate INT = 0;

				SET @QtyToCreate = @POPartOrderQty - @PODraftedQty;

				WHILE (@QtyToCreate > 0)
				BEGIN
					INSERT INTO DBO.StocklineDraft (
					[PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
					[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
					[CertifiedBy],[CertifiedDate],[TagDate],[TagTypeIds],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],
					[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],
					[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],
					[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],
					[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],
					[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],
					[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],
					[WorkOrderExtendedCost],[RepairOrderExtendedCost],[NHAItemMasterId],[TLAItemMasterId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[Level1],[Level2],[Level3],[Level4],[Condition],
					[Warehouse],[Location],[ObtainFromName],[OwnerName],[TraceableToName],[GLAccount],[AssetName],[LegalEntityName],[ShelfName],[BinName],[SiteName],[ObtainFromTypeName],[OwnerTypeName],
					[TraceableToTypeName],[UnitCostAdjustmentReasonType],[UnitSalePriceAdjustmentReasonType],[ShippingVia],[WorkOrder],[WorkOrderMaterialsName],[TagTypeId],[StockLineDraftNumber],
					[StockLineId],[TaggedBy],[TaggedByName],[UnitOfMeasureId],[UnitOfMeasure],[RevisedPartId],[RevisedPartNumber],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],
					[CertifiedType],[CertTypeId],[CertType],[IsCustomerStock],[isCustomerstockType],[CustomerId],[CalibrationVendorId],[PerformedById],[LastCalibrationDate],[NextCalibrationDate],
					[LotId],[SalesOrderId],[SubWorkOrderId],[ExchangeSalesOrderId],[WOQty],[SOQty],[ForStockQty],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],
					[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment])
					SELECT TOP 1 [PartNumber],NULL,[StocklineMatchKey],NULL,[ItemMasterId],[Quantity],[ConditionId],'',[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
					[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
					[CertifiedBy],[CertifiedDate],[TagDate],[TagTypeIds],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],
					[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],
					[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],
					[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],NULL,[QuantityToReceive],[PurchaseOrderExtendedCost],
					[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],
					[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],
					[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],
					[WorkOrderExtendedCost],[RepairOrderExtendedCost],[NHAItemMasterId],[TLAItemMasterId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[Level1],[Level2],[Level3],[Level4],[Condition],
					[Warehouse],[Location],[ObtainFromName],[OwnerName],[TraceableToName],[GLAccount],[AssetName],[LegalEntityName],[ShelfName],[BinName],[SiteName],[ObtainFromTypeName],[OwnerTypeName],
					[TraceableToTypeName],[UnitCostAdjustmentReasonType],[UnitSalePriceAdjustmentReasonType],[ShippingVia],[WorkOrder],[WorkOrderMaterialsName],[TagTypeId],[StockLineDraftNumber],
					NULL,[TaggedBy],[TaggedByName],[UnitOfMeasureId],[UnitOfMeasure],[RevisedPartId],[RevisedPartNumber],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],
					[CertifiedType],[CertTypeId],[CertType],[IsCustomerStock],[isCustomerstockType],[CustomerId],[CalibrationVendorId],[PerformedById],[LastCalibrationDate],[NextCalibrationDate],
					[LotId],[SalesOrderId],[SubWorkOrderId],[ExchangeSalesOrderId],NULL,NULL,NULL,[IsLotAssigned],NULL,NULL,[OriginalCost],[POOriginalCost],[ROOriginalCost],
					[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment]
					FROM DBO.StocklineDraft WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartId
					ORDER BY StockLineDraftId DESC;

					SET @QtyToCreate = @QtyToCreate - 1;
				END
			END

			IF (@POPartOrderQty < @PODraftedQty) -- Need to Remove Stockline Draft entries
			BEGIN
				DECLARE @QtyToRemove INT = 0;

				SET @QtyToRemove = @PODraftedQty - @POPartOrderQty;

				DELETE FROM DD
				FROM (
					SELECT *, ROW = ROW_NUMBER() OVER (ORDER BY StockLineDraftId DESC)
					FROM DBO.StocklineDraft WITH (NOLOCK)
				) DD
				WHERE ROW <= @QtyToRemove;
			END

			UPDATE StkD
			SET StkD.Quantity = @POPartOrderQty
			FROM DBO.StocklineDraft StkD
			WHERE StkD.PurchaseOrderId = @PurchaseOrderId AND StkD.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartId
			AND ((StkD.isSerialized = 1 AND StkD.IsParent = 0) OR (StkD.isSerialized = 0 AND StkD.IsParent = 1))
		
			SET @LoopID = @LoopID - 1;
		END

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'sp_UpdateStocklineDraftForPurchaseOrder' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
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