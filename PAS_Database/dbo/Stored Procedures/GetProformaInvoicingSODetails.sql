/*************************************************************           
 ** File:   [dbo].[GetProformaInvoicingSODetails]          
 ** Author:   AMIT GHEDIYA
 ** Description: Get Billing Data based on SalesOrderPartId.
 ** Date:   01/31/2024   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    01/31/2024   AMIT GHEDIYA	Created
**************************************************************/ 
CREATE     PROCEDURE [dbo].[GetProformaInvoicingSODetails]
	@SalesOrderPartId BIGINT,
	@soBillingInvoicingId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
			IF(@soBillingInvoicingId > 0)
			BEGIN
				SELECT sop.SalesOrderId, 
					   sop.SalesOrderPartId, 
					   0 AS SalesOrderShippingId, 
					   NULL AS ShipDate, 
					   so.SalesOrderNumber, 
					   CONCAT(emp.FirstName, ' ', emp.LastName) AS EmployeeName,
					   so.EmployeeId, 
					   so.OpenDate, 
					   so.CustomerReference AS CustomerRef, 
					   so.CustomerId, 
					   CONCAT(empsp.FirstName, ' ', empsp.LastName) AS SalesPerson,
					   so.SalesPersonId, 
					   cf.CreditLimit, 
					   cf.CreditTermsId, 
					   ct.[Name] AS CreditTerm, 
					   cf.CurrencyId,
					   so.TypeId, 
					   sotype.[Name] AS RevType, 
					   ISNULL(sobii.NoofPieces, 0) AS NoofPieces,
					   sobi.GrandTotal,
					   sobi.Notes
				FROM DBO.SalesOrderPart sop WITH (NOLOCK)
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
				INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 1
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 1
				WHERE sop.SalesOrderPartId = @SalesOrderPartId AND sobii.SOBillingInvoicingId = @soBillingInvoicingId;
			END
			ELSE
			BEGIN
				SELECT sop.SalesOrderId, 
				   sop.SalesOrderPartId, 
				   0 AS SalesOrderShippingId, 
				   NULL AS ShipDate, 
				   so.SalesOrderNumber, 
				   CONCAT(emp.FirstName, ' ', emp.LastName) AS EmployeeName,
				   so.EmployeeId, 
				   so.OpenDate, 
				   so.CustomerReference AS CustomerRef, 
				   so.CustomerId, 
				   CONCAT(empsp.FirstName, ' ', empsp.LastName) AS SalesPerson,
				   so.SalesPersonId, 
				   cf.CreditLimit, 
				   cf.CreditTermsId, 
				   ct.[Name] AS CreditTerm, 
				   cf.CurrencyId,
				   so.TypeId, 
				   sotype.[Name] AS RevType, 
				   ISNULL(sobii.NoofPieces, 0) AS NoofPieces,
				   sobi.GrandTotal,
				   sobi.Notes
			FROM DBO.SalesOrderPart sop WITH (NOLOCK)
			INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
			LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
			INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
			LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
			LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
			INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
			LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = sop.SalesOrderPartId
			LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 1
			LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 1
			WHERE sop.SalesOrderPartId = @SalesOrderPartId;
			END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetProformaInvoicingSODetails' 
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderPartId, '') + ''
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