-----------Standard View ------------
CREATE   VIEW [dbo].[vw_StandardAudit]
AS
	SELECT ct.StandardAuditId  AS PkID, ct.StandardId AS ID	
	,ct.StandardName [Standard Name]
	,(EMP_CR.FirstName + ' ' + EMP_CR.LastName) AS [Created By],
	ct.CreatedDate AS [Created Date], (EMP_UP.FirstName + ' ' + EMP_UP.LastName) AS [Updated By], ct.UpdatedDate AS [Updated Date], ct.IsActive AS [Is Active], ct.IsDeleted AS [Is Deleted]
	FROM [DBO].[StandardAudit] ct WITH (NOLOCK) 	
	LEFT JOIN [dbo].[Employee] EMP_CR WITH (NOLOCK) ON ct.CreatedBy = EMP_CR.EmployeeId
    LEFT JOIN [dbo].[Employee] EMP_UP WITH (NOLOCK) ON ct.UpdatedBy = EMP_UP.EmployeeId