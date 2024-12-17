/*************************************************************             
 ** File:   [USP_DeleteVendorProformaInvoicePart_ById]             
 ** Author:   RAJESH GAMI  
 ** Description: This stored procedure is used delete VendorProformaInvoicePartDetails by vendorProformaInvoicePartDetailsId  
 ** Purpose:           
 ** Date:      17 Dec 2024  
            
 ** PARAMETERS:             
          
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------			--------------------------------            
	1	17 Dec 2024  	RAJESH GAMI		CREATED  

**************************************************************/  

CREATE     PROCEDURE [dbo].[USP_DeleteVendorProformaInvoicePart_ById]
@VendorProformaInvoicePartDetailsId BIGINT,
@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				DELETE FROM DBO.VendorProformaInvoicePartDetails WHERE VendorProformaInvoicePartDetailsId = @VendorProformaInvoicePartDetailsId AND MasterCompanyId = @MasterCompanyId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteVendorProformaInvoicePart_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorProformaInvoicePartDetailsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END