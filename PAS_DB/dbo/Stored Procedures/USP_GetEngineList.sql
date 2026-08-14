/********************
** File:        [USP_GetEngineList]
** Author:      Amit Ghediya
** Description: Get Engine data from EngineRegistryHeader
** 
** Change History
********************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    29/06/2026   Amit Ghediya       Created [PN-17037]
** 2    09/07/2026   Amit Ghediya       Get Engine name for list
** 3    19/07/2026   Amit Ghediya       Added SLNum, CntrlNum, Cond, Site, Warehouse from Stockline [PN-17344]
** 4    14/08/2026   Divyesh Kathiriya  Get AC Tail Num from the aircraft linked through EngineRegistryIds. [PN-17626]
** 5    14/08/2026   Divyesh Kathiriya  Added AC Tail Num And Third Party Own Only filter for external customers. [PN-17626]

********************/
CREATE PROCEDURE [dbo].[USP_GetEngineList]
    @PageNumber         INT             = 1,
    @PageSize           INT             = 10,
    @SortColumn         VARCHAR(100)    = 'EngineRegistryId',
    @SortOrder          VARCHAR(4)      = 'DESC',
    @GlobalFilter       VARCHAR(100)    = NULL,
    @MakeType           VARCHAR(100)    = NULL,
    @EngineModel		VARCHAR(100)    = NULL,
    @EngineSubModel		VARCHAR(100)    = NULL,
    @TailNum            VARCHAR(50)     = NULL,
    @SerialNum          VARCHAR(100)    = NULL,
    @EngineStatus		VARCHAR(100)    = NULL,
    @IsActive           BIT             = NULL,
    @ManufacturedDate   DATETIME        = NULL,
    @PlaceInServiceDate DATETIME        = NULL,
    @TotalTSN           VARCHAR(50)  = NULL,
    @TotalCSN           VARCHAR(50)  = NULL,
    @Hobbs              VARCHAR(50)  = NULL,
    @EngineLocation		VARCHAR(200)    = NULL,
    @MaintenanceStatus  VARCHAR(100)    = NULL,
    @NumOfEngines       VARCHAR(100)    = NULL,
    @NextScheduled      DATETIME        = NULL,
    @EngineStatusId		BIGINT          = NULL,
    @MEL                VARCHAR(200)    = NULL,
    @IsDeleted          BIT             = 0,
    @MasterCompanyId    INT,
    @Custname           VARCHAR(200)    = NULL,
	@EngineName         VARCHAR(200)    = NULL,
    @SLNum              VARCHAR(50)     = NULL,
    @CntrlNum           VARCHAR(50)     = NULL,
    @Cond               VARCHAR(100)    = NULL,
    @Site               VARCHAR(50)     = NULL,
    @Warehouse          VARCHAR(100)    = NULL,
    @Location           VARCHAR(50)     = NULL,
    @ThirdPartyOwnOnly  BIT             = 0
