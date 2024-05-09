
CREATE   VIEW [dbo].[vw_CapabilityTypeAudit] 
AS
	SELECT AuditCapabilityTypeId AS PkID, CapabilityTypeId AS ID, CapabilityTypeDesc, SequenceNo, Description, SequenceMemo
	,CTA.IsActive AS 'Active ?', CTA.IsDeleted AS 'Deleted ?', CTA.CreatedBy as 'Created By', CTA.UpdatedBy AS 'Updated By', CTA.CreatedDate AS 'Created On', CTA.UpdatedDate AS 'Updated On', CTA.MasterCompanyId
	FROM dbo.CapabilityTypeAudit AS CTA WITH (NOLOCK)