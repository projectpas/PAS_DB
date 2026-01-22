CREATE    VIEW [dbo].[vw_JobTitle_Audit]
AS
	SELECT C.JobTitleAuditId AS PkID, C.JobTitleId AS ID, Description AS [Job Title Name], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[JobTitleAudit] C WITH (NOLOCK)