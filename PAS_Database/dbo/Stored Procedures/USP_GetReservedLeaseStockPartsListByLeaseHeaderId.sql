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
    3    21/08/2026     Amit Ghediya            LeaseStockline is now the primary Lease entity - removed LeasePart join,
                                                 QuantityOnHand/QuantityAvailable now read live from Stockline instead of a stored snapshot

exec USP_GetReservedLeaseStockPartsListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetReservedLeaseStockPartsListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT
			LSL.LeaseStocklineId,
			LSL.LeaseHeaderId,
			LSL.StockLineId,
			LSL.ItemMasterId,
			LSL.PN AS PartNumber,
			LSL.PNDescription AS PartDescription,
			LSL.StocklineNumber,
			LSL.SN AS SerialNumber,
			LSL.QtyReserved AS TotalReserved,
			SLIVE.QuantityOnHand AS QuantityOnHand,
			SLIVE.QuantityAvailable AS QuantityAvailable,
			LSL.MasterCompanyId
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
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