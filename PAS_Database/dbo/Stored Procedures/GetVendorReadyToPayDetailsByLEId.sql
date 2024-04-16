/*************************************************************           
 ** File:   [GetVendorReadyToPayDetailsByLEId]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used TO GET Vendor Ready To Pay Details By LE Id
 ** Purpose:         
 ** Date:   18/03/2024      
          
 ** PARAMETERS: @LegalEntityId bigint
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		-------------------------------- 
	1    18/03/2024   AMIT GHEDIYA		Created
	2    27/03/2024   Devendra Shekh	IsCreditMemo added to where
	3    27/03/2024   AMIT GHEDIYA		Update to get LE
	4    29/03/2024   Devendra Shekh	duplicate record issue resolved
	5    29/03/2024   AMIT GHEDIYA		Update to get desc order list.
     
-- EXEC GetVendorReadyToPayDetailsByLEId 1
**************************************************************/
CREATE   PROCEDURE [dbo].[GetVendorReadyToPayDetailsByLEId]  
@LegalEntityId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	
		DECLARE @CreditCardPaymentMethodId INT, @IsEnforceApproval INT, @ApproveStatus INT = 2, @MasterComapnyId BIGINT;

		SELECT @MasterComapnyId = LE.MasterCompanyId FROM [dbo].[LegalEntity] LE WITH(NOLOCK) WHERE LE.LegalEntityId = @LegalEntityId;
		SELECT @CreditCardPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE [Description] ='Credit Card';
		SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM [dbo].[vendorPaymentSettingMaster] WITH(NOLOCK) WHERE MasterCompanyId = @MasterComapnyId;

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
				  ISNULL(VRTPD.CustomerCreditPaymentDetailId, 0) AS CustomerCreditPaymentDetailId,
				  @IsEnforceApproval AS 'IsEnforce',
				  (SELECT CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId AND VRPA.StatusId = @ApproveStatus) AS 'IsApproved',
				 
				 (SELECT TOP 1 CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId) AS 'IsAllowDelete',

				  LE.[Name] AS 'LegalEntityName',
				  VRTPD.CreatedDate
			 FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)  
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
			 LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.LegalEntityId = VRTPDH.LegalEntityId
			 INNER JOIN [dbo].[VendorPaymentMethod] VPM WITH(NOLOCK) ON VRTPD.PaymentMethodId = VPM.VendorPaymentMethodId  
			 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId  
			  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
			 WHERE VRTPDH.LegalEntityId = @LegalEntityId AND VRTPD.IsGenerated IS NULL AND ISNULL(VRTPD.[CreditMemoHeaderId], 0) = 0
					AND ISNULL(VRTPD.IsCheckPrinted,0) = 0 AND VRTPD.CheckNumber IS NULL--AND ISNULL(VRTPD.IsCreditMemo, 0) = 0

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
				  ISNULL(VRTPD.CustomerCreditPaymentDetailId, 0) AS CustomerCreditPaymentDetailId,
				  @IsEnforceApproval AS 'IsEnforce',
				  (SELECT CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId AND VRPA.StatusId = @ApproveStatus) AS 'IsApproved',
				  (SELECT TOP 1 CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId) AS 'IsAllowDelete',
				  LE.[Name] AS 'LegalEntityName',
				  VRTPD.CreatedDate
			 FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)  
				LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
				LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.LegalEntityId = VRTPDH.LegalEntityId
				INNER JOIN [dbo].[CreditMemo] CMD WITH(NOLOCK) ON VRTPD.CreditMemoHeaderId = CMD.CreditMemoHeaderId  
				INNER JOIN [dbo].[VendorPaymentMethod] VPM WITH(NOLOCK) ON VRTPD.PaymentMethodId = VPM.VendorPaymentMethodId  
			WHERE VRTPDH.LegalEntityId = @LegalEntityId AND VRTPD.IsGenerated IS NULL AND ISNULL(VRTPD.IsCheckPrinted,0) = 0 AND VRTPD.CheckNumber IS NULL
   
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
				  ISNULL(VRTPD.CustomerCreditPaymentDetailId, 0) AS CustomerCreditPaymentDetailId,
				  @IsEnforceApproval AS 'IsEnforce',
				  (SELECT CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId AND VRPA.StatusId = @ApproveStatus) AS 'IsApproved',
				  (SELECT TOP 1 CASE WHEN ISNULL(VRPA.VendorReadyToPayApprovalId,0) > 0 THEN 1 ELSE 0 END 
					FROM [dbo].[VendorReadyToPayApproval] VRPA WITH(NOLOCK)
				  WHERE VRPA.ReadyToPayDetailsId = VRTPD.ReadyToPayDetailsId) AS 'IsAllowDelete',
				  LE.[Name] AS 'LegalEntityName',
				  VRTPD.CreatedDate
			 FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK) 
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
			 LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.LegalEntityId = VRTPDH.LegalEntityId
			 INNER JOIN [dbo].[VendorPaymentMethod] VPM WITH(NOLOCK) ON VRTPD.PaymentMethodId = VPM.VendorPaymentMethodId  
			 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VRTPD.VendorId = V.VendorId  
			  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId 
			 WHERE VRTPDH.LegalEntityId = @LegalEntityId AND VRTPD.IsGenerated IS NULL AND ISNULL(VRTPD.[CreditMemoHeaderId], 0) = 0
				   AND ISNULL(VRTPD.IsCheckPrinted,0) = 0 AND VRTPD.CheckNumber IS NULL
			 ORDER BY VRTPD.CreatedDate desc; --AND ISNULL(VRTPD.IsCreditMemo, 0) = 0;
  
  
    END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetVendorReadyToPayDetailsByLEId'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityId, '') + ''  
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