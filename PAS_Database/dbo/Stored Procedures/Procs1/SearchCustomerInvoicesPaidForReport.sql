/*************************************************************           
 ** File:   [SearchCustomerInvoicesPaidForReport]
 ** Author: unknown
 ** Description:
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	02/1/2024		AMIT GHEDIYA	added isperforma Flage for SO
	3	07/03/2024		Moin Bloch  	added Document Type
************************************************************************/
-- EXEC SearchCustomerInvoicesPaidForReport 129
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
					[IP].[NewRemainingBal] AS 'NewRemainingBal',					
					CASE WHEN [InvoiceType] = 1 AND SOBI.[IsProforma] = 1 THEN 'PROFORMA INVOICE' 
					     WHEN [InvoiceType] = 1 AND ISNULL(SOBI.[IsProforma],0) = 0  THEN 'INVOICE' 
						 WHEN [InvoiceType] = 2 AND WOBI.[IsPerformaInvoice] = 1 THEN 'PROFORMA INVOICE'
						 WHEN [InvoiceType] = 2 AND ISNULL(WOBI.IsPerformaInvoice,0) = 0  THEN 'INVOICE' 
						 WHEN [InvoiceType] = 3 THEN 'CREDIT MEMO' 
						 WHEN [InvoiceType] = 4 THEN 'STAND ALONE CREDIT MEMO'
						 WHEN [InvoiceType] = 5 THEN 'MANUAL JOURNAL'
						 WHEN [InvoiceType] = 6 THEN 'EXCHANGE INVOICE'
					     END  AS 'DocumentType',
					0 AS Ismiscellaneous 
		FROM [dbo].[InvoicePayments] [IP] WITH (NOLOCK) 	
		INNER JOIN #Paymenttemp [PT] WITH (NOLOCK) ON PT.CustomerId = IP.CustomerId  
		LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON [IP].CustomerId = CU.CustomerId
		LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON [IP].CustomerId = CF.CustomerId
		LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId	
		LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId --AND ISNULL(SOBI.IsProforma,0) = 0
		LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = [IP].SOBillingInvoicingId
		WHERE [IP].ReceiptId = @receiptId AND [IP].IsDeleted=0
		GROUP BY [IP].[PaymentId],CU.[CustomerId],CU.[Name],CU.[CustomerCode],[IP].[DocNum],[IP].[InvoiceDate],[IP].[WOSONum],[IP].[RemainingAmount],		
				 [IP].[CurrencyCode],[IP].[OriginalAmount],[IP].[RemainingAmount],[IP].[PaymentAmount], 
				 [IP].NewRemainingBal,SOBI.RemainingAmount,WOBI.RemainingAmount,[IP].[InvoiceType],[CT].[NetDays],[PT].Amount,PT.[AmountRemaining],     
				 [SOBI].[IsProforma],[WOBI].[IsPerformaInvoice]

		UNION ALL

			 SELECT  0 AS [PaymentId], 										
					 CASE WHEN ICP.CustomerId IS NOT NULL THEN ICP.CustomerId 
						  WHEN IWP.CustomerId IS NOT NULL THEN IWP.CustomerId 
						  WHEN ICCP.CustomerId IS NOT NULL THEN ICCP.CustomerId 
						  ELSE 0 END AS CustomerId,
					 CASE WHEN ICP.CustomerId IS NOT NULL THEN CCP.[Name] 
						  WHEN IWP.CustomerId IS NOT NULL THEN CWP.[Name] 
						  WHEN ICCP.CustomerId IS NOT NULL THEN CCDP.[Name] 
						  ELSE '' END AS 'CustName',
					CASE WHEN ICP.CustomerId IS NOT NULL THEN CCP.CustomerCode 
						 WHEN IWP.CustomerId IS NOT NULL THEN CWP.CustomerCode 
						 WHEN ICCP.CustomerId IS NOT NULL THEN CCDP.CustomerCode 
						 ELSE '' END AS CustomerCode,
				    (ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS AppliedAmount,
					0.00 AppliedRemainingAmount,			  
					'' AS [DocNum], 					
					'' AS InvoiceDate,					
					'' AS [WOSONum],					
					'' AS [CurrencyCode],				
					0.00 AS 'OriginalAmount', 				
					0.00 AS 'RemainingAmount',						
					0.00 AS 'AmountPastDue',						
					0.00 AS [PaymentAmount], 					
					0.00 AS 'NewRemainingBal',					
					''  AS 'DocumentType',
					1 AS Ismiscellaneous 
				 FROM [dbo].[CustomerPayments] CP WITH (NOLOCK) 
		  LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ICP.Ismiscellaneous = 1   
		  LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND IWP.Ismiscellaneous = 1   
		  LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ICCP.Ismiscellaneous = 1   
		  LEFT JOIN [dbo].[Customer] CCP WITH (NOLOCK) ON CCP.CustomerId = ICP.CustomerId  
		  LEFT JOIN [dbo].[Customer] CWP WITH (NOLOCK) ON CWP.CustomerId = IWP.CustomerId  
		  LEFT JOIN [dbo].[Customer] CCDP WITH (NOLOCK) ON CCDP.CustomerId = ICCP.CustomerId  
		 WHERE CP.[ReceiptId] = @ReceiptId AND (ICP.CustomerId > 0 OR IWP.CustomerId > 0 OR ICCP.CustomerId > 0)


	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'SearchCustomerInvoicesPaidForReport' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@ReceiptId AS VARCHAR(100)), '') + ''
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