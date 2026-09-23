/*************************************************************
 ** File:   [USP_SaveLeaseStocklineUsage]
 ** Description: Records Time (TSN) and/or Cycle (CSN) usage readings for a
 **              LeaseStockline in a SINGLE call/SINGLE transaction. @SaveTime
 **              and @SaveCycle are independent flags - either or both can be
 **              1 - and each type has its own From/To reporting period and
 **              its own Notes. @TSNHours/@TSNMinutes (Time) and @CSN (Cycle)
 **              are the LATEST ABSOLUTE reading (e.g. "2:45" total, or "50"
 **              total) - stored directly on LeaseStocklineUsage (one row per
 **              stockline, holding the current Time snapshot AND the current
 **              Cycle snapshot side by side), replacing whatever was there
 **              before. The reading(s) as entered are separately appended to
 **              LeaseStocklineUsageHistory, one row per type saved this call.
 **              Validates: at least one of @SaveTime/@SaveCycle is 1, Entry
 **              Date and the type's own value are mandatory for any type
 **              being saved, no negative Hours/Minutes/CSN, Minutes in
 **              [0,59], usage can only be recorded against an active
 **              (IsActive=1, IsDeleted=0) lease component, From Date and To
 **              Date are mandatory for any type being saved, and each type's
 **              new reading must be strictly greater than that type's last
 **              reported reading (a reading can only move forward).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    15/09/2026     Amit Ghediya            Created
    2    15/09/2026     Amit Ghediya            Reworked: @TSNHours/@TSNMinutes and
                                                 @CSNHours/@CSNMinutes are now the
                                                 incremental amount added this entry,
                                                 summed (with HH:MM carry) into the
                                                 running total on LeaseStocklineUsage,
                                                 instead of overwriting it as an
                                                 absolute reading - removed the
                                                 "new value cannot be less than
                                                 current" guard, which no longer
                                                 applies to an incremental amount
    3    15/09/2026     Amit Ghediya            @Notes is now also stored as
                                                 LatestNotes on LeaseStocklineUsage
                                                 (not just appended to History), so
                                                 the most recent note is available to
                                                 show directly on the Usage Info list
    4    16/09/2026     Kishor Makwana         [PN-17933] Time and Cycle are now fully independent saves: added @UsageType ('T'/'C') and @FromDate/@ToDate; Cycle is now a single @CSN count (dropped @CSNHours/@CSNMinutes); LatestNotes split into LatestTimeNotes/LatestCycleNotes so one type's note never overwrites the other's; added the active-component guard and per-type mandatory-field validation required by PN-17933
    5    16/09/2026     Kishor Makwana         [PN-17933] Reverted to the absolute-reading model per updated requirement: @TSNHours/@TSNMinutes/@CSN are once again stored directly on LeaseStocklineUsage (no summing); From Date/To Date are now mandatory for both Time and Cycle; re-added the "new reading must be strictly greater than the last reported reading" guard for both types
    6    16/09/2026     Kishor Makwana         [PN-17933] Combined Time and Cycle into a SINGLE call: replaced @UsageType with independent @SaveTime/@SaveCycle flags (plus @Time @Cycle params for each type) so one Save click issues one call/one transaction instead of firing two parallel calls that could race each other on the same LeaseStocklineUsage row (unique constraint on LeaseStocklineId). Added WITH (UPDLOCK, HOLDLOCK) on the snapshot read so a second concurrent save for the same stockline is serialized rather than racing.
    7    17/09/2026     Kishor Makwana		   [PN-17967] Captured a single @Now = SYSUTCDATETIME() once per call and reused it for every CreatedDate/UpdatedDate this proc writes (previously each INSERT called GETUTCDATE() separately). This makes the Time-row and Cycle-row that a single combined Save writes to LeaseStocklineUsageHistory share an EXACT, identical CreatedDate - the Usage History popup now uses that exact match to merge them back onto one display line instead of showing them as two unrelated rows.
    8    23/09/2026     Kishor Makwana          [PN-18062] Added @TotalTimeHours/@TotalTimeMinutes/@TotalCycles - manually-entered, informational-only running totals (never derived from/validated against @TSNHours/@TSNMinutes/@CSN or history, do not drive billing). They persist independently of @SaveTime/@SaveCycle (a value is written whenever passed, kept unchanged when NULL - same pattern already used for @Notes), so Total Time/Total Cycles can be saved on their own without also submitting a new Record Time/Record Cycle reading in the same call. Loosened the top guard clause accordingly, and re-verified that CurrentTSNHours/CurrentTSNMinutes/CurrentCSN below are already a plain overwrite (never summed) so "Last Time/Cycle Reported" already shows only the latest reading, not a cumulative total, as PN-18062 requires - no change needed there.
    9    23/09/2026     Kishor Makwana          [PN-18062 follow-up] Removed the "new reading must be greater than the last reported reading" guard for both Time and Cycle - a Record Time/Record Cycle entry can now be saved at any non-negative value, including lower than the last reported reading (matching client-side validation removal in lease-usage-info-entry.component.ts).
    

exec USP_SaveLeaseStocklineUsage @LeaseStocklineId=1,@SaveTime=1, @TimeEntryDate='2026-09-15', @TimeFromDate='2026-09-01', @TimeToDate='2026-09-15',@TSNHours=2, @TSNMinutes=45, @TotalTimeHours=125, @TotalTimeMinutes=15, @SaveCycle=1, @CycleEntryDate='2026-09-15', @CycleFromDate='2026-09-01', @CycleToDate='2026-09-15',	@CSN=50, @TotalCycles=500, @Notes=N'test',@MasterCompanyId=1, @UpdatedBy='test'

************************************************************************/
CREATE     PROCEDURE [dbo].[USP_SaveLeaseStocklineUsage]
	@LeaseStocklineId BIGINT,
	@SaveTime BIT = 0,
	@TimeEntryDate DATETIME2(7) = NULL,
	@TimeFromDate DATETIME2(7) = NULL,
	@TimeToDate DATETIME2(7) = NULL,
	@TSNHours DECIMAL(18,6) = NULL,
	@TSNMinutes DECIMAL(18,6) = NULL,
	@TotalTimeHours DECIMAL(18,6) = NULL,
	@TotalTimeMinutes DECIMAL(18,6) = NULL,
	@SaveCycle BIT = 0,
	@CycleEntryDate DATETIME2(7) = NULL,
	@CycleFromDate DATETIME2(7) = NULL,
	@CycleToDate DATETIME2(7) = NULL,
	@CSN DECIMAL(18,6) = NULL,
	@TotalCycles DECIMAL(18,6) = NULL,
	@Notes NVARCHAR(MAX) = NULL,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Basic validation - guard clauses, raised before the transaction starts
	IF (ISNULL(@SaveTime,0) = 0 AND ISNULL(@SaveCycle,0) = 0
		AND @TotalTimeHours IS NULL AND @TotalTimeMinutes IS NULL AND @TotalCycles IS NULL)
	BEGIN
		RAISERROR ('Enter a Time or Cycle reading, or a Total Time/Total Cycles value, to save.', 16, 1);
		RETURN (1);
	END

	IF (@SaveTime = 1 AND @TimeEntryDate IS NULL)
	BEGIN
		RAISERROR ('Entry Date is required for a Time entry.', 16, 1);
		RETURN (1);
	END

	IF (@SaveCycle = 1 AND @CycleEntryDate IS NULL)
	BEGIN
		RAISERROR ('Entry Date is required for a Cycle entry.', 16, 1);
		RETURN (1);
	END

	IF (@SaveTime = 1 AND @TSNHours IS NULL AND @TSNMinutes IS NULL)
	BEGIN
		RAISERROR ('TSN is required for a Time entry.', 16, 1);
		RETURN (1);
	END

	IF (@SaveCycle = 1 AND @CSN IS NULL)
	BEGIN
		RAISERROR ('CSN is required for a Cycle entry.', 16, 1);
		RETURN (1);
	END

	IF (ISNULL(@TSNHours,0) < 0 OR ISNULL(@TSNMinutes,0) < 0 OR ISNULL(@CSN,0) < 0)
	BEGIN
		RAISERROR ('Time and Cycle values cannot be negative.', 16, 1);
		RETURN (1);
	END

	IF (ISNULL(@TSNMinutes,0) > 59)
	BEGIN
		RAISERROR ('Minutes must be between 0 and 59.', 16, 1);
		RETURN (1);
	END

	IF (ISNULL(@TotalTimeHours,0) < 0 OR ISNULL(@TotalTimeMinutes,0) < 0 OR ISNULL(@TotalCycles,0) < 0)
	BEGIN
		RAISERROR ('Total Time and Total Cycles cannot be negative.', 16, 1);
		RETURN (1);
	END

	IF (ISNULL(@TotalTimeMinutes,0) > 59)
	BEGIN
		RAISERROR ('Total Time minutes must be between 0 and 59.', 16, 1);
		RETURN (1);
	END

	IF (@SaveTime = 1 AND (@TimeFromDate IS NULL OR @TimeToDate IS NULL))
	BEGIN
		RAISERROR ('From Date and To Date are required for a Time entry.', 16, 1);
		RETURN (1);
	END

	IF (@SaveCycle = 1 AND (@CycleFromDate IS NULL OR @CycleToDate IS NULL))
	BEGIN
		RAISERROR ('From Date and To Date are required for a Cycle entry.', 16, 1);
		RETURN (1);
	END

	IF NOT EXISTS (
		SELECT 1 FROM [dbo].[LeaseStockline] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsActive = 1 AND IsDeleted = 0
	)
	BEGIN
		RAISERROR ('Usage can only be recorded for an active lease component.', 16, 1);
		RETURN (1);
	END

	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

		DECLARE @HasSnapshotRow BIT = 0;
		DECLARE @CurrentTSNHours DECIMAL(18,6) = NULL;
		DECLARE @CurrentTSNMinutes DECIMAL(18,6) = NULL;
		DECLARE @CurrentCSN DECIMAL(18,6) = NULL;

		SELECT
			@HasSnapshotRow = 1,
			@CurrentTSNHours = CurrentTSNHours,
			@CurrentTSNMinutes = CurrentTSNMinutes,
			@CurrentCSN = CurrentCSN
		FROM [dbo].[LeaseStocklineUsage] WITH (UPDLOCK, HOLDLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;

		-- [PN-18062 follow-up] The "new reading must be greater than the last reported reading"
		-- guard (for both Time and Cycle) was removed here - a Record Time/Record Cycle entry
		-- can now be any non-negative value, including lower than the last reported reading.
		-- Matching guard also removed client-side in lease-usage-info-entry.component.ts
		-- (isNewTimeGreaterThanCurrent()/isNewCycleGreaterThanCurrent(), called from save()).

		IF (@HasSnapshotRow = 1)
		BEGIN
			UPDATE [dbo].[LeaseStocklineUsage]
			SET CurrentTSNHours    = CASE WHEN @SaveTime = 1 THEN ISNULL(@TSNHours,0) ELSE CurrentTSNHours END,
				CurrentTSNMinutes  = CASE WHEN @SaveTime = 1 THEN ISNULL(@TSNMinutes,0) ELSE CurrentTSNMinutes END,
				CurrentTSNFromDate = CASE WHEN @SaveTime = 1 THEN @TimeFromDate ELSE CurrentTSNFromDate END,
				CurrentTSNToDate   = CASE WHEN @SaveTime = 1 THEN @TimeToDate ELSE CurrentTSNToDate END,
				CurrentTSNDate     = CASE WHEN @SaveTime = 1 THEN @TimeEntryDate ELSE CurrentTSNDate END,
				TotalTimeHours     = COALESCE(@TotalTimeHours, TotalTimeHours),
				TotalTimeMinutes   = COALESCE(@TotalTimeMinutes, TotalTimeMinutes),
				CurrentCSN         = CASE WHEN @SaveCycle = 1 THEN ISNULL(@CSN,0) ELSE CurrentCSN END,
				CurrentCSNFromDate = CASE WHEN @SaveCycle = 1 THEN @CycleFromDate ELSE CurrentCSNFromDate END,
				CurrentCSNToDate   = CASE WHEN @SaveCycle = 1 THEN @CycleToDate ELSE CurrentCSNToDate END,
				CurrentCSNDate     = CASE WHEN @SaveCycle = 1 THEN @CycleEntryDate ELSE CurrentCSNDate END,
				TotalCycles        = COALESCE(@TotalCycles, TotalCycles),
				--Notes              = @Notes,
				Notes = CASE WHEN @Notes IS NOT NULL AND LTRIM(RTRIM(@Notes)) <> '' THEN @Notes ELSE Notes END,
				UpdatedBy          = @UpdatedBy,
				UpdatedDate        = @Now
			WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;

			
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[LeaseStocklineUsage]
				(LeaseStocklineId, CurrentTSNHours, CurrentTSNMinutes, CurrentTSNFromDate, CurrentTSNToDate, CurrentTSNDate,
				 TotalTimeHours, TotalTimeMinutes,
				 CurrentCSN, CurrentCSNFromDate, CurrentCSNToDate, CurrentCSNDate,
				 TotalCycles, Notes,
				 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES
				(@LeaseStocklineId,
				 CASE WHEN @SaveTime = 1 THEN ISNULL(@TSNHours,0) ELSE NULL END,
				 CASE WHEN @SaveTime = 1 THEN ISNULL(@TSNMinutes,0) ELSE NULL END,
				 CASE WHEN @SaveTime = 1 THEN @TimeFromDate ELSE NULL END,
				 CASE WHEN @SaveTime = 1 THEN @TimeToDate ELSE NULL END,
				 CASE WHEN @SaveTime = 1 THEN @TimeEntryDate ELSE NULL END,
				 @TotalTimeHours,
				 @TotalTimeMinutes,
				 CASE WHEN @SaveCycle = 1 THEN ISNULL(@CSN,0) ELSE NULL END,
				 CASE WHEN @SaveCycle = 1 THEN @CycleFromDate ELSE NULL END,
				 CASE WHEN @SaveCycle = 1 THEN @CycleToDate ELSE NULL END,
				 CASE WHEN @SaveCycle = 1 THEN @CycleEntryDate ELSE NULL END,
				 @TotalCycles,
				 @Notes,
				 @MasterCompanyId, @UpdatedBy, @UpdatedBy, @Now, @Now, 1, 0);
		END

		IF (@SaveTime = 1)
		BEGIN
			INSERT INTO [dbo].[LeaseStocklineUsageHistory]
				(LeaseStocklineId, UsageType, EntryDate, FromDate, ToDate, TSNHours, TSNMinutes, CSN, Notes,
				 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES
				(@LeaseStocklineId, 'T', @TimeEntryDate, @TimeFromDate, @TimeToDate, @TSNHours, @TSNMinutes, NULL, @Notes,
				 @MasterCompanyId, @UpdatedBy, @UpdatedBy, @Now, @Now, 1, 0);
		END

		IF (@SaveCycle = 1)
		BEGIN
			INSERT INTO [dbo].[LeaseStocklineUsageHistory]
				(LeaseStocklineId, UsageType, EntryDate, FromDate, ToDate, TSNHours, TSNMinutes, CSN, Notes,
				 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES
				(@LeaseStocklineId, 'C', @CycleEntryDate, @CycleFromDate, @CycleToDate, NULL, NULL, @CSN, @Notes,
				 @MasterCompanyId, @UpdatedBy, @UpdatedBy, @Now, @Now, 1, 0);
		END

		SELECT LeaseStocklineId,
			CurrentTSNHours, CurrentTSNMinutes, CurrentTSNFromDate, CurrentTSNToDate, CurrentTSNDate,
			TotalTimeHours, TotalTimeMinutes,
			CurrentCSN, CurrentCSNFromDate, CurrentCSNToDate, CurrentCSNDate,
			TotalCycles, Notes,
			UpdatedBy, UpdatedDate
		FROM [dbo].[LeaseStocklineUsage] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_SaveLeaseStocklineUsage]',
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