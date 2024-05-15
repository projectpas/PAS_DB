create    VIEW [dbo].[vw_ContactTagAudit]
AS
	SELECT  CT.AuditContactTagId AS [PkID],
	        CT.ContactTagId AS [ID],
			CT.TagName, 
			CT.Description,
			CT.SequenceNo,
			CT.CreatedBy AS [Created By],
			CT.UpdatedBy AS [Updated By],
			CT.CreatedDate AS [Created Date],
			CT.UpdatedDate AS [Updated Date],
			CT.IsActive AS [Is Active],
			CT.IsDeleted AS [Is Deleted]
	FROM [DBO].[ContactTagAudit] CT WITH (NOLOCK)