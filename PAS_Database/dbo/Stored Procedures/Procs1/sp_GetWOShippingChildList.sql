/*************************************************************           
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
   
	1    01/01/2024   Devendra Shekh	updated for serialnumber for MPN
	2    14/05/2024   Moin Bloch	    updated for dublicate record issue PN-7946
	3    14/05/2024   Hemant Saliya	    updated for Shapping Status

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
		SELECT  
			  wopt.[PickTicketId] AS WOPickTicketId,  
			  wos.[WorkOrderShippingId],  
			  wos.[ShipDate],  
			  wos.[WOShippingNum],  
			  wopt.[PickTicketNumber] AS  WOPickTicketNumber,  
			  (ISNULL(wopt.[QtyToShip],0) - ISNULL(wosi.[QtyShipped],0)) AS QtyToShip,  
			  wo.[WorkOrderNum],  
			  CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartNumber] ELSE imt.[PartNumber] END AS 'PartNumber',  
					   CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartDescription] ELSE imt.[PartDescription] END AS 'PartDescription',   
			  sl.[StockLineNumber],  
			  CASE WHEN ISNULL(wop.[RevisedSerialNumber], '') = '' THEN sl.[SerialNumber] ELSE wop.[RevisedSerialNumber] END AS 'SerialNumber',cr.[Name] AS CustomerName,  
			  woc.[CustomsValue],woc.CommodityCode,  
			  ISNULL(wosi.[QtyShipped],0) AS QtyShipped,  
			  1 ItemNo,  
			  wop.[WorkOrderId],
			  wop.[ID] AS WorkOrderPartId,  
			  wop.[ItemMasterId],  
			  wos.[AirwayBill],  
			  wPB.[PackagingSlipNo],wPB.PackagingSlipId,  
			  wobii.[WorkOrderShippingId] AS WOShippingId, 
			  wosi.[FedexPdfPath],
			  SS.[Status] As [Status],
			  ISNULL(wop.[IsFinishGood],0) IsFinishGood
		FROM [dbo].[WOPickTicket] wopt WITH (NOLOCK)   
			INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON wop.[WorkOrderId] = wopt.[WorkOrderId] AND wop.id=wopt.[OrderPartId]  
			INNER JOIN [dbo].[WorkOrder] wo WITH (NOLOCK) ON wo.[WorkOrderId] = wop.[WorkOrderId]  
			LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH (NOLOCK) ON wosi.[WorkOrderPartNumId] = wop.ID AND wosi.[WOPickTicketId] = wopt.[PickTicketId]
			LEFT JOIN [dbo].[WorkOrderShipping] wos WITH (NOLOCK) ON wos.[WorkOrderShippingId] = wosi.[WorkOrderShippingId]  
			LEFT JOIN [dbo].[ItemMaster] imt  WITH (NOLOCK) ON imt.[ItemMasterId] = wop.[ItemMasterId]  
			LEFT JOIN [dbo].[Stockline] sl WITH (NOLOCK) ON sl.[StockLineId] = wop.[StockLineId]  
			LEFT JOIN [dbo].[WorkOrderCustomsInfo] woc WITH (NOLOCK) ON woc.[WorkOrderShippingId] = wos.[WorkOrderShippingId]  
			LEFT JOIN [dbo].[Customer] cr WITH (NOLOCK) ON cr.[CustomerId] = wo.[CustomerId]  
			LEFT JOIN [dbo].[WorkOrderPackaginSlipItems] wPI  WITH (NOLOCK) ON wopt.[PickTicketId] = wPI.[WOPickTicketId] AND wPI.[WOPartNoId] = wop.[id]  
			LEFT JOIN [dbo].[WorkOrderPackaginSlipHeader] wPB  WITH (NOLOCK) ON wPB.[PackagingSlipId] = wPI.[PackagingSlipId]  
			LEFT JOIN DBO.ShippingStatus SS WITH(NOLOCK) ON wos.WOShippingStatusId = SS.ShippingStatusId
			OUTER APPLY (SELECT TOP 1 [WorkOrderShippingId] FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
				WHERE wosi.[WorkOrderShippingId] = WOBI.[WorkOrderShippingId] AND wos.[WorkOrderId] = WOBI.[WorkOrderId] AND ISNULL(WOBI.[IsPerformaInvoice],0) = 0) AS wobii          
		WHERE wopt.[WorkOrderId]=@WorkOrderId AND wopt.[IsConfirmed]=1 AND wopt.[OrderPartId]=@WorkOrderPartId   

     
  
	END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
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