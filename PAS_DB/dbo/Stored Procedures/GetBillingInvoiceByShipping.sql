/*************************************************************           
 ** File:   [dbo].[GetBillingInvoiceByShipping]          
 ** Author:   Deep Patel
 ** Description: Get Billing Data based on Shipping id.
 ** Date:   01-March-2021   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2021   Deep Patel    Created
	2    02/03/2021   Deep Patel    add SO type parameter in query.
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetBillingInvoiceByShipping]
	@SalesOrderShippingId bigint
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

	BEGIN TRY
		SELECT sop.SalesOrderId, sop.SalesOrderPartId, sos.SalesOrderShippingId, sos.ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
		so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerRef, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
		so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, ct.[Name] as CreditTerm, cf.CurrencyId,
		so.TypeId, sotype.[Name] as RevType, sosi.QtyShipped as NoofPieces
		from DBO.SalesOrderShipping sos WITH (NOLOCK) 
		INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON sop.SalesOrderId = sos.SalesOrderId
		INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderShippingId = sos.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
		INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
		LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
		INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
		LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
		LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
		INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
		WHERE sos.SalesOrderShippingId = @SalesOrderShippingId;
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetBillingInvoiceByShipping' 
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderShippingId, '') + ''
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