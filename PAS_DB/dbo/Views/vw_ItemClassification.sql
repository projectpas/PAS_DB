
CREATE VIEW [dbo].[vw_ItemClassification]
AS
SELECT IC.*,IT.Name AS ItemType FROM ItemClassification IC
INNER JOIN ItemType IT ON IC.ItemTypeId=IT.ItemTypeId