
CREATE      VIEW [dbo].[vw_binAudit]
AS
	SELECT ct.BinAuditId  AS PkID, ct.BinId AS ID	
	,ct.[Site] AS [Site]
	,ct.[Warehouse] AS [Warehouse]
	,ct.[Location] AS [Location]
	,ct.[Shelf] AS [Shelf]
	,ct.[Name] AS [Bin Name]
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
	FROM [DBO].[binAudit] ct WITH (NOLOCK)