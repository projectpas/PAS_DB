/*************************************************************
 ** File:   [USP_GetUnReservedLeaseStockPartsListByLeaseHeaderId]
 ** Description: Candidate grid for the "Reserve Stock" popup - Lease Stock Lines
 **              that still have order quantity remaining to reserve.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked against LeaseStockline.QtyOrder directly (no ledger table)
    3    21/08/2026     Amit Ghediya            LeaseStockline is now the primary Lease entity - removed LeasePart join,
                                                 QuantityOnHand/QuantityAvailable now read live from Stockline instead of a stored snapshot
    4    27/08/2026     Amit Ghediya            Exclude stocklines whose linked Work Order is still open (not yet
                                                 Closed/Canceled) - that stock is out being worked on, so it can't be
                                                 reserved again for the lease until the WO finishes

exec USP_GetUnReservedLeaseStockPartsListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetUnReservedLeaseStockPartsListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @WorkOrderStatusId VARCHAR(MAX) = '';

		SELECT @WorkOrderStatusId = STRING_AGG(CAST(Id AS VARCHAR(10)), ',')
		FROM [dbo].[WorkOrderStatus] WITH (NOLOCK)
		WHERE [Status] IN ('Closed', 'Canceled');

		SELECT
			LSL.LeaseStocklineId,
			LSL.LeaseHeaderId,
			LSL.StockLineId,
			LSL.ItemMasterId,
			LSL.PN AS PartNumber,
			LSL.PNDescription AS PartDescription,
			LSL.StocklineNumber,
			LSL.SN AS SerialNumber,
			LSL.QtyOrder AS QtyAvailableToReserve,
			LSL.QtyReserved AS TotalReserved,
			SLIVE.QuantityOnHand AS QuantityOnHand,
			SLIVE.QuantityAvailable AS QuantityAvailable,
			LSL.MasterCompanyId
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = LSL.WorkOrderId
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
		  AND LSL.QtyOrder > 0
		  AND (LSL.WorkOrderId IS NULL OR WO.WorkOrderStatusId IN (SELECT Item FROM DBO.SPLITSTRING(@WorkOrderStatusId,',')))
		ORDER BY LSL.LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetUnReservedLeaseStockPartsListByLeaseHeaderId]',
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