/*************************************************************
 ** File:   [USP_AddStocklineTimeCycleHistory]
 ** Description: Adds ONE entry of Time and Cycles of a stockline to StocklineTimeCycleHistory. Every module calls this procedure
                 (Lease usage, Aircraft / Engine, Work Order, ...), nobody writes the table directly.
                   - Always inserts a new row, existing rows are never changed (a wrong entry = new 'Correction' row with the difference).
                   - Hours / Minutes / Cycles = amount added by this entry (negative allowed for a correction).
                   - Total* = running total after this entry = previous row + the amount. Previous row = latest row of the stockline
                     (highest StocklineTimeCycleHistoryId, not deleted).
                   - First entry of a stockline : an 'Opening' row is written from Stockline.TotalTSN / TotalTSNMM / TotalCSN (when any of them is > 0)
                     so the old value is not lost, then this entry is added on top.
                   - Time is hours + minutes (minutes are kept below 60), same as Stockline.TotalTSN / TotalTSNMM.
                   - TSO / CSO (since overhaul) are NOT added for now : they stay at the previous value (0) on every row. Pass @AddToOverhaul = 1 to
                     make an entry grow them too (when overhaul tracking starts). EntryType = 'OverhaulReset' always sets TSO, TSO minutes and CSO to 0.
                   - @UpdateStockline = 1 : Stockline.TotalTSN / TotalTSNMM / TotalCSN are set to the new totals (current value).
                   - SUB COMPONENTS : an entry (Usage / Correction / Adjustment) of a PARENT stockline is written again, with the same Hours / Minutes / Cycles,
                     on every sub component below it (@CascadeToSubComponents = 1, default). Example : aircraft 1000 h + 100 h -> aircraft 1100,
                     its engine 2000 -> 2100, the bearing of the engine 50 -> 150. Sub components are found through Stockline.IsSubComponent /
                     SubComponentParentStocklineId, plus the engines of an aircraft (AircraftRegistryHeader.EngineRegistryIds), level after level.
                     Child rows have ParentStocklineId = the stockline the entry was made on, and the same Module / Reference as the parent entry.
                     A problem on one child never stops the parent entry (logged and skipped).
                 Serialised per stockline (UPDLOCK on the Stockline row). No result set, safe to call from other procedures; runs in the
                 caller's transaction when there is one, otherwise it opens its own.
 ** Date:   10/23/2026
 ** Author:  Kishor Makwana
 ** RETURN VALUE: @StocklineTimeCycleHistoryId OUTPUT = id of the new row (not the Opening row)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/OCT/2026  Kishor Makwana   Created
    2    23/OCT/2026  Kishor Makwana   TotalTSO / TotalTSOMM / TotalCSO stay 0 for now (@AddToOverhaul = 0 by default)
    3    26/OCT/2026  Kishor Makwana   Same time / cycles are written on all sub components of the stockline (new @CascadeToSubComponents, @ParentStocklineId)
-- DECLARE @Id BIGINT;
-- EXEC [dbo].[USP_AddStocklineTimeCycleHistory] @StocklineId = 1, @ModuleId = 1, @ReferenceId = 1, @ReferenceNumber = 'LSE-000028', @EntryType = 'Usage',
--      @Hours = 10, @Minutes = 30, @Cycles = 5, @CreatedBy = 'admin', @StocklineTimeCycleHistoryId = @Id OUTPUT;
-- current value of a stockline :
-- SELECT TOP 1 * FROM [dbo].[StocklineTimeCycleHistory] WHERE StocklineId = 1 AND ISNULL(IsDeleted, 0) = 0 ORDER BY StocklineTimeCycleHistoryId DESC
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddStocklineTimeCycleHistory]
	@StocklineId BIGINT,
	@ModuleId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferenceNumber VARCHAR(100) = NULL,
	@SubModuleId BIGINT = NULL,
	@SubReferenceId BIGINT = NULL,
	@SubReferenceNumber VARCHAR(100) = NULL,
	@EntryType VARCHAR(50) = 'Usage',
	@EntryDate DATETIME2(7) = NULL,
	@Hours DECIMAL(18, 6) = NULL,
	@Minutes DECIMAL(18, 6) = NULL,
	@Cycles DECIMAL(18, 6) = NULL,
	@Memo NVARCHAR(MAX) = NULL,
	@MasterCompanyId INT = NULL,
	@CreatedBy VARCHAR(256) = NULL,
	@UpdateStockline BIT = 1,
	@AddToOverhaul BIT = 0,
	@CascadeToSubComponents BIT = 1,
	@ParentStocklineId BIGINT = NULL,        -- set only by this procedure when it writes the row of a sub component
	@StocklineTimeCycleHistoryId BIGINT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @OwnTran BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
	BEGIN TRY
		IF (@OwnTran = 1) BEGIN TRANSACTION;

		DECLARE @SlMasterCompanyId INT, @SlTSN DECIMAL(18, 6), @SlTSNMM DECIMAL(18, 6), @SlCSN DECIMAL(18, 6);

		-- lock the stockline : entries of one stockline are written one by one
		SELECT @SlMasterCompanyId = [MasterCompanyId], @SlTSN = [TotalTSN], @SlTSNMM = [TotalTSNMM], @SlCSN = [TotalCSN]
		FROM [dbo].[Stockline] WITH (UPDLOCK, ROWLOCK)
		WHERE [StockLineId] = @StocklineId;

		IF (@SlMasterCompanyId IS NULL)
			RAISERROR('Stockline not found.', 16, 1);

		SET @MasterCompanyId = ISNULL(@MasterCompanyId, @SlMasterCompanyId);
		SET @EntryType = ISNULL(NULLIF(LTRIM(RTRIM(@EntryType)), ''), 'Usage');
		SET @EntryDate = ISNULL(@EntryDate, GETUTCDATE());

		/* ---------- previous totals = latest row, or Stockline value (written as Opening row) ---------- */
		DECLARE @PTSN DECIMAL(18, 6) = 0, @PTSNMM DECIMAL(18, 6) = 0, @PCSN DECIMAL(18, 6) = 0,
				@PTSO DECIMAL(18, 6) = 0, @PTSOMM DECIMAL(18, 6) = 0, @PCSO DECIMAL(18, 6) = 0;

		SELECT TOP 1 @PTSN = ISNULL([TotalTSN], 0), @PTSNMM = ISNULL([TotalTSNMM], 0), @PCSN = ISNULL([TotalCSN], 0),
					 @PTSO = ISNULL([TotalTSO], 0), @PTSOMM = ISNULL([TotalTSOMM], 0), @PCSO = ISNULL([TotalCSO], 0)
		FROM [dbo].[StocklineTimeCycleHistory] WITH (NOLOCK)
		WHERE [StocklineId] = @StocklineId AND ISNULL([IsDeleted], 0) = 0
		ORDER BY [StocklineTimeCycleHistoryId] DESC;

		IF (@@ROWCOUNT = 0)
		BEGIN
			SELECT @PTSN = ISNULL(@SlTSN, 0), @PTSNMM = ISNULL(@SlTSNMM, 0), @PCSN = ISNULL(@SlCSN, 0);

			IF (@PTSN <> 0 OR @PTSNMM <> 0 OR @PCSN <> 0)
				INSERT INTO [dbo].[StocklineTimeCycleHistory]
					([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [SubModuleId], [SubReferenceId], [SubReferenceNumber], [EntryType], [EntryDate],
					 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
					 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES
					(@StocklineId, NULL, NULL, NULL, NULL, NULL, NULL, 'Opening', @EntryDate,
					 @PTSN, @PTSNMM, @PCSN, @PTSN, @PTSNMM, @PCSN, 0, 0, 0, 'Opening balance from Stockline',
					 @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0);
		END

		/* ---------- new totals ---------- */
		DECLARE @AddMin DECIMAL(18, 6) = ISNULL(@Hours, 0) * 60 + ISNULL(@Minutes, 0),
				@AddCyc DECIMAL(18, 6) = ISNULL(@Cycles, 0),
				@TsnMin DECIMAL(18, 6), @TsoMin DECIMAL(18, 6),
				@NTSN DECIMAL(18, 6), @NTSNMM DECIMAL(18, 6), @NCSN DECIMAL(18, 6),
				@NTSO DECIMAL(18, 6), @NTSOMM DECIMAL(18, 6), @NCSO DECIMAL(18, 6);

		SET @TsnMin = @PTSN * 60 + @PTSNMM + @AddMin;
		SET @TsoMin = @PTSO * 60 + @PTSOMM + CASE WHEN ISNULL(@AddToOverhaul, 0) = 1 THEN @AddMin ELSE 0 END;
		SET @NCSN = @PCSN + @AddCyc;
		SET @NCSO = @PCSO + CASE WHEN ISNULL(@AddToOverhaul, 0) = 1 THEN @AddCyc ELSE 0 END;

		IF (@EntryType = 'OverhaulReset')
			SELECT @TsoMin = 0, @NCSO = 0;

		IF (@TsnMin < 0 OR @TsoMin < 0 OR @NCSN < 0 OR @NCSO < 0)
			RAISERROR('This entry makes a total time / cycle negative.', 16, 1);

		SELECT @NTSN = FLOOR(@TsnMin / 60), @NTSNMM = @TsnMin - FLOOR(@TsnMin / 60) * 60,
			   @NTSO = FLOOR(@TsoMin / 60), @NTSOMM = @TsoMin - FLOOR(@TsoMin / 60) * 60;

		INSERT INTO [dbo].[StocklineTimeCycleHistory]
			([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [SubModuleId], [SubReferenceId], [SubReferenceNumber], [EntryType], [EntryDate],
			 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
			 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [ParentStocklineId])
		VALUES
			(@StocklineId, @ModuleId, @ReferenceId, @ReferenceNumber, @SubModuleId, @SubReferenceId, @SubReferenceNumber, @EntryType, @EntryDate,
			 @Hours, @Minutes, @Cycles, @NTSN, @NTSNMM, @NCSN, @NTSO, @NTSOMM, @NCSO, @Memo,
			 @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @ParentStocklineId);

		SET @StocklineTimeCycleHistoryId = SCOPE_IDENTITY();

		/* ---------- current value on the stockline ---------- */
		IF (ISNULL(@UpdateStockline, 1) = 1)
			UPDATE [dbo].[Stockline]
			SET [TotalTSN] = @NTSN, [TotalTSNMM] = @NTSNMM, [TotalCSN] = @NCSN,
				[UpdatedBy] = ISNULL(@CreatedBy, [UpdatedBy]), [UpdatedDate] = GETUTCDATE()
			WHERE [StockLineId] = @StocklineId;

		/* ---------- sub components : same entry on every stockline below this one ---------- */
		IF (ISNULL(@CascadeToSubComponents, 1) = 1 AND @ParentStocklineId IS NULL AND @EntryType IN ('Usage', 'Correction', 'Adjustment'))
		BEGIN
			DECLARE @Seen TABLE ([StocklineId] BIGINT PRIMARY KEY, [Lvl] INT);
			DECLARE @Frontier TABLE ([StocklineId] BIGINT PRIMARY KEY);
			DECLARE @Next TABLE ([StocklineId] BIGINT PRIMARY KEY);
			DECLARE @Lvl INT = 0;

			INSERT INTO @Seen VALUES (@StocklineId, 0);
			INSERT INTO @Frontier VALUES (@StocklineId);

			WHILE (@Lvl < 10 AND EXISTS (SELECT 1 FROM @Frontier))
			BEGIN
				SET @Lvl = @Lvl + 1;
				DELETE FROM @Next;

				INSERT INTO @Next ([StocklineId])
				SELECT c.[StocklineId]
				FROM (
					-- sub components (installed components of aircraft / engine, WO / SO / RO sub components ...)
					SELECT SL.[StockLineId] AS [StocklineId]
					FROM [dbo].[Stockline] SL WITH (NOLOCK)
					INNER JOIN @Frontier F ON F.[StocklineId] = SL.[SubComponentParentStocklineId]
					WHERE ISNULL(SL.[IsSubComponent], 0) = 1 AND ISNULL(SL.[IsDeleted], 0) = 0
					UNION
					-- engines of an aircraft (list of engine registry ids on the aircraft)
					SELECT ERH.[StockLineId]
					FROM [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
					INNER JOIN @Frontier F ON F.[StocklineId] = ARH.[StockLineId]
					CROSS APPLY STRING_SPLIT(ARH.[EngineRegistryIds], ',') S
					INNER JOIN [dbo].[EngineRegistryHeader] ERH WITH (NOLOCK) ON ERH.[EngineRegistryId] = TRY_CAST(LTRIM(RTRIM(S.[value])) AS BIGINT)
					WHERE ARH.[EngineRegistryIds] IS NOT NULL AND ERH.[StockLineId] IS NOT NULL
				) c
				WHERE c.[StocklineId] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM @Seen z WHERE z.[StocklineId] = c.[StocklineId]);

				INSERT INTO @Seen ([StocklineId], [Lvl]) SELECT [StocklineId], @Lvl FROM @Next;

				DELETE FROM @Frontier;
				INSERT INTO @Frontier ([StocklineId]) SELECT [StocklineId] FROM @Next;
			END

			IF EXISTS (SELECT 1 FROM @Seen WHERE [Lvl] > 0)
			BEGIN
				DECLARE @ChildId BIGINT, @ChildHistoryId BIGINT,
						@ChildMemo NVARCHAR(MAX) = N'Same time / cycles as parent stockline ' + ISNULL((SELECT TOP 1 [StockLineNumber] FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @StocklineId), CONVERT(VARCHAR(20), @StocklineId))
												  + ISNULL(N' | ' + @Memo, N'');

				DECLARE cSubComp CURSOR LOCAL FAST_FORWARD FOR
					SELECT [StocklineId] FROM @Seen WHERE [Lvl] > 0 ORDER BY [Lvl], [StocklineId];
				OPEN cSubComp;
				FETCH NEXT FROM cSubComp INTO @ChildId;
				WHILE (@@FETCH_STATUS = 0)
				BEGIN
					BEGIN TRY
						EXEC [dbo].[USP_AddStocklineTimeCycleHistory]
							@StocklineId = @ChildId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @ReferenceNumber = @ReferenceNumber,
							@SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId, @SubReferenceNumber = @SubReferenceNumber,
							@EntryType = @EntryType, @EntryDate = @EntryDate, @Hours = @Hours, @Minutes = @Minutes, @Cycles = @Cycles,
							@Memo = @ChildMemo, @MasterCompanyId = @MasterCompanyId, @CreatedBy = @CreatedBy,
							@UpdateStockline = @UpdateStockline, @AddToOverhaul = @AddToOverhaul,
							@CascadeToSubComponents = 0, @ParentStocklineId = @StocklineId,
							@StocklineTimeCycleHistoryId = @ChildHistoryId OUTPUT;
					END TRY
					BEGIN CATCH
						-- the child problem is already logged by the call above; the parent entry stays
						PRINT 'USP_AddStocklineTimeCycleHistory : sub component ' + CONVERT(VARCHAR(20), @ChildId) + ' skipped : ' + ERROR_MESSAGE();
					END CATCH
					FETCH NEXT FROM cSubComp INTO @ChildId;
				END
				CLOSE cSubComp; DEALLOCATE cSubComp;
			END
		END

		IF (@OwnTran = 1) COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF (@OwnTran = 1 AND @@TRANCOUNT > 0) ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(2048) = ERROR_MESSAGE();
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_AddStocklineTimeCycleHistory'
			, @ProcedureParameters VARCHAR(3000) = '@StocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@StocklineId, 0)) + ''', @ModuleId = ''' + CONVERT(VARCHAR(20), ISNULL(@ModuleId, 0)) + ''', @ReferenceId = ''' + CONVERT(VARCHAR(20), ISNULL(@ReferenceId, 0)) + ''', @EntryType = ''' + ISNULL(@EntryType, '') + ''', @Hours = ''' + CONVERT(VARCHAR(30), ISNULL(@Hours, 0)) + ''', @Minutes = ''' + CONVERT(VARCHAR(30), ISNULL(@Minutes, 0)) + ''', @Cycles = ''' + CONVERT(VARCHAR(30), ISNULL(@Cycles, 0)) + ''''
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