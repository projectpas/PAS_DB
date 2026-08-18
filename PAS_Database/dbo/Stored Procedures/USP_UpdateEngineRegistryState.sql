/************************************************************
** File:        [USP_UpdateEngineRegistryState]
** Author:      Amit Ghediya
** Description: Update IsDeleted / IsActive state on an
**              EngineRegistryHeader row by Id.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    02-07-2026   Amit Ghediya   Created
************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateEngineRegistryState]
    @EngineRegistryId BIGINT,
    @MasterCompanyId    INT,
    @IsDeleted          BIT = NULL,
    @IsActive           BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @AffectedRows INT;

        BEGIN TRANSACTION;

            UPDATE [dbo].[EngineRegistryHeader]
            SET
                IsDeleted   = CASE WHEN @IsDeleted IS NOT NULL THEN @IsDeleted ELSE IsDeleted END,
                IsActive    = CASE WHEN @IsActive  IS NOT NULL THEN @IsActive  ELSE IsActive  END,
                UpdatedDate = GETUTCDATE()
            WHERE
                EngineRegistryId = @EngineRegistryId
                AND MasterCompanyId = @MasterCompanyId;

            SET @AffectedRows = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return the Id on success, -1 when no row matched the WHERE clause.
        SELECT CASE WHEN @AffectedRows > 0 THEN @EngineRegistryId ELSE -1 END AS EngineRegistryId;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_UpdateEngineRegistryState',
            @ProcedureParameters VARCHAR(3000) =
                '@EngineRegistryId = ' + ISNULL(CAST(@EngineRegistryId AS VARCHAR(20)), 'NULL')
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