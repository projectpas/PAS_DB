CREATE VIEW [dbo].[vw_UOMFamilyTypeAudit]
AS
SELECT UOMFamilyTypeAuditID AS [PkID],
       UOMFamilyTypeId AS [ID],
       Name AS [Name],
       Description AS [Description],
       CreatedBy AS [Created By],
       UpdatedBy AS [Updated By],
       CreatedDate AS [Created On],
       UpdatedDate AS [Updated On],
       IsActive AS [IsActive],
       IsDeleted AS [IsDeleted]
FROM  [dbo].[UOMFamilyTypeAudit]
