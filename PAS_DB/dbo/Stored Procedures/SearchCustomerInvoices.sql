-- =============================================

-- =============================================
CREATE PROCEDURE [dbo].[SearchCustomerInvoices]
	
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 'Invoice' AS 'DocumentType', C.Name AS 'CustName', C.CustomerCode, SOBI.InvoiceNo AS 'DocNum', SOBI.InvoiceDate, S.SalesOrderNumber AS 'WOSONum',
		S.CustomerReference, Curr.Code AS 'CurrencyCode', 0 AS 'FxRate', SOBI.GrandTotal AS 'OriginalAmount', SOBI.GrandTotal AS 'RemainingAmount',
		GETDATE() AS 'InvDueDate', DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSI',
		DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSO',
		0.00 AS 'AmountPastDue', S.BalanceDue AS 'ARBalance', ISNULL(S.CreditLimit, 0) AS 'CreditLimit', S.CreditTermName,
		SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4, 
		(Select COUNT(SOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems'
		FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
		left join Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
		LEFT JOIN Currency Curr WITH (NOLOCK) ON SOBI.CurrencyId = Curr.CurrencyId
		LEFT JOIN SalesOrder S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId
		Where SOBI.InvoiceStatus = 'Invoiced'
		Group By SOBI.InvoiceNo, C.Name, C.CustomerCode, SOBI.InvoiceNo, SOBI.InvoiceDate, S.SalesOrderNumber,
		S.CustomerReference, Curr.Code, SOBI.GrandTotal, SOBI.InvoiceDate, S.BalanceDue, S.CreditLimit, S.CreditTermName,
		SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4
	END TRY    
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SearchCustomerInvoices' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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