/*************************************************************           
 ** File:   [GetPrintCheckInvoiceData]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used GetPrintCheckInvoiceData
 ** Purpose:         
 ** Date:   28-01-2026        
          
 ** PARAMETERS:  @ReadyToPayId   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28-01-2026   AMIT GHEDIYA  Created 
    
 --EXEC GetPrintCheckInvoiceData 10,1,35
**************************************************************/
CREATE     PROCEDURE [dbo].[GetPrintCheckInvoiceData]
	@ReadyToPayId BIGINT = NULL,
	@ReadyToPayDetailsId BIGINT = NULL,
	@LegalEntityId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
		BEGIN TRY
		DECLARE @BankGlAccount VARCHAR(100) = NULL,
				@LEName VARCHAR(100) = NULL;

			SET @BankGlAccount = (SELECT DISTINCT 
				   CONCAT(G.[AccountCode],' - ',G.[AccountName]) AS GLAccount
			FROM [dbo].[LegalEntityBankingLockBox] lebl WITH (NOLOCK)
			INNER JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON lebl.GLAccountId = G.GLAccountId
			 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
			WHERE lebl.[LegalEntityId] = @LegalEntityId 
			AND lebl.[AccountTypeId] = 2 
			AND ISNULL(lebl.IsDeleted,0) = 0 AND ISNULL(lebl.IsActive,0) = 1);

			SET @LEName = (SELECT TOP 1 [Name] FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId);

			SELECT VPD.[VendorId] AS 'vendorId',
				   CASE 
						WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN RRC.InvoiceNum
						WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN CM.InvoiceNumber
						WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0  THEN NPH.InvoiceNumber
						WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN CCPD.ReferenceNumber
						WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN VNPH.InvoiceNumber
				   END AS 'invoiceNum',
				   VPD.[CheckNumber] AS 'checkNumber',
				   CASE 
						WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN CAST(RRC.InvoiceDate AS DATE)
						WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN CAST(CM.InvoiceDate AS DATE)
						WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0  THEN CAST(NPH.InvoiceDate AS DATE)
						WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN CAST(CCPD.ProcessedDate AS DATE)
						WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN CAST(VNPH.InvoiceDate AS DATE)
				   END AS 'invoiceDate',
				   CASE 
						WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN (SELECT TOP 1 ISNULL(POReference,'') FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) WHERE ReceivingReconciliationId = VPD.ReceivingReconciliationId)
						WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN ''
						WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0  THEN ISNULL(NPH.PONumber,'')
						WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN ''
						WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN ''
					END AS 'refrence',
					VPD.[OriginalAmount] AS 'invAmt',
					VPD.[PaymentMade] AS 'amtPaid',
					VPD.[DiscountAvailable] AS 'discouunt',
					0.0 AS 'adjAmt',
					@BankGlAccount AS 'GLAccount',
					@LEName AS 'LEName',
					VD.[VendorCode] AS 'vendorCode',
					VD.[VendorName] AS 'vendorName',
					dbo.ValidatePDFAddress(CASE WHEN AD.Line1 = 'N/A' OR AD.Line1 = 'NA' THEN '' ELSE AD.Line1 END,CASE WHEN AD.Line2 = 'N/A' OR AD.Line2 = 'NA' THEN '' ELSE AD.Line2 END,'',CASE WHEN AD.City = 'N/A' OR AD.City = 'NA' THEN '' ELSE AD.City END,AD.StateOrProvince, AD.PostalCode,'','','','') AS MergedAddress
		    FROM [dbo].[VendorReadyToPayDetails] VPD WITH(NOLOCK)
			LEFT JOIN [dbo].[Vendor] VD WITH(NOLOCK) ON VD.[VendorId] = VPD.[VendorId]
			LEFT JOIN [dbo].[Address] AD WITH (NOLOCK) ON VD.[AddressId] = AD.[AddressId] 
			LEFT JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			LEFT JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON VPD.CreditMemoHeaderId = CM.CreditMemoHeaderId
			LEFT JOIN [dbo].[NonPOInvoiceHeader] NPH  WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId
			LEFT JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON VPD.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId	
			LEFT JOIN [dbo].[VendorProformaInvoiceHeader] VNPH WITH(NOLOCK) ON VPD.VendorProformaInvoiceId = VNPH.VendorProformaInvoiceId 
			WHERE [ReadyToPayId] = @ReadyToPayId 
			AND [ReadyToPayDetailsId] = @ReadyToPayDetailsId
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPrintCheckInvoiceData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayId, '') + ''
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