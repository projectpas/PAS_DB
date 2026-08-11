
/*************************************************************
 ** File:   [AutoCompleteDropdownsItemMasterWithManufacturerAllTypes]
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is a Stock + Non-Stock variant of
					[AutoCompleteDropdownsItemMasterWithManufacturer], used ONLY by the Purchase
					Order "Add PN" / "Add Multiple PN" autocomplete so a single dropdown can surface
					BOTH Stock (ItemTypeId=1) and Non-Stock (ItemTypeId=2) rows from ItemMaster.
					This is a NEW, separate procedure so the existing
					[AutoCompleteDropdownsItemMasterWithManufacturer] (Stock-only, consumed by ~40
					other screens) is left completely untouched/unaffected.
 ** Purpose:
 ** Date:   15/July/2026

 ** PARAMETERS: @StartWith varchar(50)
 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
	1    15/July/2026  RAJESH GAMI		[PN-17271] - Created. Stock + Non-Stock unified variant of
										AutoCompleteDropdownsItemMasterWithManufacturer for the PO
										Setup "Add PN" / "Add Multiple PN" flows (ItemMasterNonStock
										has been merged into ItemMaster / IsNonStock flag). Adds
										ItemTypeId to the result set (1=Stock, 2=Non-Stock) so the
										Angular side can route to the correct detail-fetch API after
										selection, and suffixes the Label with ' (Stock)' /
										' (Non-Stock)' per the PN-17271 label convention. Restricted
										to ItemTypeId IN (1,2) only - Equipment/Asset item types are
										intentionally excluded (handled by the separate "Add Asset"
										button/flow). Also dropped the "AND ISNULL(rp.IsNonStock,0)=0"
										condition on the rp self-join (rp joins Im.ItemMasterId =
										rp.ItemMasterId - the SAME row as Im) - kept in the Stock-only
										source SP it was harmless there (Im is always Stock so rp is
										too), but here it would incorrectly null out RevisedPart for
										every Non-Stock row, since rp IS Im.
	2   05-Aug-2026   Bhargav Saliya    [PN-17562] Part Number search (Item Master dropdown): normalize dashes/slashes

--EXEC [AutoCompleteDropdownsItemMasterWithManufacturerAllTypes] '725',1,20,'',18
EXEC [AutoCompleteDropdownsItemMasterWithManufacturerAllTypes] '100',1,50,'',18
**************************************************************/
CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterWithManufacturerAllTypes]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON
 BEGIN TRY
  DECLARE @Sql NVARCHAR(MAX);

  IF(@IsActive = 1)
   BEGIN
     SELECT DISTINCT TOP 50
			  Im.ItemMasterId,
			  Im.ItemMasterId AS Value,
			  Im.partnumber AS PartNumber,
			  Im.ItemTypeId,
			  (im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId ) > 1 then ' - '+ M.[Name] ELSE '' END) + (CASE WHEN ISNULL(Im.IsNonStock,0) = 1 THEN ' (Non-Stock)' ELSE ' (Stock)' END)) AS Label,
			  Im.PartDescription,
			  Im.ItemClassificationId,
			  Im.ManufacturerId,
			  Im.GLAccountId,
			  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
			  uom.ShortName AS UnitOfMeasure,
			  Im.Figure,
			  Im.Item,
			  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),
			  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
				WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
				WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			  END AS StockType,
			  M.Name As Manufacturer,
			  isnull(rp. RevisedPart,'')  AS RevisedPart,
			  Im.isSerialized AS IsSerialized,
			  Im.isTimeLife AS IsTimeLife,
			  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
			  Ic.ItemClassificationCode as ItemClassification,
			  Im.SiteId,
			  Im.WarehouseId,
			  Im.LocationId,
			  Im.ShelfId,
			  Im.BinId,
			  Im.IsExpirationDateAvailable,
			  Ig.ItemGroupCode As ItemGroup
     FROM dbo.ItemMaster Im WITH(NOLOCK)
			  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId
			   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
			  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			  LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
     WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') LIKE REPLACE(REPLACE(REPLACE(REPLACE(@StartWith, '-', ''), '/', ''), '_', ''), '\', '') + '%'))
      UNION

     SELECT DISTINCT Im.ItemMasterId,
			  Im.ItemMasterId AS Value,
			  Im.partnumber AS PartNumber,
			  Im.ItemTypeId,
			  (im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) + (CASE WHEN ISNULL(Im.IsNonStock,0) = 1 THEN ' (Non-Stock)' ELSE ' (Stock)' END)) AS Label,
			  Im.PartDescription,
			  Im.ItemClassificationId,
			  Im.ManufacturerId,
			  Im.GLAccountId,
			  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
			  uom.ShortName AS UnitOfMeasure,
			  Im.Figure,
			  Im.Item,
			  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),
			  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
				WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
				WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			  END AS StockType,
			  M.Name As Manufacturer,
			  isnull(rp. RevisedPart, '')  AS RevisedPart,
			  Im.isSerialized AS IsSerialized,
			  Im.isTimeLife AS IsTimeLife,
			  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
			  Ic.ItemClassificationCode as ItemClassification,
			  Im.SiteId,
			  Im.WarehouseId,
			  Im.LocationId,
			  Im.ShelfId,
			  Im.BinId,
			  Im.IsExpirationDateAvailable,
			  Ig.ItemGroupCode As ItemGroup
     FROM dbo.ItemMaster Im WITH(NOLOCK)
			  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId
			   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
			  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			  LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
     WHERE im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
	  AND ISNULL(Im.IsDeleted,0) = 0 AND ISNULL(Im.IsActive,0) = 1
      ORDER BY Label
   End
   ELSE
   BEGIN
    SELECT DISTINCT TOP 50
			  Im.ItemMasterId,
			  Im.ItemMasterId AS Value,
			  Im.partnumber AS PartNumber,
			  Im.ItemTypeId,
			  (im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId ) > 1 then ' - '+ M.[Name] ELSE '' END) + (CASE WHEN ISNULL(Im.IsNonStock,0) = 1 THEN ' (Non-Stock)' ELSE ' (Stock)' END)) AS Label,
			  Im.PartDescription,
			  Im.ItemClassificationId,
			  Im.ManufacturerId,
			  Im.GLAccountId,
			  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
			  uom.ShortName AS UnitOfMeasure,
			  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),
			  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
				WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
				WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			  END AS StockType,
			  M.Name As Manufacturer,
			  isnull(rp. RevisedPart, '')  AS RevisedPart,
			  Im.isSerialized AS IsSerialized,
			  Im.isTimeLife AS IsTimeLife,
			  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
			  Ic.ItemClassificationCode as ItemClassification,
			  Im.SiteId,
			  Im.WarehouseId,
			  Im.LocationId,
			  Im.ShelfId,
			  Im.BinId,
			  Im.IsExpirationDateAvailable,
			  Ig.ItemGroupCode As ItemGroup
     FROM dbo.ItemMaster Im WITH(NOLOCK)
			LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
			LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId
			 LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
    WHERE Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') LIKE REPLACE(REPLACE(REPLACE(REPLACE(@StartWith, '-', ''), '/', ''), '_', ''), '\', '') + '%')
     UNION

    SELECT DISTINCT TOP 50
			  Im.ItemMasterId,
			  Im.ItemMasterId AS Value,
			  Im.partnumber AS PartNumber,
			  Im.ItemTypeId,
			  (im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) + (CASE WHEN ISNULL(Im.IsNonStock,0) = 1 THEN ' (Non-Stock)' ELSE ' (Stock)' END)) AS Label,
			  Im.PartDescription,
			  Im.ItemClassificationId,
			  Im.ManufacturerId,
			  Im.GLAccountId,
			  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
			  uom.ShortName AS UnitOfMeasure,
			  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),
			  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
				WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
				WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			  END AS StockType,
			  M.Name As Manufacturer,
			  isnull(rp. RevisedPart, '')  AS RevisedPart,
			  Im.isSerialized AS IsSerialized,
			  Im.isTimeLife AS IsTimeLife,
			  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
			  Ic.ItemClassificationCode as ItemClassification,
			  Im.SiteId,
			  Im.WarehouseId,
			  Im.LocationId,
			  Im.ShelfId,
			  Im.BinId,
			  Im.IsExpirationDateAvailable,
			  Ig.ItemGroupCode As ItemGroup
     FROM dbo.ItemMaster Im WITH(NOLOCK)
			  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId
			   LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
			  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			  LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
    WHERE Im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) AND ISNULL(Im.IsDeleted,0) = 0 AND ISNULL(Im.IsActive,0) = 1
     ORDER BY Label
   END
 END TRY
 BEGIN CATCH
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemMasterWithManufacturerAllTypes'
     ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
      + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100))
      + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))
      + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))
      + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
 END CATCH
END