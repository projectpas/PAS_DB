
CREATE   VIEW [dbo].[vw_WOPartStatusAudit] 
AS
	SELECT	WPSA.AuditWOPartStatusId AS PkID, WOPartStatusId AS ID, PartStatus AS 'Part Status', Description, WPSA.Memo
	,WPSA.IsActive AS 'Active ?', WPSA.IsDeleted AS 'Deleted ?', WPSA.CreatedBy as 'Created By', WPSA.UpdatedBy AS 'Updated By', WPSA.CreatedDate AS 'Created On', WPSA.UpdatedDate AS 'Updated On', WPSA.MasterCompanyId
	FROM dbo.WOPartStatusAudit AS WPSA WITH (NOLOCK)