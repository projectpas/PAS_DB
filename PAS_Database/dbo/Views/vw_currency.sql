CREATE VIEW [dbo].[vw_currency]
AS
SELECT        dbo.Currency.CurrencyId, dbo.Currency.Code, dbo.Currency.Symbol, dbo.Currency.DisplayName, dbo.Currency.Memo, dbo.Currency.MasterCompanyId, dbo.Currency.CreatedBy, dbo.Currency.UpdatedBy, 
                         dbo.Currency.CreatedDate, dbo.Currency.UpdatedDate, dbo.Currency.IsActive, dbo.Currency.IsDeleted, dbo.Currency.CountryId, dbo.Countries.nice_name AS Country
FROM            dbo.Currency INNER JOIN
                         dbo.Countries ON dbo.Currency.CountryId = dbo.Countries.countries_id