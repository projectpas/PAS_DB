/*************************************************************
 ** File:   [USP_DeleteLeaseCharge]
 ** Description: Soft-deletes a single LeaseCharges row (the list's Delete
 **              action).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/09/2026     Amit Ghediya            Created

exec USP_DeleteLeaseCharge @LeaseChargesId=1, @UpdatedBy='test'
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_DeleteLeaseCharge]
	@LeaseChargesId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		UPDATE [dbo].[LeaseCharges]
		SET IsDeleted = 1,
			UpdatedBy = @UpdatedBy,
			UpdatedDate = GETUTCDATE()
		WHERE LeaseChargesId = @LeaseChargesId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_DeleteLeaseCharge]',
            @ProcedureParameters varchar(3000) = '@LeaseChargesId = ''' + CAST(ISNULL(@LeaseChargesId, 0) AS varchar(100)),
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
