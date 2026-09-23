/*************************************************************
 ** File:   [USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId]
 ** Description: Returns the reserved-only LeaseStockline list for the "Usage Info"
 **              tab (only stocklines with QtyReserved > 0 are eligible for usage
 **              tracking). Mirrors the join shape of USP_GetLeasePartsByLeaseHeaderId
 **              but returns a narrow column subset plus a HasUsageInfo flag (same
 **              precedent as HasServiceComponent on the Add Item grid).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    15/09/2026     Amit Ghediya            Created
    2    15/09/2026     Amit Ghediya            Added LatestNotes (from LeaseStocklineUsage, via the same join already used for HasUsageInfo) so the most recent note is available to show on this list if a FieldMaster column is added later
    3    16/09/2026     Kishor Makwana         [PN-17933] LeaseStocklineUsage.LatestNotes was split into LatestTimeNotes/ LatestCycleNotes (Time and Cycle are now independent) - aliased LatestTimeNotes back to LatestNotes so this proc's result shape (and the C# DTO it feeds) is unchanged
    4    16/09/2026     Kishor Makwana         [PN-17933] Added LSL.IsActive so the Usage Info list can tell the UI which rows are an active lease component (usage can only be recorded against one) instead of relying on the LeaseHeader's overall status, which is the wrong granularity for this check
    5    16/09/2026     Kishor Makwana         [PN-17933] Added LSL.LeaseStatusId - the "Add Usage Information" enable/disable check was still using the Lease Header's LeaseStatusId (wrong granularity); it needs each line's OWN LeaseStatusId (Draft/Active/ Closed - the same value shown in the "Status" column on the Add Item tab)
    6    17/09/2026     Kishor Makwana		   [PN-17967] LeaseStocklineUsage.LatestTimeNotes was dropped and LatestCycleNotes was renamed to Notes (the entry form now has a single shared Notes field instead of separate Time/Cycle notes) - re-pointed the LatestNotes alias at U.Notes so this proc's result shape (and the C# DTO it feeds) stays unchanged
	7    22/09/2026     Kishor Makwana         [PN-17949] Added Time/TimeReportedDate/TimeFromDate/TimeToDate/Cycle/CycleReportedDate/CycleFromDate/CycleToDate (the full LeaseStocklineUsage snapshot, via the same join already used for HasUsageInfo/LatestNotes) so the same values already shown in the Usage Information entry popup (Last Time/Cycle Reported + Record Time/Cycle period) can also be shown as columns on this list - column names match the FieldsMaster rows already registered by the requester for ModuleId=188

exec USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT
			LSL.LeaseStocklineId,
			LSL.PN AS PartNumber,
			LSL.PNDescription AS PartDescription,
			IM.ManufacturerName,
			C.Description AS ConditionDescription,
			LSL.StocklineNumber AS StockLineNumber,
			SLIVE.ControlNumber,
			SLIVE.SerialNumber,
			LSL.BillingMethod,
			LSL.BillingInterval,
			U.Notes AS LatestNotes,
			CASE WHEN U.LeaseStocklineUsageId IS NOT NULL
				 THEN ISNULL(U.CurrentTSNHours, 0) * 60 + ISNULL(U.CurrentTSNMinutes, 0)
				 ELSE NULL END AS Time,
			U.CurrentTSNDate AS TimeReportedDate,
			U.CurrentTSNFromDate AS TimeFromDate,
			U.CurrentTSNToDate AS TimeToDate,
			U.CurrentCSN AS Cycle,
			U.CurrentCSNDate AS CycleReportedDate,
			U.CurrentCSNFromDate AS CycleFromDate,
			U.CurrentCSNToDate AS CycleToDate,
			CASE WHEN U.LeaseStocklineUsageId IS NOT NULL THEN 1 ELSE 0 END AS HasUsageInfo,
			LSL.IsActive,
			LSL.LeaseStatusId
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = LSL.ItemMasterId
		LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.ConditionId = LSL.ConditionId
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		LEFT JOIN [dbo].[LeaseStocklineUsage] U WITH (NOLOCK) ON U.LeaseStocklineId = LSL.LeaseStocklineId AND U.IsDeleted = 0
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
		  AND LSL.QtyReserved > 0
		ORDER BY LSL.LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId]',
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