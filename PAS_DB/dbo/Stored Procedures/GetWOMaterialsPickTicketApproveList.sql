
/*************************************************************           
 ** File:   [sp_GetPickTicketApproveList_New]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Get Pick Ticket Details    
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
	2    06/07/2021   Hemant Saliya Updated SP for Get Proper Data
	3    06/07/2021   Hemant Saliya Updated For Update WO Work Flow ID
     
 EXECUTE sp_GetPickTicketApproveList_New 323

**************************************************************/ 
CREATE PROCEDURE [dbo].[GetWOMaterialsPickTicketApproveList]
@workOrderId BIGINT,
@workflowWorkOrderId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				SELECT WOMS.* INTO #WOMStockline FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId WHERE WOM.WorkOrderId = @workOrderId AND WOM.WorkFlowWorkOrderId = @workflowWorkOrderId
				
				SELECT 
					wom.WorkOrderMaterialsId as OrderPartId, 
					wom.WorkOrderId as referenceId, 
					imt.PartNumber, 
					imt.PartDescription,
					wom.Quantity as Qty,
					wo.WorkOrderNum as OrderNumber, 
					''  as OrderQuoteNumber,
					wom.ItemMasterId, 
					wom.ConditionCodeId AS ConditionId,
					cr.[Name] as CustomerName, 
					cr.CustomerCode,
					(SELECT SUM(ISNULL(sl.QuantityAvailable, 0)) FROM #WOMStockline wmsl JOIN dbo.StockLine sl WITH (NOLOCK) ON wmsl.StockLineId = sl.StockLineId WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId) AS QuantityAvailable,
					CASE WHEN ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId), 0) = 0 THEN ISNULL(wom.Quantity, 0) ELSE
					(SELECT SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId) END AS QtyToShip,

					(ISNULL(wom.Quantity, 0) - ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId), 0)) AS QtyToPick,

					CASE WHEN ISNULL(wom.Quantity, 0) = ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId), 0) THEN 'Fulfilled'
					ELSE 'Fullfillng' END as [Status],

					(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM #WOMStockline wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0) 
					+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM #WOMStockline wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0)) 
					- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId),0))  
					AS ReadyToPick
				FROM dbo.WorkOrderMaterials wom WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
					INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
					INNER JOIN dbo.Customer cr WITH (NOLOCK) on cr.CustomerId = wo.CustomerId
				WHERE wom.WorkOrderId=@workOrderId AND wom.WorkFlowWorkOrderId = @workflowWorkOrderId AND (ISNULL(wom.QuantityReserved,0) + ISNULL(wom.QuantityIssued,0)) > 0  
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketApproveList_New' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@workflowWorkOrderId ,'') +''
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