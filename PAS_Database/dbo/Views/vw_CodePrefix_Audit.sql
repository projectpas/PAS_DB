CREATE   VIEW [dbo].[vw_CodePrefix_Audit]
AS
	SELECT C.AuditCodePrefixId AS PkID, C.CodePrefixId AS ID, CodeType AS [Code Type], CodePrefix AS [Code Prefix], CodeSufix AS [Code Sufix], StartsFrom AS [Starts From], Description, C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[CodePrefixesAudit] C WITH (NOLOCK)