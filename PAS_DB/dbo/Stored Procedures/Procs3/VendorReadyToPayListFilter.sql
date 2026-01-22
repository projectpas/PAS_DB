/*************************************************************           
 ** File:   [VendorReadyToPayListFilter]           
 ** Author:   
 ** Description: This stored procedure is used VendorReadyToPayListFilter 
 ** Purpose:         
 ** Date:       
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------     	
	1    21/09/2023   AMIT GHEDIYA   Added for is vendorcreditmemo or not
    2    08/01/2024   Moin Bloch     Modified (Renamed Percent to PercentId)
**************************************************************/
--EXEC VendorReadyToPayList 10,1,'ReceivingReconciliationId',1,'','',0,0,0,'ALL','',NULL,NULL,1,73
--EXEC VendorReadyToPayListFilter 1,73,'12/1/2022','12/31/2022',0
CREATE   PROCEDURE [dbo].[VendorReadyToPayListFilter]
	-- Add the parameters for the stored procedure here
	@MasterCompanyId int = null,
	@EmployeeId bigint,
	@StartDate datetime,
	@EndDate datetime,
	@ReadyToPayId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				;WITH CTE AS(
				SELECT   VRTPD.[ReadyToPayDetailsId]
                 ,VRTPD.[ReadyToPayId]
				 --,VRTPD.[DueDate]
				 --,(VRTPD.DueDate + ISNULL(ctm.NetDays,0)) as DueDate
				 ,DATEADD(DAY, ISNULL(ctm.NetDays,0),VRTPD.DueDate) AS 'DueDate'
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
                 --,VRTPD.[DaysPastDue]
                 --,VRTPD.[DiscountDate]
                 --,VRTPD.[DiscountAvailable]
                 --,VRTPD.[DiscountToken]
				 ,DATEDIFF(DAY, (CAST(VRTPD.DueDate as datetime)), GETDATE()) DaysPastDue
				 --,(VRTPD.DueDate + ISNULL(ctm.NetDays,0)) as DiscountDate
				 ,DATEADD(DAY, ISNULL(ctm.NetDays,0),VRTPD.DueDate) AS 'DiscountDate'
				 ,cast((VRTPD.OriginalAmount * ISNULL(ctm.[PercentId],0) / 100) as decimal(10,2)) as DiscountAvailable,VRTPD.DiscountToken
				 ,(VPD.InvoiceTotal - VPD.RemainingAmount) as PaidAmount,
				 SelectedforPayment = 
				   (SELECT COUNT(VCMD.VendorCreditMemoId)
					FROM [dbo].[VendorCreditMemo] VCM 
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorRMA] VR WITH (NOLOCK) ON VR.VendorRMAId = VCM.VendorRMAId
						LEFT JOIN [dbo].[Vendor] VD WITH(NOLOCK) ON VCM.VendorId = VD.VendorId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VR.VendorId = VE.VendorId
					WHERE CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId)
				 FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
				 INNER JOIN [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) ON VRTPD.ReceivingReconciliationId = VPD.ReceivingReconciliationId
				 INNER JOIN DBO.Vendor V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId
				 LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId
				 where VRTPD.ReadyToPayId =@ReadyToPayId and VRTPD.IsDeleted=0
				 UNION
				 SELECT  
				 CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.ReadyToPayDetailsId ELSE 0 END AS 'ReadyToPayDetailsId'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.ReadyToPayId ELSE VRTPD.ReadyToPayId END AS 'ReadyToPayId'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN (VPD.DueDate + ISNULL(ctm.NetDays,0)) ELSE (VRTPD.DueDate + ISNULL(ctm.NetDays,0)) END AS 'DueDate'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN DATEADD(DAY, ISNULL(ctm.NetDays,0),VPD.DueDate) ELSE DATEADD(DAY, ISNULL(ctm.NetDays,0),VRTPD.DueDate) END AS 'DueDate'				
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
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.PaymentMade ELSE 0 END AS 'PaymentMade'
				 ,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.AmountDue ELSE VRTPD.AmountDue END AS 'AmountDue'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DaysPastDue ELSE VRTPD.DaysPastDue END AS 'DaysPastDue'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DiscountDate ELSE VRTPD.DiscountDate END AS 'DiscountDate'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DiscountAvailable ELSE VRTPD.DiscountAvailable END AS 'DiscountAvailable'
				 --,CASE WHEN VPD.ReadyToPayId IS NOT NULL THEN VPD.DiscountToken ELSE VRTPD.DiscountToken END AS 'DiscountToken'
				 ,DATEDIFF(DAY, (CAST(VRTPD.DueDate as datetime)), GETDATE()) DaysPastDue
				 --,(VRTPD.DueDate + ISNULL(ctm.NetDays,0)) as DiscountDate
				 ,DATEADD(DAY, ISNULL(ctm.NetDays,0),VRTPD.DueDate) AS 'DiscountDate'
				 ,cast((VRTPD.OriginalAmount * ISNULL(ctm.[PercentId],0) / 100) as decimal(10,2)) as DiscountAvailable,VRTPD.DiscountToken
				 ,(VRTPD.InvoiceTotal - VRTPD.RemainingAmount) as PaidAmount,
				 SelectedforPayment = 
				   (SELECT COUNT(VCMD.VendorCreditMemoId)--(CASE WHEN V.VendorId IS NOT NULL THEN V.IsActive ELSE VE.IsActive END)
					FROM [dbo].[VendorCreditMemo] VCM 
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorRMA] VR WITH (NOLOCK) ON VR.VendorRMAId = VCM.VendorRMAId
						LEFT JOIN [dbo].[Vendor] VD WITH(NOLOCK) ON VCM.VendorId = VD.VendorId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VR.VendorId = VE.VendorId
					WHERE CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId)
				 FROM [dbo].[VendorPaymentDetails] VRTPD WITH(NOLOCK) 
				 LEFT JOIN VendorReadyToPayDetails VPD WITH (NOLOCK) ON VPD.ReceivingReconciliationId = VRTPD.ReceivingReconciliationId AND VRTPD.ReadyToPayId != @ReadyToPayId
				 INNER JOIN DBO.Vendor V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId
				 LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId
				 --where VRTPD.ReadyToPayId =@ReadyToPayId and VRTPD.IsDeleted=0
				 where VRTPD.MasterCompanyId=@MasterCompanyId AND VRTPD.DueDate BETWEEN @StartDate AND @EndDate
				 )
				 SELECT [ReadyToPayDetailsId],[ReadyToPayId],[DueDate],[VendorId],[VendorName],[PaymentMethodId],[ReceivingReconciliationId],[InvoiceNum]
								  ,[CurrencyId],[CurrencyName],[FXRate],[OriginalAmount],[PaymentMade],[AmountDue]
								  ,[DaysPastDue],[DiscountDate],[DiscountAvailable],[DiscountToken],[PaidAmount],[SelectedforPayment]
								  FROM CTE --WHERE ReadyToPayId = @ReadyToPayId OR ReadyToPayId = 0
					GROUP BY [ReadyToPayDetailsId],[ReadyToPayId],[DueDate],[VendorId],[VendorName],[PaymentMethodId],[ReceivingReconciliationId],[InvoiceNum]
								  ,[CurrencyId],[CurrencyName],[FXRate],[OriginalAmount],[PaymentMade],[AmountDue]
								  ,[DaysPastDue],[DiscountDate],[DiscountAvailable],[DiscountToken] ,[PaidAmount],[SelectedforPayment]
								  order by ReceivingReconciliationId;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'VendorReadyToPayList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END