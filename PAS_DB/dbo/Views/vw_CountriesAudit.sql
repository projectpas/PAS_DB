CREATE   VIEW [dbo].[vw_CountriesAudit]
AS
	SELECT CA.AuditCountries_id AS PkID,CA.countries_id AS ID , CA.countries_name AS [Country Name],
	CA.nice_name AS [Nice Name], CA.countries_iso_code AS [Country Iso Code],CA.countries_iso3 AS [Country iso3],
	CA.countries_numcode AS [Country Number Code],CA.countries_isd_code AS [Country Isd Code]
	,CA.SequenceNo AS [Sequence Num] , CA.Description AS [Description] , CA.Memo 
	,CA.CreatedBy AS [Created By],
	CA.CreatedDate AS [Created Date], CA.UpdatedBy AS [Updated By], CA.UpdatedDate AS [Updated Date], CA.IsActive AS [Is Active], CA.IsDeleted AS [Is Deleted]
	FROM [DBO].CountriesAudit CA WITH (NOLOCK)