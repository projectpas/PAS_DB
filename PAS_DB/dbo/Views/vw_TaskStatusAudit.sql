CREATE     VIEW [dbo].[vw_TaskStatusAudit] 
AS
	SELECT	TSA.TaskStatusAuditId AS PkID, TaskStatusId AS ID, Description AS 'Task Status', TSA.Memo
	,TSA.IsActive AS 'Active ?', TSA.IsDeleted AS 'Deleted ?', TSA.CreatedBy as 'Created By', TSA.UpdatedBy AS 'Updated By', TSA.CreatedDate AS 'Created On', TSA.UpdatedDate AS 'Updated On'
	FROM dbo.TaskStatusAudit AS TSA WITH (NOLOCK)