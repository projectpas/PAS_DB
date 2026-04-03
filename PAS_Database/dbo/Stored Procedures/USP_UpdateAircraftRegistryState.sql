/************************************************************
** File:        [USP_UpdateAircraftRegistryState]
** Author:      Priyansh Patel
** Description: Update IsDeleted / IsActive state on an
**              AircraftRegistryHeader row by Id.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    26-03-2025   Priyansh Patel  Created [PN-15841]
************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateAircraftRegistryState]
    @AircraftRegistryId BIGINT,
    @MasterCompanyId    INT,
    @IsDeleted          BIT = NULL,
    @IsActive           BIT = NULL
AS
BEGIN
    -- NOTE: READ UNCOMMITTED has no effect on DML statements.
    -- UPDATE always acquires row-level exclusive locks regardless
    -- of session isolation level. Removed to avoid confusion.
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @AffectedRows INT;

        BEGIN TRANSACTION;

            UPDATE [dbo].[AircraftRegistryHeader]
            SET
                IsDeleted   = CASE WHEN @IsDeleted IS NOT NULL THEN @IsDeleted ELSE IsDeleted END,
                IsActive    = CASE WHEN @IsActive  IS NOT NULL THEN @IsActive  ELSE IsActive  END,
                UpdatedDate = GETUTCDATE()
            WHERE
                AircraftRegistryId = @AircraftRegistryId
                AND MasterCompanyId = @MasterCompanyId;

            -- @@ROWCOUNT must be captured immediately; any subsequent
            -- statement (including SELECT) resets it to 0.
            SET @AffectedRows = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return the Id on success, -1 when no row matched the WHERE clause.
        SELECT CASE WHEN @AffectedRows > 0 THEN @AircraftRegistryId ELSE -1 END AS AircraftRegistryId;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_UpdateAircraftRegistryState',
            @ProcedureParameters VARCHAR(3000) =
                '@AircraftRegistryId = ' + ISNULL(CAST(@AircraftRegistryId AS VARCHAR(20)), 'NULL')
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
