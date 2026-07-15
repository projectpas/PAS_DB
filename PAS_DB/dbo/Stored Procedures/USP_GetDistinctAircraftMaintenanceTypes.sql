/************************************************************
** File:        [USP_GetDistinctAircraftMaintenanceTypes]
** Description: Returns the distinct, non-blank MaintenanceType values
**              currently in use on AircraftMaintenanceProgram, for a
**              company -- feeds the "Mtce Type" filter dropdown on the
**              Aircraft Maintenance List. Kept as its own small SP
**              (rather than adding a branch to the shared, heavily-used
**              AutoCompleteDropdowns SP) since Scheduled maintenance
**              types come from a fixed lookup (VW_WorkScopeType) but
**              Unscheduled maintenance types are arbitrary free text
**              typed by the user, so the dropdown must reflect whatever
**              values actually exist on real records.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    14/07/2026  Amit Ghediya      Created
************************************************************/
CREATE PROCEDURE [dbo].[USP_GetDistinctAircraftMaintenanceTypes]
    @MasterCompanyId INT
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        SELECT DISTINCT
            AMP.MaintenanceType AS Value,
            AMP.MaintenanceType AS Label
        FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
        WHERE AMP.MasterCompanyId = @MasterCompanyId
          AND ISNULL(AMP.IsDeleted, 0) = 0
          AND ISNULL(AMP.MaintenanceType, '') <> ''
        ORDER BY AMP.MaintenanceType;

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetDistinctAircraftMaintenanceTypes',
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