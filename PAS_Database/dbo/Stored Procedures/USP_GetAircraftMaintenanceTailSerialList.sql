/************************************************************
** File:        [USP_GetAircraftMaintenanceTailSerialList]
** Description: Returns the distinct Tail Num / Serial Num pairs that exist
**              on (non-deleted) AircraftMaintenanceProgram records for a
**              company -- feeds the "Tail Num" and "Serial Num" header
**              filter dropdowns on Maintenance List (All Aircraft, All
**              Sections). Pairs (not two flat lists) are returned so the
**              UI can narrow Serial Num by the selected Tail Num and vice
**              versa without another round trip.
**
**              TailNumber / SerialNumber are resolved exactly like
**              USP_GetAircraftMaintenanceList's REG apply: aircraft rows
**              use AircraftRegistryHeader, engine rows use
**              EngineRegistryHeader (TailNumber = Engine Name for engine
**              rows, matching what the AC Tail Num column shows).
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    16/11/2026   Bhargav Saliya  Created [PN-18505]
************************************************************/
-- EXEC [dbo].[USP_GetAircraftMaintenanceTailSerialList] @MasterCompanyId = 1;
CREATE PROCEDURE [dbo].[USP_GetAircraftMaintenanceTailSerialList]
    @MasterCompanyId INT
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        SELECT DISTINCT
            REG.TailNumber,
            REG.SerialNumber,
            REG.IsFromAircraft
        FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
        LEFT JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
               ON AMP.AircraftRegistryId = ARH.AircraftRegistryId
              AND ARH.MasterCompanyId    = @MasterCompanyId
        LEFT JOIN [dbo].[EngineRegistryHeader] ERH WITH (NOLOCK)
               ON AMP.EngineRegistryId = ERH.EngineRegistryId
              AND ERH.MasterCompanyId  = @MasterCompanyId
        CROSS APPLY (
            SELECT
                CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN NULLIF(LTRIM(RTRIM(ARH.TailNum)), '')
                     ELSE NULLIF(LTRIM(RTRIM(ERH.EngineName)), '') END AS TailNumber,
                CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN NULLIF(LTRIM(RTRIM(ARH.SerialNum)), '')
                     ELSE NULLIF(LTRIM(RTRIM(ERH.SerialNum)), '') END AS SerialNumber,
                CAST(ISNULL(AMP.IsFromAircraft, 0) AS BIT) AS IsFromAircraft
        ) REG
        WHERE AMP.MasterCompanyId = @MasterCompanyId
          AND ISNULL(AMP.IsDeleted, 0) = 0
          AND (REG.TailNumber IS NOT NULL OR REG.SerialNumber IS NOT NULL)
        ORDER BY REG.TailNumber, REG.SerialNumber;

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftMaintenanceTailSerialList',
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
