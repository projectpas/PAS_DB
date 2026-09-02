/*************************************************************
 ** File:   [USP_GetLeasePartsByLeaseHeaderId]
 ** Description: Returns the flat LeaseStockline list for a Lease (one row = one saved Add Item line).
 **              Name kept for historical/call-site continuity even though LeasePart is no longer involved.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked for denormalized PN/PNDescription schema
    3    10/08/2026     Amit Ghediya            Added ManufacturerName (joined from ItemMaster, display-only)
    4    18/08/2026     Amit Ghediya            Added OEMPMA (derived from ItemMaster.IsPma/IsOEM, LeasePart has no such column)
    5    20/08/2026     Amit Ghediya            Added StockLineStartDate/StockLineEndDate (LeaseStockline.StartDate/EndDate)
    6    21/08/2026     Amit Ghediya            LeaseStockline is now the primary Lease entity - rewritten to select directly from
                                                 LeaseStockline (no more LeasePart join/Part-vs-Stockline duplicate columns);
                                                 QtyAvailable/QtyOH now read live from Stockline instead of a stored snapshot;
                                                 added Notes/ReservedBy/UnReservedBy
    7    25/08/2026     Amit Ghediya            SerialNumber now reads live from Stockline (LeaseStockline.SN was never
                                                 populated by the Add Item save flow, always blank); added ControlNumber,
                                                 also live from Stockline (LeaseStockline has no such column at all)
    8    26/08/2026     Amit Ghediya            Added UnitCost, live from Stockline (for the Edit Item popup's Qty/Qty
                                                 OH/Qty Avail/Unit Cost/Ext Cost row)

exec USP_GetLeasePartsByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePartsByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT
			LSL.LeaseStocklineId,
			LSL.LeaseHeaderId,
			LSL.ItemMasterId,
			LSL.PN,
			LSL.PNDescription,
			IM.ManufacturerName,
			CASE WHEN IM.IsPma = 1 THEN 'PMA' WHEN IM.IsOEM = 1 THEN 'OEM' ELSE '' END AS OEMPMA,
			LSL.QtyOrder,
			LSL.QtyReserved,
			LSL.ConditionId,
			C.Description AS ConditionDescription,
			LSL.StartDate,
			LSL.EndDate,
			LSL.StockLineId,
			SLIVE.QuantityAvailable AS QtyAvailable,
			SLIVE.QuantityOnHand AS QtyOH,
			SLIVE.SerialNumber,
			SLIVE.ControlNumber,
			SLIVE.UnitCost,
			LSL.StocklineNumber,
			LSL.OutrightPrice,
			LSL.FlatRate,
			LSL.PricingMethod,
			LSL.RateUnit,
			LSL.BillingInterval,
			LSL.BillingMethod,
			LSL.MinimumCycles,
			LSL.MinimumTimes,
			LSL.MaximumCycles,
			LSL.MaximumTimes,
			LSL.UsagePerUnitCycles,
			LSL.UsagePerUnitTimes,
			LSL.OverrunPerUnitCycles,
			LSL.OverrunPerUnitTimes,
			LSL.Maintenance,
			LSL.MaintenancePer,
			LSL.Insurance,
			LSL.InsurancePer,
			LSL.Taxes,
			LSL.TaxesPer,
			LSL.RepairOrderId,
			LSL.RONumber,
			LSL.WorkOrderId,
			LSL.WorkOrderNo,
			LSL.Notes,
			LSL.ReservedBy,
			LSL.UnReservedBy,
			LSL.MasterCompanyId,
			LSL.CreatedBy,
			LSL.UpdatedBy,
			LSL.CreatedDate,
			LSL.UpdatedDate,
			LSL.IsActive,
			LSL.IsDeleted
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = LSL.ItemMasterId
		LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.ConditionId = LSL.ConditionId
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
		  AND (ISNULL(@LeaseStocklineId, 0) = 0 OR LSL.LeaseStocklineId = @LeaseStocklineId)
		ORDER BY LSL.LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeasePartsByLeaseHeaderId]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
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