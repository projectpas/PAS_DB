CREATE     VIEW [dbo].[vw_LocationAudit]
AS
	SELECT ct.LocationAuditId  AS PkID, ct.LocationAuditId AS ID	
	,ct.[Name] AS [Site Name]
	,ct.[Warehouse] AS [Warehouse]
	,ct.[LegalEntity] AS [Legal Entity]
	,ct.[Line1] AS [Address Line1]
	,ct.[Line2] AS [Address Line2]
	,ct.[City] AS [City]
	,ct.[StateOrProvince] AS [State]
	,ct.[PostalCode] AS [PostalCode]
	,ct.[Country] AS [Country]
	,ct.CreatedBy AS [Created By],
	ct.CreatedDate AS [Created Date], 
	ct.UpdatedBy AS [Updated By], 
	ct.UpdatedDate AS [Updated Date], ct.IsActive AS [Is Active], ct.IsDeleted AS [Is Deleted]
	FROM [DBO].[LocationAudit] ct WITH (NOLOCK)