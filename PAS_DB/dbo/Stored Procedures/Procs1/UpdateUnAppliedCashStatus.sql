/*************************************************************             
 ** File:   [UpdateUnAppliedCashStatus]             
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Update ManualJournal Status
 ** Purpose:           
 ** Date:   24/06/2024
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		 -------------------------------            
	1    24/06/2024   Hemant Saliya      Created
 **************************************************************/
CREATE   PROCEDURE [dbo].[UpdateUnAppliedCashStatus]
@CustomerCreditPaymentDetailId BIGINT = NULL,
@CustomerId BIGINT = NULL,
@Opr INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	DECLARE @StatusId INT;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN			
		IF(@Opr = 1)
		BEGIN
			SET @StatusId = 2 ; --Closed

			UPDATE [dbo].[CustomerCreditPaymentDetail]
			   SET [IsProcessed] = 1, StatusId = @StatusId				   
			 WHERE [CustomerCreditPaymentDetailId] = @CustomerCreditPaymentDetailId
			   AND [CustomerId] = @CustomerId
		END	
		IF(@Opr = 2)
		BEGIN
			SET @StatusId = 1 ; --Closed --Open

			UPDATE [dbo].[CustomerCreditPaymentDetail]
			   SET [IsProcessed] = 0, StatusId = @StatusId					   
			 WHERE [CustomerCreditPaymentDetailId] = @CustomerCreditPaymentDetailId
			   AND [CustomerId] = @CustomerId
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
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CustomerCreditPaymentDetailId, '') AS VARCHAR(100))  
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