
-- ---------------------------------------------------------------------------------------------------
-- View: dbo.vw_ItemMasterPartManufacturer   (source: PAS_DB/dbo/Views/vw_ItemMasterPartManufacturer.sql)
-- ---------------------------------------------------------------------------------------------------

CREATE   VIEW dbo.vw_ItemMasterPartManufacturer
AS

WITH PartCounts AS
(
    SELECT
        PartNumber,
        COUNT(*) AS PartCount
    FROM dbo.ItemMaster
     WHERE ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
GROUP BY PartNumber
)

SELECT
    IM.*,

    CASE
        WHEN PC.PartCount > 1
            THEN CONCAT(IM.PartNumber, ' - ', IM.ManufacturerName)
        ELSE IM.PartNumber
    END AS PartManufacture

FROM dbo.ItemMaster IM
INNER JOIN PartCounts PC
    ON IM.PartNumber = PC.PartNumber WHERE ISNULL(IM.IsNonStock,0) = 0
;