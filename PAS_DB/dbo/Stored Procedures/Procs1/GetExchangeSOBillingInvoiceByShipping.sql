/*************************************************************           
 ** File:   [dbo].[GetExchangeSOBillingInvoiceByShipping]          
 ** Author:   Deep Patel
 ** Description: Get Billing Data based on Shipping id.
 ** Date:   11-July-2021
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			  Author					Change Description            
 ** --   --------		 -------				--------------------------------          
    2	 29-MAR-2024	Bhargav Saliya		Get CreditTermName from [ExchangeSalesOrder] table 
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetExchangeSOBillingInvoiceByShipping]
	@ExchangeSalesOrderShippingId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT sop.ExchangeSalesOrderId, sop.ExchangeSalesOrderPartId, sos.ExchangeSalesOrderShippingId, sos.ShipDate, so.ExchangeSalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
		so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerRef, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
		so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, cf.CurrencyId,
		so.TypeId, sotype.[Name] AS RevType, sosi.QtyShipped as NoofPieces
		FROM DBO.ExchangeSalesOrderShipping sos WITH (NOLOCK) 
		INNER JOIN DBO.ExchangeSalesOrderPart sop WITH (NOLOCK) ON sop.ExchangeSalesOrderId = sos.ExchangeSalesOrderId
		INNER JOIN DBO.ExchangeSalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.ExchangeSalesOrderShippingId = sos.ExchangeSalesOrderShippingId AND sosi.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
		INNER JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) ON so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
		LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
		--INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
		LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
		LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
		INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype ON sotype.Id = so.TypeId
		WHERE sos.ExchangeSalesOrderShippingId = @ExchangeSalesOrderShippingId;
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSOBillingInvoiceByShipping' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderShippingId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END