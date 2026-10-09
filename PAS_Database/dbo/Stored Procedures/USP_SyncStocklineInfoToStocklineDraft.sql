/*************************************************************
 ** File:   [USP_SyncStocklineInfoToStocklineDraft]
 ** Author:   Rajesh Gami
 ** Description: Background-job SP. Finds DBO.StocklineDraft rows that already carry a StockLineId but whose stockline info
 **              (StockLineNumber, ControlNumber, IdNumber, ReceiverNumber, StocklineMatchKey, ReconciliationNumber) was never
 **              written back, and fills it in from DBO.Stockline.
 ** Purpose: Data-repair / sync. Fill-only: a draft column is updated ONLY when it is currently blank and the linked Stockline
 **          has a value for it. Existing draft values are never overwritten, and quantities / costs / status columns are
 **          intentionally NOT touched (they are a receiving-time snapshot and legitimately differ from the live Stockline).
 **          Safe to run repeatedly: once a row is fixed it no longer matches, so re-runs are a no-op.
 ** Date:   05-OCT-2026

 ** PARAMETERS: None

 ** RETURN VALUE: Single row with UpdatedCount (number of StocklineDraft rows fixed in this run).

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    05-OCT-2026  Rajesh Gami			[PN-18224] Created - Sync Missing Stockline Information in StocklineDraft

	EXEC [dbo].[USP_SyncStocklineInfoToStocklineDraft]
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SyncStocklineInfoToStocklineDraft]
AS
BEGIN
	-- NOTE: deliberately NOT using READ UNCOMMITTED / NOLOCK here. This SP writes values read from DBO.Stockline into
	-- DBO.StocklineDraft, so it must not pick up an uncommitted (possibly rolled back) stockline number from a receive in progress.
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @UpdatedCount INT = 0;

		-- Single set-based UPDATE (atomic on its own, no explicit transaction needed).
		-- StockLineId > 0 only: the receiving flow uses 0 for "not linked to a stockline".
		-- The WHERE keeps only rows where at least one blank draft column can be filled, so no no-op writes / audit rows.
		UPDATE sd
		SET sd.StockLineNumber =
				CASE WHEN ISNULL(LTRIM(RTRIM(sd.StockLineNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.StockLineNumber)), '') <> '' THEN sl.StockLineNumber ELSE sd.StockLineNumber END,
			sd.ControlNumber =
				CASE WHEN ISNULL(LTRIM(RTRIM(sd.ControlNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.ControlNumber)), '') <> '' THEN sl.ControlNumber ELSE sd.ControlNumber END,
			sd.IdNumber =
				CASE WHEN ISNULL(LTRIM(RTRIM(sd.IdNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.IdNumber)), '') <> '' THEN sl.IdNumber ELSE sd.IdNumber END,
			sd.ReceiverNumber =
				CASE WHEN ISNULL(LTRIM(RTRIM(sd.ReceiverNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.ReceiverNumber)), '') <> '' THEN sl.ReceiverNumber ELSE sd.ReceiverNumber END,
			sd.StocklineMatchKey =
				CASE WHEN ISNULL(LTRIM(RTRIM(sd.StocklineMatchKey)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.StocklineMatchKey)), '') <> '' THEN sl.StocklineMatchKey ELSE sd.StocklineMatchKey END,
			sd.ReconciliationNumber =
				CASE WHEN ISNULL(LTRIM(RTRIM(sd.ReconciliationNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.ReconciliationNumber)), '') <> '' THEN sl.ReconciliationNumber ELSE sd.ReconciliationNumber END,
			sd.UpdatedBy = 'Background Job',
			sd.UpdatedDate = GETUTCDATE()
		FROM [dbo].[StocklineDraft] sd WITH(NOLOCK)
		INNER JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId
		WHERE ISNULL(sd.StockLineId, 0) > 0
			AND (
					(ISNULL(LTRIM(RTRIM(sd.StockLineNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.StockLineNumber)), '') <> '')
				 OR (ISNULL(LTRIM(RTRIM(sd.ControlNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.ControlNumber)), '') <> '')
				 OR (ISNULL(LTRIM(RTRIM(sd.IdNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.IdNumber)), '') <> '')
				 OR (ISNULL(LTRIM(RTRIM(sd.ReceiverNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.ReceiverNumber)), '') <> '')
				 OR (ISNULL(LTRIM(RTRIM(sd.StocklineMatchKey)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.StocklineMatchKey)), '') <> '')
				 OR (ISNULL(LTRIM(RTRIM(sd.ReconciliationNumber)), '') = '' AND ISNULL(LTRIM(RTRIM(sl.ReconciliationNumber)), '') <> '')
				);

		SET @UpdatedCount = @@ROWCOUNT;

		SELECT @UpdatedCount AS UpdatedCount;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;

		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_STATE() AS ErrorState,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;

		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments VARCHAR(150) = 'USP_SyncStocklineInfoToStocklineDraft'
		,@ProcedureParameters VARCHAR(3000) = 'No parameters'
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END
