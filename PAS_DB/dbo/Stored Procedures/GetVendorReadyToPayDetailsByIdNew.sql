/*************************************************************           
--EXEC GetVendorReadyToPayDetailsByIdNew 28
************************************************************************/
CREATE PROCEDURE [dbo].[GetVendorReadyToPayDetailsByIdNew]
@ReadyToPayId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
			;WITH CTE AS(
				SELECT   VRTPD.[ReadyToPayDetailsId]
                 ,VRTPD.[ReadyToPayId]
				 ,VRTPD.[DueDate]
				 --,(VRTPD.DueDate + ISNULL(ctm.NetDays,0)) as DueDate
                 ,VRTPD.[VendorId]
                 ,VRTPD.[VendorName]
                 ,VRTPD.[PaymentMethodId]
                 ,VRTPD.[PaymentMethodName]
                 ,VRTPD.[ReceivingReconciliationId]
                 ,VRTPD.[InvoiceNum]
                 ,VRTPD.[CurrencyId]
                 ,VRTPD.[CurrencyName]
                 ,VRTPD.[FXRate]
                 ,VRTPD.[OriginalAmount]
                 ,VRTPD.[PaymentMade]
                 ,VRTPD.[AmountDue]
                 ,VRTPD.[DaysPastDue]
                 ,VRTPD.[DiscountDate]
                 ,VRTPD.[DiscountAvailable]
                 ,VRTPD.[DiscountToken]
				 ,(VPD.InvoiceTotal - VPD.RemainingAmount) as PaidAmount
				 FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
				 INNER JOIN [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) ON VRTPD.ReceivingReconciliationId = VPD.ReceivingReconciliationId
				 INNER JOIN DBO.Vendor V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId
				 LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId
				 LEFT JOIN [Percent] p WITH(NOLOCK) ON CAST(ctm.CreditTermsId as INT) = p.PercentId
				 where VRTPD.ReadyToPayId =@ReadyToPayId and VRTPD.IsDeleted=0
				 UNION
				 SELECT  
				 CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.ReadyToPayDetailsId ELSE 0 END AS 'ReadyToPayDetailsId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.ReadyToPayId ELSE VRTPD.ReadyToPayId END AS 'ReadyToPayId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN (VPD.DueDate + ISNULL(ctm.NetDays,0)) ELSE (VRTPD.DueDate + ISNULL(ctm.NetDays,0)) END AS 'DueDate'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.VendorId ELSE VRTPD.VendorId END AS 'VendorId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.VendorName ELSE VRTPD.VendorName END AS 'VendorName'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.PaymentMethodId ELSE VRTPD.PaymentMethodId END AS 'PaymentMethodId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.PaymentMethodName ELSE VRTPD.PaymentMethodName END AS 'PaymentMethodName'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.ReceivingReconciliationId ELSE VRTPD.ReceivingReconciliationId END AS 'ReceivingReconciliationId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.InvoiceNum ELSE VRTPD.InvoiceNum END AS 'InvoiceNum'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.CurrencyId ELSE VRTPD.CurrencyId END AS 'CurrencyId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.CurrencyName ELSE VRTPD.CurrencyName END AS 'CurrencyName'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.FXRate ELSE VRTPD.FXRate END AS 'FXRate'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.OriginalAmount ELSE VRTPD.OriginalAmount END AS 'OriginalAmount'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.PaymentMade ELSE VRTPD.PaymentMade END AS 'PaymentMade'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.AmountDue ELSE VRTPD.AmountDue END AS 'AmountDue'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.AmountDue ELSE VRTPD.RemainingAmount END AS 'AmountDue'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DaysPastDue ELSE VRTPD.DaysPastDue END AS 'DaysPastDue'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DiscountDate ELSE VRTPD.DiscountDate END AS 'DiscountDate'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DiscountAvailable ELSE VRTPD.DiscountAvailable END AS 'DiscountAvailable'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DiscountToken ELSE VRTPD.DiscountToken END AS 'DiscountToken'
				 --,DATEDIFF(DAY, (CAST(VRTPD.DueDate as datetime) + ISNULL(ctm.NetDays,0)), GETDATE()) DaysPastDue
				 ,CASE WHEN DATEDIFF(DAY, (CAST(VRTPD.DueDate as datetime) + ISNULL(ctm.NetDays,0)), GETDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VRTPD.DueDate as datetime) + ISNULL(ctm.NetDays,0)), GETDATE()) END as DaysPastDue
				 ,(VRTPD.DueDate + ISNULL(ctm.NetDays,0)) as DiscountDate,cast((VRTPD.OriginalAmount * ISNULL(p.[PercentValue],0) / 100) as decimal(10,2)) as DiscountAvailable
				 ,ISNULL(VRTPD.DiscountToken,0) as DiscountToken
				 ,(ISNULL(VRTPD.InvoiceTotal,0) - ISNULL(VRTPD.RemainingAmount,0)) as PaidAmount
				 FROM [dbo].[VendorPaymentDetails] VRTPD WITH(NOLOCK) 
				 LEFT JOIN VendorReadyToPayDetails VPD WITH (NOLOCK) ON VPD.ReceivingReconciliationId = VRTPD.ReceivingReconciliationId AND VPD.ReadyToPayId != @ReadyToPayId
				 INNER JOIN DBO.Vendor V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId
				 LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId
				 LEFT JOIN [Percent] p WITH(NOLOCK) ON CAST(ctm.CreditTermsId as INT) = p.PercentId
				 --where VRTPD.ReadyToPayId =@ReadyToPayId and VRTPD.IsDeleted=0
				 )
				 SELECT [ReadyToPayDetailsId],[ReadyToPayId],[DueDate],[VendorId],[VendorName],[PaymentMethodId],[PaymentMethodName],[ReceivingReconciliationId],[InvoiceNum]
								  ,[CurrencyId],[CurrencyName],[FXRate],[OriginalAmount],[PaymentMade],[AmountDue]
								  ,[DaysPastDue],[DiscountDate],[DiscountAvailable],[DiscountToken],[PaidAmount]
								  FROM CTE WHERE ReadyToPayId = @ReadyToPayId OR ReadyToPayId = 0
					GROUP BY [ReadyToPayDetailsId],[ReadyToPayId],[DueDate],[VendorId],[VendorName],[PaymentMethodId],[PaymentMethodName],[ReceivingReconciliationId],[InvoiceNum]
								  ,[CurrencyId],[CurrencyName],[FXRate],[OriginalAmount],[PaymentMade],[AmountDue]
								  ,[DaysPastDue],[DiscountDate],[DiscountAvailable],[DiscountToken],[PaidAmount]
								  order by ReceivingReconciliationId;

    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetVendorReadyToPayDetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayId, '') + ''
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