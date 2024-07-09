
CREATE VIEW [dbo].[vw_AssetDepreciationMethodAudit]
AS
SELECT AssetDepreciationMethodAuditId, AssetDepreciationMethodId, AssetDepreciationMethodCode, AssetDepreciationMethodName, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, SequenceNo
FROM     dbo.AssetDepreciationMethodAudit
GO



GO


