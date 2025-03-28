/*************************************************************             
** File:   [GetSalesOrderQuoteAnalysisData]
** Author:   Vishal Suthar
** Description: This procedre is used to get SOQ analysis data
** Purpose:
** Date:   12/27/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   12/27/2025   Vishal Suthar		Created

EXEC [GetSalesOrderQuoteAnalysisData] 230
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderQuoteAnalysisData]
    @SalesOrderQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			part.SalesOrderQuotePartId,
			part.SalesOrderQuoteId,
			ISNULL(partcost.NetSaleAmount, 0) AS NetSales,
			ISNULL((
				SELECT SUM(b.BillingAmount)
				FROM SalesOrderQuoteFreight b
				WHERE b.SalesOrderQuoteId = soq.SalesOrderQuoteId 
					  AND b.IsActive = 1 
					  AND b.IsDeleted = 0 
					  AND b.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			), 0) AS Freight,
			ISNULL((
				SELECT SUM(b.BillingAmount)
				FROM SalesOrderQuoteCharges b
				WHERE b.SalesOrderQuoteId = soq.SalesOrderQuoteId 
					  AND b.IsActive = 1 
					  AND b.IsDeleted = 0 
					  AND b.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			), 0) AS Misc
		FROM DBO.SalesOrderQuote soq WITH (NOLOCK)
		INNER JOIN DBO.SalesOrderQuotePartV1 part WITH (NOLOCK) ON soq.SalesOrderQuoteId = part.SalesOrderQuoteId
		LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON part.SalesOrderQuotePartId = stk.SalesOrderQuotePartId
		LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
		INNER JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
		LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
		LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON soq.CustomerId = cf.CustomerId
		INNER JOIN DBO.SalesOrderQuotePartCost partcost WITH (NOLOCK) ON part.SalesOrderQuotePartId = partcost.SalesOrderQuotePartId
		LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON cf.CurrencyId = curr.CurrencyId
		WHERE part.SalesOrderQuoteId = @SalesOrderQuoteId AND part.IsDeleted = 0;
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
			DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetSalesOrderQuoteAnalysisData' 
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + ''
			, @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			exec spLogException 
					@DatabaseName           = @DatabaseName
					, @AdhocComments          = @AdhocComments
					, @ProcedureParameters = @ProcedureParameters
					, @ApplicationName        =  @ApplicationName
					, @ErrorLogID             = @ErrorLogID OUTPUT;
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
			RETURN(1);
	END CATCH
END