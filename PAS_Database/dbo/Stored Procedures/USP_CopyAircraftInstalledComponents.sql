/*************************************************************
** File:        [USP_CopyAircraftInstalledComponents]
** Description: Copies the installed components of a source aircraft into a target aircraft
**              (same Make and Model, different Tail Num). Components already present on the
**              target (same Item Master) are skipped.
**              Copied rows are new, unlinked installed components: StockLineId is not copied,
**              and install/usage values (Date Installed, hours, cycles, landings, starts,
**              install hours/cycles) are reset. Limits/service-life values are copied.
** Date:        16/11/2026
**
** RETURN VALUE: ResultCode (1 = success, 0 = validation failure), Message, CopiedCount, SkippedCount
**************************************************************
** Change History
**************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    16/11/2026   RAJESH GAMI        Created [PN-18542]
** 2    16/11/2026   RAJESH GAMI        Engine support (@IsFromAircraft = 0, same Engine Model) [PN-18542]
** 3    18/11/2026   RAJESH GAMI        Stale PO / RO / WO links to the new copied rows are cleared [PN-18542]
**************************************************************/
--EXEC [dbo].[USP_CopyAircraftInstalledComponents] @SourceAircraftRegistryId = 1, @TargetAircraftRegistryId = 128, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN'
CREATE   PROCEDURE [dbo].[USP_CopyAircraftInstalledComponents]
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

        DECLARE @SourceMakeTypeId BIGINT, @SourceAircraftModelId BIGINT, @SourceTailNum VARCHAR(256),
                @TargetMakeTypeId BIGINT, @TargetAircraftModelId BIGINT, @TargetTailNum VARCHAR(256),
                @SourceEngineModel VARCHAR(100), @TargetEngineModel VARCHAR(100),
                @SourceTotalCount INT = 0, @CopiedCount INT = 0, @SkippedCount INT = 0,
                @NextSequenceNum INT = 0, @CurrentDate DATETIME2(7) = GETUTCDATE();

        IF (@IsFromAircraft = 1)
        BEGIN
            SELECT @SourceMakeTypeId = [MakeTypeId], @SourceAircraftModelId = [AircraftModelId], @SourceTailNum = [TailNum]
            FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
            WHERE [AircraftRegistryId] = @SourceAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;

            SELECT @TargetMakeTypeId = [MakeTypeId], @TargetAircraftModelId = [AircraftModelId], @TargetTailNum = [TailNum]
            FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
            WHERE [AircraftRegistryId] = @TargetAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;
        END
        ELSE
        BEGIN
            SELECT @SourceEngineModel = UPPER(LTRIM(RTRIM([EngineModel]))), @SourceTailNum = ISNULL(NULLIF([EngineName], ''), [TailNum])
            FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
            WHERE [EngineRegistryId] = @SourceAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;

            SELECT @TargetEngineModel = UPPER(LTRIM(RTRIM([EngineModel]))), @TargetTailNum = ISNULL(NULLIF([EngineName], ''), [TailNum])
            FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
            WHERE [EngineRegistryId] = @TargetAircraftRegistryId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;
        END

        DECLARE @EntityName VARCHAR(10) = CASE WHEN @IsFromAircraft = 1 THEN 'aircraft' ELSE 'engine' END;

        -- Validations
        IF (@SourceTailNum IS NULL OR @TargetTailNum IS NULL)
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
            SELECT 0 AS [ResultCode], 'Components can only be copied between aircraft of the same Make and Model.' AS [Message], 0 AS [CopiedCount], 0 AS [SkippedCount];
            RETURN;
        END

        IF (@IsFromAircraft = 0 AND ISNULL(@SourceEngineModel, '') <> ISNULL(@TargetEngineModel, ''))
        BEGIN
            SELECT 0 AS [ResultCode], 'Components can only be copied between engines of the same Engine Model.' AS [Message], 0 AS [CopiedCount], 0 AS [SkippedCount];
            RETURN;
        END

        -- Source components that are NOT already on the target (duplicate = ItemMasterId)
        IF OBJECT_ID('tempdb..#ComponentsToCopy') IS NOT NULL DROP TABLE #ComponentsToCopy;

        SELECT SourceComponent.*
        INTO #ComponentsToCopy
        FROM [dbo].[AircraftInstalledPartDetails] SourceComponent WITH (NOLOCK)
        WHERE SourceComponent.[AircraftRegistryId] = @SourceAircraftRegistryId
          AND ISNULL(SourceComponent.[IsFromAircraft], 0) = @IsFromAircraft
          AND SourceComponent.[IsActive]  = 1
          AND SourceComponent.[IsDeleted] = 0
          AND SourceComponent.[MasterCompanyId] = @MasterCompanyId;

        SELECT @SourceTotalCount = COUNT(1) FROM #ComponentsToCopy;

        DELETE ComponentsToCopy
        FROM #ComponentsToCopy ComponentsToCopy
        WHERE EXISTS (
            SELECT 1
            FROM [dbo].[AircraftInstalledPartDetails] TargetComponent WITH (NOLOCK)
            WHERE TargetComponent.[AircraftRegistryId] = @TargetAircraftRegistryId
              AND ISNULL(TargetComponent.[IsFromAircraft], 0) = @IsFromAircraft
              AND TargetComponent.[IsActive]  = 1
              AND TargetComponent.[IsDeleted] = 0
              AND TargetComponent.[ItemMasterId] = ComponentsToCopy.[ItemMasterId]
        );

        SELECT @CopiedCount = COUNT(1) FROM #ComponentsToCopy;
        SET @SkippedCount = @SourceTotalCount - @CopiedCount;

        IF (@CopiedCount > 0)
        BEGIN
            SELECT @NextSequenceNum = ISNULL(MAX([SequenceNum]), 0)
            FROM [dbo].[AircraftInstalledPartDetails] WITH (NOLOCK)
            WHERE [AircraftRegistryId] = @TargetAircraftRegistryId AND ISNULL([IsFromAircraft], 0) = @IsFromAircraft;

            DECLARE @NewComponentIds TABLE ([AircraftInstalledPartDetailsId] BIGINT PRIMARY KEY);

            BEGIN TRAN;

            INSERT INTO [dbo].[AircraftInstalledPartDetails]
            (
                [AircraftRegistryId], [EngineRegistryId], [IsFromAircraft], [ATAChapterId], [SequenceNum],
                [ItemMasterId], [PartNumber], [PartDescription], [IsLLP], [IsSerialized], [SerialNumber],
                [PositionCodeId], [PositionCode], [Quantity], [Memo],
                [PartFlightHours], [PartFlightMinutes], [PartCycles], [PartLandings], [PartEngineStarts],
                [ServiceLifeUnitMonthsOrDays], [ServiceLifeLimit],
                [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
            )
            OUTPUT inserted.[AircraftInstalledPartDetailsId] INTO @NewComponentIds ([AircraftInstalledPartDetailsId])
            SELECT
                @TargetAircraftRegistryId, CASE WHEN @IsFromAircraft = 1 THEN NULL ELSE @TargetAircraftRegistryId END, @IsFromAircraft, ComponentsToCopy.[ATAChapterId],
                @NextSequenceNum + ROW_NUMBER() OVER (ORDER BY ISNULL(ComponentsToCopy.[SequenceNum], 2147483647), ComponentsToCopy.[AircraftInstalledPartDetailsId]),
                ComponentsToCopy.[ItemMasterId], ComponentsToCopy.[PartNumber], ComponentsToCopy.[PartDescription],
                ComponentsToCopy.[IsLLP], ComponentsToCopy.[IsSerialized], ComponentsToCopy.[SerialNumber],
                ComponentsToCopy.[PositionCodeId], ComponentsToCopy.[PositionCode], ComponentsToCopy.[Quantity], ComponentsToCopy.[Memo],
                ComponentsToCopy.[PartFlightHours], ComponentsToCopy.[PartFlightMinutes], ComponentsToCopy.[PartCycles],
                ComponentsToCopy.[PartLandings], ComponentsToCopy.[PartEngineStarts],
                ComponentsToCopy.[ServiceLifeUnitMonthsOrDays], ComponentsToCopy.[ServiceLifeLimit],
                @MasterCompanyId, @UpdatedBy, @UpdatedBy, @CurrentDate, @CurrentDate, 1, 0
            FROM #ComponentsToCopy ComponentsToCopy;

            -- [PN-18542] The copied rows are brand new : no PO / RO / WO belongs to them. Any PO part / RO part / WO part that already points to one of these new ids
            -- is a stale link (left from an older installed component that had the same id), so it is cleared and the grid shows no PO / RO / WO number.
            UPDATE PurchaseOrderPartLink SET [AircraftInstalledPartDetailsId] = NULL
            FROM [dbo].[PurchaseOrderPart] PurchaseOrderPartLink
            INNER JOIN @NewComponentIds NewComponentIds ON NewComponentIds.[AircraftInstalledPartDetailsId] = PurchaseOrderPartLink.[AircraftInstalledPartDetailsId];

            UPDATE RepairOrderPartLink SET [AircraftInstalledPartDetailsId] = NULL
            FROM [dbo].[RepairOrderPart] RepairOrderPartLink
            INNER JOIN @NewComponentIds NewComponentIds ON NewComponentIds.[AircraftInstalledPartDetailsId] = RepairOrderPartLink.[AircraftInstalledPartDetailsId];

            UPDATE WorkOrderPartLink SET [AircraftInstalledPartDetailsId] = NULL
            FROM [dbo].[WorkOrderPartNumber] WorkOrderPartLink
            INNER JOIN @NewComponentIds NewComponentIds ON NewComponentIds.[AircraftInstalledPartDetailsId] = WorkOrderPartLink.[AircraftInstalledPartDetailsId];

            -- History (one entry for the whole copy)
            DECLARE @HistoryModuleName VARCHAR(100) = CASE WHEN @IsFromAircraft = 1 THEN 'Aircraft Installed Components' ELSE 'Engine Installed Components' END;
            DECLARE @HistoryText VARCHAR(MAX) =
                'Copied ' + CAST(@CopiedCount AS VARCHAR(10)) + ' installed component(s) from ' + CASE WHEN @IsFromAircraft = 1 THEN 'Aircraft: ' ELSE 'Engine: ' END + @SourceTailNum
                + CASE WHEN @SkippedCount > 0 THEN ' | Skipped (already exist): ' + CAST(@SkippedCount AS VARCHAR(10)) ELSE '' END
                + ' | Copied By: ' + ISNULL(@UpdatedBy, '') + ' | Copied Date: ' + CONVERT(VARCHAR(10), CAST(@CurrentDate AS DATE), 103);

            EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 3, @ModuleName = @HistoryModuleName, @RefferenceId = @TargetAircraftRegistryId,
                 @FieldsName = NULL, @OldValue = NULL, @NewValue = @SourceTailNum, @HistoryText = @HistoryText,
                 @Activity = 'Installed Components Copied', @MasterCompanyId = @MasterCompanyId, @CreatedBy = @UpdatedBy;

            COMMIT TRAN;
        END

        DROP TABLE #ComponentsToCopy;

        SELECT 1 AS [ResultCode],
               CASE WHEN @SourceTotalCount = 0 THEN 'Selected ' + @EntityName + ' has no installed components to copy.'
                    WHEN @CopiedCount = 0 THEN 'All components already exist on this ' + @EntityName + '. Nothing was copied.'
                    ELSE CAST(@CopiedCount AS VARCHAR(10)) + ' component(s) copied, ' + CAST(@SkippedCount AS VARCHAR(10)) + ' skipped (already exist).' END AS [Message],
               @CopiedCount AS [CopiedCount], @SkippedCount AS [SkippedCount];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments       VARCHAR(150)  = '[dbo].[USP_CopyAircraftInstalledComponents] '
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
