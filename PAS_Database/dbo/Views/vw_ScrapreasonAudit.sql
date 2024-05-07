
CREATE   VIEW [dbo].[vw_ScrapreasonAudit] 
AS
	SELECT	SRA.ScrapReasonAuditId AS PkID, Id AS ID, Reason AS 'Reason', SRA.Memo
	,SRA.IsActive AS 'Active ?', SRA.IsDeleted AS 'Deleted ?', SRA.CreatedBy as 'Created By', SRA.UpdatedBy AS 'Updated By', SRA.CreatedDate AS 'Created On', SRA.UpdatedDate AS 'Updated On', SRA.MasterCompanyId
	FROM dbo.ScrapReasonAudit AS SRA WITH (NOLOCK)