/*************************************************************           
 ** File:   [USP_ProformaInvoice_DeleteRestoreById]
 ** Author:   RAJESH GAMI
 ** Description: This stored procedure is used to DELETE or restore the Vendor Proforma Invoice Delete/Restore ById data
 ** Purpose:         
 ** Date:    17-Dec-2024
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author						Change Description            
 ** --   --------			-------					--------------------------------          
    1    17-Dec-2024		RAJESH GAMI					Created

exec USP_ProformaInvoice_DeleteRestoreById 1,0,'JIM ROBERTS'

************************************************************************/

CREATE     PROCEDURE [dbo].[USP_ProformaInvoice_DeleteRestoreById]
@VendorProformaInvoiceId bigint,
@IsDeleted bit,
@UpdatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				IF(@IsDeleted = 0)
					BEGIN
						UPDATE DBO.[VendorProformaInvoiceHeader]
						SET IsDeleted = 1, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
						WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId
					END
				ELSE
					BEGIN
						UPDATE DBO.[VendorProformaInvoiceHeader]
						SET IsDeleted = 0, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
						WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId
					END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ProformaInvoice_DeleteRestoreById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorProformaInvoiceId, '') + ''
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