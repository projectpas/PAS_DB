
CREATE VIEW [dbo].[vw_customer_billing_info_main]
AS
SELECT        dbo.CustomerBillingAddress.CustomerBillingAddressId, dbo.CustomerBillingAddress.CustomerId, dbo.CustomerBillingAddress.AddressId, dbo.CustomerBillingAddress.IsPrimary, dbo.CustomerBillingAddress.SiteName, 
                         dbo.CustomerBillingAddress.MasterCompanyId, dbo.CustomerBillingAddress.IsActive, dbo.Address.Line1, dbo.Address.Line2, dbo.Address.City, dbo.Address.StateOrProvince, dbo.Address.PostalCode, 
                         dbo.Countries.nice_name AS CountryName, dbo.Countries.countries_id AS countryid
FROM            dbo.Address INNER JOIN
                         dbo.CustomerBillingAddress ON dbo.Address.AddressId = dbo.CustomerBillingAddress.AddressId INNER JOIN
                         dbo.Countries ON dbo.Address.CountryId = dbo.Countries.countries_id
WHERE        (dbo.CustomerBillingAddress.IsDeleted = 0)