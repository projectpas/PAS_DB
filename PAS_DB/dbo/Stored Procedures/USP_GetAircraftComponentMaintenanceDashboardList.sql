
/****************************************************************************************************
** File:        [USP_GetAircraftComponentMaintenanceDashboardList]
** Description:
** Purpose:
** Date:
**
** RETURN VALUE:
*****************************************************************************************************
** Change History
*****************************************************************************************************
** PR   Date         Author				Change Description
** --   ----------   -------------		--------------------------------
** 1    29/05/2026   Abhishek Jirawla     Created [PN-16598]
*****************************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetAircraftComponentMaintenanceDashboardList]
(
    @PageNumber      INT           = 1,
    @PageSize        INT           = 10,
    @SortColumn      VARCHAR(100)  = NULL,
    @SortOrder       VARCHAR(4)    = 'DESC',
    @GlobalFilter    VARCHAR(100)  = NULL,
    @MasterCompanyId INT,
    @TailNumber      VARCHAR(50)   = NULL,
    @AircraftMake    VARCHAR(100)  = NULL,
    @SerialNumber    VARCHAR(100)  = NULL,
    @MtceCategory    VARCHAR(256)  = NULL,
    @MtceType        VARCHAR(200)  = NULL,
    @Section         VARCHAR(100)  = NULL,
    @PNNum           VARCHAR(100)  = NULL,
    @PNDescription   VARCHAR(100)  = NULL,
    @Qty             VARCHAR(50)   = NULL,
    @CustomerName    VARCHAR(200)  = NULL,
    @ATAChapter      VARCHAR(50)   = NULL,
    @LastMaintained  DATETIME      = NULL,
    @WONumber        VARCHAR(256)  = NULL,
    @NextScheduled   DATETIME      = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @SortColumn = UPPER(ISNULL(@SortColumn, 'ACTAILNUM'));

        ;WITH Combined AS
        (
            -- =====================================================================
            -- Source 1: Aircraft Maintenance Programs
            -- =====================================================================
            SELECT
                ARH.AircraftRegistryId,
                ARH.TailNum                                                        AS acTailNum,
                ARH.MakeType                                                       AS acMake,
                ARH.SerialNum                                                      AS serialNum,
                mtc.MtcCategory                                                    AS mtceCategory,
                AMP.MaintenanceType                                                AS mtceType,
                MC.[Name]                                                          AS section,
                WF.WorkOrderNumber                                                 AS pnNum,
                CAST(NULL AS NVARCHAR(MAX))                                        AS pnDescription,
                CAST(ISNULL(STK.QuantityAvailable, 0) AS DECIMAL(18,4))           AS qty,
                CAST(NULL AS NVARCHAR(200))                                        AS customerName,
                CAST(NULL AS NVARCHAR(200))                                        AS ataChpt,
                AMP.UpdatedDate                                                    AS lastMtced,
                LWO.WorkOrderNum                                                   AS woNum,
                LWO.WorkOrderId                                                    AS woId,
                AMP.NextScheduledMaintenance                                       AS nextSchdMtce,
                CAST(NULL AS DATETIME)                                             AS installedDate,
                CAST(NULL AS NVARCHAR(20))                                         AS installedTime,
                CAST(NULL AS BIGINT)                                               AS installedCycle,
                -- Limits
                AMP.CyclesLimit                                                    AS limitCycles,
                AMP.TimeLimit                                                      AS limitTime,
                AMP.LandingsLimit                                                  AS limitLandings,
                AMP.EngineStartsLimit                                              AS limitEngineStarts,
                AMP.FlightHoursLimitHours                                          AS LimitFlightHoursHours,
                AMP.FlightHoursLimitMinutes                                        AS LimitFlightHoursMinutes,
                CAST(AMP.FlightHoursLimitHours AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursLimitMinutes, 0) AS VARCHAR(5)), 2) AS limitFlightHours,
                -- Recorded
                AMP.CyclesRecorded                                                 AS recordCycles,
                AMP.TimeRecorded                                                   AS recordTime,
                AMP.LandingsRecorded                                               AS recordLandings,
                AMP.EngineStartsRecorded                                           AS recordEngineStarts,
                AMP.FlightHoursRecordedHours                                       AS RecordFlightHoursHours,
                AMP.FlightHoursRecordedMinutes                                     AS RecordFlightHoursMinutes,
                CAST(AMP.FlightHoursRecordedHours AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRecordedMinutes, 0) AS VARCHAR(5)), 2) AS recordFlightHours,
                -- Remaining
                CASE WHEN AMP.CyclesRemaining > 0 THEN AMP.CyclesRemaining ELSE NULL END AS remainingCycles,
                AMP.TimeRemaining                                                  AS remainingTime,
                AMP.LandingsRemaining                                              AS remainingLandings,
                AMP.EngineStartsRemaining                                          AS remainingEngineStarts,
                AMP.FlightHoursRemainingHours                                      AS RemainingFlightHoursHours,
                AMP.FlightHoursRemainingMinutes                                    AS RemainingFlightHoursMinutes,
                CAST(AMP.FlightHoursRemainingHours AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRemainingMinutes, 0) AS VARCHAR(5)), 2) AS remainingFlightHours,
                'MAINTENANCE'                                                      AS SourceType
            FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
            LEFT JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
                ON AMP.AircraftRegistryId = ARH.AircraftRegistryId AND ARH.MasterCompanyId = @MasterCompanyId
            LEFT JOIN [dbo].[MaintenanceClass] MC WITH (NOLOCK)
                ON AMP.MaintenanceClassId = MC.MaintenanceClassId
            LEFT JOIN [dbo].[Workflow] WF WITH (NOLOCK)
                ON AMP.TemplateId = WF.WorkflowId AND WF.TemplateType = 2
            LEFT JOIN [dbo].[MaintenanceCategory] mtc WITH (NOLOCK)
                ON AMP.MtcCategoryId = mtc.MtcCategoryId
            LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK)
                ON STK.StockLineId = ARH.StockLineId
            LEFT JOIN (
                SELECT WOP.[ProgramId], WO.[WorkOrderId], WO.[WorkOrderNum],
                       ROW_NUMBER() OVER (PARTITION BY WOP.[ProgramId] ORDER BY WO.[WorkOrderId] DESC) AS rn
                FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
                JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.[WorkOrderId] = WO.[WorkOrderId]
            ) LWO ON LWO.[ProgramId] = AMP.[ProgramId] AND LWO.rn = 1
            WHERE AMP.MasterCompanyId = @MasterCompanyId
              AND AMP.IsDeleted = 0

            UNION ALL

            -- =====================================================================
            -- Source 2: Aircraft Installed Part Details
            -- =====================================================================
            SELECT
                AIPD.AircraftRegistryId,
                ARH.TailNum                                                        AS acTailNum,
                ARH.MakeType                                                       AS acMake,
                ARH.SerialNum                                                      AS serialNum,
                CAST(NULL AS NVARCHAR(256))                                        AS mtceCategory,
                CAST(NULL AS NVARCHAR(200))                                        AS mtceType,
                AIPD.PositionCode                                                  AS section,
                AIPD.PartNumber                                                    AS pnNum,
                AIPD.PartDescription                                               AS pnDescription,
                CAST(ISNULL(AIPD.Quantity, 0) AS DECIMAL(18,4))                   AS qty,
                CAST(NULL AS NVARCHAR(200))                                        AS customerName,
                CONCAT_WS(' - ',
                    NULLIF(IMAM.Level1, ''),
                    NULLIF(IMAM.Level2, ''),
                    NULLIF(IMAM.Level3, '')
                )                                                                  AS ataChpt,
                AIPD.UpdatedDate                                                   AS lastMtced,
                LWO_I.WorkOrderNum                                                 AS woNum,
                LWO_I.WorkOrderId                                                  AS woId,
                CAST(NULL AS DATETIME)                                             AS nextSchdMtce,
                AIPD.DateInstalled                                                 AS installedDate,
                CAST(ISNULL(AIPD.[Hours], 0) AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AIPD.[Minutes], 0) AS VARCHAR(5)), 2) AS installedTime,
                CAST(AIPD.InstallCycles AS BIGINT)                                 AS installedCycle,
                -- Limits
                CAST(AIPD.PartCycles AS BIGINT)                                    AS limitCycles,
                CAST(NULL AS BIGINT)                                               AS limitTime,
                CAST(AIPD.PartLandings AS BIGINT)                                  AS limitLandings,
                CAST(AIPD.PartEngineStarts AS BIGINT)                              AS limitEngineStarts,
                CAST(ISNULL(AIPD.PartFlightHours, 0) AS INT)                      AS LimitFlightHoursHours,
                CAST(ISNULL(AIPD.PartFlightMinutes, 0) AS INT)                    AS LimitFlightHoursMinutes,
                CONCAT(
                    CAST(ISNULL(CAST(AIPD.PartFlightHours AS BIGINT), 0) AS VARCHAR(50)),
                    ':',
                    RIGHT('00' + CAST(ISNULL(CAST(AIPD.PartFlightMinutes AS INT), 0) AS VARCHAR(5)), 2)
                )                                                                  AS limitFlightHours,
                -- Recorded
                CAST(AIPD.Cycles AS BIGINT)                                        AS recordCycles,
                CAST(NULL AS BIGINT)                                               AS recordTime,
                CAST(AIPD.Landings AS BIGINT)                                      AS recordLandings,
                CAST(AIPD.EngineStarts AS BIGINT)                                  AS recordEngineStarts,
                CAST(ISNULL(AIPD.FlightHours, 0) AS INT) + CAST(ISNULL(AIPD.FlightMinutes, 0) AS INT) / 60 AS RecordFlightHoursHours,
                CAST(ISNULL(AIPD.FlightMinutes, 0) AS INT) % 60                   AS RecordFlightHoursMinutes,
                CAST(CAST(ISNULL(AIPD.FlightHours, 0) AS INT) + CAST(ISNULL(AIPD.FlightMinutes, 0) AS INT) / 60 AS VARCHAR(10))
                    + ':' + RIGHT('00' + CAST(CAST(ISNULL(AIPD.FlightMinutes, 0) AS INT) % 60 AS VARCHAR(5)), 2) AS recordFlightHours,
                -- Remaining
                CASE WHEN ISNULL(AIPD.PartCycles, 0) > 0
                     THEN ISNULL(AIPD.PartCycles, 0) - ISNULL(AIPD.InstallCycles, 0) - ISNULL(AIPD.Cycles, 0)
                     ELSE NULL END                                                 AS remainingCycles,
                CAST(NULL AS BIGINT)                                               AS remainingTime,
                CASE WHEN ISNULL(AIPD.PartLandings, 0) > 0
                     THEN ISNULL(AIPD.PartLandings, 0) - ISNULL(AIPD.Landings, 0)
                     ELSE NULL END                                                 AS remainingLandings,
                CASE WHEN ISNULL(AIPD.PartEngineStarts, 0) > 0
                     THEN ISNULL(AIPD.PartEngineStarts, 0) - ISNULL(AIPD.EngineStarts, 0)
                     ELSE NULL END                                                 AS remainingEngineStarts,
                CASE
                    WHEN ISNULL(AIPD.PartFlightHours, 0) = 0 AND ISNULL(AIPD.PartFlightMinutes, 0) = 0 THEN 0
                    WHEN ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                        - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                        - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) < 0 THEN 0
                    ELSE ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                        - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                        - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) / 60
                END                                                                AS RemainingFlightHoursHours,
                CASE
                    WHEN ISNULL(AIPD.PartFlightHours, 0) = 0 AND ISNULL(AIPD.PartFlightMinutes, 0) = 0 THEN 0
                    WHEN ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                        - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                        - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) < 0 THEN 0
                    ELSE ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                        - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                        - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) % 60
                END                                                                AS RemainingFlightHoursMinutes,
                CAST(
                    CASE
                        WHEN ISNULL(AIPD.PartFlightHours, 0) = 0 AND ISNULL(AIPD.PartFlightMinutes, 0) = 0 THEN 0
                        WHEN ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                            - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                            - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) < 0 THEN 0
                        ELSE ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                            - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                            - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) / 60
                    END AS VARCHAR(10)
                ) + ':' + RIGHT('00' + CAST(
                    CASE
                        WHEN ISNULL(AIPD.PartFlightHours, 0) = 0 AND ISNULL(AIPD.PartFlightMinutes, 0) = 0 THEN 0
                        WHEN ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                            - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                            - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) < 0 THEN 0
                        ELSE ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
                            - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
                            - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) % 60
                    END AS VARCHAR(5)), 2)                                         AS remainingFlightHours,
                'INSTALLED'                                                        AS SourceType
            FROM dbo.AircraftInstalledPartDetails AIPD WITH (NOLOCK)
            LEFT JOIN dbo.ItemMasterAircraftMapping IMAM WITH (NOLOCK)
                ON AIPD.ATAChapterId = IMAM.ItemMasterAircraftMappingId
            INNER JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK)
                ON ARH.AircraftRegistryId = AIPD.AircraftRegistryId
            INNER JOIN dbo.ItemMaster IM WITH (NOLOCK)
                ON AIPD.ItemMasterId = IM.ItemMasterId
            LEFT JOIN (
                SELECT WOP.AircraftInstalledPartDetailsId, WO.WorkOrderId, WO.WorkOrderNum,
                       ROW_NUMBER() OVER (PARTITION BY WOP.AircraftInstalledPartDetailsId ORDER BY WO.WorkOrderId DESC) AS rn
                FROM dbo.WorkOrderPartNumber WOP WITH (NOLOCK)
                JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
            ) LWO_I ON LWO_I.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId AND LWO_I.rn = 1
            WHERE AIPD.MasterCompanyId = @MasterCompanyId
        ),
        Filtered AS
        (
            SELECT * FROM Combined
            WHERE
                (
                    @GlobalFilter IS NULL OR @GlobalFilter = ''
                    OR acTailNum     LIKE '%' + @GlobalFilter + '%'
                    OR acMake        LIKE '%' + @GlobalFilter + '%'
                    OR serialNum     LIKE '%' + @GlobalFilter + '%'
                    OR mtceCategory  LIKE '%' + @GlobalFilter + '%'
                    OR mtceType      LIKE '%' + @GlobalFilter + '%'
                    OR section       LIKE '%' + @GlobalFilter + '%'
                    OR pnNum         LIKE '%' + @GlobalFilter + '%'
                    OR pnDescription LIKE '%' + @GlobalFilter + '%'
                    OR ataChpt       LIKE '%' + @GlobalFilter + '%'
                    OR woNum         LIKE '%' + @GlobalFilter + '%'
                )
                AND (ISNULL(@TailNumber,    '') = '' OR acTailNum    LIKE '%' + @TailNumber    + '%')
                AND (ISNULL(@AircraftMake,  '') = '' OR acMake       LIKE '%' + @AircraftMake  + '%')
                AND (ISNULL(@SerialNumber,  '') = '' OR serialNum    LIKE '%' + @SerialNumber  + '%')
                AND (ISNULL(@MtceCategory,  '') = '' OR mtceCategory LIKE '%' + @MtceCategory  + '%')
                AND (ISNULL(@MtceType,      '') = '' OR mtceType     LIKE '%' + @MtceType      + '%')
                AND (ISNULL(@Section,       '') = '' OR section      LIKE '%' + @Section       + '%')
                AND (ISNULL(@PNNum,         '') = '' OR pnNum        LIKE '%' + @PNNum         + '%')
                AND (ISNULL(@PNDescription, '') = '' OR pnDescription LIKE '%' + @PNDescription + '%')
                AND (ISNULL(@Qty,           '') = '' OR CAST(qty AS VARCHAR(50)) LIKE '%' + @Qty + '%')
                AND (ISNULL(@CustomerName,  '') = '' OR customerName LIKE '%' + @CustomerName  + '%')
                AND (ISNULL(@ATAChapter,    '') = '' OR ataChpt      LIKE '%' + @ATAChapter    + '%')
                AND (@LastMaintained IS NULL OR CAST(lastMtced AS DATE) = CAST(@LastMaintained AS DATE))
                AND (ISNULL(@WONumber,      '') = '' OR woNum        LIKE '%' + @WONumber      + '%')
                AND (@NextScheduled IS NULL OR CAST(nextSchdMtce AS DATE) = CAST(@NextScheduled AS DATE))
        ),
        Paged AS
        (
            SELECT *, COUNT(1) OVER () AS TotalRecords FROM Filtered
        )
        SELECT * FROM Paged
        ORDER BY
            CASE WHEN @SortColumn = 'ACTAILNUM'            AND @SortOrder = 'ASC'  THEN acTailNum END ASC,
            CASE WHEN @SortColumn = 'ACTAILNUM'            AND @SortOrder = 'DESC' THEN acTailNum END DESC,
            CASE WHEN @SortColumn = 'ACMAKE'               AND @SortOrder = 'ASC'  THEN acMake END ASC,
            CASE WHEN @SortColumn = 'ACMAKE'               AND @SortOrder = 'DESC' THEN acMake END DESC,
            CASE WHEN @SortColumn = 'SERIALNUM'            AND @SortOrder = 'ASC'  THEN serialNum END ASC,
            CASE WHEN @SortColumn = 'SERIALNUM'            AND @SortOrder = 'DESC' THEN serialNum END DESC,
            CASE WHEN @SortColumn = 'MTCECATEGORY'         AND @SortOrder = 'ASC'  THEN mtceCategory END ASC,
            CASE WHEN @SortColumn = 'MTCECATEGORY'         AND @SortOrder = 'DESC' THEN mtceCategory END DESC,
            CASE WHEN @SortColumn = 'MTCETYPE'             AND @SortOrder = 'ASC'  THEN mtceType END ASC,
            CASE WHEN @SortColumn = 'MTCETYPE'             AND @SortOrder = 'DESC' THEN mtceType END DESC,
            CASE WHEN @SortColumn = 'SECTION'              AND @SortOrder = 'ASC'  THEN section END ASC,
            CASE WHEN @SortColumn = 'SECTION'              AND @SortOrder = 'DESC' THEN section END DESC,
            CASE WHEN @SortColumn = 'PNNUM'                AND @SortOrder = 'ASC'  THEN pnNum END ASC,
            CASE WHEN @SortColumn = 'PNNUM'                AND @SortOrder = 'DESC' THEN pnNum END DESC,
            CASE WHEN @SortColumn = 'PNDESCRIPTION'        AND @SortOrder = 'ASC'  THEN pnDescription END ASC,
            CASE WHEN @SortColumn = 'PNDESCRIPTION'        AND @SortOrder = 'DESC' THEN pnDescription END DESC,
            CASE WHEN @SortColumn = 'QTY'                  AND @SortOrder = 'ASC'  THEN qty END ASC,
            CASE WHEN @SortColumn = 'QTY'                  AND @SortOrder = 'DESC' THEN qty END DESC,
            CASE WHEN @SortColumn = 'CUSTOMERNAME'         AND @SortOrder = 'ASC'  THEN customerName END ASC,
            CASE WHEN @SortColumn = 'CUSTOMERNAME'         AND @SortOrder = 'DESC' THEN customerName END DESC,
            CASE WHEN @SortColumn = 'ATACHPT'              AND @SortOrder = 'ASC'  THEN ataChpt END ASC,
            CASE WHEN @SortColumn = 'ATACHPT'              AND @SortOrder = 'DESC' THEN ataChpt END DESC,
            CASE WHEN @SortColumn = 'LASTMTCED'            AND @SortOrder = 'ASC'  THEN lastMtced END ASC,
            CASE WHEN @SortColumn = 'LASTMTCED'            AND @SortOrder = 'DESC' THEN lastMtced END DESC,
            CASE WHEN @SortColumn = 'WONUM'                AND @SortOrder = 'ASC'  THEN woNum END ASC,
            CASE WHEN @SortColumn = 'WONUM'                AND @SortOrder = 'DESC' THEN woNum END DESC,
            CASE WHEN @SortColumn = 'NEXTSCHDMTCE'         AND @SortOrder = 'ASC'  THEN nextSchdMtce END ASC,
            CASE WHEN @SortColumn = 'NEXTSCHDMTCE'         AND @SortOrder = 'DESC' THEN nextSchdMtce END DESC,
            CASE WHEN @SortColumn = 'INSTALLEDDATE'        AND @SortOrder = 'ASC'  THEN installedDate END ASC,
            CASE WHEN @SortColumn = 'INSTALLEDDATE'        AND @SortOrder = 'DESC' THEN installedDate END DESC,
            CASE WHEN @SortColumn = 'LIMITCYCLES'          AND @SortOrder = 'ASC'  THEN limitCycles END ASC,
            CASE WHEN @SortColumn = 'LIMITCYCLES'          AND @SortOrder = 'DESC' THEN limitCycles END DESC,
            CASE WHEN @SortColumn = 'LIMITTIME'            AND @SortOrder = 'ASC'  THEN limitTime END ASC,
            CASE WHEN @SortColumn = 'LIMITTIME'            AND @SortOrder = 'DESC' THEN limitTime END DESC,
            CASE WHEN @SortColumn = 'LIMITLANDINGS'        AND @SortOrder = 'ASC'  THEN limitLandings END ASC,
            CASE WHEN @SortColumn = 'LIMITLANDINGS'        AND @SortOrder = 'DESC' THEN limitLandings END DESC,
            CASE WHEN @SortColumn = 'LIMITENGINESTARTS'    AND @SortOrder = 'ASC'  THEN limitEngineStarts END ASC,
            CASE WHEN @SortColumn = 'LIMITENGINESTARTS'    AND @SortOrder = 'DESC' THEN limitEngineStarts END DESC,
            CASE WHEN @SortColumn = 'LIMITFLIGHTHOURS'     AND @SortOrder = 'ASC'  THEN LimitFlightHoursHours END ASC,
            CASE WHEN @SortColumn = 'LIMITFLIGHTHOURS'     AND @SortOrder = 'DESC' THEN LimitFlightHoursHours END DESC,
            CASE WHEN @SortColumn = 'RECORDCYCLES'         AND @SortOrder = 'ASC'  THEN recordCycles END ASC,
            CASE WHEN @SortColumn = 'RECORDCYCLES'         AND @SortOrder = 'DESC' THEN recordCycles END DESC,
            CASE WHEN @SortColumn = 'RECORDTIME'           AND @SortOrder = 'ASC'  THEN recordTime END ASC,
            CASE WHEN @SortColumn = 'RECORDTIME'           AND @SortOrder = 'DESC' THEN recordTime END DESC,
            CASE WHEN @SortColumn = 'RECORDLANDINGS'       AND @SortOrder = 'ASC'  THEN recordLandings END ASC,
            CASE WHEN @SortColumn = 'RECORDLANDINGS'       AND @SortOrder = 'DESC' THEN recordLandings END DESC,
            CASE WHEN @SortColumn = 'RECORDENGINESTARTS'   AND @SortOrder = 'ASC'  THEN recordEngineStarts END ASC,
            CASE WHEN @SortColumn = 'RECORDENGINESTARTS'   AND @SortOrder = 'DESC' THEN recordEngineStarts END DESC,
            CASE WHEN @SortColumn = 'RECORDFLIGHTHOURS'    AND @SortOrder = 'ASC'  THEN RecordFlightHoursHours END ASC,
            CASE WHEN @SortColumn = 'RECORDFLIGHTHOURS'    AND @SortOrder = 'DESC' THEN RecordFlightHoursHours END DESC,
            CASE WHEN @SortColumn = 'REMAININGCYCLES'      AND @SortOrder = 'ASC'  THEN remainingCycles END ASC,
            CASE WHEN @SortColumn = 'REMAININGCYCLES'      AND @SortOrder = 'DESC' THEN remainingCycles END DESC,
            CASE WHEN @SortColumn = 'REMAININGTIME'        AND @SortOrder = 'ASC'  THEN remainingTime END ASC,
            CASE WHEN @SortColumn = 'REMAININGTIME'        AND @SortOrder = 'DESC' THEN remainingTime END DESC,
            CASE WHEN @SortColumn = 'REMAININGLANDINGS'    AND @SortOrder = 'ASC'  THEN remainingLandings END ASC,
            CASE WHEN @SortColumn = 'REMAININGLANDINGS'    AND @SortOrder = 'DESC' THEN remainingLandings END DESC,
            CASE WHEN @SortColumn = 'REMAININGENGINESTARTS' AND @SortOrder = 'ASC'  THEN remainingEngineStarts END ASC,
            CASE WHEN @SortColumn = 'REMAININGENGINESTARTS' AND @SortOrder = 'DESC' THEN remainingEngineStarts END DESC,
            CASE WHEN @SortColumn = 'REMAININGFLIGHTHOURS' AND @SortOrder = 'ASC'  THEN RemainingFlightHoursHours END ASC,
            CASE WHEN @SortColumn = 'REMAININGFLIGHTHOURS' AND @SortOrder = 'DESC' THEN RemainingFlightHoursHours END DESC,
            acTailNum ASC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftComponentMaintenanceDashboardList',
            @ProcedureParameters VARCHAR(3000),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        SET @ProcedureParameters =
              '@PageNumber='        + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(20))
            + ', @PageSize='        + CAST(ISNULL(@PageSize, 0) AS VARCHAR(20))
            + ', @SortColumn='      + ISNULL(@SortColumn, '')
            + ', @SortOrder='       + ISNULL(@SortOrder, '')
            + ', @MasterCompanyId=' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20));

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
    END CATCH
END;