/************************************************************
** File:        [USP_AutoAssignSBADApplicability]
** Author:      Vishal Suthar
** Description: When Auto Assign SB/AD Applicability is on in Publication Setting,
**              creates the maintenance records for every aircraft matching a
**              publication's effectivity and marks the publication applicable.
**              Runs for one publication (by @AircraftPublicationId or
**              @AircraftEffectivityId) or for all publications of the company.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    17/11/2026   Vishal Suthar   Created [PN-18547]
************************************************************/
CREATE PROCEDURE [dbo].[USP_AutoAssignSBADApplicability]
    @MasterCompanyId        INT,
    @AircraftPublicationId  BIGINT       = NULL,
    @AircraftEffectivityId  BIGINT       = NULL,
    @CreatedBy              VARCHAR(256)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        IF NOT EXISTS (SELECT 1 FROM [dbo].[PublicationSettings] WITH (NOLOCK)
                       WHERE [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted], 0) = 0
                         AND [IsAutoAssignSBADApplicability] = 1)
        BEGIN
            SELECT 0 AS RecordsCreated;
            RETURN 0;
        END

        IF ISNULL(@AircraftPublicationId, 0) = 0 AND ISNULL(@AircraftEffectivityId, 0) > 0
        BEGIN
            SELECT @AircraftPublicationId = [AircraftPublicationId] FROM [dbo].[AircraftEffectivity] WITH (NOLOCK)
            WHERE [AircraftEffectivityId] = @AircraftEffectivityId;
        END

        DECLARE @Publications TABLE (AircraftPublicationId BIGINT PRIMARY KEY);
        DECLARE @Result TABLE (RecordsCreated INT);
        DECLARE @PublicationId BIGINT;

        INSERT INTO @Publications (AircraftPublicationId)
        SELECT AP.[AircraftPublicationId]
        FROM [dbo].[AircraftPublication] AP WITH (NOLOCK)
        WHERE AP.[MasterCompanyId] = @MasterCompanyId
          AND ISNULL(AP.[IsDeleted], 0) = 0 AND ISNULL(AP.[IsActive], 1) = 1
          AND (ISNULL(@AircraftPublicationId, 0) = 0 OR AP.[AircraftPublicationId] = @AircraftPublicationId)
          AND EXISTS (SELECT 1 FROM [dbo].[AircraftEffectivity] AE WITH (NOLOCK)
                      WHERE AE.[AircraftPublicationId] = AP.[AircraftPublicationId] AND ISNULL(AE.[IsDeleted], 0) = 0);

        -- Reuse the existing matching logic; it skips aircraft that already have a record
        DECLARE db_cursorPublication CURSOR LOCAL FAST_FORWARD FOR
        SELECT AircraftPublicationId FROM @Publications;
        OPEN db_cursorPublication;
        FETCH NEXT FROM db_cursorPublication INTO @PublicationId;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO @Result (RecordsCreated)
            EXEC [dbo].[USP_CreateAircraftPublicationMaintenance] @AircraftPublicationId = @PublicationId, @MasterCompanyId = @MasterCompanyId, @CreatedBy = @CreatedBy;

            FETCH NEXT FROM db_cursorPublication INTO @PublicationId;
        END
        CLOSE db_cursorPublication;
        DEALLOCATE db_cursorPublication;

        -- A publication with maintenance records is applicable
        UPDATE AP
        SET AP.[Applicability] = 1, AP.[UpdatedBy] = @CreatedBy, AP.[UpdatedDate] = GETUTCDATE()
        FROM [dbo].[AircraftPublication] AP
        INNER JOIN @Publications P ON P.AircraftPublicationId = AP.[AircraftPublicationId]
        WHERE ISNULL(AP.[Applicability], 0) = 0
          AND EXISTS (SELECT 1 FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
                      WHERE AMP.[AircraftPublicationId] = AP.[AircraftPublicationId] AND ISNULL(AMP.[IsDeleted], 0) = 0);

        SELECT ISNULL(SUM(RecordsCreated), 0) AS RecordsCreated FROM @Result;

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_AutoAssignSBADApplicability',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = '         + ISNULL(CAST(@MasterCompanyId       AS VARCHAR(20)), 'NULL')
                + ', @AircraftPublicationId = ' + ISNULL(CAST(@AircraftPublicationId AS VARCHAR(20)), 'NULL')
                + ', @AircraftEffectivityId = ' + ISNULL(CAST(@AircraftEffectivityId AS VARCHAR(20)), 'NULL')
                + ', @CreatedBy = '             + ISNULL(@CreatedBy, 'NULL'),
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
