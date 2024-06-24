CREATE   VIEW [dbo].[vw_PublicationTypeAudit]
AS
SELECT PublicationTypeAuditId AS [PkID], 
	   PublicationTypeId AS [ID], 
	   Name AS [Name], 
	   Description AS [Description],
	   CreatedBy AS [Created By], 
	   UpdatedBy AS [Updated By], 
	   CreatedDate AS [Created On], 
	   UpdatedDate AS [Updated On], 
	   IsActive AS [IsActive], 
	   IsDeleted AS [IsDeleted]
FROM  [dbo].[PublicationTypeAudit]