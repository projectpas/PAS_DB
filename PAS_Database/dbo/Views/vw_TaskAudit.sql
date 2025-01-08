


CREATE      VIEW [dbo].[vw_TaskAudit] 
AS
	SELECT TA.TaskAuditId AS PkID, 
	TaskId AS ID, 
	[Description] AS 'Task', 
	IsTravelerTask as 'Traveler Task',
	StandardHours AS 'Standard Hours',
	StandardMinute AS 'Standard Minute',
	Descrepancy AS 'Descrepancy',
	Resolution AS 'Resolution',
	[Sequence] AS 'Sequence No',
	Memo AS 'Memo',
	TA.CreatedDate AS 'Created Date', 
	TA.UpdatedDate AS 'Updated Date', 
	TA.IsActive as 'Active ?',
	TA.IsDeleted as 'Deleted ?', 
	TA.CreatedBy as 'Created By', 
	TA.UpdatedBy as 'Updated By' 
	FROM dbo.TaskAudit AS TA WITH (NOLOCK)