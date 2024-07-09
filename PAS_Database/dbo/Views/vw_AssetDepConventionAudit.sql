
CREATE VIEW [dbo].[vw_AssetDepConventionAudit]
AS
SELECT AssetDepConventionAuditId AS PkID, AssetDepConventionId As ID, AssetDepConventionCode, AssetDepConventionName, UpdatedDate, CreatedDate, UpdatedBy, CreatedBy, IsActive ,IsDeleted
FROM  dbo.AssetDepConventionAudit WITH (NOLOCK)
GO



GO


