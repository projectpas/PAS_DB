/*************************************************************           
 ** File:   [USP_NonPoInvoice_DeleteRestoreById]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to DELETE or restore the POInovice data
 ** Purpose:         
 ** Date:    09/13/2023
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			 Author						Change Description            
 ** --   --------		 -------					--------------------------------          
    1    09/13/2023		Devendra Shekh					Created
    1    09/14/2023		Devendra Shekh					added updatedby

exec USP_NonPoInvoice_DeleteRestoreById 1,0,'JIM ROBERTS'

************************************************************************/

CREATE   PROCEDURE [dbo].[USP_NonPoInvoice_DeleteRestoreById]
@NonPOInvoiceId bigint,
@IsDeleted bit,
@UpdatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				IF(@IsDeleted = 'false')
					BEGIN
						UPDATE [NonPOInvoiceHeader]
						SET IsDeleted = 1, UpdatedBy = @UpdatedBy
						WHERE [NonPOInvoiceId] = @NonPOInvoiceId
					END
				ELSE
					BEGIN
						UPDATE [NonPOInvoiceHeader]
						SET IsDeleted = 0, UpdatedBy = @UpdatedBy
						WHERE [NonPOInvoiceId] = @NonPOInvoiceId
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
              , @AdhocComments     VARCHAR(150)    = 'USP_NonPoInvoice_DeleteRestoreById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoiceId, '') + ''
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