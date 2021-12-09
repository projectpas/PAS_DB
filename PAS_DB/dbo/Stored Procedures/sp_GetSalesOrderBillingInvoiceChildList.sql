CREATE Procedure [dbo].[sp_GetSalesOrderBillingInvoiceChildList]
	@SalesOrderId  bigint,
	@SalesOrderPartId bigint,
	@ConditionId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT DISTINCT sosi.SalesOrderShippingId, 
				--(SELECT TOP 1 a.SOBillingInvoicingId FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.SalesOrderId = @SalesOrderId AND ItemMasterId = imt.ItemMasterId) AS SOBillingInvoicingId,
				(SELECT TOP 1 a.SOBillingInvoicingId FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where b.SalesOrderShippingId = sosi.SalesOrderShippingId) AS SOBillingInvoicingId,
				(SELECT TOP 1 a.InvoiceDate FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.SalesOrderId = @SalesOrderId AND SalesOrderShippingId = sosi.SalesOrderShippingId) AS InvoiceDate,
				(SELECT TOP 1 a.InvoiceNo FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.SalesOrderId = @SalesOrderId AND SalesOrderShippingId = sosi.SalesOrderShippingId) AS InvoiceNo,
				sos.SOShippingNum, sosi.QtyShipped as QtyToBill, 
				so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
				sl.SerialNumber, cr.[Name] as CustomerName, 
				(SELECT SUM(b.NoofPieces) FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId WHERE a.SalesOrderId = @SalesOrderId AND b.SalesOrderPartId = sop.SalesOrderPartId) AS QtyBilled,
				sop.ItemNo,
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description as 'Condition', 
				curr.Code as 'CurrencyCode',
				((ISNULL(sop.UnitSalePrice, 0) * SUM(sosi.QtyShipped)) + 
				(((ISNULL(sop.UnitSalePrice, 0) * SUM(sosi.QtyShipped)) * ISNULL(sop.TaxPercentage, 0)) / 100) + 
				SUM(ISNULL(sof.MarkupFixedPrice, 0)) + SUM(ISNULL(socg.MarkupFixedPrice, 0))) as 'TotalSales',
				(SELECT TOP 1 a.InvoiceStatus FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.SalesOrderId = @SalesOrderId AND SalesOrderShippingId = sosi.SalesOrderShippingId) AS InvoiceStatus,
				sos.SmentNum AS 'SmentNo'
				FROM DBO.SalesOrderShippingItem sosi WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sosi.SalesOrderShippingId = sos.SalesOrderShippingId
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderShippingId = sos.SalesOrderShippingId
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId
				INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) on sop.SalesOrderId = sos.SalesOrderId AND sop.SalesOrderPartId = sosi.SalesOrderPartId
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
				LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) on soc.SalesOrderShippingId = sos.SalesOrderShippingId
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId
				LEFT JOIN DBO.SalesOrderFreight sof WITH (NOLOCK) ON so.SalesOrderId = sof.SalesOrderId AND sof.IsActive = 1 AND sof.IsDeleted = 0
				LEFT JOIN DBO.SalesOrderCharges socg WITH (NOLOCK) ON so.SalesOrderId = socg.SalesOrderId AND socg.IsActive = 1 AND socg.IsDeleted = 0
				WHERE sos.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId
				GROUP BY sosi.SalesOrderShippingId, sos.SOShippingNum, so.SalesOrderNumber, imt.ItemMasterId, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
				sl.SerialNumber, cr.[Name], sop.ItemNo, sop.SalesOrderId, sop.SalesOrderPartId, cond.Description, curr.Code,
				sobi.InvoiceStatus, sosi.QtyShipped,
				sop.UnitSalePrice, sop.TaxAmount, sop.TaxPercentage, sos.SmentNum;
			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSalesOrderBillingInvoiceChildList' 
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