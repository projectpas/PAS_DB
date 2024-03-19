/*************************************************************             
 ** File:   [SearchCustomerInvoicesPaid]             
 ** Author:   
 ** Description: This stored procedure is used to GET Customer Invoices 
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date          Author			Change Description              
 ** --   --------      -------			-------------------------------            
	1                  unknown			Created	
	2    16/10/2023    MOIN BLOCH		Modify(Added INVOICE TYPE FOR Stand Alone Credit Memo / Manual Journal)
	3    22/11/2023    AMIT GHEDIYA     Modify(Added INVOICE TYPE FOR Exchange Invoice)
	4    18/03/2024    Moin Bloch       Modify(Changed DSO Logic)


	EXEC [dbo].[SearchCustomerInvoicesPaid]  1,1
**************************************************************/  
CREATE     PROCEDURE [dbo].[SearchCustomerInvoicesPaid]  
@customerId bigint = NULL,  
@receiptId bigint = NULL  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	DECLARE @SOInvoiceType INT = 1
	DECLARE @WOInvoiceType INT = 2
	DECLARE	@CREDITMEMO INT = 3
	DECLARE	@STANDALONECREDITMEMO INT = 4
	DECLARE	@MANUALJOURNAL INT = 5
	DECLARE	@ESOInvoiceType INT = 6
	
    SELECT [IP].PaymentId,   
	 CASE WHEN IP.InvoiceType = @SOInvoiceType THEN 'INVOICE' 
	      WHEN IP.InvoiceType = @WOInvoiceType THEN 'INVOICE'  
		  WHEN IP.InvoiceType = @CREDITMEMO THEN 'CREDIT MEMO'  
		  WHEN IP.InvoiceType = @STANDALONECREDITMEMO THEN 'STAND ALONE CREDIT MEMO' 
		  WHEN IP.InvoiceType = @MANUALJOURNAL THEN 'MANUAL JOURNAL' 
		  WHEN IP.InvoiceType = @ESOInvoiceType THEN 'INVOICE'
	  END AS 'DocumentType', 
     C.Name AS 'CustName',   
     C.CustomerCode,   
     [IP].SOBillingInvoicingId,   
     UPPER([IP].DocNum) AS DocNum,   
     [IP].InvoiceDate,  
     UPPER([IP].WOSONum) AS WOSONum,  
     [IP].CurrencyCode,  
     0 AS 'FxRate',   
     [IP].OriginalAmount AS 'OriginalAmount',   
     CASE WHEN InvoiceType = @SOInvoiceType THEN SOBI.RemainingAmount WHEN InvoiceType = @WOInvoiceType THEN WOBI.RemainingAmount WHEN InvoiceType = @ESOInvoiceType THEN ESOBI.RemainingAmount ELSE 0 END AS 'RemainingAmount',  
     GETUTCDATE() AS 'InvDueDate',   
     CASE WHEN (IP.InvoiceType = @CREDITMEMO OR IP.InvoiceType = @STANDALONECREDITMEMO OR IP.InvoiceType = @MANUALJOURNAL)
	      THEN 0 
		  ELSE CASE WHEN IP.InvoiceType = @SOInvoiceType AND SOBI.IsProforma = 1 
				    THEN 0 
				    WHEN IP.InvoiceType = @SOInvoiceType AND ISNULL(SOBI.IsProforma,0) = 0
				    THEN DATEDIFF(DAY, [IP].InvoiceDate, GETUTCDATE())
				    WHEN IP.InvoiceType = @WOInvoiceType AND WOBI.IsPerformaInvoice = 1 
				    THEN 0 
				    WHEN IP.InvoiceType = @WOInvoiceType AND ISNULL(WOBI.IsPerformaInvoice,0 ) = 0
				    THEN DATEDIFF(DAY, [IP].InvoiceDate, GETUTCDATE())
				    WHEN IP.InvoiceType = @ESOInvoiceType
				    THEN DATEDIFF(DAY, [IP].InvoiceDate, GETUTCDATE())
			END
	  END AS 'DSI', 
	  CASE WHEN (IP.InvoiceType = @CREDITMEMO OR IP.InvoiceType = @STANDALONECREDITMEMO OR IP.InvoiceType = @MANUALJOURNAL)
	      THEN 0 
		  ELSE CASE WHEN IP.InvoiceType = @SOInvoiceType AND SOBI.IsProforma = 1 
				    THEN 0 
				    WHEN IP.InvoiceType = @SOInvoiceType AND ISNULL(SOBI.IsProforma,0) = 0
				    THEN CASE WHEN (DATEDIFF(DAY, IP.InvoiceDate, GETUTCDATE()) - ISNULL(CT.NetDays,0)) > 0 
			                  THEN (DATEDIFF(DAY, IP.InvoiceDate, GETUTCDATE()) - ISNULL(CT.NetDays,0)) ELSE 0 END
				    WHEN IP.InvoiceType = @WOInvoiceType AND WOBI.IsPerformaInvoice = 1 
				    THEN 0 
				    WHEN IP.InvoiceType = @WOInvoiceType AND ISNULL(WOBI.IsPerformaInvoice,0 ) = 0
				    THEN CASE WHEN (DATEDIFF(DAY, IP.InvoiceDate, GETUTCDATE()) - ISNULL(CT.NetDays,0)) > 0 
			                  THEN (DATEDIFF(DAY, IP.InvoiceDate, GETUTCDATE()) - ISNULL(CT.NetDays,0)) ELSE 0 END
				    WHEN IP.InvoiceType = @ESOInvoiceType
				    THEN CASE WHEN (DATEDIFF(DAY, IP.InvoiceDate, GETUTCDATE()) - ISNULL(CT.NetDays,0)) > 0 
			                  THEN (DATEDIFF(DAY, IP.InvoiceDate, GETUTCDATE()) - ISNULL(CT.NetDays,0)) ELSE 0 END
			END
	 END AS 'DSO', 		
	 CASE WHEN (CT.NetDays - DATEDIFF(DAY, CASt([IP].InvoiceDate as date), GETUTCDATE())) < 0 THEN [IP].RemainingAmount ELSE 0.00 END AS 'AmountPastDue',    
     ([IP].RemainingAmount - [IP].PaymentAmount) AS 'ARBalance',   
     ISNULL([IP].CreditLimit, 0) AS 'CreditLimit',   
     [IP].CreditTermName,  
     [IP].LastMSLevel,  
     [IP].AllMSlevels,  
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
FROM [dbo].[InvoicePayments] [IP] WITH (NOLOCK)    
	  LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON [IP].CustomerId = C.CustomerId  
	  LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON [IP].CustomerId = CF.CustomerId  
	  LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId   
	  LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId AND IP.InvoiceType = @SOInvoiceType  
	  LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = [IP].SOBillingInvoicingId  AND IP.InvoiceType = @WOInvoiceType 
	  LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK) ON ESOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId  
WHERE [IP].CustomerId = @customerId AND [IP].ReceiptId = @receiptId AND [IP].IsDeleted=0  
	  GROUP BY [IP].PaymentId, C.Name, C.CustomerCode, [IP].SOBillingInvoicingId,[IP].DocNum,[IP].InvoiceDate,[IP].WOSONum,[IP].RemainingAmount,    
     [IP].CurrencyCode,[IP].OriginalAmount,[IP].RemainingAmount,[IP].ARBalance,[IP].CreditLimit,[IP].CreditTermName,[IP].PaymentAmount,   
     [IP].DiscAmount,[IP].DiscType,[IP].BankFeeAmount,[IP].BankFeeType,[IP].OtherAdjustAmt,[IP].Reason,[IP].NewRemainingBal,  
     [IP].Status,[IP].CtrlNum,[IP].LastMSLevel,[IP].AllMSlevels,[IP].InvoiceType,[IP].Id,[IP].ReceiptId,[IP].GLARAccount,[CT].NetDays,  
     [IP].AmountPastDue,[IP].CreatedDate,SOBI.RemainingAmount,WOBI.RemainingAmount,ESOBI.RemainingAmount,  
     SOBI.IsProforma,WOBI.IsPerformaInvoice
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