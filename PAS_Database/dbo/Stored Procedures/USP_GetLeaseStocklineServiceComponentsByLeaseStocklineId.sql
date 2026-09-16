/*************************************************************
 ** File:   [USP_GetLeaseStocklineServiceComponentsByLeaseStocklineId]
 ** Description: Returns the dynamic/custom-named Service Component rows
 **              (Name/Amount/Per) saved for a single LeaseStockline.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    14/09/2026     Amit Ghediya            Created

exec USP_GetLeaseStocklineServiceComponentsByLeaseStocklineId @LeaseStocklineId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetLeaseStocklineServiceComponentsByLeaseStocklineId]
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT LeaseStocklineServiceComponentId, LeaseStocklineId, ComponentName, Amount, Per
		FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0
		ORDER BY LeaseStocklineServiceComponentId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseStocklineServiceComponentsByLeaseStocklineId]',
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
