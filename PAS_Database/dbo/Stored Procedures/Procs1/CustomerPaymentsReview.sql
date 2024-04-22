/*************************************************************             
 ** File:   [CustomerPaymentsReview]             
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
	2    20/02/2024    Devendra Shekh	added isDeleted flage
	3    07/03/2024    Moin Bloch	    added AmtApplied Field	
	4    11/03/2024    Moin Bloch	    check misc customer
	5    20/03/2024    Moin Bloch	    changed same customer logic
	6    08/04/2024    Devendra Shekh	remaining amt issue for known customer without invoices resolved
	7    19/04/2024    Moin Bloch	    Duplicate issue

	EXEC [dbo].[CustomerPaymentsReview]  10169
**************************************************************/  

CREATE   PROCEDURE [dbo].[CustomerPaymentsReview]    
@ReceiptId BIGINT = NULL    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON    
 BEGIN TRY    
    	
  --;WITH myCTE(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS    
	 -- (SELECT DISTINCT IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode,     
	 -- LTRIM(RTRIM(A.PaymentRef)) PaymentRef, 
	 -- (ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS 'Amount'
	 -- FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)    
	 -- LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = IPS.CustomerId    
	 -- LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId    
	 -- LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ICP.CustomerId = IPS.CustomerId    
	 -- LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND IWP.CustomerId = IPS.CustomerId    
	 -- LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ICCP.CustomerId = IPS.CustomerId    
	 -- OUTER APPLY(    
	 --  SELECT DISTINCT  ((ISNULL(ICP1.CheckNumber,'')) + (CASE WHEN IWP1.ReferenceNo IS NOT NULL THEN ' ' + IWP1.ReferenceNo ELSE '' END) +     
	 --  (CASE WHEN ICCP1.Reference IS NOT NULL THEN ' ' + ICCP1.Reference ELSE '' END)) AS 'PaymentRef'    
	 --  FROM [dbo].[CustomerPayments] CP1 WITH (NOLOCK) --ON CP.ReceiptId = IPS.ReceiptId    
	 --  LEFT JOIN [dbo].[InvoiceCheckPayment] ICP1 WITH (NOLOCK)  ON ICP1.ReceiptId = CP1.ReceiptId AND ICP1.CustomerId = IPS.CustomerId    
	 --  LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP1 WITH (NOLOCK) ON IWP1.ReceiptId = CP1.ReceiptId AND IWP1.CustomerId = IPS.CustomerId    
	 --  LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP1 WITH (NOLOCK) ON ICCP1.ReceiptId = CP1.ReceiptId AND ICCP1.CustomerId = IPS.CustomerId    
	 --  WHERE CP.ReceiptId = CP1.ReceiptId --AND ICP1.ReceiptId = IPS.ReceiptId --AND ICP1.CustomerId = IPS.CustomerId    
	 -- ) A    
	 -- WHERE CP.ReceiptId = @ReceiptId    
	 -- AND IPS.IsDeleted = 0
	 -- GROUP BY A.PaymentRef, IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, ICP.CheckNumber, IWP.ReferenceNo, ICCP.Reference, ICP.Amount, IWP.Amount, ICCP.Amount, IPS.PaymentAmount)    

	;WITH myCTE(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS 
	  (SELECT  CP.ReceiptId, 
			  CASE WHEN ICP.CustomerId IS NOT NULL THEN CCP.CustomerId
				   ELSE 0 END,
			  CASE WHEN ICP.CustomerId IS NOT NULL THEN  CCP.Name
				   ELSE '' END,
			  CASE WHEN ICP.CustomerId IS NOT NULL THEN  CCP.CustomerCode
				   ELSE '' END,
			  CASE WHEN ICP.CustomerId IS NOT NULL THEN CASE WHEN ISNULL(ICP.CheckNumber,'') = '' THEN 	'~' ELSE ICP.CheckNumber END			  
				   ELSE '' END      
		 ,(ISNULL(ICP.Amount, 0)) AS 'Amount'
	  FROM [dbo].[CustomerPayments] CP WITH (NOLOCK)  
	  LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ISNULL(ICP.Ismiscellaneous,0) = 0  
	  LEFT JOIN [dbo].[Customer] CCP WITH (NOLOCK) ON CCP.CustomerId = ICP.CustomerId 	 
	  WHERE CP.ReceiptId =  @ReceiptId              
	  AND CP.IsDeleted = 0
	  AND ISNULL(ICP.Amount, 0) > 0
	  
	  UNION 

	  SELECT  CP.ReceiptId, 
			  CASE WHEN IWP.CustomerId IS NOT NULL THEN CWP.CustomerId				   
				   ELSE 0 END,
			  CASE WHEN CWP.CustomerId IS NOT NULL THEN  CWP.Name				   
				   ELSE '' END,
			  CASE WHEN IWP.CustomerId IS NOT NULL THEN  CWP.CustomerCode				   
				   ELSE '' END,
			  CASE WHEN IWP.CustomerId IS NOT NULL THEN CASE WHEN ISNULL(IWP.ReferenceNo,'') = '' THEN 	'~' ELSE IWP.ReferenceNo END 				   
				   ELSE '' END      
		 ,ISNULL(IWP.Amount, 0) AS 'Amount'
	  FROM [dbo].[CustomerPayments] CP WITH (NOLOCK)  
	  LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND ISNULL(IWP.Ismiscellaneous,0) = 0     
	  LEFT JOIN [dbo].[Customer] CWP WITH (NOLOCK) ON CWP.CustomerId = IWP.CustomerId 
	  WHERE CP.ReceiptId =  @ReceiptId              
	  AND CP.IsDeleted = 0	 
	  AND ISNULL(IWP.Amount,0) > 0

	  UNION 

	  SELECT  CP.ReceiptId, 
			  CASE WHEN ICCP.CustomerId IS NOT NULL THEN CDP.CustomerId
				   ELSE 0 END,
			  CASE WHEN ICCP.CustomerId IS NOT NULL THEN CDP.Name
				   ELSE '' END,
			  CASE WHEN ICCP.CustomerId IS NOT NULL THEN CDP.CustomerCode
				   ELSE '' END,
			  CASE WHEN ICCP.CustomerId IS NOT NULL THEN CASE WHEN ISNULL(ICCP.Reference,'') = '' THEN 	'~' ELSE ICCP.Reference END
				   ELSE '' END      
		 , ISNULL(ICCP.Amount, 0) AS 'Amount'
	  FROM [dbo].[CustomerPayments] CP WITH (NOLOCK)  
	  LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ISNULL(ICCP.Ismiscellaneous,0) = 0         
	  LEFT JOIN [dbo].[Customer] CDP WITH (NOLOCK) ON CDP.CustomerId = ICCP.CustomerId     
	  WHERE CP.ReceiptId =  @ReceiptId              
	  AND CP.IsDeleted = 0	
	  AND ISNULL(ICCP.Amount, 0) > 0
	) 
	  
  , myCTE1(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS     
	  (SELECT DISTINCT ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, SUM(C.Amount) As Amount    
	   FROM myCTE C GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef)    
  
  , myCTE2(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS     
	  (SELECT C.ReceiptId, C.CustomerId, Name, CustomerCode,     
		CASE WHEN ISNULL(LTRIM(RTRIM(C.PaymentRef)),'') <> '' THEN   
		  STUFF(    
			  (SELECT ' ' + PaymentRef    
			 FROM myCTE1 i2    
			 WHERE C.ReceiptId = i2.ReceiptId AND C.CustomerId = i2.CustomerId    
			 FOR XML PATH(''))    
			  , 1, 1, ''    
		   )    
		   ELSE '' END  
		  AS PaymentRef    
		  , Amount 
		  FROM myCTE1 C    
		  LEFT JOIN [dbo].[InvoicePayments] IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId    
		  GROUP BY C.ReceiptId, C.CustomerId, Name, CustomerCode,C.PaymentRef, Amount)  
	  
  ,myCTE3(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS     
	  (SELECT DISTINCT ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, SUM(C.Amount) As Amount    
	   FROM myCTE2 C    
	  GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef) 
	  
  ,myCTE4(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount, AmountRemaining, AmtApplied) AS     
	  (SELECT C.ReceiptId, 
			 C.CustomerId, 
			 C.[Name], 
			 C.CustomerCode,     
			 REPLACE(PaymentRef, '~' ,'') AS PaymentRef,
			 Amount, 
			 CASE WHEN ISNULL(IPS.PaymentId, 0) = 0 AND ISNULL(CU.Ismiscellaneous, 0) = 0 THEN Amount ELSE (Amount - SUM(IPS.PaymentAmount) + ISNULL(SUM(CASE WHEN IPS.InvoiceType = 3 THEN ABS(ISNULL(IPS.OriginalAmount,0)) ELSE 0 END),0))  END AS AmountRemaining,
			(Amount - (Amount - SUM(IPS.PaymentAmount) + ISNULL(SUM(CASE WHEN IPS.InvoiceType = 3 THEN ABS(ISNULL(IPS.OriginalAmount,0)) ELSE 0 END),0)))  AS AmtApplied  
		  FROM myCTE3 C          
	  LEFT JOIN [dbo].[InvoicePayments] IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId    
	  LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.CustomerId = C.CustomerId    
	  GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, Amount, PaymentRef, IPS.PaymentId, CU.Ismiscellaneous)
  
   SELECT [ReceiptId],
          [CustomerId],
		  [Name],
		  [CustomerCode],
		  [PaymentRef],
		  ISNULL([Amount],0)AS Amount,
		  ISNULL(SUM(AmountRemaining),0) AS AmountRemaining,
		  ISNULL(SUM(AmtApplied),0) AS AmtApplied
     FROM myCTE4 GROUP BY 
	      [ReceiptId],
          [CustomerId],
		  [Name],
		  [CustomerCode],
		  [PaymentRef],
	      [Amount]
		
	  UNION ALL

	  SELECT CP.ReceiptId, 
			 CASE WHEN ICP.CustomerId IS NOT NULL THEN ICP.CustomerId 
				  WHEN IWP.CustomerId IS NOT NULL THEN IWP.CustomerId 
				  WHEN ICCP.CustomerId IS NOT NULL THEN ICCP.CustomerId 
				  ELSE 0 END AS CustomerId,
			 CASE WHEN ICP.CustomerId IS NOT NULL THEN CCP.Name 
				  WHEN IWP.CustomerId IS NOT NULL THEN CWP.Name 
				  WHEN ICCP.CustomerId IS NOT NULL THEN CCDP.Name 
				  ELSE '' END AS [Name],
			 CASE WHEN ICP.CustomerId IS NOT NULL THEN CCP.CustomerCode 
				  WHEN IWP.CustomerId IS NOT NULL THEN CWP.CustomerCode 
				  WHEN ICCP.CustomerId IS NOT NULL THEN CCDP.CustomerCode 
				  ELSE '' END AS CustomerCode,
			LTRIM(RTRIM(A.PaymentRef)) PaymentRef, 
			(ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS 'Amount',
			0 AmountRemaining,
			(ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS 'AmtApplied'	
	   FROM [dbo].[CustomerPayments] CP WITH (NOLOCK) 
	  LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ICP.Ismiscellaneous = 1   
	  LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND IWP.Ismiscellaneous = 1  
	  LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ICCP.Ismiscellaneous = 1  
	  LEFT JOIN [dbo].[Customer] CCP WITH (NOLOCK) ON CCP.CustomerId = ICP.CustomerId  
	  LEFT JOIN [dbo].[Customer] CWP WITH (NOLOCK) ON CWP.CustomerId = IWP.CustomerId  
	  LEFT JOIN [dbo].[Customer] CCDP WITH (NOLOCK) ON CCDP.CustomerId = ICCP.CustomerId  
	  OUTER APPLY(    
		   SELECT DISTINCT  ((ISNULL(ICP1.CheckNumber,'')) + (CASE WHEN IWP1.ReferenceNo IS NOT NULL THEN ' ' + IWP1.ReferenceNo ELSE '' END) +     
		   (CASE WHEN ICCP1.Reference IS NOT NULL THEN ' ' + ICCP1.Reference ELSE '' END)) AS 'PaymentRef'    
		   FROM [dbo].[CustomerPayments] CP1 WITH (NOLOCK)
		   LEFT JOIN [dbo].[InvoiceCheckPayment] ICP1 WITH (NOLOCK)  ON ICP1.ReceiptId = CP1.ReceiptId AND ICP1.Ismiscellaneous = 1  
		   LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP1 WITH (NOLOCK) ON IWP1.ReceiptId = CP1.ReceiptId AND IWP1.Ismiscellaneous = 1  
		   LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP1 WITH (NOLOCK) ON ICCP1.ReceiptId = CP1.ReceiptId AND ICCP1.Ismiscellaneous = 1  
		   WHERE CP.ReceiptId = CP1.ReceiptId 
	  ) A  
	  WHERE CP.[ReceiptId] = @ReceiptId AND (ICP.CustomerId > 0 OR IWP.CustomerId > 0 OR ICCP.CustomerId > 0)

 END TRY        
  BEGIN CATCH    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'CustomerPaymentsReview'                  
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReceiptId, '') AS VARCHAR(100))  
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