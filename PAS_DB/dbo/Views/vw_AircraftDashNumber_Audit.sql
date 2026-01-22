
CREATE   VIEW [dbo].[vw_AircraftDashNumber_Audit]
AS
	SELECT C.DashNumberAuditId AS PkID, C.DashNumberId AS ID, AircraftTypeId AS [Aircraft Type], AircraftModelId AS [Model Name], DashNumber AS [Dash Number], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[AircraftDashNumberAudit] C WITH (NOLOCK)