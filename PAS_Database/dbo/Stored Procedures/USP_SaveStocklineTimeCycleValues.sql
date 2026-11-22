/*************************************************************
 ** File:   [USP_SaveStocklineTimeCycleValues]
 ** Description: Called by the Stockline Details save (USP_CreateStockLine) with the VALUES (not amounts) of
                 TotalTSN, TotalTSNMM, TotalCSN, TotalTSO, TotalTSOMM, TotalCSO. Writes the ledger rows (StocklineTimeCycleHistory)
                 and then makes the stockline current (USP_UpdateStocklineTimeCycleFromHistory).
                   - @IsCreate = 1 : previous value is 0. EntryType 'Stockline'. A row is written only for the group that has a value.
                   - Edit : previous value = latest history row; when the stockline has no history yet, the current Stockline values
                            (before this save) are written first as one 'Stockline' baseline row. EntryType is always 'Stockline'.
                            Nothing is written when none of the six values changed.
                   - Time row  (any of TSN / TSO changed)  : Hours / Minutes = difference (new - previous, TSN, or TSO when only TSO changed), Cycles = NULL.
                   - Cycle row (any of CSN / CSO changed)  : Cycles = difference (CSN, or CSO when only CSO changed), Hours / Minutes = NULL.
                   - Every row carries the running totals of all six values, so the latest row is always the current value.
                   - Nothing is written when no value changed. Rows are never changed, only inserted.
                 Call it BEFORE the Stockline row is updated with the new values (it reads the old Stockline values for the baseline).
 ** Date:   18/NOV/2026
 ** Author:  Rajesh Gami
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author         Change Description
 ** --   --------     -------        --------------------------------
    1    18/NOV/2026  Rajesh Gami    [PN-18594] Created
************************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveStocklineTimeCycleValues]
	@StocklineId BIGINT,
	@MasterCompanyId INT,
	@TotalTSN DECIMAL(18, 6) = NULL,
	@TotalTSNMM DECIMAL(18, 6) = NULL,
	@TotalCSN DECIMAL(18, 6) = NULL,
	@TotalTSO DECIMAL(18, 6) = NULL,
	@TotalTSOMM DECIMAL(18, 6) = NULL,
	@TotalCSO DECIMAL(18, 6) = NULL,
	@IsCreate BIT = 0,
	@UpdatedBy VARCHAR(256) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @OwnTran BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
	BEGIN TRY
		IF (@OwnTran = 1) BEGIN TRANSACTION;

		SELECT @TotalTSN = ISNULL(@TotalTSN, 0), @TotalTSNMM = ISNULL(@TotalTSNMM, 0), @TotalCSN = ISNULL(@TotalCSN, 0),
			   @TotalTSO = ISNULL(@TotalTSO, 0), @TotalTSOMM = ISNULL(@TotalTSOMM, 0), @TotalCSO = ISNULL(@TotalCSO, 0);

		IF (@TotalTSN < 0 OR @TotalTSO < 0 OR @TotalCSN < 0 OR @TotalCSO < 0 OR @TotalTSNMM < 0 OR @TotalTSOMM < 0)
			RAISERROR('Time / Cycle values cannot be negative.', 16, 1);
		IF (@TotalTSNMM >= 60 OR @TotalTSOMM >= 60)
			RAISERROR('Minutes must be less than 60.', 16, 1);

		DECLARE @StockLineNumber VARCHAR(100), @StocklineModuleId BIGINT,
				@SlTSN DECIMAL(18, 6), @SlTSNMM DECIMAL(18, 6), @SlCSN DECIMAL(18, 6),
				@SlTSO DECIMAL(18, 6), @SlTSOMM DECIMAL(18, 6), @SlCSO DECIMAL(18, 6);

		-- lock the stockline : the entries of one stockline are written one by one
		SELECT @StockLineNumber = [StockLineNumber],
			   @SlTSN = ISNULL([TotalTSN], 0), @SlTSNMM = ISNULL([TotalTSNMM], 0), @SlCSN = ISNULL([TotalCSN], 0),
			   @SlTSO = ISNULL([TotalTSO], 0), @SlTSOMM = ISNULL([TotalTSOMM], 0), @SlCSO = ISNULL([TotalCSO], 0)
		FROM [dbo].[Stockline] WITH (UPDLOCK, ROWLOCK)
		WHERE [StockLineId] = @StocklineId;

		IF (@@ROWCOUNT = 0)
			RAISERROR('Stockline not found.', 16, 1);

		SELECT @StocklineModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'StockLine';

		/* ---------- previous values ---------- */
		DECLARE @PTSN DECIMAL(18, 6) = 0, @PTSNMM DECIMAL(18, 6) = 0, @PCSN DECIMAL(18, 6) = 0,
				@PTSO DECIMAL(18, 6) = 0, @PTSOMM DECIMAL(18, 6) = 0, @PCSO DECIMAL(18, 6) = 0,
				@EntryType VARCHAR(50) = NULL, @HasHistory BIT = 0;

		SELECT TOP 1 @HasHistory = 1, @EntryType = H.[EntryType],
			   @PTSN = ISNULL(H.[TotalTSN], 0), @PTSNMM = ISNULL(H.[TotalTSNMM], 0), @PCSN = ISNULL(H.[TotalCSN], 0),
			   @PTSO = ISNULL(H.[TotalTSO], 0), @PTSOMM = ISNULL(H.[TotalTSOMM], 0), @PCSO = ISNULL(H.[TotalCSO], 0)
		FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
		WHERE H.[StocklineId] = @StocklineId AND ISNULL(H.[IsDeleted], 0) = 0
		ORDER BY H.[StocklineTimeCycleHistoryId] DESC;

		IF (ISNULL(@IsCreate, 0) = 1)
		BEGIN
			SELECT @PTSN = 0, @PTSNMM = 0, @PCSN = 0, @PTSO = 0, @PTSOMM = 0, @PCSO = 0, @EntryType = 'Stockline';
		END
		ELSE IF (@HasHistory = 0)
		BEGIN
			-- old stockline without history : its current value is the starting point (written once as a baseline row)
			SELECT @PTSN = @SlTSN, @PTSNMM = @SlTSNMM, @PCSN = @SlCSN, @PTSO = @SlTSO, @PTSOMM = @SlTSOMM, @PCSO = @SlCSO;

			-- only when a value really changed (nothing changed = nothing written)
			IF ((@PTSN <> 0 OR @PTSNMM <> 0 OR @PCSN <> 0 OR @PTSO <> 0 OR @PTSOMM <> 0 OR @PCSO <> 0)
				AND (@PTSN <> @TotalTSN OR @PTSNMM <> @TotalTSNMM OR @PCSN <> @TotalCSN OR @PTSO <> @TotalTSO OR @PTSOMM <> @TotalTSOMM OR @PCSO <> @TotalCSO))
				INSERT INTO [dbo].[StocklineTimeCycleHistory]
					([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [EntryType], [EntryDate],
					 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
					 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES
					(@StocklineId, @StocklineModuleId, @StocklineId, @StockLineNumber, 'Stockline', GETUTCDATE(),
					 @PTSN, @PTSNMM, @PCSN, @PTSN, @PTSNMM, @PCSN, @PTSO, @PTSOMM, @PCSO, 'Opening balance from Stockline',
					 @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0);
		END

		-- every entry written from the Stockline Details screen (create or edit) is EntryType 'Stockline'
		SET @EntryType = 'Stockline';

		/* ---------- differences (time in minutes) ---------- */
		DECLARE @DiffTsnMin DECIMAL(18, 6) = (@TotalTSN * 60 + @TotalTSNMM) - (@PTSN * 60 + @PTSNMM),
				@DiffTsoMin DECIMAL(18, 6) = (@TotalTSO * 60 + @TotalTSOMM) - (@PTSO * 60 + @PTSOMM),
				@DiffCsn DECIMAL(18, 6) = @TotalCSN - @PCSN,
				@DiffCso DECIMAL(18, 6) = @TotalCSO - @PCSO,
				@RowMin DECIMAL(18, 6), @RowHours DECIMAL(18, 6), @RowMinutes DECIMAL(18, 6), @RowCycles DECIMAL(18, 6),
				@RowMemo NVARCHAR(MAX);

		/* ---------- time row : TSN / TSO ---------- */
		IF (@DiffTsnMin <> 0 OR @DiffTsoMin <> 0)
		BEGIN
			SET @RowMin = CASE WHEN @DiffTsnMin <> 0 THEN @DiffTsnMin ELSE @DiffTsoMin END;
			SET @RowHours = CAST(@RowMin / 60 AS BIGINT);          -- truncates towards zero, minutes keep the same sign
			SET @RowMinutes = @RowMin - @RowHours * 60;
			SET @RowMemo = N'Stockline Details : TSN ' + CONVERT(VARCHAR(30), @DiffTsnMin) + N' min, TSO ' + CONVERT(VARCHAR(30), @DiffTsoMin) + N' min';

			INSERT INTO [dbo].[StocklineTimeCycleHistory]
				([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [EntryType], [EntryDate],
				 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
				 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES
				(@StocklineId, @StocklineModuleId, @StocklineId, @StockLineNumber, @EntryType, GETUTCDATE(),
				 @RowHours, @RowMinutes, NULL, @TotalTSN, @TotalTSNMM, @PCSN, @TotalTSO, @TotalTSOMM, @PCSO, @RowMemo,
				 @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0);
		END

		/* ---------- cycle row : CSN / CSO ---------- */
		IF (@DiffCsn <> 0 OR @DiffCso <> 0)
		BEGIN
			SET @RowCycles = CASE WHEN @DiffCsn <> 0 THEN @DiffCsn ELSE @DiffCso END;
			SET @RowMemo = N'Stockline Details : CSN ' + CONVERT(VARCHAR(30), @DiffCsn) + N', CSO ' + CONVERT(VARCHAR(30), @DiffCso);

			INSERT INTO [dbo].[StocklineTimeCycleHistory]
				([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [EntryType], [EntryDate],
				 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
				 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES
				(@StocklineId, @StocklineModuleId, @StocklineId, @StockLineNumber, @EntryType, GETUTCDATE(),
				 NULL, NULL, @RowCycles, @TotalTSN, @TotalTSNMM, @TotalCSN, @TotalTSO, @TotalTSOMM, @TotalCSO, @RowMemo,
				 @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0);
		END

		/* ---------- latest history row -> Stockline (the six fields) ---------- */
		EXEC [dbo].[USP_UpdateStocklineTimeCycleFromHistory] @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId;

		IF (@OwnTran = 1) COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF (@OwnTran = 1 AND @@TRANCOUNT > 0) ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(2048) = ERROR_MESSAGE();
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SaveStocklineTimeCycleValues'
			, @ProcedureParameters VARCHAR(3000) = '@StocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@StocklineId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''', @IsCreate = ''' + CONVERT(VARCHAR(5), ISNULL(@IsCreate, 0)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR('%s (error log id : %d)', 16, 1, @ErrorMessage, @ErrorLogID);
		RETURN(1);
	END CATCH
END
