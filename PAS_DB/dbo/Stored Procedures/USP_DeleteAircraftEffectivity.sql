/************************************************************
** File:        [USP_DeleteAircraftEffectivity]
** Author:      Amit Ghediya
** Description: Soft-deletes an Aircraft Effectivity rule -- the
**              AircraftEffectivity header row and its related
**              AircraftEffectivitySerialDetail rows (Aircraft/Component
**              affects + except entries), matched by AircraftEffectivityId.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    13/07/2026  Amit Ghediya      Created
************************************************************/
CREATE PROCEDURE [dbo].[USP_DeleteAircraftEffectivity]
    @AircraftEffectivityId BIGINT,
    @MasterCompanyId       INT,
    @UpdatedBy             VARCHAR(256)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @AffectedRows INT;

        BEGIN TRANSACTION;

            UPDATE [dbo].[AircraftEffectivity]
            SET
                IsDeleted   = 1,
                IsActive    = 0,
                UpdatedBy   = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE
                AircraftEffectivityId = @AircraftEffectivityId
                AND MasterCompanyId = @MasterCompanyId;

            SET @AffectedRows = @@ROWCOUNT;

            UPDATE [dbo].[AircraftEffectivitySerialDetail]
            SET
                IsDeleted   = 1,
                UpdatedBy   = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE
                AircraftEffectivityId = @AircraftEffectivityId
                AND MasterCompanyId = @MasterCompanyId
                AND IsDeleted = 0;

        COMMIT TRANSACTION;

        -- Return the Id on success, -1 when no AircraftEffectivity row matched the WHERE clause.
        SELECT CASE WHEN @AffectedRows > 0 THEN @AircraftEffectivityId ELSE -1 END AS AircraftEffectivityId;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_DeleteAircraftEffectivity',
            @ProcedureParameters VARCHAR(3000) =
                '@AircraftEffectivityId = ' + ISNULL(CAST(@AircraftEffectivityId AS VARCHAR(20)), 'NULL')
                + ', @MasterCompanyId = '   + ISNULL(CAST(@MasterCompanyId       AS VARCHAR(20)), 'NULL'),
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