/************************************************************
** File:        [USP_UpdateAircraftPublicationState]
** Author:      Amit Ghediya
** Description: Update IsDeleted / IsActive state on an
**              AircraftPublicationHeader row by Id.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    01/05/2026  Amit Ghediya		Created 
************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateAircraftPublicationState]
    @AircraftPublicationId BIGINT,
    @MasterCompanyId    INT,
    @IsDeleted          BIT = NULL,
    @IsActive           BIT = NULL
AS
BEGIN
    
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @AffectedRows INT;

        BEGIN TRANSACTION;

            UPDATE [dbo].[AircraftPublication]
            SET
                IsDeleted   = CASE WHEN @IsDeleted IS NOT NULL THEN @IsDeleted ELSE IsDeleted END,
                IsActive    = CASE WHEN @IsActive  IS NOT NULL THEN @IsActive  ELSE IsActive  END,
                UpdatedDate = GETUTCDATE()
            WHERE
                AircraftPublicationId = @AircraftPublicationId
                AND MasterCompanyId = @MasterCompanyId;

            SET @AffectedRows = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return the Id on success, -1 when no row matched the WHERE clause.
        SELECT CASE WHEN @AffectedRows > 0 THEN @AircraftPublicationId ELSE -1 END AS AircraftPublicationId;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_UpdateAircraftPublicationState',
            @ProcedureParameters VARCHAR(3000) =
                '@AircraftPublicationId = ' + ISNULL(CAST(@AircraftPublicationId AS VARCHAR(20)), 'NULL')
                + ', @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId   AS VARCHAR(20)), 'NULL')
                + ', @IsDeleted = '       + ISNULL(CAST(@IsDeleted         AS VARCHAR(5)),  'NULL')
                + ', @IsActive = '        + ISNULL(CAST(@IsActive          AS VARCHAR(5)),  'NULL'),
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