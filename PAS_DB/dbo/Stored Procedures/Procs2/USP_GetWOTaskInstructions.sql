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
    2    05 MAR 2025   RAJESH GAMI		Added Parameter: MasterCompanyId and Change the logic based on recenlty change in TaskInstructionMaster Screen.
EXEC [dbo].[USP_GetWOTaskInstructions] 0,1
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetWOTaskInstructions]
	@TaskId bigint = 0,
	@MasterCompanyId INT 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
			IF OBJECT_ID(N'tempdb..#TmpWOTaskTbl') IS NOT NULL    
			BEGIN    
				DROP TABLE #TmpWOTaskTbl
			END
			IF OBJECT_ID(N'tempdb..#TmpWOWithoutTaskTbl') IS NOT NULL    
			BEGIN    
				DROP TABLE #TmpWOWithoutTaskTbl
			END
		IF (ISNULL(@TaskId, 0) = 0)
		BEGIN
			SELECT TaskInstructionId INTO #TmpWOWithoutTaskTbl FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) WHERE ParentId IS NULL AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId
			SELECT TIM.TaskInstructionId, TIM.Title, TIM.Description, TIM.SequenceNumber FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) 
				   WHERE ParentId IN(SELECT TaskInstructionId FROM #TmpWOWithoutTaskTbl) AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId;
		END
		ELSE
		BEGIN
			SELECT TaskInstructionId INTO #TmpWOTaskTbl FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) WHERE ParentId IS NULL AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId AND TaskId = @TaskId
			SELECT TIM.TaskInstructionId, TIM.Title, TIM.Description, TIM.SequenceNumber FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) 
				   WHERE TaskId = @TaskId AND  ParentId IN(SELECT TaskInstructionId FROM #TmpWOTaskTbl) AND IsDeleted = 0;
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