/*************************************************************
 ** File:   [USP_GetReservedLeaseStockPartsListByLeaseHeaderId]
 ** Description: Candidate grid for the "UnReserve Stock" popup - Lease Stock Lines
 **              that currently have a non-zero reserved quantity.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked against LeaseStockline.QtyReserved directly (no ledger table)

exec USP_GetReservedLeaseStockPartsListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetReservedLeaseStockPartsListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT
			LSL.LeaseStocklineId,
			LP.LeasePartId,
			LP.LeaseHeaderId,
			LSL.StockLineId,
			LP.ItemMasterId,
			LP.PN AS PartNumber,
			LP.PNDescription AS PartDescription,
			LSL.StocklineNumber,
			LSL.SN AS SerialNumber,
			LSL.QtyReserved AS TotalReserved,
			LSL.QtyOH AS QuantityOnHand,
			LSL.QtyAvailable AS QuantityAvailable,
			LP.MasterCompanyId
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN [dbo].[LeasePart] LP WITH (NOLOCK) ON LP.LeasePartId = LSL.LeasePartId
		WHERE LP.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
		  AND LP.IsDeleted = 0
		  AND LSL.QtyReserved > 0
		ORDER BY LSL.LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetReservedLeaseStockPartsListByLeaseHeaderId]',
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