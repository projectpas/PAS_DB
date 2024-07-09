
CREATE VIEW [dbo].[vw_TangibleClassAudit]
AS
SELECT TangibleClassAuditId  AS PkID, TangibleClassId AS ID, TangibleClassName, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
FROM     dbo.TangibleClassAudit
GO



GO


