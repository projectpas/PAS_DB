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
** 10   26/05/2026   Priyansh Patel     Added Worsheet Header Id [PN-16537]
11   09/July/2026	 RAJESH GAMI	    [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
*****************************************************************************************************/
-- EXEC [dbo].[USP_GetAircraftMaintenanceList] @MasterCompanyId = 1 @AircraftRegistryId = 22;
CREATE  PROCEDURE [dbo].[USP_GetAircraftMaintenanceList]
    @PageNumber              INT             = 1,
    @PageSize                INT             = 10,
    @SortColumn              VARCHAR(100)    = 'ProgramId',
    @SortOrder               VARCHAR(4)      = 'DESC',
    @GlobalFilter            VARCHAR(100)    = NULL,
    @ProgramId               VARCHAR(50)      = NULL,
    @VersionNumber           VARCHAR(50)     = NULL,
    @TailNumber              VARCHAR(50)     = NULL,
    @AircraftMake            VARCHAR(100)    = NULL,
    @AircraftModel           VARCHAR(100)    = NULL,
    @SerialNumber            VARCHAR(100)    = NULL,
    @NextScheduled           DATETIME        = NULL,
    @MaintenanceType         VARCHAR(200)    = NULL,
    @TemplateId              BIGINT          = NULL,
    @TemplateIdNumber        VARCHAR(100)     = NULL,
    @TemplateVersionNumber   VARCHAR(50)    = NULL,
    @FlightHoursLimit        VARCHAR(20) = NULL,
    @CyclesLimit             VARCHAR(50) = NULL,
    @TimeLimit               VARCHAR(50) = NULL,
    @LandingsLimit           VARCHAR(50) = NULL,
    @EngineStartsLimit       VARCHAR(50) = NULL,
    @FlightHoursRecorded     VARCHAR(20) = NULL,
    @CyclesRecorded          VARCHAR(50) = NULL,
    @TimeRecorded            VARCHAR(50) = NULL,
    @LandingsRecorded        VARCHAR(50) = NULL,
    @EngineStartsRecorded    VARCHAR(50) = NULL,
    @FlightHoursRemaining    VARCHAR(20) = NULL,
    @CyclesRemaining         VARCHAR(50) = NULL,
    @TimeRemaining           VARCHAR(50) = NULL,
    @LandingsRemaining       VARCHAR(50) = NULL,
    @EngineStartsRemaining   VARCHAR(50) = NULL,
    @MaintenanceClassName    VARCHAR(100) = NULL,
    @IsActive                BIT             = NULL,
    @IsDeleted               BIT             = 0,
    @AircraftRegistryId      BIGINT,
    @MasterCompanyId         INT,
    @WorksheetNumber         VARCHAR(50) = NULL,
    @MtcCategory    VARCHAR(256) = NULL,
    @WoNumber    VARCHAR(256) = NULL


AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ACTemplateType INT  = 2;

        WITH CTE AS
        (
            SELECT
                AMP.ProgramId,AMP.AircraftRegistryId,ARH.AircraftRegistryNumber,AMP.VersionNumber,AMP.MaintenanceType, AMP.MaintenanceTypeId,AMP.NextScheduledMaintenance,
				AMP.TemplateId AS TemplateId,
               WF.WorkOrderNumber AS TemplateIdNumber,AMP.TemplateVersionNumber,
                ARH.TailNum AS TailNumber,
                ARH.MakeType AS AircraftMake,
                ARH.AircraftModel,
                ARH.SerialNum AS SerialNumber,
                MC.[Name] AS MaintenanceClassName,
                AMP.FlightHoursLimitHours,
                AMP.FlightHoursLimitMinutes,
                AMP.FlightHoursRecordedHours,
                AMP.FlightHoursRecordedMinutes,
                AMP.FlightHoursRemainingHours,
                AMP.FlightHoursRemainingMinutes,
                -- Flight Hours
                CAST(AMP.FlightHoursRecordedHours AS VARCHAR) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRecordedMinutes,0) AS VARCHAR),2) AS FlightHoursRecorded,
                CAST(AMP.FlightHoursLimitHours AS VARCHAR) + ':' +  RIGHT('00' + CAST(ISNULL(AMP.FlightHoursLimitMinutes,0) AS VARCHAR),2) AS FlightHoursLimit,
                CAST(AMP.FlightHoursRemainingHours AS VARCHAR) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRemainingMinutes,0) AS VARCHAR),2) AS FlightHoursRemaining,
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
                AMP.IsActive,
                AMP.UpdatedDate,
                AMP.UpdatedBy,
                AMP.CreatedDate,
                AMP.CreatedBy,
                WSH.WorksheetNumber,
                mtc.MtcCategory,
                AMP.MtcCategoryId,
                LWO.WorkOrderNum,
                LWO.WorkOrderId ,
                ARH.StockLineId,				
                CASE WHEN STK.[IsCustomerStock] = 1 THEN 'Yes' ELSE 'No' END AS [IsCustomerStock], 
                ISNULL(STK.[QuantityAvailable],0) [QuantityAvailable],
                ISNULL(STK.[QuantityOnHand],0) [QuantityOnHand],
                WSH.WorksheetHeaderId,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK)
            LEFT JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK) ON AMP.AircraftRegistryId = ARH.AircraftRegistryId  AND ARH.MasterCompanyId = @MasterCompanyId 
            LEFT JOIN [dbo].[MaintenanceClass] MC WITH (NOLOCK)  ON AMP.MaintenanceClassId = MC.MaintenanceClassId
            LEFT JOIN [dbo].[Workflow] WF WITH (NOLOCK)  ON AMP.TemplateId = WF.WorkflowId AND WF.TemplateType = @ACTemplateType
            LEFT JOIN [dbo].[MaintenanceCategory] mtc WITH (NOLOCK) ON AMP.[MtcCategoryId] = mtc.[MtcCategoryId]
            LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = ISNULL(ARH.[StockLineId], ERH.[StockLineId]) AND ISNULL(STK.IsNonStock,0) = 0      
			LEFT JOIN [dbo].[View_Employee_Cert] EMP WITH (NOLOCK) ON EMP.EmployeeId = AMP.LastinspectedById          
            LEFT JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY ProgramId ORDER BY CreatedDate DESC) AS RN FROM [dbo].[WorksheetHeader] WITH (NOLOCK)) WSH ON AMP.ProgramId = WSH.ProgramId AND WSH.RN = 1
            LEFT JOIN (
                    SELECT WOP.[ProgramId], WO.[WorkOrderId], WO.[WorkOrderNum],
                           ROW_NUMBER() OVER (PARTITION BY WOP.[ProgramId] ORDER BY WO.[WorkOrderId] DESC) AS rn
                    FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
                    JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.[WorkOrderId] = WO.[WorkOrderId]
                ) LWO ON LWO.[ProgramId] = AMP.[ProgramId] AND LWO.rn = 1
            WHERE (@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0 OR AMP.AircraftRegistryId = @AircraftRegistryId) --AMP.AircraftRegistryId = @AircraftRegistryId  
			AND AMP.MasterCompanyId = @MasterCompanyId  AND (@IsDeleted IS NULL OR AMP.IsDeleted = @IsDeleted)
                -- Global Filter
                AND ( @GlobalFilter IS NULL OR AMP.TailNumber       LIKE '%' + @GlobalFilter + '%' OR CAST(AMP.ProgramId AS VARCHAR(50))   LIKE '%' + @GlobalFilter + '%' OR
                    AMP.MaintenanceType  LIKE '%' + @GlobalFilter + '%'
                )
                -- Column Filters
                AND (@ProgramId IS NULL  OR CAST(AMP.ProgramId AS VARCHAR(50)) LIKE '%' + @ProgramId + '%')
                AND (@VersionNumber   IS NULL OR AMP.VersionNumber     LIKE '%' + @VersionNumber     + '%')
                AND (@TailNumber      IS NULL OR AMP.TailNumber     LIKE '%' + @TailNumber     + '%')
                AND (@AircraftMake    IS NULL OR ARH.MakeType   LIKE '%' + @AircraftMake   + '%')
                AND (@AircraftModel   IS NULL OR ARH.AircraftModel  LIKE '%' + @AircraftModel  + '%')
                AND (@SerialNumber    IS NULL OR ARH.SerialNum   LIKE '%' + @SerialNumber   + '%')
                AND (@MaintenanceType IS NULL OR AMP.MaintenanceType LIKE '%' + @MaintenanceType + '%')
                AND (@TemplateId      IS NULL OR AMP.TemplateId = @TemplateId)
                AND (@TemplateVersionNumber IS NULL OR AMP.TemplateVersionNumber LIKE '%' + @TemplateVersionNumber + '%')
                AND (@TemplateIdNumber IS NULL OR WF.WorkOrderNumber LIKE '%' + @TemplateIdNumber + '%')
                AND (@IsActive        IS NULL OR AMP.IsActive = @IsActive)
                AND (@NextScheduled   IS NULL OR CAST(AMP.NextScheduledMaintenance AS DATE) = CAST(@NextScheduled AS DATE))
                AND (@MaintenanceClassName IS NULL  OR MC.[Name] LIKE '%' + @MaintenanceClassName + '%')
                -- Flight Hours (string compare since formatted HH:mm)
                AND (@FlightHoursLimit IS NULL OR  (CAST(AMP.FlightHoursLimitHours AS VARCHAR) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursLimitMinutes,0) AS VARCHAR),2)) LIKE '%' + @FlightHoursLimit + '%')
                AND (@FlightHoursRecorded IS NULL OR   (CAST(AMP.FlightHoursRecordedHours AS VARCHAR) + ':' +  RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRecordedMinutes,0) AS VARCHAR),2)) LIKE '%' + @FlightHoursRecorded + '%')
                AND (@FlightHoursRemaining IS NULL OR  (CAST(AMP.FlightHoursRemainingHours AS VARCHAR) + ':' + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursRemainingMinutes,0) AS VARCHAR),2)) LIKE '%' + @FlightHoursRemaining + '%')
               
                AND (@CyclesLimit IS NULL OR CAST(AMP.CyclesLimit AS VARCHAR) LIKE '%' + @CyclesLimit + '%')
                AND (@TimeLimit IS NULL OR CAST(AMP.TimeLimit AS VARCHAR) LIKE '%' + @TimeLimit + '%')
                AND (@LandingsLimit IS NULL OR CAST(AMP.LandingsLimit AS VARCHAR) LIKE '%' + @LandingsLimit + '%')
                AND (@EngineStartsLimit IS NULL OR CAST(AMP.EngineStartsLimit AS VARCHAR) LIKE '%' + @EngineStartsLimit + '%')
                AND (@CyclesRecorded IS NULL OR CAST(AMP.CyclesRecorded AS VARCHAR) LIKE '%' + @CyclesRecorded + '%')
                AND (@TimeRecorded IS NULL OR CAST(AMP.TimeRecorded AS VARCHAR) LIKE '%' + @TimeRecorded + '%')
                AND (@LandingsRecorded IS NULL OR CAST(AMP.LandingsRecorded AS VARCHAR) LIKE '%' + @LandingsRecorded + '%')
                AND (@EngineStartsRecorded IS NULL OR CAST(AMP.EngineStartsRecorded AS VARCHAR) LIKE '%' + @EngineStartsRecorded + '%')
                AND (@CyclesRemaining IS NULL OR CAST(AMP.CyclesRemaining AS VARCHAR) LIKE '%' + @CyclesRemaining + '%')
                AND (@TimeRemaining IS NULL OR CAST(AMP.TimeRemaining AS VARCHAR) LIKE '%' + @TimeRemaining + '%')
                AND (@LandingsRemaining IS NULL OR CAST(AMP.LandingsRemaining AS VARCHAR) LIKE '%' + @LandingsRemaining + '%')
                AND (@EngineStartsRemaining IS NULL OR CAST(AMP.EngineStartsRemaining AS VARCHAR) LIKE '%' + @EngineStartsRemaining + '%')
                AND (@MaintenanceClassName IS NULL  OR MC.[Name] LIKE '%' + @MaintenanceClassName + '%')
                AND (ISNULL(@WorksheetNumber,'') ='' OR WSH.WorksheetNumber LIKE '%' + @WorksheetNumber + '%')
                AND (ISNULL(@MtcCategory,'') ='' OR mtc.MtcCategory LIKE '%' + @MtcCategory + '%')
                AND (ISNULL(@WoNumber,'') ='' OR LWO.WorkOrderNum LIKE '%' + @WoNumber + '%')

        )

        SELECT *
        FROM CTE
        ORDER BY
            CASE WHEN @SortColumn = 'ProgramId'        AND @SortOrder = 'ASC'  THEN ProgramId END ASC,
            CASE WHEN @SortColumn = 'ProgramId'        AND @SortOrder = 'DESC' THEN ProgramId END DESC,
            CASE WHEN @SortColumn = 'VersionNumber'    AND @SortOrder = 'ASC'  THEN VersionNumber END ASC,
            CASE WHEN @SortColumn = 'VersionNumber'    AND @SortOrder = 'DESC' THEN VersionNumber END DESC,
            CASE WHEN @SortColumn = 'TailNumber'        AND @SortOrder = 'ASC'  THEN TailNumber END ASC,
            CASE WHEN @SortColumn = 'TailNumber'        AND @SortOrder = 'DESC' THEN TailNumber END DESC,
            CASE WHEN @SortColumn = 'AircraftMake'      AND @SortOrder = 'ASC'  THEN AircraftMake END ASC,
            CASE WHEN @SortColumn = 'AircraftMake'      AND @SortOrder = 'DESC' THEN AircraftMake END DESC,
            CASE WHEN @SortColumn = 'AircraftModel'     AND @SortOrder = 'ASC'  THEN AircraftModel END ASC,
            CASE WHEN @SortColumn = 'AircraftModel'     AND @SortOrder = 'DESC' THEN AircraftModel END DESC,
            CASE WHEN @SortColumn = 'SerialNumber'     AND @SortOrder = 'ASC'  THEN SerialNumber END ASC,
            CASE WHEN @SortColumn = 'SerialNumber'     AND @SortOrder = 'DESC' THEN SerialNumber END DESC,
            CASE WHEN @SortColumn = 'MaintenanceType'   AND @SortOrder = 'ASC'  THEN MaintenanceType END ASC,
            CASE WHEN @SortColumn = 'MaintenanceType'   AND @SortOrder = 'DESC' THEN MaintenanceType END DESC,
            CASE WHEN @SortColumn = 'TemplateId'   AND @SortOrder = 'ASC'  THEN TemplateIdNumber END ASC,
            CASE WHEN @SortColumn = 'TemplateId'   AND @SortOrder = 'DESC' THEN TemplateIdNumber END DESC,
            CASE WHEN @SortColumn = 'TemplateVersionNumber'   AND @SortOrder = 'ASC'  THEN TemplateVersionNumber END ASC,
            CASE WHEN @SortColumn = 'TemplateVersionNumber'   AND @SortOrder = 'DESC' THEN TemplateVersionNumber END DESC,
            CASE WHEN @SortColumn = 'NextScheduledMaintenance' AND @SortOrder = 'ASC'  THEN NextScheduledMaintenance END ASC,
            CASE WHEN @SortColumn = 'NextScheduledMaintenance' AND @SortOrder = 'DESC' THEN NextScheduledMaintenance END DESC,
            CASE WHEN @SortColumn = 'MaintenanceClassName' AND @SortOrder = 'ASC' THEN MaintenanceClassName END ASC,
            CASE WHEN @SortColumn = 'MaintenanceClassName' AND @SortOrder = 'DESC' THEN MaintenanceClassName END DESC,
            CASE WHEN @SortColumn = 'FlightHoursLimit' AND @SortOrder = 'ASC'THEN FlightHoursLimitHours END ASC,
            CASE WHEN @SortColumn = 'FlightHoursLimit' AND @SortOrder = 'DESC' THEN FlightHoursLimitHours END DESC,
            CASE WHEN @SortColumn = 'FlightHoursRecorded' AND @SortOrder = 'ASC' THEN FlightHoursRecordedHours END ASC,
            CASE WHEN @SortColumn = 'FlightHoursRecorded' AND @SortOrder = 'DESC' THEN FlightHoursRecordedHours END DESC,
            CASE WHEN @SortColumn = 'FlightHoursRemaining' AND @SortOrder = 'ASC' THEN FlightHoursRemainingHours END ASC,
            CASE WHEN @SortColumn = 'FlightHoursRemaining' AND @SortOrder = 'DESC' THEN FlightHoursRemainingHours END DESC,
            CASE WHEN @SortColumn = 'CyclesLimit' AND @SortOrder = 'ASC' THEN CyclesLimit END ASC,
            CASE WHEN @SortColumn = 'CyclesLimit' AND @SortOrder = 'DESC' THEN CyclesLimit END DESC,
            CASE WHEN @SortColumn = 'TimeLimit' AND @SortOrder = 'ASC' THEN TimeLimit END ASC,
            CASE WHEN @SortColumn = 'TimeLimit' AND @SortOrder = 'DESC' THEN TimeLimit END DESC,
            CASE WHEN @SortColumn = 'LandingsLimit' AND @SortOrder = 'ASC' THEN LandingsLimit END ASC,
            CASE WHEN @SortColumn = 'LandingsLimit' AND @SortOrder = 'DESC' THEN LandingsLimit END DESC,
            CASE WHEN @SortColumn = 'EngineStartsLimit' AND @SortOrder = 'ASC' THEN EngineStartsLimit END ASC,
            CASE WHEN @SortColumn = 'EngineStartsLimit' AND @SortOrder = 'DESC' THEN EngineStartsLimit END DESC,
            CASE WHEN @SortColumn = 'CyclesRecorded' AND @SortOrder = 'ASC' THEN CyclesRecorded END ASC,
            CASE WHEN @SortColumn = 'CyclesRecorded' AND @SortOrder = 'DESC' THEN CyclesRecorded END DESC,
            CASE WHEN @SortColumn = 'TimeRecorded' AND @SortOrder = 'ASC' THEN TimeRecorded END ASC,
            CASE WHEN @SortColumn = 'TimeRecorded' AND @SortOrder = 'DESC' THEN TimeRecorded END DESC,
            CASE WHEN @SortColumn = 'LandingsRecorded' AND @SortOrder = 'ASC' THEN LandingsRecorded END ASC,
            CASE WHEN @SortColumn = 'LandingsRecorded' AND @SortOrder = 'DESC' THEN LandingsRecorded END DESC,
            CASE WHEN @SortColumn = 'EngineStartsRecorded' AND @SortOrder = 'ASC' THEN EngineStartsRecorded END ASC,
            CASE WHEN @SortColumn = 'EngineStartsRecorded' AND @SortOrder = 'DESC' THEN EngineStartsRecorded END DESC,
            CASE WHEN @SortColumn = 'CyclesRemaining' AND @SortOrder = 'ASC' THEN CyclesRemaining END ASC,
            CASE WHEN @SortColumn = 'CyclesRemaining' AND @SortOrder = 'DESC' THEN CyclesRemaining END DESC,
            CASE WHEN @SortColumn = 'TimeRemaining' AND @SortOrder = 'ASC' THEN TimeRemaining END ASC,
            CASE WHEN @SortColumn = 'TimeRemaining' AND @SortOrder = 'DESC' THEN TimeRemaining END DESC,
            CASE WHEN @SortColumn = 'LandingsRemaining' AND @SortOrder = 'ASC' THEN LandingsRemaining END ASC,
            CASE WHEN @SortColumn = 'LandingsRemaining' AND @SortOrder = 'DESC' THEN LandingsRemaining END DESC,
            CASE WHEN @SortColumn = 'EngineStartsRemaining' AND @SortOrder = 'ASC' THEN EngineStartsRemaining END ASC,
            CASE WHEN @SortColumn = 'EngineStartsRemaining' AND @SortOrder = 'DESC' THEN EngineStartsRemaining END DESC,
            CASE WHEN @SortColumn = 'CreatedDate'       AND @SortOrder = 'ASC'  THEN CreatedDate END ASC,
            CASE WHEN @SortColumn = 'CreatedDate'       AND @SortOrder = 'DESC' THEN CreatedDate END DESC,
            CASE WHEN @SortColumn = 'WorksheetNumber' AND @SortOrder = 'ASC' THEN WorksheetNumber END ASC,
            CASE WHEN @SortColumn = 'WorksheetNumber' AND @SortOrder = 'DESC' THEN WorksheetNumber END DESC,
            CASE WHEN @SortColumn = 'MtcCategory'       AND @SortOrder = 'ASC'  THEN MtcCategory END ASC,
            CASE WHEN @SortColumn = 'MtcCategory'       AND @SortOrder = 'DESC' THEN MtcCategory END DESC,
             CASE WHEN @SortColumn = 'woNumber'       AND @SortOrder = 'ASC'  THEN WorkOrderNum END ASC,
            CASE WHEN @SortColumn = 'woNumber'       AND @SortOrder = 'DESC' THEN WorkOrderNum END DESC,
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
                '@MasterCompanyId = '    + ISNULL(CAST(@MasterCompanyId   AS VARCHAR(20)), 'NULL')
                + ', @IsDeleted = '      + ISNULL(CAST(@IsDeleted         AS VARCHAR(5)),  'NULL')
                + ', @GlobalFilter = '   + ISNULL(@GlobalFilter, 'NULL'),
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