-- ===== PROCEDURE: [dbo].[USP_UpdateWorkOrderMaterials]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs3/USP_UpdateWorkOrderMaterials.sql) =====
/*************************************************************             
 ** File:   [USP_UpdateWorkOrderMaterials]             
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
  
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderMaterials]  
	@tbl_WorkOrderMaterialsType [WorkOrderMaterialsType] READONLY
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION  

		IF OBJECT_ID('tempdb..#tmpWorkOrderMaterial') IS NOT NULL
			DROP TABLE #tmpWorkOrderMaterial;

		IF OBJECT_ID('tempdb..#tmpWorkOrderMaterialKit') IS NOT NULL
			DROP TABLE #tmpWorkOrderMaterialKit;

		DECLARE @ProvisionId INT, @SUB_WORK_ORDER_ProvisionId INT = 3;
		DECLARE @isExistingMaterilas BIT = 0;
		DECLARE @workOrderId BIGINT = 0, @IsAutoIssue BIT = 0;
		DECLARE @TotalMaterialCount INT, @CurrentRowId INT, @InitialRowId INT = 1;		
		DECLARE @PartStatusEnumReserve INT = 1, @PartStatusEnumIssue INT = 2, @PartStatusEnumUnIssue INT = 4, @PartStatusEnumUnReserve INT = 5;
		DECLARE @Quantity INT, @WorkOrderPartNoId BIGINT, @WorkOrderMaterialsId BIGINT, @WorkFlowWorkOrderId BIGINT, @ItemMasterId BIGINT, @CreatedBy VARCHAR(200), @MasterCompanyId INT, @WorkOrderTypeId BIGINT, @EmployeeId BIGINT, @WOMStockLineId BIGINT;
		DECLARE @tmpWOMaterial [WorkOrderMaterialsType];

		SELECT @ProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [ProvisionId] = @SUB_WORK_ORDER_ProvisionId AND ISNULL([IsActive], 0) = 1 AND ISNULL([IsDeleted], 0) = 0;

		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, * INTO #tmpWorkOrderMaterial FROM @tbl_WorkOrderMaterialsType WHERE ISNULL(IsKitType, 0) = 0;
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, * INTO #tmpWorkOrderMaterialKit FROM @tbl_WorkOrderMaterialsType WHERE ISNULL(IsKitType, 0) = 1;	

		IF EXISTS (SELECT 1 FROM #tmpWorkOrderMaterial)
		BEGIN
			SELECT @workOrderId = [WorkOrderId], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
			FROM #tmpWorkOrderMaterial WHERE [RowId] = @InitialRowId;
		END
		ELSE
		BEGIN
			SELECT @workOrderId = [WorkOrderId], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
			FROM #tmpWorkOrderMaterialKit WHERE [RowId] = @InitialRowId;
		END
		
		-- Working On Work Order Material : Start
		SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWorkOrderMaterial;

		UPDATE TMP
		SET TMP.PartStatusId = CASE WHEN TMP.PartStatusId = @PartStatusEnumUnIssue THEN @PartStatusEnumIssue WHEN TMP.PartStatusId = @PartStatusEnumUnReserve THEN @PartStatusEnumReserve ELSE TMP.PartStatusId END,
			TMP.QtyToTurnIn = CASE WHEN TMP.ProvisionId = @ProvisionId THEN TMP.Quantity ELSE TMP.QtyToTurnIn END,
			TMP.Quantity = CASE WHEN TMP.ProvisionId = @ProvisionId THEN 0 ELSE TMP.Quantity END
		FROM #tmpWorkOrderMaterial TMP;

		IF(ISNULL(@TotalMaterialCount, 0) > 0)
		BEGIN
			
			WHILE(@TotalMaterialCount >= @CurrentRowId)
			BEGIN
				
				SELECT @WorkOrderMaterialsId = [WorkOrderMaterialsId], @Quantity = [Quantity], @isExistingMaterilas = [isExistingMaterilas], @WOMStockLineId = [StockLineId] FROM #tmpWorkOrderMaterial TMP WHERE TMP.RowId = @CurrentRowId

				IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN #tmpWorkOrderMaterial TMP ON WOM.WorkOrderMaterialsId = TMP.WorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					-- Add Entry in History Table	: Start
					IF(ISNULL(@Quantity, 0) > 0)
					BEGIN
					
						DECLARE @historyModuleId BIGINT, @historySubModuleId BIGINT, @TemplateBody NVARCHAR(MAX), @WOMQuantity INT, @OldValue VARCHAR(MAX) = '', @NewValue VARCHAR(MAX) = '', @partnumber VARCHAR(50), @AddPNPart VARCHAR(20) = 'AddPN';
			
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
							SET @NewValue = CASE WHEN @isExistingMaterilas = 1 THEN CAST(ISNULL(@WOMQuantity, 0) + ISNULL(@Quantity, 0) AS VARCHAR) ELSE CAST(ISNULL(@Quantity, 0) AS VARCHAR) END
						END
						ELSE
						BEGIN
							SET @OldValue = CAST(0 AS VARCHAR)
							SET @NewValue = CAST(ISNULL(@Quantity, 0) AS VARCHAR)
						END
						
						EXEC [dbo].[USP_History] @historyModuleId,@workOrderId,@historySubModuleId,@WorkOrderPartNoId,@OldValue,@NewValue,@TemplateBody,@AddPNPart,@MasterCompanyId,@CreatedBy,NULL,@CreatedBy,NULL;
						
					END
					-- Add Entry in History Table	: End

					UPDATE WOM
					SET WOM.QtyToTurnIn = CASE WHEN TMP.ProvisionId = @ProvisionId THEN TMP.QtyToTurnIn ELSE WOM.QtyToTurnIn END,
						WOM.Quantity = CASE WHEN TMP.ProvisionId != @ProvisionId THEN CASE WHEN TMP.isExistingMaterilas = 1 THEN ISNULL(WOM.Quantity, 0) + ISNULL(TMP.Quantity, 0) ELSE TMP.Quantity END ELSE WOM.Quantity END,
						WOM.IsDeferred = TMP.IsDeferred,
						WOM.UnitCost = TMP.UnitCost,
						WOM.ExtendedCost = TMP.ExtendedCost,
						WOM.Memo = TMP.Memo,
						WOM.ProvisionId = CASE WHEN ISNULL(TMP.IsStocklineEdit, 0) = 0 THEN TMP.ProvisionId ELSE WOM.ProvisionId END,
						WOM.TaskId = TMP.TaskId,
						WOM.MaterialMandatoriesId = TMP.MaterialMandatoriesId,
						WOM.Figure = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.Figure ELSE WOM.Figure END,
						WOM.Item = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.Item ELSE WOM.Item END,
						WOM.IsAltPart = CASE WHEN ISNULL(TMP.IsAltPart, 0) = 1 THEN TMP.IsAltPart ELSE WOM.IsAltPart END,
						WOM.AltPartMasterPartId = CASE WHEN ISNULL(TMP.IsAltPart, 0) = 1 THEN TMP.IsAlternatePart ELSE WOM.AltPartMasterPartId END,
						WOM.IsEquPart = CASE WHEN ISNULL(TMP.IsEquPart, 0) = 1 THEN TMP.IsEquPart ELSE WOM.IsEquPart END,
						WOM.EquPartMasterPartId = CASE WHEN ISNULL(TMP.IsEquPart, 0) = 1 THEN TMP.IsAlternatePart ELSE WOM.EquPartMasterPartId END
					FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)
					INNER JOIN #tmpWorkOrderMaterial TMP ON WOM.WorkOrderMaterialsId = TMP.WorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId
				END
				ELSE
				BEGIN
					-- Savinvg New Work Order Material
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
					SET	TMP.WorkOrderMaterialsId = @WorkOrderMaterialsId
					FROM #tmpWorkOrderMaterial TMP 
					WHERE [RowId] = @CurrentRowId;
				END

				DELETE FROM @tmpWOMaterial;

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
				FROM #tmpWorkOrderMaterial WHERE [RowId] = @CurrentRowId; 

				IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) WHERE WOMS.WorkOrderMaterialsId = @WorkOrderMaterialsId AND WOMS.StockLineId = @WOMStockLineId) AND @WOMStockLineId > 0
				BEGIN
					-- Create Work Order Material StockLine
					EXEC [USP_CreateWorkOrderMaterialsStoclkine] @tmpWOMaterial;
				END
				ELSE 
				BEGIN
					-- Update Work Order Material StockLine
					IF(ISNULL(@WOMStockLineId, 0) > 0)
					BEGIN
						UPDATE WOMS
						SET WOMS.Quantity = TMP.StocklineQuantity,
							WOMS.ProvisionId = TMP.ProvisionId,
							WOMS.UnitCost = STK.UnitCost,
							WOMS.ExtendedCost = ISNULL(TMP.StocklineQuantity, 0) * ISNULL(STK.UnitCost, 0),
							WOMS.Figure = TMP.Figure,
							WOMS.Item = TMP.Item
						FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK)
						INNER JOIN #tmpWorkOrderMaterial TMP ON WOMS.StockLineId = TMP.StockLineId
						INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId
						WHERE TMP.RowId = @CurrentRowId AND ISNULL(STK.IsNonStock,0) = 0;
					END
				END

				SET @CurrentRowId += 1;
			END			
		END
		-- Working On Work Order Material : End

		-- Working On Work Order Material kit : Start
		SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWorkOrderMaterialKit;

		IF(ISNULL(@TotalMaterialCount, 0) > 0)
		BEGIN
			WHILE(@TotalMaterialCount >= @CurrentRowId)
			BEGIN
				SELECT @WorkOrderMaterialsId = [WorkOrderMaterialsId], @Quantity = [Quantity], @isExistingMaterilas = [isExistingMaterilas], @WOMStockLineId = [StockLineId] FROM #tmpWorkOrderMaterialKit TMP WHERE TMP.RowId = @CurrentRowId
				
				IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN #tmpWorkOrderMaterialKit TMP ON WOM.WorkOrderMaterialsKitId = TMP.WorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					UPDATE WOM
					SET WOM.Quantity = ISNULL(TMP.Quantity, 0),
						WOM.ProvisionId = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.ProvisionId ELSE WOM.ProvisionId END,
						WOM.Figure = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.Figure ELSE WOM.Figure END,
						WOM.Item = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.Item ELSE WOM.Item END
					FROM [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK)
					INNER JOIN #tmpWorkOrderMaterialKit TMP ON WOM.WorkOrderMaterialsKitId = TMP.WorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId
				END

				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND WOMS.StockLineId = @WOMStockLineId)
				BEGIN
					-- Update Work Order Material StockLine
					UPDATE WOMS
					SET	WOMS.ProvisionId = TMP.ProvisionId,			 
						WOMS.Quantity = CASE WHEN ISNULL(TMP.Quantity, 0) >= (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) THEN TMP.Quantity ELSE WOMS.Quantity END
					FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK)
					INNER JOIN #tmpWorkOrderMaterialKit TMP ON WOMS.StockLineId = TMP.StockLineId
					WHERE TMP.RowId = @CurrentRowId;
				END

				SET @CurrentRowId += 1;
			END
		END
		-- Working On Work Order Material kit : End

		IF EXISTS (SELECT 1 FROM #tmpWorkOrderMaterial)
		BEGIN
			SELECT @workOrderId = [WorkOrderId], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
			FROM #tmpWorkOrderMaterial WHERE [RowId] = @InitialRowId;
		END
		ELSE
		BEGIN
			SELECT @workOrderId = [WorkOrderId], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
			FROM #tmpWorkOrderMaterialKit WHERE [RowId] = @InitialRowId;
		END

		-- Update Work Order Material Cost Details
		EXEC [USP_UpdateWOMaterialsCost] @WorkOrderMaterialsId, @WorkFlowWorkOrderId;

		-- Update Work Order Total Cost Details
		EXEC [USP_UpdateWOTotalCostDetails] @WorkOrderId, @WorkFlowWorkOrderId, @CreatedBy, @MasterCompanyId;

		-- Update Work Order Cost Details
		EXEC [USP_UpdateWOCostDetails] @WorkOrderId, @WorkFlowWorkOrderId, @CreatedBy, @MasterCompanyId;

		-- Selecting Result
		SELECT * FROM #tmpWorkOrderMaterial

		UNION

		SELECT * FROM #tmpWorkOrderMaterialKit;
		
	COMMIT TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderMaterials'   
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