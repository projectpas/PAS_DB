/*************************************************************           
 ** File:   [CopyExistingBillingInvoicingDetailsforCM_CashReceipt]           
 ** Author:   HEMANT SALIYA
 ** Description: Update Billing Invoicing Details in CM and Cash Receipt
 ** Purpose:         
 ** Date:   28/04/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/04/2025   HEMANT SALIYA    Created

EXEC CopyExistingBillingInvoicingDetailsforCM_CashReceipt 2
**************************************************************/ 
CREATE   PROCEDURE [dbo].[CopyExistingBillingInvoicingDetailsforCM_CashReceipt]
@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	 BEGIN TRY  	
	
		DECLARE @WOModuleId BIGINT;
		DECLARE @SOModuleId BIGINT;
		
		SET @WOModuleId = 15; --Work Order
		SET @SOModuleId = 10; --Sales Order

		
		--UPPDATE Credit Memo 

		UPDATE dbo.CreditMemo SET InvoiceId = BI.BillingInvoicingId 
		FROM dbo.CreditMemo CM JOIN dbo.BillingInvoicing BI ON CM.InvoiceId =  BI.OldBillingInvoicingId 
		WHERE BI.ModuleId = @WOModuleId AND CM.InvoiceTypeId = 1 AND CM.MasterCompanyId = @MasterCompanyId

		UPDATE dbo.CreditMemo SET InvoiceId = BI.BillingInvoicingId 
		FROM dbo.CreditMemo CM JOIN dbo.BillingInvoicing BI ON CM.InvoiceId =  BI.OldBillingInvoicingId 
		WHERE BI.ModuleId = @SOModuleId AND CM.InvoiceTypeId = 2 AND CM.MasterCompanyId = @MasterCompanyId
		
		--UPPDATE Credit Memo Details
		UPDATE dbo.CreditMemoDetails SET InvoiceId = BI.BillingInvoicingId 
		FROM dbo.CreditMemoDetails CMD JOIN dbo.BillingInvoicing BI ON CMD.InvoiceId =  BI.OldBillingInvoicingId 
		WHERE BI.ModuleId = @WOModuleId AND CMD.InvoiceTypeId = 1 AND CMD.MasterCompanyId = @MasterCompanyId

		UPDATE dbo.CreditMemoDetails SET InvoiceId = BI.BillingInvoicingId 
		FROM dbo.CreditMemoDetails CMD JOIN dbo.BillingInvoicing BI ON CMD.InvoiceId =  BI.OldBillingInvoicingId 
		WHERE BI.ModuleId = @SOModuleId AND CMD.InvoiceTypeId = 2 AND CMD.MasterCompanyId = @MasterCompanyId

		--UPPDATE Cash Receipt 		
		UPDATE dbo.InvoicePayments SET SOBillingInvoicingId = BI.BillingInvoicingId 
		FROM dbo.InvoicePayments INV JOIN dbo.BillingInvoicing BI ON INV.SOBillingInvoicingId =  BI.OldBillingInvoicingId 
		WHERE BI.ModuleId = @WOModuleId AND INV.InvoiceType = 2 AND INV.MasterCompanyId = @MasterCompanyId

		UPDATE dbo.InvoicePayments SET SOBillingInvoicingId = BI.BillingInvoicingId 
		FROM dbo.InvoicePayments INV  JOIN dbo.BillingInvoicing BI ON INV.SOBillingInvoicingId =  BI.OldBillingInvoicingId 
		WHERE BI.ModuleId = @SOModuleId AND INV.InvoiceType = 1 AND INV.MasterCompanyId = @MasterCompanyId

		--UPPDATE RMA
		UPDATE dbo.CustomerRMADeatils SET InvoiceId = BII.BillingInvoicingId, BillingInvoicingItemId = BII.BillingInvoicingItemId 
		FROM dbo.CustomerRMADeatils CRD 
			JOIN dbo.BillingInvoicingItems BII ON CRD.BillingInvoicingItemId =  BII.OldWOBillingInvoicingItemId 
				AND CRD.InvoiceId = BII.OldBillingInvoicingId 
		WHERE BII.ModuleId = @WOModuleId AND CRD.MasterCompanyId = @MasterCompanyId



	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetBillingInvoicingDetails'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))			                                      
												   + '@Parameter2 = ''' + CAST(ISNULL(@WOModuleId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END