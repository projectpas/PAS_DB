-- ===== PROCEDURE: [dbo].[USP_Lot_GetPartsForOtherCostAdd]   (file: _PAS_DB/PAS_Database/dbo/Stored Procedures/USP_Lot_GetPartsForOtherCostAdd.sql) =====

/*************************************************************
 ** File:   [USP_Lot_GetPartsForOtherCostAdd]
 ** Author: RAJESH GAMI
 ** Description: [PN-17853] Returns the distinct Part Numbers eligible for the Other Cost tab's Add-manual-
 **              entry popup's Part Number dropdown. As of 03-Sep-2026 (Rajesh) this is restricted to parts
 **              that have actually been SOLD off this Lot on a Sales Order (i.e. appear in the Sales Activity
 **              tab / LotCalculationDetails Type = 'Trans Out(SO)'), not just any part mapped to the Lot via
 **              LotTransInOutDetails - a manual Other Cost entry only makes sense against a sold SO part now.
 **              If the Lot has no sold parts, this returns zero rows and the Angular popup's "NA" option
 **              (added client-side, not by this SP) is the only choice left in the dropdown.
 **              [PN-18032] 23-Sep-2026: also UNIONs in Non-Stock Serviceable parts (ItemMaster.IsNonStock=1
 **              AND ItemMaster.IsService=1), scoped to @MasterCompanyId only (not tied to this Lot's sold
 **              stocklines, since a Non-Stock Service item never has a Stockline). IsNonStock (0/1) flags
 **              which branch a row came from, result ORDER BY IsNonStock, PartNumber so the Angular dropdown
 **              lists Sold parts first, Non-Stock Service parts last ("NA" stays a client-side-only prepend).
 ** Date:   02-Sep-2026 (updated 03-Sep-2026, 23-Sep-2026)
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author        Change Description
 ** --   --------     -------       ---------------------------
    1    02-Sep-2026  RAJESH GAMI   [PN-17853] Created
    2    03-Sep-2026  RAJESH GAMI   [PN-17853] Restricted to SOLD (Trans Out(SO)) parts only, per Rajesh -
                                    Other Cost Add is now scoped to the Sales Activity tab's parts
    3    23-Sep-2026  RAJESH GAMI   [PN-18032] Added a 2nd branch (UNION ALL) for Non-Stock Serviceable
                                    parts (ItemMaster.IsNonStock=1 AND ItemMaster.IsService=1), so they can
                                    also be picked on the Other Cost Add popup's Part Number dropdown, per
                                    Rajesh. Added IsNonStock (0/1) to the result so the Angular popup knows
                                    to disable Stockline Number and not require Memo for these rows (same
                                    Stockline-not-applicable treatment as "NA", but Memo stays optional -
                                    only NA requires it). Result now ORDER BY IsNonStock, PartNumber so
                                    Sold parts list first and Non-Stock Service parts list last.
**************************************************************
 EXEC USP_Lot_GetPartsForOtherCostAdd 1,1
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_Lot_GetPartsForOtherCostAdd]
@LotId BIGINT = 0,
@MasterCompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN

		SELECT
			DISTINCT
			im.ItemMasterId AS 'ItemMasterId',
			im.PartNumber AS 'PartNumber',
			im.PartDescription AS 'PartDescription',
			im.ManufacturerId AS 'ManufacturerId',
			im.ManufacturerName AS 'ManufacturerName',
			CAST(0 AS BIT) AS 'IsNonStock' -- [PN-18032]
		FROM [dbo].[LotTransInOutDetails] lin  WITH (NOLOCK)
		-- [PN-17853] 03-Sep-2026: only parts actually SOLD off this Lot (Sales Activity tab) are eligible
		INNER JOIN [dbo].[LotCalculationDetails] ltCal WITH (NOLOCK) ON lin.LotTransInOutId = ltCal.LotTransInOutId
			AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))
		INNER JOIN [dbo].[Stockline] stk WITH (NOLOCK) ON lin.StockLineId = stk.StockLineId
		INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stk.ItemMasterId = im.ItemMasterId
		WHERE lin.LotId = @LotId AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(stk.IsNonStock,0) = 0
		AND stk.MasterCompanyId = @MasterCompanyId

		UNION ALL

		-- [PN-18032] 23-Sep-2026: Non-Stock Serviceable parts (ItemMaster.IsNonStock=1 AND IsService=1) -
		-- not tied to this Lot's sold stocklines at all (a Non-Stock Service item never has a Stockline),
		-- just scoped to the company, active, not deleted (Rajesh, 23-Sep-2026).
		SELECT
			DISTINCT
			im2.ItemMasterId AS 'ItemMasterId',
			im2.PartNumber AS 'PartNumber',
			im2.PartDescription AS 'PartDescription',
			im2.ManufacturerId AS 'ManufacturerId',
			im2.ManufacturerName AS 'ManufacturerName',
			CAST(1 AS BIT) AS 'IsNonStock'
		FROM [dbo].[ItemMaster] im2 WITH (NOLOCK)
		WHERE im2.MasterCompanyId = @MasterCompanyId
		AND ISNULL(im2.IsNonStock,0) = 1 AND ISNULL(im2.IsService,0) = 1
		AND ISNULL(im2.IsActive,1) = 1 AND ISNULL(im2.IsDeleted,0) = 0

		ORDER BY IsNonStock, PartNumber;

	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetPartsForOtherCostAdd]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END