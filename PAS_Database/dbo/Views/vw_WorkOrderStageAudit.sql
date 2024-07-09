CREATE     VIEW [dbo].[vw_WorkOrderStageAudit] 
AS
	SELECT WSA.WorkOrderStageAuditId AS PkID, WorkOrderStageId AS ID, EmployeeName AS Manager, 
	IsCustAlerts as 'Alert Customer',IncludeInDashboard AS 'Include In Dashboard',IncludeInStageReport AS 'Include In Stage Report',	Sequence AS 'Sequence No',
	WS.Status AS 'Status', WSA.CreatedDate, WSA.UpdatedDate, WSA.IsActive, WSA.CreatedBy, WSA.UpdatedBy, WSA.IsDeleted
	FROM dbo.WorkOrderStageAudit AS WSA WITH (NOLOCK)
	LEFT JOIN [dbo].[WorkOrderStatus] WS WITH(NOLOCK) ON WSA.StatusId = WS.Id