-- ===== PROCEDURE: [dbo].[USP_Lot_GetPartsForOtherCostAdd]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_Lot_GetPartsForOtherCostAdd.sql) =====

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
 ** Date:   02-Sep-2026 (updated 03-Sep-2026)
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
**************************************************************
 EXEC USP_Lot_GetPartsForOtherCostAdd 1,1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetPartsForOtherCostAdd]
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
			im.ManufacturerName AS 'ManufacturerName'
		FROM [dbo].[LotTransInOutDetails] lin  WITH (NOLOCK)
		-- [PN-17853] 03-Sep-2026: only parts actually SOLD off this Lot (Sales Activity tab) are eligible
		INNER JOIN [dbo].[LotCalculationDetails] ltCal WITH (NOLOCK) ON lin.LotTransInOutId = ltCal.LotTransInOutId
			AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))
		INNER JOIN [dbo].[Stockline] stk WITH (NOLOCK) ON lin.StockLineId = stk.StockLineId
		INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stk.ItemMasterId = im.ItemMasterId
		WHERE lin.LotId = @LotId AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(stk.IsNonStock,0) = 0
		AND stk.MasterCompanyId = @MasterCompanyId
		ORDER BY im.PartNumber;

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