/*************************************************************
** File:        [USP_CopyAircraftMaintenanceSchedule]
** Description: Copies the maintenance schedule (events of AircraftMaintenanceProgram) of a source
**              aircraft / engine into a target aircraft / engine of the same Make and Model
**              (Engine: same Engine Model). An event that already exists on the target
**              (same Maintenance Type + Template + Mtce Category) is skipped.
**              Event fields are copied (template, limits, description, scheduled flag ...). RESET on the copy:
**              Last Inspected date / By, Next Scheduled Mtce, Recorded Time and Cycles (hours, minutes, cycles,
**              time, landings, engine starts = 0) and Remaining (= Limit). Not copied: AircraftPublicationId,
**              WorksheetNumber / WorkOrderNum (they point to the source's own documents).
**              Tail / Make / Model / Serial are taken from the target; SequenceNo is regenerated.
** Date:        17/11/2026
**
** RETURN VALUE: ResultCode (1 = success, 0 = validation failure), Message, CopiedCount, SkippedCount
**************************************************************
** Change History
**************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    17/11/2026   RAJESH GAMI        Created [PN-18545]
** 3    18/11/2026   RAJESH GAMI        [PN-18545] Stale WO / Worksheet links to the new copied events are cleared
** 2    18/11/2026   RAJESH GAMI        [PN-18545] Copy resets Last Inspected / By, Next Sch Mtce, Recorded Time & Cycles; Remaining = Limit
**************************************************************/
--EXEC [dbo].[USP_CopyAircraftMaintenanceSchedule] @SourceAircraftRegistryId = 1, @TargetAircraftRegistryId = 128, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN'
--EXEC [dbo].[USP_CopyAircraftMaintenanceSchedule] @SourceAircraftRegistryId = 6, @TargetAircraftRegistryId = 10, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN', @IsFromAircraft = 0
CREATE   PROCEDURE [dbo].[USP_CopyAircraftMaintenanceSchedule]
(
    @SourceAircraftRegistryId BIGINT,
    @TargetAircraftRegistryId BIGINT,
    @MasterCompanyId          INT,
    @UpdatedBy                VARCHAR(256),
    @IsFromAircraft           BIT = 1      -- 1 = Aircraft Registry, 0 = Engine Registry (ids are then EngineRegistryId)
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @IsFromAircraft = ISNULL(@IsFromAircraft, 1);

        DECLARE @SourceMakeTypeId BIGINT, @SourceAircraftModelId BIGINT, @SourceDisplayName VARCHAR(256),
                @TargetMakeTypeId BIGINT, @TargetAircraftModelId BIGINT, @TargetDisplayName VARCHAR(256),
                @SourceEngineModel VARCHAR(100), @TargetEngineModel VARCHAR(100),
                @TargetMakeType VARCHAR(100), @TargetModel VARCHAR(100), @TargetSerialNum VARCHAR(100),
                @SourceTotalCount INT = 0, @CopiedCount INT = 0, @SkippedCount INT = 0,
                @LastSequenceNo BIGINT = 0, @CurrentDate DATETIME2(7) = GETUTCDATE();

        IF (@IsFromAircraft = 1)
        BEGIN
            SELECT @SourceMakeTypeId = [MakeTypeId], @SourceAircraftModelId = [AircraftModelId], @SourceDisplayName = [TailNum]
            FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
            WHERE [AircraftRegistryId] = @SourceAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;

            SELECT @TargetMakeTypeId = [MakeTypeId], @TargetAircraftModelId = [AircraftModelId], @TargetDisplayName = [TailNum],
                   @TargetMakeType = [MakeType], @TargetModel = [AircraftModel], @TargetSerialNum = [SerialNum]
            FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
            WHERE [AircraftRegistryId] = @TargetAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;
        END
        ELSE
        BEGIN
            SELECT @SourceEngineModel = UPPER(LTRIM(RTRIM([EngineModel]))), @SourceDisplayName = ISNULL(NULLIF([EngineName], ''), [TailNum])
            FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
            WHERE [EngineRegistryId] = @SourceAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;

            SELECT @TargetEngineModel = UPPER(LTRIM(RTRIM([EngineModel]))), @TargetDisplayName = ISNULL(NULLIF([EngineName], ''), [TailNum]),
                   @TargetMakeType = [MakeType], @TargetModel = [EngineModel], @TargetSerialNum = [SerialNum]
            FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
            WHERE [EngineRegistryId] = @TargetAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;
        END

        DECLARE @EntityName VARCHAR(10) = CASE WHEN @IsFromAircraft = 1 THEN 'aircraft' ELSE 'engine' END;

        -- Validations
        IF (@SourceDisplayName IS NULL OR @TargetDisplayName IS NULL)
        BEGIN
            SELECT 0 AS [ResultCode], 'Source or target ' + @EntityName + ' was not found.' AS [Message], 0 AS [CopiedCount], 0 AS [SkippedCount];
            RETURN;
        END

        IF (@SourceAircraftRegistryId = @TargetAircraftRegistryId)
        BEGIN
            SELECT 0 AS [ResultCode], 'Source and target ' + @EntityName + ' must be different.' AS [Message], 0 AS [CopiedCount], 0 AS [SkippedCount];
            RETURN;
        END

        IF (@IsFromAircraft = 1
            AND (ISNULL(@SourceMakeTypeId, 0) <> ISNULL(@TargetMakeTypeId, 0) OR ISNULL(@SourceAircraftModelId, 0) <> ISNULL(@TargetAircraftModelId, 0)))
        BEGIN
            SELECT 0 AS [ResultCode], 'Maintenance schedule can only be copied between aircraft of the same Make and Model.' AS [Message], 0 AS [CopiedCount], 0 AS [SkippedCount];
            RETURN;
        END

        IF (@IsFromAircraft = 0 AND ISNULL(@SourceEngineModel, '') <> ISNULL(@TargetEngineModel, ''))
        BEGIN
            SELECT 0 AS [ResultCode], 'Maintenance schedule can only be copied between engines of the same Engine Model.' AS [Message], 0 AS [CopiedCount], 0 AS [SkippedCount];
            RETURN;
        END

        -- Source events (active, not deleted); one row per Maintenance Type + Template + Mtce Category
        IF OBJECT_ID('tempdb..#EventsToCopy') IS NOT NULL DROP TABLE #EventsToCopy;

        SELECT SourceEvent.*,
               ROW_NUMBER() OVER (PARTITION BY ISNULL(SourceEvent.[MaintenanceTypeId], 0), ISNULL(SourceEvent.[MaintenanceType], ''),
                                               ISNULL(SourceEvent.[TemplateId], 0), ISNULL(SourceEvent.[MtcCategoryId], 0)
                                  ORDER BY SourceEvent.[ProgramId]) AS [KeyRowNumber]
        INTO #EventsToCopy
        FROM [dbo].[AircraftMaintenanceProgram] SourceEvent WITH (NOLOCK)
        WHERE SourceEvent.[AircraftRegistryId] = @SourceAircraftRegistryId
          AND ISNULL(SourceEvent.[IsFromAircraft], 0) = @IsFromAircraft
          AND SourceEvent.[IsActive]  = 1
          AND SourceEvent.[IsDeleted] = 0
          AND SourceEvent.[MasterCompanyId] = @MasterCompanyId;

        SELECT @SourceTotalCount = COUNT(1) FROM #EventsToCopy;

        DELETE FROM #EventsToCopy WHERE [KeyRowNumber] > 1;

        -- Skip events that already exist on the target
        DELETE EventsToCopy
        FROM #EventsToCopy EventsToCopy
        WHERE EXISTS (
            SELECT 1
            FROM [dbo].[AircraftMaintenanceProgram] TargetEvent WITH (NOLOCK)
            WHERE TargetEvent.[AircraftRegistryId] = @TargetAircraftRegistryId
              AND ISNULL(TargetEvent.[IsFromAircraft], 0) = @IsFromAircraft
              AND TargetEvent.[IsActive]  = 1
              AND TargetEvent.[IsDeleted] = 0
              AND ISNULL(TargetEvent.[MaintenanceTypeId], 0) = ISNULL(EventsToCopy.[MaintenanceTypeId], 0)
              AND ISNULL(TargetEvent.[MaintenanceType], '')  = ISNULL(EventsToCopy.[MaintenanceType], '')
              AND ISNULL(TargetEvent.[TemplateId], 0)        = ISNULL(EventsToCopy.[TemplateId], 0)
              AND ISNULL(TargetEvent.[MtcCategoryId], 0)     = ISNULL(EventsToCopy.[MtcCategoryId], 0)
        );

        SELECT @CopiedCount = COUNT(1) FROM #EventsToCopy;
        SET @SkippedCount = @SourceTotalCount - @CopiedCount;

        IF (@CopiedCount > 0)
        BEGIN
            DECLARE @NewProgramIds TABLE ([ProgramId] BIGINT PRIMARY KEY);

            BEGIN TRAN;

            SELECT @LastSequenceNo = ISNULL(MAX([SequenceNo]), 0) FROM [dbo].[AircraftMaintenanceProgram] WITH (TABLOCKX, HOLDLOCK);

            INSERT INTO [dbo].[AircraftMaintenanceProgram]
            (
                [AircraftRegistryId], [EngineRegistryId], [IsFromAircraft], [VersionNumber], [TailNumber],
                [AircraftMake], [AircraftModel], [SerialNumber],
                [MaintenanceType], [MaintenanceTypeId], [MaintenanceClassId], [MtcCategoryId],
                [NextScheduledMaintenance], [TemplateId], [TemplateVersionNumber],
                [FlightHoursLimitHours], [FlightHoursLimitMinutes], [FlightHoursLimitMonthsOrDays],
                [CyclesLimit], [TimeLimit], [LandingsLimit], [EngineStartsLimit],
                [FlightHoursRecordedHours], [FlightHoursRecordedMinutes], [CyclesRecorded], [TimeRecorded], [LandingsRecorded], [EngineStartsRecorded],
                [FlightHoursRemainingHours], [FlightHoursRemainingMinutes], [CyclesRemaining], [TimeRemaining], [LandingsRemaining], [EngineStartsRemaining],
                [IsScheduled], [IsMtceRecordUpdated], [LastinspectedById], [LastInspectedDate], [Description],
                [AircraftPublicationId], [WorksheetNumber], [WorkOrderNum], [SequenceNo],
                [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
            )
            OUTPUT inserted.[ProgramId] INTO @NewProgramIds ([ProgramId])
            SELECT
                @TargetAircraftRegistryId, CASE WHEN @IsFromAircraft = 1 THEN NULL ELSE @TargetAircraftRegistryId END, @IsFromAircraft,
                EventsToCopy.[VersionNumber], @TargetDisplayName,
                @TargetMakeType, @TargetModel, @TargetSerialNum,
                EventsToCopy.[MaintenanceType], EventsToCopy.[MaintenanceTypeId], EventsToCopy.[MaintenanceClassId], EventsToCopy.[MtcCategoryId],
                NULL, EventsToCopy.[TemplateId], EventsToCopy.[TemplateVersionNumber],   -- Next Sch Mtce reset [PN-18545]
                EventsToCopy.[FlightHoursLimitHours], EventsToCopy.[FlightHoursLimitMinutes], EventsToCopy.[FlightHoursLimitMonthsOrDays],
                EventsToCopy.[CyclesLimit], EventsToCopy.[TimeLimit], EventsToCopy.[LandingsLimit], EventsToCopy.[EngineStartsLimit],
                -- Recorded Time / Cycles reset (nothing recorded yet on the target) [PN-18545]
                0, 0, 0, 0, 0, 0,
                -- Remaining = Limit (nothing recorded yet)
                EventsToCopy.[FlightHoursLimitHours], EventsToCopy.[FlightHoursLimitMinutes], EventsToCopy.[CyclesLimit], EventsToCopy.[TimeLimit], EventsToCopy.[LandingsLimit], EventsToCopy.[EngineStartsLimit],
                -- Last Inspected / Last Inspected By reset [PN-18545]
                EventsToCopy.[IsScheduled], 0, NULL, NULL, EventsToCopy.[Description],
                NULL, NULL, NULL,
                @LastSequenceNo + ROW_NUMBER() OVER (ORDER BY ISNULL(EventsToCopy.[SequenceNo], 9223372036854775807), EventsToCopy.[ProgramId]),
                @MasterCompanyId, @UpdatedBy, @UpdatedBy, @CurrentDate, @CurrentDate, 1, 0
            FROM #EventsToCopy EventsToCopy;

            -- [PN-18545] The copied events are brand new : no Work Order / Worksheet belongs to them. Any WO part / worksheet that already points to one of these
            -- new ProgramIds is a stale link (left from an older event with the same id), so it is cleared and the grid shows no WO Num / Worksheet.
            UPDATE WorkOrderPartLink SET [ProgramId] = NULL
            FROM [dbo].[WorkOrderPartNumber] WorkOrderPartLink
            INNER JOIN @NewProgramIds NewProgramIds ON NewProgramIds.[ProgramId] = WorkOrderPartLink.[ProgramId];

            UPDATE WorksheetMappingLink SET [ProgramId] = NULL
            FROM [dbo].[WorksheetMapping] WorksheetMappingLink
            INNER JOIN @NewProgramIds NewProgramIds ON NewProgramIds.[ProgramId] = WorksheetMappingLink.[ProgramId];

            UPDATE WorksheetHeaderLink SET [ProgramId] = NULL
            FROM [dbo].[WorksheetHeader] WorksheetHeaderLink
            INNER JOIN @NewProgramIds NewProgramIds ON NewProgramIds.[ProgramId] = WorksheetHeaderLink.[ProgramId];

            -- History (one entry for the whole copy)
            DECLARE @HistoryModuleName VARCHAR(100) = CASE WHEN @IsFromAircraft = 1 THEN 'Aircraft Maintenance' ELSE 'Engine Maintenance' END;
            DECLARE @HistoryText VARCHAR(MAX) =
                'Copied ' + CAST(@CopiedCount AS VARCHAR(10)) + ' maintenance event(s) from ' + CASE WHEN @IsFromAircraft = 1 THEN 'Aircraft: ' ELSE 'Engine: ' END + @SourceDisplayName
                + CASE WHEN @SkippedCount > 0 THEN ' | Skipped (already exist): ' + CAST(@SkippedCount AS VARCHAR(10)) ELSE '' END
                + ' | Copied By: ' + ISNULL(@UpdatedBy, '') + ' | Copied Date: ' + CONVERT(VARCHAR(10), CAST(@CurrentDate AS DATE), 103);

            EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 2, @ModuleName = @HistoryModuleName, @RefferenceId = @TargetAircraftRegistryId,
                 @FieldsName = NULL, @OldValue = NULL, @NewValue = @SourceDisplayName, @HistoryText = @HistoryText,
                 @Activity = 'Maintenance Schedule Copied', @MasterCompanyId = @MasterCompanyId, @CreatedBy = @UpdatedBy;

            COMMIT TRAN;
        END

        DROP TABLE #EventsToCopy;

        SELECT 1 AS [ResultCode],
               CASE WHEN @SourceTotalCount = 0 THEN 'Selected ' + @EntityName + ' has no maintenance events to copy.'
                    WHEN @CopiedCount = 0 THEN 'All maintenance events already exist on this ' + @EntityName + '. Nothing was copied.'
                    ELSE CAST(@CopiedCount AS VARCHAR(10)) + ' maintenance event(s) copied, ' + CAST(@SkippedCount AS VARCHAR(10)) + ' skipped (already exist).' END AS [Message],
               @CopiedCount AS [CopiedCount], @SkippedCount AS [SkippedCount];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments       VARCHAR(150)  = '[dbo].[USP_CopyAircraftMaintenanceSchedule] '
            , @ProcedureParameters VARCHAR(3000) = '@SourceAircraftRegistryId = ' + ISNULL(CAST(@SourceAircraftRegistryId AS VARCHAR(20)), '')
                                                 + ', @TargetAircraftRegistryId = ' + ISNULL(CAST(@TargetAircraftRegistryId AS VARCHAR(20)), '')
            , @ApplicationName     VARCHAR(100)  = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException
              @DatabaseName        = @DatabaseName
            , @AdhocComments       = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName     = @ApplicationName
            , @ErrorLogID          = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END
