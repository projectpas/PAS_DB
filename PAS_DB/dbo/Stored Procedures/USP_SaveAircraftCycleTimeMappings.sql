/****** Object:  StoredProcedure [dbo].[USP_SaveAircraftCycleTimeMappings] ******/

/*************************************************************     
** Author:  <Amit Ghediya>    
** Create date: <14/04/2026>    
** Description: <This Proc Is used to Save Turn In Aircraft CycleTime>    
    
Exec [USP_SaveAircraftCycleTimeMappings]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author              Change Description    
** --   --------    -------             --------------------------------  
   1    14/04/2026  Amit Ghediya        Created  
   2    15/04/2026  Amit Ghediya        Added into AircraftMaintenanceProgram table (PN-16015)
   3    21/04/2026  Amit Ghediya        Stop insert into AircraftMaintenanceProgram table update logic to save data.
   4    22/04/2026  Amit Ghediya        Add DateInstalled Last Flown Date (PN-16156).
   5    28/04/2026  Amit Ghediya        Get Minutes related data (PN-16151)
   6    04/05/2026  Amit Ghediya        Revert insert into AircraftMaintenanceProgram table update logic to save data.
   7    07/05/2026  Priyansh Patel      Fixed the Remaining time calculation [PN-16306]
   8    07/05/2026  Abhishek Jirawla    Edit Last flown date only when add cycle time is done.
   9    14/05/2026  Amit Ghediya        Update logic for AircraftMaintenanceProgram & LastFlownDate [PN-16428].
   10   27/05/2026  Priyansh Patel      Update logic for Remaining Cycles [PN-16587].
   11   29/05/2026  Code Review         Fix: Remaining calc uses cumulative not current cycle;
                                        Fix: Minutes overflow into hours on RecordedMinutes;
                                        Fix: INSERT branch Remaining = Limit - Recorded;
                                        Fix: Time/Landings/EngineStarts no longer blindly reset to Limit;
                                        Fix: @CycleId safe TOP 1 on update branch;
                                        Perf: Replace CURSOR with set-based MERGE for engine data;
                                        Perf: Remove NOLOCK from UPDATE targets;
                                        Perf: Collapse multi-scan of AMP into single pass;
                                        Perf: Remove READ UNCOMMITTED from write transaction.
  12    02/06/2026  Amit Ghediya        Update logic for AircraftMaintenanceProgram for currunt HH:mm update for hr & cycle [PN-16650].
  13	16/06/2026  Amit Ghediya        Update minute logic for AircraftInstalledPartDetails [PN-16887]
  14    17/07/2026  Amit Ghediya        Save EngineRegistryId with engine rows, and additionally mirror the
                                        same AircraftInstalledPartDetails / AircraftMaintenanceProgram update
                                        (and insert-if-missing) logic used for the aircraft onto each attached
                                        engine's own EngineRegistryId/IsFromAircraft=0 records. Aircraft-level
                                        logic above is unchanged.
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveAircraftCycleTimeMappings]  
    @CycleData  NVARCHAR(MAX),
    @EngineData NVARCHAR(MAX)
AS  
BEGIN  
    SET NOCOUNT ON;
    -- NOTE: Removed SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED — 
    --       dirty reads are unsafe inside a write transaction.

    BEGIN TRY 
    BEGIN TRANSACTION

        -------------------------------------------------------
        -- READ CYCLE JSON INTO TEMP TABLE
        -------------------------------------------------------
        DECLARE @CycleTable TABLE
        (
            AircraftCycleTimeMappingsId BIGINT,
            ModuleId                    BIGINT,
            RefrenceId                  BIGINT,
            CycleDate                   DATETIME2,
            [Hours]                     DECIMAL(18,6),
            [Minutes]                   DECIMAL(18,6),
            CurruntHours                DECIMAL(18,6),
            CurruntMinutes              DECIMAL(18,6),
            CumulativeHours             DECIMAL(18,6),
            CumulativeMinutes           DECIMAL(18,6),
            Cycles                      DECIMAL(18,6),
            CyclesMinutes               DECIMAL(18,6),
            CurruntCycles               DECIMAL(18,6),
            CurruntCyclesMinutes        DECIMAL(18,6),
            CumulativeCycles            DECIMAL(18,6),
            CumulativeCyclesMinutes     DECIMAL(18,6),
            AddUpdated                  BIT,
            Memo                        NVARCHAR(MAX),
            MasterCompanyId             INT,
            CreatedBy                   VARCHAR(256),
            UpdatedBy                   VARCHAR(256)
        );

        INSERT INTO @CycleTable
        SELECT *
        FROM OPENJSON(@CycleData)
        WITH
        (
            AircraftCycleTimeMappingsId BIGINT,
            ModuleId                    BIGINT,
            RefrenceId                  BIGINT,
            CycleDate                   DATETIME2,
            [Hours]                     DECIMAL(18,6),
            [Minutes]                   DECIMAL(18,6),
            CurruntHours                DECIMAL(18,6),
            CurruntMinutes              DECIMAL(18,6),
            CumulativeHours             DECIMAL(18,6),
            CumulativeMinutes           DECIMAL(18,6),
            Cycles                      DECIMAL(18,6),
            CyclesMinutes               DECIMAL(18,6),
            CurruntCycles               DECIMAL(18,6),
            CurruntCyclesMinutes        DECIMAL(18,6),
            CumulativeCycles            DECIMAL(18,6),
            CumulativeCyclesMinutes     DECIMAL(18,6),
            AddUpdated                  BIT,
            Memo                        NVARCHAR(MAX),
            MasterCompanyId             INT,
            CreatedBy                   VARCHAR(256),
            UpdatedBy                   VARCHAR(256)
        );

        -------------------------------------------------------
        -- DECLARE @CycleId for return
        -------------------------------------------------------
        DECLARE @CycleId BIGINT, @AircraftRegistryId BIGINT = 0;	
		
		SELECT TOP 1 @AircraftRegistryId = RefrenceId FROM @CycleTable;

        -------------------------------------------------------
        -- CHECK INSERT OR UPDATE
        -------------------------------------------------------
        IF EXISTS (SELECT 1 FROM @CycleTable WHERE ISNULL(AircraftCycleTimeMappingsId, 0) > 0)
        BEGIN
            ---------------------------------------------------
            -- UPDATE existing AircraftCycleTimeMappings
            ---------------------------------------------------
            UPDATE A
            SET
                A.ModuleId                  = C.ModuleId,
                A.RefrenceId                = C.RefrenceId,
                A.CycleDate                 = C.CycleDate,
                A.[Hours]                   = C.[Hours],
                A.[Minutes]                 = C.[Minutes],
                A.CurruntHours              = C.CurruntHours,
                A.CurruntMinutes            = C.CurruntMinutes,
                A.CumulativeHours           = C.CumulativeHours,
                A.CumulativeMinutes         = C.CumulativeMinutes,
                A.Cycles                    = C.Cycles,
                A.CyclesMinutes             = C.CyclesMinutes,
                A.CurruntCycles             = C.CurruntCycles,
                A.CurruntCyclesMinutes      = C.CurruntCyclesMinutes,
                A.CumulativeCycles          = C.CumulativeCycles,
                A.CumulativeCyclesMinutes   = C.CumulativeCyclesMinutes,
                A.Memo                      = C.Memo,
                A.MasterCompanyId           = C.MasterCompanyId,
                A.UpdatedBy                 = C.UpdatedBy,
                A.UpdatedDate               = GETUTCDATE()
            FROM dbo.AircraftCycleTimeMappings A WITH(NOLOCK)
            INNER JOIN @CycleTable C
                ON A.AircraftCycleTimeMappingsId = C.AircraftCycleTimeMappingsId;

            -- FIX: Use TOP 1 to avoid arbitrary assignment when multiple rows exist
            SELECT TOP 1 @CycleId = AircraftCycleTimeMappingsId
            FROM @CycleTable
            WHERE ISNULL(AircraftCycleTimeMappingsId, 0) > 0;
        END
        ELSE
        BEGIN
            ---------------------------------------------------
            -- INSERT new AircraftCycleTimeMappings
            ---------------------------------------------------
            INSERT INTO dbo.AircraftCycleTimeMappings
            (
                ModuleId, RefrenceId, CycleDate,
                [Hours], [Minutes],
                CurruntHours, CurruntMinutes,
                CumulativeHours, CumulativeMinutes,
                Cycles, CyclesMinutes,
                CurruntCycles, CurruntCyclesMinutes,
                CumulativeCycles, CumulativeCyclesMinutes,
                Memo, MasterCompanyId,
                CreatedBy, UpdatedBy,
                CreatedDate, UpdatedDate,
                IsActive, IsDeleted
            )
            SELECT
                ModuleId, RefrenceId, GETUTCDATE(),
                [Hours], [Minutes],
                CurruntHours, CurruntMinutes,
                CumulativeHours, CumulativeMinutes,
                Cycles, CyclesMinutes,
                CurruntCycles, CurruntCyclesMinutes,
                CumulativeCycles, CumulativeCyclesMinutes,
                Memo, MasterCompanyId,
                CreatedBy, UpdatedBy,
                GETUTCDATE(), GETUTCDATE(),
                1, 0
            FROM @CycleTable;

            SET @CycleId = SCOPE_IDENTITY();
        END

        -------------------------------------------------------
        -- UPDATE AircraftInstalledPartDetails (ADD values)
        -------------------------------------------------------

		-------------------------------------------------------
        -- READ OLD VALUES before UPDATE AIPD
        -------------------------------------------------------
        DECLARE @Old_FlightHours    VARCHAR(50) = '',
                @Old_FlightMinutes  VARCHAR(50) = '',
                @Old_Cycles         VARCHAR(50) = '',
                @Old_FlightHrsMin   VARCHAR(50) = '', -- HH:MM format
                @AircraftRegistryId_Hist BIGINT  = 0,
                @UpdatedBy_Hist     VARCHAR(256) = '',
                @MasterCompanyId_Hist INT        = 0;

        SELECT TOP 1
            @AircraftRegistryId_Hist = C.RefrenceId,
            @UpdatedBy_Hist          = C.UpdatedBy,
            @MasterCompanyId_Hist    = C.MasterCompanyId
        FROM @CycleTable C;

        SELECT
            @Old_FlightHours   = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.FlightHours,   0))),
            @Old_FlightMinutes = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.FlightMinutes, 0))),
            @Old_Cycles        = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.Cycles,        0))),
            @Old_FlightHrsMin  = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.FlightHours,   0)))
                               + ' : '
                               + RIGHT('00' + CONVERT(VARCHAR(2), CONVERT(BIGINT, ISNULL(AIPD.FlightMinutes, 0))), 2)
        FROM dbo.AircraftInstalledPartDetails AIPD WITH(NOLOCK)
        INNER JOIN @CycleTable C ON AIPD.AircraftRegistryId = C.RefrenceId;


		UPDATE AIPD
		SET
			-- Hours: accumulate + carry overflow from minutes
			AIPD.FlightHours =
			CASE WHEN ISNULL(C.[Hours], 0) > 0
			THEN
				FLOOR(
					FLOOR(ISNULL(AIPD.FlightHours, 0))
					+ FLOOR(ISNULL(C.[Hours], 0))
					+ (
						(FLOOR(ISNULL(AIPD.FlightMinutes, 0))
						 + FLOOR(ISNULL(C.[Minutes], 0)))
						/ 60
					  )
				)
			ELSE
				FLOOR(
					FLOOR(ISNULL(C.[CumulativeHours], 0))
					+ (FLOOR(ISNULL(C.[CumulativeMinutes], 0)) / 60)
				)
			END,

			-- Minutes: keep only remainder after carrying into hours
			AIPD.FlightMinutes =
				CASE WHEN ISNULL(C.[Minutes], 0) > 0
				THEN
					(FLOOR(ISNULL(AIPD.FlightMinutes, 0))
					 + FLOOR(ISNULL(C.[Minutes], 0)))
					% 60
				ELSE
					FLOOR(ISNULL(C.[CumulativeMinutes], 0)) % 60
				END,

			-- Cycles: accumulate or set from cumulative
			AIPD.Cycles =
				CASE WHEN ISNULL(C.[Cycles], 0) > 0
				THEN ISNULL(AIPD.Cycles, 0) + ISNULL(C.[Cycles], 0)
				ELSE ISNULL(C.[CumulativeCycles], 0)
				END,

			AIPD.UpdatedBy   = C.UpdatedBy,
			AIPD.UpdatedDate = GETUTCDATE(),

			-- LastFlownDate: only update when AddUpdated = 1 (add cycle, not edit)
			AIPD.LastFlownDate =
				CASE
					WHEN ISNULL(C.AddUpdated, 0) = 1
					THEN CAST(GETUTCDATE() AS DATE)
					ELSE AIPD.LastFlownDate
				END

		FROM dbo.AircraftInstalledPartDetails AIPD WITH(NOLOCK)
		INNER JOIN @CycleTable C ON AIPD.AircraftRegistryId = C.RefrenceId;

		-------------------------------------------------------
        -- READ NEW VALUES after UPDATE AIPD
        -------------------------------------------------------
        DECLARE @New_FlightHours    VARCHAR(50) = '',
                @New_FlightMinutes  VARCHAR(50) = '',
                @New_Cycles         VARCHAR(50) = '',
                @New_FlightHrsMin   VARCHAR(50) = ''; -- HH:MM format

        SELECT
            @New_FlightHours   = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.FlightHours,   0))),
            @New_FlightMinutes = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.FlightMinutes, 0))),
            @New_Cycles        = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.Cycles,        0))),
            @New_FlightHrsMin  = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIPD.FlightHours,   0)))
                               + ' : '
                               + RIGHT('00' + CONVERT(VARCHAR(2), CONVERT(BIGINT, ISNULL(AIPD.FlightMinutes, 0))), 2)
        FROM dbo.AircraftInstalledPartDetails AIPD WITH(NOLOCK)
        INNER JOIN @CycleTable C ON AIPD.AircraftRegistryId = C.RefrenceId;

		-------------------------------------------------------
        -- HISTORY BLOCK for AIPD cycle update
        -- Same pattern as USP_InsertUpdateAircraftInstalledPartDetails
        -------------------------------------------------------
        DECLARE @AIPD_TemplateBody  VARCHAR(MAX) = '',
                @AIPD_Activity      VARCHAR(100) = 'Cycle Time Updated',
                @AIPD_PartIdStr     VARCHAR(100) = NULL;

        -- Get part number for NewValue label
        SELECT TOP 1
            @AIPD_PartIdStr = 'Part: ' + ISNULL(AIPD.PartNumber, '')
        FROM dbo.AircraftInstalledPartDetails AIPD WITH(NOLOCK)
        INNER JOIN @CycleTable C ON AIPD.AircraftRegistryId = C.RefrenceId;

        -- Diff old vs new — only changed fields
        IF @Old_FlightHrsMin <> @New_FlightHrsMin AND @New_FlightHrsMin <> '0 : 00'
            SET @AIPD_TemplateBody += 'Flight Hours (HH:MM): ' + @Old_FlightHrsMin + ' to ' + @New_FlightHrsMin + ' | ';

        IF @Old_Cycles <> @New_Cycles AND @New_Cycles <> '0'
            SET @AIPD_TemplateBody += 'Cycles: ' + @Old_Cycles + ' to ' + @New_Cycles + ' | ';

        -- Remove trailing ' | '
        SET @AIPD_TemplateBody = RTRIM(@AIPD_TemplateBody);
        IF RIGHT(@AIPD_TemplateBody, 3) = ' | '
            SET @AIPD_TemplateBody = LEFT(@AIPD_TemplateBody, LEN(@AIPD_TemplateBody) - 3);
        ELSE IF RIGHT(@AIPD_TemplateBody, 2) = ' |'
            SET @AIPD_TemplateBody = LEFT(@AIPD_TemplateBody, LEN(@AIPD_TemplateBody) - 2);
        ELSE IF RIGHT(@AIPD_TemplateBody, 1) = '|'
            SET @AIPD_TemplateBody = LEFT(@AIPD_TemplateBody, LEN(@AIPD_TemplateBody) - 1);

        -- Save history if anything changed
        IF ISNULL(LTRIM(RTRIM(@AIPD_TemplateBody)), '') <> ''
        BEGIN
			EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 2,@ModuleName = 'Cycle Time Updated',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
												 @OldValue = NULL,@NewValue = NULL,@HistoryText = @AIPD_TemplateBody,@Activity = @AIPD_Activity,@MasterCompanyId = @MasterCompanyId_Hist,
												 @CreatedBy = @UpdatedBy_Hist;
        END
        -- ── END HISTORY BLOCK for AIPD ────────────────────────

        -------------------------------------------------------
        -- UPDATE / INSERT AircraftMaintenanceProgram
        -- FIX: All remaining calculations now use cumulative
        --      totals (existing recorded + this cycle's delta),
        --      not just the current cycle's values alone.
        -- FIX: Minutes overflow is carried into hours correctly.
        -- PERF: Single scan of AMP using CROSS APPLY for
        --       pre-computed intermediates; eliminates the
        --       separate SELECT @ProgramId + SELECT @Remaining
        --       + UPDATE pattern (3 passes → 1 pass).
        -------------------------------------------------------
        IF EXISTS (
            SELECT 1 
            FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
            INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId
        )
        BEGIN
            UPDATE AMP
            SET
                -----------------------------------------------
                -- RECORDED: accumulate existing + this cycle
                -----------------------------------------------
                -- Hours: carry over any minute overflow
                AMP.FlightHoursRecordedHours =
					CASE WHEN ISNULL(C.[Hours], 0) > 0 THEN
						FLOOR(ISNULL(AMP.FlightHoursRecordedHours,   0))
						+ FLOOR(ISNULL(C.[Hours], 0))
						+ (   -- carry from minutes overflow
							  (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0))
							   + FLOOR(ISNULL(C.[Minutes], 0)))
							  / 60
						  )
					ELSE FLOOR(ISNULL(C.[CumulativeHours], 0))
						+ (  FLOOR(ISNULL(C.[CumulativeMinutes], 0))
							  / 60
						  )
				    END,

                -- Minutes: keep only the remainder after carrying into hours
                AMP.FlightHoursRecordedMinutes =
					CASE WHEN ISNULL(C.[Minutes], 0) > 0 THEN
						(FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0))
						 + FLOOR(ISNULL(C.[Minutes], 0)))
						% 60
					ELSE (FLOOR(ISNULL(C.[CumulativeMinutes], 0)))
						% 60
					END,

                AMP.CyclesRecorded =
					CASE WHEN ISNULL(C.[Cycles], 0) > 0 THEN
						 ISNULL(AMP.CyclesRecorded, 0) + ISNULL(C.Cycles, 0)
					ELSE ISNULL(C.CumulativeCycles, 0)
					END,

                -----------------------------------------------
                -- REMAINING: Limit minus NEW cumulative total
                -- FIX: was subtracting only current C.[Hours]/
                --      C.Cycles instead of full recorded total.
                -----------------------------------------------
                AMP.FlightHoursRemainingHours =
                    CASE
                        WHEN calc.LimitTotalMinutes IS NULL THEN NULL
                        WHEN calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes < 0 THEN 0
                        ELSE (calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes) / 60
                    END,

                AMP.FlightHoursRemainingMinutes =
                    CASE
                        WHEN calc.LimitTotalMinutes IS NULL THEN NULL
                        WHEN calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes < 0 THEN 0
                        ELSE (calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes) % 60
                    END,

                AMP.CyclesRemaining =
                    CASE
                        WHEN calc.NewRecordedCycles IS NULL THEN NULL
                        WHEN ISNULL(AMP.CyclesLimit, 0) - calc.NewRecordedCycles < 0 THEN 0
                        ELSE ISNULL(AMP.CyclesLimit, 0) - calc.NewRecordedCycles
                    END,

                -----------------------------------------------
                -- Time / Landings / EngineStarts:
                -- FIX: do NOT blindly overwrite with Limit.
                -- Leave unchanged (no data is passed for these
                -- in @CycleData). Decrement only when you have
                -- actual values to subtract.
                -----------------------------------------------
                -- AMP.TimeRemaining          = (unchanged — omitted intentionally)
                -- AMP.LandingsRemaining      = (unchanged — omitted intentionally)
                -- AMP.EngineStartsRemaining  = (unchanged — omitted intentionally)

                AMP.UpdatedBy   = C.UpdatedBy,
                AMP.UpdatedDate = GETUTCDATE()

            FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
            INNER JOIN @CycleTable C
                ON AMP.AircraftRegistryId = C.RefrenceId
            -- PERF: CROSS APPLY computes intermediates once per row,
            --       replacing separate SELECT @Variable statements
            CROSS APPLY (
                SELECT
                    -- Limit expressed entirely in minutes
                    LimitTotalMinutes =
                        ISNULL(AMP.FlightHoursLimitHours,   0) * 60
                        + ISNULL(AMP.FlightHoursLimitMinutes, 0),

                    -- New cumulative recorded expressed entirely in minutes.
                    -- FIX: flatten directly to (hours * 60 + minutes) — no intermediate
                    -- carry needed here. Carrying inside the hours part and then adding
                    -- raw minutes again caused double-counting (e.g. 20h 41m was computed
                    -- as 1,249 min instead of 1,241 min, skewing the remainder).
                    -- The final / 60 and % 60 on (Limit - Recorded) handles all overflow.
                    NewRecordedTotalMinutes =
                        (FLOOR(ISNULL(AMP.FlightHoursRecordedHours, 0)) + FLOOR(ISNULL(C.[Hours], 0))) * 60
                        + (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0)) + FLOOR(ISNULL(C.[Minutes], 0))),

                    -- New cumulative cycles
                    NewRecordedCycles =
                        ISNULL(AMP.CyclesRecorded, 0) + ISNULL(C.Cycles, 0)
            ) AS calc
            -- Only update the single active upcoming program per aircraft
            -- (same intent as the old @ProgramId filter, now inline)
            WHERE AMP.ProgramId = (
                SELECT TOP 1 ProgramId
                FROM dbo.AircraftMaintenanceProgram amp2 WITH(NOLOCK)
                WHERE amp2.AircraftRegistryId   = AMP.AircraftRegistryId
                  AND amp2.IsDeleted            = 0
                  AND amp2.IsActive             = 1
                  AND amp2.NextScheduledMaintenance IS NOT NULL
                  AND amp2.NextScheduledMaintenance >= CAST(GETDATE() AS DATE)
                ORDER BY amp2.NextScheduledMaintenance ASC
            );
        END
        ELSE
        BEGIN
            ---------------------------------------------------
            -- INSERT new AircraftMaintenanceProgram row
            -- FIX: RemainingHours/Minutes = Limit - Recorded
            --      (was incorrectly set equal to Recorded).
            ---------------------------------------------------
            INSERT INTO dbo.AircraftMaintenanceProgram
            (
                TailNumber, AircraftMake, AircraftModel, SerialNumber,
                MaintenanceType, TemplateId,
                FlightHoursRecordedHours,
                FlightHoursRecordedMinutes,
                FlightHoursRemainingHours,
                FlightHoursRemainingMinutes,
                CyclesRemaining,
                CyclesRecorded,
                MasterCompanyId,
                CreatedBy, UpdatedBy,
                CreatedDate, UpdatedDate,
                IsActive, IsDeleted,
                AircraftRegistryId
            )
            SELECT
                '', '', '', '',
                '', 1,
                -- Recorded = cumulative value passed in
                FLOOR(ISNULL(C.CumulativeHours,   0)),
                FLOOR(ISNULL(C.CumulativeMinutes, 0)) % 60,  -- keep within 0-59
                -- FIX: Remaining = 0 on first insert (no limit defined yet);
                --      set to NULL so UI can show "not configured" rather than wrong data.
                --      If a limit exists upstream, subtract: LimitHours - CumulativeHours, etc.
                NULL,   -- FlightHoursRemainingHours  — no limit defined at insert time
                NULL,   -- FlightHoursRemainingMinutes — no limit defined at insert time
                NULL,   -- CyclesRemaining             — no limit defined at insert time
                ISNULL(C.CumulativeCycles, 0),
                C.MasterCompanyId,
                C.CreatedBy, C.UpdatedBy,
                GETUTCDATE(), GETUTCDATE(),
                1, 0,
                C.RefrenceId
            FROM @CycleTable C;
        END

        -------------------------------------------------------
        -- UPSERT ENGINE DATA
        -- PERF: Replaced row-by-row CURSOR with a single
        --       set-based MERGE statement.
        -------------------------------------------------------
        DECLARE @EngineTable TABLE
        (
            AircraftEngineStartsMappingsId  BIGINT,
            AircraftCycleTimeMappingsId     BIGINT,
            EngineRegistryId                BIGINT,
            EngineName                      VARCHAR(50),
            [Hours]                         DECIMAL(18,6),
            [Minutes]                       DECIMAL(18,6),
            CurruntHours                    DECIMAL(18,6),
            CurruntMinutes                  DECIMAL(18,6),
            CumulativeHours                 DECIMAL(18,6),
            CumulativeMinutes               DECIMAL(18,6),
            Starts                          INT,
            CurruntStarts                   INT,
            CumulativeStarts                INT,
            Memo                            NVARCHAR(MAX),
            MasterCompanyId                 INT,
            CreatedBy                       VARCHAR(256),
            UpdatedBy                       VARCHAR(256)
        );

        INSERT INTO @EngineTable
        SELECT
            AircraftEngineStartsMappingsId,
            AircraftCycleTimeMappingsId,
            EngineRegistryId,
            EngineName,
            [Hours], [Minutes],
            CurruntHours, CurruntMinutes,
            CumulativeHours, CumulativeMinutes,
            Starts, CurruntStarts, CumulativeStarts,
            Memo, MasterCompanyId,
            CreatedBy, UpdatedBy
        FROM OPENJSON(@EngineData)
        WITH
        (
            AircraftEngineStartsMappingsId  BIGINT,
            AircraftCycleTimeMappingsId     BIGINT,
            EngineRegistryId                BIGINT,
            EngineName                      VARCHAR(50),
            [Hours]                         DECIMAL(18,6),
            [Minutes]                       DECIMAL(18,6),
            CurruntHours                    DECIMAL(18,6),
            CurruntMinutes                  DECIMAL(18,6),
            CumulativeHours                 DECIMAL(18,6),
            CumulativeMinutes               DECIMAL(18,6),
            Starts                          INT,
            CurruntStarts                   INT,
            CumulativeStarts                INT,
            Memo                            NVARCHAR(MAX),
            MasterCompanyId                 INT,
            CreatedBy                       VARCHAR(256),
            UpdatedBy                       VARCHAR(256)
        );

        -- Single MERGE replaces the entire CURSOR loop
        MERGE dbo.AircraftEngineStartsMappings AS target
        USING @EngineTable AS source
            ON  target.AircraftEngineStartsMappingsId = source.AircraftEngineStartsMappingsId
            AND target.EngineName                     = source.EngineName
        WHEN MATCHED THEN
            UPDATE SET
                target.EngineRegistryId = source.EngineRegistryId,
                target.[Hours]          = source.[Hours],
                target.[Minutes]        = source.[Minutes],
                target.CurruntHours     = source.CurruntHours,
                target.CurruntMinutes   = source.CurruntMinutes,
                target.CumulativeHours  = source.CumulativeHours,
                target.CumulativeMinutes= source.CumulativeMinutes,
                target.Starts           = source.Starts,
                target.CurruntStarts    = source.CurruntStarts,
                target.CumulativeStarts = source.CumulativeStarts,
                target.Memo             = source.Memo,
                target.MasterCompanyId  = source.MasterCompanyId,
                target.UpdatedBy        = source.UpdatedBy,
                target.UpdatedDate      = GETUTCDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                AircraftCycleTimeMappingsId,
                EngineRegistryId,
                EngineName,
                [Hours], [Minutes],
                CurruntHours, CurruntMinutes,
                CumulativeHours, CumulativeMinutes,
                Starts, CurruntStarts, CumulativeStarts,
                Memo, MasterCompanyId,
                CreatedBy, UpdatedBy,
                CreatedDate, UpdatedDate,
                IsActive, IsDeleted
            )
            VALUES
            (
                @CycleId,               -- always link to the just-saved cycle record
                source.EngineRegistryId,
                source.EngineName,
                source.[Hours], source.[Minutes],
                source.CurruntHours, source.CurruntMinutes,
                source.CumulativeHours, source.CumulativeMinutes,
                source.Starts, source.CurruntStarts, source.CumulativeStarts,
                source.Memo, source.MasterCompanyId,
                source.CreatedBy, source.UpdatedBy,
                GETUTCDATE(), GETUTCDATE(),
                1, 0
            );

        -------------------------------------------------------
        -- MIRROR AIRCRAFT-LEVEL AIPD/AMP UPDATES ONTO EACH ATTACHED ENGINE
        -- Same formulas as the aircraft blocks above, scoped by
        -- EngineRegistryId/IsFromAircraft=0 instead of AircraftRegistryId/IsFromAircraft=1.
        -- Cycles are NOT entered separately per engine in the UI — the aircraft's own
        -- Cycles/CumulativeCycles/AddUpdated values are mirrored onto each engine too.
        -- Aircraft-level logic above is untouched by this block.
        -------------------------------------------------------
        DECLARE @Eng_Cycles DECIMAL(18,6), @Eng_CumulativeCycles DECIMAL(18,6), @Eng_AddUpdated BIT;
        SELECT TOP 1
            @Eng_Cycles           = Cycles,
            @Eng_CumulativeCycles = CumulativeCycles,
            @Eng_AddUpdated       = AddUpdated
        FROM @CycleTable;

        -- AIPD (installed parts) for each attached engine
        UPDATE AIPD
        SET
            AIPD.FlightHours =
                CASE WHEN ISNULL(ET.[Hours], 0) > 0
                THEN
                    FLOOR(
                        FLOOR(ISNULL(AIPD.FlightHours, 0))
                        + FLOOR(ISNULL(ET.[Hours], 0))
                        + (
                            (FLOOR(ISNULL(AIPD.FlightMinutes, 0))
                             + FLOOR(ISNULL(ET.[Minutes], 0)))
                            / 60
                          )
                    )
                ELSE
                    FLOOR(
                        FLOOR(ISNULL(ET.CumulativeHours, 0))
                        + (FLOOR(ISNULL(ET.CumulativeMinutes, 0)) / 60)
                    )
                END,

            AIPD.FlightMinutes =
                CASE WHEN ISNULL(ET.[Minutes], 0) > 0
                THEN
                    (FLOOR(ISNULL(AIPD.FlightMinutes, 0))
                     + FLOOR(ISNULL(ET.[Minutes], 0)))
                    % 60
                ELSE
                    FLOOR(ISNULL(ET.CumulativeMinutes, 0)) % 60
                END,

            AIPD.Cycles =
                CASE WHEN ISNULL(@Eng_Cycles, 0) > 0
                THEN ISNULL(AIPD.Cycles, 0) + ISNULL(@Eng_Cycles, 0)
                ELSE ISNULL(@Eng_CumulativeCycles, 0)
                END,

            AIPD.UpdatedBy   = ET.UpdatedBy,
            AIPD.UpdatedDate = GETUTCDATE(),

            AIPD.LastFlownDate =
                CASE
                    WHEN ISNULL(@Eng_AddUpdated, 0) = 1
                    THEN CAST(GETUTCDATE() AS DATE)
                    ELSE AIPD.LastFlownDate
                END

        FROM dbo.AircraftInstalledPartDetails AIPD WITH(NOLOCK)
        INNER JOIN @EngineTable ET ON AIPD.EngineRegistryId = ET.EngineRegistryId AND ISNULL(AIPD.IsFromAircraft, 0) = 0
        WHERE ET.EngineRegistryId IS NOT NULL;

        -- AircraftMaintenanceProgram for each attached engine — UPDATE existing engine-scoped row(s)
        UPDATE AMP
        SET
            AMP.FlightHoursRecordedHours =
                CASE WHEN ISNULL(ET.[Hours], 0) > 0 THEN
                    FLOOR(ISNULL(AMP.FlightHoursRecordedHours,   0))
                    + FLOOR(ISNULL(ET.[Hours], 0))
                    + (
                          (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0))
                           + FLOOR(ISNULL(ET.[Minutes], 0)))
                          / 60
                      )
                ELSE FLOOR(ISNULL(ET.CumulativeHours, 0))
                    + (  FLOOR(ISNULL(ET.CumulativeMinutes, 0))
                          / 60
                      )
                END,

            AMP.FlightHoursRecordedMinutes =
                CASE WHEN ISNULL(ET.[Minutes], 0) > 0 THEN
                    (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0))
                     + FLOOR(ISNULL(ET.[Minutes], 0)))
                    % 60
                ELSE (FLOOR(ISNULL(ET.CumulativeMinutes, 0)))
                    % 60
                END,

            AMP.CyclesRecorded =
                CASE WHEN ISNULL(@Eng_Cycles, 0) > 0 THEN
                     ISNULL(AMP.CyclesRecorded, 0) + ISNULL(@Eng_Cycles, 0)
                ELSE ISNULL(@Eng_CumulativeCycles, 0)
                END,

            AMP.FlightHoursRemainingHours =
                CASE
                    WHEN calc.LimitTotalMinutes IS NULL THEN NULL
                    WHEN calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes < 0 THEN 0
                    ELSE (calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes) / 60
                END,

            AMP.FlightHoursRemainingMinutes =
                CASE
                    WHEN calc.LimitTotalMinutes IS NULL THEN NULL
                    WHEN calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes < 0 THEN 0
                    ELSE (calc.LimitTotalMinutes - calc.NewRecordedTotalMinutes) % 60
                END,

            AMP.CyclesRemaining =
                CASE
                    WHEN calc.NewRecordedCycles IS NULL THEN NULL
                    WHEN ISNULL(AMP.CyclesLimit, 0) - calc.NewRecordedCycles < 0 THEN 0
                    ELSE ISNULL(AMP.CyclesLimit, 0) - calc.NewRecordedCycles
                END,

            AMP.UpdatedBy   = ET.UpdatedBy,
            AMP.UpdatedDate = GETUTCDATE()

        FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
        INNER JOIN @EngineTable ET
            ON AMP.EngineRegistryId = ET.EngineRegistryId AND ISNULL(AMP.IsFromAircraft, 0) = 0
        CROSS APPLY (
            SELECT
                LimitTotalMinutes =
                    ISNULL(AMP.FlightHoursLimitHours,   0) * 60
                    + ISNULL(AMP.FlightHoursLimitMinutes, 0),

                NewRecordedTotalMinutes =
                    (FLOOR(ISNULL(AMP.FlightHoursRecordedHours, 0)) + FLOOR(ISNULL(ET.[Hours], 0))) * 60
                    + (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0)) + FLOOR(ISNULL(ET.[Minutes], 0))),

                NewRecordedCycles =
                    ISNULL(AMP.CyclesRecorded, 0) + ISNULL(@Eng_Cycles, 0)
        ) AS calc
        WHERE ET.EngineRegistryId IS NOT NULL
          AND AMP.ProgramId = (
                SELECT TOP 1 amp2.ProgramId
                FROM dbo.AircraftMaintenanceProgram amp2 WITH(NOLOCK)
                WHERE amp2.EngineRegistryId          = AMP.EngineRegistryId
                  AND ISNULL(amp2.IsFromAircraft, 0) = 0
                  AND amp2.IsDeleted                 = 0
                  AND amp2.IsActive                  = 1
                ORDER BY
                    -- upcoming scheduled first (soonest), then most recent as fallback
                    CASE WHEN amp2.NextScheduledMaintenance >= CAST(GETDATE() AS DATE) THEN 0 ELSE 1 END,
                    CASE WHEN amp2.NextScheduledMaintenance >= CAST(GETDATE() AS DATE)
                         THEN amp2.NextScheduledMaintenance END ASC,
                    amp2.NextScheduledMaintenance DESC,
                    amp2.ProgramId DESC
            );

        -- AircraftMaintenanceProgram — INSERT for any attached engine that has no program row yet
        INSERT INTO dbo.AircraftMaintenanceProgram
        (
            TailNumber, AircraftMake, AircraftModel, SerialNumber,
            MaintenanceType, TemplateId,
            FlightHoursRecordedHours,
            FlightHoursRecordedMinutes,
            FlightHoursRemainingHours,
            FlightHoursRemainingMinutes,
            CyclesRemaining,
            CyclesRecorded,
            MasterCompanyId,
            CreatedBy, UpdatedBy,
            CreatedDate, UpdatedDate,
            IsActive, IsDeleted,
            AircraftRegistryId, EngineRegistryId, IsFromAircraft
        )
        SELECT
            '', '', '', '',
            '', 1,
            FLOOR(ISNULL(ET.CumulativeHours,   0)),
            FLOOR(ISNULL(ET.CumulativeMinutes, 0)) % 60,
            NULL,
            NULL,
            NULL,
            ISNULL(@Eng_CumulativeCycles, 0),
            ET.MasterCompanyId,
            ET.CreatedBy, ET.UpdatedBy,
            GETUTCDATE(), GETUTCDATE(),
            1, 0,
            ET.EngineRegistryId, ET.EngineRegistryId, 0
        FROM @EngineTable ET
        WHERE ET.EngineRegistryId IS NOT NULL
          AND NOT EXISTS (
                SELECT 1 FROM dbo.AircraftMaintenanceProgram amp3 WITH(NOLOCK)
                WHERE amp3.EngineRegistryId = ET.EngineRegistryId
                  AND ISNULL(amp3.IsFromAircraft, 0) = 0
                  AND amp3.IsDeleted = 0
            );

		-----------------------Add LastFlownDate--------------------

		UPDATE dbo.AircraftRegistryHeader SET LastFlownDate = CAST(GETUTCDATE() AS DATE) WHERE AircraftRegistryId  = @AircraftRegistryId;

		----------------------End LastFlownDate----------------------

        -------------------------------------------------------
        -- RETURN the saved cycle ID to the caller
        -------------------------------------------------------
        SELECT @CycleId AS AircraftCycleTimeMappingsId;

    COMMIT TRANSACTION;
    END TRY        

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRANSACTION;
        END

        DECLARE @ErrorLogID          INT,
                @DatabaseName        VARCHAR(100)  = DB_NAME(),
                @AdhocComments       VARCHAR(150)  = 'USP_SaveAircraftCycleTimeMappings',
                @ProcedureParameters VARCHAR(3000) = '@CycleData = '''
                                                     + CAST(ISNULL(@CycleData, '') AS VARCHAR(100)),
                @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException 
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);
    END CATCH    
END
GO
