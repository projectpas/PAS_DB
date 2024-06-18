
CREATE VIEW [dbo].[vw_ManagementStructureLevelAudit]
AS
	SELECT C.ManagmentStructureLevelAuditID AS PkID, C.ID AS ID, MST.[Description] AS [Level], C.Code AS [Code], C.[Description] AS [Description], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[ManagementStructureLevelAudit] C WITH (NOLOCK)
	INNER JOIN [DBO].[ManagementStructureType] MST WITH (NOLOCK) ON MST.TypeID = C.TypeID