CREATE   VIEW [dbo].[vw_PercentAudit]
AS
	SELECT ca.PercentageAuditId  AS PkID, ca.PercentId AS ID	,ca.PercentValue [Percent Value],ca.Description 
	,ca.CreatedBy AS [Created By],
	ca.CreatedDate AS [Created Date], ca.UpdatedBy AS [Updated By], ca.UpdatedDate AS [Updated Date], ca.IsActive AS [Is Active], ca.IsDeleted AS [Is Deleted]
	FROM [DBO].PercentAudit ca WITH (NOLOCK)