
CREATE VIEW [dbo].[vw_bin]
AS
SELECT        dbo.Countries.nice_name AS Country, dbo.Address.Line1, dbo.Address.Line2, dbo.Address.Line3, dbo.Address.City, dbo.Address.StateOrProvince, dbo.Address.PostalCode, dbo.Site.Name AS Site, 
                         dbo.Warehouse.Name AS Warehouse, dbo.Location.Name AS Location, dbo.Shelf.Name AS Shelf, dbo.Bin.BinId, dbo.Bin.Name, dbo.Bin.Memo, dbo.Bin.MasterCompanyId, dbo.Bin.CreatedBy, dbo.Bin.UpdatedBy, 
                         dbo.Bin.CreatedDate, dbo.Bin.UpdatedDate, dbo.Bin.IsActive, dbo.Bin.IsDeleted, dbo.Site.SiteId, dbo.Shelf.ShelfId, dbo.Location.LocationId, dbo.Warehouse.WarehouseId,ISNULL(dbo.LegalEntity.Name,'') AS LegalEntity
FROM            dbo.Address INNER JOIN
                         dbo.Site ON dbo.Address.AddressId = dbo.Site.AddressId INNER JOIN
                         dbo.Countries ON dbo.Address.CountryId = dbo.Countries.countries_id INNER JOIN
                         dbo.Bin INNER JOIN
                         dbo.Shelf ON dbo.Bin.ShelfId = dbo.Shelf.ShelfId INNER JOIN
                         dbo.Location ON dbo.Shelf.LocationId = dbo.Location.LocationId INNER JOIN
                         dbo.Warehouse ON dbo.Location.WarehouseId = dbo.Warehouse.WarehouseId ON dbo.Site.SiteId = dbo.Warehouse.SiteId LEFT JOIN 
						  dbo.LegalEntity ON dbo.Site.LegalEntityId=dbo.LegalEntity.LegalEntityId