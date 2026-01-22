CREATE Procedure [dbo].[sp_GetExchangeSalesOrderBillingInvoiceChildList]
	@ExchangeSalesOrderId  bigint,
	@ExchangeSalesOrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT DISTINCT sosi.ExchangeSalesOrderShippingId, CASE WHEN sop.ExchangeSalesOrderPartId IS NOT NULL THEN sobi.SOBillingInvoicingId ELSE NULL END AS SOBillingInvoicingId, 
				CASE WHEN sop.ExchangeSalesOrderPartId IS NOT NULL THEN sobi.InvoiceDate ELSE NULL END AS InvoiceDate,
				CASE WHEN sop.ExchangeSalesOrderPartId IS NOT NULL THEN sobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
				sos.SOShippingNum, SUM(sosi.QtyShipped) as QtyToBill, 
				so.ExchangeSalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
				sl.SerialNumber, cr.[Name] as CustomerName, 
				(SELECT COUNT(*) FROM DBO.ExchangeSalesOrderBillingInvoicingItem sobii WITH (NOLOCK) WHERE sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId) AS QtyBilled,
				--sop.ItemNo,
				sop.ExchangeSalesOrderId, sop.ExchangeSalesOrderPartId, cond.Description as 'Condition', 
				curr.Code as 'CurrencyCode',
				--((ISNULL(sop.UnitSalePrice, 0) * SUM(sosi.QtyShipped)) + 
				--(((ISNULL(sop.UnitSalePrice, 0) * SUM(sosi.QtyShipped)) * ISNULL(sop.TaxPercentage, 0)) / 100) + 
				--SUM(ISNULL(sof.MarkupFixedPrice, 0)) + SUM(ISNULL(socg.MarkupFixedPrice, 0))) as 'TotalSales',
				((ISNULL(sop.ExchangeListPrice, 0) * SUM(sosi.QtyShipped))) as 'TotalSales',
				sobi.InvoiceStatus 
				FROM DBO.ExchangeSalesOrderShippingItem sosi WITH (NOLOCK)
				INNER JOIN DBO.ExchangeSalesOrderShipping sos WITH (NOLOCK) on sosi.ExchangeSalesOrderShippingId = sos.ExchangeSalesOrderShippingId
				LEFT JOIN DBO.ExchangeSalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.ExchangeSalesOrderId = sos.ExchangeSalesOrderId
				INNER JOIN DBO.ExchangeSalesOrderPart sop WITH (NOLOCK) on sop.ExchangeSalesOrderId = sos.ExchangeSalesOrderId AND sop.ExchangeSalesOrderPartId = sosi.ExchangeSalesOrderPartId
				INNER JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
				LEFT JOIN DBO.ExchangeSalesOrderCustomsInfo soc WITH (NOLOCK) on soc.ExchangeSalesOrderShippingId = sos.ExchangeSalesOrderShippingId
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId
				LEFT JOIN DBO.ExchangeSalesOrderFreight sof WITH (NOLOCK) ON so.ExchangeSalesOrderId = sof.ExchangeSalesOrderId AND sof.IsActive = 1 AND sof.IsDeleted = 0
				LEFT JOIN DBO.ExchangeSalesOrderCharges socg WITH (NOLOCK) ON so.ExchangeSalesOrderId = socg.ExchangeSalesOrderId AND socg.IsActive = 1 AND socg.IsDeleted = 0
				WHERE sos.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sop.ItemMasterId = @ExchangeSalesOrderPartId
				GROUP BY sosi.ExchangeSalesOrderShippingId, sobi.SOBillingInvoicingId, sobi.InvoiceDate, sobi.InvoiceNo, 
				sos.SOShippingNum, so.ExchangeSalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
				sl.SerialNumber, cr.[Name], 
				--sop.ItemNo,
				sop.ExchangeSalesOrderId, sop.ExchangeSalesOrderPartId, cond.Description, curr.Code,
				sobi.InvoiceStatus,
				--sop.UnitSalePrice, sop.TaxAmount, sop.TaxPercentage;
				sop.ExchangeListPrice
			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetExchangeSalesOrderBillingInvoiceChildList' 
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