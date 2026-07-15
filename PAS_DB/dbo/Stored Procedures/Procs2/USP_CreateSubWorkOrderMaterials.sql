-- ===== PROCEDURE: [dbo].[USP_CreateSubWorkOrderMaterials]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_CreateSubWorkOrderMaterials.sql) =====
/*************************************************************             
 ** File:   [USP_CreateSubWorkOrderMaterials]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Create Sub work order materials
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
  
CREATE   PROCEDURE [dbo].[USP_CreateSubWorkOrderMaterials]  
	@tbl_SubWorkOrderMaterialsType [SubWorkOrderMaterialsType] READONLY
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION  

		IF OBJECT_ID('tempdb..#tmpSubWorkOrderMaterial') IS NOT NULL
			DROP TABLE #tmpSubWorkOrderMaterial;

		DECLARE @isExistingMaterilas BIT = 0;
		DECLARE @workOrderId BIGINT = 0;
		DECLARE @TotalMaterialCount INT, @CurrentRowId INT, @InitialRowId INT = 1;		
		DECLARE @Quantity INT, @WorkOrderPartNoId BIGINT, @SubWorkOrderMaterialsId BIGINT, @SubWorkOrderId BIGINT, @SubWOPartNoId BIGINT, @ItemMasterId BIGINT, @CreatedBy VARCHAR(200), @MasterCompanyId INT, @WorkOrderTypeId BIGINT, @EmployeeId BIGINT, @WOMStockLineId BIGINT;
		DECLARE @ProvisionId INT, @SUB_WORK_ORDER_ProvisionId INT = 3;
		DECLARE @tmpSubWOMaterial [SubWorkOrderMaterialsType];
		DECLARE @tmpStkSubWOMaterial [SubWorkOrderMaterialsType];

		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, * INTO #tmpSubWorkOrderMaterial FROM @tbl_SubWorkOrderMaterialsType;

		SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpSubWorkOrderMaterial;
		
		IF(ISNULL(@TotalMaterialCount, 0) > 0)
		BEGIN
			WHILE(@TotalMaterialCount >= @CurrentRowId)
			BEGIN
				
				IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN #tmpSubWorkOrderMaterial TMP ON WOM.ItemMasterId = TMP.ItemMasterId AND WOM.ConditionCodeId = TMP.ConditionCodeId 
						AND WOM.TaskId = TMP.TaskId AND ISNULL(WOM.Item, '') = ISNULL(TMP.Item, '') AND ISNULL(WOM.Figure, '') = ISNULL(TMP.Figure, '') AND WOM.SubWOPartNoId = TMP.SubWOPartNoId AND WOM.WorkOrderId = TMP.WorkOrderId
						WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					UPDATE TMP
					SET TMP.SubWorkOrderMaterialsId = (SELECT TOP 1 WOM.SubWorkOrderMaterialsId FROM [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN #tmpSubWorkOrderMaterial TMP ON WOM.ItemMasterId = TMP.ItemMasterId AND WOM.ConditionCodeId = TMP.ConditionCodeId 
												AND WOM.TaskId = TMP.TaskId AND ISNULL(WOM.Item, '') = ISNULL(TMP.Item, '') AND ISNULL(WOM.Figure, '') = ISNULL(TMP.Figure, '') AND WOM.SubWOPartNoId = TMP.SubWOPartNoId AND WOM.WorkOrderId = TMP.WorkOrderId),
						TMP.isExistingMaterilas = 1
					FROM #tmpSubWorkOrderMaterial TMP WHERE TMP.RowId = @CurrentRowId

					SET @isExistingMaterilas = 1
				END

				SET @CurrentRowId += 1;
			END			
		END

		SELECT @workOrderId = [WorkOrderId], @Quantity = [Quantity], @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId], @SubWorkOrderId = [SubWorkOrderId], @SubWOPartNoId = [SubWOPartNoId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
		FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @InitialRowId;
		
		IF(ISNULL(@isExistingMaterilas, 0) = 1)
		BEGIN
			INSERT INTO @tmpSubWOMaterial ([SubWorkOrderMaterialsId], [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], 
				[UnitOfMeasureId], [UnitCost], [ExtendedCost], [Price], [ExtendedPrice], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate],
				[IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [IssuedById], [ReservedById], [IsEquPart], [ParentSubWorkOrderMaterialsId], [ItemMappingId], 
				[TotalReserved], [TotalIssued], [ProvisionId], [MaterialMandatoriesId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],
				[QuantityTurnIn], [Condition], [UOM], [ItemClassification], [Provision], [TaskName], [Site], [WareHouse], [Locations], [Shelf], [Bin], [TotalStocklineQtyReq], 
				[POId], [PONum], [PONextDlvrDate], [QtyOnOrder], [QtyOnBkOrder], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [UnReservedQty], [UnIssuedQty],
				[TotalUnIssued], [TotalUnReserved], [StockLineId], [StocklineQuantity], [IsStocklineEdit], [isExistingMaterilas], [IsAlternatePart], [IsKitType], [KitId] )
			SELECT [SubWorkOrderMaterialsId], [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], 
				[UnitOfMeasureId], [UnitCost], [ExtendedCost], [Price], [ExtendedPrice], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate],
				[IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [IssuedById], [ReservedById], [IsEquPart], [ParentSubWorkOrderMaterialsId], [ItemMappingId], 
				[TotalReserved], [TotalIssued], [ProvisionId], [MaterialMandatoriesId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],
				[QuantityTurnIn], [Condition], [UOM], [ItemClassification], [Provision], [TaskName], [Site], [WareHouse], [Locations], [Shelf], [Bin], [TotalStocklineQtyReq], 
				[POId], [PONum], [PONextDlvrDate], [QtyOnOrder], [QtyOnBkOrder], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [UnReservedQty], [UnIssuedQty],
				[TotalUnIssued], [TotalUnReserved], [StockLineId], [StocklineQuantity], [IsStocklineEdit], [isExistingMaterilas], [IsAlternatePart], [IsKitType], [KitId] 
			FROM #tmpSubWorkOrderMaterial; 

			EXEC [USP_UpdateSubWorkOrderMaterials] @tmpSubWOMaterial;
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
			FROM #tmpSubWorkOrderMaterial TMP
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
			 AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [dbo].[StockLine] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0

			SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpSubWorkOrderMaterial;

			IF(ISNULL(@TotalMaterialCount, 0) > 0)
			BEGIN
				WHILE(@TotalMaterialCount >= @CurrentRowId)
				BEGIN
					INSERT INTO [dbo].[SubWorkOrderMaterials] ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost],
						[Price], [ExtendedPrice], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [IssuedById],
						[ReservedById], [IsEquPart], [ParentSubWorkOrderMaterialsId], [ItemMappingId], [TotalReserved], [TotalIssued], [ProvisionId], [MaterialMandatoriesId], [MasterCompanyId], [CreatedBy], [UpdatedBy], 
						[CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [QuantityTurnIn], [Condition], [UOM], [ItemClassification], [Provision], [TaskName], [Site], [WareHouse], [Locations], [Shelf], [Bin], 
						[TotalStocklineQtyReq], [POId], [PONum], [PONextDlvrDate], [QtyOnOrder], [QtyOnBkOrder], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [UnReservedQty], [UnIssuedQty], [TotalUnIssued], [TotalUnReserved])
					SELECT [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost],
						[Price], [ExtendedPrice], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [IssuedById],
						[ReservedById], [IsEquPart], [ParentSubWorkOrderMaterialsId], [ItemMappingId], [TotalReserved], [TotalIssued], [ProvisionId], [MaterialMandatoriesId], [MasterCompanyId], [CreatedBy], [UpdatedBy], 
						[CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [QuantityTurnIn], [Condition], [UOM], [ItemClassification], [Provision], [TaskName], [Site], [WareHouse], [Locations], [Shelf], [Bin], 
						[TotalStocklineQtyReq], [POId], [PONum], [PONextDlvrDate], [QtyOnOrder], [QtyOnBkOrder], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [UnReservedQty], [UnIssuedQty], [TotalUnIssued], [TotalUnReserved]
					FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @CurrentRowId;

					SET @SubWorkOrderMaterialsId = SCOPE_IDENTITY();			
					
					UPDATE TMP
					SET	TMP.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId,
						TMP.UnitOfMeasureId = CASE WHEN ISNULL(TMP.UnitOfMeasureId, 0) = 0 THEN CASE WHEN ISNULL(TMP.StockLineId, 0) > 0 THEN STK.PurchaseUnitOfMeasureId ELSE IM.PurchaseUnitOfMeasureId END ELSE TMP.UnitOfMeasureId END
					FROM #tmpSubWorkOrderMaterial TMP 
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[StockLine] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0
					WHERE [RowId] = @CurrentRowId;
					
					SELECT @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId], @WOMStockLineId = [StockLineId] FROM #tmpSubWorkOrderMaterial TMP WHERE TMP.RowId = @CurrentRowId
					
					IF(ISNULL(@WOMStockLineId, 0) > 0)
					BEGIN
						DELETE FROM @tmpStkSubWOMaterial;
						
						INSERT INTO @tmpStkSubWOMaterial ([SubWorkOrderMaterialsId], [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], 
							[UnitOfMeasureId], [UnitCost], [ExtendedCost], [Price], [ExtendedPrice], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate],
							[IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [IssuedById], [ReservedById], [IsEquPart], [ParentSubWorkOrderMaterialsId], [ItemMappingId], 
							[TotalReserved], [TotalIssued], [ProvisionId], [MaterialMandatoriesId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],
							[QuantityTurnIn], [Condition], [UOM], [ItemClassification], [Provision], [TaskName], [Site], [WareHouse], [Locations], [Shelf], [Bin], [TotalStocklineQtyReq], 
							[POId], [PONum], [PONextDlvrDate], [QtyOnOrder], [QtyOnBkOrder], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [UnReservedQty], [UnIssuedQty],
							[TotalUnIssued], [TotalUnReserved], [StockLineId], [StocklineQuantity], [IsStocklineEdit], [isExistingMaterilas], [IsAlternatePart], [IsKitType], [KitId] )
						SELECT [SubWorkOrderMaterialsId], [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], 
							[UnitOfMeasureId], [UnitCost], [ExtendedCost], [Price], [ExtendedPrice], [Memo], [IsDeferred], [QuantityReserved], [QuantityIssued], [IssuedDate], [ReservedDate],
							[IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [IssuedById], [ReservedById], [IsEquPart], [ParentSubWorkOrderMaterialsId], [ItemMappingId], 
							[TotalReserved], [TotalIssued], [ProvisionId], [MaterialMandatoriesId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],
							[QuantityTurnIn], [Condition], [UOM], [ItemClassification], [Provision], [TaskName], [Site], [WareHouse], [Locations], [Shelf], [Bin], [TotalStocklineQtyReq], 
							[POId], [PONum], [PONextDlvrDate], [QtyOnOrder], [QtyOnBkOrder], [QtyToTurnIn], [Figure], [Item], [EquPartMasterPartId], [UnReservedQty], [UnIssuedQty],
							[TotalUnIssued], [TotalUnReserved], [StockLineId], [StocklineQuantity], [IsStocklineEdit], [isExistingMaterilas], [IsAlternatePart], [IsKitType], [KitId] 
						FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @CurrentRowId; 
						
						-- Create Sub Work Order Material StockLine
						EXEC [USP_CreateSubWorkOrderMaterialsStoclkine] @tmpStkSubWOMaterial;
					END

					SET @CurrentRowId += 1;
				END			
			END
			
			SELECT @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId] FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @InitialRowId;

			-- Update Sub Work Order Total Cost Details
			EXEC [UpdateSubWorkOrderMPNCostDetail] @WorkOrderId, @SubWorkOrderId, @SubWOPartNoId, @CreatedBy, @MasterCompanyId;
			
			-- Update Sub Work Order Material Cost Details
			EXEC [USP_UpdateSubWOMaterialsCost] @SubWorkOrderMaterialsId;

			-- Selecting Result
			SELECT * FROM #tmpSubWorkOrderMaterial;
		END		
   
	COMMIT TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'USP_CreateSubWorkOrderMaterials'   
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