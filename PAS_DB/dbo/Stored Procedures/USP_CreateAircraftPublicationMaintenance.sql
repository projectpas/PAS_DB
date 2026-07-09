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

************************************************************/
CREATE      PROCEDURE [dbo].[USP_CreateAircraftPublicationMaintenance]
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

        SELECT @MtcCategoryId = [MtcCategoryId] FROM DBO.MaintenanceCategory WITH(NOLOCK) WHERE [MtcCategory] = 'Unscheduled Maintenance' AND [MasterCompanyId] = @MasterCompanyId;

        SELECT @PubNum = [PubNum] FROM [dbo].[AircraftPublication] WITH (NOLOCK) WHERE [AircraftPublicationId] = @AircraftPublicationId;

        SET @OldSequenceNum = ISNULL((SELECT MAX(SequenceNo) FROM dbo.AircraftMaintenanceProgram WITH (NOLOCK)), 0);

        BEGIN TRANSACTION;

            ;WITH MatchedAircraft AS
            (
                SELECT
                    ar.AircraftRegistryId,
                    ar.TailNum,
                    ar.MakeType,
                    ar.AircraftModel,
                    ar.SerialNum,
                    ROW_NUMBER() OVER (ORDER BY ar.AircraftRegistryId) AS RowNum
                FROM [dbo].[AircraftRegistryHeader] ar WITH (NOLOCK)
                INNER JOIN [dbo].[AircraftEffectivity] ae WITH (NOLOCK)
                    ON ae.MakeTypeId = ar.MakeTypeId
                    AND ae.SerialNum = ar.SerialNum
                    AND ae.AircraftPublicationId = @AircraftPublicationId
                    AND ISNULL(ae.IsDeleted, 0) = 0
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