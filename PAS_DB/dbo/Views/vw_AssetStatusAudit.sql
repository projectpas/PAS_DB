
CREATE VIEW [dbo].[vw_AssetStatusAudit]
AS
SELECT AssetStatusAuditId  AS PkID, AssetStatusId AS ID, Name, Memo, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsDeleted, IsActive 
FROM dbo.AssetStatusAudit