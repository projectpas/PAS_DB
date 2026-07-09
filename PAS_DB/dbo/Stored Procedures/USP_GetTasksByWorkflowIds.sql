/*************************************************************             
** File:   [USP_GetTasksByWorkflowIds]
** Author:   SUMIT KUMAR
** Description:  Retrieves active tasks associated with the specified list of workflow template IDs.
** Purpose:
** Date:   07/02/2026

** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   07/02/2026   Sumit Kumar		Created

EXEC [USP_GetTasksByWorkflowIds] 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetTasksByWorkflowIds]
(
    @WorkflowIds VARCHAR(MAX),
    @MasterCompanyId INT,
    @WorkOrderId BIGINT = 0,
    @WorkOrderPartNumberId BIGINT = 0
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            w.WorkflowId,
            w.WorkflowDescription,
            wt.WorkflowTaskId,
            wt.TaskId,
            t.Description AS TaskDescription,
            t.Description AS Task,
            wt.SequenceNumber,
            ws.WorkScopeId,
            ws.Description AS WorkScope,
            w.WorkOrderNumber as WorkFlowNo,
            CAST(CASE WHEN wot.TaskId IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS AlreadyInWO
        FROM dbo.WorkflowTask wt WITH(NOLOCK)
        INNER JOIN dbo.Workflow w WITH(NOLOCK) ON wt.WorkflowId = w.WorkflowId
        INNER JOIN dbo.Task t WITH(NOLOCK) ON wt.TaskId = t.TaskId
        LEFT JOIN dbo.WorkScope ws WITH(NOLOCK) ON w.WorkScopeId = ws.WorkScopeId
        LEFT JOIN (SELECT DISTINCT TaskId FROM dbo.WorkOrderTask WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId 
                    AND WorkOrderPartNumberId = @WorkOrderPartNumberId
                    AND ISNULL(IsActive, 1) = 1
                    AND ISNULL(IsDeleted, 0) = 0
                ) wot ON wot.TaskId = wt.TaskId
        WHERE wt.WorkflowId IN (SELECT Item FROM DBO.SPLITSTRING(@WorkflowIds, ','))
          AND wt.MasterCompanyId = @MasterCompanyId
          AND ISNULL(wt.IsDeleted, 0) = 0
          AND ISNULL(w.IsDeleted, 0) = 0
        ORDER BY w.WorkflowId, TRY_CAST(wt.SequenceNumber AS DECIMAL(10, 4));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name();
        DECLARE @AdhocComments VARCHAR(150) = 'USP_GetTasksByWorkflowIds';
        DECLARE @ProcedureParameters VARCHAR(3000) = '@WorkflowIds = ' + CAST(ISNULL(@WorkflowIds, '') AS VARCHAR(100));
        EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = 'PAS', @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database.', 16, 1);
    END CATCH
END
