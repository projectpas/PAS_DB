/********************************************************************
 ** File:   [USP_GetLeaseNumberByLeaseStocklineId]
 ** Description: Returns the Lease Number for a given Lease Stockline Id.
 **
 ***********************************************************************
 ** Change History
 ***********************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         ------------------------------------
    1    09/01/2026   Amit Ghediya    Created

exec USP_GetLeaseNumberByLeaseStocklineId @LeaseStocklineId = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseNumberByLeaseStocklineId]
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT LH.LeaseNumber
		FROM dbo.LeaseStockline LSL WITH (NOLOCK)
		INNER JOIN dbo.LeaseHeader LH WITH (NOLOCK) ON LH.LeaseHeaderId = LSL.LeaseHeaderId
		WHERE LSL.LeaseStocklineId = @LeaseStocklineId
		  AND LSL.IsDeleted = 0
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseNumberByLeaseStocklineId]',
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