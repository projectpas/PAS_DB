/********************************************************************
 ** File:   [USP_UpdateLeaseHeaderState]
 ** Description: Updates IsActive/IsDeleted state of a Lease Header record.
 **
 ***********************************************************************
 ** Change History
 ***********************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         ------------------------------------
    1    04/08/2026   Amit Ghediya    Created

exec USP_UpdateLeaseHeaderState @LeaseHeaderId=1,@MasterCompanyId=1,@IsDeleted=NULL,@IsActive=0
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateLeaseHeaderState]
	@LeaseHeaderId BIGINT,
	@MasterCompanyId INT,
	@IsDeleted BIT = NULL,
	@IsActive BIT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
		UPDATE [dbo].[LeaseHeader]
		SET
			IsDeleted = ISNULL(@IsDeleted, IsDeleted),
			IsActive  = ISNULL(@IsActive, IsActive),
			UpdatedDate = GETUTCDATE()
		WHERE LeaseHeaderId = @LeaseHeaderId
		  AND MasterCompanyId = @MasterCompanyId;

		SELECT LeaseHeaderId FROM [dbo].[LeaseHeader] WHERE LeaseHeaderId = @LeaseHeaderId;

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
            ROLLBACK TRAN;

		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_UpdateLeaseHeaderState]',
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