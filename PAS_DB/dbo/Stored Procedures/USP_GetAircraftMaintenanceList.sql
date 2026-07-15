/****************************************************************************************************
** File:        [USP_GetAircraftMaintenanceList]
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
** 1    10/04/2026   Priyansh Patel     Created [PN-16016]
** 2    28/04/2026   Priyansh Patel     Added Mtce Class [PN-16160]
** 3    07/05/2026   Priyansh Patel     Added TemplateIdNumber [PN-16344]
** 4    18-05-2026   Ayushi Patel       Return WorksheetNumber from worksheetheader table [PN-16454]
** 5    18/05/2026   Bhargav Saliya     Added IsScheduledMaintenance [PN-16475]
** 6    19/05/2026   Bhargav Saliya     Rever The IsScheduledMaintenance Changes and added MtcCategory and MtcCategoryId [PN-16475]
** 7    20/05/2026   Priyansh Patel     Fix the WorksheetNumber to return the latest [PN-16408]
** 8    22/05/2026   Priyansh Patel     Added WO num  [PN-16537]
** 9    22/05/2026   Moin Bloch         Added  [StockLineId],[IsCustomerStock] PN-16469
** 10   26/05/2026   Priyansh Patel     Added Worksheet Header Id [PN-16537]
** 11   02/06/2026   Abhishek Jirawla   Added IsScheduled [PN-16679]
** 12   25/06/2026	 Amit Ghediya	    Added @LastInspectedDate,@Description,@LastinspectedById [PN-17000]
** 13   22/05/2026   Moin Bloch         Added @FlightHoursLimitDays PN-17043
** 14   30/06/2026	 Amit Ghediya	    Update for Engine data [PN-17075]
** 15   07/07/2026	 Amit Ghediya	    Update for get is from Aircraft Or Engine maintanace for get stockline logic
** 16   10/07/2026	 -                  Performance & standards refactor:
**                                      - Pre-split EngineRegistryIds once into table variable (removed per-row STRING_SPLIT)
**                                      - Replaced ranked derived tables (WorksheetHeader / WorkOrder) with OUTER APPLY TOP 1
**                                      - Computed Aircraft vs Engine display columns once via CROSS APPLY; column filters
**                                        (TailNumber/Make/Model/SerialNumber) now match displayed values (bug fix)
**                                      - Removed duplicate @MaintenanceClassName predicate and commented-out code
**                                      - Date filters converted to sargable range predicates
**                                      - Wired up previously-unused @MaintanaceType filter (AIRFRAME/ENGINE)
**                                      - Explicit output column list (removed SELECT *)
**                                      - Expanded error-log parameter capture
** 17   14/07/2026	 Amit Ghediya	    Added @IsScheduled filter; added WoStatus (latest linked work
**                                      order's status, same source as the WO Status shown on the
**                                      Airworthiness Compliance Tracking / ADs and SBs list); added
**                                      ApplicableSbAd (comma-separated PubNum list of publications
**                                      flagged Applicability=1 whose AircraftEffectivity/
**                                      AircraftEffectivitySerialDetail criteria match this aircraft --
**                                      aircraft-linked records only, NULL for engine-linked rows)
** 18   14/07/2026	 Amit Ghediya	    Added @ApplicableSbAd,@WoStatus filter [PN-17161]
*****************************************************************************************************/
-- EXEC [dbo].[USP_GetAircraftMaintenanceList] @MasterCompanyId = 1, @AircraftRegistryId = 22;
CREATE   PROCEDURE [dbo].[USP_GetAircraftMaintenanceList]
    @PageNumber              INT             = 1,
    @PageSize                INT             = 10,
    @SortColumn              VARCHAR(100)    = 'ProgramId',
    @SortOrder               VARCHAR(4)      = 'DESC',
    @GlobalFilter            VARCHAR(100)    = NULL,
    @ProgramId               VARCHAR(50)     = NULL,
    @VersionNumber           VARCHAR(50)     = NULL,
    @TailNumber              VARCHAR(50)     = NULL,
    @AircraftMake            VARCHAR(100)    = NULL,
    @AircraftModel           VARCHAR(100)    = NULL,
    @SerialNumber            VARCHAR(100)    = NULL,
    @NextScheduled           DATETIME        = NULL,
    @MaintenanceType         VARCHAR(200)    = NULL,
    @TemplateId              BIGINT          = NULL,
    @TemplateIdNumber        VARCHAR(100)    = NULL,
    @TemplateVersionNumber   VARCHAR(50)     = NULL,
    @FlightHoursLimit        VARCHAR(20)     = NULL,
    @CyclesLimit             VARCHAR(50)     = NULL,
    @TimeLimit               VARCHAR(50)     = NULL,
    @LandingsLimit           VARCHAR(50)     = NULL,
    @EngineStartsLimit       VARCHAR(50)     = NULL,
    @FlightHoursRecorded     VARCHAR(20)     = NULL,
    @CyclesRecorded          VARCHAR(50)     = NULL,
    @TimeRecorded            VARCHAR(50)     = NULL,
    @LandingsRecorded        VARCHAR(50)     = NULL,
    @EngineStartsRecorded    VARCHAR(50)     = NULL,
    @FlightHoursRemaining    VARCHAR(20)     = NULL,
    @CyclesRemaining         VARCHAR(50)     = NULL,
    @TimeRemaining           VARCHAR(50)     = NULL,
    @LandingsRemaining       VARCHAR(50)     = NULL,
    @EngineStartsRemaining   VARCHAR(50)     = NULL,
    @MaintenanceClassName    VARCHAR(100)    = NULL,
    @IsActive                BIT             = NULL,
    @IsDeleted               BIT             = 0,
    @AircraftRegistryId      BIGINT,
    @MasterCompanyId         INT,
    @WorksheetNumber         VARCHAR(50)     = NULL,
    @MtcCategory             VARCHAR(256)    = NULL,
    @WoNumber                VARCHAR(256)    = NULL,
    @LastMtced               DATETIME        = NULL,
    @LastInspectedDate       DATETIME        = NULL,
    @Description             VARCHAR(256)    = NULL,
    @LastinspectedBy         VARCHAR(256)    = NULL,
    @IsFromAircraft          BIT             = NULL,
    @SequenceNo              BIGINT          = NULL,
    @MaintanaceType          VARCHAR(256)    = NULL,
    @IsScheduled             BIT             = NULL,
	@ApplicableSbAd          BIT             = NULL,
	@WoStatus                VARCHAR(50)     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ACTemplateType INT = 2;

        --------------------------------------------------------------------------------
        -- Normalize date filters to sargable half-open ranges [start, next day)
        --------------------------------------------------------------------------------
        DECLARE @NextScheduledFrom      DATE = CAST(@NextScheduled     AS DATE),
                @LastMtcedFrom          DATE = CAST(@LastMtced         AS DATE),
                @LastInspectedFrom      DATE = CAST(@LastInspectedDate AS DATE);

        DECLARE @NextScheduledTo        DATE = DATEADD(DAY, 1, @NextScheduledFrom),
                @LastMtcedTo            DATE = DATEADD(DAY, 1, @LastMtcedFrom),
                @LastInspectedTo        DATE = DATEADD(DAY, 1, @LastInspectedFrom);

        --------------------------------------------------------------------------------
        -- Pre-split the aircraft's linked engine registry ids ONCE
        -- (replaces per-row STRING_SPLIT inside an EXISTS)
        --------------------------------------------------------------------------------
        DECLARE @EngineIds TABLE (EngineRegistryId BIGINT PRIMARY KEY);

        IF (ISNULL(@AircraftRegistryId, 0) <> 0 AND ISNULL(@IsFromAircraft, 0) = 1)
        BEGIN
            INSERT INTO @EngineIds (EngineRegistryId)
            SELECT DISTINCT TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value)))
            FROM [dbo].[AircraftRegistryHeader] ARH2 WITH (NOLOCK)
            CROSS APPLY STRING_SPLIT(ARH2.EngineRegistryIds, ',') s
            WHERE ARH2.AircraftRegistryId = @AircraftRegistryId
              AND ARH2.MasterCompanyId    = @MasterCompanyId
              AND TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value))) IS NOT NULL;
        END;

        ;WITH CTE AS
        (
            SELECT
                AMP.ProgramId,
                AMP.AircraftRegistryId,
                AMP.EngineRegistryId,
                ARH.AircraftRegistryNumber,
                AMP.VersionNumber,
                AMP.MaintenanceType,
                AMP.MaintenanceTypeId,
                AMP.NextScheduledMaintenance,
                AMP.TemplateId,
                WF.WorkOrderNumber          AS TemplateIdNumber,
                AMP.TemplateVersionNumber,
                REG.TailNumber,
                REG.AircraftMake,
                REG.AircraftModel,
                REG.SerialNumber,
                REG.MaintanaceType,
                MC.[Name]                   AS MaintenanceClassName,
                AMP.FlightHoursLimitHours,
                AMP.FlightHoursLimitMinutes,
                AMP.FlightHoursLimitMonthsOrDays,
                AMP.FlightHoursRecordedHours,
                AMP.FlightHoursRecordedMinutes,
                AMP.FlightHoursRemainingHours,
                AMP.FlightHoursRemainingMinutes,
                -- Flight Hours (formatted HH:mm)
                FH.FlightHoursRecorded,
                FH.FlightHoursLimit,
                FH.FlightHoursRemaining,
                -- Limits
                AMP.CyclesLimit,
                AMP.TimeLimit,
                AMP.LandingsLimit,
                AMP.EngineStartsLimit,
                -- Recorded
                AMP.CyclesRecorded,
                AMP.TimeRecorded,
                AMP.LandingsRecorded,
                AMP.EngineStartsRecorded,
                -- Remaining
                CASE WHEN AMP.CyclesRemaining > 0 THEN AMP.CyclesRemaining ELSE NULL END AS CyclesRemaining,
                AMP.TimeRemaining,
                AMP.LandingsRemaining,
                AMP.EngineStartsRemaining,
                AMP.IsScheduled,
                AMP.IsActive,
                AMP.UpdatedDate,
                AMP.UpdatedBy,
                AMP.CreatedDate,
                AMP.CreatedBy,
                WSH.WorksheetNumber,
                MTC.MtcCategory,
                AMP.MtcCategoryId,
                LWO.WorkOrderNum,
                LWO.WorkOrderId,
                REG.StockLineId,
                CASE WHEN STK.[IsCustomerStock] = 1 THEN 'Yes' ELSE 'No' END AS [IsCustomerStock],
                ISNULL(STK.[QuantityAvailable], 0)  AS [QuantityAvailable],
                ISNULL(STK.[QuantityOnHand], 0)     AS [QuantityOnHand],
                WSH.WorksheetHeaderId,
                AMP.UpdatedDate             AS LastMtced,
                AMP.LastInspectedDate,
                AMP.[Description],
                EMP.EmployeeId              AS LastinspectedById,
                EMP.EmployeeName            AS LastinspectedBy,
                AMP.SequenceNo,
                AMP.IsFromAircraft,
                LWO.WorkOrderStatus         AS WoStatus,
				CASE WHEN ISNULL(AMP.AircraftPublicationId,0) > 0 THEN 1 ELSE 0 END AS ApplicableSbAd,
                COUNT(1) OVER ()            AS TotalRecords
            FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
            LEFT JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
                   ON AMP.AircraftRegistryId = ARH.AircraftRegistryId
                  AND ARH.MasterCompanyId    = @MasterCompanyId
            LEFT JOIN [dbo].[EngineRegistryHeader] ERH WITH (NOLOCK)
                   ON AMP.EngineRegistryId = ERH.EngineRegistryId
                  AND ERH.MasterCompanyId  = @MasterCompanyId
            -- Compute Aircraft-vs-Engine display values ONCE; reused by both SELECT and filters
            CROSS APPLY (
                SELECT
                    CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN ARH.TailNum        ELSE ERH.TailNum        END AS TailNumber,
                    CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN ARH.MakeType       ELSE ERH.MakeType       END AS AircraftMake,
                    CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN ARH.AircraftModel  ELSE ERH.EngineModel    END AS AircraftModel,
                    CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN ARH.SerialNum      ELSE ERH.SerialNum      END AS SerialNumber,
                    CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN ISNULL(ARH.StockLineId, 0) ELSE ISNULL(ERH.StockLineId, 0) END AS StockLineId,
                    CASE WHEN ISNULL(AMP.IsFromAircraft, 0) = 1 THEN 'AIRFRAME'         ELSE 'ENGINE'           END AS MaintanaceType
            ) REG
            -- Format flight-hours strings ONCE; reused by both SELECT and filters
            CROSS APPLY (
                SELECT
                    CAST(AMP.FlightHoursRecordedHours  AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRecordedMinutes,  0) AS VARCHAR(2)), 2) AS FlightHoursRecorded,
                    CAST(AMP.FlightHoursLimitHours     AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursLimitMinutes,     0) AS VARCHAR(2)), 2) AS FlightHoursLimit,
                    CAST(AMP.FlightHoursRemainingHours AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRemainingMinutes, 0) AS VARCHAR(2)), 2) AS FlightHoursRemaining
            ) FH
            LEFT JOIN [dbo].[MaintenanceClass] MC WITH (NOLOCK)
                   ON AMP.MaintenanceClassId = MC.MaintenanceClassId
            LEFT JOIN [dbo].[Workflow] WF WITH (NOLOCK)
                   ON AMP.TemplateId  = WF.WorkflowId
                  AND WF.TemplateType = @ACTemplateType
            LEFT JOIN [dbo].[MaintenanceCategory] MTC WITH (NOLOCK)
                   ON AMP.[MtcCategoryId] = MTC.[MtcCategoryId]
            LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK)
                   ON STK.[StockLineId] = REG.StockLineId
            LEFT JOIN [dbo].[View_Employee_Cert] EMP WITH (NOLOCK)
                   ON EMP.EmployeeId = AMP.LastinspectedById
            -- Latest worksheet per program (replaces ranking the whole WorksheetHeader table)
            OUTER APPLY (
                SELECT TOP (1) W.WorksheetNumber, W.WorksheetHeaderId
                FROM [dbo].[WorksheetHeader] W WITH (NOLOCK)
                WHERE W.ProgramId = AMP.ProgramId
                ORDER BY W.CreatedDate DESC
            ) WSH
            -- Latest work order per program (replaces ranking the whole WorkOrder join)
            OUTER APPLY (
                SELECT TOP (1) WO.[WorkOrderId], WO.[WorkOrderNum], WOP.[WorkOrderStatus]
                FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
                JOIN [dbo].[WorkOrder] WO WITH (NOLOCK)
                  ON WOP.[WorkOrderId] = WO.[WorkOrderId]
                WHERE WOP.[ProgramId] = AMP.[ProgramId]
                ORDER BY WO.[WorkOrderId] DESC
            ) LWO
            WHERE
                AMP.MasterCompanyId = @MasterCompanyId
                AND (@IsDeleted IS NULL OR AMP.IsDeleted = @IsDeleted)
                AND (
                        @AircraftRegistryId IS NULL OR @AircraftRegistryId = 0
                        OR ( ISNULL(@IsFromAircraft, 0) = 1
                             AND (
                                    ( AMP.AircraftRegistryId = @AircraftRegistryId
                                      AND ISNULL(AMP.IsFromAircraft, 0) = 1 )
                                    OR ( ISNULL(AMP.IsFromAircraft, 0) = 0
                                         AND AMP.EngineRegistryId IS NOT NULL
                                         AND AMP.EngineRegistryId IN (SELECT EngineRegistryId FROM @EngineIds) )
                                 )
                           )
                        OR ( ISNULL(@IsFromAircraft, 0) = 0
                             AND ISNULL(AMP.IsFromAircraft, 0) = 0
                             AND AMP.EngineRegistryId = @AircraftRegistryId )
                    )
                AND ( @GlobalFilter IS NULL
                      OR REG.TailNumber                        LIKE '%' + @GlobalFilter + '%'
                      OR CAST(AMP.ProgramId AS VARCHAR(50))    LIKE '%' + @GlobalFilter + '%'
                      OR AMP.MaintenanceType                   LIKE '%' + @GlobalFilter + '%'
                )
                -- Column Filters (filter on the same computed values that are displayed)
                AND (@ProgramId       IS NULL OR CAST(AMP.ProgramId AS VARCHAR(50)) LIKE '%' + @ProgramId + '%')
                AND (@VersionNumber   IS NULL OR AMP.VersionNumber        LIKE '%' + @VersionNumber        + '%')
                AND (@TailNumber      IS NULL OR REG.TailNumber           LIKE '%' + @TailNumber           + '%')
                AND (@AircraftMake    IS NULL OR REG.AircraftMake         LIKE '%' + @AircraftMake         + '%')
                AND (@AircraftModel   IS NULL OR REG.AircraftModel        LIKE '%' + @AircraftModel        + '%')
                AND (@SerialNumber    IS NULL OR REG.SerialNumber         LIKE '%' + @SerialNumber         + '%')
                AND (@MaintanaceType  IS NULL OR REG.MaintanaceType       LIKE '%' + @MaintanaceType       + '%')
                AND (@MaintenanceType IS NULL OR AMP.MaintenanceType      LIKE '%' + @MaintenanceType      + '%')
                AND (@TemplateId      IS NULL OR AMP.TemplateId = @TemplateId)
                AND (@TemplateVersionNumber IS NULL OR AMP.TemplateVersionNumber LIKE '%' + @TemplateVersionNumber + '%')
                AND (@TemplateIdNumber IS NULL OR WF.WorkOrderNumber      LIKE '%' + @TemplateIdNumber     + '%')
                AND (@IsActive        IS NULL OR AMP.IsActive = @IsActive)
                -- Sargable date-range predicates
                AND (@NextScheduledFrom IS NULL OR (AMP.NextScheduledMaintenance >= @NextScheduledFrom AND AMP.NextScheduledMaintenance < @NextScheduledTo))
                AND (@LastMtcedFrom     IS NULL OR (AMP.UpdatedDate              >= @LastMtcedFrom     AND AMP.UpdatedDate              < @LastMtcedTo))
                AND (@LastInspectedFrom IS NULL OR (AMP.LastInspectedDate        >= @LastInspectedFrom AND AMP.LastInspectedDate        < @LastInspectedTo))
                AND (@LastinspectedBy   IS NULL OR EMP.EmployeeName       LIKE '%' + @LastinspectedBy      + '%')
                AND (@MaintenanceClassName IS NULL OR MC.[Name]           LIKE '%' + @MaintenanceClassName + '%')
                -- Flight Hours (string compare since formatted HH:mm)
                AND (@FlightHoursLimit     IS NULL OR FH.FlightHoursLimit     LIKE '%' + @FlightHoursLimit     + '%')
                AND (@FlightHoursRecorded  IS NULL OR FH.FlightHoursRecorded  LIKE '%' + @FlightHoursRecorded  + '%')
                AND (@FlightHoursRemaining IS NULL OR FH.FlightHoursRemaining LIKE '%' + @FlightHoursRemaining + '%')
                AND (@CyclesLimit          IS NULL OR CAST(AMP.CyclesLimit          AS VARCHAR(50)) LIKE '%' + @CyclesLimit          + '%')
                AND (@TimeLimit            IS NULL OR CAST(AMP.TimeLimit            AS VARCHAR(50)) LIKE '%' + @TimeLimit            + '%')
                AND (@LandingsLimit        IS NULL OR CAST(AMP.LandingsLimit        AS VARCHAR(50)) LIKE '%' + @LandingsLimit        + '%')
                AND (@EngineStartsLimit    IS NULL OR CAST(AMP.EngineStartsLimit    AS VARCHAR(50)) LIKE '%' + @EngineStartsLimit    + '%')
                AND (@CyclesRecorded       IS NULL OR CAST(AMP.CyclesRecorded       AS VARCHAR(50)) LIKE '%' + @CyclesRecorded       + '%')
                AND (@TimeRecorded         IS NULL OR CAST(AMP.TimeRecorded         AS VARCHAR(50)) LIKE '%' + @TimeRecorded         + '%')
                AND (@LandingsRecorded     IS NULL OR CAST(AMP.LandingsRecorded     AS VARCHAR(50)) LIKE '%' + @LandingsRecorded     + '%')
                AND (@EngineStartsRecorded IS NULL OR CAST(AMP.EngineStartsRecorded AS VARCHAR(50)) LIKE '%' + @EngineStartsRecorded + '%')
                AND (@CyclesRemaining      IS NULL OR CAST(AMP.CyclesRemaining      AS VARCHAR(50)) LIKE '%' + @CyclesRemaining      + '%')
                AND (@TimeRemaining        IS NULL OR CAST(AMP.TimeRemaining        AS VARCHAR(50)) LIKE '%' + @TimeRemaining        + '%')
                AND (@LandingsRemaining    IS NULL OR CAST(AMP.LandingsRemaining    AS VARCHAR(50)) LIKE '%' + @LandingsRemaining    + '%')
                AND (@EngineStartsRemaining IS NULL OR CAST(AMP.EngineStartsRemaining AS VARCHAR(50)) LIKE '%' + @EngineStartsRemaining + '%')
                AND (ISNULL(@WorksheetNumber, '') = '' OR WSH.WorksheetNumber LIKE '%' + @WorksheetNumber + '%')
                AND (ISNULL(@MtcCategory, '')     = '' OR MTC.MtcCategory     LIKE '%' + @MtcCategory     + '%')
                AND (ISNULL(@WoNumber, '')        = '' OR LWO.WorkOrderNum    LIKE '%' + @WoNumber        + '%')
                AND (ISNULL(@Description, '')     = '' OR AMP.[Description]   LIKE '%' + @Description     + '%')
                AND (@SequenceNo IS NULL OR CAST(AMP.SequenceNo AS VARCHAR(50)) LIKE '%' + CAST(@SequenceNo AS VARCHAR(50)) + '%')
                AND (@IsScheduled IS NULL OR AMP.IsScheduled = @IsScheduled)
				AND (@ApplicableSbAd IS NULL OR CASE WHEN ISNULL(AMP.AircraftPublicationId,0) > 0 THEN 1 ELSE 0 END = @ApplicableSbAd)
				AND (ISNULL(@WoStatus, '') = '' OR LWO.WorkOrderStatus LIKE '%' + @WoStatus + '%')
        )

        SELECT
            ProgramId, AircraftRegistryId, EngineRegistryId, AircraftRegistryNumber,
            VersionNumber, MaintenanceType, MaintenanceTypeId, NextScheduledMaintenance,
            TemplateId, TemplateIdNumber, TemplateVersionNumber,
            TailNumber, AircraftMake, AircraftModel, SerialNumber, MaintanaceType,
            MaintenanceClassName,
            FlightHoursLimitHours, FlightHoursLimitMinutes, FlightHoursLimitMonthsOrDays,
            FlightHoursRecordedHours, FlightHoursRecordedMinutes,
            FlightHoursRemainingHours, FlightHoursRemainingMinutes,
            FlightHoursRecorded, FlightHoursLimit, FlightHoursRemaining,
            CyclesLimit, TimeLimit, LandingsLimit, EngineStartsLimit,
            CyclesRecorded, TimeRecorded, LandingsRecorded, EngineStartsRecorded,
            CyclesRemaining, TimeRemaining, LandingsRemaining, EngineStartsRemaining,
            IsScheduled, IsActive,
            UpdatedDate, UpdatedBy, CreatedDate, CreatedBy,
            WorksheetNumber, MtcCategory, MtcCategoryId,
            WorkOrderNum, WorkOrderId,
            StockLineId, IsCustomerStock, QuantityAvailable, QuantityOnHand,
            WorksheetHeaderId,
            LastMtced, LastInspectedDate, [Description],
            LastinspectedById, LastinspectedBy,
            SequenceNo, IsFromAircraft,
            WoStatus, ApplicableSbAd,
            TotalRecords
        FROM CTE
        ORDER BY
            CASE WHEN @SortColumn = 'ProgramId'                AND @SortOrder = 'ASC'  THEN ProgramId END ASC,
            CASE WHEN @SortColumn = 'ProgramId'                AND @SortOrder = 'DESC' THEN ProgramId END DESC,
            CASE WHEN @SortColumn = 'VersionNumber'            AND @SortOrder = 'ASC'  THEN VersionNumber END ASC,
            CASE WHEN @SortColumn = 'VersionNumber'            AND @SortOrder = 'DESC' THEN VersionNumber END DESC,
            CASE WHEN @SortColumn = 'TailNumber'               AND @SortOrder = 'ASC'  THEN TailNumber END ASC,
            CASE WHEN @SortColumn = 'TailNumber'               AND @SortOrder = 'DESC' THEN TailNumber END DESC,
            CASE WHEN @SortColumn = 'AircraftMake'             AND @SortOrder = 'ASC'  THEN AircraftMake END ASC,
            CASE WHEN @SortColumn = 'AircraftMake'             AND @SortOrder = 'DESC' THEN AircraftMake END DESC,
            CASE WHEN @SortColumn = 'AircraftModel'            AND @SortOrder = 'ASC'  THEN AircraftModel END ASC,
            CASE WHEN @SortColumn = 'AircraftModel'            AND @SortOrder = 'DESC' THEN AircraftModel END DESC,
            CASE WHEN @SortColumn = 'SerialNumber'             AND @SortOrder = 'ASC'  THEN SerialNumber END ASC,
            CASE WHEN @SortColumn = 'SerialNumber'             AND @SortOrder = 'DESC' THEN SerialNumber END DESC,
            CASE WHEN @SortColumn = 'MaintanaceType'           AND @SortOrder = 'ASC'  THEN MaintanaceType END ASC,
            CASE WHEN @SortColumn = 'MaintanaceType'           AND @SortOrder = 'DESC' THEN MaintanaceType END DESC,
            CASE WHEN @SortColumn = 'MaintenanceType'          AND @SortOrder = 'ASC'  THEN MaintenanceType END ASC,
            CASE WHEN @SortColumn = 'MaintenanceType'          AND @SortOrder = 'DESC' THEN MaintenanceType END DESC,
            CASE WHEN @SortColumn = 'TemplateId'               AND @SortOrder = 'ASC'  THEN TemplateIdNumber END ASC,
            CASE WHEN @SortColumn = 'TemplateId'               AND @SortOrder = 'DESC' THEN TemplateIdNumber END DESC,
            CASE WHEN @SortColumn = 'TemplateVersionNumber'    AND @SortOrder = 'ASC'  THEN TemplateVersionNumber END ASC,
            CASE WHEN @SortColumn = 'TemplateVersionNumber'    AND @SortOrder = 'DESC' THEN TemplateVersionNumber END DESC,
            CASE WHEN @SortColumn = 'NextScheduledMaintenance' AND @SortOrder = 'ASC'  THEN NextScheduledMaintenance END ASC,
            CASE WHEN @SortColumn = 'NextScheduledMaintenance' AND @SortOrder = 'DESC' THEN NextScheduledMaintenance END DESC,
            CASE WHEN @SortColumn = 'UpdatedDate'              AND @SortOrder = 'ASC'  THEN UpdatedDate END ASC,
            CASE WHEN @SortColumn = 'UpdatedDate'              AND @SortOrder = 'DESC' THEN UpdatedDate END DESC,
            CASE WHEN @SortColumn = 'MaintenanceClassName'     AND @SortOrder = 'ASC'  THEN MaintenanceClassName END ASC,
            CASE WHEN @SortColumn = 'MaintenanceClassName'     AND @SortOrder = 'DESC' THEN MaintenanceClassName END DESC,
            CASE WHEN @SortColumn = 'FlightHoursLimit'         AND @SortOrder = 'ASC'  THEN FlightHoursLimitHours END ASC,
            CASE WHEN @SortColumn = 'FlightHoursLimit'         AND @SortOrder = 'DESC' THEN FlightHoursLimitHours END DESC,
            CASE WHEN @SortColumn = 'FlightHoursRecorded'      AND @SortOrder = 'ASC'  THEN FlightHoursRecordedHours END ASC,
            CASE WHEN @SortColumn = 'FlightHoursRecorded'      AND @SortOrder = 'DESC' THEN FlightHoursRecordedHours END DESC,
            CASE WHEN @SortColumn = 'FlightHoursRemaining'     AND @SortOrder = 'ASC'  THEN FlightHoursRemainingHours END ASC,
            CASE WHEN @SortColumn = 'FlightHoursRemaining'     AND @SortOrder = 'DESC' THEN FlightHoursRemainingHours END DESC,
            CASE WHEN @SortColumn = 'CyclesLimit'              AND @SortOrder = 'ASC'  THEN CyclesLimit END ASC,
            CASE WHEN @SortColumn = 'CyclesLimit'              AND @SortOrder = 'DESC' THEN CyclesLimit END DESC,
            CASE WHEN @SortColumn = 'TimeLimit'                AND @SortOrder = 'ASC'  THEN TimeLimit END ASC,
            CASE WHEN @SortColumn = 'TimeLimit'                AND @SortOrder = 'DESC' THEN TimeLimit END DESC,
            CASE WHEN @SortColumn = 'LandingsLimit'            AND @SortOrder = 'ASC'  THEN LandingsLimit END ASC,
            CASE WHEN @SortColumn = 'LandingsLimit'            AND @SortOrder = 'DESC' THEN LandingsLimit END DESC,
            CASE WHEN @SortColumn = 'EngineStartsLimit'        AND @SortOrder = 'ASC'  THEN EngineStartsLimit END ASC,
            CASE WHEN @SortColumn = 'EngineStartsLimit'        AND @SortOrder = 'DESC' THEN EngineStartsLimit END DESC,
            CASE WHEN @SortColumn = 'CyclesRecorded'           AND @SortOrder = 'ASC'  THEN CyclesRecorded END ASC,
            CASE WHEN @SortColumn = 'CyclesRecorded'           AND @SortOrder = 'DESC' THEN CyclesRecorded END DESC,
            CASE WHEN @SortColumn = 'TimeRecorded'             AND @SortOrder = 'ASC'  THEN TimeRecorded END ASC,
            CASE WHEN @SortColumn = 'TimeRecorded'             AND @SortOrder = 'DESC' THEN TimeRecorded END DESC,
            CASE WHEN @SortColumn = 'LandingsRecorded'         AND @SortOrder = 'ASC'  THEN LandingsRecorded END ASC,
            CASE WHEN @SortColumn = 'LandingsRecorded'         AND @SortOrder = 'DESC' THEN LandingsRecorded END DESC,
            CASE WHEN @SortColumn = 'EngineStartsRecorded'     AND @SortOrder = 'ASC'  THEN EngineStartsRecorded END ASC,
            CASE WHEN @SortColumn = 'EngineStartsRecorded'     AND @SortOrder = 'DESC' THEN EngineStartsRecorded END DESC,
            CASE WHEN @SortColumn = 'CyclesRemaining'          AND @SortOrder = 'ASC'  THEN CyclesRemaining END ASC,
            CASE WHEN @SortColumn = 'CyclesRemaining'          AND @SortOrder = 'DESC' THEN CyclesRemaining END DESC,
            CASE WHEN @SortColumn = 'TimeRemaining'            AND @SortOrder = 'ASC'  THEN TimeRemaining END ASC,
            CASE WHEN @SortColumn = 'TimeRemaining'            AND @SortOrder = 'DESC' THEN TimeRemaining END DESC,
            CASE WHEN @SortColumn = 'LandingsRemaining'        AND @SortOrder = 'ASC'  THEN LandingsRemaining END ASC,
            CASE WHEN @SortColumn = 'LandingsRemaining'        AND @SortOrder = 'DESC' THEN LandingsRemaining END DESC,
            CASE WHEN @SortColumn = 'EngineStartsRemaining'    AND @SortOrder = 'ASC'  THEN EngineStartsRemaining END ASC,
            CASE WHEN @SortColumn = 'EngineStartsRemaining'    AND @SortOrder = 'DESC' THEN EngineStartsRemaining END DESC,
            CASE WHEN @SortColumn = 'CreatedDate'              AND @SortOrder = 'ASC'  THEN CreatedDate END ASC,
            CASE WHEN @SortColumn = 'CreatedDate'              AND @SortOrder = 'DESC' THEN CreatedDate END DESC,
            CASE WHEN @SortColumn = 'WorksheetNumber'          AND @SortOrder = 'ASC'  THEN WorksheetNumber END ASC,
            CASE WHEN @SortColumn = 'WorksheetNumber'          AND @SortOrder = 'DESC' THEN WorksheetNumber END DESC,
            CASE WHEN @SortColumn = 'MtcCategory'              AND @SortOrder = 'ASC'  THEN MtcCategory END ASC,
            CASE WHEN @SortColumn = 'MtcCategory'              AND @SortOrder = 'DESC' THEN MtcCategory END DESC,
            CASE WHEN @SortColumn = 'woNumber'                 AND @SortOrder = 'ASC'  THEN WorkOrderNum END ASC,
            CASE WHEN @SortColumn = 'woNumber'                 AND @SortOrder = 'DESC' THEN WorkOrderNum END DESC,
            CASE WHEN @SortColumn = 'LastMtced'                AND @SortOrder = 'ASC'  THEN LastMtced END ASC,
            CASE WHEN @SortColumn = 'LastMtced'                AND @SortOrder = 'DESC' THEN LastMtced END DESC,
            CASE WHEN @SortColumn = 'LastInspectedDate'        AND @SortOrder = 'ASC'  THEN LastInspectedDate END ASC,
            CASE WHEN @SortColumn = 'LastInspectedDate'        AND @SortOrder = 'DESC' THEN LastInspectedDate END DESC,
            CASE WHEN @SortColumn = 'LastinspectedBy'          AND @SortOrder = 'ASC'  THEN LastinspectedBy END ASC,
            CASE WHEN @SortColumn = 'LastinspectedBy'          AND @SortOrder = 'DESC' THEN LastinspectedBy END DESC,
            CASE WHEN @SortColumn = 'Description'              AND @SortOrder = 'ASC'  THEN [Description] END ASC,
            CASE WHEN @SortColumn = 'Description'              AND @SortOrder = 'DESC' THEN [Description] END DESC,
            CASE WHEN @SortColumn = 'SequenceNo'               AND @SortOrder = 'ASC'  THEN SequenceNo END ASC,
            CASE WHEN @SortColumn = 'SequenceNo'               AND @SortOrder = 'DESC' THEN SequenceNo END DESC,

			CASE WHEN @SortColumn = 'IsScheduled'               AND @SortOrder = 'ASC'  THEN IsScheduled END ASC,
            CASE WHEN @SortColumn = 'IsScheduled'               AND @SortOrder = 'DESC' THEN IsScheduled END DESC,
			CASE WHEN @SortColumn = 'WoStatus'               AND @SortOrder = 'ASC'  THEN WoStatus END ASC,
            CASE WHEN @SortColumn = 'WoStatus'               AND @SortOrder = 'DESC' THEN WoStatus END DESC,
			CASE WHEN @SortColumn = 'ApplicableSbAd'               AND @SortOrder = 'ASC'  THEN ApplicableSbAd END ASC,
            CASE WHEN @SortColumn = 'ApplicableSbAd'               AND @SortOrder = 'DESC' THEN ApplicableSbAd END DESC,
            ProgramId DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY

    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftMaintenanceList',
            @ProcedureParameters VARCHAR(3000) =
                  '@MasterCompanyId = '      + ISNULL(CAST(@MasterCompanyId    AS VARCHAR(20)), 'NULL')
                + ', @AircraftRegistryId = ' + ISNULL(CAST(@AircraftRegistryId AS VARCHAR(20)), 'NULL')
                + ', @IsFromAircraft = '     + ISNULL(CAST(@IsFromAircraft     AS VARCHAR(5)),  'NULL')
                + ', @IsDeleted = '          + ISNULL(CAST(@IsDeleted          AS VARCHAR(5)),  'NULL')
                + ', @PageNumber = '         + ISNULL(CAST(@PageNumber         AS VARCHAR(10)), 'NULL')
                + ', @PageSize = '           + ISNULL(CAST(@PageSize           AS VARCHAR(10)), 'NULL')
                + ', @SortColumn = '         + ISNULL(@SortColumn,   'NULL')
                + ', @SortOrder = '          + ISNULL(@SortOrder,    'NULL')
                + ', @GlobalFilter = '       + ISNULL(@GlobalFilter, 'NULL'),
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