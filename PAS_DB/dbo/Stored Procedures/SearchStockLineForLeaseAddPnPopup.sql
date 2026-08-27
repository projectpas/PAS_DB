/*************************************************************
 ** File:   [SearchStockLineForLeaseAddPnPopup]
 ** Description: Search Stock Line details for the Lease "Add Item" popup - mirrors
 **              [SearchStockLineForAddPN] (Work Order's Add PN popup), minus the
 **              already-staged @StocklineIdlist carry-forward, which Lease's Add
 **              Item flow doesn't need.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    19/08/2026     Amit Ghediya            Created
    2    25/08/2026     Amit Ghediya            Added TracableToName/OwnerName/ObtainFromName (StockLine columns) - were missing, showed blank in the Add Item popup

EXECUTE [SearchStockLineForLeaseAddPnPopup] '1636', 1, 1
************************************************************************/
CREATE    PROCEDURE [dbo].[SearchStockLineForLeaseAddPnPopup]
	@ItemMasterIdlist VARCHAR(MAX) = '0',
	@ConditionId BIGINT = NULL,
	@CustomerId BIGINT = NULL,
	@MappingType INT = -1
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @AlternatePartNumber VARCHAR(250);

		SELECT @AlternatePartNumber = STRING_AGG(Im.partnumber, ',')
		FROM [DBO].[Nha_Tla_Alt_Equ_ItemMapping] IMM
			JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON IMM.ItemMasterId = IM.ItemMasterId
		WHERE MappingItemMasterId = @ItemMasterIdlist AND IMM.MappingType IN (1,2) AND IMM.IsActive = 1 AND IMM.IsDeleted = 0;

		SELECT DISTINCT
			im.PartNumber
			,sl.StockLineId
			,im.ItemMasterId AS PartId
			,im.ItemMasterId AS ItemMasterId
			,im.PartDescription AS Description
			,sl.PurchaseUnitOfMeasureId AS unitOfMeasureId
			,suom.Description AS unitOfMeasure
			,ig.Description AS ItemGroup
			,mf.Name AS Manufacturer
			,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
			,ic.ItemClassificationCode
			,ic.Description AS ItemClassification
			,ic.ItemClassificationId
			,c.Description ConditionDescription
			,c.ConditionId
			,ISNULL(@AlternatePartNumber,'') AlternateFor
			,CASE
				WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
				WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
				WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
				END AS StockType
			,@MappingType AS MappingType
			,sl.StockLineNumber
			,sl.SerialNumber
			,sl.ControlNumber
			,sl.IdNumber
			,uom.ShortName AS UomDescription
			,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
			,ISNULL(sl.UnitCost, 0) AS unitCost
			,ISNULL(sl.UnitSalesPrice, 0) AS unitSalePrice
			,sl.TraceableToName AS TracableToName
			,sl.OwnerName AS OwnerName
			,sl.ObtainFromName AS ObtainFromName
			,'Stock Line' AS Method
			,'S' AS MethodType
			,CONVERT(BIT,0) AS PMA
			,mf.Name AS StkLineManufacturer
			,ISNULL(imps.PP_FXRatePerc, 0) AS FixRate
			,ISNULL(sl.CustomerId, 0) AS CustomerId
			,sl.IsCustomerStock
			,cus.Name AS CustomerName
		FROM DBO.ItemMaster im WITH(NOLOCK)
			JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId
				AND sl.isActive = 1 AND sl.IsDeleted = 0
				AND sl.ConditionId = CASE WHEN @ConditionId IS NOT NULL THEN @ConditionId ELSE sl.ConditionId END
			LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
			LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
			LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId
			LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
			LEFT JOIN DBO.UnitOfMeasure uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			LEFT JOIN DBO.UnitOfMeasure suom WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = suom.UnitOfMeasureId
			LEFT JOIN DBO.Customer cus WITH(NOLOCK) ON sl.CustomerId = cus.CustomerId
			LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) ON imps.ItemMasterId = im.ItemMasterId
				AND imps.ConditionId = c.ConditionId
		WHERE
			im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
			AND ISNULL(sl.QuantityAvailable, 0) > 0
			AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
			AND sl.IsParent = 1
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[SearchStockLineForLeaseAddPnPopup]',
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