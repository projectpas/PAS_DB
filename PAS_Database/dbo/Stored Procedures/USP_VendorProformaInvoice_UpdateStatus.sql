/*************************************************************           
 ** File:   [USP_VendorProformaInvoice_UpdateStatus]
 ** Author:   RAJESH GAMI
 ** Description: This stored procedure is used to Active/InActive the Proforma Invoice data
 ** Purpose:         
 ** Date:    17-Dec-2024
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			 Author						Change Description            
 ** --   --------		 -------					--------------------------------          
    1    17-Dec-2024		RAJESH GAMI					Created

exec USP_VendorProformaInvoice_UpdateStatus 1,0
************************************************************************/

CREATE    PROCEDURE [dbo].[USP_VendorProformaInvoice_UpdateStatus]
@VendorProformaInvoiceId bigint,
@IsActive bit,
@UpdatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				IF(@IsActive = 0) 
					BEGIN
						UPDATE	dbo.VendorProformaInvoiceHeader
						SET		IsActive = 0,
								UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
						WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId
					END
				ELSE
					BEGIN
						UPDATE	dbo.VendorProformaInvoiceHeader
						SET		IsActive = 1,
								UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
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
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorProformaInvoice_UpdateStatus' 
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