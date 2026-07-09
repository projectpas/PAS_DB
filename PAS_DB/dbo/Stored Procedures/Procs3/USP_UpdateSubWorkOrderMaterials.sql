/*************************************************************             
 ** File:   [USP_UpdateSubWorkOrderMaterials]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Create Sub work order materials
 ** Date:   28-April-2025         
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date					Author						Change Description              
 ** --   --------				-------					--------------------------------            
 ** 1    28-April-2025			Devendra Shekh				Created
 2    09/July/2026			RAJESH GAMI				[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
       
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[USP_UpdateSubWorkOrderMaterials]  
	@tbl_SubWorkOrderMaterialsType [SubWorkOrderMaterialsType] READONLY
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION  

		IF OBJECT_ID('tempdb..#tmpSubWorkOrderMaterial') IS NOT NULL
			DROP TABLE #tmpSubWorkOrderMaterial;

		IF OBJECT_ID('tempdb..#tmpSubWorkOrderMaterialKit') IS NOT NULL
			DROP TABLE #tmpSubWorkOrderMaterialKit;

		DECLARE @ProvisionId INT, @SUB_WORK_ORDER_ProvisionId INT = 3;
		DECLARE @isExistingMaterilas BIT = 0;
		DECLARE @workOrderId BIGINT = 0, @IsAutoIssue BIT = 0;
		DECLARE @TotalMaterialCount INT, @CurrentRowId INT, @InitialRowId INT = 1;		
		DECLARE @PartStatusEnumReserve INT = 1, @PartStatusEnumIssue INT = 2, @PartStatusEnumUnIssue INT = 4, @PartStatusEnumUnReserve INT = 5;
		DECLARE @Quantity INT, @WorkOrderPartNoId BIGINT, @SubWorkOrderMaterialsId BIGINT, @SubWorkOrderId BIGINT, @SubWOPartNoId BIGINT, @ItemMasterId BIGINT, @CreatedBy VARCHAR(200), @MasterCompanyId INT, @WorkOrderTypeId BIGINT, @EmployeeId BIGINT, @WOMStockLineId BIGINT;
		DECLARE @tmpSubWOMaterial [SubWorkOrderMaterialsType];

		SELECT @ProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [ProvisionId] = @SUB_WORK_ORDER_ProvisionId AND ISNULL([IsActive], 0) = 1 AND ISNULL([IsDeleted], 0) = 0;

		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, * INTO #tmpSubWorkOrderMaterial FROM @tbl_SubWorkOrderMaterialsType WHERE ISNULL(IsKitType, 0) = 0;
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, * INTO #tmpSubWorkOrderMaterialKit FROM @tbl_SubWorkOrderMaterialsType WHERE ISNULL(IsKitType, 0) = 1;	

		IF EXISTS (SELECT 1 FROM #tmpSubWorkOrderMaterial)
		BEGIN
			SELECT @workOrderId = [WorkOrderId], @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId], @SubWorkOrderId = [SubWorkOrderId], @SubWOPartNoId = [SubWOPartNoId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
			FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @InitialRowId;
		END
		ELSE
		BEGIN
			SELECT @workOrderId = [WorkOrderId], @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId], @SubWorkOrderId = [SubWorkOrderId], @SubWOPartNoId = [SubWOPartNoId], @ItemMasterId = [ItemMasterId], @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId]
			FROM #tmpSubWorkOrderMaterialKit WHERE [RowId] = @InitialRowId;
		END
		
		-- Working On Sub Work Order Material : Start
		SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpSubWorkOrderMaterial;

		UPDATE TMP
		SET TMP.PartStatusId = CASE WHEN TMP.PartStatusId = @PartStatusEnumUnIssue THEN @PartStatusEnumIssue WHEN TMP.PartStatusId = @PartStatusEnumUnReserve THEN @PartStatusEnumReserve ELSE TMP.PartStatusId END
			--,TMP.QtyToTurnIn = CASE WHEN TMP.ProvisionId = @ProvisionId THEN TMP.Quantity ELSE TMP.QtyToTurnIn END,
			--TMP.Quantity = CASE WHEN TMP.ProvisionId = @ProvisionId THEN 0 ELSE TMP.Quantity END
		FROM #tmpSubWorkOrderMaterial TMP;

		IF(ISNULL(@TotalMaterialCount, 0) > 0)
		BEGIN
			
			WHILE(@TotalMaterialCount >= @CurrentRowId)
			BEGIN
				
				SELECT @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId], @Quantity = [Quantity], @isExistingMaterilas = [isExistingMaterilas], @WOMStockLineId = [StockLineId] FROM #tmpSubWorkOrderMaterial TMP WHERE TMP.RowId = @CurrentRowId

				IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN #tmpSubWorkOrderMaterial TMP ON WOM.SubWorkOrderMaterialsId = TMP.SubWorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					UPDATE WOM
					SET --WOM.QtyToTurnIn = CASE WHEN TMP.ProvisionId = @ProvisionId THEN TMP.QtyToTurnIn ELSE WOM.QtyToTurnIn END,
						WOM.Quantity = CASE WHEN TMP.isExistingMaterilas = 1 THEN ISNULL(WOM.Quantity, 0) + ISNULL(TMP.Quantity, 0) ELSE TMP.Quantity END,
						WOM.IsDeferred = TMP.IsDeferred,
						WOM.UnitCost = TMP.UnitCost,
						--WOM.ExtendedCost = TMP.ExtendedCost,
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
					FROM [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK)
					INNER JOIN #tmpSubWorkOrderMaterial TMP ON WOM.SubWorkOrderMaterialsId = TMP.SubWorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId
				END
				ELSE
				BEGIN
					-- Savinvg New Sub Work Order Material
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
					SET	TMP.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
					FROM #tmpSubWorkOrderMaterial TMP 
					WHERE [RowId] = @CurrentRowId;
				END

				DELETE FROM @tmpSubWOMaterial;

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
				FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @CurrentRowId; 

				IF NOT EXISTS(SELECT 1 FROM [dbo].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND WOMS.StockLineId = @WOMStockLineId) AND @WOMStockLineId > 0
				BEGIN
					-- Create Sub Work Order Material StockLine
					EXEC [USP_CreateSubWorkOrderMaterialsStoclkine] @tmpSubWOMaterial;
				END
				ELSE 
				BEGIN
					-- Update Sub Work Order Material StockLine
					IF(ISNULL(@WOMStockLineId, 0) > 0)
					BEGIN
						UPDATE WOMS
						SET WOMS.Quantity = TMP.StocklineQuantity,
							WOMS.ProvisionId = TMP.ProvisionId,
							WOMS.UnitCost = STK.UnitCost,
							WOMS.ExtendedCost = ISNULL(TMP.StocklineQuantity, 0) * ISNULL(STK.UnitCost, 0),
							WOMS.Figure = TMP.Figure,
							WOMS.Item = TMP.Item
						FROM [dbo].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK)
						INNER JOIN #tmpSubWorkOrderMaterial TMP ON WOMS.StockLineId = TMP.StockLineId
						INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId
						WHERE TMP.RowId = @CurrentRowId AND ISNULL(STK.IsNonStock,0) = 0;
					END
				END

				SET @CurrentRowId += 1;
			END			
		END
		-- Working On Sub Work Order Material : End

		-- Working On Sub Work Order Material kit : Start
		SELECT @TotalMaterialCount = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpSubWorkOrderMaterialKit;

		IF(ISNULL(@TotalMaterialCount, 0) > 0)
		BEGIN
			WHILE(@TotalMaterialCount >= @CurrentRowId)
			BEGIN
				SELECT @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId], @Quantity = [Quantity], @isExistingMaterilas = [isExistingMaterilas], @WOMStockLineId = [StockLineId] FROM #tmpSubWorkOrderMaterialKit TMP WHERE TMP.RowId = @CurrentRowId
				
				IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN #tmpSubWorkOrderMaterialKit TMP ON WOM.SubWorkOrderMaterialsKitId = TMP.SubWorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					UPDATE WOM
					SET WOM.Quantity = ISNULL(TMP.Quantity, 0),
						WOM.ProvisionId = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.ProvisionId ELSE WOM.ProvisionId END,
						WOM.Figure = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.Figure ELSE WOM.Figure END,
						WOM.Item = CASE WHEN ISNULL(TMP.StockLineId, 0) = 0 THEN TMP.Item ELSE WOM.Item END
					FROM [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK)
					INNER JOIN #tmpSubWorkOrderMaterialKit TMP ON WOM.WorkOrderMaterialsKitId = TMP.SubWorkOrderMaterialsId WHERE TMP.RowId = @CurrentRowId
				END

				IF EXISTS(SELECT 1 FROM [dbo].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId AND WOMS.StockLineId = @WOMStockLineId)
				BEGIN
					-- Update Sub Work Order Material StockLine
					UPDATE WOMS
					SET	WOMS.ProvisionId = TMP.ProvisionId 
						--WOMS.Quantity = CASE WHEN ISNULL(TMP.Quantity, 0) >= (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) THEN TMP.Quantity ELSE WOMS.Quantity END
					FROM [dbo].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK)
					INNER JOIN #tmpSubWorkOrderMaterialKit TMP ON WOMS.StockLineId = TMP.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = TMP.SubWorkOrderMaterialsId
					WHERE TMP.RowId = @CurrentRowId;
				END

				SET @CurrentRowId += 1;
			END
		END
		-- Working On Sub Work Order Material kit : End

		IF EXISTS (SELECT 1 FROM #tmpSubWorkOrderMaterial)
		BEGIN
			SELECT @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId] FROM #tmpSubWorkOrderMaterial WHERE [RowId] = @InitialRowId;
		END
		ELSE
		BEGIN
			SELECT @SubWorkOrderMaterialsId = [SubWorkOrderMaterialsId] FROM #tmpSubWorkOrderMaterialKit WHERE [RowId] = @InitialRowId;
		END

		-- Update Sub Work Order Total Cost Details
		EXEC [UpdateSubWorkOrderMPNCostDetail] @WorkOrderId, @SubWorkOrderId, @SubWOPartNoId, @CreatedBy, @MasterCompanyId;

		-- Update Sub Work Order Material Cost Details
		EXEC [USP_UpdateSubWOMaterialsCost] @SubWorkOrderMaterialsId;

		-- Selecting Result
		SELECT * FROM #tmpSubWorkOrderMaterial

		UNION

		SELECT * FROM #tmpSubWorkOrderMaterialKit;
		
	COMMIT TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'USP_UpdateSubWorkOrderMaterials'   
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