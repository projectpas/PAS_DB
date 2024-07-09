CREATE     VIEW [dbo].[vw_EvidenceAudit] 
AS
	SELECT	EA.EvidenceAuditId AS PkID, EvidenceId AS ID, EvidenceName AS 'Evidence'
	,EA.IsActive AS 'Active ?', EA.IsDeleted AS 'Deleted ?', EA.CreatedBy as 'Created By', EA.UpdatedBy AS 'Updated By', EA.CreatedDate AS 'Created On', EA.UpdatedDate AS 'Updated On'
	FROM dbo.EvidenceAudit AS EA WITH (NOLOCK)