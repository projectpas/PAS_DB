CREATE   VIEW [dbo].[vw_FindingAudit] 
AS
	SELECT FA.AuditFindingId AS PkID, FindingId AS ID, FindingCode, Description, CreatedDate, UpdatedDate, IsActive, MasterCompanyId, CreatedBy, UpdatedBy, IsDeleted
	FROM dbo.FindingAudit AS FA WITH (NOLOCK)