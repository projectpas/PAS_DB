CREATE   VIEW [dbo].[vw_EmployeeExpertise_Audit]
AS
	SELECT C.AuditEmployeeExpertiseId AS PkID, C.EmployeeExpertiseId AS ID, Description AS [Expertise Name], Avglaborrate AS [Avg Labor Rate], Overheadburden AS [Overhead Burden], IsWorksInShop AS [Works In Shop?], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[EmployeeExpertiseAudit] C WITH (NOLOCK)