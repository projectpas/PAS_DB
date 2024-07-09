CREATE     VIEW [dbo].[vw_WorkPerformedAudit] 
AS
	SELECT	WPA.WorkPerformedAuditId AS PkID, WorkPerformedId AS ID, WorkPerformedCode AS 'Work Performed Code', Description, WPA.Memo
	,WPA.IsActive AS 'Active ?', WPA.IsDeleted AS 'Deleted ?', WPA.CreatedBy as 'Created By', WPA.UpdatedBy AS 'Updated By', WPA.CreatedDate AS 'Created On', WPA.UpdatedDate AS 'Updated On'
	FROM dbo.WorkPerformedAudit AS WPA WITH (NOLOCK)