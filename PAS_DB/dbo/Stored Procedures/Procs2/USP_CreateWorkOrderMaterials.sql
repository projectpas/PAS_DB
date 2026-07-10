-- ===== PROCEDURE: [dbo].[USP_CreateWorkOrderMaterials]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_CreateWorkOrderMaterials.sql) =====
/*************************************************************             
 ** File:   [USP_CreateWorkOrderMaterials]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Create work order materials
 ** Date:   28-April-2025         
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date					Author						Change Description              
 ** --   --------				-------					--------------------------------            
 ** 1    28-April-2025			Devendra Shekh				Created
       
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	2    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderMaterials]  
	@tbl_WorkOrderMaterialsType [WorkOrderMaterialsType] READONLY
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION  

		IF OBJECT_ID('tempdb..#tmpWorkOrderMaterial') IS NOT NULL
			DROP TABLE #tmpWorkOrderMaterial;

		DECLARE @isExistingMaterilas BIT = 0;
		DECLARE @workOrderId BIGINT = 0, @IsAutoIssue BIT = 0;
		DECLARE @TotalMaterialCount INT, @CurrentRowId INT, @InitialRowId INT = 1;		
		DECLARE @Quantity INT, @WorkOrderPartNoId BIGINT, @WorkOrderMaterialsId BIGINT, @WorkFlowWorkOrderId BIGINT, @ItemMasterId BIGINT, @CreatedBy VARCHAR(200), @MasterCompanyId INT, @WorkOrderTypeId BIGINT, @EmployeeId BIGINT, @WOMStockLineId BIGINT;
		DECLARE @ProvisionId INT, @SUB_WORK_ORDER_ProvisionId INT = 3;
		DECLARE @tmpWOMaterial [WorkOrderMaterialsType];
		DECLARE @tmpStkWOMaterial [WorkOrderMaterialsType];

		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, * INTO #tmpWorkOrderMaterial FROM @tbl_WorkOrderMaterialsType;

		SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWorkOrderMaterial;

		IF(ISNULL(@TotalMaterialCount, 0) > 0)
		BEGIN
			WHILE(@TotalMaterialCount >= @CurrentRowId)
			BEGIN
				
				IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN #tmpWorkOrderMaterial TMP ON WOM.ItemMasterId = TMP.ItemMasterId AND WOM.ConditionCodeId = TMP.ConditionCodeId 
						AND WOM.TaskId = TMP.TaskId AND ISNULL(WOM.Item, '') = ISNULL(TMP.Item, '') AND ISNULL(WOM.Figure, '') = ISNULL(TMP.Figure, '') AND WOM.WorkFlowWorkOrderId = TMP.WorkFlowWorkOrderId AND WOM.WorkOrderId = TMP.WorkOrderId
						WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					UPDATE TMP
					SET TMP.WorkOrderMaterialsId = (SELECT TOP 1 WOM.WorkOrderMaterialsId FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN #tmpWorkOrderMaterial TMP ON WOM.ItemMasterId = TMP.ItemMasterId AND WOM.ConditionCodeId = TMP.ConditionCodeId 
												AND WOM.TaskId = TMP.TaskId AND ISNULL(WOM.Item, '') = ISNULL(TMP.Item, '') AND ISNULL(WOM.Figure, '') = ISNULL(TMP.Figure, '') AND WOM.WorkFlowWorkOrderId = TMP.WorkFlowWorkOrderId AND WOM.WorkOrderId = TMP.WorkOrderId),
						TMP.isExistingMaterilas = 1
					FROM #tmpWorkOrderMaterial TMP WHERE TMP.RowId = @CurrentRowId

					SET @isExistingMaterilas = 1
				END

				SET @CurrentRowId += 1;
			END			
		END

		SELECT @workOrderId = [WorkOrderId], @Quantity = [Quantity], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
		FROM #tmpWorkOrderMaterial WHERE [RowId] = @InitialRowId;

		IF(ISNULL(@workOrderId, 0) > 0)
		BEGIN
			SELECT @IsAutoIssue = WS.IsAutoReserve, @WorkOrderTypeId = WO.WorkOrderTypeId, @EmployeeId = WO.[EmployeeId]
			FROM [dbo].[WorkOrderSettings] WS WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WS.WorkOrderTypeId = WO.WorkOrderTypeId AND WS.MasterCompanyId = WO.MasterCompanyId
			WHERE WO.WorkOrderId = @workOrderId;
		END

		-- Add Entry in History Table	: Start
		IF(ISNULL(@Quantity, 0) > 0) AND ISNULL(@isExistingMaterilas, 0) = 0
		BEGIN

			DECLARE @historyModuleId BIGINT, @historySubModuleId BIGINT, @TemplateBody NVARCHAR(MAX), @WOMQuantity INT, @OldValue VARCHAR(MAX)='', @NewValue VARCHAR(MAX) ='', @partnumber VARCHAR(50), @AddPNPart VARCHAR(20) = 'AddPN';
			
			SELECT @WOMQuantity = [Quantity] FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId
			SELECT @WorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;
			SELECT @partnumber = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;

			SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @AddPNPart;
			SELECT @historyModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
			SELECT @historySubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';

			SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', @partnumber);

			--Added for WO History 
			IF(ISNULL(@WorkOrderMaterialsId, 0) > 0)
			BEGIN
				SET @OldValue = CAST(@WOMQuantity AS VARCHAR)
				SET @NewValue = CAST(ISNULL(@WOMQuantity, 0) + ISNULL(@Quantity, 0) AS VARCHAR)
			END
			ELSE
			BEGIN
				SET @OldValue = CAST(0 AS VARCHAR)
				SET @NewValue = CAST(ISNULL(@Quantity, 0) AS VARCHAR)
			END

			EXEC [dbo].[USP_History] @historyModuleId,@workOrderId,@historySubModuleId,@WorkOrderPartNoId,@OldValue,@NewValue,@TemplateBody,@AddPNPart,@MasterCompanyId,@CreatedBy,NULL,@CreatedBy,NULL;
		END
		-- Add Entry in History Table	: End

		IF(ISNULL(@isExistingMaterilas, 0) = 1)
		BEGIN
			INSERT INTO @tmpWOMaterial ([WorkOrderMaterialsId], [WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred],
				[QuantityReserved], [QuantityIssued], [IssuedById], [IssuedDate], [ReservedById], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [PartStatusId], [UnReservedQty], [UnIssuedQty], [ParentWorkOrderMaterialsId], [ItemMappingId],
				[TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued], [QtyToTurnIn], [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder], [QtyOnBkOrder], [IsFromWorkFlow], [IsEquPart], [StockLineId],
				[StocklineQuantity], [Provision], [WareHouse], [Location], [Shelf], [Bin], [TaskName], [Condition], [MandatoryOrSupplemental], [StockLineNumber], [PartNumber], [PartDescription], [AltPartNumber], [SerialNumber], [StockType], [ControlId],
				[ControlNo], [ItemType], [QunatityRequried], [QunatityReserved], [QunatityTurnIn], [QunatityBackOrder], [QunatityRemaining], [Currency], [PurchaseOrderNumber], [RepairOrderNumber], [PartQuantityOnHand], [PartQuantityAvailable],
				[PartQuantityOnOrder], [Receiver], [WorkOrderNumber], [SubWorkOrder], [SalesOrder], [TimeLife], [PurchaseUnitOfMeasureId], [IsStocklineEdit], [isExistingMaterilas], [Figure], [Item], [IsAlternatePart], [EquPartMasterPartId], [KitId],
				[IsKitType], [isfromsubWorkOrder], [ExpectedSerialNumber], [POId], [PONum], [PONextDlvrDate], [IsExchangeTender], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT [WorkOrderMaterialsId], [WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred], 
				[QuantityReserved], [QuantityIssued], [IssuedById], [IssuedDate], [ReservedById], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [PartStatusId], [UnReservedQty], [UnIssuedQty], [ParentWorkOrderMaterialsId], [ItemMappingId],
				[TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued], [QtyToTurnIn], [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder], [QtyOnBkOrder], [IsFromWorkFlow], [IsEquPart], [StockLineId],
				[StocklineQuantity], [Provision], [WareHouse], [Location], [Shelf], [Bin], [TaskName], [Condition], [MandatoryOrSupplemental], [StockLineNumber], [PartNumber], [PartDescription], [AltPartNumber], [SerialNumber], [StockType], [ControlId],
				[ControlNo], [ItemType], [QunatityRequried], [QunatityReserved], [QunatityTurnIn], [QunatityBackOrder], [QunatityRemaining], [Currency], [PurchaseOrderNumber], [RepairOrderNumber], [PartQuantityOnHand], [PartQuantityAvailable],
				[PartQuantityOnOrder], [Receiver], [WorkOrderNumber], [SubWorkOrder], [SalesOrder], [TimeLife], [PurchaseUnitOfMeasureId], [IsStocklineEdit], [isExistingMaterilas], [Figure], [Item], [IsAlternatePart], [EquPartMasterPartId], [KitId],
				[IsKitType], [isfromsubWorkOrder], [ExpectedSerialNumber], [POId], [PONum], [PONextDlvrDate], [IsExchangeTender], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
			FROM #tmpWorkOrderMaterial; 

			EXEC [USP_UpdateWorkOrderMaterials] @tmpWOMaterial;
		END
		ELSE
		BEGIN

			SELECT @ProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [ProvisionId] = @SUB_WORK_ORDER_ProvisionId AND ISNULL([IsActive], 0) = 1 AND ISNULL([IsDeleted], 0) = 0;

			UPDATE TMP
			SET	TMP.ItemClassificationId = CASE WHEN ISNULL(TMP.ItemClassificationId, 0) = 0 THEN IM.ItemClassificationId ELSE TMP.ItemClassificationId END,
				TMP.QtyToTurnIn = CASE WHEN TMP.ProvisionId = @ProvisionId THEN TMP.Quantity ELSE TMP.QtyToTurnIn END,
				TMP.Quantity = CASE WHEN TMP.ProvisionId = @ProvisionId THEN 0 ELSE TMP.Quantity END,
				TMP.UnitOfMeasureId = CASE WHEN ISNULL(TMP.UnitOfMeasureId, 0) = 0 THEN CASE WHEN ISNULL(TMP.StockLineId, 0) > 0 THEN STK.PurchaseUnitOfMeasureId ELSE IM.PurchaseUnitOfMeasureId END ELSE TMP.UnitOfMeasureId END,
				--TMP.IsAltPart = CASE WHEN ISNULL(TMP.IsAltPart, 0) = 1 THEN TMP.IsAltPart ELSE TMP.IsAltPart END,
				TMP.AltPartMasterPartId = CASE WHEN ISNULL(TMP.IsAltPart, 0) = 1 THEN TMP.IsAlternatePart ELSE TMP.AltPartMasterPartId END,
				--TMP.IsEquPart = CASE WHEN ISNULL(TMP.IsEquPart, 0) = 1 THEN TMP.IsEquPart ELSE TMP.IsEquPart END,
				TMP.EquPartMasterPartId = CASE WHEN ISNULL(TMP.IsEquPart, 0) = 1 THEN TMP.IsAlternatePart ELSE TMP.EquPartMasterPartId END,
				TMP.IsActive = 1,
				TMP.IsDeleted = 0,
				TMP.CreatedDate = GETUTCDATE(),
				TMP.UpdatedDate =  GETUTCDATE()
			FROM #tmpWorkOrderMaterial TMP
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
			 AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [dbo].[StockLine] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0

			SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWorkOrderMaterial;

			IF(ISNULL(@TotalMaterialCount, 0) > 0)
			BEGIN
				WHILE(@TotalMaterialCount >= @CurrentRowId)
				BEGIN
					INSERT INTO [dbo].[WorkOrderMaterials] ([WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [ConditionCodeId], [ItemClassificationId],
							[Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [UnReservedQty], [UnIssuedQty], 
							[IssuedById], [ReservedById], [IsEquPart], [ParentWorkOrderMaterialsId], [ItemMappingId], [TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued], [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder],
							[QtyOnBkOrder], [POId], [PONum], [PONextDlvrDate], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [isfromsubWorkOrder], [ExpectedSerialNumber])
					SELECT [WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [ConditionCodeId], [ItemClassificationId],
							[Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [UnReservedQty], [UnIssuedQty], 
							[IssuedById], [ReservedById], [IsEquPart], [ParentWorkOrderMaterialsId], [ItemMappingId], [TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued], [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder],
							[QtyOnBkOrder], [POId], [PONum], [PONextDlvrDate], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [isfromsubWorkOrder], [ExpectedSerialNumber]
					FROM #tmpWorkOrderMaterial WHERE [RowId] = @CurrentRowId;

					SET @WorkOrderMaterialsId = SCOPE_IDENTITY();			
					
					UPDATE TMP
					SET	TMP.WorkOrderMaterialsId = @WorkOrderMaterialsId,
						TMP.UnitOfMeasureId = CASE WHEN ISNULL(TMP.UnitOfMeasureId, 0) = 0 THEN CASE WHEN ISNULL(TMP.StockLineId, 0) > 0 THEN STK.PurchaseUnitOfMeasureId ELSE IM.PurchaseUnitOfMeasureId END ELSE TMP.UnitOfMeasureId END
					FROM #tmpWorkOrderMaterial TMP 
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[StockLine] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0
					WHERE [RowId] = @CurrentRowId;

					SELECT @WorkOrderMaterialsId = [WorkOrderMaterialsId], @WOMStockLineId = [StockLineId] FROM #tmpWorkOrderMaterial TMP WHERE TMP.RowId = @CurrentRowId

					IF(ISNULL(@WOMStockLineId, 0) > 0)
					BEGIN
						DELETE FROM @tmpStkWOMaterial;

						INSERT INTO @tmpStkWOMaterial ([WorkOrderMaterialsId], [WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred],
							[QuantityReserved], [QuantityIssued], [IssuedById], [IssuedDate], [ReservedById], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [PartStatusId], [UnReservedQty], [UnIssuedQty], [ParentWorkOrderMaterialsId], [ItemMappingId],
							[TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued], [QtyToTurnIn], [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder], [QtyOnBkOrder], [IsFromWorkFlow], [IsEquPart], [StockLineId],
							[StocklineQuantity], [Provision], [WareHouse], [Location], [Shelf], [Bin], [TaskName], [Condition], [MandatoryOrSupplemental], [StockLineNumber], [PartNumber], [PartDescription], [AltPartNumber], [SerialNumber], [StockType], [ControlId],
							[ControlNo], [ItemType], [QunatityRequried], [QunatityReserved], [QunatityTurnIn], [QunatityBackOrder], [QunatityRemaining], [Currency], [PurchaseOrderNumber], [RepairOrderNumber], [PartQuantityOnHand], [PartQuantityAvailable],
							[PartQuantityOnOrder], [Receiver], [WorkOrderNumber], [SubWorkOrder], [SalesOrder], [TimeLife], [PurchaseUnitOfMeasureId], [IsStocklineEdit], [isExistingMaterilas], [Figure], [Item], [IsAlternatePart], [EquPartMasterPartId], [KitId],
							[IsKitType], [isfromsubWorkOrder], [ExpectedSerialNumber], [POId], [PONum], [PONextDlvrDate], [IsExchangeTender], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
						SELECT [WorkOrderMaterialsId], [WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred], 
							[QuantityReserved], [QuantityIssued], [IssuedById], [IssuedDate], [ReservedById], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [PartStatusId], [UnReservedQty], [UnIssuedQty], [ParentWorkOrderMaterialsId], [ItemMappingId],
							[TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued], [QtyToTurnIn], [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder], [QtyOnBkOrder], [IsFromWorkFlow], [IsEquPart], [StockLineId],
							[StocklineQuantity], [Provision], [WareHouse], [Location], [Shelf], [Bin], [TaskName], [Condition], [MandatoryOrSupplemental], [StockLineNumber], [PartNumber], [PartDescription], [AltPartNumber], [SerialNumber], [StockType], [ControlId],
							[ControlNo], [ItemType], [QunatityRequried], [QunatityReserved], [QunatityTurnIn], [QunatityBackOrder], [QunatityRemaining], [Currency], [PurchaseOrderNumber], [RepairOrderNumber], [PartQuantityOnHand], [PartQuantityAvailable],
							[PartQuantityOnOrder], [Receiver], [WorkOrderNumber], [SubWorkOrder], [SalesOrder], [TimeLife], [PurchaseUnitOfMeasureId], [IsStocklineEdit], [isExistingMaterilas], [Figure], [Item], [IsAlternatePart], [EquPartMasterPartId], [KitId],
							[IsKitType], [isfromsubWorkOrder], [ExpectedSerialNumber], [POId], [PONum], [PONextDlvrDate], [IsExchangeTender], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
						FROM #tmpWorkOrderMaterial WHERE [RowId] = @CurrentRowId; 
						
						-- Create Work Order Material StockLine
						EXEC [USP_CreateWorkOrderMaterialsStoclkine] @tmpStkWOMaterial;
					END

					SET @CurrentRowId += 1;
				END			
			END

			SELECT @WorkOrderMaterialsId = [WorkOrderMaterialsId] FROM #tmpWorkOrderMaterial WHERE [RowId] = @InitialRowId;

			-- Auto Reserve / Issue Work Order Materials
			EXEC [USP_AutoReserveIssueWorkOrderMaterials] @WorkFlowWorkOrderId, @CreatedBy;

			-- Update Work Order Material Cost Details
			EXEC [USP_UpdateWOMaterialsCost] @WorkOrderMaterialsId, @WorkFlowWorkOrderId;

			-- Update Work Order Total Cost Details
			EXEC [USP_UpdateWOTotalCostDetails] @WorkOrderId, @WorkFlowWorkOrderId, @CreatedBy, @MasterCompanyId;

			-- Update Work Order Cost Details
			EXEC [USP_UpdateWOCostDetails] @WorkOrderId, @WorkFlowWorkOrderId, @CreatedBy, @MasterCompanyId;

			DECLARE @isValid BIT = 0; -- Will enable it once WO auto issue functionality implement  

			IF(@isValid = 1)
			BEGIN

				DECLARE @woQuoteApproveId INT = 5, @CustWorkOrderTypeEnumId INT = 1, @InternalWorkOrderTypeEnumId INT = 1, @ReplaceProvisionEnumId INT = 1, @ReplcaeProvisionId INT = 0, @arConditionId INT = 0, @ARCondDesc VARCHAR(30) = 'AR', @PickTicketFulfillingStatusEnumId INT = 1,
						@PickTicketNumber VARCHAR(50),  @PickTicketMemo NVARCHAR(MAX);

				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOQ.WorkOrderId = WO.WorkOrderId WHERE WOQ.QuoteStatusId = @woQuoteApproveId)
				BEGIN
					
					SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWorkOrderMaterial;

					IF((@workOrderId > 0) AND @WorkOrderTypeId IN (@CustWorkOrderTypeEnumId, @InternalWorkOrderTypeEnumId) AND ISNULL(@IsAutoIssue, 0) = 1 AND @TotalMaterialCount > 0)
					BEGIN

						SET @ReplcaeProvisionId = (SELECT TOP 1 [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [ProvisionId] = @ReplaceProvisionEnumId AND ISNULL([IsActive], 0) = 1 AND ISNULL([IsDeleted], 0) = 0); 
						SET @arConditionId = (SELECT TOP 1 [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [Description] = @ARCondDesc AND ISNULL([IsActive], 0) = 1 AND ISNULL([IsDeleted], 0) = 0 AND [MasterCompanyId] = @MasterCompanyId)

						IF OBJECT_ID('tempdb..#tmpWOPickTicketItem') IS NOT NULL
							DROP TABLE #tmpWOPickTicketItem;
						 
						SELECT TOP 1 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS TmpPickItemId, 0 AS [PickTicketId], @workOrderId AS [WorkOrderId], TMP.WorkOrderMaterialsId, ISNULL(WOMS.Quantity, 0) AS [Qty], ISNULL(WOMS.Quantity, 0) AS [QtyToShip], @PickTicketNumber AS [PickTicketNumber], @PickTicketFulfillingStatusEnumId AS [Status],
						@EmployeeId AS [PickedById], ISNULL(@EmployeeId, 0) AS [ConfirmedById], GETUTCDATE() AS [ConfirmedDate], @PickTicketMemo AS [Memo], 1 AS [IsConfirmed], WOMS.StockLineId AS [StocklineId], TMP.IsKitType AS [IsKitType]
						INTO #tmpWOPickTicketItem
						FROM #tmpWorkOrderMaterial TMP
						INNER JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON TMP.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
						WHERE TMP.ProvisionId = @ReplcaeProvisionId AND TMP.ConditionCodeId != @arConditionId
						ORDER BY WOMS.CreatedDate DESC

						IF EXISTS(SELECT 1 FROM #tmpWOPickTicketItem)
						BEGIN
							
							DECLARE @WOPickTicketCodePrefix INT, @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50), @CurrentNo INT = 0, @TotalPickItems INT, @CurrentPicktItemId INT;

							-- Code Types Of CodePrefix	
							SELECT @WOPickTicketCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'WOPickTicket';

							 -- Determine WOPickTicket Code Prefix and Number
							SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @WOPickTicketCodePrefix AND [MasterCompanyId] = @MasterCompanyId;

							-- Check for current number and increment
							IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
							BEGIN
								SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
								IF @CurrentNo > 0
								BEGIN
									SET @CurrentNo = @CurrentNo + 1;
									UPDATE [dbo].[CodePrefixes] 
									SET [CurrentNummber] = @CurrentNo
									WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
								END
								ELSE
								BEGIN
									SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
									UPDATE [dbo].[CodePrefixes]
									SET [CurrentNummber] = @CurrentNo 
									WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
								END
								-- Generate WOPickTicket Number
								SET @PickTicketNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
							END
							ELSE
							BEGIN
								-- Generate WOPickTicket Number
								SET @PickTicketNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
							END

							SELECT @TotalPickItems = COUNT(TmpPickItemId), @CurrentPicktItemId = MIN(TmpPickItemId) FROM #tmpWOPickTicketItem;

							IF(ISNULL(@TotalPickItems, 0) > 0)
							BEGIN
								
								DECLARE @WOPickTicketId BIGINT, @WOPickTicketNumber NVARCHAR(MAX), @IsActive BIT, @IsDeleted BIT, @Qty INT, @QtyToShip INT, @Status INT, @PickedById BIGINT, @ConfirmedById INT, @Memo NVARCHAR(MAX),
										@IsConfirmed BIT, @CodePrefixId BIGINT, @CurrentNummber BIGINT, @IsMPN BIT, @StocklineId BIGINT, @IsKitType BIT;

								WHILE(@TotalPickItems >= @CurrentPicktItemId)
								BEGIN
									
									SELECT @WOPickTicketId = [PickTicketId], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @Qty = [Qty], @QtyToShip = [QtyToShip], @Status = [Status], @PickedById = [PickedById], @ConfirmedById = [ConfirmedById],
											@Memo = [Memo], @IsConfirmed = [IsConfirmed], @StocklineId = [StocklineId], @IsKitType = [IsKitType]
									FROM #tmpWOPickTicketItem WHERE TmpPickItemId = @CurrentPicktItemId;

									EXEC [sp_savePickTicketItemInterface_WO]	@WOPickTicketId, @PickTicketNumber, @workOrderId, @CreatedBy, @CreatedBy, 1, 0, @WorkOrderMaterialsId, @Qty, @QtyToShip, @MasterCompanyId, @Status, @PickedById, @ConfirmedById,
																				@Memo, @IsConfirmed, NULL, NULL, 0, @StocklineId, @IsKitType

									SET @CurrentPicktItemId += 1;

								END
							END
						END
					END
				END
			END

			-- Selecting Result
			SELECT * FROM #tmpWorkOrderMaterial;
		END		
   
	COMMIT TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderMaterials'   
				, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' 
				, @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
				EXEC	spLogException   
						@DatabaseName   = @DatabaseName  
						, @AdhocComments   = @AdhocComments  
						, @ProcedureParameters  = @ProcedureParameters  
						, @ApplicationName         = @ApplicationName  
						, @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
	END CATCH  
END