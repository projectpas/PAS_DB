/*************************************************************           
 ** File:   [USP_VendorCreditMemoDetailsByVendorId]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used VendorReadyToPayList for get vendor creditmemo details
 ** Purpose:         
 ** Date:   21/09/2023      
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/09/2023   AMIT GHEDIYA  Created
	2    04/10/2023   Moin Bloch    Added Manual Journal List
	3    06/11/2023   AMIT GHEDIYA  Update Status Approved To Posted for VendorCreditMemo.
	4    07/11/2023   AMIT GHEDIYA  Update Amount select Orignalamount to ApplierdAmt.
     
-- EXEC USP_VendorCreditMemoDetailsByVendorId 1,1287,0 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_VendorCreditMemoDetailsByVendorId]  
@MasterCompanyId INT = NULL,  
@VendorId BIGINT = NULL ,
@VendorPaymentDetailsId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	  DECLARE @VendorCreditMemoStatusId INT;
	  DECLARE @PostStatusId INT;

      SELECT @VendorCreditMemoStatusId = [Id] FROM [CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
	  SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';

     SELECT DISTINCT VCM.VendorCreditMemoId,
					 VCM.VendorCreditMemoNumber,
					 VendorId = (CASE WHEN V.VendorId IS NOT NULL THEN V.VendorId ELSE VE.VendorId END),
					 VendorName = (CASE WHEN V.VendorId IS NOT NULL THEN V.VendorName ELSE VE.VendorName END),
					 CU.Code AS 'CurrencyName',
					 ISNULL(SUM(VCMD.ApplierdAmt),0) AS Amount,
					 VCM.VendorCreditMemoStatusId AS 'StatusId',
					 CMS.[Name] AS 'Status',
					 VCM.MasterCompanyId,
					 IsCreditMemo = 1,
					 VendorPaymentDetailsId = CASE WHEN ISNULL(VCMM.VendorCreditMemoMappingId,0) > 0 THEN ISNULL(VCMM.VendorPaymentDetailsId,0) ELSE 0 END,
					 IsAlreadyUsed = CASE WHEN ISNULL(VCMM.VendorCreditMemoMappingId,0) > 0 THEN 1 ELSE 0 END,
					 SelectedforPayment = (SELECT COUNT(VCMM.VendorPaymentDetailsId) FROM  [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) WHERE 
					 VCMM.VendorPaymentDetailsId = @VendorPaymentDetailsId AND VCM.VendorCreditMemoId = VCMM.VendorCreditMemoId),
				     3 AS InvoiceType,
					 'Credit Memo' PaymentType
			FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)
				LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
				LEFT JOIN [dbo].[VendorRMA] VR WITH (NOLOCK) ON VR.VendorRMAId = VCM.VendorRMAId
				LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VCM.VendorId = V.VendorId
				LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VR.VendorId = VE.VendorId
				LEFT JOIN [dbo].[Currency] CU WITH (NOLOCK) ON CU.CurrencyId = VCM.CurrencyId	
				LEFT JOIN [dbo].[CreditMemoStatus] CMS WITH (NOLOCK) ON VCM.VendorCreditMemoStatusId = CMS.Id
				LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON  VCM.VendorCreditMemoId = VCMM.VendorCreditMemoId
			WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId 			
			AND VCM.MasterCompanyId = @MasterCompanyId 		
			AND ISNULL(VCM.IsVendorPayment,0) = 0
			AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = @VendorId
			GROUP BY VCM.VendorCreditMemoId,VCM.VendorCreditMemoNumber,V.VendorId,VE.VendorId,V.VendorName,VE.VendorName,CU.Code,
					 VCM.VendorCreditMemoStatusId,CMS.[Name],VCM.MasterCompanyId,VCMM.VendorPaymentDetailsId,VCMM.VendorCreditMemoMappingId
		
		   UNION ALL

	 SELECT MJH.ManualJournalHeaderId AS VendorCreditMemoId,
			UPPER(MJH.JournalNumber) AS VendorCreditMemoNumber,   
			MJD.ReferenceId AS VendorId,
			VED.VendorName,
			CR.Code AS 'CurrencyName',
			SUM(ISNULL(MJD.Credit,0) - ISNULL(MJD.Debit,0)) AS Amount,
			MJH.[ManualJournalStatusId] AS 'StatusId',
			MJS.[Name] AS 'Status',
			MJH.MasterCompanyId,
			IsCreditMemo = 1,
			VendorPaymentDetailsId = CASE WHEN ISNULL(VCMM.VendorCreditMemoMappingId,0) > 0 THEN ISNULL(VCMM.VendorPaymentDetailsId,0) ELSE 0 END,
			IsAlreadyUsed = CASE WHEN ISNULL(VCMM.VendorCreditMemoMappingId,0) > 0 THEN 1 ELSE 0 END,
			SelectedforPayment = (SELECT COUNT(VCMM.VendorPaymentDetailsId) 
				     FROM  [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) WHERE 
				   	 VCMM.VendorPaymentDetailsId = @VendorPaymentDetailsId 
					 AND MJH.ManualJournalHeaderId = VCMM.VendorCreditMemoId),
			5 AS InvoiceType,
			'Manual Journal' PaymentType
	 FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
	   INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
		LEFT JOIN [dbo].[Vendor] VED WITH(NOLOCK) ON MJD.ReferenceId = VED.VendorId
		LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON MJH.FunctionalCurrencyId = CR.CurrencyId
		LEFT JOIN [dbo].[ManualJournalStatus] MJS WITH(NOLOCK) ON MJH.[ManualJournalStatusId] = MJS.[ManualJournalStatusId]
		LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON MJH.ManualJournalHeaderId = VCMM.VendorCreditMemoId
    WHERE MJH.MasterCompanyId = @MasterCompanyId  
      AND MJD.ReferenceId = @VendorId 
      AND MJD.ReferenceTypeId = 2 
      AND MJH.[ManualJournalStatusId] = @PostStatusId
	  AND ISNULL(MJD.IsClosed,0) = 0
	  GROUP BY MJH.ManualJournalHeaderId,MJH.JournalNumber,VED.VendorId,VED.VendorName,CR.Code,
			   MJH.ManualJournalStatusId,MJS.[Name],MJH.MasterCompanyId,MJD.ReferenceId, 
			   VCMM.VendorPaymentDetailsId,VCMM.VendorCreditMemoMappingId
	
 END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorCreditMemoDetailsByVendorId'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END