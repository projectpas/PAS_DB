/*************************************************************
 ** File:  [USP_CleanUpUserActivityLogs]
 ** Author:  Sahdev Saliya
 ** Description: This stored procedure deletes UserActivityLog records older than @RetentionDays days
 ** Date:   25-Aug-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    28-Aug-2026	Sahdev Saliya		Created

--  EXEC [dbo].[USP_CleanUpUserActivityLogs] '2026-08-20'
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_CleanUpUserActivityLogs]
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		DECLARE @CutoffDate DATETIME = DATEADD(DAY, -5, GETUTCDATE());

		DELETE FROM [dbo].[UserActivityLog]
		WHERE [CreatedDate] < @CutoffDate;

		SELECT @@ROWCOUNT AS RowsDeleted;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments VARCHAR(150)			= 'USP_CleanUpUserActivityLogs'
		, @ProcedureParameters VARCHAR(3000)	= '@CutoffDate = ''' + CAST(ISNULL(@CutoffDate, '') AS VARCHAR(100)) + ''
		, @ApplicationName VARCHAR(100)			= 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
		exec spLogException
				@DatabaseName				= @DatabaseName
				, @AdhocComments			= @AdhocComments
				, @ProcedureParameters		= @ProcedureParameters
				, @ApplicationName			=  @ApplicationName
				, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END