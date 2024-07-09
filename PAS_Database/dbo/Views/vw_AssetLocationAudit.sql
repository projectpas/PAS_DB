

CREATE VIEW [dbo].[vw_AssetLocationAudit]
AS
SELECT AssetLocationId AS PkID, AssetLocationId AS ID, Code, Name, CreatedBy, UpdatedBy, UpdatedDate, CreatedDate, IsDeleted, IsActive
FROM     dbo.AssetLocation
GO



GO


