CREATE VIEW [dbo].[vw_CertificationTypeAudit]
AS
	SELECT ipor.CertificationTypeAuditId  AS PkID, ipor.CertificationTypeId AS ID	,ipor.CertificationName As [Certification Name]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].CertificationTypeAudit ipor WITH (NOLOCK)