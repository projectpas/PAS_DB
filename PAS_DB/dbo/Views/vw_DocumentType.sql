CREATE   VIEW [dbo].[vw_DocumentType]
AS
	SELECT ipor.AuditDocumentTypeId  AS PkID, ipor.DocumentTypeId AS ID	,ipor.Name
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].DocumentTypeAudit ipor WITH (NOLOCK)