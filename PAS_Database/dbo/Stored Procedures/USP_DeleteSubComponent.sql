/*************************************************************
 ** File:   [USP_DeleteSubComponent]
 ** Description: Deletes a Sub Component (same as the Work Order / Repair Order Sub-Assy delete : the row is removed, the audit trigger keeps the old values).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    05/11/2026		Kishor Makwana		[PN-18497] Created
**************************************************************/
-- EXEC [dbo].[USP_DeleteSubComponent] @SubComponentId = 1, @MasterCompanyId = 1
CREATE   PROCEDURE [dbo].[USP_DeleteSubComponent]
	@SubComponentId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRANSACTION

		DELETE FROM [dbo].[SubComponent] WHERE [SubComponentId] = @SubComponentId AND [MasterCompanyId] = @MasterCompanyId;

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
			, @AdhocComments VARCHAR(150) = 'USP_DeleteSubComponent'
			, @ProcedureParameters VARCHAR(3000) = '@SubComponentId = ' + CAST(ISNULL(@SubComponentId, 0) AS VARCHAR(20))
			, @ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END