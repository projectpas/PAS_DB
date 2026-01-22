/*************************************************************             
 ** File:   [UpdateStandAloneCreditMemoStatus]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Update Stand Alone Credit Memo Status
 ** Purpose:           
 ** Date:   02/10/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		 -------------------------------            
	1    02/10/2023   Moin Bloch      Created
 **************************************************************/
CREATE   PROCEDURE [dbo].[UpdateStandAloneCreditMemoStatus]
@CreditMemoHeaderId BIGINT = NULL,
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
			DECLARE @StatusId INT
			DECLARE @StatusName VARCHAR(50)

			SELECT @StatusId = Id,
				   @StatusName = [Name] 
			  FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) 
			 WHERE [Name] = 'Closed';

			UPDATE [dbo].[CreditMemo]
			   SET [StatusId] = @StatusId,
				   [Status] = @StatusName
			 WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
		END
		IF(@Opr = 2)
		BEGIN
			UPDATE [dbo].[CreditMemo]
			   SET [IsClosed] = 1				   
			 WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
		END	
		IF(@Opr = 3)
		BEGIN
			UPDATE [dbo].[CreditMemo]
			   SET [IsClosed] = 0				   
			 WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
		END	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateStandAloneCreditMemoStatus' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CreditMemoHeaderId, '') AS VARCHAR(100))  
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