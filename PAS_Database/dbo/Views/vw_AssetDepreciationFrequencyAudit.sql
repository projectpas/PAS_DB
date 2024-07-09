

CREATE VIEW [dbo].[vw_AssetDepreciationFrequencyAudit]
AS
SELECT AssetDepreciationFrequencyAuditId AS PkID, AssetDepreciationFrequencyId AS ID, Name, Description, UpdatedDate, CreatedDate, UpdatedBy, CreatedBy, IsActive, IsDeleted
FROM dbo.AssetDepreciationFrequencyAudit WITH(NOLOCk)
GO



GO


