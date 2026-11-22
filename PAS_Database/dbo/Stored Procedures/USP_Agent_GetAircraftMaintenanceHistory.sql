/****************************************************************************************************
** File:        [USP_Agent_GetAircraftMaintenanceHistory]
** Description: PAS Assistant (AI agent) tool "get_aircraft_maintenance_history".
**              Maintenance history of one aircraft, looked up by tail number or AC registration number.
**              Same data as the Aircraft Registry > Maintenance list (USP_GetAircraftMaintenanceList):
**              airframe programs of the aircraft + programs of the engines linked to it
**              (AircraftRegistryHeader.EngineRegistryIds), with the latest work order and worksheet.
**
**              Always returns TWO result sets:
**                1. Matched aircraft (max 10). Exact tail/registration matches win over partial ones.
**                2. Maintenance history (newest first, max @Top rows, TotalRecords = full count).
**                   Filled only when exactly one aircraft matched; otherwise empty.
**
** Parameters:  @MasterCompanyId            - required, tenant filter
**              @TailOrRegistrationNumber   - required, exact or contains match on TailNum / AircraftRegistryNumber
**              @Top                        - max history rows returned
*****************************************************************************************************
** Change History
*****************************************************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    20/11/2026   Hemant             Created (PAS Assistant aircraft maintenance history tool)
*****************************************************************************************************/
-- EXEC [dbo].[USP_Agent_GetAircraftMaintenanceHistory] @MasterCompanyId = 1, @TailOrRegistrationNumber = 'N123';
CREATE   PROCEDURE [dbo].[USP_Agent_GetAircraftMaintenanceHistory]
    @MasterCompanyId            INT,
    @TailOrRegistrationNumber   VARCHAR(50),
    @Top                        INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Search VARCHAR(50) = NULLIF(LTRIM(RTRIM(@TailOrRegistrationNumber)), '');

        -- "contains" pattern; LIKE wildcards typed by the user are matched literally
        DECLARE @Pattern VARCHAR(160) =
            '%' + REPLACE(REPLACE(REPLACE(@Search, '[', '[[]'), '%', '[%]'), '_', '[_]') + '%';

        --------------------------------------------------------------------------------
        -- 1. Find the aircraft
        --------------------------------------------------------------------------------
        DECLARE @Aircraft TABLE
        (
            AircraftRegistryId      BIGINT PRIMARY KEY,
            AircraftRegistryNumber  VARCHAR(30),
            TailNum                 VARCHAR(50),
            MakeType                VARCHAR(256),
            AircraftModel           VARCHAR(256),
            SerialNum               VARCHAR(100),
            EngineRegistryIds       NVARCHAR(500),
            IsExact                 BIT
        );

        IF (@Search IS NOT NULL)
        BEGIN
            INSERT INTO @Aircraft
            SELECT TOP (10)
                ARH.AircraftRegistryId, ARH.AircraftRegistryNumber, ARH.TailNum, ARH.MakeType, ARH.AircraftModel,
                ARH.SerialNum, ARH.EngineRegistryIds,
                CASE WHEN ARH.TailNum = @Search OR ARH.AircraftRegistryNumber = @Search THEN 1 ELSE 0 END
            FROM [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
            WHERE ARH.MasterCompanyId = @MasterCompanyId
              AND ARH.IsDeleted = 0
              AND (ARH.TailNum LIKE @Pattern OR ARH.AircraftRegistryNumber LIKE @Pattern)
            ORDER BY CASE WHEN ARH.TailNum = @Search OR ARH.AircraftRegistryNumber = @Search THEN 0 ELSE 1 END, ARH.TailNum;

            -- Exact matches win, so "N123" does not also pick up "N1234"
            IF EXISTS (SELECT 1 FROM @Aircraft WHERE IsExact = 1)
                DELETE FROM @Aircraft WHERE IsExact = 0;
        END;

        -- Result set 1: matched aircraft
        SELECT
            AircraftRegistryNumber  AS acRegNumber,
            TailNum                 AS tailNumber,
            MakeType                AS make,
            AircraftModel           AS model,
            SerialNum               AS serialNumber
        FROM @Aircraft
        ORDER BY TailNum;

        --------------------------------------------------------------------------------
        -- 2. History - only when exactly one aircraft matched
        --------------------------------------------------------------------------------
        DECLARE @AircraftRegistryId BIGINT, @RegNum VARCHAR(30), @Tail VARCHAR(50), @EngineIdList NVARCHAR(500);

        IF ((SELECT COUNT(1) FROM @Aircraft) = 1)
            SELECT @AircraftRegistryId = AircraftRegistryId, @RegNum = AircraftRegistryNumber,
                   @Tail = TailNum, @EngineIdList = EngineRegistryIds
            FROM @Aircraft;

        DECLARE @EngineIds TABLE (EngineRegistryId BIGINT PRIMARY KEY);

        INSERT INTO @EngineIds (EngineRegistryId)
        SELECT DISTINCT TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value)))
        FROM STRING_SPLIT(ISNULL(@EngineIdList, ''), ',') s
        WHERE TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value))) IS NOT NULL;

        -- Result set 2: maintenance history (empty when @AircraftRegistryId is NULL)
        ;WITH CTE AS
        (
            SELECT
                AMP.ProgramId,
                AMP.IsFromAircraft,
                ERH.EngineName,
                AMP.MaintenanceType,
                AMP.[Description],
                AMP.UpdatedDate,
                AMP.LastInspectedDate,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
            LEFT JOIN [dbo].[EngineRegistryHeader] ERH WITH (NOLOCK)
                   ON ERH.EngineRegistryId = AMP.EngineRegistryId
                  AND ERH.MasterCompanyId  = @MasterCompanyId
            WHERE @AircraftRegistryId IS NOT NULL
              AND AMP.MasterCompanyId = @MasterCompanyId
              AND AMP.IsDeleted = 0
              AND (   (ISNULL(AMP.IsFromAircraft, 0) = 1 AND AMP.AircraftRegistryId = @AircraftRegistryId)
                   OR (ISNULL(AMP.IsFromAircraft, 0) = 0 AND AMP.EngineRegistryId IN (SELECT EngineRegistryId FROM @EngineIds)))
        )
        SELECT TOP (@Top)
            @RegNum                                                    AS acRegNumber,
            @Tail                                                      AS tailNumber,
            CASE WHEN ISNULL(C.IsFromAircraft, 0) = 1 THEN 'Airframe' ELSE C.EngineName END AS component,
            C.MaintenanceType                                          AS maintenanceType,
            C.[Description]                                            AS maintenanceDetails,
            CONVERT(VARCHAR(10), C.UpdatedDate, 23)                    AS [date],
            CONVERT(VARCHAR(10), C.LastInspectedDate, 23)              AS lastInspectedDate,
            LWO.WorkOrderNum                                           AS workOrderNumber,
            LWO.WorkOrderStatus                                        AS workOrderStatus,
            WSH.WorksheetNumber                                        AS worksheetNumber,
            C.TotalRecords
        FROM CTE C
        -- Latest work order per program
        OUTER APPLY (
            SELECT TOP (1) WO.WorkOrderNum, WOP.WorkOrderStatus
            FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.ProgramId = C.ProgramId
            ORDER BY WO.WorkOrderId DESC
        ) LWO
        -- Latest worksheet per program
        OUTER APPLY (
            SELECT TOP (1) W.WorksheetNumber
            FROM [dbo].[WorksheetMapping] WSM WITH (NOLOCK)
            INNER JOIN [dbo].[WorksheetHeader] W WITH (NOLOCK) ON W.WorksheetHeaderId = WSM.WorksheetHeaderId
            WHERE WSM.ProgramId = C.ProgramId
            ORDER BY W.CreatedDate DESC
        ) WSH
        ORDER BY C.UpdatedDate DESC, C.ProgramId DESC;

    END TRY

    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_Agent_GetAircraftMaintenanceHistory',
            @ProcedureParameters VARCHAR(3000) =
                  '@MasterCompanyId = '            + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL')
                + ', @TailOrRegistrationNumber = ' + ISNULL(@TailOrRegistrationNumber, 'NULL')
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
