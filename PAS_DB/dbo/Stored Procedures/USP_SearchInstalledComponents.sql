/*************************************************************
** File:        [USP_SearchInstalledComponents]
** Description: To search the installed components
** Date:        21/04/2026
**
** RETURN VALUE:
**************************************************************
** Change History
**************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    21/04/2026   Priyansh Patel     Created [PN-16140]
** 2    06/05/2026   Priyansh Patel     Created [PN-16303]
** 3    03/06/2026   Nakul Chandigra    Added [TotalTSNMM] field for select [PN-16691]
** 3    04/06/2026   Sumit Kumar        Added missing fields for the view PN-16214.

*************************************************************/
--EXEC [dbo].[USP_SearchInstalledComponents] @MasterCompanyId =1
CREATE   PROCEDURE [dbo].[USP_SearchInstalledComponents]
(   
    @MasterCompanyId    INT,
    @ItemMasterId       BIGINT          = NULL,
    @PartDescription    VARCHAR(500)    = NULL,
    @SerialNum          VARCHAR(100)    = NULL,
    @ATACode            VARCHAR(200)    = NULL,
    @DateInstalled      DATE            = NULL,
    -- Column Filters
    @ACTailNum          VARCHAR(100)    = NULL,
    @MakeType           VARCHAR(100)    = NULL,
    @AircraftModel      VARCHAR(100)    = NULL,
    @ColumnSerialNum    VARCHAR(100)    = NULL,  
    @TotalTSN           DECIMAL(18,6)   = NULL,
    @TotalCSN           DECIMAL(18,6)   = NULL,
    @Hobbs              DECIMAL(18,6)   = NULL,
    @FlightHours        VARCHAR(100)   = NULL,
    @Cycles             DECIMAL(18,6)   = NULL,
    @LastMaintenance    DATE            = NULL,
    @NextMaintenance    DATE            = NULL,

    -- Pagination
    @PageNumber         INT             = 1,
    @PageSize           INT             = 10,

    -- Sorting
    @SortColumn         VARCHAR(50)     = 'DateInstalled',
    @SortOrder          INT             = -1    -- 1 ASC, -1 DESC
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

    ;WITH Result AS (
        SELECT
            [AIPD].[AircraftInstalledPartDetailsId],
            [AIPD].[AircraftRegistryId]                                                     AS [AircraftRegistryId],
            [AIPD].[ItemMasterId]                                                           AS [ItemMasterId],
            [AIPD].[PartNumber]                                                             AS [PartNumber],
            [AIPD].[PartDescription]                                                        AS [PartDescription],
            [ARH].[TailNum]                                                                 AS [ACTailNum],
            [ARH].[MakeType],
            [ARH].[AircraftModel],
            [ARH].[SerialNum],
            [ARH].[TotalTSN],
            [ARH].[TotalCSN],
            [ARH].[Hobbs],
            CONCAT_WS(' - ', [IMAM].[Level1], [IMAM].[Level2], [IMAM].[Level3])            AS [ATACode],
            [AIPD].[DateInstalled],
            FORMAT(ISNULL([AIPD].[FlightHours], 0), '0') + ' : ' + FORMAT(ISNULL([AIPD].[FlightMinutes], 0), '00') AS [FlightHours],
            [AIPD].[Cycles],
            [ARH].[LastMaintenanceDate]                                                     AS [LastMaintenance],
            [ARH].[NextScheduled]                                                           AS [NextMaintenance],
            [ARH].[TotalTSNMM],
            [AIPD].[SequenceNum],
            [AIPD].[IsLLP],
			[AIPD].[IsSerialized],
            [AIPD].[Quantity],
            [AIPD].[PositionCode],
            [AIPD].[InstallCycles],
            [AIPD].[InstallFlightHours],
			[AIPD].[InstallFlightTime] AS 'InstallFlightMinutes',
            [AIPD].[PartEngineStarts] AS EngineStarts,
            [AIPD].[ATAChapterId],
            CONCAT_WS(' - ',
				NULLIF(IMAM.Level1, ''),
				NULLIF(IMAM.Level2, ''),
				NULLIF(IMAM.Level3, '')
			) AS AtaChapter,
            [STK].Condition,
			[STK].StockLineNumber,
			[STK].ControlNumber,
			[STK].SerialNumber
        FROM [dbo].[AircraftInstalledPartDetails] AIPD WITH (NOLOCK)
             LEFT JOIN [dbo].[ItemMasterAircraftMapping] IMAM WITH (NOLOCK) ON AIPD.ATAChapterId = IMAM.ItemMasterAircraftMappingId
             LEFT JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK) ON ARH.AircraftRegistryId = AIPD.AircraftRegistryId
             LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.StockLineId = AIPD.StockLineId
            WHERE AIPD.MasterCompanyId = @MasterCompanyId
            AND (@ItemMasterId      IS NULL OR @ItemMasterId = 0  OR AIPD.ItemMasterId = @ItemMasterId)
            AND (@PartDescription   IS NULL OR AIPD.PartDescription LIKE '%' + @PartDescription + '%')
            AND (@ACTailNum         IS NULL OR ARH.TailNum          LIKE '%' + @ACTailNum       + '%')
            AND (@MakeType          IS NULL OR ARH.MakeType         LIKE '%' + @MakeType        + '%')
            AND (@AircraftModel     IS NULL OR ARH.AircraftModel    LIKE '%' + @AircraftModel   + '%')
            AND (@SerialNum       IS NULL OR ARH.SerialNum LIKE '%' + @SerialNum       + '%')
            AND (@ColumnSerialNum IS NULL OR ARH.SerialNum LIKE '%' + @ColumnSerialNum + '%')
            AND (@ATACode           IS NULL OR CONCAT_WS(' - ', IMAM.Level1, IMAM.Level2, IMAM.Level3) LIKE '%' + @ATACode + '%')
            AND (@DateInstalled     IS NULL OR CAST(AIPD.DateInstalled          AS DATE) = @DateInstalled)
            AND (@LastMaintenance   IS NULL OR CAST(ARH.LastMaintenanceDate     AS DATE) = @LastMaintenance)
            AND (@NextMaintenance   IS NULL OR CAST(ARH.NextScheduled           AS DATE) = @NextMaintenance)
            AND (@TotalTSN          IS NULL OR ARH.TotalTSN      = @TotalTSN)
            AND (@TotalCSN          IS NULL OR ARH.TotalCSN      = @TotalCSN)
            AND (@Hobbs             IS NULL OR ARH.Hobbs         = @Hobbs)
            AND (@FlightHours       IS NULL OR CAST([AIPD].[FlightHours]  AS VARCHAR) LIKE '%' + @FlightHours + '%' OR CAST([AIPD].[FlightMinutes]  AS VARCHAR) LIKE '%' + @FlightHours + '%')
            AND (@Cycles            IS NULL OR AIPD.Cycles       = @Cycles)
    ),
    TotalCounted AS (
        SELECT COUNT(1) AS TotalCount FROM Result
    )
    SELECT r.*, t.TotalCount
    FROM Result r
    CROSS JOIN TotalCounted t
    ORDER BY
        -- ACTailNum
        CASE WHEN @SortColumn = 'acTailNum'         AND @SortOrder = 1  THEN ACTailNum       END ASC,
        CASE WHEN @SortColumn = 'acTailNum'         AND @SortOrder = -1 THEN ACTailNum       END DESC,
        -- MakeType
        CASE WHEN @SortColumn = 'acMakeType'          AND @SortOrder = 1  THEN MakeType        END ASC,
        CASE WHEN @SortColumn = 'acMakeType'          AND @SortOrder = -1 THEN MakeType        END DESC,
        -- AircraftModel
        CASE WHEN @SortColumn = 'aircraftModel'     AND @SortOrder = 1  THEN AircraftModel   END ASC,
        CASE WHEN @SortColumn = 'aircraftModel'     AND @SortOrder = -1 THEN AircraftModel   END DESC,
        -- SerialNum
        CASE WHEN @SortColumn = 'serialNum'         AND @SortOrder = 1  THEN SerialNum       END ASC,
        CASE WHEN @SortColumn = 'serialNum'         AND @SortOrder = -1 THEN SerialNum       END DESC,
        -- TotalTSN
        CASE WHEN @SortColumn = 'totalTSN'          AND @SortOrder = 1  THEN TotalTSN        END ASC,
        CASE WHEN @SortColumn = 'totalTSN'          AND @SortOrder = -1 THEN TotalTSN        END DESC,
        -- TotalCSN
        CASE WHEN @SortColumn = 'totalCSN'          AND @SortOrder = 1  THEN TotalCSN        END ASC,
        CASE WHEN @SortColumn = 'totalCSN'          AND @SortOrder = -1 THEN TotalCSN        END DESC,
        -- Hobbs
        CASE WHEN @SortColumn = 'hobbs'             AND @SortOrder = 1  THEN Hobbs           END ASC,
        CASE WHEN @SortColumn = 'hobbs'             AND @SortOrder = -1 THEN Hobbs           END DESC,
        -- FlightHours
        CASE WHEN @SortColumn = 'flightHours'       AND @SortOrder = 1  THEN FlightHours     END ASC,
        CASE WHEN @SortColumn = 'flightHours'       AND @SortOrder = -1 THEN FlightHours     END DESC,
        -- Cycles
        CASE WHEN @SortColumn = 'cycles'            AND @SortOrder = 1  THEN Cycles          END ASC,
        CASE WHEN @SortColumn = 'cycles'            AND @SortOrder = -1 THEN Cycles          END DESC,
        -- DateInstalled
        CASE WHEN @SortColumn = 'DateInstalled'     AND @SortOrder = 1  THEN DateInstalled   END ASC,
        CASE WHEN @SortColumn = 'DateInstalled'     AND @SortOrder = -1 THEN DateInstalled   END DESC,
        -- LastMaintenance
        CASE WHEN @SortColumn = 'lastMaintenance'   AND @SortOrder = 1  THEN LastMaintenance END ASC,
        CASE WHEN @SortColumn = 'lastMaintenance'   AND @SortOrder = -1 THEN LastMaintenance END DESC,
        -- NextMaintenance
        CASE WHEN @SortColumn = 'nextMaintenance'   AND @SortOrder = 1  THEN NextMaintenance END ASC,
        CASE WHEN @SortColumn = 'nextMaintenance'   AND @SortOrder = -1 THEN NextMaintenance END DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
    DECLARE
        @ErrorLogID INT,
        @DatabaseName VARCHAR(100) = DB_NAME(),
        @AdhocComments VARCHAR(150) = 'USP_SearchInstalledComponents',
        @ProcedureParameters VARCHAR(3000),
        @ApplicationName VARCHAR(100) = 'PAS';

    SET @ProcedureParameters =
          '@ItemMasterId=' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(20))
        + ', @PNDescription=' + ISNULL(@PartDescription, '')
        + ', @SerialNum=' + ISNULL(@SerialNum, '')
        + ', @ATACode=' + ISNULL(@ATACode, '')
        + ', @DateInstalled=' + ISNULL(CONVERT(VARCHAR(20), @DateInstalled, 120), '')
        + ', @PageNumber=' + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(20))
        + ', @PageSize=' + CAST(ISNULL(@PageSize, 0) AS VARCHAR(20))
        + ', @SortColumn=' + ISNULL(@SortColumn, '')
        + ', @SortOrder=' + CAST(ISNULL(@SortOrder, 0) AS VARCHAR(20));

    EXEC spLogException
         @DatabaseName        = @DatabaseName,
         @AdhocComments       = @AdhocComments,
         @ProcedureParameters = @ProcedureParameters,
         @ApplicationName     = @ApplicationName,
         @ErrorLogID          = @ErrorLogID OUTPUT;

    RAISERROR
    (
        'Unexpected error occurred in the database. Please let the support team know the error number: %d',
        16,
        1,
        @ErrorLogID
    );

    RETURN 1;
END CATCH
END