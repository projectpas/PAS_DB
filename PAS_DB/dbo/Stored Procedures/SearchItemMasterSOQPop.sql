CREATE PROCEDURE [dbo].[SearchItemMasterSOQPop]
@ItemMasterIdlist VARCHAR(max) = '0', 
--@ConditionId BIGINT = NULL,
@ConditionIds VARCHAR(100) = NULL,
@CustomerId BIGINT = NULL,
@MappingType INT = -1

AS
BEGIN

	SELECT 
		im.PartNumber
		,im.ItemMasterId As PartId
		,im.ItemMasterId As ItemMasterId
		,im.PartDescription AS Description
		,SUM(ISNULL(sl.QuantityAvailable, 0)) AS QtyAvailable
		,SUM(ISNULL(sl.QuantityOnHand, 0)) AS QtyOnHand
		,ig.Description AS ItemGroup
		,mf.Name Manufacturer
		,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
		,ic.ItemClassificationCode
		,ic.Description AS ItemClassification
		,ic.ItemClassificationId
		,c.ConditionId ConditionId
		,c.Description ConditionDescription
		,ISNULL(STUFF((
        SELECT DISTINCT ', '+ I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M INNER JOIN ItemMaster I ON I.ItemMasterId = M.ItemMasterId Where M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1
        FOR XML PATH('')
        )
        ,1,1,''), '') AlternateFor
		,CASE 
			WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber --'PMA&DER'
			WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber --'PMA'
			WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END AS Oempmader
		,@MappingType AS MappingType
		,imps.PP_UnitPurchasePrice AS UnitCost
		,imps.SP_CalSPByPP_UnitSalePrice AS UnitSalePrice
	FROM DBO.ItemMaster im 
	LEFT JOIN DBO.Condition c ON c.ConditionId in (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,','))
	LEFT JOIN DBO.StockLine sl ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId = c.ConditionId 
		AND sl.IsDeleted = 0 
		--AND ((sl.ConditionId = CASE WHEN @ConditionIds = '' THEN @ConditionIds ELSE sl.ConditionId END)
		--	OR sl.ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,',')))
	LEFT JOIN DBO.PurchaseOrder po ON po.PurchaseOrderId = sl.PurchaseOrderId 
		AND sl.IsDeleted = 0
	LEFT JOIN DBO.PurchaseOrderPart pop ON po.PurchaseOrderId = pop.PurchaseOrderId 
		AND pop.ItemMasterId = im.ItemMasterId 
		AND pop.IsDeleted = 0
	LEFT JOIN DBO.ItemGroup ig ON im.ItemGroupId = ig.ItemGroupId
	LEFT JOIN DBO.Manufacturer mf ON im.ManufacturerId = mf.ManufacturerId
	LEFT JOIN DBO.ItemClassification ic ON im.ItemClassificationId = ic.ItemClassificationId
	LEFT JOIN (SELECT partnumber, ItemMasterId FROM DBO.ItemMaster) OEMPMA ON OEMPMA.ItemMasterId = im.IsOemPNId
	LEFT JOIN DBO.ItemMasterPurchaseSale imps on imps.ItemMasterId = im.ItemMasterId
				and imps.ConditionId = c.ConditionId
	WHERE 
		im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
		--AND (sl.ItemMasterId is null OR ((@ConditionIds = '' OR @ConditionIds IS NULL OR  sl.ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,',')))))
	GROUP BY
		im.PartNumber
		,im.ItemMasterId 
		,im.PartDescription
		,ig.Description 
		,mf.Name 
		,im.ManufacturerId
		,ic.ItemClassificationCode
		,ic.Description
		,ic.ItemClassificationId
		,c.Description
		,c.ConditionId
		--,CASE 
		--	WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
		--	WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
		--	WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
		--	ELSE 'OEM'
		--END 
		,im.IsPma
		,im.IsDER
		,OEMPMA.partnumber
		,sl.ItemMasterId
		,imps.PP_UnitPurchasePrice
		,imps.SP_CalSPByPP_UnitSalePrice
END