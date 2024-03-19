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
	2    18/03/2024   AMIT GHEDIYA		Created
     
-- EXEC GetVendorReadyToPayDetailsByLEId 1
**************************************************************/
CREATE   PROCEDURE [dbo].[GetVendorReadyToPayDetailsByLEId]  
@LegalEntityId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	
	SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) 'ReadyToPaymentMade',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   Tab.ReadyToPayId,
			   Tab.ReadyToPayDetailsId,
			   RRH.VendorId,
			   RRH.CreatedDate
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK)
			   LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDHM WITH(NOLOCK) ON RRH.ReadyToPayId = VRTPDHM.ReadyToPayId
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE VRTPDHM.LegalEntityId = @LegalEntityId 

		 UNION ALL

		 SELECT 0 AS ReceivingReconciliationId,
				CMD.CreditMemoNumber AS [InvoiceNum],
				--CMD.[Status],
				'Selected to be Paid' AS [Status],
				ABS(ISNULL(Amount,0)) AS OriginalTotal,
				0 AS RRTotal,
				0 AS InvoiceTotal,
				0 AS 'DifferenceAmount',  
				C.Name as [VendorName],
				0 AS 'PaymentHold',
				CMD.InvoiceDate AS 'InvociedDate',
				CMD.InvoiceDate AS 'EntryDate',
				'' AS 'PaymentMethod',
				'' AS 'PaymentRef',
				'' AS 'DateProcessed',
				'' AS 'CheckCrashed',
				ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
				ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
				'' AS BankName,
				'' AS BankAccountNumber,
				Tab.ReadyToPayId,
				Tab.ReadyToPayDetailsId,
				CRF.CustomerId AS [VendorId],
				CMD.CreatedDate
			FROM [dbo].[CreditMemo] CMD WITH(NOLOCK)  
				JOIN [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.EntityStructureId = CMD.ManagementStructureId
				JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
				JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId 
				INNER JOIN [dbo].[CustomerRefund] CRF WITH(NOLOCK) ON CMD.CustomerRefundId = CRF.CustomerRefundId  
				INNER JOIN [dbo].[RefundCreditMemoMapping] RFCM WITH(NOLOCK) ON CMD.CreditMemoHeaderId = RFCM.CreditMemoHeaderId  
				INNER JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH(NOLOCK) ON CMBD.ReferenceId = CRF.CustomerRefundId AND CMBD.ModuleId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerRefund')
				INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON CMD.CustomerId = C.CustomerId  
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,max(PM.Description) as PaymentMethod,Max(VRTPDH.PrintCheck_Wire_Num) as PaymentRef,VRTPDH.ReadyToPayId
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.CreditMemoHeaderId,0) = CMD.CreditMemoHeaderId AND VD.CheckNumber IS NULL
			    GROUP BY VD.VendorPaymentDetailsId, VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE LE.LegalEntityId = @LegalEntityId
		  GROUP BY CMD.CreditMemoNumber, CMD.[Status], Amount, C.Name, CMD.InvoiceDate, Tab.DiscountToken, Tab.ReadyToPaymentMade, CRF.CustomerId, CMD.CreatedDate, Tab.ReadyToPayDetailsId, Tab.ReadyToPayId

	UNION ALL

		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) 'ReadyToPaymentMade',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   Tab.ReadyToPayId,
			   Tab.ReadyToPayDetailsId,
			   RRH.VendorId,
			   RRH.CreatedDate
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK)
			   LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDHF WITH(NOLOCK) ON RRH.ReadyToPayId = VRTPDHF.ReadyToPayId
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE VRTPDHF.LegalEntityId = @LegalEntityId
  
    END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetVendorReadyToPayDetailsById'   
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