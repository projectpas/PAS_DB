

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

-- EXEC CustomerPaymentsReview 90
CREATE PROCEDURE [dbo].[CustomerPaymentsReview]
	@ReceiptId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY

		;WITH myCTE(ReceiptId, CustomerId, Name, CustomerCode, PaymentRef, Amount) AS
		(SELECT DISTINCT IPS.ReceiptId, C.CustomerId, C.Name, C.CustomerCode, 
		A.PaymentRef,

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

		SELECT C.ReceiptId, C.CustomerId, Name, CustomerCode, 
		PaymentRef, Amount, (Amount - SUM(IPS.PaymentAmount)) AS AmountRemaining FROM myCTE2 C
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