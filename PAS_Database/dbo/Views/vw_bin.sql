CREATE VIEW [dbo].[vw_bin]
AS
SELECT        dbo.Countries.nice_name AS Country, dbo.Address.Line1, dbo.Address.Line2, dbo.Address.Line3, dbo.Address.City, dbo.Address.StateOrProvince, dbo.Address.PostalCode, dbo.Site.Name AS Site, dbo.Site.Name AS SiteName,  
                         dbo.Warehouse.Name AS Warehouse, dbo.Location.Name AS Location, dbo.Shelf.Name AS Shelf, dbo.Bin.BinId, dbo.Bin.Name, dbo.Bin.Memo, dbo.Bin.MasterCompanyId, dbo.Bin.CreatedBy, dbo.Bin.UpdatedBy, 
                         dbo.Bin.CreatedDate, dbo.Bin.UpdatedDate, dbo.Bin.IsActive, dbo.Bin.IsDeleted, dbo.Site.SiteId, dbo.Shelf.ShelfId, dbo.Location.LocationId, dbo.Warehouse.WarehouseId,ISNULL(dbo.LegalEntity.Name,'') AS LegalEntity
FROM            dbo.Address WITH(NOLOCK) INNER JOIN
                         dbo.Site WITH(NOLOCK) ON dbo.Address.AddressId = dbo.Site.AddressId INNER JOIN
                         dbo.Countries WITH(NOLOCK) ON dbo.Address.CountryId = dbo.Countries.countries_id INNER JOIN
                         dbo.Bin WITH(NOLOCK) INNER JOIN
                         dbo.Shelf WITH(NOLOCK) ON dbo.Bin.ShelfId = dbo.Shelf.ShelfId INNER JOIN
                         dbo.Location WITH(NOLOCK) ON dbo.Shelf.LocationId = dbo.Location.LocationId INNER JOIN
                         dbo.Warehouse WITH(NOLOCK) ON dbo.Location.WarehouseId = dbo.Warehouse.WarehouseId ON dbo.Site.SiteId = dbo.Warehouse.SiteId LEFT JOIN 
						  dbo.LegalEntity WITH(NOLOCK) ON dbo.Site.LegalEntityId=dbo.LegalEntity.LegalEntityId