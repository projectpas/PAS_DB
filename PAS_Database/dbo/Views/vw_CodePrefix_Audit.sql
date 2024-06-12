CREATE   VIEW [dbo].[vw_CodePrefix_Audit]
AS
	SELECT C.AuditCodePrefixId AS PkID, C.CodePrefixId AS ID, CodeType AS [Code Type], CodePrefix AS [Code Prefix], CodeSufix AS [Code Sufix], StartsFrom AS [Starts From], Description, (EMP_CR.FirstName + ' ' + EMP_CR.LastName) AS [Created By],
	C.CreatedDate AS [Created Date], (EMP_UP.FirstName + ' ' + EMP_UP.LastName) AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[CodePrefixesAudit] C WITH (NOLOCK) 
	LEFT JOIN [dbo].[Employee] EMP_CR WITH (NOLOCK) ON C.CreatedBy = EMP_CR.CreatedBy
    LEFT JOIN [dbo].[Employee] EMP_UP WITH (NOLOCK) ON C.UpdatedBy = EMP_UP.UpdatedBy