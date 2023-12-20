/*************************************************************             
 ** File:   [USP_UpdateNonPO_HeadserStatus]            
 ** Author:   Devendra    
 ** Description: to update the nonpo header status
 ** Purpose:           
 ** Date:   10-oct-2023         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 **	 S NO   Date			 Author			 Change Description              
 **	 --   --------		 -------		--------------------------------            
 1	 O5-oct-2023			Devendra		created  
       
EXECUTE   [dbo].[USP_UpdateNonPO_HeadserStatus] 37,'admin'  
*************************************************************/      
CREATE   PROCEDURE [dbo].[USP_UpdateNonPO_HeadserStatus]
@NonPOInvoiceId bigint,
@UpdatedBy VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				IF(@NonPOInvoiceId > 0)
					BEGIN
						UPDATE NonPOInvoiceHeader
						SET StatusId = (SELECT NonPOInvoiceHeaderStatusId FROM NonPOInvoiceHeaderStatus WHERE [Description] = 'Pending')
						, [UpdatedBy] = @UpdatedBy 
						, [UpdatedDate] = GETUTCDATE()
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
              , @AdhocComments     VARCHAR(150)    = '[USP_UpdateNonPO_HeadserStatus]' 
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