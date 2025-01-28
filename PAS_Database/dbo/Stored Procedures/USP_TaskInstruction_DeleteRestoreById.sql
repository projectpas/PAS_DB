/***************************************************************  
 ** File:   [USP_TaskInstruction_DeleteRestoreById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to UPDATE delete State of TaskInstruction
 ** Date:  1st-JAN-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    1st-JAN-2025		Devendra Shekh			Created
    2    28-JAN-2025		Ekta Chandegra  		Update isDeleted value for parent
 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_TaskInstruction_DeleteRestoreById]
@TaskInstructionId bigint,
@IsDeleted bit,
@UpdatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
			BEGIN 
				IF(@IsDeleted = 0)
				BEGIN
					UPDATE [dbo].[TaskInstructionMaster]
					SET		IsDeleted = 1,
							UpdatedBy = @UpdatedBy,
							UpdatedDate = GETUTCDATE()
					WHERE [TaskInstructionId] = @TaskInstructionId OR [ParentId] = @TaskInstructionId
				END
				ELSE
				BEGIN
					UPDATE [dbo].[TaskInstructionMaster]
					SET		IsDeleted = 0,
							UpdatedBy = @UpdatedBy,
							UpdatedDate = GETUTCDATE()
					WHERE [TaskInstructionId] = @TaskInstructionId OR [ParentId] = @TaskInstructionId
				END
			END
		END TRY    
		BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_TaskInstruction_DeleteRestoreById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TaskInstructionId, '') + ''
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