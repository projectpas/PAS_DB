
CREATE   VIEW [dbo].[vw_TaskAudit] 
AS
	SELECT TA.TaskAuditId AS PkID, TaskId AS ID, Description AS 'Task', 
	IsTravelerTask as 'Traveler Task',Sequence AS 'Sequence No',Memo AS 'Memo'
	,TA.CreatedDate, TA.UpdatedDate, TA.IsActive, TA.MasterCompanyId, TA.CreatedBy, TA.UpdatedBy, TA.IsDeleted
	FROM dbo.TaskAudit AS TA WITH (NOLOCK)