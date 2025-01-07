/*************************************************************
 ** File:   [USP_GetWOTaskInstructions]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get WO Task Instruction with ParentId NULL
 ** Purpose:
 ** Date:   01/01/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    01/01/2025   Vishal Suthar		Created

EXEC [dbo].[USP_GetWOTaskInstructions] 274
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOTaskInstructions]
	@TaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF (ISNULL(@TaskId, 0) = 0)
		BEGIN
			SELECT TIM.TaskInstructionId, TIM.Title, TIM.Description, TIM.SequenceNumber FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) WHERE ParentId IS NULL;
		END
		ELSE
		BEGIN
			SELECT TIM.TaskInstructionId, TIM.Title, TIM.Description, TIM.SequenceNumber FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) WHERE TaskId = @TaskId AND ParentId IS NULL;
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOTaskInstructions'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@TaskId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END