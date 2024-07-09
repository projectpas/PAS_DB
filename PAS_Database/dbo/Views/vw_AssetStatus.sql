
CREATE VIEW [dbo].[vw_AssetStatus]
AS
SELECT AssetStatusId, Name, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
FROM     dbo.AssetStatus
GO



GO


