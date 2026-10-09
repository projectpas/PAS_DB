/****** Object:  StoredProcedure [dbo].[USP_SaveEngineCycleTimeMappings] ******/

/*************************************************************
** Author:  <Moin Bloch>
** Create date: <29/09/2026>
** Description: <This Proc Is used to Save Engine Registry CycleTime (Engine Registry List)>
**              Based on USP_SaveAircraftCycleTimeMappings, scoped to the engine only:
**              - Upserts AircraftCycleTimeMappings header + AircraftEngineStartsMappings rows.
**              - Updates AircraftInstalledPartDetails / AircraftMaintenanceProgram rows matched on
**                EngineRegistryId with IsFromAircraft = 0 or NULL.
**              - Does NOT touch aircraft-scoped rows (AircraftRegistryId) or AircraftRegistryHeader,
**                because RefrenceId here is an EngineRegistryId, not an AircraftRegistryId.

Exec [USP_SaveEngineCycleTimeMappings]
**************************************************************
** Change History
**************************************************************
** PR   Date        Author              Change Description
** --   --------    -------             --------------------------------
   1    30/09/2026  Moin Bloch          Created (ModuleId = 2 for Engine Registry; sets EngineRegistryHeader.LastFlownDate)
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveEngineCycleTimeMappings]
    @CycleData  NVARCHAR(MAX),
    @EngineData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

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

        DECLARE @CycleId BIGINT;

        -------------------------------------------------------
        -- CHECK INSERT OR UPDATE AircraftCycleTimeMappings
        -------------------------------------------------------
        IF EXISTS (SELECT 1 FROM @CycleTable WHERE ISNULL(AircraftCycleTimeMappingsId, 0) > 0)
        BEGIN
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
            FROM dbo.AircraftCycleTimeMappings A
            INNER JOIN @CycleTable C
                ON A.AircraftCycleTimeMappingsId = C.AircraftCycleTimeMappingsId;

            SELECT TOP 1 @CycleId = AircraftCycleTimeMappingsId
            FROM @CycleTable
            WHERE ISNULL(AircraftCycleTimeMappingsId, 0) > 0;
        END
        ELSE
        BEGIN
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
        -- READ ENGINE JSON INTO TEMP TABLE
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

        -------------------------------------------------------
        -- UPSERT AircraftEngineStartsMappings
        -------------------------------------------------------
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
                @CycleId,
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
        -- Cycles: the Engine Registry popup has no cycle input, so cycles are only
        -- accumulated when an ADD value is sent; otherwise existing cycles are kept
        -- (the aircraft proc's "ELSE CumulativeCycles" would reset them to the header value).
        -------------------------------------------------------
        DECLARE @Eng_Cycles DECIMAL(18,6);
        SELECT TOP 1 @Eng_Cycles = Cycles FROM @CycleTable;

        -------------------------------------------------------
        -- UPDATE AircraftInstalledPartDetails for the engine
        -- (EngineRegistryId, IsFromAircraft = 0 or NULL)
        -------------------------------------------------------
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
                ELSE AIPD.Cycles
                END,

            AIPD.UpdatedBy   = ET.UpdatedBy,
            AIPD.UpdatedDate = GETUTCDATE(),

            -- LastFlownDate: only when something was ADDED (not on a pure edit of current values)
            AIPD.LastFlownDate =
                CASE
                    WHEN ISNULL(ET.[Hours], 0) > 0 OR ISNULL(ET.[Minutes], 0) > 0 OR ISNULL(ET.Starts, 0) > 0
                    THEN CAST(GETUTCDATE() AS DATE)
                    ELSE AIPD.LastFlownDate
                END

        FROM dbo.AircraftInstalledPartDetails AIPD
        INNER JOIN @EngineTable ET
            ON AIPD.EngineRegistryId = ET.EngineRegistryId
           AND ISNULL(AIPD.IsFromAircraft, 0) = 0
        WHERE ET.EngineRegistryId IS NOT NULL;

        -------------------------------------------------------
        -- UPDATE AircraftMaintenanceProgram for the engine
        -- (EngineRegistryId, IsFromAircraft = 0 or NULL;
        --  only the next active upcoming program per engine)
        -------------------------------------------------------
        UPDATE AMP
        SET
            AMP.FlightHoursRecordedHours =
                CASE WHEN ISNULL(ET.[Hours], 0) > 0 THEN
                    FLOOR(ISNULL(AMP.FlightHoursRecordedHours, 0))
                    + FLOOR(ISNULL(ET.[Hours], 0))
                    + (
                          (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0))
                           + FLOOR(ISNULL(ET.[Minutes], 0)))
                          / 60
                      )
                ELSE FLOOR(ISNULL(ET.CumulativeHours, 0))
                    + (FLOOR(ISNULL(ET.CumulativeMinutes, 0)) / 60)
                END,

            AMP.FlightHoursRecordedMinutes =
                CASE WHEN ISNULL(ET.[Minutes], 0) > 0 THEN
                    (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0))
                     + FLOOR(ISNULL(ET.[Minutes], 0)))
                    % 60
                ELSE FLOOR(ISNULL(ET.CumulativeMinutes, 0)) % 60
                END,

            AMP.CyclesRecorded =
                CASE WHEN ISNULL(@Eng_Cycles, 0) > 0 THEN
                     ISNULL(AMP.CyclesRecorded, 0) + ISNULL(@Eng_Cycles, 0)
                ELSE AMP.CyclesRecorded
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

        FROM dbo.AircraftMaintenanceProgram AMP
        INNER JOIN @EngineTable ET
            ON AMP.EngineRegistryId = ET.EngineRegistryId
           AND ISNULL(AMP.IsFromAircraft, 0) = 0
        CROSS APPLY (
            SELECT
                LimitTotalMinutes =
                    ISNULL(AMP.FlightHoursLimitHours, 0) * 60
                    + ISNULL(AMP.FlightHoursLimitMinutes, 0),

                -- Recorded total after this save, in minutes (same rule as the recorded columns above)
                NewRecordedTotalMinutes =
                    CASE WHEN ISNULL(ET.[Hours], 0) > 0 OR ISNULL(ET.[Minutes], 0) > 0
                    THEN (FLOOR(ISNULL(AMP.FlightHoursRecordedHours, 0)) + FLOOR(ISNULL(ET.[Hours], 0))) * 60
                         + (FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0)) + FLOOR(ISNULL(ET.[Minutes], 0)))
                    ELSE FLOOR(ISNULL(ET.CumulativeHours, 0)) * 60
                         + FLOOR(ISNULL(ET.CumulativeMinutes, 0))
                    END,

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
                  AND amp2.NextScheduledMaintenance IS NOT NULL
                  AND amp2.NextScheduledMaintenance >= CAST(GETDATE() AS DATE)
                ORDER BY amp2.NextScheduledMaintenance ASC, amp2.ProgramId DESC
            );

        -----------------------Add LastFlownDate--------------------
        -- Only when something was ADDED for the engine (not on a pure edit of current values)
        UPDATE ERH
        SET ERH.LastFlownDate = CAST(GETUTCDATE() AS DATE)
        FROM dbo.EngineRegistryHeader ERH
        INNER JOIN @EngineTable ET ON ERH.EngineRegistryId = ET.EngineRegistryId
        WHERE ISNULL(ET.[Hours], 0) > 0 OR ISNULL(ET.[Minutes], 0) > 0 OR ISNULL(ET.Starts, 0) > 0;
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
                @AdhocComments       VARCHAR(150)  = 'USP_SaveEngineCycleTimeMappings',
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