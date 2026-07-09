/*************************************************************             
** File:   [USP_GetGenericWorkFlowTemplates]
** Author:   SUMIT KUMAR
** Description: Retrieves active workflow templates that are either generic (no PN) or match the given ItemMasterId.
** Purpose:
** Date:   07/02/2026

** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   07/02/2026   Sumit Kumar		Created

EXEC [USP_GetGenericWorkFlowTemplates] 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetGenericWorkFlowTemplates]
(
    @WorkScopeId BIGINT,
    @MasterCompanyId INT
)
AS
BEGIN
    BEGIN TRY
        SELECT
            w.WorkflowId,
            w.WorkScopeId,
            w.WorkflowDescription,
            w.Version,
            w.ItemMasterId,
            im.PartNumber,
            im.PartDescription,
            w.CreatedBy,
            w.CreatedDate,
            w.WorkOrderNumber as WorkFlowNo,
            ISNULL(wt.TaskCount, 0) AS TaskCount
        FROM dbo.Workflow w WITH (NOLOCK)
        LEFT JOIN dbo.ItemMaster im WITH (NOLOCK) ON w.ItemMasterId = im.ItemMasterId
        LEFT JOIN (SELECT WorkflowId, COUNT(DISTINCT TaskId) AS TaskCount FROM dbo.WorkflowTask WITH (NOLOCK) WHERE ISNULL(IsDeleted, 0) = 0 GROUP BY WorkflowId) wt
            ON w.WorkflowId = wt.WorkflowId
        WHERE w.WorkScopeId = @WorkScopeId
            AND w.MasterCompanyId = @MasterCompanyId
            AND w.IsActive = 1
            AND ISNULL(w.IsDeleted, 0) = 0
            AND w.ItemMasterId IS NULL -- Only Generic WO Templates
            AND w.TemplateType = 1 -- WO Template only
            AND TaskCount > 0
        ORDER BY w.WorkflowDescription;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name();
        DECLARE @AdhocComments VARCHAR(150) = 'USP_GetGenericWorkFlowTemplates';
        DECLARE @ProcedureParameters VARCHAR(3000) = '@WorkScopeId = ' + CAST(ISNULL(@WorkScopeId, '') AS VARCHAR(100));
        EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = 'PAS', @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database.', 16, 1);
    END CATCH
END
