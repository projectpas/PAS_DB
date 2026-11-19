/*************************************************************
 ** File:   [USP_UpdateStocklineTimeCycleFromHistory]
 ** Description: Common procedure. Sets the current Time / Cycle values of a stockline
                 (TotalTSN, TotalTSNMM, TotalCSN, TotalTSO, TotalTSOMM, TotalCSO) from the LATEST entry of
                 StocklineTimeCycleHistory of that stockline (highest StocklineTimeCycleHistoryId, not deleted, same MasterCompanyId).
                 Every history row carries the running totals of all six values, so the latest row is the current value.
                 When the stockline has no history row nothing is changed.
 ** Date:   18/NOV/2026
 ** Author:  Rajesh Gami
 ** PARAMETERS: @StocklineId BIGINT, @MasterCompanyId INT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author         Change Description
 ** --   --------     -------        --------------------------------
    1    18/NOV/2026  Rajesh Gami    [PN-18594] Created
 -- EXEC [dbo].[USP_UpdateStocklineTimeCycleFromHistory] @StocklineId = 120120, @MasterCompanyId = 1
************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateStocklineTimeCycleFromHistory]
	@StocklineId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @TSN DECIMAL(18, 6), @TSNMM DECIMAL(18, 6), @CSN DECIMAL(18, 6),
				@TSO DECIMAL(18, 6), @TSOMM DECIMAL(18, 6), @CSO DECIMAL(18, 6);

		SELECT TOP 1
			@TSN = ISNULL(H.[TotalTSN], 0), @TSNMM = ISNULL(H.[TotalTSNMM], 0), @CSN = ISNULL(H.[TotalCSN], 0),
			@TSO = ISNULL(H.[TotalTSO], 0), @TSOMM = ISNULL(H.[TotalTSOMM], 0), @CSO = ISNULL(H.[TotalCSO], 0)
		FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
		WHERE H.[StocklineId] = @StocklineId
		  AND ISNULL(H.[IsDeleted], 0) = 0
		  AND (@MasterCompanyId IS NULL OR H.[MasterCompanyId] = @MasterCompanyId)
		ORDER BY H.[StocklineTimeCycleHistoryId] DESC;

		IF (@@ROWCOUNT = 0)
			RETURN;

		UPDATE [dbo].[Stockline]
		SET [TotalTSN] = @TSN, [TotalTSNMM] = @TSNMM, [TotalCSN] = @CSN,
			[TotalTSO] = @TSO, [TotalTSOMM] = @TSOMM, [TotalCSO] = @CSO
		WHERE [StockLineId] = @StocklineId
		  AND (@MasterCompanyId IS NULL OR [MasterCompanyId] = @MasterCompanyId);
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_UpdateStocklineTimeCycleFromHistory'
			, @ProcedureParameters VARCHAR(3000) = '@StocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@StocklineId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR('Something went wrong while updating the stockline time / cycle (error log id : %d)', 16, 1, @ErrorLogID);
		RETURN(1);
	END CATCH
END
