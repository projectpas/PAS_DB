

CREATE VIEW [dbo].[vw_warehouse]
AS
SELECT        dbo.Warehouse.WarehouseId, Warehouse.WarehouseCode, dbo.Warehouse.Name, dbo.Warehouse.SiteId, dbo.Warehouse.Memo, dbo.Warehouse.MasterCompanyId, dbo.Warehouse.CreatedBy, dbo.Warehouse.UpdatedBy, dbo.Warehouse.CreatedDate, 
                         dbo.Warehouse.UpdatedDate, dbo.Warehouse.IsActive, dbo.Warehouse.IsDeleted, dbo.Site.Name AS SiteName, dbo.Address.Line1, dbo.Address.Line2, dbo.Address.Line3, dbo.Address.City, dbo.Address.StateOrProvince, 
                         dbo.Address.PostalCode, dbo.Countries.nice_name AS Country, dbo.Site.LegalEntityId, dbo.Site.SiteId AS Expr1,ISNULL(dbo.LegalEntity.Name,'') AS LegalEntity
FROM            dbo.Address WITH(NOLOCK) INNER JOIN
                         dbo.Site WITH(NOLOCK) ON dbo.Address.AddressId = dbo.Site.AddressId INNER JOIN
                         dbo.Countries WITH(NOLOCK) ON dbo.Address.CountryId = dbo.Countries.countries_id INNER JOIN
                         dbo.Warehouse WITH(NOLOCK) ON dbo.Site.SiteId = dbo.Warehouse.SiteId LEFT JOIN
						 dbo.LegalEntity WITH(NOLOCK) ON dbo.Site.LegalEntityId=dbo.LegalEntity.LegalEntityId