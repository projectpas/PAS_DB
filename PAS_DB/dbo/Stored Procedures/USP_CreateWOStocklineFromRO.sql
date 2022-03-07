----------------------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_CreateWOStocklineFromRO]          
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Crate A Stockline from WO Materials   
 ** Purpose:         
 ** Date:   08/19/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		   Change Description            
 ** --   --------     -------		   --------------------------------          
    1    08/19/2021   Hemant Saliya    Created
    2    10/12/2021   Vishal Suthar    Reserved Added Qty
     
 EXECUTE USP_CreateWOStocklineFromRO 36

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_CreateWOStocklineFromRO]    
(    
@RepairOrderId  BIGINT  = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RowCount INT = 0;
				DECLARE @StocklineId BIGINT;
				DECLARE @TaskId INT = 0;
				DECLARE @ProvisionId INT = 0;
				DECLARE @REPAIRProvisionId INT = 0;
				DECLARE @MaterialMandatoriesId INT = 0;
				DECLARE @WorkFlowWorkOrderId BIGINT = 0;
				DECLARE @WorkOrderMaterialStockLineId BIGINT = 0;
				DECLARE @Quantity INT = 0;	
				DECLARE @StlQuantity INT = 0;
				DECLARE @QtyFulfilled INT = 0;	
				DECLARE @WorkOrderMaterialsId BIGINT = 0;
				DECLARE @ExWorkOrderMaterialsId BIGINT;
				DECLARE @ExWorkOrderMaterialStockLineId BIGINT = 0;
				DECLARE @MasterCompanyId INT;
				DECLARE @WorkOrderId BIGINT;
				DECLARE @LoopID AS INT;
				DECLARE @MasterLoopID AS INT;
				DECLARE @SubWorkOrderId BIGINT;
				DECLARE @SubWOPartNoId BIGINT;
				DECLARE @RepairOrderPartId BIGINT;
				DECLARE @PartStatusId AS INT = 1; --DEFAULT 1 FOR RESERVE

				IF OBJECT_ID(N'tempdb..#ROStockLineSamePart') IS NOT NULL
				BEGIN
				DROP TABLE #ROStockLineSamePart
				END

				IF OBJECT_ID(N'tempdb..#ROStockLineRevisedPart') IS NOT NULL
				BEGIN
				DROP TABLE #ROStockLineRevisedPart
				END

				CREATE TABLE #ROStockLineSamePart
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 ItemMasterId BIGINT NULL,
					 ConditionId BIGINT NULL,
					 StockLineId BIGINT NULL,
					 WorkOrderId BIGINT NULL,
					 SubWorkOrderId BIGINT NULL,
					 RepairOrderId BIGINT NULL,
					 MasterCompanyId INT NULL,
					 Requisitioner VARCHAR(500),
					 RepairOrderNumber VARCHAR(500) NULL
				)

				CREATE TABLE #ROStockLineRevisedPart
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 ItemMasterId BIGINT NULL,
					 ConditionId BIGINT NULL,
					 StockLineId BIGINT NULL,
					 WorkOrderId BIGINT NULL,
					 SubWorkOrderId BIGINT NULL,
					 RepairOrderId BIGINT NULL,
					 MasterCompanyId INT NULL,
					 Requisitioner VARCHAR(500),
					 RepairOrderNumber VARCHAR(500) NULL
				)

				CREATE TABLE #RepairOrderPartData
				(
				ID INT IDENTITY,
				RepairOrderPartID BIGINT
				)

				SELECT @REPAIRProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'REPAIR'
				SELECT @MaterialMandatoriesId = Id FROM dbo.MaterialMandatories WITH (NOLOCK) WHERE UPPER(Name) = 'MANDATORY'
				SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE'

				INSERT INTO #RepairOrderPartData (RepairOrderPartID) SELECT RepairOrderPartRecordId FROM dbo.RepairOrderPart RP WITH(NOLOCK) WHERE RP.RepairOrderId = @RepairOrderId AND RP.ItemTypeId=1

				SELECT  @MasterLoopID = MAX(ID) FROM #RepairOrderPartData
				WHILE(@MasterLoopID > 0)
				BEGIN
					
					IF OBJECT_ID(N'tempdb..#StockLine') IS NOT NULL
					BEGIN
					DROP TABLE #StockLine
					END

					IF OBJECT_ID(N'tempdb..#StockLineData') IS NOT NULL
					BEGIN
					DROP TABLE #StockLineData
					END

					CREATE TABLE #StockLineData
					(
					ID INT IDENTITY,
					StockLineID BIGINT
					)

					SELECT @RepairOrderPartId = RepairOrderPartID FROM #RepairOrderPartData WHERE ID  = @MasterLoopID
					SELECT @MasterCompanyId = RP.MasterCompanyId FROM dbo.RepairOrderPart RP WITH(NOLOCK) WHERE RP.RepairOrderPartRecordId = @RepairOrderPartId AND RP.ItemTypeId=1
					SELECT @TaskId = TaskId FROM dbo.Task  WITH(NOLOCK) WHERE UPPER([Description]) = 'ASSEMBLE' AND MasterCompanyId = @MasterCompanyId

					IF((SELECT COUNT(1) FROM dbo.Stockline SL WITH(NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId  AND IsParent = 1 AND Sl.QuantityAvailable > 0 AND SL.RepairOrderPartRecordId = @RepairOrderPartId) > 0)
					BEGIN
						SELECT * INTO #StockLine FROM dbo.Stockline SL WITH(NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId AND SL.RepairOrderPartRecordId = @RepairOrderPartId AND IsParent = 1 AND Sl.QuantityAvailable > 0
						INSERT INTO #StockLineData (StockLineID) SELECT StockLineID FROM #StockLine
					END

					IF((SELECT COUNT(1) FROM dbo.RepairOrderPart RP WITH(NOLOCK) WHERE  RP.ItemTypeId=1 AND RP.RepairOrderPartRecordId = @RepairOrderPartId AND ISNULL(RP.SubWorkOrderId, 0) > 0) > 0)
					BEGIN
						--#### Case (1) REPAIR ORDER For SUB WORK ORDER ---############
						SELECT @WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId, @Quantity = WOMS.Quantity, @MasterCompanyId = RP.MasterCompanyId , @WorkOrderId = WOM.WorkOrderId,
							   @SubWorkOrderId = SWO.SubWorkOrderId, @SubWOPartNoId = WOM.SubWOPartNoId
						FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
							JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
							JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId
							JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId
							JOIN dbo.WorkOrderMaterials WM WITH(NOLOCK) ON WM.WorkOrderMaterialsId = SWO.WorkOrderMaterialsId
						WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId AND WOMS.ProvisionId = @REPAIRProvisionId AND RP.ItemTypeId=1

						SET @QtyFulfilled = @Quantity;
				
						SELECT  @LoopID = MAX(ID) FROM #StockLineData
						WHILE(@LoopID > 0)
						BEGIN
							SELECT @StocklineId = StocklineId FROM #StockLineData WHERE ID  = @LoopID
							SET @StlQuantity = (SELECT ISNULL(CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 0) FROM #StockLine SL WHERE SL.StockLineId = @StocklineId)
							IF(@QtyFulfilled > 0)
							BEGIN
								IF((SELECT COUNT(1) FROM dbo.RepairOrderPart RP WITH(NOLOCK) JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId  WHERE  RP.ItemTypeId=1 AND ISNULL(RP.RevisedPartId, 0) > 0 AND SL.StockLineId = @StocklineId ) > 0)
								BEGIN
										--CASE 1 REVISED PART
										DELETE FROM #ROStockLineRevisedPart
										INSERT INTO #ROStockLineRevisedPart (ItemMasterId, ConditionId , WorkOrderId, SubWorkOrderId, RepairOrderId, Requisitioner,RepairOrderNumber, StockLineId)
										SELECT DISTINCT TOP 1 RP.RevisedPartId, RP.ConditionId , RP.WorkOrderId, RP.SubWorkOrderId, RP.RepairOrderId, RO.Requisitioner,
												RO.RepairOrderNumber, SL.StockLineId						
										FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
											JOIN dbo.ItemMaster IM ON RP.RevisedPartId = IM.ItemMasterId
											JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
											JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
										WHERE SL.StockLineId = @StocklineId AND RP.ItemTypeId=1

										SELECT @WorkOrderMaterialsId = SubWorkOrderMaterialsId FROM dbo.SubWorkOrderMaterials SOM WITH(NOLOCK) 
												JOIN #ROStockLineRevisedPart ROS ON ROS.SubWorkOrderId = SOM.SubWorkOrderId AND ROS.WorkOrderId = SOM.WorkOrderId
										WHERE ROS.ConditionId = SOM.ConditionCodeId AND ROS.ItemMasterId = SOM.ItemMasterId AND SOM.SubWOPartNoId = @SubWOPartNoId

										SET @WorkOrderMaterialsId = ISNULL(@WorkOrderMaterialsId, 0);

										IF((SELECT COUNT(1) FROM dbo.SubWorkOrderMaterials WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = ISNULL(@WorkOrderMaterialsId, 0)) = 0)
										BEGIN
											INSERT INTO dbo.SubWorkOrderMaterials (WorkOrderId, SubWorkOrderId, SubWOPartNoId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
													UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, TotalReserved, TotalIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate, 
													UpdatedBy, MasterCompanyId, IsActive, IsDeleted, PartStatusId, ReservedDate) 
											SELECT ROS.WorkOrderId, @SubWorkOrderId, @SubWOPartNoId, ROS.ItemMasterId, @TaskId, ROS.ConditionId, IM.ItemClassificationId, @StlQuantity, IM.PurchaseUnitOfMeasureId, 0, 0, 'FROM RO', 
														0, @StlQuantity, 0, @StlQuantity, 0, @MaterialMandatoriesId, @ProvisionId, GETDATE(), 'FROM RO', GETDATE(), 'FROM RO', @MasterCompanyId, 1, 0 , @PartStatusId, GETDATE()
											FROM #ROStockLineRevisedPart ROS WITH(NOLOCK) 
												JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
												JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
											WHERE SL.StockLineId = @StocklineId;

											SELECT @WorkOrderMaterialsId = SCOPE_IDENTITY()

											EXEC UpdateSubWorkOrderMaterialsColumnsWithId @SubWorkOrderMaterialsId = @WorkOrderMaterialsId;
										END
										ELSE
										BEGIN
											UPDATE dbo.SubWorkOrderMaterials 
												SET Quantity = Quantity + @StlQuantity, 
													QuantityReserved = QuantityReserved + @StlQuantity,
													TotalReserved = TotalReserved + @StlQuantity,
													UpdatedDate = GETDATE(),
													UpdatedBy = 'FROM RO'
											WHERE SubWorkOrderMaterialsId = @WorkOrderMaterialsId
										END

										UPDATE Stockline SET QuantityAvailable = QuantityAvailable - @StlQuantity,
										QuantityReserved = QuantityReserved + @StlQuantity WHERE StockLineId = @StocklineId

										INSERT INTO dbo.SubWorkOrderMaterialStockLine (SubWorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
													IsAltPart, IsEquPart, ExtendedPrice, UnitCost, UnitPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
										SELECT @WorkOrderMaterialsId, @StockLineId, SL.ItemMasterId, @ProvisionId, SL.ConditionId, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												0, 0, 0, 0, ISNULL(SL.UnitCost, 0), ISNULL(SL.UnitCost, 0), GETDATE(), SL.UpdatedBy, GETDATE(), SL.UpdatedBy, @MasterCompanyId, 1, 0 
										FROM #ROStockLineRevisedPart ROS WITH(NOLOCK) 
											JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
											JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
										WHERE SL.StockLineId = @StocklineId AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @WorkOrderMaterialsId);

										SELECT @WorkOrderMaterialStockLineId = SCOPE_IDENTITY()

										UPDATE dbo.SubWorkOrderMaterialStockLine SET ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity, 0) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId

										SET @QtyFulfilled =  @QtyFulfilled - (SELECT SUM(ISNULL(Quantity,0)) FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE RepairOrderId = @RepairOrderId)

										SELECT @ExWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId, @ExWorkOrderMaterialStockLineId = WOMS.SWOMStockLineId
										FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK)
											JOIN dbo.RepairOrderPart RP WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
											JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId
										WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId AND WOM.SubWorkOrderId = @SubWorkOrderId AND WOM.WorkOrderId = @WorkOrderId AND RP.ItemTypeId=1

										IF(@QtyFulfilled <= 0)
										BEGIN
											DELETE WOMS FROM dbo.SubWorkOrderMaterialStockLine WOMS WHERE WOMS.SWOMStockLineId = @ExWorkOrderMaterialStockLineId;
										END
										ELSE
										BEGIN
											UPDATE dbo.SubWorkOrderMaterialStockLine SET Quantity = Quantity - @StlQuantity WHERE SWOMStockLineId = @ExWorkOrderMaterialStockLineId;
										END

										IF((SELECT COUNT(1) FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @ExWorkOrderMaterialsId) = 0)
										BEGIN
											DELETE WOM FROM dbo.SubWorkOrderMaterials WOM WHERE WOM.SubWorkOrderMaterialsId = @ExWorkOrderMaterialsId;
										END

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE MATERIALS COST
										EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @WorkOrderMaterialsId;

									END
								ELSE
								BEGIN
									--CASE 2 SAME AS PART
									INSERT INTO #ROStockLineSamePart(ItemMasterId, ConditionId , WorkOrderId, SubWorkOrderId, RepairOrderId, Requisitioner,RepairOrderNumber, StockLineId)
									SELECT DISTINCT TOP 1 RP.ItemMasterId, RP.ConditionId , RP.WorkOrderId, RP.SubWorkOrderId, RP.RepairOrderId, RO.Requisitioner,
											RO.RepairOrderNumber, SL.StockLineId
									FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
										JOIN dbo.ItemMaster IM ON RP.ItemMasterId = IM.ItemMasterId
										JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
										JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
									WHERE SL.StockLineId = @StocklineId  AND RP.ItemTypeId=1

									IF((SELECT COUNT(1) FROM #ROStockLineSamePart WITH(NOLOCK) WHERE ISNULL(WorkOrderId, 0) > 0 ) > 0)
									BEGIN
										SELECT @ExWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId, @ExWorkOrderMaterialStockLineId = WOMS.SWOMStockLineId
										FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK)
											JOIN dbo.RepairOrderPart RP WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
											JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId
										WHERE RP.RepairOrderId = @RepairOrderId AND WOM.SubWorkOrderId = @SubWorkOrderId AND WOM.WorkOrderId = @WorkOrderId AND RP.ItemTypeId=1

										INSERT INTO dbo.SubWorkOrderMaterialStockLine (SubWorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
												IsAltPart, IsEquPart, ExtendedPrice, UnitCost, UnitPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
										SELECT @ExWorkOrderMaterialsId, @StockLineId, SL.ItemMasterId, @ProvisionId, SL.ConditionId, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												0, 0, 0, 0, ISNULL(SL.UnitCost, 0), ISNULL(SL.UnitCost, 0), GETDATE(), SL.UpdatedBy, GETDATE(), SL.UpdatedBy, Sl.MasterCompanyId, 1, 0 
										FROM #ROStockLineSamePart ROS WITH(NOLOCK) 
											JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
											JOIN dbo.ItemMaster IM WITH(NOLOCK)  ON SL.ItemMasterId = IM.ItemMasterId
										WHERE SL.StockLineId = @StocklineId AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @ExWorkOrderMaterialsId);

										SELECT @WorkOrderMaterialStockLineId = SCOPE_IDENTITY()

										UPDATE dbo.SubWorkOrderMaterialStockLine SET ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity, 0) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId

										UPDATE dbo.SubWorkOrderMaterials 
											SET QuantityReserved = QuantityReserved + @StlQuantity, 
												TotalReserved = TotalReserved + @StlQuantity,
												UpdatedDate = GETDATE()
										WHERE SubWorkOrderMaterialsId = @ExWorkOrderMaterialsId

										UPDATE Stockline SET QuantityAvailable = QuantityAvailable - @StlQuantity,
										QuantityReserved = QuantityReserved + @StlQuantity WHERE StockLineId = @StocklineId

										SET @QtyFulfilled =  @QtyFulfilled - (SELECT Quantity FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId)

										IF(@QtyFulfilled <= 0)
										BEGIN
											DELETE WOMS FROM dbo.SubWorkOrderMaterialStockLine WOMS WHERE WOMS.SWOMStockLineId = @ExWorkOrderMaterialStockLineId;
										END
										ELSE
										BEGIN
											UPDATE dbo.SubWorkOrderMaterialStockLine SET Quantity = Quantity - @StlQuantity  WHERE SWOMStockLineId = @ExWorkOrderMaterialStockLineId;
										END

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE MATERIALS COST
										EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @WorkOrderMaterialsId;
									END
								END
							END
							SET @LoopID = @LoopID - 1;
						END 
					END
					ELSE
					BEGIN
						--# Case (2) REPAIRE ORDER For WORK ORDER
						SELECT @WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId, @Quantity = WOMS.Quantity, @MasterCompanyId = RP.MasterCompanyId , @WorkOrderId = WOM.WorkOrderId
						FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
							JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
						WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId AND WOMS.ProvisionId = @REPAIRProvisionId AND RP.ItemTypeId=1

						SET @QtyFulfilled = @Quantity;
				
						SELECT  @LoopID = MAX(ID) FROM #StockLineData
						WHILE(@LoopID > 0)
						BEGIN
							SELECT @StocklineId = StocklineId FROM #StockLineData WHERE ID  = @LoopID
							SET @StlQuantity = (SELECT ISNULL(CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 0) FROM #StockLine SL WHERE SL.StockLineId = @StocklineId)
							IF(@QtyFulfilled > 0)
							BEGIN
								IF((SELECT COUNT(1) FROM dbo.RepairOrderPart RP WITH(NOLOCK) JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId  WHERE  RP.ItemTypeId=1 AND ISNULL(RP.RevisedPartId, 0) > 0 AND SL.StockLineId = @StocklineId ) > 0)
								BEGIN
										--CASE 1 REVISED PART
										DELETE FROM #ROStockLineRevisedPart
										INSERT INTO #ROStockLineRevisedPart (ItemMasterId, ConditionId , WorkOrderId, SubWorkOrderId, RepairOrderId, Requisitioner,RepairOrderNumber, StockLineId)
										SELECT DISTINCT TOP 1 RP.RevisedPartId, RP.ConditionId , RP.WorkOrderId, RP.SubWorkOrderId, RP.RepairOrderId, RO.Requisitioner,
												RO.RepairOrderNumber, SL.StockLineId						
										FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
											JOIN dbo.ItemMaster IM ON RP.RevisedPartId = IM.ItemMasterId
											JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
											JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
										WHERE SL.StockLineId = @StocklineId  AND RP.ItemTypeId=1

										SET @WorkOrderMaterialsId = 0;
										SELECT @WorkOrderMaterialsId = ISNULL(WorkOrderMaterialsId, 0) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 
												JOIN #ROStockLineRevisedPart ROS ON ROS.WorkOrderId = WOM.WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
										WHERE ROS.ConditionId = WOM.ConditionCodeId AND ROS.ItemMasterId = WOM.ItemMasterId

										SET @WorkOrderMaterialsId = ISNULL(@WorkOrderMaterialsId, 0);
						
										IF((SELECT COUNT(1) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = ISNULL(@WorkOrderMaterialsId, 0)) = 0)
										BEGIN
											INSERT INTO dbo.WorkOrderMaterials (WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
													UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, TotalReserved, TotalIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate, 
													UpdatedBy, MasterCompanyId, IsActive, IsDeleted, PartStatusId, ReservedDate) 
											SELECT ROS.WorkOrderId, @WorkFlowWorkOrderId, ROS.ItemMasterId, @TaskId, ROS.ConditionId, IM.ItemClassificationId, @StlQuantity, IM.PurchaseUnitOfMeasureId, 0, 0, 'FROM RO', 
														0, @StlQuantity, 0, 0, @StlQuantity, @MaterialMandatoriesId, @ProvisionId, GETDATE(), 'FROM RO', GETDATE(), 'FROM RO', @MasterCompanyId, 1, 0 , @PartStatusId, GETDATE()
											FROM #ROStockLineRevisedPart ROS WITH(NOLOCK) 
												JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
												JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
											WHERE SL.StockLineId = @StocklineId;

											SELECT @WorkOrderMaterialsId = SCOPE_IDENTITY()
										END
										ELSE
										BEGIN
											UPDATE dbo.WorkOrderMaterials 
												SET Quantity = Quantity + @StlQuantity, 
													QuantityReserved = QuantityReserved + @StlQuantity,
													TotalReserved = TotalReserved + @StlQuantity,
													UpdatedDate = GETDATE(),
													UpdatedBy = 'FROM RO'
											WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
										END

										UPDATE Stockline SET QuantityAvailable = QuantityAvailable - @StlQuantity,
										QuantityReserved = QuantityReserved + @StlQuantity
										WHERE StockLineId = @StocklineId

										INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, RepairOrderId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
													IsAltPart, IsEquPart, ExtendedPrice, UnitCost, UnitPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
										SELECT @WorkOrderMaterialsId, @RepairOrderId, @StockLineId, SL.ItemMasterId, @ProvisionId, SL.ConditionId, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												0, 0, 0, 0, ISNULL(SL.UnitCost, 0), ISNULL(SL.UnitCost, 0), GETDATE(), SL.UpdatedBy, GETDATE(), SL.UpdatedBy, @MasterCompanyId, 1, 0 
										FROM #ROStockLineRevisedPart ROS WITH(NOLOCK) 
											JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
											JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
										WHERE SL.StockLineId = @StocklineId AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.WorkOrderMaterialStockLine WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId);

										SELECT @WorkOrderMaterialStockLineId = SCOPE_IDENTITY()

										UPDATE dbo.WorkOrderMaterialStockLine SET ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity, 0) WHERE WOMStockLineId = @WorkOrderMaterialStockLineId

										SET @QtyFulfilled =  @QtyFulfilled - (SELECT SUM(ISNULL(Quantity,0)) FROM dbo.WorkOrderMaterialStockLine WITH(NOLOCK) WHERE RepairOrderId = @RepairOrderId)

										SELECT @ExWorkOrderMaterialsId = WOM.WorkOrderMaterialsId, @ExWorkOrderMaterialStockLineId = WOMS.WOMStockLineId
										FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK)
											JOIN dbo.RepairOrderPart RP WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
											JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
										WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.WorkOrderId = @WorkOrderId AND RP.ItemTypeId=1

										IF(@QtyFulfilled <= 0)
										BEGIN
											DELETE WOMS FROM dbo.WorkOrderMaterialStockLine WOMS WHERE WOMS.WOMStockLineId = @ExWorkOrderMaterialStockLineId;
										END
										ELSE
										BEGIN
											UPDATE dbo.WorkOrderMaterialStockLine SET Quantity = Quantity - @StlQuantity WHERE WOMStockLineId = @ExWorkOrderMaterialStockLineId; 
										END

										IF((SELECT COUNT(1) FROM dbo.WorkOrderMaterialStockLine WITH(NOLOCK) WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId) = 0)
										BEGIN
											DELETE WOM FROM dbo.WorkOrderMaterials WOM WHERE WOM.WorkOrderMaterialsId = @ExWorkOrderMaterialsId;
										END

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE MATERIALS COST
										EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @WorkOrderMaterialsId;

									END
								ELSE
								BEGIN
									--CASE 2 SAME AS PART
									INSERT INTO #ROStockLineSamePart(ItemMasterId, ConditionId , WorkOrderId, SubWorkOrderId, RepairOrderId, Requisitioner,RepairOrderNumber, StockLineId)
									SELECT DISTINCT TOP 1 RP.ItemMasterId, RP.ConditionId , RP.WorkOrderId, RP.SubWorkOrderId, RP.RepairOrderId, RO.Requisitioner,
											RO.RepairOrderNumber, SL.StockLineId
									FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
										JOIN dbo.ItemMaster IM ON RP.ItemMasterId = IM.ItemMasterId
										JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
										JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
									WHERE SL.StockLineId = @StocklineId AND RP.ItemTypeId=1

									IF((SELECT COUNT(1) FROM #ROStockLineSamePart WITH(NOLOCK) WHERE ISNULL(WorkOrderId, 0) > 0 ) > 0)
									BEGIN
										DECLARE @OldConditionId BIGINT = 0;
										DECLARE @NewConditionId BIGINT = 0;
										DECLARE @NewWorkOrderMaterialsId BIGINT = 0;
										DECLARE @NewProvisionId BIGINT = 0;
										DECLARE @UnitCost DECIMAL(20, 2) = 0;

										SELECT @ExWorkOrderMaterialsId = WOM.WorkOrderMaterialsId, @ExWorkOrderMaterialStockLineId = WOMS.WOMStockLineId
										FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK)
											JOIN dbo.RepairOrderPart RP WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
											JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
										WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.WorkOrderId = @WorkOrderId AND RP.ItemTypeId=1

										INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, RepairOrderId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
												IsAltPart, IsEquPart, ExtendedPrice, UnitCost, UnitPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
										SELECT @ExWorkOrderMaterialsId, @RepairOrderId, @StockLineId, SL.ItemMasterId, @ProvisionId, SL.ConditionId, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
												0, 0, 0, 0, ISNULL(SL.UnitCost, 0), ISNULL(SL.UnitCost, 0), GETDATE(), SL.UpdatedBy, GETDATE(), SL.UpdatedBy, Sl.MasterCompanyId, 1, 0 
										FROM #ROStockLineSamePart ROS WITH(NOLOCK) 
											JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
											JOIN dbo.ItemMaster IM WITH(NOLOCK)  ON SL.ItemMasterId = IM.ItemMasterId
										WHERE SL.StockLineId = @StocklineId AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.WorkOrderMaterialStockLine WITH(NOLOCK) WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId);

										SELECT @OldConditionId = ConditionCodeId FROM dbo.WorkOrderMaterials WITH (NOLOCK) WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId
										SELECT @NewConditionId = ConditionId FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId

										SELECT @WorkOrderMaterialStockLineId = SCOPE_IDENTITY()

										UPDATE dbo.WorkOrderMaterialStockLine SET ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity, 0) WHERE WOMStockLineId = @WorkOrderMaterialStockLineId

										IF (@OldConditionId = @NewConditionId)
										BEGIN
											UPDATE dbo.WorkOrderMaterials 
												SET QuantityReserved = QuantityReserved + @StlQuantity, 
													TotalReserved = TotalReserved + @StlQuantity,
													UpdatedDate = GETDATE()
											WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId
										END

										UPDATE Stockline SET QuantityAvailable = QuantityAvailable - @StlQuantity,
										QuantityReserved = QuantityReserved + @StlQuantity WHERE StockLineId = @StocklineId

										SET @QtyFulfilled =  @QtyFulfilled - (SELECT SUM(ISNULL(Quantity,0)) FROM dbo.WorkOrderMaterialStockLine WITH(NOLOCK) WHERE RepairOrderId = @RepairOrderId) 

										IF(@QtyFulfilled <= 0)
										BEGIN
											DELETE WOMS FROM dbo.WorkOrderMaterialStockLine WOMS WHERE WOMS.WOMStockLineId = @ExWorkOrderMaterialStockLineId;

											IF (@OldConditionId <> @NewConditionId)
											BEGIN
												UPDATE dbo.WorkOrderMaterials SET ConditionCodeId = @NewConditionId WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId
											END
										END
										ELSE
										BEGIN
											UPDATE dbo.WorkOrderMaterialStockLine SET Quantity = Quantity - @StlQuantity, ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity - @StlQuantity, 0) WHERE WOMStockLineId = @ExWorkOrderMaterialStockLineId

											IF (@OldConditionId <> @NewConditionId)
											BEGIN
												INSERT INTO [dbo].[WorkOrderMaterials]
												   ([WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
												   [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred], [QuantityReserved],
												   [QuantityIssued], [IssuedDate], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [UnReservedQty], [UnIssuedQty],
												   [IssuedById], [ReservedById], [IsEquPart], [ParentWorkOrderMaterialsId], [ItemMappingId], [TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued],
												   [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder], [QtyOnBkOrder], [POId], [PONum], [PONextDlvrDate])
												SELECT [WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
												   [TaskId], @NewConditionId, [ItemClassificationId], @StlQuantity, [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDeferred], [QuantityReserved],
												   [QuantityIssued], [IssuedDate], [ReservedDate], [IsAltPart], [AltPartMasterPartId], [IsFromWorkFlow], [PartStatusId], [UnReservedQty], [UnIssuedQty],
												   [IssuedById], [ReservedById], [IsEquPart], [ParentWorkOrderMaterialsId], [ItemMappingId], [TotalReserved], [TotalIssued], [TotalUnReserved], [TotalUnIssued],
												   [ProvisionId], [MaterialMandatoriesId], [WOPartNoId], [TotalStocklineQtyReq], [QtyOnOrder], [QtyOnBkOrder], [POId], [PONum], [PONextDlvrDate]
												FROM dbo.WorkOrderMaterials WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId
												
												SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()
												
												UPDATE dbo.WorkOrderMaterialStockLine
												SET WorkOrderMaterialsId = @NewWorkOrderMaterialsId
												WHERE WOMStockLineId = @WorkOrderMaterialStockLineId

												SELECT @UnitCost = UnitCost, @NewProvisionId = ProvisionId FROM dbo.WorkOrderMaterialStockLine WHERE WOMStockLineId = @WorkOrderMaterialStockLineId

												UPDATE [dbo].[WorkOrderMaterials]
												SET Quantity = Quantity - @StlQuantity,
												ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity - @StlQuantity, 0),
												UpdatedDate = GETDATE()
												WHERE WorkOrderMaterialsId = @ExWorkOrderMaterialsId

												UPDATE [dbo].[WorkOrderMaterials]
												SET Quantity = @StlQuantity,
												QuantityReserved = QuantityReserved + @StlQuantity,
												TotalReserved = TotalReserved + @StlQuantity,
												UnitCost = @UnitCost,
												ExtendedCost = ISNULL(@UnitCost, 0) * ISNULL(@StlQuantity, 0),
												ProvisionId = @NewProvisionId,
												UpdatedDate = GETDATE()
												WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
											END
										END

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE WO PART LEVEL TOTAL COST
										EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkFlowWorkOrderId, @UpdatedBy = 'Admin' ;

										--UPDATE MATERIALS COST
										EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @WorkOrderMaterialsId;
									END
								END
							END
							SET @LoopID = @LoopID - 1;
						END 
					END

					SET @MasterLoopID = @MasterLoopID - 1;
				END

				IF OBJECT_ID(N'tempdb..#ROStockLineSamePart') IS NOT NULL
				BEGIN
				DROP TABLE #ROStockLineSamePart
				END

				IF OBJECT_ID(N'tempdb..#ROStockLineRevisedPart') IS NOT NULL
				BEGIN
				DROP TABLE #ROStockLineRevisedPart
				END

				IF OBJECT_ID(N'tempdb..#StockLine') IS NOT NULL
				BEGIN
				DROP TABLE #StockLine
				END
				
				IF OBJECT_ID(N'tempdb..#StockLineData') IS NOT NULL
				BEGIN
				DROP TABLE #StockLineData
				END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateWOStocklineFromRO' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@RepairOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END