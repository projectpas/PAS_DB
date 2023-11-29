CREATE   VIEW dbo.vw_countryList
AS
	SELECT countries_id,countries_name,countries_iso3,MasterCompanyId
	FROM dbo.Countries WITH(NOLOCK)