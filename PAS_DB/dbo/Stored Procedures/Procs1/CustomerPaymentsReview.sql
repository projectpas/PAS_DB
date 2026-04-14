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
	8    20/06/2024    Moin Bloch	    Added isDeleted flage
	9    11/07/2024    Moin Bloch	    Fix For Stand Alone Credit Memo
	10   10/04/2026    Moin Bloch       Added New Field [IsNonInvoicePayment] PN-15989
	11   13/04/2026    Moin Bloch       Fix Duplicate lines generated in Review & Post for multiple Non-Invoice Payments PN-16040
	

	EXEC [dbo].[CustomerPaymentsReview]  10243
**************************************************************/  

CREATE   PROCEDURE [dbo].[CustomerPaymentsReview]    
@ReceiptId BIGINT = NULL    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON    
 BEGIN TRY    
    	
	 DECLARE @CreditMemoInvoiceType INT = 3;
	 DECLARE @StandAloneCreditMemoInvoiceType INT = 4;

	;WITH myCTE(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount, IsNonInvoicePayment) AS 
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
		 ,ISNULL(ICP.[IsNonInvoicePayment],0)
	  FROM [dbo].[CustomerPayments] CP WITH (NOLOCK)  
	  LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ISNULL(ICP.Ismiscellaneous,0) = 0 AND ISNULL(ICP.[IsNonInvoicePayment],0) = 0 AND ICP.IsActive = 1 AND ICP.IsDeleted = 0
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
		 ,ISNULL(IWP.[IsNonInvoicePayment],0)
	  FROM [dbo].[CustomerPayments] CP WITH (NOLOCK)  
	  LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND ISNULL(IWP.Ismiscellaneous,0) = 0 AND ISNULL(IWP.[IsNonInvoicePayment],0) = 0 AND IWP.IsActive = 1 AND IWP.IsDeleted = 0     
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
		 , ISNULL(ICCP.[IsNonInvoicePayment],0)
	  FROM [dbo].[CustomerPayments] CP WITH (NOLOCK)  
	  LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ISNULL(ICCP.Ismiscellaneous,0) = 0 AND ISNULL(ICCP.[IsNonInvoicePayment],0) = 0 AND ICCP.IsActive = 1 AND ICCP.IsDeleted = 0             
	  LEFT JOIN [dbo].[Customer] CDP WITH (NOLOCK) ON CDP.CustomerId = ICCP.CustomerId     
	  WHERE CP.ReceiptId =  @ReceiptId              
	  AND CP.IsDeleted = 0	
	  AND ISNULL(ICCP.Amount, 0) > 0
	) 
	  
  , myCTE1(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount, IsNonInvoicePayment) AS     
	  (SELECT DISTINCT ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, SUM(C.Amount) As Amount, C.IsNonInvoicePayment    
	   FROM myCTE C GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, C.IsNonInvoicePayment)    
  
  , myCTE2(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount, IsNonInvoicePayment) AS     
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
		  , IsNonInvoicePayment
		  FROM myCTE1 C    
		  LEFT JOIN [dbo].[InvoicePayments] IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId AND IPS.IsActive = 1 AND IPS.IsDeleted = 0      
		  GROUP BY C.ReceiptId, C.CustomerId, Name, CustomerCode,C.PaymentRef, Amount, C.IsNonInvoicePayment)  
	  
  ,myCTE3(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount, IsNonInvoicePayment) AS     
	  (SELECT DISTINCT ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, SUM(C.Amount) As Amount, C.IsNonInvoicePayment    
	   FROM myCTE2 C    
	  GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, C.IsNonInvoicePayment) 
	  
  ,myCTE4(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount, IsNonInvoicePayment, AmountRemaining, AmtApplied) AS     
	  (SELECT C.ReceiptId, 
			 C.CustomerId, 
			 C.[Name], 
			 C.CustomerCode,     
			 REPLACE(PaymentRef, '~' ,'') AS PaymentRef,
			 Amount, 
			 C.IsNonInvoicePayment,
			 CASE WHEN ISNULL(IPS.PaymentId, 0) = 0 AND ISNULL(CU.Ismiscellaneous, 0) = 0 THEN Amount ELSE (Amount - SUM(IPS.PaymentAmount) + ISNULL(SUM(CASE WHEN IPS.InvoiceType = @CreditMemoInvoiceType OR IPS.InvoiceType = @StandAloneCreditMemoInvoiceType THEN ABS(ISNULL(IPS.OriginalAmount,0)) ELSE 0 END),0))  END AS AmountRemaining,
			(Amount - (Amount - SUM(IPS.PaymentAmount) + ISNULL(SUM(CASE WHEN IPS.InvoiceType = @CreditMemoInvoiceType OR IPS.InvoiceType = @StandAloneCreditMemoInvoiceType THEN ABS(ISNULL(IPS.OriginalAmount,0)) ELSE 0 END),0)))  AS AmtApplied  
		  FROM myCTE3 C          
	  LEFT JOIN [dbo].[InvoicePayments] IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId AND IPS.IsActive = 1 AND IPS.IsDeleted = 0     
	  LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.CustomerId = C.CustomerId    
	  GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, Amount,C.IsNonInvoicePayment, PaymentRef, IPS.PaymentId, CU.Ismiscellaneous)
  
   SELECT [ReceiptId],
          [CustomerId],
		  [Name],
		  [CustomerCode],
		  [PaymentRef],
		  ISNULL([Amount],0)AS Amount,
		  IsNonInvoicePayment,
		  (ISNULL([Amount],0) - ISNULL(SUM(AmtApplied),0)) AS AmountRemaining,
		  ISNULL(SUM(AmtApplied),0) AS AmtApplied
     FROM myCTE4 GROUP BY 
	      [ReceiptId],
          [CustomerId],
		  [Name],
		  [CustomerCode],
		  [PaymentRef],
	      [Amount],
		  [IsNonInvoicePayment]
		
	  UNION ALL

	  SELECT 
		[ReceiptId],
		[CustomerId],
		[Name],
		[CustomerCode],
		LTRIM(RTRIM(PaymentRef)) AS [PaymentRef],
		[Amount],
		[IsNonInvoicePayment],
		0 AS [AmountRemaining],
		[Amount] AS AmtApplied
		FROM
		(
			SELECT 
				CP.[ReceiptId],
				ICP.[CustomerId],
				C.[Name],
				C.[CustomerCode],
				ICP.[CheckNumber] AS PaymentRef,
				ICP.[Amount],
				ISNULL(ICP.[IsNonInvoicePayment],0) AS IsNonInvoicePayment
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK) 
			INNER JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.ReceiptId = CP.ReceiptId AND (ICP.Ismiscellaneous = 1 OR ISNULL(ICP.IsNonInvoicePayment,0) = 1)
			INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = ICP.CustomerId 
			WHERE CP.ReceiptId = @ReceiptId AND CP.IsDeleted = 0 AND ICP.CustomerId > 0

			UNION ALL

			SELECT 
				CP.[ReceiptId],
				IWP.[CustomerId],
				C.[Name],
				C.[CustomerCode],
				IWP.[ReferenceNo] AS PaymentRef,
				IWP.[Amount],
				ISNULL(IWP.[IsNonInvoicePayment],0)
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND (IWP.Ismiscellaneous = 1 OR ISNULL(IWP.IsNonInvoicePayment,0) = 1)
			INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = IWP.CustomerId
			WHERE CP.ReceiptId = @ReceiptId AND CP.IsDeleted = 0 AND IWP.CustomerId > 0

			UNION ALL

			SELECT 
				CP.[ReceiptId],
				ICCP.[CustomerId],
				C.[Name],
				C.[CustomerCode],
				ICCP.[Reference] AS PaymentRef,
				ICCP.[Amount],
				ISNULL(ICCP.[IsNonInvoicePayment],0)
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH(NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND (ICCP.Ismiscellaneous = 1 OR ISNULL(ICCP.IsNonInvoicePayment,0) = 1)
			INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = ICCP.CustomerId
			WHERE CP.ReceiptId = @ReceiptId AND CP.IsDeleted = 0 AND ICCP.CustomerId > 0
		) X; 

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