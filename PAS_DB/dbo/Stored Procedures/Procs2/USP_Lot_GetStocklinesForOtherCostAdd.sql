-- ===== PROCEDURE: [dbo].[USP_Lot_GetStocklinesForOtherCostAdd]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_Lot_GetStocklinesForOtherCostAdd.sql) =====

/*************************************************************
 ** File:   [USP_Lot_GetStocklinesForOtherCostAdd]
 ** Author: RAJESH GAMI
 ** Description: [PN-17853] Returns the Stocklines eligible for the Other Cost tab's Add-manual-entry
 **              popup's Stockline Number dropdown (displayed to the user as "StocklineNumber-Condition"),
 **              scoped to a Lot AND a specific Part (ItemMasterId). As of 03-Sep-2026 (Rajesh) this is
 **              restricted to Stocklines actually SOLD off this Lot on a Sales Order (Sales Activity tab /
 **              LotCalculationDetails Type = 'Trans Out(SO)'), matching the same restriction now applied to
 **              USP_Lot_GetPartsForOtherCostAdd's Part Number dropdown. Also returns
 **              FreightAdjustment/MiscAdjustment so the UI can auto-populate Reconciled Freight/Reconciled
 **              Charges once a Stockline is selected.
 ** Date:   02-Sep-2026 (updated 03-Sep-2026)
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author        Change Description
 ** --   --------     -------       ---------------------------
    1    02-Sep-2026  RAJESH GAMI   [PN-17853] Created
    2    03-Sep-2026  RAJESH GAMI   [PN-17853] Restricted to SOLD (Trans Out(SO)) stocklines only, per Rajesh
**************************************************************
 EXEC USP_Lot_GetStocklinesForOtherCostAdd 1,1,1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetStocklinesForOtherCostAdd]
@LotId BIGINT = 0,
@ItemMasterId BIGINT = 0,
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
			stk.StockLineId AS 'StocklineId',
			stk.StockLineNumber AS 'StocklineNumber',
			stk.ConditionId AS 'ConditionId',
			ISNULL(c.Description, stk.Condition) AS 'Condition',
			ISNULL(stk.FreightAdjustment,0) AS 'ReconciledFreight',
			ISNULL(stk.MiscAdjustment,0) AS 'ReconciledCharges'
		FROM [dbo].[LotTransInOutDetails] lin  WITH (NOLOCK)
		-- [PN-17853] 03-Sep-2026: only stocklines actually SOLD off this Lot (Sales Activity tab) are eligible
		INNER JOIN [dbo].[LotCalculationDetails] ltCal WITH (NOLOCK) ON lin.LotTransInOutId = ltCal.LotTransInOutId
			AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))
		INNER JOIN [dbo].[Stockline] stk WITH (NOLOCK) ON lin.StockLineId = stk.StockLineId
		LEFT JOIN [dbo].[Condition] c WITH (NOLOCK) ON c.ConditionId = stk.ConditionId
		WHERE lin.LotId = @LotId AND stk.ItemMasterId = @ItemMasterId
		AND stk.MasterCompanyId = @MasterCompanyId
		ORDER BY stk.StockLineNumber;

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
            ,@AdhocComments varchar(150) = '[USP_Lot_GetStocklinesForOtherCostAdd]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)) + ''', @ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)),
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