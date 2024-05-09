CREATE   VIEW [dbo].[vw_CurrencyAudit]
AS
	SELECT ca.CurrencyAuditId  AS PkID, ca.CurrencyId AS ID	,ca.Code,ca.Symbol ,ca.DisplayName [Display ame]
	,(EMP_CR.FirstName + ' ' + EMP_CR.LastName) AS [Created By],
	ca.CreatedDate AS [Created Date], (EMP_UP.FirstName + ' ' + EMP_UP.LastName) AS [Updated By], ca.UpdatedDate AS [Updated Date], ca.IsActive AS [Is Active], ca.IsDeleted AS [Is Deleted]
	FROM [DBO].CurrencyAudit ca WITH (NOLOCK) 	
	LEFT JOIN [dbo].[Employee] EMP_CR WITH (NOLOCK) ON ca.CreatedBy = EMP_CR.EmployeeId
    LEFT JOIN [dbo].[Employee] EMP_UP WITH (NOLOCK) ON ca.UpdatedBy = EMP_UP.EmployeeId