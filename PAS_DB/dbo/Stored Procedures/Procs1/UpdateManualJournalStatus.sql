/*************************************************************             
 ** File:   [UpdateStandAloneCreditMemoStatus]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Update ManualJournal Status
 ** Purpose:           
 ** Date:   03/10/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		 -------------------------------            
	1    03/10/2023   Moin Bloch      Created
 **************************************************************/
CREATE   PROCEDURE [dbo].[UpdateManualJournalStatus]
@ManualJournalHeaderId BIGINT = NULL,
@CustomerId BIGINT = NULL,
@Opr INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN			
		IF(@Opr = 1)
		BEGIN
			UPDATE [dbo].[ManualJournalDetails]
			   SET [IsClosed] = 1				   
			 WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId
			   AND [ReferenceTypeId] = 1
			   AND [ReferenceId] = @CustomerId
		END	
		IF(@Opr = 2)
		BEGIN
			UPDATE [dbo].[ManualJournalDetails]
			   SET [IsClosed] = 0				   
			 WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId
			   AND [ReferenceTypeId] = 1
			   AND [ReferenceId] = @CustomerId
		END	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateManualJournalStatus' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ManualJournalHeaderId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END