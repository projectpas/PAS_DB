

CREATE VIEW [dbo].[vw_AssetDepreciationIntervalAudit]
AS
SELECT AssetDepreciationIntervalAuditId AS PkID, AssetDepreciationIntervalId AS ID, AssetDepreciationIntervalCode, AssetDepreciationIntervalName, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive,  IsDeleted
FROM dbo.AssetDepreciationIntervalAudit WITH(NOLOCK)
GO



GO


