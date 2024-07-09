

CREATE VIEW [dbo].[vw_AssetDepreciationMethodAudit]
AS
SELECT AssetDepreciationMethodAuditId AS PkID, AssetDepreciationMethodId AS ID, AssetDepreciationMethodCode, AssetDepreciationMethodName, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
FROM dbo.AssetDepreciationMethodAudit
GO



GO


