/************************************************************
** File:        [USP_GetDistinctWorksheetDefects]
** Description: Returns the distinct, non-blank DefectDescription values
**              currently in use on WorksheetPart, for a company -- feeds
**              the "Defects" autocomplete on the Worksheet Add/Edit screen
**              so a user can pick an existing defect description or type
**              a brand new one (free text is still accepted and saved).
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    24/07/2026  Amit Ghediya      Created
************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetDistinctWorksheetDefects]
    @MasterCompanyId INT
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        SELECT DISTINCT
            WP.DefectDescription AS Value,
            WP.DefectDescription AS Label
        FROM [dbo].[WorksheetPart] WP WITH (NOLOCK)
        WHERE WP.MasterCompanyId = @MasterCompanyId
          AND ISNULL(WP.IsDeleted, 0) = 0
          AND ISNULL(WP.DefectDescription, '') <> ''
        ORDER BY WP.DefectDescription;

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetDistinctWorksheetDefects',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL'),
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