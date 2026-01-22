-- EXEC [dbo].[sp_GetExchangeSalesOrderBillingInvoiceList] 223
CREATE Procedure [dbo].[sp_GetExchangeSalesOrderBillingInvoiceList]
@ExchangeSalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				select so.ExchangeSalesOrderNumber, imt.partnumber, imt.PartDescription, 
				SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyToBill,
				(SELECT ISNULL(SUM(NoofPieces), 0) FROM ExchangeSalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN ExchangeSalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.ExchangeSalesOrderId = @ExchangeSalesOrderId AND ItemMasterId = imt.ItemMasterId) AS QtyBilled,
				sop.ExchangeSalesOrderId, imt.ItemMasterId AS ExchangeSalesOrderPartId,
				(ISNULL(SUM(sosi.QtyShipped), 0) - (SELECT ISNULL(SUM(NoofPieces), 0) FROM ExchangeSalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN ExchangeSalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.ExchangeSalesOrderId = @ExchangeSalesOrderId AND ItemMasterId = imt.ItemMasterId)) as QtyRemaining,
				CASE WHEN SUM(ISNULL(sosi.QtyShipped, 0)) = (SELECT ISNULL(SUM(NoofPieces), 0) FROM ExchangeSalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN ExchangeSalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.ExchangeSalesOrderId = @ExchangeSalesOrderId AND ItemMasterId = imt.ItemMasterId) THEN 'Fullfilled'
				ELSE 'Fullfilling' END as [Status],
				0 AS ItemNo  
				from DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
				INNER JOIN DBO.ExchangeSalesOrderShipping sos WITH (NOLOCK) on sos.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
				INNER JOIN DBO.ExchangeSalesOrderShippingItem sosi WITH (NOLOCK) on sos.ExchangeSalesOrderShippingId = sosi.ExchangeSalesOrderShippingId AND sosi.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
				LEFT JOIN DBO.ExchangeSalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.ExchangeSalesOrderId = sos.ExchangeSalesOrderId
				LEFT JOIN DBO.ExchangeSalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							AND sobii.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId AND sobii.NoofPieces = sosi.QtyShipped
				WHERE sop.ExchangeSalesOrderId = @ExchangeSalesOrderId
				GROUP BY so.ExchangeSalesOrderNumber, imt.partnumber, imt.PartDescription,
				sop.ExchangeSalesOrderId, imt.ItemMasterId
			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetExchangeSalesOrderBillingInvoiceList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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