/*************************************************************           
 ** File:   [USP_CreateChildStockline]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Crate child stocklines for Non-serialized stockline
 ** Purpose:         
 ** Date:   08/25/2021        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author    Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/14/2021   Vishal Suthar		Created
    2    12/30/2021  HEMANT SALIYA		Added Sub Module Id and Sub Reference Id for WO Materials 

EXEC [dbo].[USP_CreateChildStockline]  883, 5, 15, 166, 1, 1, 0, 0
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateChildStockline] 
(
	@StocklineId BIGINT = NULL,
	@MasterCompanyId BIGINT,
	@ModuleId INT,
	@ReferenceId INT,
	@IsAddUpdate BIT,
	@ExecuteParentChild BIT = 0,
	@UpdateQuantities BIT = 0,
	@IsOHUpdated BIT = 0,
	@AddHistoryForNonSerialized BIT = 0,
	@SubModuleId INT = NULL,
	@SubReferenceId BIGINT = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
        DECLARE @Qty BIGINT;
		DECLARE @LoopID AS int;
		DECLARE @CurrentIdNumber AS BIGINT;
		DECLARE @IdNumber AS VARCHAR(50);
		DECLARE @IdCodeTypeId BIGINT;
		DECLARE @StocklineNumber VARCHAR(50);
		DECLARE @CurrentIndex BIGINT;
		DECLARE @NewStocklineId BIGINT;
		DECLARE @RemainingAvailableQty INT = 0;
		DECLARE @RemainingOHQty INT = 0;
		DECLARE @RemainingReservedQty INT = 0;
		DECLARE @RemainingIssuedQty INT = 0;
		
		SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';
		
		DECLARE @StkLineNumber VARCHAR(100);
		SELECT @StkLineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId

		IF(@SubReferenceId = 0)
		BEGIN
			 SET @SubReferenceId = NULL;
		END

		IF(@SubModuleId = 0)
		BEGIN
			 SET @SubModuleId = NULL;
		END

		IF (@AddHistoryForNonSerialized = 1)
		BEGIN
			DECLARE @IsNewStkCreated BIT = 0;

			IF NOT EXISTS (SELECT TOP 1 [StocklineId] FROM [dbo].[StocklineHistory] WHERE StockLineId = @StocklineId)
			BEGIN
				INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
				SELECT @ModuleId, @ReferenceId, @StockLineId, 1, 1, 0, 0, 'New Stockline ('+ CAST(@StkLineNumber AS VARCHAR) +') Created.', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId 
				FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId

				SET @IsNewStkCreated = 1;
			END
			
			IF EXISTS (SELECT TOP 1 [StocklineId] FROM [dbo].[StocklineHistory] WHERE StockLineId = @StocklineId)
			BEGIN
				DECLARE @AvailableQty INT;
				DECLARE @ReservedQty INT;
				DECLARE @OnHandQty INT;
				DECLARE @IdNum VARCHAR(50);

				SELECT @AvailableQty = QuantityAvailable,
					@ReservedQty = QuantityReserved,
					@OnHandQty = QuantityOnHand,
					@IdNum = IdNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId

				IF (@ReservedQty > 0 AND @IsNewStkCreated = 0)
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					SELECT @ModuleId, @ReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'Stockline ('+ @IdNum +') Reserved', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId 
					FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
				END

				IF (@AvailableQty > 0 AND @IsNewStkCreated = 0)
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					SELECT @ModuleId, @ReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'Stockline ('+ @IdNum +') UnReserved', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId 
					FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
				END

				IF (@OnHandQty <= 0 AND @IsNewStkCreated = 0)
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					SELECT @ModuleId, @ReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'Stockline ('+ @IdNum +') Removed from OH', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId 
					FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
				END
			END
		END
		ELSE IF (@UpdateQuantities = 0)
		BEGIN
			IF (@ExecuteParentChild = 1)
			BEGIN
				IF (@IsAddUpdate = 0)
				BEGIN
					UPDATE STLN
					SET [PartNumber] = STL.PartNumber
						,[StockLineNumber] = STL.[StockLineNumber]
						,[StocklineMatchKey] = STL.[StocklineMatchKey]
						,[ControlNumber] = STL.[ControlNumber]
						,[ItemMasterId] = STL.[ItemMasterId]
						,[Quantity] = STL.[Quantity]
						,[ConditionId] = STL.[ConditionId]
						,[SerialNumber] = STL.[SerialNumber]
						,[ShelfLife] = STL.[ShelfLife]
						,[ShelfLifeExpirationDate] = STL.[ShelfLifeExpirationDate]
						,[WarehouseId] = STL.[WarehouseId]
						,[LocationId] = STL.[LocationId]
						,[ObtainFrom] = STL.[ObtainFrom]
						,[Owner] = STL.[Owner]
						,[TraceableTo] = STL.[TraceableTo]
						,[ManufacturerId] = STL.[ManufacturerId]
						,[Manufacturer] = STL.[Manufacturer]
						,[ManufacturerLotNumber] = STL.[ManufacturerLotNumber]
						,[ManufacturingDate] = STL.[ManufacturingDate]
						,[ManufacturingBatchNumber] = STL.[ManufacturingBatchNumber]
						,[PartCertificationNumber] = STL.[PartCertificationNumber]
						,[CertifiedBy] = STL.[CertifiedBy]
						,[CertifiedDate] = STL.[CertifiedDate]
						,[TagDate] = STL.[TagDate]
						,[TagType] = STL.[TagType]
						,[CertifiedDueDate] = STL.[CertifiedDueDate]
						,[CalibrationMemo] = STL.[CalibrationMemo]
						,[OrderDate] = STL.[OrderDate]
						,[PurchaseOrderId] = STL.[PurchaseOrderId]
						,[PurchaseOrderUnitCost] = STL.[PurchaseOrderUnitCost]
						,[InventoryUnitCost] = STL.[InventoryUnitCost]
						,[RepairOrderId] = STL.[RepairOrderId]
						,[RepairOrderUnitCost] = STL.[RepairOrderUnitCost]
						,[ReceivedDate] = STL.[ReceivedDate]
						,[ReceiverNumber] = STL.[ReceiverNumber]
						,[ReconciliationNumber] = STL.[ReconciliationNumber]
						,[UnitSalesPrice] = STL.[UnitSalesPrice]
						,[CoreUnitCost] = STL.[CoreUnitCost]
						,[GLAccountId] = STL.[GLAccountId]
						,[AssetId] = STL.[AssetId]
						,[IsHazardousMaterial] = STL.[IsHazardousMaterial]
						,[IsPMA] = STL.[IsPMA]
						,[IsDER] = STL.[IsDER]
						,[OEM] = STL.[OEM]
						,[Memo] = STL.[Memo]
						,[ManagementStructureId] = STL.[ManagementStructureId]
						,[LegalEntityId] = STL.[LegalEntityId]
						,[MasterCompanyId] = STL.[MasterCompanyId]
						,[CreatedBy] = STL.[CreatedBy]
						,[UpdatedBy] = STL.[UpdatedBy]
						,[CreatedDate] = STL.[CreatedDate]
						,[UpdatedDate] = STL.[UpdatedDate]
						,[isSerialized] = STL.[isSerialized]
						,[ShelfId] = STL.[ShelfId]
						,[BinId] = STL.[BinId]
						,[SiteId] = STL.[SiteId]
						,[ObtainFromType] = STL.[ObtainFromType]
						,[OwnerType] = STL.[OwnerType]
						,[TraceableToType] = STL.[TraceableToType]
						,[UnitCostAdjustmentReasonTypeId] = STL.[UnitCostAdjustmentReasonTypeId]
						,[UnitSalePriceAdjustmentReasonTypeId] = STL.[UnitSalePriceAdjustmentReasonTypeId]
						--,[IdNumber] = STL.[IdNumber]
						,[QuantityToReceive] = STL.[QuantityToReceive]
						,[PurchaseOrderExtendedCost] = STL.[PurchaseOrderExtendedCost]
						,[ManufacturingTrace] = STL.[ManufacturingTrace]
						,[ExpirationDate] = STL.[ExpirationDate]
						,[AircraftTailNumber] = STL.[AircraftTailNumber]
						,[ShippingViaId] = STL.[ShippingViaId]
						,[EngineSerialNumber] = STL.[EngineSerialNumber]
						,[QuantityRejected] = STL.[QuantityRejected]
						,[PurchaseOrderPartRecordId] = STL.[PurchaseOrderPartRecordId]
						,[ShippingAccount] = STL.[ShippingAccount]
						,[ShippingReference] = STL.[ShippingReference]
						,[TimeLifeCyclesId] = STL.[TimeLifeCyclesId]
						,[TimeLifeDetailsNotProvided] = STL.[TimeLifeDetailsNotProvided]
						,[WorkOrderId] = STL.[WorkOrderId]
						,[WorkOrderMaterialsId] = STL.[WorkOrderMaterialsId]
						--,[QuantityReserved] = STL.[QuantityReserved]
						,[QuantityTurnIn] = STL.[QuantityTurnIn]
						--,[QuantityIssued] = STL.[QuantityIssued]
						--,[QuantityOnHand] = STL.[QuantityOnHand]
						--,[QuantityAvailable] = STL.[QuantityAvailable]
						--,[QuantityOnOrder] = STL.[QuantityOnOrder]
						--,[QtyReserved] = STL.[QtyReserved]
						--,[QtyIssued] = STL.[QtyIssued]
						,[BlackListed] = STL.[BlackListed]
						,[BlackListedReason] = STL.[BlackListedReason]
						,[Incident] = STL.[Incident]
						,[IncidentReason] = STL.[IncidentReason]
						,[Accident] = STL.[Accident]
						,[AccidentReason] = STL.[AccidentReason]
						,[RepairOrderPartRecordId] = STL.[RepairOrderPartRecordId]
						,[isActive] = STL.[isActive]
						,[isDeleted] = STL.[isDeleted]
						,[WorkOrderExtendedCost] = STL.[WorkOrderExtendedCost]
						,[RepairOrderExtendedCost] = STL.[RepairOrderExtendedCost]
						,[IsCustomerStock] = STL.[IsCustomerStock]
						,[EntryDate] = STL.[EntryDate]
						,[LotCost] = STL.[LotCost]
						,[NHAItemMasterId] = STL.[NHAItemMasterId]
						,[TLAItemMasterId] = STL.[TLAItemMasterId]
						,[ItemTypeId] = STL.[ItemTypeId]
						,[AcquistionTypeId] = STL.[AcquistionTypeId]
						,[RequestorId] = STL.[RequestorId]
						,[LotNumber] = STL.[LotNumber]
						,[LotDescription] = STL.[LotDescription]
						,[TagNumber] = STL.[TagNumber]
						,[InspectionBy] = STL.[InspectionBy]
						,[InspectionDate] = STL.[InspectionDate]
						,[VendorId] = STL.[VendorId]
						--,[IsParent] = STL.[IsParent]
						--,[ParentId] = STL.[ParentId]
						,[IsSameDetailsForAllParts] = STL.[IsSameDetailsForAllParts]
						,[WorkOrderPartNoId] = STL.[WorkOrderPartNoId]
						,[SubWorkOrderId] = STL.[SubWorkOrderId]
						,[SubWOPartNoId] = STL.[SubWOPartNoId]
						,[IsOemPNId] = STL.[IsOemPNId]
						,[PurchaseUnitOfMeasureId] = STL.[PurchaseUnitOfMeasureId]
						,[ObtainFromName] = STL.[ObtainFromName]
						,[OwnerName] = STL.[OwnerName]
						,[TraceableToName] = STL.[TraceableToName]
						,[Level1] = STL.[Level1]
						,[Level2] = STL.[Level2]
						,[Level3] = STL.[Level3]
						,[Level4] = STL.[Level4]
						,[Condition] = STL.[Condition]
						,[GlAccountName] = STL.[GlAccountName]
						,[Site] = STL.[Site]
						,[Warehouse] = STL.[Warehouse]
						,[Location] = STL.[Location]
						,[Shelf] = STL.[Shelf]
						,[Bin] = STL.[Bin]
						,[UnitOfMeasure] = STL.[UnitOfMeasure]
						,[WorkOrderNumber] = STL.[WorkOrderNumber]
						,[itemGroup] = STL.[itemGroup]
						,[TLAPartNumber] = STL.[TLAPartNumber]
						,[NHAPartNumber] = STL.[NHAPartNumber]
						,[TLAPartDescription] = STL.[TLAPartDescription]
						,[NHAPartDescription] = STL.[NHAPartDescription]
						,[itemType] = STL.[itemType]
						,[CustomerId] = STL.[CustomerId]
						,[CustomerName] = STL.[CustomerName]
						,[isCustomerstockType] = STL.[isCustomerstockType]
						,[PNDescription] = STL.[PNDescription]
						,[RevicedPNId] = STL.[RevicedPNId]
						,[RevicedPNNumber] = STL.[RevicedPNNumber]
						,[OEMPNNumber] = STL.[OEMPNNumber]
						,[TaggedBy] = STL.[TaggedBy]
						,[TaggedByName] = STL.[TaggedByName]
						,[UnitCost] = STL.[UnitCost]
						,[TaggedByType] = STL.[TaggedByType]
						,[TaggedByTypeName] = STL.[TaggedByTypeName]
						,[CertifiedById] = STL.[CertifiedById]
						,[CertifiedTypeId] = STL.[CertifiedTypeId]
						,[CertifiedType] = STL.[CertifiedType]
						,[CertTypeId] = STL.[CertTypeId]
						,[CertType] = STL.[CertType]
						,[TagTypeId] = STL.[TagTypeId]
						,[IsFinishGood] = STL.[IsFinishGood]
					FROM DBO.Stockline STL
					LEFT JOIN DBO.Stockline STLN WITH (NOLOCK) ON STL.StockLineId = STLN.ParentId
					WHERE STL.StockLineId = @StockLineId

					UPDATE TFLN
							SET [CyclesRemaining] = TFL.[CyclesRemaining]
							,[CyclesSinceNew] = TFL.[CyclesSinceNew]
							,[CyclesSinceOVH] = TFL.[CyclesSinceOVH]
							,[CyclesSinceInspection] = TFL.[CyclesSinceInspection]
							,[CyclesSinceRepair] = TFL.[CyclesSinceRepair]
							,[TimeRemaining] = TFL.[TimeRemaining]
							,[TimeSinceNew] = TFL.[TimeSinceNew]
							,[TimeSinceOVH] = TFL.[TimeSinceOVH]
							,[TimeSinceInspection] = TFL.[TimeSinceInspection]
							,[TimeSinceRepair] = TFL.[TimeSinceRepair]
							,[LastSinceNew] = TFL.[LastSinceNew]
							,[LastSinceOVH] = TFL.[LastSinceOVH]
							,[LastSinceInspection] = TFL.[LastSinceInspection]
							,[MasterCompanyId] = TFL.[MasterCompanyId]
							,[CreatedBy] = TFL.[CreatedBy]
							,[UpdatedBy] = TFL.[UpdatedBy]
							,[CreatedDate] = TFL.[CreatedDate]
							,[UpdatedDate] = TFL.[UpdatedDate]
							,[IsActive] = TFL.[IsActive]
							,[PurchaseOrderId] = TFL.[PurchaseOrderId]
							,[PurchaseOrderPartRecordId] = TFL.[PurchaseOrderPartRecordId]
							,[DetailsNotProvided] = TFL.[DetailsNotProvided]
							,[RepairOrderId] = TFL.[RepairOrderId]
							,[RepairOrderPartRecordId] = TFL.[RepairOrderPartRecordId]
							FROM DBO.TimeLife TFL
							LEFT JOIN DBO.Stockline STLN WITH (NOLOCK) ON TFL.StockLineId = STLN.ParentId
							LEFT JOIN DBO.TimeLife TFLN WITH (NOLOCK) ON TFLN.StockLineId = STLN.StockLineId
							WHERE TFL.StockLineId = @StockLineId

					DECLARE @tmp table (Id INT IDENTITY(1,1) PRIMARY KEY NOT NULL, StockLineId INT NOT NULL)
					DECLARE @nStockLineId INT 
					DECLARE @Id INT = 0

					INSERT INTO @tmp SELECT STL.StockLineId FROM DBO.Stockline STL
					LEFT JOIN DBO.Stockline STLN WITH (NOLOCK) ON STL.StockLineId = STLN.ParentId
					WHERE STL.ParentId = @StockLineId

					WHILE (1=1)
					BEGIN
						SELECT @nStockLineId = StockLineId, @Id = Id
						FROM @tmp
						WHERE Id = @Id + 1

						IF @@rowcount = 0 BREAK;

						EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @nStockLineId
					END
				END
				ELSE
				BEGIN
					SELECT @Qty = QuantityAvailable, 
					@RemainingAvailableQty = QuantityAvailable,
					@RemainingOHQty = QuantityOnHand,
					@RemainingIssuedQty = QuantityIssued,
					@RemainingReservedQty = QuantityReserved,
					@StocklineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId

					SET @LoopID = @Qty;
					SET @CurrentIndex = 0;

					WHILE (@LoopID > 0)
					BEGIN
						IF (@IsAddUpdate = 1)
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

							INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
							SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
							FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
							WHERE CT.CodeTypeId = @IdCodeTypeId
							AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

							IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
							BEGIN
								IF (@CurrentIndex = 0)
								BEGIN
									SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) 
												ELSE CAST(StartsFrom AS BIGINT) END 
									FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
								END
								ELSE
								BEGIN
									SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
											ELSE CAST(StartsFrom AS BIGINT) + 1 END 
									FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
								END

								SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(
												@CurrentIdNumber,
												(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
												(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
							END

							INSERT INTO DBO.Stockline ([PartNumber],[StockLineNumber],[StocklineMatchKey] ,[ControlNumber] ,[ItemMasterId]
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
							[QuantityReserved],
							[QuantityTurnIn],
							[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed]
							,[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive]
							,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]
							,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy]
							,[InspectionDate],[VendorId],
							[IsParent],
							[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId]
							,[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName]
							,[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin]
							,[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]
							,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]
							,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId]
							,[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood])

							SELECT [PartNumber],
							@StocklineNumber
							,[StocklineMatchKey] ,[ControlNumber] ,[ItemMasterId]
							,1,[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId]
							,[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate]
							,[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate]
							,[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId]
							,[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost]
							,[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureId],[LegalEntityId]
							,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId]
							,[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId]
							,@IdNumber
							,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber]
							,[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference]
							,[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId], 0
							,[QuantityTurnIn], 0, 1, 1,[QuantityOnOrder], [QtyReserved]
							,[QtyIssued],[BlackListed]
							,[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive]
							,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]
							,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy]
							,[InspectionDate],[VendorId],
							0
							,@StocklineId,[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId]
							,[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName]
							,[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin]
							,[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription]
							,[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]
							,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId]
							,[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood] FROM DBO.Stockline SL WITH (NOLOCK)
							WHERE SL.StockLineId = @StocklineId

							SELECT @NewStocklineId = SCOPE_IDENTITY()

							INSERT INTO [dbo].[TimeLife]
								([CyclesRemaining]
								,[CyclesSinceNew]
								,[CyclesSinceOVH]
								,[CyclesSinceInspection]
								,[CyclesSinceRepair]
								,[TimeRemaining]
								,[TimeSinceNew]
								,[TimeSinceOVH]
								,[TimeSinceInspection]
								,[TimeSinceRepair]
								,[LastSinceNew]
								,[LastSinceOVH]
								,[LastSinceInspection]
								,[MasterCompanyId]
								,[CreatedBy]
								,[UpdatedBy]
								,[CreatedDate]
								,[UpdatedDate]
								,[IsActive]
								,[PurchaseOrderId]
								,[PurchaseOrderPartRecordId]
								,[StockLineId]
								,[DetailsNotProvided]
								,[RepairOrderId]
								,[RepairOrderPartRecordId])
							SELECT [CyclesRemaining]
								,[CyclesSinceNew]
								,[CyclesSinceOVH]
								,[CyclesSinceInspection]
								,[CyclesSinceRepair]
								,[TimeRemaining]
								,[TimeSinceNew]
								,[TimeSinceOVH]
								,[TimeSinceInspection]
								,[TimeSinceRepair]
								,[LastSinceNew]
								,[LastSinceOVH]
								,[LastSinceInspection]
								,[MasterCompanyId]
								,[CreatedBy]
								,[UpdatedBy]
								,[CreatedDate]
								,[UpdatedDate]
								,[IsActive]
								,[PurchaseOrderId]
								,[PurchaseOrderPartRecordId]
								,@NewStocklineId
								,[DetailsNotProvided]
								,[RepairOrderId]
								,[RepairOrderPartRecordId] FROM TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId

							-- Use variable instead of updating in the table
							UPDATE CodePrefixes SET CurrentNummber = @CurrentIdNumber WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId

							EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId
						END

						SET @LoopID = @LoopID - 1;
						SET @CurrentIndex = @CurrentIndex + 1;

						IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
						BEGIN
							DROP TABLE #tmpCodePrefixes 
						END
					END

					UPDATE CodePrefixes SET CurrentNummber = 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId
				END
			END

			-- Add Stockline History
			IF (@IsAddUpdate = 1) --Stockline Create
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [SubModuleId], [SubReferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					VALUES (@ModuleId, @ReferenceId, @SubModuleId, @SubReferenceId, @StockLineId, @Qty, @Qty, 0, 0, 'New Stockline ('+ CAST(@StkLineNumber AS VARCHAR) +') Created.', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId)
			END
			ELSE IF @IsAddUpdate = 0
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [SubModuleId], [SubReferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					SELECT @ModuleId, @ReferenceId, @SubModuleId, @SubReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'Stockline ('+ STL.StockLineNumber +') has been updated.', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
				END
			ELSE
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [SubModuleId], [SubReferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					SELECT @ModuleId, @ReferenceId, @SubModuleId, @SubReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'New Stockline ('+ STL.StockLineNumber +') Created.', 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
				END
		END
		ELSE
			BEGIN
				/* START: Update Qty into Child rows */
				DECLARE @ActionMsg VARCHAR(50) = '';
				DECLARE @MasterLoopID INT;
				DECLARE @StocklineToUpdate INT;
				DECLARE @IdNumberUpdated VARCHAR(50);
				DECLARE @AllIdNumbers VARCHAR(500) = '';

				DECLARE @PrevReservedQty INT = 0;
				DECLARE @PrevIssuedQty INT = 0;
				DECLARE @PrevOHQty INT = 0;
				DECLARE @PrevAvailableQty INT = 0;

				IF (@IsOHUpdated = 0)
				BEGIN
					SELECT @RemainingAvailableQty = QuantityAvailable,
					@RemainingOHQty = QuantityOnHand,
					@RemainingIssuedQty = QuantityIssued,
					@RemainingReservedQty = QuantityReserved,
					@StocklineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId

					IF OBJECT_ID(N'tempdb..#childTableTtmp') IS NOT NULL
					BEGIN
						DROP TABLE #childTableTtmp
					END

					CREATE TABLE #childTableTtmp (
						ID bigint NOT NULL IDENTITY,
						StockLineId bigint NULL
					)

					INSERT INTO #childTableTtmp SELECT STLN.StockLineId FROM DBO.Stockline STL
					LEFT JOIN DBO.Stockline STLN WITH (NOLOCK) ON STL.StockLineId = STLN.ParentId
					WHERE STL.StockLineId = @StockLineId
					ORDER BY STLN.StockLineId DESC

					SELECT @MasterLoopID = MAX(ID) FROM #childTableTtmp;

					WHILE (@MasterLoopID > 0)
					BEGIN
						SELECT @StocklineToUpdate = StocklineId FROM #childTableTtmp WHERE ID = @MasterLoopID;
						SELECT @IdNumberUpdated = IdNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineToUpdate
					
						DECLARE @CalculatedIssuedQty INT = CASE WHEN @RemainingIssuedQty > 0 THEN 1 ELSE 0 END;
						DECLARE @CalculatedReservedQty INT = CASE WHEN (@CalculatedIssuedQty) > 0 THEN 0 ELSE CASE WHEN @RemainingReservedQty > 0 THEN 1 ELSE 0 END END;
						DECLARE @CalculatedOHQty INT = CASE WHEN (@CalculatedIssuedQty) > 0 THEN 0 ELSE CASE WHEN @RemainingOHQty > 0 THEN 1 ELSE 0 END END;
						DECLARE @CalculatedAvailableQty INT = CASE WHEN @RemainingAvailableQty > 0 THEN CASE WHEN (@CalculatedReservedQty + @CalculatedIssuedQty) > 0 THEN 0 ELSE 1 END ELSE 0 END;

						SELECT @PrevReservedQty = QuantityReserved, @PrevIssuedQty = QuantityIssued,
						@PrevOHQty = QuantityOnHand, @PrevAvailableQty = QuantityAvailable FROM DBO.Stockline WHERE StocklineId = @StocklineToUpdate;

						Update DBO.Stockline
						SET QuantityReserved = @CalculatedReservedQty,
						QuantityIssued = @CalculatedIssuedQty,
						QuantityOnHand = @CalculatedOHQty, 
						QuantityAvailable = @CalculatedAvailableQty
						WHERE StocklineId = @StocklineToUpdate;

						IF (@CalculatedAvailableQty > 0)
							SET @RemainingAvailableQty = @RemainingAvailableQty - 1;
						IF (@CalculatedOHQty > 0)
							SET @RemainingOHQty = @RemainingOHQty - 1;
						IF (@CalculatedReservedQty > 0)
							SET @RemainingReservedQty = @RemainingReservedQty - 1;
						SET @RemainingIssuedQty = @RemainingIssuedQty - 1;

						IF ((@CalculatedReservedQty <> @PrevReservedQty) OR (@CalculatedIssuedQty <> @PrevIssuedQty) OR (@CalculatedOHQty <> @PrevOHQty))
						BEGIN
							IF (@CalculatedReservedQty > @PrevReservedQty)
							BEGIN
								SET @ActionMsg = 'Reserved'
							END
							ELSE IF (@CalculatedReservedQty < @PrevReservedQty)
							BEGIN
								SET @ActionMsg = 'UnReserved'
							END

							IF (@CalculatedIssuedQty > @PrevIssuedQty)
							BEGIN
								SET @ActionMsg = 'Issued'
							END
							ELSE IF (@CalculatedIssuedQty < @PrevIssuedQty)
							BEGIN
								SET @ActionMsg = 'UnIssued'
							END

							IF (@CalculatedOHQty > @PrevOHQty)
							BEGIN
								SET @ActionMsg = 'Added into OH'
							END
							ELSE IF (@CalculatedOHQty < @PrevOHQty)
							BEGIN
								SET @ActionMsg = 'Removed from OH'
							END

							IF @AllIdNumbers != ''
							BEGIN
								SET @AllIdNumbers = @AllIdNumbers + ', ' + @IdNumberUpdated
							END
							ELSE
							BEGIN
								SET @AllIdNumbers = @IdNumberUpdated
							END
						END

						SET @MasterLoopID = @MasterLoopID - 1;
					END
				END
				ELSE
				BEGIN
					SELECT @RemainingAvailableQty = QuantityAvailable,
					@RemainingOHQty = QuantityOnHand,
					@StocklineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId

					IF OBJECT_ID(N'tempdb..#childTableTOHtmp') IS NOT NULL
					BEGIN
						DROP TABLE #childTableTOHtmp
					END

					CREATE TABLE #childTableTOHtmp (
						ID bigint NOT NULL IDENTITY,
						StockLineId bigint NULL
					)

					INSERT INTO #childTableTOHtmp SELECT STLN.StockLineId FROM DBO.Stockline STL
					LEFT JOIN DBO.Stockline STLN WITH (NOLOCK) ON STL.StockLineId = STLN.ParentId
					WHERE STL.StockLineId = @StockLineId
					ORDER BY STLN.StockLineId --DESC

					SELECT @MasterLoopID = MAX(ID) FROM #childTableTOHtmp;

					WHILE (@MasterLoopID > 0)
					BEGIN
						SELECT @StocklineToUpdate = StocklineId FROM #childTableTOHtmp WHERE ID = @MasterLoopID;
						SELECT @IdNumberUpdated = IdNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineToUpdate
					
						DECLARE @CalculatedIssuedQtyOH INT = CASE WHEN @RemainingIssuedQty > 0 THEN 1 ELSE 0 END;
						DECLARE @CalculatedReservedQtyOH INT = CASE WHEN (@CalculatedIssuedQtyOH) > 0 THEN 0 ELSE CASE WHEN @RemainingReservedQty > 0 THEN 1 ELSE 0 END END;
						DECLARE @CalculatedOHQtyOH INT = CASE WHEN (@CalculatedIssuedQty) > 0 THEN 0 ELSE CASE WHEN @RemainingOHQty > 0 THEN 1 ELSE 0 END END;
						DECLARE @CalculatedAvailableQtyOH INT = CASE WHEN @RemainingAvailableQty > 0 THEN CASE WHEN (@CalculatedReservedQtyOH + @CalculatedIssuedQtyOH) > 0 THEN 0 ELSE 1 END ELSE 0 END;

						SELECT @PrevOHQty = QuantityOnHand, @PrevAvailableQty = QuantityAvailable FROM DBO.Stockline WHERE StocklineId = @StocklineToUpdate;

						Update DBO.Stockline
						SET QuantityOnHand = @CalculatedOHQtyOH,
						QuantityAvailable = @CalculatedAvailableQtyOH
						WHERE StocklineId = @StocklineToUpdate;

						IF (@CalculatedOHQtyOH > 0)
							SET @RemainingOHQty = @RemainingOHQty - 1;
						IF (@CalculatedAvailableQtyOH > 0)
							SET @RemainingAvailableQty = @RemainingAvailableQty - 1;

						IF ((@CalculatedOHQtyOH <> @PrevOHQty) OR (@CalculatedAvailableQtyOH <> @PrevAvailableQty))
						BEGIN
							IF (@CalculatedOHQtyOH > @PrevOHQty)
							BEGIN
								SET @ActionMsg = 'Added into OH'
							END
							ELSE IF (@CalculatedOHQtyOH < @PrevOHQty)
							BEGIN
								SET @ActionMsg = 'Removed from OH'
							END

							IF (@CalculatedAvailableQtyOH > @PrevAvailableQty)
							BEGIN
								SET @ActionMsg = 'Added into Avail Qty'
							END
							ELSE IF (@CalculatedAvailableQtyOH < @PrevAvailableQty)
							BEGIN
								SET @ActionMsg = 'Removed from Avail Qty'
							END

							IF @AllIdNumbers != ''
							BEGIN
								SET @AllIdNumbers = @AllIdNumbers + ', ' + @IdNumberUpdated
							END
							ELSE
							BEGIN
								SET @AllIdNumbers = @IdNumberUpdated
							END
						END

						SET @MasterLoopID = @MasterLoopID - 1;
					END
				END

				IF (@AllIdNumbers <> '')
				BEGIN
					INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [SubModuleId], [SubReferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
					SELECT @ModuleId, @ReferenceId, @SubModuleId, @SubReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'Stockline ('+ @AllIdNumbers +') ' + @ActionMsg, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId 
					FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
				END
				/* END: Update Qty into Child rows */
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
		,@AdhocComments varchar(150) = 'USP_CreateChildStockline'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@StocklineId, '') + ''
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