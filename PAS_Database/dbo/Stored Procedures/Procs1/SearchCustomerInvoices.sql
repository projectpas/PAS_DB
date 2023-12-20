-- =============================================
-- EXEC SearchCustomerInvoices
-- =============================================
CREATE PROCEDURE [dbo].[SearchCustomerInvoices]
	
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 'Invoice' AS 'DocumentType', 
				C.Name AS 'CustName', 
				C.CustomerCode, 
				SOBI.InvoiceNo AS 'DocNum', 
				SOBI.InvoiceDate, 
				S.SalesOrderNumber AS 'WOSONum',
				S.CustomerReference, 
				Curr.Code AS 'CurrencyCode', 
				0 AS 'FxRate', 
				SOBI.GrandTotal AS 'OriginalAmount', 
				SOBI.GrandTotal AS 'RemainingAmount',
				GETDATE() AS 'InvDueDate', 
				DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSI',
				DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSO',
				0.00 AS 'AmountPastDue', 
				S.BalanceDue AS 'ARBalance', 
				ISNULL(S.CreditLimit, 0) AS 'CreditLimit', 
				S.CreditTermName,
				--SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4, 
				(Select COUNT(SOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems'
			FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN Currency Curr WITH (NOLOCK) ON SOBI.CurrencyId = Curr.CurrencyId
				LEFT JOIN SalesOrder S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId
			Where SOBI.InvoiceStatus = 'Invoiced'
				Group By SOBI.InvoiceNo, C.Name, C.CustomerCode, SOBI.InvoiceNo, SOBI.InvoiceDate, S.SalesOrderNumber,
				S.CustomerReference, Curr.Code, SOBI.GrandTotal, SOBI.InvoiceDate, S.BalanceDue, S.CreditLimit, S.CreditTermName
				--SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4

		UNION ALL

		SELECT 'Invoice' AS 'DocumentType', 
				C.Name AS 'CustName', 
				C.CustomerCode, 
				WOBI.InvoiceNo AS 'DocNum', 
				WOBI.InvoiceDate, 
				WO.WorkOrderNum AS 'WOSONum',
				'' AS CustomerReference, 
				Curr.Code AS 'CurrencyCode', 
				0 AS 'FxRate', 
				WOBI.GrandTotal AS 'OriginalAmount', 
				WOBI.GrandTotal AS 'RemainingAmount',
				GETDATE() AS 'InvDueDate', 
				DATEDIFF(DAY, WOBI.InvoiceDate, GETDATE()) AS 'DSI',
				DATEDIFF(DAY, WOBI.InvoiceDate, GETDATE()) AS 'DSO',
				0.00 AS 'AmountPastDue', 
				0.00 AS 'ARBalance', 
				ISNULL(WO.CreditLimit, 0) AS 'CreditLimit', 
				WO.CreditTerms AS 'CreditTermName',
				--WOBI.Level1, WOBI.Level2, WOBI.Level3, WOBI.Level4, 
				(Select COUNT(WOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems'
			FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN Currency Curr WITH (NOLOCK) ON WOBI.CurrencyId = Curr.CurrencyId
				LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
			Where WOBI.InvoiceStatus = 'Invoiced'
				Group By WOBI.InvoiceNo, C.Name, C.CustomerCode, WOBI.InvoiceNo, WOBI.InvoiceDate, WO.WorkOrderNum,
				Curr.Code, WOBI.GrandTotal, WOBI.InvoiceDate, WO.CreditLimit, WO.CreditTerms
				--WOBI.Level1, WOBI.Level2, WOBI.Level3, WOBI.Level4
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