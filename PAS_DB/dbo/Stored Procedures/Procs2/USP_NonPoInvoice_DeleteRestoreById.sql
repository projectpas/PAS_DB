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
    2    10/09/2026		Claude (Rajesh Gami)			[PN-18257] after delete / restore, re-sync CustomerPayments.IsNonPOGenerated
                                                    for the Cash Receipts paid by this invoice's lines (LOT Commission Report
                                                    "Initiate Payment" is allowed again once no active invoice pays the receipt).

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

				-- [PN-18257] re-sync IsNonPOGenerated for the receipts this invoice pays (line level + old header level ReceiptId)
				UPDATE CP
				   SET CP.[IsNonPOGenerated] = CASE WHEN EXISTS (SELECT 1 FROM [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK)
				                                                 INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK) ON NPH.[NonPOInvoiceId] = NPD.[NonPOInvoiceId]
				                                                 WHERE NPD.[ReceiptId] = CP.[ReceiptId] AND ISNULL(NPD.[IsDeleted],0) = 0 AND ISNULL(NPH.[IsDeleted],0) = 0)
				                                    THEN 1 ELSE 0 END
				  FROM [dbo].[CustomerPayments] CP
				 WHERE CP.[ReceiptId] IN (SELECT NPD.[ReceiptId] FROM [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK)
				                          WHERE NPD.[NonPOInvoiceId] = @NonPOInvoiceId AND ISNULL(NPD.[ReceiptId],0) > 0
				                          UNION
				                          SELECT NPH.[ReceiptId] FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				                          WHERE NPH.[NonPOInvoiceId] = @NonPOInvoiceId AND ISNULL(NPH.[ReceiptId],0) > 0);
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