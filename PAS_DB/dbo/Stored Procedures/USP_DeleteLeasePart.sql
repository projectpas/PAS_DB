/*************************************************************
 ** File:   [USP_DeleteLeasePart]
 ** Description: Soft-deletes a LeasePart and cascades soft-delete to its child LeaseStockline rows.
 **              Refuses if any child stockline currently has reserved quantity (must UnReserve first).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked to check LeaseStockline.QtyReserved directly (no ledger table)

exec USP_DeleteLeasePart @LeasePartId=1,@UpdatedBy=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteLeasePart]
	@LeasePartId BIGINT,
	@UpdatedBy BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		IF EXISTS (
			SELECT 1
			FROM [dbo].[LeaseStockline] WITH (NOLOCK)
			WHERE LeasePartId = @LeasePartId
			  AND IsDeleted = 0
			  AND ISNULL(QtyReserved, 0) > 0
		)
		BEGIN
			SELECT 0 AS Status, 'This part has reserved stock. UnReserve it before removing.' AS Message;
			RETURN;
		END

		UPDATE [dbo].[LeaseStockline]
		SET IsActive = 0, IsDeleted = 1, UpdatedBy = @UpdatedBy, UpdatedDate = SYSDATETIME()
		WHERE LeasePartId = @LeasePartId;

		UPDATE [dbo].[LeasePart]
		SET IsActive = 0, IsDeleted = 1, UpdatedBy = @UpdatedBy, UpdatedDate = SYSDATETIME()
		WHERE LeasePartId = @LeasePartId;

		SELECT 1 AS Status, 'Removed successfully' AS Message;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_DeleteLeasePart]',
            @ProcedureParameters varchar(3000) = '@LeasePartId = ''' + CAST(ISNULL(@LeasePartId, 0) AS varchar(100)),
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