CREATE VIEW [dbo].[vw_PublicationTypeAudit]
AS
SELECT PublicationTypeAuditId, PublicationTypeId, Name, Description ,CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
FROM  [dbo].[PublicationTypeAudit]