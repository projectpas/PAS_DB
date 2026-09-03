/*************************************************************
 ** File:   [USP_UpdateLeaseStocklineWorkOrder]
 ** Description: Links (or updates) the Work Order created for a Lease Stockline back onto [LeaseStockline].
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    27/08/2026     Amit Ghediya            Created

exec USP_UpdateLeaseStocklineWorkOrder @LeaseStockLineId=1,@WorkOrderId=1,@WorkOrderNo='WO-000001'
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateLeaseStocklineWorkOrder]
	@LeaseStockLineId BIGINT,
	@WorkOrderId BIGINT,
	@WorkOrderNo VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		UPDATE [dbo].[LeaseStockline]
		SET WorkOrderId = @WorkOrderId,
			WorkOrderNo = @WorkOrderNo
		WHERE LeaseStocklineId = @LeaseStockLineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_UpdateLeaseStocklineWorkOrder]',
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