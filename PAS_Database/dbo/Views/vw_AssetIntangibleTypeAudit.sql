CREATE   VIEW [DBO].[vw_AssetIntangibleTypeAudit]
AS
SELECT 
	AssetIntangibleTypeAuditId AS [PkID],
	AssetIntangibleTypeId AS [ID],
	AssetIntangibleName AS [Intangible Asset Class],
	AssetIntangibleCode AS [Code],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [DBO].[AssetIntangibleTypeAudit]
GO