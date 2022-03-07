-------------------------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_CreateSubWOStocklineFromRO]          
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Crate A Stockline from Sub WO Materials   
 ** Purpose:         
 ** Date:   08/19/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/19/2021   Hemant Saliya Created
     
 EXECUTE USP_CreateSubWOStocklineFromRO 134

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_CreateSubWOStocklineFromRO]    
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
				DECLARE @QtyFulfilled INT = 0;	
				DECLARE @WorkOrderMaterialsId BIGINT = 0;
				DECLARE @ExWorkOrderMaterialsId BIGINT;
				DECLARE @ExWorkOrderMaterialStockLineId BIGINT = 0;
				DECLARE @MasterCompanyId INT;
				DECLARE @WorkOrderId BIGINT;
				DECLARE @LoopID AS INT 
				DECLARE @SubWorkOrderId BIGINT;
				DECLARE @SubWOPartNoId BIGINT;

				SELECT @REPAIRProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'REPAIR'
				SELECT @MaterialMandatoriesId = Id FROM dbo.MaterialMandatories WITH (NOLOCK) WHERE UPPER(Name) = 'MANDATORY'
				SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE'

				SELECT @WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId, @Quantity = WOMS.Quantity, @MasterCompanyId = RP.MasterCompanyId , @WorkOrderId = WOM.WorkOrderId,
						@SubWorkOrderId = SWO.SubWorkOrderId, @SubWOPartNoId = WOM.SubWOPartNoId
				FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
					JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
					JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId
					JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId
					JOIN dbo.WorkOrderMaterials WM WITH(NOLOCK) ON WM.WorkOrderMaterialsId = SWO.WorkOrderMaterialsId
				WHERE RP.RepairOrderId = @RepairOrderId AND WOMS.ProvisionId = @REPAIRProvisionId AND RP.ItemTypeId=1

				SET @QtyFulfilled = @Quantity;

				SELECT @TaskId = TaskId FROM dbo.Task  WITH(NOLOCK) WHERE UPPER([Description]) = 'ASSEMBLE' AND MasterCompanyId = @MasterCompanyId

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

				CREATE TABLE #StockLineData
				(
				ID INT IDENTITY,
				StockLineID BIGINT
				)

				SELECT * INTO #StockLine
				FROM dbo.Stockline SL WITH(NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId AND IsParent = 1 AND Sl.QuantityAvailable > 0

				INSERT INTO #StockLineData (StockLineID) SELECT StockLineID FROM #StockLine
				
				SELECT  @LoopID = MAX(ID) FROM #StockLineData
				WHILE(@LoopID > 0)
				BEGIN
					SELECT @StocklineId = StocklineId FROM #StockLineData WHERE ID  = @LoopID
					PRINT @StocklineId; 
					IF(@QtyFulfilled > 0)
					BEGIN
						IF((SELECT COUNT(1) FROM dbo.RepairOrderPart RP WITH(NOLOCK) JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId  WHERE RP.ItemTypeId=1 AND ISNULL(RP.RevisedPartId, 0) > 0 AND SL.StockLineId = @StocklineId ) > 0)
						BEGIN
								--CASE 1 REVISED PART
								INSERT INTO #ROStockLineRevisedPart (ItemMasterId, ConditionId , WorkOrderId, SubWorkOrderId, RepairOrderId, Requisitioner,RepairOrderNumber, StockLineId)
								SELECT DISTINCT TOP 1 RP.ItemMasterId, RP.ConditionId , RP.WorkOrderId, RP.SubWorkOrderId, RP.RepairOrderId, RO.Requisitioner,
										RO.RepairOrderNumber, SL.StockLineId						
								FROM dbo.RepairOrderPart RP WITH(NOLOCK) 
									JOIN dbo.ItemMaster IM ON RP.RevisedPartId = IM.ItemMasterId
									JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
									JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
								WHERE SL.StockLineId = @StocklineId  AND RP.ItemTypeId=1
						
								IF((SELECT COUNT(1) FROM dbo.SubWorkOrderMaterials WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = ISNULL(@WorkOrderMaterialsId, 0)) = 0)
								BEGIN
									INSERT INTO dbo.SubWorkOrderMaterials (WorkOrderId, SubWorkOrderId, SubWOPartNoId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
											UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate, 
											UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
									SELECT ROS.WorkOrderId, @SubWorkOrderId, @SubWOPartNoId, ROS.ItemMasterId, @TaskId, ROS.ConditionId, IM.ItemClassificationId, @Quantity, IM.PurchaseUnitOfMeasureId, 0, 0, 'FROM RO', 
												0, 0, 0, @MaterialMandatoriesId, @ProvisionId, GETDATE(), 'FROM RO', GETDATE(), 'FROM RO', @MasterCompanyId, 1, 0 
									FROM #ROStockLineRevisedPart ROS WITH(NOLOCK) 
										JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
										JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
									WHERE SL.StockLineId = @StocklineId;

									SELECT @WorkOrderMaterialsId = SCOPE_IDENTITY()
								END

								INSERT INTO dbo.SubWorkOrderMaterialStockLine (SubWorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
											UnitCost, UnitPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
								SELECT @WorkOrderMaterialsId, @StockLineId, SL.ItemMasterId, @ProvisionId, SL.ConditionId, 
										CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
										0, 0, ISNULL(SL.UnitCost, 0), ISNULL(SL.UnitCost, 0), GETDATE(), SL.UpdatedBy, GETDATE(), SL.UpdatedBy, @MasterCompanyId, 1, 0 
								FROM #ROStockLineRevisedPart ROS WITH(NOLOCK) 
									JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
									JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
								WHERE SL.StockLineId = @StocklineId AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @WorkOrderMaterialsId);

								SELECT @WorkOrderMaterialStockLineId = SCOPE_IDENTITY()

								UPDATE dbo.SubWorkOrderMaterialStockLine SET ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity, 0) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId

								SET @QtyFulfilled =  @QtyFulfilled - (SELECT Quantity FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId)

								SELECT @ExWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId, @ExWorkOrderMaterialStockLineId = WOMS.SWOMStockLineId
								FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK)
									JOIN dbo.RepairOrderPart RP WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
									JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId
								WHERE RP.RepairOrderId = @RepairOrderId AND WOM.SubWorkOrderId = @SubWorkOrderId AND WOM.WorkOrderId = @WorkOrderId AND RP.ItemTypeId=1

								IF(@QtyFulfilled <= 0)
								BEGIN
									DELETE WOMS FROM dbo.SubWorkOrderMaterialStockLine WOMS WHERE WOMS.SWOMStockLineId = @ExWorkOrderMaterialStockLineId;
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
							WHERE SL.StockLineId = @StocklineId AND RP.ItemTypeId=1

							IF((SELECT COUNT(1) FROM #ROStockLineSamePart WITH(NOLOCK) WHERE ISNULL(WorkOrderId, 0) > 0 ) > 0)
							BEGIN
								SELECT @ExWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId, @ExWorkOrderMaterialStockLineId = WOMS.SWOMStockLineId
								FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK)
									JOIN dbo.RepairOrderPart RP WITH(NOLOCK) ON RP.StockLineId = WOMS.StocklineId
									JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId
								WHERE RP.RepairOrderId = @RepairOrderId AND WOM.SubWorkOrderId = @SubWorkOrderId AND WOM.WorkOrderId = @WorkOrderId AND RP.ItemTypeId=1

								INSERT INTO dbo.SubWorkOrderMaterialStockLine (SubWorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
										UnitCost, UnitPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
								SELECT @ExWorkOrderMaterialsId, @StockLineId, SL.ItemMasterId, @ProvisionId, SL.ConditionId, 
										CASE WHEN SL.QuantityAvailable > @Quantity THEN @Quantity ELSE SL.QuantityAvailable END, 
										0, 0, ISNULL(SL.UnitCost, 0), ISNULL(SL.UnitCost, 0), GETDATE(), SL.UpdatedBy, GETDATE(), SL.UpdatedBy, Sl.MasterCompanyId, 1, 0 
								FROM #ROStockLineSamePart ROS WITH(NOLOCK) 
									JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
									JOIN dbo.ItemMaster IM WITH(NOLOCK)  ON SL.ItemMasterId = IM.ItemMasterId
								WHERE SL.StockLineId = @StocklineId AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @ExWorkOrderMaterialsId);

								SELECT @WorkOrderMaterialStockLineId = SCOPE_IDENTITY()

								UPDATE dbo.SubWorkOrderMaterialStockLine SET ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity, 0) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId

								SET @QtyFulfilled =  @QtyFulfilled - (SELECT Quantity FROM dbo.SubWorkOrderMaterialStockLine WITH(NOLOCK) WHERE SWOMStockLineId = @WorkOrderMaterialStockLineId)

								IF(@QtyFulfilled <= 0)
								BEGIN
									DELETE WOMS FROM dbo.SubWorkOrderMaterialStockLine WOMS WHERE WOMS.SWOMStockLineId = @ExWorkOrderMaterialStockLineId;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateSubWOStocklineFromRO' 
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