/*************************************************************
 ** File:   [USP_AddStocklineTimeCycleFromCycleEntry]
 ** Description: Writes the ledger rows (StocklineTimeCycleHistory) for ONE save of the "Cycle & Time" popup of an Aircraft / Engine.
                 Called by USP_SaveAircraftCycleTimeMappings and USP_SaveEngineCycleTimeMappings (aircraft stockline, engine stockline).
                   1) EDITED current value (pencil icon) : @HasStored = 1 and the Current value in the popup differs from the value saved last time
                      (@OldCum*)  ->  one 'Correction' row with the difference (can be negative).
                   2) ADD : any of @AddHours / @AddMinutes / @AddCycles > 0  ->  one 'Usage' row with the added amount.
                 The ledger only inserts, nothing is changed. Nothing is written when the aircraft / engine has no stockline.
                 A problem in the ledger must not block the cycle save : errors are caught here (logged by USP_AddStocklineTimeCycleHistory).
 ** Date:   26/10/2026
 ** Author: Kishor Makwana
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author             Change Description
 ** --   --------     -------            --------------------------------
    1    26/OCT/2026  Kishor Makwana     Created
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddStocklineTimeCycleFromCycleEntry]
	@StocklineId BIGINT,
	@ModuleId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferenceNumber VARCHAR(100) = NULL,
	@SubModuleId BIGINT = NULL,
	@SubReferenceId BIGINT = NULL,
	@SubReferenceNumber VARCHAR(100) = NULL,
	@EntryDate DATETIME2(7) = NULL,
	@AddHours DECIMAL(18, 6) = 0,
	@AddMinutes DECIMAL(18, 6) = 0,
	@AddCycles DECIMAL(18, 6) = 0,
	@HasStored BIT = 0,
	@OldCumHours DECIMAL(18, 6) = 0,
	@OldCumMinutes DECIMAL(18, 6) = 0,
	@OldCumCycles DECIMAL(18, 6) = 0,
	@CurHours DECIMAL(18, 6) = 0,
	@CurMinutes DECIMAL(18, 6) = 0,
	@CurCycles DECIMAL(18, 6) = 0,
	@Memo NVARCHAR(MAX) = NULL,
	@MasterCompanyId INT = NULL,
	@CreatedBy VARCHAR(256) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF (ISNULL(@StocklineId, 0) = 0) RETURN;

	BEGIN TRY
		DECLARE @Id BIGINT,
				@DiffMin DECIMAL(18, 6),
				@DiffCyc DECIMAL(18, 6),
				@DiffH DECIMAL(18, 6),
				@DiffM DECIMAL(18, 6);

		/* ---------- 1) edited current value -> Correction ---------- */
		IF (ISNULL(@HasStored, 0) = 1)
		BEGIN
			SET @DiffMin = (ISNULL(@CurHours, 0) * 60 + ISNULL(@CurMinutes, 0)) - (ISNULL(@OldCumHours, 0) * 60 + ISNULL(@OldCumMinutes, 0));
			SET @DiffCyc = ISNULL(@CurCycles, 0) - ISNULL(@OldCumCycles, 0);

			IF (@DiffMin <> 0 OR @DiffCyc <> 0)
			BEGIN
				SET @DiffH = CAST(@DiffMin / 60 AS BIGINT);      -- truncates towards zero, minutes keep the same sign
				SET @DiffM = @DiffMin - @DiffH * 60;

				EXEC [dbo].[USP_AddStocklineTimeCycleHistory]
					@StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @ReferenceNumber = @ReferenceNumber,
					@SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId, @SubReferenceNumber = @SubReferenceNumber,
					@EntryType = 'Correction', @EntryDate = @EntryDate, @Hours = @DiffH, @Minutes = @DiffM, @Cycles = @DiffCyc,
					@Memo = N'Current time / cycles edited', @MasterCompanyId = @MasterCompanyId, @CreatedBy = @CreatedBy,
					@StocklineTimeCycleHistoryId = @Id OUTPUT;
			END
		END

		/* ---------- 2) added time / cycles -> Usage ---------- */
		IF (ISNULL(@AddHours, 0) > 0 OR ISNULL(@AddMinutes, 0) > 0 OR ISNULL(@AddCycles, 0) > 0)
		BEGIN
			EXEC [dbo].[USP_AddStocklineTimeCycleHistory]
				@StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @ReferenceNumber = @ReferenceNumber,
				@SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId, @SubReferenceNumber = @SubReferenceNumber,
				@EntryType = 'Usage', @EntryDate = @EntryDate, @Hours = @AddHours, @Minutes = @AddMinutes, @Cycles = @AddCycles,
				@Memo = @Memo, @MasterCompanyId = @MasterCompanyId, @CreatedBy = @CreatedBy,
				@StocklineTimeCycleHistoryId = @Id OUTPUT;
		END
	END TRY
	BEGIN CATCH
		-- already logged by USP_AddStocklineTimeCycleHistory (spLogException); the cycle save itself must go on
		PRINT 'USP_AddStocklineTimeCycleFromCycleEntry : ' + ERROR_MESSAGE();
	END CATCH
END