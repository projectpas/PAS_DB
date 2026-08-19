/*************************************************************
 ** File:   [USP_UpdateLeaseStocklineRepairOrder]
 ** Description: Links (or updates) the Repair Order created for a Lease Stockline back onto [LeaseStockline].
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    18/08/2026     Amit Ghediya            Created

exec USP_UpdateLeaseStocklineRepairOrder @LeaseStockLineId=1,@RepairOrderId=1,@RONumber='RO-000001'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateLeaseStocklineRepairOrder]
	@LeaseStockLineId BIGINT,
	@RepairOrderId BIGINT,
	@RONumber VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		UPDATE [dbo].[LeaseStockline]
		SET RepairOrderId = @RepairOrderId,
			RONumber = @RONumber
		WHERE LeaseStocklineId = @LeaseStockLineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_UpdateLeaseStocklineRepairOrder]',
            @ProcedureParameters varchar(3000) = '@LeaseStockLineId = ''' + CAST(ISNULL(@LeaseStockLineId, 0) AS varchar(100)),
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