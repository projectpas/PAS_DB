/*************************************************************           
 ** File:   [sp_GetWOShippingParentList]           
 ** Author:   Subhash Saliya
 ** Description: Get  for Work order Shipping List    
 ** Purpose:         
 ** Date:   23-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2021   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
	3    07/16/2024   Devendra Shekh Added Case For Status

     
 EXECUTE [sp_GetWOShippingParentList] 34, 39
**************************************************************/
CREATE     Procedure [dbo].[sp_GetWOShippingParentList]
@WorkOrderId  bigint,
@WorkOrderPartId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		  BEGIN TRANSACTION
			BEGIN
				SELECT 
					wo.WorkOrderNum,
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
			        CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
					SUM(ISNULL(wopt.QtyToShip, 0)) as QtyToShip,
					SUM(ISNULL(wosi.QtyShipped, 0)) as QtyShipped,
					wop.WorkOrderId,
					wop.ID as WorkOrderPartId,
					SUM(ISNULL(wopt.QtyToShip, 0)) - SUM(ISNULL(wosi.QtyShipped,0)) as QtyRemaining,
					--CASE WHEN SUM(ISNULL(wopt.QtyToShip, 0)) = SUM(ISNULL(wosi.QtyShipped, 0)) THEN 'Fullfilled' ELSE 'Fullfilling' END as [Status], 
					CASE WHEN SS.[Status] IS NULL THEN 'Ready' ELSE SS.[Status] END As [Status],
					1 as ItemNo,
					isnull(cds.ShipViaId,0) as ShipViaId
				FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
					LEFT JOIN DBO.WorkOrder wo  WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
					INNER JOIN DBO.WOPickTicket wopt  WITH(NOLOCK) on wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
					LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
					LEFT JOIN DBO.CustomerDomensticShipping CDSD WITH(NOLOCK) ON CDSD.CustomerId = wo.CustomerId and CDSD.IsPrimary=1
					LEFT JOIN DBO.CustomerDomensticShippingShipVia cds WITH(NOLOCK) ON CDSD.CustomerDomensticShippingId = cds.CustomerDomensticShippingId and cds.IsPrimary=1					
					LEFT JOIN DBO.WorkOrderShippingItem wosi  WITH(NOLOCK) on wosi.WorkOrderPartNumId = wop.ID AND wosi.WOPickTicketId = wopt.PickTicketId
					LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId and wos.WorkOrderId = wo.WorkOrderId
					LEFT JOIN DBO.ShippingStatus SS WITH(NOLOCK) ON wos.WOShippingStatusId = SS.ShippingStatusId
				WHERE wop.WorkOrderId = @WorkOrderId AND wopt.IsConfirmed = 1 AND wop.IsFinishGood = 1 --and wop.ID=@WorkOrderPartId
				GROUP BY wo.WorkOrderNum,imt.partnumber,imt.PartDescription,cds.ShipViaId,wop.WorkOrderId,wop.ID,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, SS.[Status];
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWOShippingParentList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH

END