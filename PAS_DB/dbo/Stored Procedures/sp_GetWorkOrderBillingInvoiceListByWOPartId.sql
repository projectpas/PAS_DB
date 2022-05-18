
CREATE Procedure [dbo].[sp_GetWorkOrderBillingInvoiceListByWOPartId]
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
					imt.partnumber, 
					imt.PartDescription, 
					(SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
					                                      INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId )	 AS QtyToBill,
					ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId),0) as QtyBilled,
					wop.WorkOrderId, imt.ItemMasterId AS ItemMasterId,
					wop.ID as WorkOrderPartId ,
					((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
					                                      INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId )) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId),0) as QtyRemaining,
					CASE WHEN 
					(SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
					                                      INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId )
					= ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId),0) THEN 'Fullfilled'
					ELSE 'Fullfilling' END as [Status], 
					CASE WHEN SUM(ISNULL(wosi.QtyShipped, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId) THEN 'Fullfilled'
					END as [Status], 0 AS ItemNo  
				FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
					LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
					INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId
					INNER JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
					LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
					LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
					LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0
					AND wobii.WorkOrderPartId = wop.ID AND wobii.NoofPieces = wosi.QtyShipped
				WHERE wop.WorkOrderId = @WorkOrderId 
				and wop.ID in (SELECT WorkOrderPartId FROM WorkOrderBillingInvoicingItem WITH (NOLOCK)
								WHERE BillingInvoicingId in 
								(SELECT TOP 1  BillingInvoicingId FROM WorkOrderBillingInvoicing WITH (NOLOCK)
								WHERE WorkOrderId=@WorkOrderId ORDER BY BillingInvoicingId DESC))  --= @workOrderPartNumberId
				GROUP BY wo.WorkOrderNum,wop.ID, imt.partnumber, imt.PartDescription,wo.WorkOrderId,
					wop.WorkOrderId, imt.ItemMasterId
			END
		 COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderBillingInvoiceList' 
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