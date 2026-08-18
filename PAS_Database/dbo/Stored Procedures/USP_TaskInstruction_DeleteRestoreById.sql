
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
    3    28-JAN-2025		Vishal Suthar  			Modified the logic of delete and restore with all it's child too
    4    06-MAR-2025		RAJESH GAMI  			Add condition while deleting the record (Hard delete)
	5    07-JULY-2026		NAKUL CHANDIGRA			Add condition for hard deleting the entire Task Instruction. [PN-17036]
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
					IF((SELECT TOP 1 ISNULL(SequenceNumber,0) FROM DBO.TaskInstructionMaster WITH (NOLOCK) WHERE TaskInstructionId =  @TaskInstructionId) = 0)
					BEGIN
						--UPDATE TaskInstructionMaster
						--SET IsDeleted = 1
						--WHERE TaskInstructionId = @TaskInstructionId;
						DELETE FROM TaskInstructionMaster WHERE TaskInstructionId = @TaskInstructionId OR ParentId = @TaskInstructionId ;
					END
					ELSE
					BEGIN
						;WITH RecursiveCTE AS (
							SELECT TaskInstructionId 
							FROM DBO.TaskInstructionMaster WITH (NOLOCK)
							WHERE TaskInstructionId = @TaskInstructionId

							UNION ALL

							SELECT TIM.TaskInstructionId
							FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK)
							INNER JOIN RecursiveCTE R ON TIM.ParentId = R.TaskInstructionId
						)
					DELETE FROM TaskInstructionMaster WHERE TaskInstructionId IN (SELECT TaskInstructionId FROM RecursiveCTE) AND SequenceNumber >0
						--UPDATE TaskInstructionMaster
						--SET IsDeleted = 1
						--WHERE TaskInstructionId IN (SELECT TaskInstructionId FROM RecursiveCTE) AND SequenceNumber >0;
					END
					
				END
				ELSE
				BEGIN
					;WITH RecursiveCTE AS (
						SELECT TaskInstructionId 
						FROM DBO.TaskInstructionMaster WITH (NOLOCK)
						WHERE TaskInstructionId = @TaskInstructionId

						UNION ALL

						SELECT TIM.TaskInstructionId
						FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK)
						INNER JOIN RecursiveCTE R ON TIM.ParentId = R.TaskInstructionId
					)
					
					UPDATE TaskInstructionMaster
					SET IsDeleted = 0
					WHERE TaskInstructionId IN (SELECT TaskInstructionId FROM RecursiveCTE);
					
					DECLARE @TaskId BIGINT = (SELECT TOP 1 TaskId FROM dbo.TaskInstructionMaster WITH(NOLOCK) WHERE TaskInstructionId = @TaskInstructionId)
					Update TaskInstructionMaster SET IsDeleted = 0  WHERE TaskId = @TaskId AND SequenceNumber = 0 AND IsParent = 1; 

				
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