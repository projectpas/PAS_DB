/****************************************************************************************************
** File:        [USP_Agent_SearchInstalledComponents]
** Description: PAS Assistant (AI agent) tool "search_installed_components".
**              Lists components installed on aircraft with the aircraft they are installed on,
**              installed date/time/cycles, maintenance intervals (limits), recorded and remaining
**              time/cycles, last and next scheduled maintenance.
**              Same source and remaining-value rules as USP_GetAircraftComponentMaintenanceDashboardList
**              (INSTALLED rows), except:
**                - remaining time is not floored at 0 (negative = overdue)
**                - NextScheduledMaintenance = LastInspectionDate + service life
**                - deleted installed parts / aircraft are excluded
**              Times are flight hours formatted as H:mm.
**
** Parameters:  @MasterCompanyId            - required, tenant filter
**              @TailOrRegistrationNumber   - optional, contains match on TailNum / AircraftRegistryNumber
**              @PartNumber                 - optional, contains match on component part number
**              @Top                        - max rows returned (TotalRecords gives the full match count)
*****************************************************************************************************
** Change History
*****************************************************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    20/11/2026   Hemant             Created (PAS Assistant installed components tool)
*****************************************************************************************************/
-- EXEC [dbo].[USP_Agent_SearchInstalledComponents] @MasterCompanyId = 1, @TailOrRegistrationNumber = 'N123';
CREATE   PROCEDURE [dbo].[USP_Agent_SearchInstalledComponents]
    @MasterCompanyId            INT,
    @TailOrRegistrationNumber   VARCHAR(50) = NULL,
    @PartNumber                 VARCHAR(50) = NULL,
    @Top                        INT         = 25
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);

        -- "contains" patterns; LIKE wildcards typed by the user are matched literally
        DECLARE @AcPattern VARCHAR(160) = CASE WHEN NULLIF(LTRIM(RTRIM(@TailOrRegistrationNumber)), '') IS NULL THEN NULL
                ELSE '%' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@TailOrRegistrationNumber)), '[', '[[]'), '%', '[%]'), '_', '[_]') + '%' END;
        DECLARE @PnPattern VARCHAR(160) = CASE WHEN NULLIF(LTRIM(RTRIM(@PartNumber)), '') IS NULL THEN NULL
                ELSE '%' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PartNumber)), '[', '[[]'), '%', '[%]'), '_', '[_]') + '%' END;

        ;WITH CTE AS
        (
            SELECT
                IP.AircraftInstalledPartDetailsId,
                IP.PartNumber,
                IP.PartDescription,
                IP.SerialNumber,
                ARH.AircraftRegistryNumber,
                ARH.TailNum,
                IP.DateInstalled,
                CAST(IP.InstallCycles AS BIGINT)  AS InstallCycles,
                CAST(IP.PartCycles    AS BIGINT)  AS CycleLimit,
                CAST(IP.Cycles        AS BIGINT)  AS RecordedCycles,
                IP.ServiceLifeUnitMonthsOrDays,
                IP.ServiceLifeLimit,
                IP.LastInspectionDate,
                IP.UpdatedDate                    AS LastMaintenance,
                M.InstallMinutes,
                M.LimitMinutes,
                M.RecordedMinutes,
                CASE IP.ServiceLifeUnitMonthsOrDays
                     WHEN 1 THEN DATEADD(MONTH, IP.ServiceLifeLimit, IP.LastInspectionDate)
                     WHEN 2 THEN DATEADD(DAY,   IP.ServiceLifeLimit, IP.LastInspectionDate)
                END                               AS NextScheduled,
                COUNT(1) OVER ()                  AS TotalRecords
            FROM [dbo].[AircraftInstalledPartDetails] IP WITH (NOLOCK)
            INNER JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
                    ON ARH.AircraftRegistryId = IP.AircraftRegistryId
                   AND ARH.MasterCompanyId    = @MasterCompanyId
                   AND ARH.IsDeleted          = 0
            INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)
                    ON IM.ItemMasterId = IP.ItemMasterId
                   AND ISNULL(IM.IsNonStock, 0) = 0
            -- Flight time in minutes, computed once
            CROSS APPLY (
                SELECT
                    CAST(ISNULL(IP.InstallFlightHours, 0) AS BIGINT) * 60 + CAST(ISNULL(IP.InstallFlightTime, 0)  AS BIGINT) AS InstallMinutes,
                    CAST(ISNULL(IP.PartFlightHours, 0)    AS BIGINT) * 60 + CAST(ISNULL(IP.PartFlightMinutes, 0)  AS BIGINT) AS LimitMinutes,
                    CAST(ISNULL(IP.FlightHours, 0)        AS BIGINT) * 60 + CAST(ISNULL(IP.FlightMinutes, 0)      AS BIGINT) AS RecordedMinutes
            ) M
            WHERE IP.MasterCompanyId = @MasterCompanyId
              AND IP.IsDeleted = 0
              AND ISNULL(IP.IsFromAircraft, 0) = 1
              AND (@AcPattern IS NULL OR ARH.TailNum LIKE @AcPattern OR ARH.AircraftRegistryNumber LIKE @AcPattern)
              AND (@PnPattern IS NULL OR IP.PartNumber LIKE @PnPattern)
        )
        SELECT TOP (@Top)
            C.PartNumber                                               AS partNumber,
            C.PartDescription                                          AS [description],
            C.SerialNumber                                             AS serialNumber,
            C.AircraftRegistryNumber                                   AS acRegNumber,
            C.TailNum                                                  AS tailNumber,
            CONVERT(VARCHAR(10), C.DateInstalled, 23)                  AS installedDate,
            F.InstalledTime                                            AS installedTime,
            C.InstallCycles                                            AS installedCycle,
            F.TimeLimit                                                AS timeLimit,
            CASE WHEN C.ServiceLifeLimit > 0 AND C.ServiceLifeUnitMonthsOrDays = 1 THEN CAST(C.ServiceLifeLimit AS VARCHAR(20)) + ' Mths'
                 WHEN C.ServiceLifeLimit > 0 AND C.ServiceLifeUnitMonthsOrDays = 2 THEN CAST(C.ServiceLifeLimit AS VARCHAR(20)) + ' Days'
            END                                                        AS calendarLimit,
            NULLIF(C.CycleLimit, 0)                                    AS cycleLimit,
            F.RecordedTime                                             AS recordedTime,
            C.RecordedCycles                                           AS recordedCycle,
            F.RemainingTime                                            AS remainingTime,
            CASE WHEN C.NextScheduled IS NOT NULL
                 THEN CAST(DATEDIFF(DAY, @Today, C.NextScheduled) AS VARCHAR(20)) + ' Days'
            END                                                        AS calendarRemaining,
            CASE WHEN C.CycleLimit > 0
                 THEN C.CycleLimit - ISNULL(C.InstallCycles, 0) - ISNULL(C.RecordedCycles, 0)
            END                                                        AS remainingCycle,
            CONVERT(VARCHAR(10), C.LastMaintenance, 23)                AS lastMaintenance,
            CONVERT(VARCHAR(10), C.LastInspectionDate, 23)             AS lastInspectionDate,
            CONVERT(VARCHAR(10), C.NextScheduled, 23)                  AS nextScheduledMaintenance,
            C.TotalRecords
        FROM CTE C
        -- Remaining = limit - aircraft time at install - recorded (negative = overdue)
        CROSS APPLY (
            SELECT CASE WHEN C.LimitMinutes > 0 THEN C.LimitMinutes - C.InstallMinutes - C.RecordedMinutes END AS RemainingMinutes
        ) R
        -- Format minutes as H:mm
        CROSS APPLY (
            SELECT
                CAST(C.InstallMinutes / 60 AS VARCHAR(20)) + ':' + RIGHT('0' + CAST(C.InstallMinutes % 60 AS VARCHAR(2)), 2)   AS InstalledTime,
                CAST(C.RecordedMinutes / 60 AS VARCHAR(20)) + ':' + RIGHT('0' + CAST(C.RecordedMinutes % 60 AS VARCHAR(2)), 2) AS RecordedTime,
                CASE WHEN C.LimitMinutes > 0
                     THEN CAST(C.LimitMinutes / 60 AS VARCHAR(20)) + ':' + RIGHT('0' + CAST(C.LimitMinutes % 60 AS VARCHAR(2)), 2)
                END                                                                                                             AS TimeLimit,
                CASE WHEN R.RemainingMinutes IS NOT NULL
                     THEN CASE WHEN R.RemainingMinutes < 0 THEN '-' ELSE '' END
                          + CAST(ABS(R.RemainingMinutes) / 60 AS VARCHAR(20)) + ':'
                          + RIGHT('0' + CAST(ABS(R.RemainingMinutes) % 60 AS VARCHAR(2)), 2)
                END                                                                                                             AS RemainingTime
        ) F
        ORDER BY C.TailNum, C.PartNumber, C.AircraftInstalledPartDetailsId;

    END TRY

    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_Agent_SearchInstalledComponents',
            @ProcedureParameters VARCHAR(3000) =
                  '@MasterCompanyId = '            + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL')
                + ', @TailOrRegistrationNumber = ' + ISNULL(@TailOrRegistrationNumber, 'NULL')
                + ', @PartNumber = '               + ISNULL(@PartNumber, 'NULL')
                + ', @Top = '                      + ISNULL(CAST(@Top AS VARCHAR(10)), 'NULL'),
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
