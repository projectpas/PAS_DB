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
    2   13-AUG-2026   Sumit Kumar		Changes to show all WO templates regardless wheather its have pn num or not [PN-17659]

EXEC [USP_GetGenericWorkFlowTemplates] 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetGenericWorkFlowTemplates]
(
    @MasterCompanyId INT
)
AS
BEGIN
    BEGIN TRY
        SELECT DISTINCT
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
            ISNULL(wt.TaskCount, 0) AS TaskCount,
            CASE WHEN w.IsVersionIncrease IS NULL THEN CASE WHEN WFParentId IS NULL THEN 0 ELSE 1 END ELSE w.IsVersionIncrease END AS IsVersionIncrease
        FROM dbo.Workflow w WITH (NOLOCK)
        LEFT JOIN dbo.ItemMaster im WITH (NOLOCK) ON w.ItemMasterId = im.ItemMasterId AND ISNULL(im.IsNonStock,0) = 0
        LEFT JOIN (SELECT WorkflowId, COUNT(DISTINCT TaskId) AS TaskCount FROM dbo.WorkflowTask WITH (NOLOCK) WHERE ISNULL(IsDeleted, 0) = 0 GROUP BY WorkflowId) wt
            ON w.WorkflowId = wt.WorkflowId
        WHERE w.MasterCompanyId = @MasterCompanyId
            AND w.IsActive = 1
            AND ISNULL(w.IsDeleted, 0) = 0
            -- AND w.ItemMasterId IS NULL -- Show all templates regardless wheather the pn num have or not.
            AND w.TemplateType = 1 -- WO Template only
            AND TaskCount > 0
            AND IsVersionIncrease = 0 -- Fetch only latest version templates
        ORDER BY w.WorkflowDescription;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name();
        DECLARE @AdhocComments VARCHAR(150) = 'USP_GetGenericWorkFlowTemplates';
        DECLARE @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100));
        EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = 'PAS', @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database.', 16, 1);
    END CATCH
END
