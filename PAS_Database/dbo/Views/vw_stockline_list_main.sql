
CREATE VIEW [dbo].[vw_stockline_list_main]
AS
SELECT        dbo.Stockline.StockLineId, dbo.Stockline.PartNumber, dbo.ItemMaster.PartDescription, dbo.ItemType.Description AS ItemType, dbo.ItemGroup.Description AS ItemGroup, dbo.Stockline.StockLineNumber, 
                         dbo.Stockline.SerialNumber, dbo.Stockline.ConditionId, dbo.Condition.Description AS ConditionType, dbo.Stockline.Quantity, dbo.Stockline.GLAccountId, dbo.GLAccount.AccountCode, dbo.Stockline.QuantityOnHand, 
                         dbo.Stockline.QuantityAvailable, dbo.Stockline.isActive AS IsActive, dbo.Stockline.isDeleted AS IsDeleted
FROM            dbo.Stockline INNER JOIN
                         dbo.ItemMaster ON dbo.Stockline.ItemMasterId = dbo.ItemMaster.ItemMasterId INNER JOIN
                         dbo.ItemType ON dbo.ItemMaster.ItemTypeId = dbo.ItemType.ItemTypeId INNER JOIN
                         dbo.ItemGroup ON dbo.ItemMaster.ItemGroupId = dbo.ItemGroup.ItemGroupId INNER JOIN
                         dbo.Condition ON dbo.Stockline.ConditionId = dbo.Condition.ConditionId INNER JOIN
                         dbo.GLAccount ON dbo.Stockline.GLAccountId = dbo.GLAccount.GLAccountId
WHERE        (dbo.Stockline.isDeleted = 0)