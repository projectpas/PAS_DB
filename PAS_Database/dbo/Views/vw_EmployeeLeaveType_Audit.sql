CREATE   VIEW [dbo].[vw_EmployeeLeaveType_Audit]
AS
	SELECT C.AuditEmployeeLeaveTypeId AS PkID, C.EmployeeLeaveTypeId AS ID, LeaveType AS [Employee Leave Type], Description AS [Description], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[EmployeeLeaveTypeAudit] C WITH (NOLOCK)