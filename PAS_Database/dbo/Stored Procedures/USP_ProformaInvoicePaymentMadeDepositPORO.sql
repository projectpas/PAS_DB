/***************************************************************  
 ** File:   [USP_ProformaInvoicePaymentMadeDepositPORO]             
 ** Author:   RAJESH GAMI
 ** Description: This stored procedure is used to deposit amount into PO/RO from the vendor proforma invoice
 ** Date:  02-JAN-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    02-JAN-2024		RAJESH GAMI			Created
	2    06-JAN-2024		RAJESH GAMI			Added @VendorProformaInvoiceId in the PO/RO
 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_ProformaInvoicePaymentMadeDepositPORO]
	@VendorProformaInvoiceId BIGINT = NULL,  
	@PaymentMade Decimal(18,2) = 0    
AS    
BEGIN    
	SET NOCOUNT ON;    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	BEGIN TRY    
	
	BEGIN TRANSACTION
		DECLARE @ReferenceId BIGINT = 0, @isPurchaseOrder BIT = 0,@ReferenceNum VARCHAR(100)= '';
		SELECT  @ReferenceNum = VendorProformaInvoiceNo, @ReferenceId= ISNULL(ReferenceId,0),@isPurchaseOrder = ISNULL(IsPurchaseOrder,0) FROM [dbo].[VendorProformaInvoiceHeader] VPI WITH(NOLOCK) WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId
		IF(@isPurchaseOrder = 1)
		BEGIN
			UPDATE PurchaseOrder Set DepositAmount = ISNULL(DepositAmount,0) + @PaymentMade , VendorProformaInvoiceNo = @ReferenceNum, VendorProformaInvoiceId = @VendorProformaInvoiceId Where PurchaseOrderId = @ReferenceId
		END
		ELSE 
		BEGIN
			UPDATE RepairOrder Set DepositAmount = ISNULL(DepositAmount,0) + @PaymentMade , VendorProformaInvoiceNo = @ReferenceNum, VendorProformaInvoiceId = @VendorProformaInvoiceId Where RepairOrderId = @ReferenceId
		END
		
	COMMIT TRANSACTION
	 
	END TRY    
	BEGIN CATCH    
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'USP_ProformaInvoicePaymentMadeDepositPORO',    
			@ProcedureParameters varchar(3000) = '@@VendorProformaInvoiceId = ''' + CAST(ISNULL(@VendorProformaInvoiceId, '') AS varchar(100))    
			+ '@PaymentMade = ''' + CAST(ISNULL(@PaymentMade, '') AS varchar(100)),    
			@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
			EXEC spLogException @DatabaseName = @DatabaseName,    
				@AdhocComments = @AdhocComments,    
				@ProcedureParameters = @ProcedureParameters,    
				@ApplicationName = @ApplicationName,    
				@ErrorLogID = @ErrorLogID OUTPUT;    
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH    
END