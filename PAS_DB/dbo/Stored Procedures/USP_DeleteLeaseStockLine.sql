/*************************************************************
 ** File:   [USP_DeleteLeaseStockLine]
 ** Description: Soft-deletes a single LeaseStockline. Refuses if it currently has
 **              reserved quantity (must UnReserve first).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked to check QtyReserved directly (no ledger table)

exec USP_DeleteLeaseStockLine @LeaseStocklineId=1,@UpdatedBy=''
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteLeaseStockLine]
	@LeaseStocklineId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		IF EXISTS (
			SELECT 1
			FROM [dbo].[LeaseStockline] WITH (NOLOCK)
			WHERE LeaseStocklineId = @LeaseStocklineId
			  AND IsDeleted = 0
			  AND ISNULL(QtyReserved, 0) > 0
		)
		BEGIN
			SELECT 0 AS Status, 'This stock line has reserved stock. UnReserve it before removing.' AS Message;
			RETURN;
		END

		UPDATE [dbo].[LeaseStockline]
		SET IsActive = 0, IsDeleted = 1, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
		WHERE LeaseStocklineId = @LeaseStocklineId;

		SELECT 1 AS Status, 'Removed successfully' AS Message;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_DeleteLeaseStockLine]',
            @ProcedureParameters varchar(3000) = '@LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS varchar(100)),
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