/*************************************************************           
 ** File:   [GetVendorReadyToPayDetailsById]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used TO GET Vendor Ready To Pay Details By Id
 ** Purpose:         
 ** Date:   13/07/2023      
          
 ** PARAMETERS: @ReadyToPayId bigint,@ReadyToPayDetailsId bigint
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		-------------------------------- 
	1    13/07/2023   Moin Bloch		Added All Vendor Payment Methods
	2    22/09/2023   AMIT GHEDIYA		Added CreditMemoAmount Fields
	3    20/10/2023   Devendra Shekh	added union for creditmemo details
	4    27/10/2023   Moin Bloch	    added CheckNumber
	5    30/10/2023   Moin Bloch	    added Payment Method Name
	6    31/10/2023   Devendra Shekh	added union for nonpo details
	7    02/11/2023   Devendra Shekh	added condtion for NonPOInvoiceId
	8    29/03/2024   AMIT GHEDIYA		Update to get LE
     
-- EXEC GetVendorReadyToPayDetailsById 7,0
**************************************************************/
CREATE   PROCEDURE [dbo].[GetVendorReadyToPayDetailsById]  
@ReadyToPayId bigint,
@ReadyToPayDetailsId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	DECLARE @CreditCardPaymentMethodId INT, @ApproveStatus INT = 2;
	SELECT @CreditCardPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE [Description] ='Credit Card';
	
    SELECT VRTPD.[ReadyToPayDetailsId]  
          ,VRTPD.[ReadyToPayId]  
          ,ISNULL(VRTPD.[DueDate],'') AS 'DueDate'
          ,VRTPD.[VendorId]  
          ,VRTPD.[VendorName]  
          ,VRTPD.[PaymentMethodId]           
		  ,VPM.[Description] AS [PaymentMethodName]
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
		  ,IsCheckPayment = (SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN [dbo].[CheckPayment] ch WITH(NOLOCK) on ch.CheckPaymentId = vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted=0)
	      ,IsDomesticWirePayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
	      ,IsInternationlWirePayment = (SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
          ,IsACHTransferPayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
	      ,IsCreditCardPayment = (SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
		  ,ISNULL(VRTPD.IsCreditMemo,0) AS 'IsCreditMemo',
		  ISNULL(VRTPD.CreditMemoAmount,0) AS 'CreditMemoAmount',
		  0 AS [CreditMemoHeaderId],
		  VRTPD.[CheckNumber],
		  ISNULL(VRTPD.VendorReadyToPayDetailsTypeId, 0) AS VendorReadyToPayDetailsTypeId,
		  ISNULL(VRTPD.NonPOInvoiceId, 0) AS NonPOInvoiceId,
		  (SELECT CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId AND VRPA.StatusId = @ApproveStatus) AS 'IsApproved',
		 LE.[Name] AS 'LegalEntityName'
     FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)  
	 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
	 LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.LegalEntityId = VRTPDH.LegalEntityId
	 INNER JOIN [dbo].[VendorPaymentMethod] VPM WITH(NOLOCK) ON VRTPD.PaymentMethodId = VPM.VendorPaymentMethodId  
     INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId  
      LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
     WHERE VRTPD.ReadyToPayId = @ReadyToPayId AND VRTPD.IsDeleted = 0 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(VRTPD.NonPOInvoiceId, 0) = 0 AND
	 VRTPD.ReadyToPayDetailsId = CASE WHEN ISNULL(@ReadyToPayDetailsId,0) = 0 THEN VRTPD.ReadyToPayDetailsId ELSE @ReadyToPayDetailsId END

	 UNION

	 SELECT VRTPD.[ReadyToPayDetailsId]  
          ,VRTPD.[ReadyToPayId]  
          ,ISNULL(VRTPD.[DueDate],'') AS 'DueDate'
          ,VRTPD.[VendorId]  
          ,VRTPD.[VendorName]  
          ,VRTPD.[PaymentMethodId]  
          ,VPM.[Description] AS [PaymentMethodName]
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
		  ,IsCheckPayment =   1
	      ,IsDomesticWirePayment = 0
	      ,IsInternationlWirePayment = 0
          ,IsACHTransferPayment = 0
	      ,IsCreditCardPayment = 0
		  ,ISNULL(VRTPD.IsCreditMemo,0) AS 'IsCreditMemo'
		  ,ISNULL(VRTPD.CreditMemoAmount,0) AS 'CreditMemoAmount'
		  ,ISNULL(VRTPD.CreditMemoHeaderId, 0) AS [CreditMemoHeaderId]
		  ,VRTPD.[CheckNumber]
		  ,ISNULL(VRTPD.VendorReadyToPayDetailsTypeId, 0) AS VendorReadyToPayDetailsTypeId
		  ,ISNULL(VRTPD.NonPOInvoiceId, 0) AS NonPOInvoiceId,
		  (SELECT CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId AND VRPA.StatusId = @ApproveStatus) AS 'IsApproved',
		 LE.[Name] AS 'LegalEntityName'
     FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)  
		LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.LegalEntityId = VRTPDH.LegalEntityId
		INNER JOIN [dbo].[CreditMemo] CMD WITH(NOLOCK) ON VRTPD.CreditMemoHeaderId = CMD.CreditMemoHeaderId  
		INNER JOIN [dbo].[VendorPaymentMethod] VPM WITH(NOLOCK) ON VRTPD.PaymentMethodId = VPM.VendorPaymentMethodId  
     WHERE VRTPD.ReadyToPayId = @ReadyToPayId AND VRTPD.IsDeleted = 0 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) <> 0 AND ISNULL(VRTPD.NonPOInvoiceId, 0) = 0 AND
	 VRTPD.ReadyToPayDetailsId = CASE WHEN ISNULL(@ReadyToPayDetailsId,0) = 0 THEN VRTPD.ReadyToPayDetailsId ELSE @ReadyToPayDetailsId END

	 UNION

	     SELECT VRTPD.[ReadyToPayDetailsId]  
          ,VRTPD.[ReadyToPayId]  
          ,ISNULL(VRTPD.[DueDate],'') AS 'DueDate'
          ,VRTPD.[VendorId]  
          ,VRTPD.[VendorName]  
          ,VRTPD.[PaymentMethodId]           
		  ,VPM.[Description] AS [PaymentMethodName]
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
		  ,IsCheckPayment = (SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN [dbo].[CheckPayment] ch WITH(NOLOCK) on ch.CheckPaymentId = vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted=0)
	      ,IsDomesticWirePayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
	      ,IsInternationlWirePayment = (SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
          ,IsACHTransferPayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
	      ,IsCreditCardPayment = (SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0)
		  ,ISNULL(VRTPD.IsCreditMemo,0) AS 'IsCreditMemo',
		  ISNULL(VRTPD.CreditMemoAmount,0) AS 'CreditMemoAmount',
		  0 AS [CreditMemoHeaderId],
		  VRTPD.[CheckNumber],
		  ISNULL(VRTPD.VendorReadyToPayDetailsTypeId, 0) AS VendorReadyToPayDetailsTypeId,
		  ISNULL(VRTPD.NonPOInvoiceId, 0) AS NonPOInvoiceId,
		  (SELECT CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId AND VRPA.StatusId = @ApproveStatus) AS 'IsApproved',
		 LE.[Name] AS 'LegalEntityName'
     FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)  
	 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
	 LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.LegalEntityId = VRTPDH.LegalEntityId
	 INNER JOIN [dbo].[VendorPaymentMethod] VPM WITH(NOLOCK) ON VRTPD.PaymentMethodId = VPM.VendorPaymentMethodId  
     INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId  
      LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
     WHERE VRTPD.ReadyToPayId = @ReadyToPayId AND VRTPD.IsDeleted = 0 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(VRTPD.NonPOInvoiceId, 0) <> 0 AND
	 VRTPD.ReadyToPayDetailsId = CASE WHEN ISNULL(@ReadyToPayDetailsId,0) = 0 THEN VRTPD.ReadyToPayDetailsId ELSE @ReadyToPayDetailsId END
  
    END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
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