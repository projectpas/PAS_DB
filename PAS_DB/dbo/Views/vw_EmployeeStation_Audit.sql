CREATE   VIEW [dbo].[vw_EmployeeStation_Audit]
AS
	SELECT C.AuditEmployeeStationId AS PkID, C.EmployeeStationId AS ID, StationName AS [Employee Station Name], Description AS [Description], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[EmployeeStationAudit] C WITH (NOLOCK)