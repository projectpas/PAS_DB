
CREATE VIEW [dbo].[vw_itemmaster_list_main]
AS
SELECT        dbo.ItemMaster.ItemMasterId, dbo.ItemMaster.NationalStockNumber, dbo.ItemMaster.partnumber AS PartNumber, dbo.ItemMaster.PartDescription, dbo.ItemMaster.isTimeLife AS IsTimeLife, 
                         dbo.ItemMaster.isSerialized AS IsSerialized, dbo.ItemMaster.ItemGroupId, dbo.ItemMaster.ItemClassificationId, dbo.ItemClassification.ItemClassificationCode, dbo.ItemGroup.Description AS ItemGroup, dbo.ItemMaster.IsActive, 
                         dbo.Manufacturer.Name AS Manufacturer, dbo.ItemMaster.ItemTypeId, dbo.ItemMaster.UnitCost, dbo.ItemMaster.ListPrice, dbo.ItemMaster.IsHazardousMaterial
FROM            dbo.ItemMaster INNER JOIN
                         dbo.ItemClassification ON dbo.ItemMaster.ItemClassificationId = dbo.ItemClassification.ItemClassificationId INNER JOIN
                         dbo.ItemGroup ON dbo.ItemMaster.ItemGroupId = dbo.ItemGroup.ItemGroupId INNER JOIN
                         dbo.Manufacturer ON dbo.ItemMaster.ManufacturerId = dbo.Manufacturer.ManufacturerId
WHERE        (dbo.ItemMaster.IsDeleted = 0)