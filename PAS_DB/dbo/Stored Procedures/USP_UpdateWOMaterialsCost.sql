
/*************************************************************           
 ** File:   [USP_UpdateWOMaterialsCost]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Materials List    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya Created
     
 EXECUTE USP_UpdateWOMaterialsCost 281,195, 10576
  EXECUTE USP_UpdateWOMaterialsCost 768

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_UpdateWOMaterialsCost]    
(    
@WorkOrderMaterialsId  BIGINT  = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				IF OBJECT_ID(N'tempdb..#tmpWOMaterials') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMaterials 
				END
				
				CREATE TABLE #tmpWOMaterials 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderId BIGINT NULL,
					 WorkFlowWorkOrderId BIGINT NULL,
					 WorkOrderMaterialsId BIGINT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 ExtendedCost DECIMAL(18,2) NULL,
					 StlCount INT NULL,
					 StlReqQty INT NULL
				)

				INSERT INTO #tmpWOMaterials (WorkOrderId,WorkFlowWorkOrderId,WorkOrderMaterialsId, UnitCost, ExtendedCost, StlCount, StlReqQty ) 
					SELECT WOM.WorkOrderId, WOM.WorkFlowWorkOrderId, WOM.WorkOrderMaterialsId, 
					(SELECT SUM(WOMSL.UnitCost)  FROM  dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOMSL.WorkOrderMaterialsId = @WorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As UnitCost,
					(SELECT SUM(WOMSL.ExtendedCost)  FROM  dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOMSL.WorkOrderMaterialsId = @WorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As UnitCost,
					(SELECT COUNT(1)  FROM  dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOMSL.WorkOrderMaterialsId = @WorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As StlCount,
					(SELECT SUM(WOMSL.Quantity)  FROM  dbo.WorkOrderMaterialStockLine WOMSL WHERE WOMSL.WorkOrderMaterialsId = @WorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As StlReqQty
				FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
				WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId 

				UPDATE WorkOrderMaterials SET  
					UnitCost = tmp.UnitCost, 
					ExtendedCost= tmp.ExtendedCost,
					TotalStocklineQtyReq = tmp.StlReqQty
				FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.WorkOrderMaterialsId = tmp.WorkOrderMaterialsId
				WHERE tmp.StlCount > 0
		
				UPDATE WorkOrderMaterials SET  
					UnitCost = CASE WHEN ISNULL(WOM.UnitCost, 0) > 0 THEN WOM.UnitCost ELSE ISNULL(IMPS.PP_UnitPurchasePrice, 0) END,
					ExtendedCost= CASE WHEN ISNULL(WOM.UnitCost, 0) > 0 THEN WOM.UnitCost * WOM.Quantity ELSE ISNULL(IMPS.PP_UnitPurchasePrice, 0) * WOM.Quantity END,
					TotalStocklineQtyReq = 0
				FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.WorkOrderMaterialsId = tmp.WorkOrderMaterialsId
					LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH(NOLOCK) ON IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId
				WHERE tmp.StlCount = 0

				IF OBJECT_ID(N'tempdb..#tmpMaterilasPickTicket') IS NOT NULL
				BEGIN
				DROP TABLE #tmpMaterilasPickTicket 
				END
				
				CREATE TABLE #tmpMaterilasPickTicket 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderMaterialsId BIGINT NULL,
					 WorkordermaterialstocklineId BIGINT NULL,
					 StocklineId BIGINT NULL,
					 QtyToReserve INT NULL,
					 QtyToShip INT NULL,
					 QtyPtickTicketRemove INT NULL,
				)

				INSERT INTO #tmpMaterilasPickTicket (WorkOrderMaterialsId, WorkordermaterialstocklineId,StocklineId,  QtyToReserve, QtyToShip)
				SELECT WorkOrderMaterialsId,WOMStockLineId,StockLineId, (QtyReserved + QtyIssued),
				(Select SUM(QtyToShip) from WorkorderPickTicket WHERE WorkOrderMaterialsId = woms.WorkOrderMaterialsId AND StocklineId =woms.StockLineId)
				FROM dbo.WorkOrderMaterialStockLine woms WHERE woms.WorkOrderMaterialsId = @WorkOrderMaterialsId

				UPDATE #tmpMaterilasPickTicket SET QtyPtickTicketRemove = ISNULL(QtyToShip,0) -  ISNULL(QtyToReserve,0)
				from #tmpMaterilasPickTicket		
				
				IF OBJECT_ID(N'tempdb..#tmpremovePT') IS NOT NULL
				BEGIN
				DROP TABLE #tmpremovePT 
				END
				
				CREATE TABLE #tmpremovePT 
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 WorkOrderMaterialsId BIGINT NULL,
						 WorkordermaterialstocklineId BIGINT NULL,
						 StocklineId BIGINT NULL,
						 QtyToReserve INT NULL,
						 QtyToShip INT NULL,
						 QtyPtickTicketRemove INT NULL,
						 PickTicketId bigint null,
						 PickTicketQtyToShip INT NULL,
					)
					
				INSERT INTO #tmpremovePT  SELECT  TMP.WorkOrderMaterialsId,TMP.WorkOrderMaterialsId,TMP.StocklineId,TMP.QtyToReserve,TMP.QtyToShip,TMP.QtyPtickTicketRemove,WOP.PickTicketId,WOP.QtyToShip FROM  dbo.WorkorderPickTicket WOP INNER JOIN  #tmpMaterilasPickTicket TMP 
					ON TMP.WorkOrderMaterialsId = WOP.WorkOrderMaterialsId AND TMP.StocklineId = WOP.StocklineId WHERE TMP.QtyPtickTicketRemove > 0 AND  WOP.QtyToShip > 0 ORDER BY WOP.PickTicketId 
		
				DECLARE @LoopID as int
				SELECT  @LoopID = MAX(ID) FROM #tmpremovePT
				DECLARE @PickTicketId bigint = 0
				DECLARE @QtyRemove bigint = 0
				DECLARE @QtyAvilable bigint = 0
				DECLARE @PTQtytoShip bigint = 0
				WHILE(@LoopID > 0)
				BEGIN
				SELECT @PickTicketId = PickTicketId, @QtyRemove = QtyPtickTicketRemove , @QtyAvilable = PickTicketQtyToShip FROM #tmpremovePT WHERE ID  = @LoopID

				IF @QtyRemove = 0 
				BEGIN
				   SET @QtyAvilable = 0
				END 

				IF @QtyRemove >= @QtyAvilable 
				BEGiN
				    SET  @PTQtytoShip =  @QtyAvilable 
				    SET @QtyRemove = @QtyRemove - @QtyAvilable
				END
				ELSE
				BEGIN
				   SET  @PTQtytoShip = @QtyRemove
				    SET @QtyRemove  = @PTQtytoShip
				END 
				
				UPDATE #tmpremovePT SET QtyPtickTicketRemove = @QtyRemove
								
				UPDATE dbo.WorkorderPickTicket SET QtyToShip = (QtyToShip- @PTQtytoShip) WHERE PickTicketId = @PickTicketId

				DELETE FROM dbo.WorkorderPickTicket WHERE QtyToShip = 0 AND PickTicketId = @PickTicketId
				
				SET @LoopID = @LoopID - 1;
				END
			
				IF OBJECT_ID(N'tempdb..#tmpremovePT') IS NOT NULL
				BEGIN
				DROP TABLE #tmpremovePT 
				END

				IF OBJECT_ID(N'tempdb..#tmpMaterilasPickTicket') IS NOT NULL
				BEGIN
				DROP TABLE #tmpMaterilasPickTicket 
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMaterials') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMaterials 
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
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOMaterialsCost' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderMaterialsId, '') + '' 
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