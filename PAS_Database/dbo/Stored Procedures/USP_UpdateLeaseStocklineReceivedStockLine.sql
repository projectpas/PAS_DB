/********************************************************************
 ** File:   [USP_UpdateLeaseStocklineReceivedStockLine]
 ** Description: Called when a Repair Order created from a Lease Stockline is
 **              received - links the Lease Stockline to whichever physical
 **              StockLine row now holds the received part (the original
 **              outbound line if it was updated in place, or a brand new
 **              line if receiving created one), and refreshes the
 **              denormalized StocklineNumber/ConditionId to match that line.
 **              Mirrors how AircraftInstalledPartDetails.StockLineId gets
 **              re-linked during the same receiving flow.
 **
 ***********************************************************************
 ** Change History
 ***********************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         ------------------------------------
    1    09/01/2026   Amit Ghediya    Created

exec USP_UpdateLeaseStocklineReceivedStockLine @LeasePartId = 1, @StockLineId = 1, @StocklineNumber = 'STL-000001', @ConditionId = 1
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateLeaseStocklineReceivedStockLine]
	@LeasePartId BIGINT,
	@StockLineId BIGINT,
	@StocklineNumber VARCHAR(100) = NULL,
	@ConditionId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
		IF @LeasePartId IS NOT NULL AND @LeasePartId > 0 AND @StockLineId IS NOT NULL AND @StockLineId > 0
		BEGIN
			UPDATE dbo.LeaseStockline
			   SET StockLineId = @StockLineId,
			       StocklineNumber = ISNULL(@StocklineNumber, StocklineNumber),
			       ConditionId = ISNULL(@ConditionId, ConditionId)
			 WHERE LeaseStocklineId = @LeasePartId
			   AND IsDeleted = 0;

			COMMIT TRANSACTION;
		END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_UpdateLeaseStocklineReceivedStockLine]',
            @ProcedureParameters varchar(3000) = '@LeasePartId = ''' + CAST(ISNULL(@LeasePartId, 0) AS varchar(100)) + ''', @StockLineId = ''' + CAST(ISNULL(@StockLineId, 0) AS varchar(100)),
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