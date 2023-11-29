
CREATE    PROCEDURE [dbo].[CustomerPaymentsReview]    
@ReceiptId BIGINT = NULL    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON    
 BEGIN TRY    
    
  ;WITH myCTE(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS    
  (SELECT DISTINCT IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode,     
  LTRIM(RTRIM(A.PaymentRef)) PaymentRef,  
    
  --SUM(ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS 'Amount'    
  (ISNULL(ICP.Amount, 0) + ISNULL(IWP.Amount, 0) + ISNULL(ICCP.Amount, 0)) AS 'Amount'    
  FROM DBO.InvoicePayments IPS WITH (NOLOCK)    
  LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = IPS.CustomerId    
  LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId    
  --LEFT JOIN (SELECT Amount, ReceiptId, CustomerId, CheckNumber FROM DBO.InvoiceCheckPayment WITH (NOLOCK)) ICP ON ICP.ReceiptId = CP.ReceiptId AND ICP.CustomerId = IPS.CustomerId    
  LEFT JOIN DBO.InvoiceCheckPayment ICP WITH (NOLOCK)  ON ICP.ReceiptId = CP.ReceiptId AND ICP.CustomerId = IPS.CustomerId    
  LEFT JOIN DBO.InvoiceWireTransferPayment IWP WITH (NOLOCK) ON IWP.ReceiptId = CP.ReceiptId AND IWP.CustomerId = IPS.CustomerId    
  LEFT JOIN DBO.InvoiceCreditDebitCardPayment ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CP.ReceiptId AND ICCP.CustomerId = IPS.CustomerId    
  OUTER APPLY(    
   SELECT DISTINCT  ((ISNULL(ICP1.CheckNumber,'')) + (CASE WHEN IWP1.ReferenceNo IS NOT NULL THEN ' ' + IWP1.ReferenceNo ELSE '' END) +     
   (CASE WHEN ICCP1.Reference IS NOT NULL THEN ' ' + ICCP1.Reference ELSE '' END)) AS 'PaymentRef'    
   FROM DBO.CustomerPayments CP1 WITH (NOLOCK) --ON CP.ReceiptId = IPS.ReceiptId    
   LEFT JOIN DBO.InvoiceCheckPayment ICP1 WITH (NOLOCK)  ON ICP1.ReceiptId = CP1.ReceiptId AND ICP1.CustomerId = IPS.CustomerId    
   LEFT JOIN DBO.InvoiceWireTransferPayment IWP1 WITH (NOLOCK) ON IWP1.ReceiptId = CP1.ReceiptId AND IWP1.CustomerId = IPS.CustomerId    
   LEFT JOIN DBO.InvoiceCreditDebitCardPayment ICCP1 WITH (NOLOCK) ON ICCP1.ReceiptId = CP1.ReceiptId AND ICCP1.CustomerId = IPS.CustomerId    
   Where CP.ReceiptId = CP1.ReceiptId --AND ICP1.ReceiptId = IPS.ReceiptId --AND ICP1.CustomerId = IPS.CustomerId    
  ) A    
  Where CP.ReceiptId = @ReceiptId    
  GROUP BY A.PaymentRef, IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, ICP.CheckNumber, IWP.ReferenceNo, ICCP.Reference, ICP.Amount, IWP.Amount, ICCP.Amount, IPS.PaymentAmount)    
    
  , myCTE1(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS     
  (SELECT DISTINCT ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef, SUM(C.Amount) As Amount    
  FROM myCTE C    
  GROUP BY C.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, C.PaymentRef)    
    
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
  , Amount FROM myCTE1 C    
  LEFT JOIN InvoicePayments IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId    
  GROUP BY C.ReceiptId, C.CustomerId, Name, CustomerCode,C.PaymentRef, Amount)   
    
  SELECT C.ReceiptId, C.CustomerId, Name, CustomerCode,     
  PaymentRef, Amount, (Amount - SUM(IPS.PaymentAmount) + ISNULL(SUM(CASE WHEN IPS.InvoiceType = 3 THEN ABS(ISNULL(IPS.OriginalAmount,0)) ELSE 0 END),0))  AS AmountRemaining
  FROM myCTE2 C    
  --- ISNULL(SUM(IPS.DiscAmount),0) - ISNULL(SUM(IPS.BankFeeAmount),0) - ISNULL(SUM(IPS.OtherAdjustAmt),0))    
      
  LEFT JOIN InvoicePayments IPS WITH (NOLOCK) ON C.ReceiptId = IPS.ReceiptId AND IPS.CustomerId = C.CustomerId    
  GROUP BY C.ReceiptId, C.CustomerId, Name, CustomerCode, Amount, PaymentRef    
 END TRY        
  BEGIN CATCH    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'BindDropdowns'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceiptId, '') + ''    
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