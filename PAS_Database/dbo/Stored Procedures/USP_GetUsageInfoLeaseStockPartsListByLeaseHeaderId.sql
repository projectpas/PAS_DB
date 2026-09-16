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
    2    15/09/2026     Amit Ghediya            Added LatestNotes (from
                                                 LeaseStocklineUsage, via the same
                                                 join already used for HasUsageInfo)
                                                 so the most recent note is
                                                 available to show on this list if
                                                 a FieldMaster column is added later

exec USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId]
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
			U.LatestNotes,
			CASE WHEN U.LeaseStocklineUsageId IS NOT NULL THEN 1 ELSE 0 END AS HasUsageInfo
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