AS
BEGIN
    --SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

    DECLARE @AccountType VARCHAR(20) = 'External';

        WITH CTE AS
        (
            SELECT
                AR.EngineRegistryId,
                AR.MakeType,
				AR.EngineName,
                AR.EngineModel,
                AR.EngineSubModel,
                AR.NumOfEngines,
                AIRCRAFT.[TailNum],
                AR.SerialNum,
                AR.ManufacturedDate,
                AR.PlaceInServiceDate,
                AR.TotalTSN,
				CAST(CAST(ISNULL(AR.TotalTSN,0) AS INT) AS VARCHAR) + ' : ' + RIGHT('00' + CAST(CAST(ISNULL(AR.TotalTSNMM,0) AS INT) AS VARCHAR),2) AS TotalTSNHHMM,
				AR.TotalCSN,
                AR.Hobbs,
                AR.EngineLocation,
				AMS.[Name] AS MaintenanceStatus,
                AR.NextScheduled,
                AR.MEL,
				ASS.[Name] AS EngineStatus,
                AR.IsActive,
                AR.CreatedDate,
                C.[Name] AS Custname,
                STK.StockLineNumber AS SLNum,
                STK.ControlNumber AS CntrlNum,
                STK.Condition AS Cond,
                SITE.[Name] AS Site,
                WH.[Name] AS Warehouse,
                LOC.[Name] AS Location,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[EngineRegistryHeader] AS AR WITH (NOLOCK)
			LEFT JOIN [dbo].[AircraftStatus] ASS WITH (NOLOCK) ON AR.[EngineStatusId] = ASS.[AircraftStatusId]
			LEFT JOIN [dbo].[MaintenanceStatus] AMS WITH (NOLOCK) ON AR.[MaintenanceStatusId] = AMS.[MaintenanceStatusId]
            LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON AR.CustomerId = C.CustomerId
            LEFT JOIN [dbo].[CustomerAffiliation] CA WITH (NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
            LEFT JOIN [dbo].[StockLine] STK WITH (NOLOCK) ON AR.StockLineId = STK.StockLineId
            LEFT JOIN [dbo].[Site] SITE WITH (NOLOCK) ON STK.SiteId = SITE.SiteId
            LEFT JOIN [dbo].[Warehouse] WH WITH (NOLOCK) ON STK.WarehouseId = WH.WarehouseId
            LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON STK.LocationId = LOC.LocationId
            OUTER APPLY
            (
                SELECT TOP (1)
                    AIRCRAFT_HEADER.[TailNum]
                FROM [dbo].[AircraftRegistryHeader] AIRCRAFT_HEADER WITH (NOLOCK)
                CROSS APPLY STRING_SPLIT(AIRCRAFT_HEADER.[EngineRegistryIds], ',') ENGINE_ID
                WHERE AIRCRAFT_HEADER.[MasterCompanyId] = AR.[MasterCompanyId]
                    AND AIRCRAFT_HEADER.[IsDeleted] = 0
                    AND TRY_CONVERT(BIGINT, LTRIM(RTRIM(ENGINE_ID.[value]))) = AR.[EngineRegistryId]
                ORDER BY AIRCRAFT_HEADER.[AircraftRegistryId] DESC
            ) AIRCRAFT
            WHERE
                AR.MasterCompanyId = @MasterCompanyId
                AND (@IsDeleted IS NULL OR AR.IsDeleted = @IsDeleted)
                AND (
                    @GlobalFilter IS NULL
                    OR AR.MakeType       LIKE '%' + @GlobalFilter + '%'
                    OR AR.EngineModel  LIKE '%' + @GlobalFilter + '%'
                    OR AIRCRAFT.[TailNum] LIKE '%' + @GlobalFilter + '%'
                    OR AR.SerialNum      LIKE '%' + @GlobalFilter + '%'
                    OR AR.EngineStatus LIKE '%' + @GlobalFilter + '%'
                    OR C.[Name] LIKE '%' + @GlobalFilter + '%'
                )
                AND (@MakeType          IS NULL OR AR.MakeType         LIKE '%' + @MakeType         + '%')
				AND (@EngineName          IS NULL OR AR.EngineName LIKE '%' + @EngineName + '%')
                AND (@EngineModel     IS NULL OR AR.EngineModel    LIKE '%' + @EngineModel    + '%')
                AND (@EngineSubModel  IS NULL OR AR.EngineSubModel LIKE '%' + @EngineSubModel + '%')
                AND (@TailNum           IS NULL OR AIRCRAFT.[TailNum] LIKE '%' + @TailNum + '%')
                AND (@SerialNum         IS NULL OR AR.SerialNum        LIKE '%' + @SerialNum        + '%')
                AND (@EngineStatus    IS NULL OR AR.EngineStatus   LIKE '%' + @EngineStatus   + '%')
                AND (@IsActive          IS NULL OR AR.IsActive         = @IsActive)
                AND (@ManufacturedDate  IS NULL OR CAST(AR.ManufacturedDate  AS DATE) = CAST(@ManufacturedDate  AS DATE))
                AND (@PlaceInServiceDate IS NULL OR CAST(AR.PlaceInServiceDate AS DATE) = CAST(@PlaceInServiceDate AS DATE))
                AND (@NumOfEngines      IS NULL OR AR.NumOfEngines     LIKE '%' + @NumOfEngines     + '%')
                AND (@TotalTSN          IS NULL OR AR.TotalTSN     LIKE '%' + @TotalTSN     + '%')
                AND (@TotalCSN          IS NULL OR AR.TotalCSN     LIKE '%' + @TotalCSN     + '%')
                AND (@Hobbs             IS NULL OR AR.Hobbs     LIKE '%' + @Hobbs     + '%')
                AND (@EngineLocation  IS NULL OR AR.EngineLocation LIKE '%' + @EngineLocation + '%')
                AND (@MaintenanceStatus  IS NULL OR AR.MaintenanceStatus LIKE '%' + @MaintenanceStatus + '%')
                AND (@NextScheduled     IS NULL OR CAST(AR.NextScheduled AS DATE) = CAST(@NextScheduled AS DATE))
                AND (@MEL               IS NULL OR AR.MEL              LIKE '%' + @MEL              + '%')
                AND (@EngineStatusId  IS NULL OR AR.EngineStatusId = @EngineStatusId)
                AND (@Custname          IS NULL OR C.[Name] LIKE '%' + @Custname + '%')
                AND (@SLNum             IS NULL OR STK.StockLineNumber LIKE '%' + @SLNum     + '%')
                AND (@CntrlNum          IS NULL OR STK.ControlNumber   LIKE '%' + @CntrlNum  + '%')
                AND (@Cond              IS NULL OR STK.Condition       LIKE '%' + @Cond      + '%')
                AND (@Site              IS NULL OR SITE.[Name]         LIKE '%' + @Site      + '%')
                AND (@Warehouse         IS NULL OR WH.[Name]           LIKE '%' + @Warehouse + '%')
                AND (@Location          IS NULL OR LOC.[Name]          LIKE '%' + @Location  + '%')
                AND (ISNULL(@ThirdPartyOwnOnly, 0) = 0 OR CA.[AccountType] = @AccountType)
        )
        SELECT
            EngineRegistryId,
            MakeType,
			EngineName,
            EngineModel,
            EngineSubModel,
            NumOfEngines,
            TailNum,
            SerialNum,
            ManufacturedDate,
            PlaceInServiceDate,
            TotalTSN,			
            TotalCSN,
			TotalTSNHHMM,
            Hobbs,
            EngineLocation,
            MaintenanceStatus,
            NextScheduled,
            MEL,
            EngineStatus,
            IsActive,
            CreatedDate,
            Custname,
            SLNum,
            CntrlNum,
            Cond,
            Site,
            Warehouse,
            Location,
            TotalRecords
        FROM CTE
        ORDER BY
            CASE WHEN @SortColumn = 'MakeType'           AND @SortOrder = 'ASC'  THEN MakeType          END ASC,
            CASE WHEN @SortColumn = 'MakeType'           AND @SortOrder = 'DESC' THEN MakeType          END DESC,
			CASE WHEN @SortColumn = 'EngineName'      AND @SortOrder = 'ASC'  THEN EngineName     END ASC,
            CASE WHEN @SortColumn = 'EngineName'      AND @SortOrder = 'DESC' THEN EngineName     END DESC,
            CASE WHEN @SortColumn = 'EngineModel'      AND @SortOrder = 'ASC'  THEN EngineModel     END ASC,
            CASE WHEN @SortColumn = 'EngineModel'      AND @SortOrder = 'DESC' THEN EngineModel     END DESC,
            CASE WHEN @SortColumn = 'EngineSubModel'   AND @SortOrder = 'ASC'  THEN EngineSubModel  END ASC,
            CASE WHEN @SortColumn = 'EngineSubModel'   AND @SortOrder = 'DESC' THEN EngineSubModel  END DESC,
            CASE WHEN @SortColumn = 'TailNum'            AND @SortOrder = 'ASC'  THEN TailNum           END ASC,
            CASE WHEN @SortColumn = 'TailNum'            AND @SortOrder = 'DESC' THEN TailNum           END DESC,
            CASE WHEN @SortColumn = 'SerialNum'          AND @SortOrder = 'ASC'  THEN SerialNum         END ASC,
            CASE WHEN @SortColumn = 'SerialNum'          AND @SortOrder = 'DESC' THEN SerialNum         END DESC,
            CASE WHEN @SortColumn = 'EngineStatus'     AND @SortOrder = 'ASC'  THEN EngineStatus    END ASC,
            CASE WHEN @SortColumn = 'EngineStatus'     AND @SortOrder = 'DESC' THEN EngineStatus    END DESC,
            CASE WHEN @SortColumn = 'ManufacturedDate'   AND @SortOrder = 'ASC'  THEN ManufacturedDate  END ASC,
            CASE WHEN @SortColumn = 'ManufacturedDate'   AND @SortOrder = 'DESC' THEN ManufacturedDate  END DESC,
            CASE WHEN @SortColumn = 'PlaceInServiceDate' AND @SortOrder = 'ASC'  THEN PlaceInServiceDate END ASC,
            CASE WHEN @SortColumn = 'PlaceInServiceDate' AND @SortOrder = 'DESC' THEN PlaceInServiceDate END DESC,
            CASE WHEN @SortColumn = 'TotalTSN'           AND @SortOrder = 'ASC'  THEN TotalTSN          END ASC,
            CASE WHEN @SortColumn = 'TotalTSN'           AND @SortOrder = 'DESC' THEN TotalTSN          END DESC,
            CASE WHEN @SortColumn = 'TotalCSN'           AND @SortOrder = 'ASC'  THEN TotalCSN          END ASC,
            CASE WHEN @SortColumn = 'TotalCSN'           AND @SortOrder = 'DESC' THEN TotalCSN          END DESC,
			CASE WHEN @SortColumn = 'TotalTSNHHMM'       AND @SortOrder = 'ASC'  THEN TotalTSNHHMM      END ASC,
            CASE WHEN @SortColumn = 'TotalTSNHHMM'       AND @SortOrder = 'DESC' THEN TotalTSNHHMM      END DESC,
            CASE WHEN @SortColumn = 'Hobbs'              AND @SortOrder = 'ASC'  THEN Hobbs             END ASC,
            CASE WHEN @SortColumn = 'Hobbs'              AND @SortOrder = 'DESC' THEN Hobbs             END DESC,
            CASE WHEN @SortColumn = 'EngineLocation'   AND @SortOrder = 'ASC'  THEN EngineLocation  END ASC,
            CASE WHEN @SortColumn = 'EngineLocation'   AND @SortOrder = 'DESC' THEN EngineLocation  END DESC,
            CASE WHEN @SortColumn = 'MaintenanceStatus'  AND @SortOrder = 'ASC'  THEN MaintenanceStatus  END ASC,
            CASE WHEN @SortColumn = 'MaintenanceStatus'  AND @SortOrder = 'DESC' THEN MaintenanceStatus  END DESC,
            CASE WHEN @SortColumn = 'NextScheduled'      AND @SortOrder = 'ASC'  THEN NextScheduled     END ASC,
            CASE WHEN @SortColumn = 'NextScheduled'      AND @SortOrder = 'DESC' THEN NextScheduled     END DESC,
            CASE WHEN @SortColumn = 'MEL'                AND @SortOrder = 'ASC'  THEN MEL               END ASC,
            CASE WHEN @SortColumn = 'MEL'                AND @SortOrder = 'DESC' THEN MEL               END DESC,
            CASE WHEN @SortColumn = 'NumOfEngines'       AND @SortOrder = 'ASC'  THEN NumOfEngines      END ASC,
            CASE WHEN @SortColumn = 'NumOfEngines'       AND @SortOrder = 'DESC' THEN NumOfEngines      END DESC,
            CASE WHEN @SortColumn = 'CreatedDate'        AND @SortOrder = 'ASC'  THEN CreatedDate       END ASC,
            CASE WHEN @SortColumn = 'CreatedDate'        AND @SortOrder = 'DESC' THEN CreatedDate       END DESC,
            CASE WHEN @SortColumn = 'Custname' AND @SortOrder = 'ASC' THEN Custname END ASC,
            CASE WHEN @SortColumn = 'Custname' AND @SortOrder = 'DESC' THEN Custname END DESC,
            CASE WHEN @SortColumn = 'SLNum' AND @SortOrder = 'ASC' THEN SLNum END ASC,
            CASE WHEN @SortColumn = 'SLNum' AND @SortOrder = 'DESC' THEN SLNum END DESC,
            CASE WHEN @SortColumn = 'CntrlNum' AND @SortOrder = 'ASC' THEN CntrlNum END ASC,
            CASE WHEN @SortColumn = 'CntrlNum' AND @SortOrder = 'DESC' THEN CntrlNum END DESC,
            CASE WHEN @SortColumn = 'Cond' AND @SortOrder = 'ASC' THEN Cond END ASC,
            CASE WHEN @SortColumn = 'Cond' AND @SortOrder = 'DESC' THEN Cond END DESC,
            CASE WHEN @SortColumn = 'Site' AND @SortOrder = 'ASC' THEN Site END ASC,
            CASE WHEN @SortColumn = 'Site' AND @SortOrder = 'DESC' THEN Site END DESC,
            CASE WHEN @SortColumn = 'Warehouse' AND @SortOrder = 'ASC' THEN Warehouse END ASC,
            CASE WHEN @SortColumn = 'Warehouse' AND @SortOrder = 'DESC' THEN Warehouse END DESC,
            CASE WHEN @SortColumn = 'Location' AND @SortOrder = 'ASC' THEN Location END ASC,
            CASE WHEN @SortColumn = 'Location' AND @SortOrder = 'DESC' THEN Location END DESC,
            EngineRegistryId DESC
        OFFSET  (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);                         -- prevents bad cached plans from dynamic sort/filter pattern

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetEngineList',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = '    + ISNULL(CAST(@MasterCompanyId   AS VARCHAR(20)), 'NULL')
                + ', @IsDeleted = '      + ISNULL(CAST(@IsDeleted         AS VARCHAR(5)),  'NULL')
                + ', @EngineStatusId = '+ ISNULL(CAST(@EngineStatusId AS VARCHAR(20)), 'NULL')
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