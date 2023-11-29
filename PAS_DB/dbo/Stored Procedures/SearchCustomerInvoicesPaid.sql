-- EXEC [dbo].[SearchCustomerInvoicesPaid] 68,10153  
CREATE   PROCEDURE [dbo].[SearchCustomerInvoicesPaid]  
 @customerId bigint = null,  
 @receiptId bigint = null  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
    SELECT [IP].PaymentId,   
     CASE WHEN IP.InvoiceType = 3 THEN 'Credit Memo' ELSE 'Invoice' END AS 'DocumentType',   
        C.Name AS 'CustName',   
     C.CustomerCode,   
     [IP].SOBillingInvoicingId,   
     [IP].DocNum,   
     [IP].InvoiceDate,  
     --S.SalesOrderNumber AS 'WOSONum',  
     [IP].WOSONum,  
     --S.CustomerReference,   
     --Curr.Code AS 'CurrencyCode',   
     [IP].CurrencyCode,  
     0 AS 'FxRate',   
     [IP].OriginalAmount AS 'OriginalAmount',   
     --[IP].RemainingAmount AS 'RemainingAmount',  
     CASE WHEN InvoiceType = 1 THEN SOBI.RemainingAmount WHEN InvoiceType = 2 THEN WOBI.RemainingAmount ELSE 0 END AS 'RemainingAmount',  
     GETDATE() AS 'InvDueDate',   
     CASE WHEN IP.InvoiceType = 3 THEN 0 ELSE DATEDIFF(DAY, [IP].InvoiceDate, GETDATE()) END AS 'DSI',       
     CASE WHEN IP.InvoiceType = 3 THEN 0 ELSE (CT.NetDays - DATEDIFF(DAY, CASt([IP].InvoiceDate as date), GETDATE())) END AS 'DSO',  
     CASE WHEN (CT.NetDays - DATEDIFF(DAY, CASt([IP].InvoiceDate as date), GETDATE())) < 0 THEN [IP].RemainingAmount ELSE 0.00 END AS 'AmountPastDue',    
     --[IP].AmountPastDue AS 'AmountPastDue',   
     ([IP].RemainingAmount - [IP].PaymentAmount) AS 'ARBalance',   
     --ISNULL([IP].CreditLimit, 0) AS 'ARBalance',  
     ISNULL([IP].CreditLimit, 0) AS 'CreditLimit',   
     [IP].CreditTermName,  
     --(Select COUNT(SOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems',   
     [IP].LastMSLevel,  
     [IP].AllMSlevels,  
     --SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4,  
     [IP].PaymentAmount,   
     [IP].DiscAmount,   
     [IP].DiscType,   
     [IP].BankFeeAmount,   
     [IP].BankFeeType,   
     [IP].OtherAdjustAmt,   
     [IP].Reason,   
     [IP].NewRemainingBal AS 'NewRemainingBal',   
     [IP].Status,   
     [IP].CtrlNum,  
     [IP].InvoiceType,  
     [IP].Id,  
     [IP].ReceiptId,  
     [IP].GLARAccount,  
     [IP].CreatedDate  
	  FROM InvoicePayments [IP] WITH (NOLOCK)    
	  LEFT JOIN Customer C WITH (NOLOCK) ON [IP].CustomerId = C.CustomerId  
	  LEFT JOIN CustomerFinancial CF WITH (NOLOCK) ON [IP].CustomerId = CF.CustomerId  
	  LEFT JOIN CreditTerms CT WITH (NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId   
	  LEFT JOIN SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId  
	  LEFT JOIN WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = [IP].SOBillingInvoicingId  
	  WHERE [IP].CustomerId = @customerId AND [IP].ReceiptId = @receiptId AND [IP].IsDeleted=0  
	  Group By [IP].PaymentId, C.Name, C.CustomerCode, [IP].SOBillingInvoicingId,[IP].DocNum,[IP].InvoiceDate,[IP].WOSONum,[IP].RemainingAmount,    
     [IP].CurrencyCode,[IP].OriginalAmount,[IP].RemainingAmount,[IP].ARBalance,[IP].CreditLimit,[IP].CreditTermName,[IP].PaymentAmount,   
     [IP].DiscAmount,[IP].DiscType,[IP].BankFeeAmount,[IP].BankFeeType,[IP].OtherAdjustAmt,[IP].Reason,[IP].NewRemainingBal,  
     [IP].Status,[IP].CtrlNum,[IP].LastMSLevel,[IP].AllMSlevels,[IP].InvoiceType,[IP].Id,[IP].ReceiptId,[IP].GLARAccount,[CT].NetDays,  
     [IP].AmountPastDue,[IP].CreatedDate,SOBI.RemainingAmount,WOBI.RemainingAmount  
  
        -- OLD SP  
  --SELECT [IP].PaymentId, 'Invoice' AS 'DocumentType', C.Name AS 'CustName', C.CustomerCode, SOBI.SOBillingInvoicingId, SOBI.InvoiceNo AS 'DocNum', SOBI.InvoiceDate, S.SalesOrderNumber AS 'WOSONum',  
  --S.CustomerReference, Curr.Code AS 'CurrencyCode', 0 AS 'FxRate', SOBI.GrandTotal AS 'OriginalAmount', SOBI.GrandTotal AS 'RemainingAmount',  
  --GETDATE() AS 'InvDueDate', DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSI',  
  --DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSO',  
  --0.00 AS 'AmountPastDue', S.BalanceDue AS 'ARBalance', ISNULL(S.CreditLimit, 0) AS 'CreditLimit', S.CreditTermName,  
  --(Select COUNT(SOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems',   
  --SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4,  
  --[IP].PaymentAmount, [IP].DiscAmount, [IP].DiscType, [IP].BankFeeAmount, [IP].BankFeeType,   
  --[IP].OtherAdjustAmt, [IP].Reason, [IP].RemainingBalance AS 'NewRemainingBal', [IP].Status, [IP].CtrlNum  
  --FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)  
  --INNER JOIN InvoicePayments AS [IP] WITH (NOLOCK) ON [IP].SOBillingInvoicingId = SOBI.SOBillingInvoicingId  
  --left join Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId  
  --LEFT JOIN Currency Curr WITH (NOLOCK) ON SOBI.CurrencyId = Curr.CurrencyId  
  --LEFT JOIN SalesOrder S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId  
  --Where SOBI.InvoiceStatus = 'Invoiced'  
  --AND [IP].CustomerId = @customerId AND [IP].ReceiptId = @receiptId  
  --Group By [IP].PaymentId, SOBI.InvoiceNo, C.Name, C.CustomerCode, SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceDate, S.SalesOrderNumber,  
  --S.CustomerReference, Curr.Code, SOBI.GrandTotal, SOBI.InvoiceDate, S.BalanceDue, S.CreditLimit, S.CreditTermName,  
  --SOBI.Level1, SOBI.Level2, SOBI.Level3, SOBI.Level4,   
  --[IP].PaymentAmount, [IP].DiscAmount, [IP].DiscType, [IP].BankFeeAmount, [IP].BankFeeType, [IP].OtherAdjustAmt,   
  --[IP].Reason, [IP].RemainingBalance, [IP].Status, [IP].CtrlNum  
  
  
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'SearchCustomerInvoicesPaid'   
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@customerId AS VARCHAR(10)), '') + ''  
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