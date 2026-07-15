-- ===== PROCEDURE: [dbo].[USP_GetWOBillingPerformaInvoiceListByWOPartId]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetWOBillingPerformaInvoiceListByWOPartId.sql) =====
/*************************************************************           
 ** File:     [USP_GetWOBillingPerformaInvoiceListByWOPartId]           
 ** Author:	  Devendra Shekh
 ** Description: This SP is Used to  Get WOBilling PerformaInvoiceList By WOPartId   
 ** Purpose:         
 ** Date:   01/29/2024	
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date         Author				Change Description            
 ** --   	--------     -------			--------------------------------     
	1    01/29/2024		 Devendra Shekh		CREATED
	2    02/02/2024		 Devendra Shekh		modified joins for shipping 
	3    07-07-2025      Moin Bloch         Changed Old To New Billing Table SP NOT in USE
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	5    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

	EXEC [USP_GetWOBillingPerformaInvoiceListByWOPartId] 3543,3013

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWOBillingPerformaInvoiceListByWOPartId]
@WorkOrderId  bigint,
@workOrderPartNumberId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		 BEGIN TRANSACTION
			BEGIN
			
				SELECT 
					wo.WorkOrderNum as WorkOrderNumber, 
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
			        CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription',
					ISNULL((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
					                                      INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID ),0)	 AS QtyToBill,
					ISNULL((Select SUM(ISNULL(WOBI.QtyBilled,0)) FROM dbo.BillingInvoicing WOB inner join  dbo.BillingInvoicingItems WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.ReferenceId = wo.WorkOrderId AND WOBI.SubReferenceId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) as QtyBilled,
					wop.WorkOrderId,
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
					wop.ID as WorkOrderPartId ,
					(ISNULL((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
					                                      INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID),0)) - ISNULL((Select SUM(ISNULL(WOBI.QtyBilled,0)) FROM dbo.BillingInvoicing WOB inner join  dbo.BillingInvoicingItems WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.ReferenceId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) as QtyRemaining,
					CASE WHEN 
					(SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
					                                      INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID )
					= ISNULL((Select  SUM(ISNULL(WOBI.QtyBilled,0)) FROM dbo.BillingInvoicing WOB inner join  dbo.BillingInvoicingItems WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.ReferenceId = wo.WorkOrderId AND WOBI.SubReferenceId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) THEN 'Fullfilled'
					ELSE 'Fullfilling' END as [Status], 
					CASE WHEN SUM(ISNULL(wosi.QtyShipped, 0)) = (SELECT SUM(ISNULL(QtyBilled, 0)) FROM dbo.BillingInvoicingItems wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 1) THEN 'Fullfilled'
					END as [Status], 0 AS ItemNo  
				FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
					LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
					LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId
					LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
					LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					 AND ISNULL(imt.IsNonStock,0) = 0
					 LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
					LEFT JOIN DBO.BillingInvoicingItems wobii WITH(NOLOCK) on wop.ID = wobii.SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
					LEFT JOIN DBO.BillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0
					AND wobii.SubReferenceId = wop.ID AND wobii.QtyBilled = wosi.QtyShipped AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
				WHERE wop.WorkOrderId = @WorkOrderId 
				and wop.ID in (SELECT SubReferenceId FROM dbo.BillingInvoicingItems WITH (NOLOCK)
								WHERE ISNULL(IsPerformaInvoice, 0) = 1 AND BillingInvoicingId in 
								(SELECT TOP 1  BillingInvoicingId FROM dbo.BillingInvoicing WITH (NOLOCK)
								WHERE ReferenceId=@WorkOrderId AND ISNULL(IsPerformaInvoice, 0) = 1 ORDER BY BillingInvoicingId DESC))  --= @workOrderPartNumberId
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOBillingPerformaInvoiceListByWOPartId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter4 = ' + ISNULL(@workOrderPartNumberId ,'') +''
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