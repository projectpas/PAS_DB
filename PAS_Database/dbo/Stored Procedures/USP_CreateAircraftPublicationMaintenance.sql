/************************************************************
** File:        [USP_CreateAircraftPublicationMaintenance]
** Author:      Amit Ghediya
** Description: Creates AircraftMaintenanceProgram records for
**              every AircraftRegistryHeader row that matches
**              the AC Type & AC Serial Number effectivity
**              criteria defined against an AircraftPublication
**              (via AircraftEffectivity). Skips aircraft that
**              already have a maintenance record for this
**              publication.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    09/07/2026  Amit Ghediya		Created
** 2    14/07/2026  Amit Ghediya		Allow to create maintanace for allow except ser num [PN-17223]
** 3    14/08/2026  Amit Ghediya		Update new code for get default Maintenance category
************************************************************/
CREATE         PROCEDURE [dbo].[USP_CreateAircraftPublicationMaintenance]
    @AircraftPublicationId BIGINT,
    @MasterCompanyId       INT,
    @CreatedBy              VARCHAR(256)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @AffectedRows INT,
                @MtcCategoryId BIGINT = NULL,
                @PubNum VARCHAR(50) = NULL,
                @OldSequenceNum INT = NULL;

        SELECT @MtcCategoryId = [MtcCategoryId] FROM DBO.MaintenanceCategory WITH(NOLOCK) WHERE [MaintenanceCode] = 'MAJOR_OVERHAUL' AND [MasterCompanyId] = @MasterCompanyId;

        SELECT @PubNum = [PubNum] FROM [dbo].[AircraftPublication] WITH (NOLOCK) WHERE [AircraftPublicationId] = @AircraftPublicationId;

        SET @OldSequenceNum = ISNULL((SELECT MAX(SequenceNo) FROM dbo.AircraftMaintenanceProgram WITH (NOLOCK)), 0);

        BEGIN TRANSACTION;

            -- DISTINCT is required here: an aircraft can now match more than one
            -- AircraftEffectivity rule for the same publication (e.g. a range-based rule and a
            -- separate component-scoped rule both covering it), so the join below can return more
            -- than one row per aircraft. Sequence numbers are assigned afterwards, over the
            -- deduped set, so each aircraft still gets exactly one maintenance program row.
            ;WITH MatchedAircraftRaw AS
            (
                SELECT DISTINCT
                    ar.AircraftRegistryId,
                    ar.TailNum,
                    ar.MakeType,
                    ar.AircraftModel,
                    ar.SerialNum
                FROM [dbo].[AircraftRegistryHeader] ar WITH (NOLOCK)
                INNER JOIN [dbo].[AircraftEffectivity] ae WITH (NOLOCK)
                    ON ae.MakeTypeId = ar.MakeTypeId
                    AND ae.AircraftPublicationId = @AircraftPublicationId
                    AND ISNULL(ae.IsDeleted, 0) = 0
                    AND (ae.AircraftModelId IS NULL OR ar.AircraftModelId = ae.AircraftModelId)
                    AND (
                          -- Case A: rule HAS aircraft affect rows -> registry serial must be in that list
                          (
                              EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AF WITH (NOLOCK)
                                      WHERE AF.AircraftEffectivityId = ae.AircraftEffectivityId
                                        AND AF.IsAircraftSerialNum = 1 AND AF.IsAffect = 1 AND AF.IsDeleted = 0)
                              AND EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AF WITH (NOLOCK)
                                          WHERE AF.AircraftEffectivityId = ae.AircraftEffectivityId
                                            AND AF.IsAircraftSerialNum = 1 AND AF.IsAffect = 1 AND AF.IsDeleted = 0
                                            AND (
                                                (AF.FromSerial = ar.SerialNum)
                                            ))
                          )
                          OR
                          -- Case B: NO affect rows -> if the picker has EVER touched this rule's
                          -- AC-level data (any affect OR except row), trust the child table and treat
                          -- "no affects" as wildcard -- AircraftEffectivity.SerialNum isn't kept in
                          -- sync once the grid's eye icon edits only the child table. Only fall back
                          -- to the legacy single-value/blank field when completely untouched by the picker.
                          (
                              NOT EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AF WITH (NOLOCK)
                                          WHERE AF.AircraftEffectivityId = ae.AircraftEffectivityId
                                            AND AF.IsAircraftSerialNum = 1 AND AF.IsAffect = 1 AND AF.IsDeleted = 0)
                              AND (
                                    EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail ANYAC WITH (NOLOCK)
                                            WHERE ANYAC.AircraftEffectivityId = ae.AircraftEffectivityId
                                              AND ANYAC.IsAircraftSerialNum = 1 AND ANYAC.IsDeleted = 0)
                                    OR (ISNULL(ae.SerialNum, '') <> '' AND ae.SerialNum = ar.SerialNum)
                                    OR ISNULL(ae.SerialNum, '') = ''
                                  )
                          )
                        )
                    -- Aircraft-level exclusion: skip if this aircraft's serial has been
                    -- explicitly excepted for this rule
                    AND NOT EXISTS (
                        SELECT 1
                        FROM dbo.AircraftEffectivitySerialDetail EXC WITH (NOLOCK)
                        WHERE EXC.AircraftEffectivityId = ae.AircraftEffectivityId
                          AND EXC.IsAircraftSerialNum    = 1
                          AND EXC.IsAffect               = 0
                          AND EXC.IsDeleted              = 0
                          AND EXC.FromSerial             = ar.SerialNum
                    )
                WHERE
                    ar.MasterCompanyId = @MasterCompanyId
                    AND ISNULL(ar.IsDeleted, 0) = 0
                    AND NOT EXISTS
                    (
                        SELECT 1
                        FROM [dbo].[AircraftMaintenanceProgram] amp WITH (NOLOCK)
                        WHERE amp.AircraftPublicationId = @AircraftPublicationId
                          AND amp.AircraftRegistryId = ar.AircraftRegistryId
                          AND ISNULL(amp.IsDeleted, 0) = 0
                    )
            ),
            MatchedAircraft AS
            (
                SELECT
                    AircraftRegistryId,
                    TailNum,
                    MakeType,
                    AircraftModel,
                    SerialNum,
                    ROW_NUMBER() OVER (ORDER BY AircraftRegistryId) AS RowNum
                FROM MatchedAircraftRaw
            )
            INSERT INTO [dbo].[AircraftMaintenanceProgram]
            (
                AircraftRegistryId,
                TailNumber,
                AircraftMake,
                AircraftModel,
                SerialNumber,
                MaintenanceType,
                MtcCategoryId,
                AircraftPublicationId,
                IsFromAircraft,
                SequenceNo,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
                IsActive,
                IsDeleted
            )
            SELECT
                ma.AircraftRegistryId,
                ma.TailNum,
                ma.MakeType,
                ma.AircraftModel,
                ma.SerialNum,
                @PubNum,
                @MtcCategoryId,
                @AircraftPublicationId,
                1,
                @OldSequenceNum + ma.RowNum,
                @MasterCompanyId,
                @CreatedBy,
                @CreatedBy,
                GETUTCDATE(),
                GETUTCDATE(),
                1,
                0
            FROM MatchedAircraft ma;

            SET @AffectedRows = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @AffectedRows AS RecordsCreated;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_CreateAircraftPublicationMaintenance',
            @ProcedureParameters VARCHAR(3000) =
                '@AircraftPublicationId = ' + ISNULL(CAST(@AircraftPublicationId AS VARCHAR(20)), 'NULL')
                + ', @MasterCompanyId = '   + ISNULL(CAST(@MasterCompanyId       AS VARCHAR(20)), 'NULL')
                + ', @CreatedBy = '         + ISNULL(@CreatedBy, 'NULL'),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected error in the database. Please provide error number %d to the support team.',
            16, 1, @ErrorLogID
        );

        RETURN 1;

    END CATCH;
END;