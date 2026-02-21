/*************************************************************           
 ** File:   [USP_UpdateNonPOInvoicePartMemo]           
 ** Author:   Sahdev Saliya
 ** Description: Updates Memo status of a NonPOInvoicePartDetails
 ** Purpose:         
 ** Date:   16-02-2026       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    16-02-2026    Sahdev Saliya       Created  

**************************************************************/  
CREATE    PROCEDURE [dbo].[USP_UpdateNonPOInvoicePartMemo]
    @NonPOInvoicePartDetailsId BIGINT,
    @Memo VARCHAR(max) = NULL,
    @UpdatedBy VARCHAR(50),
	@MasterCompanyId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE dbo.NonPOInvoicePartDetails
        SET 
            Memo = @Memo,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE NonPOInvoicePartDetailsId = @NonPOInvoicePartDetailsId AND MasterCompanyId = @MasterCompanyId;
    END TRY
    BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_UpdateNonPOInvoicePartMemo' 
				  , @ProcedureParameters VARCHAR(3000)  =  '@Parameter1 = '''+ ISNULL(@NonPOInvoicePartDetailsId, '')
			 
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END