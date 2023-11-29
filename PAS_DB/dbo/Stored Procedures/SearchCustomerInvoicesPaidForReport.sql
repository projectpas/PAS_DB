
-- EXEC SearchCustomerInvoicesPaidForReport 49
CREATE     PROCEDURE [dbo].[SearchCustomerInvoicesPaidForReport]
@ReceiptId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

			 IF OBJECT_ID(N'tempdb..#Paymenttemp') IS NOT NULL    
			 BEGIN    
				DROP TABLE #Paymenttemp
			 END        
			 CREATE TABLE #Paymenttemp
			 (   
				ID BIGINT IDENTITY(1,1),
				ReceiptId BIGINT NULL,    
				CustomerId  BIGINT NULL, 
				CustName [varchar](100) NULL,
				CustomerCode [VARCHAR](50) NULL,
				Amount DECIMAL(18,2) NULL,
				AmountRemaining DECIMAL(18,2) NULL
             )    
			;WITH myCTE(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS
			(SELECT DISTINCT IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode,A.PaymentRef,
		(ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS 'Amount'
		FROM DBO.InvoicePayments IPS WITH (NOLOCK)
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = IPS.CustomerId
		LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
		--LEFT JOIN (SELECT Amount, ReceiptId, CustomerId, CheckNumber FROM DBO.InvoiceCheckPayment WITH (NOLOCK)) ICP ON ICP.ReceiptId = CP.ReceiptId AND ICP.CustomerId = IPS.CustomerId
		LEFT JOIN DBO.InvoiceCheckPayment ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ICP.CustomerId = IPS.CustomerId
		LEFT JOIN DBO.InvoiceWireTransferPayment IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND IWP.CustomerId = IPS.CustomerId
		LEFT JOIN DBO.InvoiceCreditDebitCardPayment ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ICCP.CustomerId = IPS.CustomerId
		OUTER APPLY(
			SELECT DISTINCT (ICP1.CheckNumber + (CASE WHEN IWP.ReferenceNo IS NOT NULL THEN ' ' + IWP.ReferenceNo ELSE '' END) + 
			(CASE WHEN ICCP.Reference IS NOT NULL THEN ' ' + ICCP.Reference ELSE '' END)) AS 'PaymentRef'
			FROM DBO.InvoiceCheckPayment ICP1 WITH (NOLOCK)
			LEFT JOIN DBO.InvoiceWireTransferPayment IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND IWP.CustomerId = IPS.CustomerId
			LEFT JOIN DBO.InvoiceCreditDebitCardPayment ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ICCP.CustomerId = IPS.CustomerId
			Where ICP1.ReceiptId = IPS.ReceiptId AND ICP1.CustomerId = IPS.CustomerId
		) A
		Where CP.ReceiptId = @ReceiptId
		GROUP BY A.PaymentRef, IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, ICP.CheckNumber, IWP.ReferenceNo, ICCP.Reference, ICP.Amount, IWP.Amount, ICCP.Amount, IPS.PaymentAmount)

		, myCTE1(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS 
		(SELECT DISTINCT ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, SUM(C.Amount) As Amount
		FROM myCTE C
		GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef)

		, myCTE2(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS 
		(SELECT C.ReceiptId, C.CustomerId, Name, CustomerCode, 
		STUFF(
			   (SELECT ' ' + PaymentRef
					FROM myCTE1 i2
					WHERE C.ReceiptId = i2.ReceiptId AND C.CustomerId = i2.CustomerId
					FOR XML PATH(''))
			   , 1, 1, ''
			)
		AS PaymentRef
		, Amount FROM myCTE1 C
		LEFT JOIN InvoicePayments IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId
		GROUP BY C.ReceiptId, C.CustomerId, Name, CustomerCode, Amount)

		INSERT INTO #Paymenttemp (ReceiptId,CustomerId,CustName,CustomerCode,Amount,AmountRemaining)
		SELECT C.ReceiptId, C.CustomerId, Name, CustomerCode, 
		--Amount, (Amount - SUM(IPS.PaymentAmount) - ISNULL(SUM(IPS.DiscAmount),0) - ISNULL(SUM(IPS.BankFeeAmount),0) - ISNULL(SUM(IPS.OtherAdjustAmt),0)) AS AmountRemaining FROM myCTE2 C
		  Amount, (Amount - SUM(IPS.PaymentAmount))  AS AmountRemaining FROM myCTE2 C
		LEFT JOIN InvoicePayments IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId
		GROUP BY C.ReceiptId, C.CustomerId, Name, CustomerCode, Amount, PaymentRef
						
			 SELECT [IP].[PaymentId], 					
					[CU].[CustomerId],
				    [CU].[Name] AS 'CustName', 
					[CU].[CustomerCode], 	
					[PT].[Amount] as AppliedAmount,
					[PT].[AmountRemaining] as AppliedRemainingAmount,
					[IP].[DocNum], 					
					FORMAT([IP].[InvoiceDate], 'MM/dd/yyyy') AS InvoiceDate,					
					[IP].[WOSONum],					
					[IP].[CurrencyCode],				
					[IP].[OriginalAmount] AS 'OriginalAmount', 				
					CASE WHEN [InvoiceType] = 1 THEN SOBI.[RemainingAmount] ELSE WOBI.[RemainingAmount] END AS 'RemainingAmount',						
					CASE WHEN (CT.[NetDays] - DATEDIFF(DAY, CASt([IP].[InvoiceDate] as date), GETDATE())) < 0 THEN [IP].[RemainingAmount] ELSE 0.00 END AS 'AmountPastDue',						
					[IP].[PaymentAmount], 					
					[IP].[NewRemainingBal] AS 'NewRemainingBal'

		FROM [dbo].[InvoicePayments] [IP] WITH (NOLOCK) 	
		INNER JOIN #Paymenttemp [PT] WITH (NOLOCK) ON PT.CustomerId = IP.CustomerId  
		LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON [IP].CustomerId = CU.CustomerId
		LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON [IP].CustomerId = CF.CustomerId
		LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId	
		LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId
		LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = [IP].SOBillingInvoicingId
		WHERE 
		[IP].ReceiptId = @receiptId AND [IP].IsDeleted=0
		Group By [IP].[PaymentId],CU.[CustomerId],CU.[Name],CU.[CustomerCode],[IP].[DocNum],[IP].[InvoiceDate],[IP].[WOSONum],[IP].[RemainingAmount],		
				 [IP].[CurrencyCode],[IP].[OriginalAmount],[IP].[RemainingAmount],[IP].[PaymentAmount], 
				 [IP].NewRemainingBal,SOBI.RemainingAmount,WOBI.RemainingAmount,[IP].[InvoiceType],[CT].[NetDays],[PT].Amount,PT.[AmountRemaining]     

	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'SearchCustomerInvoicesPaidForReport' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@ReceiptId AS VARCHAR(10)), '') + ''
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