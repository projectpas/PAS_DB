CREATE VIEW [dbo].[vw_mpn_list]
AS
SELECT        dbo.MasterParts.MasterPartId, dbo.MasterParts.PartNumber, dbo.MasterParts.Description, dbo.ItemMaster.ItemGroupId, dbo.ItemMaster.IsDER, dbo.ItemMaster.IsPma, dbo.ItemMaster.RevisedPartId, 
                         ItemMaster_1.PartDescription AS revised_mpn, dbo.ItemGroup.Description AS item_group
FROM            dbo.MasterParts INNER JOIN
                         dbo.ItemMaster ON dbo.MasterParts.MasterPartId = dbo.ItemMaster.MasterPartId INNER JOIN
                         dbo.ItemGroup ON dbo.ItemMaster.ItemGroupId = dbo.ItemGroup.ItemGroupId LEFT OUTER JOIN
                         dbo.ItemMaster AS ItemMaster_1 ON dbo.ItemMaster.RevisedPartId = ItemMaster_1.ItemMasterId