/************************************************************
** File:        [USP_GetAircraftRegistryList]
** Author:      Priyansh Patel
** Description: Get Aircraft Registry data from AircraftRegistryHeader
** 
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    26/02/2026   Priyansh Patel  Created [PN-15841]
************************************************************/
CREATE PROCEDURE [dbo].[USP_GetAircraftRegistryList]
    @PageNumber         INT             = 1,
    @PageSize           INT             = 10,
    @SortColumn         VARCHAR(100)    = 'AircraftRegistryId',
    @SortOrder          VARCHAR(4)      = 'DESC',
    @GlobalFilter       VARCHAR(100)    = NULL,
    @MakeType           VARCHAR(100)    = NULL,
    @AircraftModel      VARCHAR(100)    = NULL,
    @AircraftSubModel   VARCHAR(100)    = NULL,
    @TailNum            VARCHAR(50)     = NULL,
    @SerialNum          VARCHAR(100)    = NULL,
    @AircraftStatus     VARCHAR(100)    = NULL,
    @IsActive           BIT             = NULL,
    @ManufacturedDate   DATETIME        = NULL,
    @PlaceInServiceDate DATETIME        = NULL,
    @TotalTSN           DECIMAL(18, 2)  = NULL,
    @TotalCSN           DECIMAL(18, 2)  = NULL,
    @Hobbs              DECIMAL(18, 2)  = NULL,
    @AircraftLocation   VARCHAR(200)    = NULL,
    @NumOfEngines       VARCHAR(100)    = NULL,
    @NextScheduled      DATETIME        = NULL,
    @AircraftStatusId   BIGINT          = NULL,
    @MEL                VARCHAR(200)    = NULL,
    @IsDeleted          BIT             = 0,
    @MasterCompanyId    INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

        WITH CTE AS
        (
            SELECT
                AR.AircraftRegistryId,
                AR.MakeType,
                AR.AircraftModel,
                AR.AircraftSubModel,
                AR.NumOfEngines,
                AR.TailNum,
                AR.SerialNum,
                AR.ManufacturedDate,
                AR.PlaceInServiceDate,
                AR.TotalTSN,
                AR.TotalCSN,
                AR.Hobbs,
                AR.AircraftLocation,
                AR.NextScheduled,
                AR.MEL,
                AR.AircraftStatus,
                AR.IsActive,
                AR.CreatedDate,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[AircraftRegistryHeader] AS AR WITH (NOLOCK)
            WHERE
                AR.MasterCompanyId = @MasterCompanyId
                AND (@IsDeleted IS NULL OR AR.IsDeleted = @IsDeleted)
                AND (
                    @GlobalFilter IS NULL
                    OR AR.MakeType       LIKE '%' + @GlobalFilter + '%'
                    OR AR.AircraftModel  LIKE '%' + @GlobalFilter + '%'
                    OR AR.TailNum        LIKE '%' + @GlobalFilter + '%'
                    OR AR.SerialNum      LIKE '%' + @GlobalFilter + '%'
                    OR AR.AircraftStatus LIKE '%' + @GlobalFilter + '%'
                )
                AND (@MakeType          IS NULL OR AR.MakeType         LIKE '%' + @MakeType         + '%')
                AND (@AircraftModel     IS NULL OR AR.AircraftModel    LIKE '%' + @AircraftModel    + '%')
                AND (@AircraftSubModel  IS NULL OR AR.AircraftSubModel LIKE '%' + @AircraftSubModel + '%')
                AND (@TailNum           IS NULL OR AR.TailNum          LIKE '%' + @TailNum          + '%')
                AND (@SerialNum         IS NULL OR AR.SerialNum        LIKE '%' + @SerialNum        + '%')
                AND (@AircraftStatus    IS NULL OR AR.AircraftStatus   LIKE '%' + @AircraftStatus   + '%')
                AND (@IsActive          IS NULL OR AR.IsActive         = @IsActive)
                AND (@ManufacturedDate  IS NULL OR CAST(AR.ManufacturedDate  AS DATE) = CAST(@ManufacturedDate  AS DATE))
                AND (@PlaceInServiceDate IS NULL OR CAST(AR.PlaceInServiceDate AS DATE) = CAST(@PlaceInServiceDate AS DATE))
                AND (@NumOfEngines      IS NULL OR AR.NumOfEngines     LIKE '%' + @NumOfEngines     + '%')
                AND (@TotalTSN          IS NULL OR AR.TotalTSN         = @TotalTSN)
                AND (@TotalCSN          IS NULL OR AR.TotalCSN         = @TotalCSN)
                AND (@Hobbs             IS NULL OR AR.Hobbs            = @Hobbs)
                AND (@AircraftLocation  IS NULL OR AR.AircraftLocation LIKE '%' + @AircraftLocation + '%')
                AND (@NextScheduled     IS NULL OR CAST(AR.NextScheduled AS DATE) = CAST(@NextScheduled AS DATE))
                AND (@MEL               IS NULL OR AR.MEL              LIKE '%' + @MEL              + '%')
                AND (@AircraftStatusId  IS NULL OR AR.AircraftStatusId = @AircraftStatusId)
        )
        SELECT
            AircraftRegistryId,
            MakeType,
            AircraftModel,
            AircraftSubModel,
            NumOfEngines,
            TailNum,
            SerialNum,
            ManufacturedDate,
            PlaceInServiceDate,
            TotalTSN,
            TotalCSN,
            Hobbs,
            AircraftLocation,
            NextScheduled,
            MEL,
            AircraftStatus,
            IsActive,
            CreatedDate,
            TotalRecords
        FROM CTE
        ORDER BY
            CASE WHEN @SortColumn = 'MakeType'           AND @SortOrder = 'ASC'  THEN MakeType          END ASC,
            CASE WHEN @SortColumn = 'MakeType'           AND @SortOrder = 'DESC' THEN MakeType          END DESC,
            CASE WHEN @SortColumn = 'AircraftModel'      AND @SortOrder = 'ASC'  THEN AircraftModel     END ASC,
            CASE WHEN @SortColumn = 'AircraftModel'      AND @SortOrder = 'DESC' THEN AircraftModel     END DESC,
            CASE WHEN @SortColumn = 'AircraftSubModel'   AND @SortOrder = 'ASC'  THEN AircraftSubModel  END ASC,
            CASE WHEN @SortColumn = 'AircraftSubModel'   AND @SortOrder = 'DESC' THEN AircraftSubModel  END DESC,
            CASE WHEN @SortColumn = 'TailNum'            AND @SortOrder = 'ASC'  THEN TailNum           END ASC,
            CASE WHEN @SortColumn = 'TailNum'            AND @SortOrder = 'DESC' THEN TailNum           END DESC,
            CASE WHEN @SortColumn = 'SerialNum'          AND @SortOrder = 'ASC'  THEN SerialNum         END ASC,
            CASE WHEN @SortColumn = 'SerialNum'          AND @SortOrder = 'DESC' THEN SerialNum         END DESC,
            CASE WHEN @SortColumn = 'AircraftStatus'     AND @SortOrder = 'ASC'  THEN AircraftStatus    END ASC,
            CASE WHEN @SortColumn = 'AircraftStatus'     AND @SortOrder = 'DESC' THEN AircraftStatus    END DESC,
            CASE WHEN @SortColumn = 'ManufacturedDate'   AND @SortOrder = 'ASC'  THEN ManufacturedDate  END ASC,
            CASE WHEN @SortColumn = 'ManufacturedDate'   AND @SortOrder = 'DESC' THEN ManufacturedDate  END DESC,
            CASE WHEN @SortColumn = 'PlaceInServiceDate' AND @SortOrder = 'ASC'  THEN PlaceInServiceDate END ASC,
            CASE WHEN @SortColumn = 'PlaceInServiceDate' AND @SortOrder = 'DESC' THEN PlaceInServiceDate END DESC,
            CASE WHEN @SortColumn = 'TotalTSN'           AND @SortOrder = 'ASC'  THEN TotalTSN          END ASC,
            CASE WHEN @SortColumn = 'TotalTSN'           AND @SortOrder = 'DESC' THEN TotalTSN          END DESC,
            CASE WHEN @SortColumn = 'TotalCSN'           AND @SortOrder = 'ASC'  THEN TotalCSN          END ASC,
            CASE WHEN @SortColumn = 'TotalCSN'           AND @SortOrder = 'DESC' THEN TotalCSN          END DESC,
            CASE WHEN @SortColumn = 'Hobbs'              AND @SortOrder = 'ASC'  THEN Hobbs             END ASC,
            CASE WHEN @SortColumn = 'Hobbs'              AND @SortOrder = 'DESC' THEN Hobbs             END DESC,
            CASE WHEN @SortColumn = 'AircraftLocation'   AND @SortOrder = 'ASC'  THEN AircraftLocation  END ASC,
            CASE WHEN @SortColumn = 'AircraftLocation'   AND @SortOrder = 'DESC' THEN AircraftLocation  END DESC,
            CASE WHEN @SortColumn = 'NextScheduled'      AND @SortOrder = 'ASC'  THEN NextScheduled     END ASC,
            CASE WHEN @SortColumn = 'NextScheduled'      AND @SortOrder = 'DESC' THEN NextScheduled     END DESC,
            CASE WHEN @SortColumn = 'MEL'                AND @SortOrder = 'ASC'  THEN MEL               END ASC,
            CASE WHEN @SortColumn = 'MEL'                AND @SortOrder = 'DESC' THEN MEL               END DESC,
            CASE WHEN @SortColumn = 'NumOfEngines'       AND @SortOrder = 'ASC'  THEN NumOfEngines      END ASC,
            CASE WHEN @SortColumn = 'NumOfEngines'       AND @SortOrder = 'DESC' THEN NumOfEngines      END DESC,
            CASE WHEN @SortColumn = 'CreatedDate'        AND @SortOrder = 'ASC'  THEN CreatedDate       END ASC,
            CASE WHEN @SortColumn = 'CreatedDate'        AND @SortOrder = 'DESC' THEN CreatedDate       END DESC,
            AircraftRegistryId DESC
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
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftRegistryList',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = '    + ISNULL(CAST(@MasterCompanyId   AS VARCHAR(20)), 'NULL')
                + ', @IsDeleted = '      + ISNULL(CAST(@IsDeleted         AS VARCHAR(5)),  'NULL')
                + ', @AircraftStatusId = '+ ISNULL(CAST(@AircraftStatusId AS VARCHAR(20)), 'NULL')
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
