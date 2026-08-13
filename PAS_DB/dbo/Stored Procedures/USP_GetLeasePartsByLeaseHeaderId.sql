/*************************************************************
 ** File:   [USP_GetLeasePartsByLeaseHeaderId]
 ** Description: Returns the flat Part+StockLine list for a Lease, grouped client-side by Angular.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked for denormalized PN/PNDescription schema
    3    10/08/2026     Amit Ghediya            Added ManufacturerName (joined from ItemMaster, display-only)

exec USP_GetLeasePartsByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePartsByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@LeasePartId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT
			LP.LeasePartId,
			LP.LeaseHeaderId,
			LP.ItemMasterId,
			LP.PN,
			LP.PNDescription,
			LP.UOM,
			IM.ManufacturerName,
			LP.QtyRequested,
			LP.QtyOrder,
			LP.QtyReserved,
			LP.ConditionId,
			C.Description AS ConditionDescription,
			LP.OEMPMA,
			LP.AircraftSectionId,
			ACS.Section AS AcSection,
			LP.StartDate,
			LP.EndDate,
			LP.POId,
			LP.PONumber,
			LP.StatusId,

			LSL.LeaseStocklineId,
			LSL.StockLineId,
			LSL.PNDescription AS StockLinePNDescription,
			LSL.QtyOrder AS StockLineQtyOrder,
			LSL.QtyReserved AS StockLineQtyReserved,
			LSL.QtyAvailable,
			LSL.QtyOH,
			LSL.SN,
			LSL.StocklineNumber,
			LSL.ConditionId AS StockLineConditionId,
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

			LP.MasterCompanyId,
			LP.CreatedBy,
			LP.UpdatedBy,
			LP.CreatedDate,
			LP.UpdatedDate,
			LP.IsActive,
			LP.IsDeleted
		FROM [dbo].[LeasePart] LP WITH (NOLOCK)
		LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = LP.ItemMasterId
		LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.ConditionId = LP.ConditionId
		LEFT JOIN [dbo].[AircraftSection] ACS WITH (NOLOCK) ON ACS.AircraftSectionId = LP.AircraftSectionId
		LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeasePartId = LP.LeasePartId AND LSL.IsDeleted = 0
		WHERE LP.LeaseHeaderId = @LeaseHeaderId
		  AND LP.IsDeleted = 0
		  AND (ISNULL(@LeasePartId, 0) = 0 OR LP.LeasePartId = @LeasePartId)
		ORDER BY LP.LeasePartId, LSL.LeaseStocklineId;

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