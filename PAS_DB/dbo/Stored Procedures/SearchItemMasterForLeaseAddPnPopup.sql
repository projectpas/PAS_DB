/*************************************************************
 ** File:   [SearchItemMasterForLeaseAddPnPopup]
 ** Description: Search Item Master details for the Lease "Add Item" popup - mirrors
 **              [SearchItemMasterByCustomerRestrictionForAddPN] (Work Order's Add PN popup).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    19/08/2026     Amit Ghediya            Created

EXECUTE [SearchItemMasterForLeaseAddPnPopup] '1636', '1', 1
************************************************************************/
CREATE    PROCEDURE [dbo].[SearchItemMasterForLeaseAddPnPopup]
	@ItemMasterIdlist VARCHAR(MAX) = '0',
	@ConditionIds VARCHAR(100) = NULL,
	@CustomerId BIGINT = NULL,
	@MappingType INT = -1
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

	BEGIN TRY
		SELECT DISTINCT
			im.PartNumber
			,im.ItemMasterId AS PartId
			,im.ItemMasterId AS ItemMasterId
			,im.PartDescription AS Description
			,im.PurchaseUnitOfMeasureId AS unitOfMeasureId
			,im.PurchaseUnitOfMeasure AS unitOfMeasure
			,im.IsPma
			,im.IsDER
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
				SELECT DISTINCT ', ' + I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M INNER JOIN ItemMaster I ON I.ItemMasterId = M.ItemMasterId
				WHERE M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1 AND M.IsActive = 1 AND M.IsDeleted = 0
				AND ISNULL(I.IsNonStock,0) = 0
				FOR XML PATH(''))
			,1,1,''), '') AlternateFor
			,CASE
				WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
				WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
				WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
				END AS Oempmader
			,@MappingType AS MappingType
			,ISNULL(imps.PP_UnitPurchasePrice, 0) AS UnitCost
			,ISNULL(imps.SP_CalSPByPP_UnitSalePrice, 0) AS UnitSalePrice
			,ISNULL(imps.PP_FXRatePerc, 0) AS FixRate
		FROM DBO.ItemMaster im WITH (NOLOCK)
		LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,','))
		LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId = c.ConditionId
			AND sl.IsDeleted = 0 AND sl.isActive = 1 AND sl.IsParent = 1 AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId)) AND ISNULL(sl.IsNonStock,0) = 0
		LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
		LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
		LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
		LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) ON imps.ItemMasterId = im.ItemMasterId
			AND imps.ConditionId = c.ConditionId
		WHERE
			im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
			AND ISNULL(im.IsNonStock,0) = 0
		GROUP BY
			im.PartNumber
			,im.PurchaseUnitOfMeasureId
			,im.PurchaseUnitOfMeasure
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
			,im.IsPma
			,im.IsDER
			,imps.PP_UnitPurchasePrice
			,imps.SP_CalSPByPP_UnitSalePrice
			,imps.PP_FXRatePerc
		ORDER BY 7 DESC
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[SearchItemMasterForLeaseAddPnPopup]',
            @ProcedureParameters varchar(3000) = '@ItemMasterIdlist = ''' + ISNULL(@ItemMasterIdlist, ''),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END