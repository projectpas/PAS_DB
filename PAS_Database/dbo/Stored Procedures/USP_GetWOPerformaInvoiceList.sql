/*************************************************************           
 ** File:     [USP_GetWOPerformaInvoiceList]           
 ** Author:	  Devendra Shekh
 ** Description: This SP is Used to get list of performa Invoices for WO Part    
 ** Purpose:         
 ** Date:  01/30/2024
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    01/30/2024   Devendra Shekh		created

 -- EXEC [dbo].[USP_GetWOPerformaInvoiceList] 4177, 3668, 0
**************************************************************/ 

CREATE   Procedure [dbo].[USP_GetWOPerformaInvoiceList]
	@WorkOrderId  BIGINT,
	@WorkOrderPartNumberId  BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		 BEGIN TRANSACTION
			BEGIN
				DECLARE @IsInvoiceBeforeShippingAllowed BIT,@isWOPartShipped BIT = 0;

				SET @isWOPartShipped = CASE WHEN (SELECT COUNT(wos.WorkOrderShippingId) AS TotalRecord FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
						INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId
						INNER JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
						WHERE wos.WorkOrderId = @WorkOrderId AND wosi.WorkOrderPartNumId = @workOrderPartNumberId) > 0 THEN 1 ELSE 0 END;

				SELECT @IsInvoiceBeforeShippingAllowed = ISNULL(WOPN.AllowInvoiceBeforeShipping, 0) FROM DBO.WorkOrderPartNumber WOPN WITH(NOLOCK) WHERE WOPN.WorkOrderId = @WorkOrderId;

				SELECT 
						wo.WorkOrderNum as WorkOrderNumber, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription',

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0 
							 THEN CASE WHEN (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) < 0 
									   THEN 0 ELSE (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) END
							 ELSE (SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId  AND WP.ID = wop.ID) END AS QtyToBill,

						CASE WHEN ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) < 0 THEN 0 
							 ELSE ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) END AS QtyBilled,

						wop.WorkOrderId, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						wop.ID as WorkOrderPartId ,

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
											INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0 THEN
								CASE WHEN ((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) < 0 THEN 0 
								ELSE ((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) END
							ELSE CASE WHEN ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) < 0 THEN 0 
							ELSE ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) END END as QtyRemaining,

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0
							 THEN CASE WHEN (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) = ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) 
									  THEN 'Fullfilled' ELSE 'Fullfilling' END
							 ELSE CASE WHEN (SELECT SUM(ISNULL(WSI.QtyToShip, 0)) FROM WOPickTicket  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.OrderPartId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) = ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) 
								  THEN 'Fullfilled' ELSE 'Fullfilling' END END as [Status], 

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0 
							 THEN CASE WHEN SUM(ISNULL(wosi.QtyShipped, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 1) 
								  THEN 'Fullfilled' END 
							ELSE CASE WHEN SUM(ISNULL(wop.Quantity, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 1) THEN 'Fullfilled'
								 END END as [Status],
						0 AS ItemNo  
					FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
						LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0
						AND wobii.WorkOrderPartId = wop.ID AND wobii.NoofPieces = wop.Quantity
					WHERE wop.WorkOrderId = @WorkOrderId
					GROUP BY wo.WorkOrderNum,wop.ID, imt.partnumber, imt.PartDescription,wo.WorkOrderId,
					wop.WorkOrderId, imt.ItemMasterId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription
			END
		 COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOPerformaInvoiceList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''@Parameter2 = ' + ISNULL(@workOrderPartNumberId ,'') +''
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