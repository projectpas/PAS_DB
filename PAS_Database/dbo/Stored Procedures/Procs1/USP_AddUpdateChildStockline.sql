
/*************************************************************             
 ** File:   [USP_AddUpdateChildStockline]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to add/update child stockline
 ** Purpose:           
 ** Date:   07/12/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    07/12/2023   Vishal Suthar		Created
    2    07/21/2023   Vishal Suthar		Modified to handle adjustment increase-decrease qty
	3    6 Nov 2023   Rajesh Gami       SalesPrice Expriry Date And Stockline History UnitSalesPrice and SalesPriceExpiryDate related change
	4    5 Jan 2024   Hemant Saliya     Added Rec Customer Delete Hinstory
	5    8 Jan 2024   Hemant Saliya     Added Create Sub WO Hinstory
	6    23 jan 2024  Shrey Chandegara  Add ActionId 7 for when create tendorstockline created then can't insert into childstockline.
	7    12/08/2024  Moin Bloch         Convert @StocklineId To varchar for Errolog
	
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateChildStockline]
(
	@StocklineId BIGINT = NULL,
	@ActionId INT = NULL,
	@QtyOnAction INT = NULL,
	@ModuleName VARCHAR(100) NULL,
	@ReferenceNumber VARCHAR(100) NULL,
	@SubModuleName VARCHAR(100) NULL,
	@SubReferenceNumber VARCHAR(100) NULL,
	@UpdatedBy VARCHAR(100) = NULL
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @UnAvailQtyCount INT = 0;
		DECLARE @AvailQtyCount INT = 0;
		DECLARE @RemainingAvailableQty INT = 0;
		DECLARE @RemainingOHQty INT = 0;
		DECLARE @RemainingReservedQty INT = 0;
		DECLARE @RemainingIssuedQty INT = 0;
		DECLARE @IdCodeTypeId BIGINT;
		DECLARE @CurrentIndex BIGINT;
		DECLARE @CurrentIdNumber AS BIGINT;
		DECLARE @IdNumber AS VARCHAR(50);
		DECLARE @StocklineNumber VARCHAR(50);
		DECLARE @NewStocklineId BIGINT;
		DECLARE @LoopID AS int;
		DECLARE @MasterCompanyId BIGINT;
		DECLARE @MasterLoopID INT;
		DECLARE @StocklineToUpdate BIGINT;  
		DECLARE @IdNumberUpdated VARCHAR(50);
		DECLARE @Qty INT;
		DECLARE @PrevReservedQty INT = 0;
		DECLARE @PrevIssuedQty INT = 0;  
		DECLARE @PrevOHQty INT = 0;  
		DECLARE @PrevAvailableQty INT = 0;

		SELECT @UnAvailQtyCount = COUNT(*) FROM DBO.ChildStockline CStk WITH (NOLOCK) WHERE CStk.StockLineId = @StocklineId AND CStk.QuantityOnHand = 0;
		SELECT @AvailQtyCount = COUNT(*) FROM DBO.ChildStockline CStk WITH (NOLOCK) WHERE CStk.StockLineId = @StocklineId AND CStk.QuantityOnHand = 1 AND CStk.QuantityAvailable = 1;

		DECLARE @RemainingQtyToCreate INT = 0;
		SET @RemainingQtyToCreate = @QtyOnAction - @UnAvailQtyCount;

		IF (@ActionId = 1 OR @ActionId = 11 OR @ActionId = 7)
		BEGIN
			SELECT @Qty = Quantity,   
			@RemainingAvailableQty = QuantityAvailable,  
			@RemainingOHQty = QuantityOnHand,  
			@RemainingIssuedQty = QuantityIssued,  
			@RemainingReservedQty = QuantityReserved,  
			@MasterCompanyId = MasterCompanyId,  
			@StocklineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId;

			SET @LoopID = @Qty;  
			SET @CurrentIndex = 0;

			WHILE (@LoopID > 0)
			BEGIN
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
  
				SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
				WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				IF EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)  
				BEGIN
				IF (@CurrentIndex = 0)
				BEGIN
					SELECT @CurrentIdNumber = CAST(StartsFrom AS BIGINT) FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId  
				END
				ELSE
				BEGIN
					SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1
							ELSE CAST(StartsFrom AS BIGINT) + 1 END
					FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
				END
  
				SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash (@CurrentIdNumber,  
					(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),  
					(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))  
				END  
  
				INSERT INTO DBO.ChildStockline ([StockLineId],[PartNumber],[StockLineNumber],[StocklineMatchKey] ,[ControlNumber] ,[ItemMasterId]  
				,[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId]  
				,[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate]  
				,[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate]  
				,[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId]  
				,[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost]  
				,[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId],[LegalEntityId]  
				,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId]  
				,[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId]  
				,[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber]  
				,[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference]  
				,[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],  
				[QuantityReserved], [QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed]  
				,[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive]  
				,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]  
				,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy]  
				,[InspectionDate],[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],
				[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],
				[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]
				,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]  
				,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId]  
				,[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],[RRQty],LotMainStocklineId,IsFromInitialPO,LotSourceId, LotId,IsLotAssigned,
				[ModuleName], [ReferenceName], [SubModuleName], [SubReferenceName],SalesPriceExpiryDate)  
  
				SELECT [StockLineId],[PartNumber], @StocklineNumber  
				,[StocklineMatchKey] ,[ControlNumber] ,[ItemMasterId]  
				,1,[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId]  
				,[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate]  
				,[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate]  
				,[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId]  
				,[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost]  
				,[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId],[LegalEntityId]  
				,[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId]  
				,[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId]  
				,@IdNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber]  
				,[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference]  
				,[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId], 0,[QuantityTurnIn], 0, 1, 1,[QuantityOnOrder], [QtyReserved]  
				,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive]  
				,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]  
				,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy]  
				,[InspectionDate],[VendorId],0,@StocklineId,[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId]  
				,[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName]  
				,[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin]  
				,[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]  
				,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]  
				,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId]  
				,[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],1,NULL,NULL,NULL,NULL,NULL,
				@ModuleName, @ReferenceNumber, @SubModuleName, @SubReferenceNumber,SalesPriceExpiryDate
				FROM DBO.Stockline SL WITH (NOLOCK) WHERE SL.StockLineId = @StocklineId  
  
				SELECT @NewStocklineId = SCOPE_IDENTITY()

				INSERT INTO [dbo].[TimeLife] ([CyclesRemaining], [CyclesSinceNew], [CyclesSinceOVH], [CyclesSinceInspection], [CyclesSinceRepair], [TimeRemaining], [TimeSinceNew], [TimeSinceOVH], [TimeSinceInspection], [TimeSinceRepair],
					[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],
					[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId])
				SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],
					[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],@NewStocklineId,
					[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId] 
				FROM DBO.TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId;
  
				-- Use variable instead of updating in the table  
				UPDATE CodePrefixes SET CurrentNummber = @CurrentIdNumber WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId  
  
				--EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId;
				
				SET @LoopID = @LoopID - 1;
				SET @CurrentIndex = @CurrentIndex + 1;
			END
		END
		ELSE
		BEGIN
			IF (@RemainingQtyToCreate > 0 AND @ActionId = 8)
			BEGIN
				SELECT @Qty = QuantityAvailable,   
				@RemainingAvailableQty = QuantityAvailable,  
				@RemainingOHQty = QuantityOnHand,  
				@RemainingIssuedQty = QuantityIssued,  
				@RemainingReservedQty = QuantityReserved,  
				@MasterCompanyId = MasterCompanyId,  
				@StocklineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId;

				SET @LoopID = @RemainingQtyToCreate;  
				SET @CurrentIndex = 0;

				WHILE (@LoopID > 0)
				BEGIN
					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_adjustment') IS NOT NULL  
					BEGIN  
						DROP TABLE #tmpCodePrefixes_adjustment
					END
      
					CREATE TABLE #tmpCodePrefixes_adjustment
					(
						ID BIGINT NOT NULL IDENTITY,   
						CodePrefixId BIGINT NULL,  
						CodeTypeId BIGINT NULL,  
						CurrentNumber BIGINT NULL,  
						CodePrefix VARCHAR(50) NULL,  
						CodeSufix VARCHAR(50) NULL,  
						StartsFrom BIGINT NULL,  
					)
  
					SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';

					INSERT INTO #tmpCodePrefixes_adjustment (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
					WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					SET @CurrentIdNumber = 0;
					SELECT @CurrentIdNumber = COUNT(*) FROM DBO.ChildStockline WHERE StockLineId = @StocklineId;
					SET @CurrentIdNumber = @CurrentIdNumber + 1;
  
					SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash (@CurrentIdNumber,  
						(SELECT CodePrefix FROM #tmpCodePrefixes_adjustment WHERE CodeTypeId = @IdCodeTypeId),  
						(SELECT CodeSufix FROM #tmpCodePrefixes_adjustment WHERE CodeTypeId = @IdCodeTypeId))) 
  
					INSERT INTO DBO.ChildStockline ([StockLineId],[PartNumber],[StockLineNumber],[StocklineMatchKey] ,[ControlNumber] ,[ItemMasterId]  
					,[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId]  
					,[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate]  
					,[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate]  
					,[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId]  
					,[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost]  
					,[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId],[LegalEntityId]  
					,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId]  
					,[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId]  
					,[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber]  
					,[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference]  
					,[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],  
					[QuantityReserved], [QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed]  
					,[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive]  
					,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]  
					,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy]  
					,[InspectionDate],[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],
					[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],
					[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]
					,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]  
					,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId]  
					,[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],[RRQty],LotMainStocklineId,IsFromInitialPO,LotSourceId, LotId,IsLotAssigned,
					[ModuleName], [ReferenceName], [SubModuleName], [SubReferenceName],SalesPriceExpiryDate)  
  
					SELECT [StockLineId],[PartNumber], @StocklineNumber  
					,[StocklineMatchKey] ,[ControlNumber] ,[ItemMasterId]  
					,1,[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId]  
					,[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate]  
					,[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate]  
					,[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId]  
					,[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost]  
					,[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId],[LegalEntityId]  
					,[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId]  
					,[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId]  
					,@IdNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber]  
					,[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference]  
					,[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId], 0,[QuantityTurnIn], 0, 1, 1,[QuantityOnOrder], [QtyReserved]  
					,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive]  
					,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]  
					,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy]  
					,[InspectionDate],[VendorId],0,@StocklineId,[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId]  
					,[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName]  
					,[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin]  
					,[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]  
					,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]  
					,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId]  
					,[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],1,NULL,NULL,NULL,NULL,NULL,
					@ModuleName, @ReferenceNumber, @SubModuleName, @SubReferenceNumber,SalesPriceExpiryDate
					FROM DBO.Stockline SL WITH (NOLOCK) WHERE SL.StockLineId = @StocklineId  
  
					SELECT @NewStocklineId = SCOPE_IDENTITY()

					INSERT INTO [dbo].[TimeLife] ([CyclesRemaining], [CyclesSinceNew], [CyclesSinceOVH], [CyclesSinceInspection], [CyclesSinceRepair], [TimeRemaining], [TimeSinceNew], [TimeSinceOVH], [TimeSinceInspection], [TimeSinceRepair],
						[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],
						[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId])
					SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],
						[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],@NewStocklineId,
						[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId] 
					FROM DBO.TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId;
  
					-- Use variable instead of updating in the table  
					UPDATE CodePrefixes SET CurrentNummber = @CurrentIdNumber WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId  
  
					SET @LoopID = @LoopID - 1;
					SET @CurrentIndex = @CurrentIndex + 1;
				END
			END

			IF ((@AvailQtyCount >= @QtyOnAction) AND @ActionId = 9)
			BEGIN
				DECLARE @MasterLoop_DeleteID INT;

				IF OBJECT_ID(N'tempdb..#childTableTtmp_Delete') IS NOT NULL  
				BEGIN  
					DROP TABLE #childTableTtmp_Delete
				END  
  
				CREATE TABLE #childTableTtmp_Delete (
					ID bigint NOT NULL IDENTITY,
					ChildStockLineId bigint NULL
				)
  
				INSERT INTO #childTableTtmp_Delete
				SELECT STL.ChildStockLineId FROM DBO.ChildStockline STL WITH (NOLOCK)
				WHERE STL.StockLineId = @StockLineId
				ORDER BY STL.ChildStockLineId;

				SELECT @MasterLoop_DeleteID = MAX(ID) FROM #childTableTtmp_Delete;  
			
				DECLARE @RemainingQtyToDelete INT = 0;
				SET @RemainingQtyToDelete = @QtyOnAction;

				WHILE (@MasterLoop_DeleteID > 0)
				BEGIN
					DECLARE @StocklineToDelete BIGINT = 0;

					SELECT @StocklineToDelete = ChildStockLineId FROM #childTableTtmp_Delete WHERE ID = @MasterLoop_DeleteID;

					IF (@StocklineToDelete > 0 AND @RemainingQtyToDelete > 0)
					BEGIN
						DELETE FROM DBO.ChildStockline WHERE ChildStockLineId = @StocklineToDelete;

						SET @RemainingQtyToDelete = @RemainingQtyToDelete - 1;
						SET @QtyOnAction = @QtyOnAction - 1;
					END

					SET @MasterLoop_DeleteID = @MasterLoop_DeleteID - 1;
				END
			END

			DECLARE @MasterLoop_UpdateID INT;
  
			IF OBJECT_ID(N'tempdb..#childTableTtmp') IS NOT NULL  
			BEGIN  
				DROP TABLE #childTableTtmp  
			END  
  
			CREATE TABLE #childTableTtmp (  
				ID bigint NOT NULL IDENTITY,  
				ChildStockLineId bigint NULL  
			)
  
			INSERT INTO #childTableTtmp 
			SELECT STL.ChildStockLineId FROM DBO.ChildStockline STL WITH (NOLOCK)
			WHERE STL.StockLineId = @StockLineId  
			ORDER BY STL.ChildStockLineId DESC  
  
			DECLARE @RemainingQty INT = 0;
			SET @RemainingQty = @QtyOnAction;

			SELECT @MasterLoop_UpdateID = MAX(ID) FROM #childTableTtmp;  
			
			WHILE (@MasterLoop_UpdateID > 0)
			BEGIN
				SELECT @StocklineToUpdate = ChildStockLineId FROM #childTableTtmp WHERE ID = @MasterLoop_UpdateID;
				
				IF (@QtyOnAction > 0)
				BEGIN
					SELECT @PrevReservedQty = QuantityReserved, @PrevIssuedQty = QuantityIssued, @PrevOHQty = QuantityOnHand, @PrevAvailableQty = QuantityAvailable 
					FROM DBO.ChildStockline WITH (NOLOCK) WHERE ChildStockLineId = @StocklineToUpdate;

					IF (@ActionId = 2) -- Reserve
					BEGIN
						IF (@PrevReservedQty = 0 AND @PrevAvailableQty > 0 AND @PrevIssuedQty = 0 AND @PrevOHQty > 0)
						BEGIN
							PRINT @StocklineToUpdate;
							Update DBO.ChildStockline SET QuantityReserved = 1, QuantityAvailable = 0, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 3) -- UnReserve
					BEGIN
						IF (@PrevReservedQty > 0 AND @PrevAvailableQty = 0 AND @PrevIssuedQty = 0 AND @PrevOHQty > 0)
						BEGIN
							Update DBO.ChildStockline SET QuantityReserved = 0, QuantityAvailable = 1, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 4) -- Issue
					BEGIN
						IF (@PrevIssuedQty = 0 AND @PrevReservedQty > 0 AND @PrevOHQty > 0 AND @PrevAvailableQty = 0)
						BEGIN
							Update DBO.ChildStockline SET QuantityReserved = 0, QuantityAvailable = 0, QuantityIssued = 1, QuantityOnHand = 0, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 5) -- UnIssue
					BEGIN
						IF (@PrevIssuedQty > 0 AND @PrevReservedQty = 0 AND @PrevOHQty = 0 AND @PrevAvailableQty = 0)
						BEGIN
							Update DBO.ChildStockline SET QuantityReserved = 1, QuantityAvailable = 0, QuantityIssued = 0, QuantityOnHand = 1, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 8) -- Adjustment-Increase
					BEGIN
						IF (@PrevOHQty = 0 AND @PrevAvailableQty = 0)
						BEGIN
							Update DBO.ChildStockline SET QuantityAvailable = 1, QuantityOnHand = 1, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 9) -- Adjustment-Decrease
					BEGIN
						IF (@PrevOHQty > 0 AND @PrevAvailableQty > 0)
						BEGIN
							Update DBO.ChildStockline SET QuantityAvailable = 0, QuantityOnHand = 0, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 14) -- Delete Receving Customer
					BEGIN
						IF (@PrevOHQty > 0 AND @PrevAvailableQty > 0)
						BEGIN
							Update DBO.ChildStockline SET QuantityAvailable = 0, QuantityOnHand = 0, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
					ELSE IF (@ActionId = 15) -- CREATE SUB WO
					BEGIN
						IF (@PrevReservedQty = 0 AND @PrevAvailableQty > 0 AND @PrevIssuedQty = 0 AND @PrevOHQty > 0)
						BEGIN
							PRINT @StocklineToUpdate;
							Update DBO.ChildStockline SET QuantityReserved = 1, QuantityAvailable = 0, ModuleName = @ModuleName, ReferenceName = @ReferenceNumber, SubModuleName = @SubModuleName, SubReferenceName = @SubReferenceNumber, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
							WHERE ChildStockLineId = @StocklineToUpdate;

							SET @QtyOnAction = @QtyOnAction - 1;
						END
					END
				END

				SET @MasterLoop_UpdateID = @MasterLoop_UpdateID - 1;
			END
		END
	END
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
  ROLLBACK TRAN;
  DECLARE @ErrorLogID int
  ,@DatabaseName varchar(100) = DB_NAME()
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
  ,@AdhocComments varchar(150) = 'USP_AddUpdateChildStockline' 
  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))  
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