
CREATE VIEW [dbo].[vw_AssetIntangibleTypeAudit]
AS
SELECT AssetIntangibleTypeId  AS PkID, AssetIntangibleTypeId AS ID, AssetIntangibleName, AssetIntangibleCode, Description, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsDeleted, IsActive 
FROM     dbo.AssetIntangibleType
GO



GO


