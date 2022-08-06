--   EXEC sp_GetSalesOrderBillingInvoiceList 119
CREATE Procedure [dbo].[sp_GetSalesOrderBillingInvoiceList]
@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				select DISTINCT so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sop.ConditionId, 				
				sop.SalesOrderId, imt.ItemMasterId AS SalesOrderPartId,				
				'' as [Status],
				0 AS ItemNo  
				from DBO.SalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = sos.SalesOrderId
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.NoofPieces = sosi.QtyShipped
				WHERE sop.SalesOrderId = @SalesOrderId
				GROUP BY so.SalesOrderNumber, imt.partnumber, imt.PartDescription,
				sop.SalesOrderId, imt.ItemMasterId, sop.Qty, sop.ConditionId
			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSalesOrderBillingInvoiceList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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