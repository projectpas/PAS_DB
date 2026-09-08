/***************************************************************  
 ** File:   [USP_WorkFlowTaskInstruction_DeleteRestoreById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to UPDATE delete State of TaskInstruction For Work Flow
 ** Date:  07-Feb-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  					Change Description              
 ** --   --------			-------					--------------------------------
 	1    07-Feb-2025		Devendra Shekh				Created            
	2    03-Sep-2026		SUMIT KUMAR				[PN-17813] Soft-delete / restore associated WorkFlowDirectionImage records
 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_WorkFlowTaskInstruction_DeleteRestoreById]
@WorkflowDirectionId bigint,
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
					;WITH RecursiveCTE AS (
						SELECT WorkflowDirectionId 
						FROM DBO.WorkflowDirection WITH (NOLOCK)
						WHERE WorkflowDirectionId = @WorkflowDirectionId

						UNION ALL

						SELECT TIM.WorkflowDirectionId
						FROM DBO.WorkflowDirection TIM WITH (NOLOCK)
						INNER JOIN RecursiveCTE R ON TIM.ParentId = R.WorkflowDirectionId
					)
					
					UPDATE WorkflowDirection
					SET IsDeleted = 1
					WHERE WorkflowDirectionId IN (SELECT WorkflowDirectionId FROM RecursiveCTE);

					-- Soft-delete associated images in WorkFlowDirectionImage for deleted directions
					;WITH RecursiveCTE AS (
						SELECT WorkflowDirectionId 
						FROM DBO.WorkflowDirection WITH (NOLOCK)
						WHERE WorkflowDirectionId = @WorkflowDirectionId

						UNION ALL

						SELECT TIM.WorkflowDirectionId
						FROM DBO.WorkflowDirection TIM WITH (NOLOCK)
						INNER JOIN RecursiveCTE R ON TIM.ParentId = R.WorkflowDirectionId
					)
					UPDATE WorkFlowDirectionImage
					SET IsDeleted = 1,
						UpdatedBy = @UpdatedBy,
						UpdatedDate = GETUTCDATE()
					WHERE WorkflowDirectionId IN (SELECT WorkflowDirectionId FROM RecursiveCTE);
				END
				ELSE
				BEGIN
					;WITH RecursiveCTE AS (
						SELECT WorkflowDirectionId 
						FROM DBO.WorkflowDirection WITH (NOLOCK)
						WHERE WorkflowDirectionId = @WorkflowDirectionId

						UNION ALL

						SELECT TIM.WorkflowDirectionId
						FROM DBO.WorkflowDirection TIM WITH (NOLOCK)
						INNER JOIN RecursiveCTE R ON TIM.ParentId = R.WorkflowDirectionId
					)
					
					UPDATE WorkflowDirection
					SET IsDeleted = 0
					WHERE WorkflowDirectionId IN (SELECT WorkflowDirectionId FROM RecursiveCTE);

					-- Restore associated images in WorkFlowDirectionImage for restored directions
					;WITH RecursiveCTE AS (
						SELECT WorkflowDirectionId 
						FROM DBO.WorkflowDirection WITH (NOLOCK)
						WHERE WorkflowDirectionId = @WorkflowDirectionId

						UNION ALL

						SELECT TIM.WorkflowDirectionId
						FROM DBO.WorkflowDirection TIM WITH (NOLOCK)
						INNER JOIN RecursiveCTE R ON TIM.ParentId = R.WorkflowDirectionId
					)
					UPDATE WorkFlowDirectionImage
					SET IsDeleted = 0,
						UpdatedBy = @UpdatedBy,
						UpdatedDate = GETUTCDATE()
					WHERE WorkflowDirectionId IN (SELECT WorkflowDirectionId FROM RecursiveCTE);
				END
			END
		END TRY    
		BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_WorkFlowTaskInstruction_DeleteRestoreById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkflowDirectionId, '') + ''
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