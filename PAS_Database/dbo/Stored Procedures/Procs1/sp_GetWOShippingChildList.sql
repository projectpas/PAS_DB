﻿/*************************************************************           
 ** File:   [sp_GetWOShippingChildList]           
 ** Author:   
 ** Description: This SP is Used to GetWOShippingChildList
 ** Purpose:         
 ** Date:     
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------  
	1    
	2    01/01/2024   Devendra Shekh	updated for serialnumber for MPN

EXEC DBO.sp_GetWOShippingChildList @ItemMasterIdlist=20751,@WorkOrderId =618 ,@WorkOrderPartId=10
**************************************************************/ 
CREATE Procedure [dbo].[sp_GetWOShippingChildList]  
@WorkOrderId bigint,  
@WorkOrderPartId bigint  
AS  
BEGIN  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
     SELECT   
      wopt.PickTicketId as WOPickTicketId,  
      wos.WorkOrderShippingId,  
      wos.ShipDate,  
      wos.WOShippingNum,  
      wopt.PickTicketNumber as  WOPickTicketNumber,  
      (ISNULL(wopt.QtyToShip,0) - ISNULL(wosi.QtyShipped,0)) as QtyToShip,  
      wo.WorkOrderNum,  
      CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',  
               CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription',   
      sl.StockLineNumber,  
      CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END AS 'SerialNumber',cr.[Name] as CustomerName,  
      woc.CustomsValue,woc.CommodityCode,  
      ISNULL(wosi.QtyShipped,0) as QtyShipped,  
      1 ItemNo,  
      wop.WorkOrderId,wop.ID as WorkOrderPartId,  
      wop.ItemMasterId,  
      wos.AirwayBill,  
      wPB.PackagingSlipNo,wPB.PackagingSlipId,  
      wobii.WorkOrderShippingId AS WOShippingId, 
	  wosi.FedexPdfPath,
	  ISNULL(wop.IsFinishGood,0) IsFinishGood
     FROM DBO.WOPickTicket wopt WITH (NOLOCK)   
      INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId = wopt.WorkOrderId  and wop.id=wopt.OrderPartId  
      LEFT JOIN DBO.WorkOrderShippingItem wosi on wosi.WorkOrderPartNumId = wop.ID AND wosi.WOPickTicketId = wopt.PickTicketId  
      LEFT JOIN DBO.WorkOrderShipping wos on wos.WorkOrderShippingId = wosi.WorkOrderShippingId  
      INNER JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId  
      LEFT JOIN DBO.ItemMaster imt  WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId  
      LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = wop.StockLineId  
      LEFT JOIN DBO.WorkOrderCustomsInfo woc WITH (NOLOCK) on woc.WorkOrderShippingId = wos.WorkOrderShippingId  
      LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = wo.CustomerId  
      LEFT JOIN DBO.WorkOrderPackaginSlipItems wPI  WITH (NOLOCK) ON wopt.PickTicketId = wPI.WOPickTicketId AND wPI.WOPartNoId = wop.id  
      LEFT JOIN DBO.WorkOrderPackaginSlipHeader wPB  WITH (NOLOCK) ON wPB.PackagingSlipId = wPI.PackagingSlipId  
      OUTER APPLY (SELECT TOP 1 WorkOrderShippingId FROM DBO.WorkOrderBillingInvoicing WOBI   
          WHERE wosi.WorkOrderShippingId = WOBI.WorkOrderShippingId) AS wobii  
        
     WHERE wopt.WorkOrderId=@WorkOrderId AND wopt.IsConfirmed=1 AND wopt.OrderPartId=@WorkOrderPartId   
    END  
   COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWOShippingChildList'   
                           ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) as bigint)  
                                                      + '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderPartId, 0) as bigint)   
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END