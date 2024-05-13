
CREATE     VIEW [dbo].[vw_ManufacturerAudit]
AS
	SELECT ct.ManufacturerAuditId  AS PkID, ct.ManufacturerAuditId AS ID	
	,ct.[Name] AS [Name]
	,ct.CreatedBy AS [Created By],
	ct.CreatedDate AS [Created Date], 
	ct.UpdatedBy AS [Updated By], 
	ct.UpdatedDate AS [Updated Date], ct.IsActive AS [Is Active], ct.IsDeleted AS [Is Deleted]
	FROM [DBO].[ManufacturerAudit] ct WITH (NOLOCK)