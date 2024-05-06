CREATE   VIEW [dbo].[vw_IntegrationPortalAudit]
AS
	SELECT ipor.IntegrationPortalAuditId  AS PkID, ipor.IntegrationPortalId AS ID	,ipor.Description,ipor.PortalURL [Portal URL]
	,(EMP_CR.FirstName + ' ' + EMP_CR.LastName) AS [Created By],
	ipor.CreatedDate AS [Created Date], (EMP_UP.FirstName + ' ' + EMP_UP.LastName) AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].IntegrationPortalAudit ipor WITH (NOLOCK) 	
	LEFT JOIN [dbo].[Employee] EMP_CR WITH (NOLOCK) ON ipor.CreatedBy = EMP_CR.EmployeeId
    LEFT JOIN [dbo].[Employee] EMP_UP WITH (NOLOCK) ON ipor.UpdatedBy = EMP_UP.EmployeeId