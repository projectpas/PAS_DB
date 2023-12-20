/*************************************************************             
--EXEC GetHistoryVendorReadyToPayDetailsById 29  
************************************************************************/  
create       PROCEDURE [dbo].[GetHistoryVendorReadyToPayDetailsById]  
@ReadyToPayId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
    SELECT   VRTPD.[ReadyToPayDetailsId]  
                 ,VRTPD.[ReadyToPayId]  
     ,VRTPD.[DueDate]  
                 ,VRTPD.[VendorId]  
                 ,VRTPD.[VendorName]  
                 ,VRTPD.[PaymentMethodId]  
                 ,PM.Description as [PaymentMethodName]  
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
				 ,VRTPD.[VendorPaymentDetailsId]
				 ,VRTPD.[CreatedDate]  
                 ,VRTPD.[UpdatedDate]  
                 ,VRTPD.[UpdatedBy]
				 ,VRTPD.[CreatedBy]
				 ,IsCheckPayment = (SELECT Case when Count(ch.CheckPaymentId) >0 then 1 else 0 end  FROM DBO.VendorCheckPayment VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId and ch.IsDeleted=0),
	              IsDomesticWirePayment = (SELECT Case when Count(VP.VendorDomesticWirePaymentId) >0 then 1 else 0 end  FROM DBO.VendorDomesticWirePayment VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId and vp.IsDeleted=0),
	              IsInternationlWirePayment = (SELECT Case when Count(VP.VendorInternationalWirePaymentId) >0 then 1 else 0 end  FROM DBO.VendorInternationlWirePayment VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId and vp.IsDeleted=0)
     FROM [dbo].[VendorReadyToPayDetailsAudit] VRTPD WITH(NOLOCK)  
     INNER JOIN DBO.Vendor V ON VRTPD.VendorId = V.VendorId  
	  LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId
     LEFT JOIN PaymentMethod PM WITH(NOLOCK) ON PM.PaymentMethodId = VRTPD.PaymentMethodId  
     LEFT JOIN [Percent] p WITH(NOLOCK) ON CAST(ctm.CreditTermsId as INT) = p.PercentId  
     where VRTPD.ReadyToPayId =@ReadyToPayId and VRTPD.IsDeleted=0  
  
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