
CREATE VIEW [dbo].[vw_shelf]
AS
SELECT        dbo.Address.Line1, dbo.Address.Line2, dbo.Address.Line3, dbo.Address.City, dbo.Address.StateOrProvince, dbo.Address.PostalCode, dbo.Countries.nice_name AS Country, dbo.Site.Name AS Site, 
                         dbo.Warehouse.Name AS Warehouse, dbo.Shelf.ShelfId, dbo.Shelf.Name, dbo.Location.Name AS Location, dbo.Shelf.Memo, dbo.Shelf.MasterCompanyId, dbo.Shelf.CreatedBy, dbo.Shelf.UpdatedBy, dbo.Shelf.CreatedDate, 
                         dbo.Shelf.UpdatedDate, dbo.Shelf.IsActive, dbo.Shelf.IsDeleted, dbo.Site.SiteId, dbo.Location.LocationId, dbo.Warehouse.WarehouseId,ISNULL(dbo.LegalEntity.Name,'') AS LegalEntity
FROM            dbo.Address INNER JOIN
                         dbo.Site ON dbo.Address.AddressId = dbo.Site.AddressId INNER JOIN
                         dbo.Location INNER JOIN
                         dbo.Warehouse ON dbo.Location.WarehouseId = dbo.Warehouse.WarehouseId ON dbo.Site.SiteId = dbo.Warehouse.SiteId INNER JOIN
                         dbo.Countries ON dbo.Address.CountryId = dbo.Countries.countries_id INNER JOIN
                         dbo.Shelf ON dbo.Location.LocationId = dbo.Shelf.LocationId  LEFT JOIN 
						  dbo.LegalEntity ON dbo.Site.LegalEntityId=dbo.LegalEntity.LegalEntityId