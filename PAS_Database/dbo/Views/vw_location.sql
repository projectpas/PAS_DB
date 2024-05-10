
CREATE VIEW [dbo].[vw_location]
AS
SELECT        dbo.Address.Line1, dbo.Address.Line2, dbo.Address.Line3, dbo.Address.City, dbo.Address.StateOrProvince, dbo.Address.PostalCode, dbo.Countries.nice_name AS Country, dbo.Site.Name AS Site,dbo.Site.Name AS SiteName,  
                         dbo.Warehouse.Name AS Warehouse, dbo.Location.LocationId, dbo.Location.Name, dbo.Location.Memo, dbo.Location.CreatedBy, dbo.Location.UpdatedBy, dbo.Location.CreatedDate, dbo.Location.UpdatedDate, 
                         dbo.Location.IsActive, dbo.Location.IsDeleted,dbo.Location.MasterCompanyId, dbo.Warehouse.WarehouseId, dbo.Site.SiteId,ISNULL(dbo.LegalEntity.Name,'') AS LegalEntity
FROM            dbo.Address WITH(NOLOCK) INNER JOIN
                         dbo.Site WITH(NOLOCK) ON dbo.Address.AddressId = dbo.Site.AddressId INNER JOIN
                         dbo.Location WITH(NOLOCK) INNER JOIN
                         dbo.Warehouse WITH(NOLOCK) ON dbo.Location.WarehouseId = dbo.Warehouse.WarehouseId ON dbo.Site.SiteId = dbo.Warehouse.SiteId INNER JOIN
                         dbo.Countries WITH(NOLOCK) ON dbo.Address.CountryId = dbo.Countries.countries_id LEFT JOIN 
						 dbo.LegalEntity WITH(NOLOCK) ON dbo.Site.LegalEntityId=dbo.LegalEntity.LegalEntityId