/*************************************************************             
 ** File:   [USP_DeleteNonPOInvoicePart_ById]             
 ** Author:   Devendra Shekh  
 ** Description: This stored procedure is used delete nonpoinvoicepart byid  
 ** Purpose:           
 ** Date:      22nd September 2023  
            
 ** PARAMETERS:             
 @WorkOrderId BIGINT     
 @WFWOId BIGINT    
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------			--------------------------------            
	1	O9/22/2023		Devendra Shekh		Modified to return SUM of all the records before paging  
	2	10/09/2026		Claude (Rajesh Gami)	[PN-18257] when the deleted line paid a Cash Receipt (ReceiptId) and no other
							active line still does, reset CustomerPayments.IsNonPOGenerated = 0 so the LOT
							Commission Report allows "Initiate Payment" again for that receipt.

**************************************************************/  

Create   PROCEDURE [dbo].[USP_DeleteNonPOInvoicePart_ById]
@NonPOInvoicePartDetailsId BIGINT,
@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				DECLARE @DeletedReceiptId BIGINT = NULL;
				SELECT @DeletedReceiptId = [ReceiptId] FROM [dbo].[NonPOInvoicePartDetails] WITH (NOLOCK)
				 WHERE NonPOInvoicePartDetailsId = @NonPOInvoicePartDetailsId AND MasterCompanyId = @MasterCompanyId;

				DELETE FROM NonPOInvoicePartDetails WHERE NonPOInvoicePartDetailsId = @NonPOInvoicePartDetailsId AND MasterCompanyId = @MasterCompanyId

				IF (ISNULL(@DeletedReceiptId,0) > 0
				    AND NOT EXISTS (SELECT 1 FROM [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK)
				                    INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK) ON NPH.[NonPOInvoiceId] = NPD.[NonPOInvoiceId]
				                    WHERE NPD.[ReceiptId] = @DeletedReceiptId AND ISNULL(NPD.[IsDeleted],0) = 0 AND ISNULL(NPH.[IsDeleted],0) = 0))
				BEGIN
					UPDATE [dbo].[CustomerPayments] SET [IsNonPOGenerated] = 0 WHERE [ReceiptId] = @DeletedReceiptId;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteNonPOInvoicePart_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoicePartDetailsId, '') + ''
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