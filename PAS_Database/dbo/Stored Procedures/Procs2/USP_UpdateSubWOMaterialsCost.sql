
/*************************************************************           
 ** File:   [USP_UpdateSubWOMaterialsCost]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Materials List    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @SubWorkOrderMaterialsId BIGINT    
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya Created
	2    10/04/2021   Hemant Saliya Update Sub WO Pick Ticket Deletion based On Reservation 
	3    12/18/2023   Hemant Saliya Added Kit Part for Sub WO Cost Calc
     
 EXECUTE USP_UpdateSubWOMaterialsCost 161
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_UpdateSubWOMaterialsCost]    
(    
@SubWorkOrderMaterialsId  BIGINT  = NULL
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
					 SubWorkOrderMaterialsId BIGINT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 ExtendedCost DECIMAL(18,2) NULL,
					 StlCount INT NULL,
					 StlReqQty INT NULL,
					 IsKit BIT NULL
				)

				INSERT INTO #tmpWOMaterials (WorkOrderId, SubWorkOrderMaterialsId, UnitCost, ExtendedCost, StlCount, StlReqQty, IsKit ) 
					SELECT WOM.WorkOrderId, WOM.SubWorkOrderMaterialsId, 
					(SELECT SUM(WOMSL.UnitCost)  FROM  dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOMSL.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As UnitCost,
					(SELECT SUM(WOMSL.ExtendedCost)  FROM  dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOMSL.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As UnitCost,
					(SELECT COUNT(1)  FROM  dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOMSL.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As StlCount,
					(SELECT SUM(WOMSL.Quantity)  FROM  dbo.SubWorkOrderMaterialStockLine WOMSL WHERE WOMSL.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As StlReqQty,
					0
				FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK)
				WHERE WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId 
				UNION ALL
				SELECT WOM.WorkOrderId, WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId, 
					(SELECT SUM(WOMSL.UnitCost)  FROM  dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOMSL.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As UnitCost,
					(SELECT SUM(WOMSL.ExtendedCost)  FROM  dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOMSL.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As ExtendedCost,
					(SELECT COUNT(1)  FROM  dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOMSL.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As StlCount,
					(SELECT SUM(WOMSL.Quantity)  FROM  dbo.SubWorkOrderMaterialStockLineKit WOMSL WHERE WOMSL.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0)  As StlReqQty,
					1
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK)
				WHERE WOM.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId 				

				UPDATE SubWorkOrderMaterials SET  
					--UnitCost = tmp.UnitCost, 
					ExtendedCost= tmp.ExtendedCost,
					TotalStocklineQtyReq = tmp.StlReqQty
				FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.SubWorkOrderMaterialsId = tmp.SubWorkOrderMaterialsId
				WHERE tmp.StlCount > 0

				UPDATE SubWorkOrderMaterialsKit SET  
					--UnitCost = tmp.UnitCost, 
					ExtendedCost= tmp.ExtendedCost,
					TotalStocklineQtyReq = tmp.StlReqQty
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.SubWorkOrderMaterialsKitId = tmp.SubWorkOrderMaterialsId
				WHERE tmp.StlCount > 0 AND tmp.IsKit = 1
		
				UPDATE SubWorkOrderMaterials SET  
					UnitCost = CASE WHEN ISNULL(WOM.UnitCost, 0) > 0 THEN WOM.UnitCost ELSE ISNULL(IMPS.PP_UnitPurchasePrice, 0) END,
					ExtendedCost= CASE WHEN ISNULL(WOM.UnitCost, 0) > 0 THEN WOM.UnitCost * WOM.Quantity ELSE ISNULL(IMPS.PP_UnitPurchasePrice, 0) * WOM.Quantity END,
					TotalStocklineQtyReq = 0
				FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.SubWorkOrderMaterialsId = tmp.SubWorkOrderMaterialsId
					LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH(NOLOCK) ON IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId
				WHERE tmp.StlCount = 0

				UPDATE SubWorkOrderMaterialsKit SET  
					UnitCost = CASE WHEN ISNULL(WOM.UnitCost, 0) > 0 THEN WOM.UnitCost ELSE ISNULL(IMPS.PP_UnitPurchasePrice, 0) END,
					ExtendedCost= CASE WHEN ISNULL(WOM.UnitCost, 0) > 0 THEN WOM.UnitCost * WOM.Quantity ELSE ISNULL(IMPS.PP_UnitPurchasePrice, 0) * WOM.Quantity END,
					TotalStocklineQtyReq = 0
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.SubWorkOrderMaterialsKitId = tmp.SubWorkOrderMaterialsId
					LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH(NOLOCK) ON IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId
				WHERE tmp.StlCount = 0 AND tmp.IsKit = 1

				UPDATE SubWorkOrderMaterialStockLine SET  
					Quantity = CASE WHEN (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued,0)) > Quantity THEN (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued,0)) ELSE Quantity END
				FROM dbo.SubWorkOrderMaterialStockLine WOM WITH(NOLOCK)
					JOIN #tmpWOMaterials tmp ON WOM.SubWorkOrderMaterialsId = tmp.SubWorkOrderMaterialsId

				IF OBJECT_ID(N'tempdb..#tmpWOMaterials') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMaterials 
				END

				IF OBJECT_ID(N'tempdb..#tmpMaterilasPickTicket') IS NOT NULL
				BEGIN
				DROP TABLE #tmpMaterilasPickTicket 
				END

				CREATE TABLE #tmpMaterilasPickTicket 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 SubWorkOrderMaterialsId BIGINT NULL,
					 SWOMStockLineId BIGINT NULL,
					 StocklineId BIGINT NULL,
					 QtyToReserve INT NULL,
					 QtyToShip INT NULL,
					 QtyPtickTicketRemove INT NULL,
				)

				INSERT INTO #tmpMaterilasPickTicket (SubWorkOrderMaterialsId, SWOMStockLineId,StocklineId,  QtyToReserve, QtyToShip)
				SELECT SubWorkOrderMaterialsId,SWOMStockLineId,StockLineId, (QtyReserved + QtyIssued),
				(Select SUM(QtyToShip) from SubWorkorderPickTicket WHERE SubWorkOrderMaterialsId = woms.SubWorkOrderMaterialsId AND StocklineId =woms.StockLineId)
				FROM dbo.SubWorkOrderMaterialStockLine woms WHERE woms.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId

				UPDATE #tmpMaterilasPickTicket SET QtyPtickTicketRemove = ISNULL(QtyToShip,0) -  ISNULL(QtyToReserve,0)
				FROM #tmpMaterilasPickTicket

				IF OBJECT_ID(N'tempdb..#tmpremovePT') IS NOT NULL
				BEGIN
				DROP TABLE #tmpremovePT 
				END
				
				CREATE TABLE #tmpremovePT 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 SubWorkOrderMaterialsId BIGINT NULL,
					 SWOMStockLineId BIGINT NULL,
					 StocklineId BIGINT NULL,
					 QtyToReserve INT NULL,
					 QtyToShip INT NULL,
					 QtyPtickTicketRemove INT NULL,
					 PickTicketId bigint null,
					 PickTicketQtyToShip INT NULL,
				)

				INSERT INTO #tmpremovePT  SELECT  TMP.SubWorkOrderMaterialsId,TMP.SubWorkOrderMaterialsId,TMP.StocklineId,TMP.QtyToReserve,TMP.QtyToShip,TMP.QtyPtickTicketRemove,WOP.PickTicketId,WOP.QtyToShip 
				FROM  dbo.SubWorkorderPickTicket WOP 
					INNER JOIN  #tmpMaterilasPickTicket TMP ON TMP.SubWorkOrderMaterialsId = WOP.SubWorkOrderMaterialsId AND TMP.StocklineId = WOP.StocklineId 
				WHERE TMP.QtyPtickTicketRemove > 0 AND  WOP.QtyToShip > 0 
				ORDER BY WOP.PickTicketId 
		
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
								
				UPDATE dbo.SubWorkorderPickTicket SET QtyToShip = (QtyToShip- @PTQtytoShip) WHERE PickTicketId = @PickTicketId

				DELETE FROM dbo.SubWorkorderPickTicket WHERE QtyToShip = 0 AND PickTicketId = @PickTicketId
				
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
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOMaterialsCost' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderMaterialsId, '') + '' 
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