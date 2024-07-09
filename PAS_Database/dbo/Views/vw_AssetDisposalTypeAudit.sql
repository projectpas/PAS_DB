

CREATE VIEW [dbo].[vw_AssetDisposalTypeAudit]
AS
SELECT AssetDisposalTypeAuditId AS PkID, AssetDisposalTypeId AS ID, AssetDisposalCode, AssetDisposalName, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
FROM     dbo.AssetDisposalTypeAudit
GO



GO


