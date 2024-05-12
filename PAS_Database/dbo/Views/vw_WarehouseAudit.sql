CREATE     VIEW [dbo].[vw_WarehouseAudit]
AS
	SELECT ct.WarehouseAuditId  AS PkID, ct.WarehouseAuditId AS ID	
	,ct.[Name] AS [Site Name]
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
	FROM [DBO].[WarehouseAudit] ct WITH (NOLOCK)