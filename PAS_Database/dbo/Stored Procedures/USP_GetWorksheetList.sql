/************************************************************
** File:        [USP_GetWorksheetList]
** Author:      
** Description: Get Worksheet list from WorksheetHeader and WorksheetPart
** 
** Change History
************************************************************
** PR   Date          Author           Description
** --   ----------    -------------    -------------------------
** 1    14/05/2026    Priyansh Patel   Created [PN-16408]
** 2    21/05/2026    Priyansh Patel    Worksheettype from setup screen [PN-16515]
** 3    21/05/2026    Priyansh Patel    Added MaintenanceTime minutes [PN-16509]
** 4    22/05/2026    Priyansh Patel    Fixed the employee and time filters [PN-16536]
** 5    26/05/2026    Priyansh Patel    Fixed the issue with time [PN-16588]
** 6    15/06/2026    Amit Ghediya		bind Wo Num, Ws Status [PN-16694]
** 7    27/07/2026    Amit Ghediya		Remove VW_WorkScopeType


************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorksheetList]
    @PageNumber                     INT             = 1,
    @PageSize                       INT             = 10,
    @SortColumn                     VARCHAR(100)    = 'WorksheetHeaderId',
    @SortOrder                      VARCHAR(4)      = 'DESC',
    @GlobalFilter                   VARCHAR(200)    = NULL,
    -- WorksheetHeader filters
    @WorksheetNumber                VARCHAR(50)     = NULL,
    @WorksheetType                  VARCHAR(50)     = NULL,
    @WorkOrderNo                    VARCHAR(50)     = NULL,
	@PNNum							VARCHAR(50)     = NULL,
    @MakeType                       VARCHAR(100)    = NULL,
    @AircraftModel                  VARCHAR(100)    = NULL,
    @AFHours                        VARCHAR(50)     = NULL,
    @InspectionType                 VARCHAR(100)    = NULL,
	@MaintenanceCategory            VARCHAR(100)    = NULL,
    @InspectionDate                 DATETIME        = NULL,
    @QualitySafetyDeptSignOutBy     VARCHAR(100)    = NULL,
    @QualitySafetyDeptSignOutDate   DATETIME        = NULL,
    @QualitySafetyDeptSignInBy      VARCHAR(100)    = NULL,
    @QualitySafetyDeptSignInDate    DATETIME        = NULL,
    @ReleaseToServiceBy             VARCHAR(100)    = NULL,
    @ReleaseDate                    DATETIME        = NULL,
    @CreatedBy                      VARCHAR(100)    = NULL,
    @CreatedDate                    DATETIME        = NULL,
    -- WorksheetPart filters
    @DefectDescription              VARCHAR(500)    = NULL,
    @MaintenanceAction              VARCHAR(500)    = NULL,
	@WSStatus                       VARCHAR(100)     = NULL,
    @MaintenanceTime                VARCHAR(20)     = NULL,
    @MechBy                         VARCHAR(100)    = NULL,
    @InspBy                         VARCHAR(100)    = NULL,
    -- Standard
    @IsDeleted                      BIT             = 0,
    @MasterCompanyId                INT,
	@IsShowPN                       BIT             = 0
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        WITH CTE AS
        (
            SELECT
                WH.WorksheetHeaderId,
                WH.WorksheetNumber,
                ACS.Section AS WorksheetType,
                CASE WHEN ISNULL(WH.AircraftInstalledPartDetailsId,0) > 0 THEN WO.WorkOrderNum ELSE LWO.WorkOrderNum END AS WorkOrderNo,
				CASE WHEN ISNULL(WH.AircraftInstalledPartDetailsId,0) > 0 THEN WO.WorkOrderId ELSE LWO.WorkOrderId END AS WorkOrderId,
				CASE WHEN ISNULL(@IsShowPN,0) = 0 THEN '' ELSE AIPD.[PartNumber] END AS PNNum,
                WH.MakeTypeId,
                WH.MakeType,
                WH.AircraftModelId,
                WH.AircraftModel,
                WH.AFHours,
				WH.InspectionType,
				MC.MtcCategory AS MaintenanceCategory,
                WH.InspectionDate,
                WH.QualitySafetyDeptSignOutBy,
                WH.QualitySafetyDeptSignOutDate,
                WH.QualitySafetyDeptSignInBy,
                WH.QualitySafetyDeptSignInDate,
                WH.ReleaseToServiceBy,
                WH.ReleaseDate,
                WH.CreatedBy,
                WH.CreatedDate,
                WP.WorksheetPartId,
                WP.ItemNo,
                WP.SignedBy,
                WP.DefectDescription,
                WP.MaintenanceAction,
				CASE
					WHEN ISNULL(WH.AircraftInstalledPartDetailsId, 0) = 0
						 AND LWO.WorkOrderId IS NULL
					THEN 'Open'
					WHEN ISNULL(
							CASE
								WHEN ISNULL(WH.AircraftInstalledPartDetailsId, 0) > 0
								THEN WOP.WorkOrderStatusId      
								ELSE LWO.WorkOrderStatusId     
							END, 0) = 2
					THEN 'Closed'
					ELSE 'In Process'
				END AS WSStatus,
                CASE 
                    WHEN ISNULL(WP.MaintenanceTime, 0) = 0 AND ISNULL(WP.MaintenanceTimeMinutes, 0) = 0 
                    THEN NULL
                ELSE  CAST(ISNULL(WP.MaintenanceTime, 0) AS VARCHAR(10)) + ' : ' + 
                RIGHT('00' + CAST(ISNULL(WP.MaintenanceTimeMinutes, 0) AS VARCHAR(2)), 2) END AS MaintenanceTime,
                ISNULL(em.FirstName,'') + CASE WHEN ISNULL(em.LastName,'') <> '' THEN ' ' + em.LastName ELSE '' END AS MechBy,
                ISNULL(ei.FirstName,'') + CASE WHEN ISNULL(ei.LastName,'') <> '' THEN ' ' + ei.LastName ELSE '' END AS InspBy,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[WorksheetHeader] WH WITH (NOLOCK)
            LEFT JOIN [dbo].[WorksheetPart] WP WITH (NOLOCK) ON WP.WorksheetHeaderId = WH.WorksheetHeaderId AND WP.IsDeleted = 0
            LEFT JOIN [dbo].[AircraftSection] ACS WITH (NOLOCK) ON WH.WorksheetTypeId = ACS.AircraftSectionId AND ACS.IsDeleted = 0
            --LEFT JOIN [dbo].[MaintenanceType] MT WITH (NOLOCK) ON MT.MaintenanceTypeId = WH.InspectionType AND MT.IsDeleted = 0
			LEFT JOIN [dbo].[MaintenanceCategory] MC WITH (NOLOCK) ON MC.MtcCategoryId = WH.MtcCategoryId AND MC.IsDeleted = 0
            LEFT JOIN [dbo].[Employee] em WITH(NOLOCK) ON em.EmployeeId = wp.MechBy AND em.MasterCompanyId = @MasterCompanyId
            LEFT JOIN [dbo].[Employee] ei WITH(NOLOCK) ON ei.EmployeeId = wp.InspBy AND ei.MasterCompanyId = @MasterCompanyId
			LEFT JOIN [dbo].[AircraftInstalledPartDetails] AIPD WITH(NOLOCK) ON AIPD.AircraftInstalledPartDetailsId = WH.AircraftInstalledPartDetailsId
			OUTER APPLY (SELECT TOP 1 WOP_inner.WorkOrderId,WOP_inner.ID AS WOPartNumberId,WOP_inner.WorkOrderStatusId
				FROM dbo.WorkOrderPartNumber WOP_inner WITH (NOLOCK)
				WHERE WOP_inner.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
				ORDER BY WOP_inner.ID DESC 
			) AS WOP
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
			LEFT JOIN [dbo].[AircraftMaintenanceProgram] AMP WITH(NOLOCK) ON AMP.[ProgramId] = WH.[ProgramId]
			LEFT JOIN (
                    SELECT WOP.[ProgramId], WO.[WorkOrderId], WO.[WorkOrderNum],WOP.WorkOrderStatusId,
                           ROW_NUMBER() OVER (PARTITION BY WOP.[ProgramId] ORDER BY WO.[WorkOrderId] DESC) AS rn
                    FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
                    JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.[WorkOrderId] = WO.[WorkOrderId]
                ) LWO ON LWO.[ProgramId] = AMP.[ProgramId] AND LWO.rn = 1

            WHERE
                WH.MasterCompanyId = @MasterCompanyId
                AND (@IsDeleted IS NULL OR WH.IsDeleted = @IsDeleted)
                -- Global filter
                AND (
                    @GlobalFilter IS NULL
                    OR WH.WorksheetNumber   LIKE '%' + @GlobalFilter + '%'
                    OR ACS.Section     LIKE '%' + @GlobalFilter + '%'
                    OR CASE WHEN ISNULL(WH.AircraftInstalledPartDetailsId,0) > 0 THEN WO.WorkOrderNum ELSE LWO.WorkOrderNum END       LIKE '%' + @GlobalFilter + '%'
					OR CASE WHEN ISNULL(@IsShowPN,0) = 0 THEN '' ELSE AIPD.[PartNumber] END	LIKE '%' + @GlobalFilter + '%'
                    OR WH.MakeType          LIKE '%' + @GlobalFilter + '%'
                    OR WH.AircraftModel     LIKE '%' + @GlobalFilter + '%'
                    OR WH.InspectionType    LIKE '%' + @GlobalFilter + '%'
					OR MC.MtcCategory		LIKE '%' + @GlobalFilter + '%'
                    OR WP.DefectDescription LIKE '%' + @GlobalFilter + '%'
                    OR WP.MaintenanceAction LIKE '%' + @GlobalFilter + '%'
                    OR ISNULL(em.FirstName,'') + CASE WHEN ISNULL(em.LastName,'') <> '' THEN ' ' + em.LastName ELSE '' END LIKE '%' + @GlobalFilter + '%'
                    OR ISNULL(ei.FirstName,'') + CASE WHEN ISNULL(ei.LastName,'') <> '' THEN ' ' + ei.LastName ELSE '' END LIKE '%' + @GlobalFilter + '%'
                )

                -- Row-level column filters
                AND (@WorksheetNumber            IS NULL OR WH.WorksheetNumber           LIKE '%' + @WorksheetNumber           + '%')
                AND (@WorksheetType              IS NULL OR ACS.Section             LIKE '%' + @WorksheetType             + '%')
                AND (@WorkOrderNo                IS NULL OR CASE WHEN ISNULL(WH.AircraftInstalledPartDetailsId,0) > 0 THEN WO.WorkOrderNum ELSE LWO.WorkOrderNum END               LIKE '%' + @WorkOrderNo               + '%')
				AND (@PNNum						 IS NULL OR CASE WHEN ISNULL(@IsShowPN,0) = 0 THEN '' ELSE AIPD.[PartNumber] END               LIKE '%' + @PNNum               + '%')
                AND (@MakeType                   IS NULL OR WH.MakeType                  LIKE '%' + @MakeType                  + '%')
                AND (@AircraftModel              IS NULL OR WH.AircraftModel             LIKE '%' + @AircraftModel             + '%')
                AND (@AFHours                    IS NULL OR WH.AFHours                   LIKE '%' + @AFHours                   + '%')
                AND (@InspectionType             IS NULL OR WH.InspectionType            LIKE '%' + @InspectionType            + '%')
				AND (@MaintenanceCategory        IS NULL OR MC.MtcCategory            LIKE '%' + @MaintenanceCategory            + '%')
                AND (@InspectionDate             IS NULL OR CAST(WH.InspectionDate             AS DATE) = CAST(@InspectionDate             AS DATE))
                AND (@QualitySafetyDeptSignOutBy IS NULL OR WH.QualitySafetyDeptSignOutBy LIKE '%' + @QualitySafetyDeptSignOutBy + '%')
                AND (@QualitySafetyDeptSignOutDate IS NULL OR CAST(WH.QualitySafetyDeptSignOutDate AS DATE) = CAST(@QualitySafetyDeptSignOutDate AS DATE))
                AND (@QualitySafetyDeptSignInBy  IS NULL OR WH.QualitySafetyDeptSignInBy  LIKE '%' + @QualitySafetyDeptSignInBy  + '%')
                AND (@QualitySafetyDeptSignInDate IS NULL OR CAST(WH.QualitySafetyDeptSignInDate  AS DATE) = CAST(@QualitySafetyDeptSignInDate  AS DATE))
                AND (@ReleaseToServiceBy         IS NULL OR WH.ReleaseToServiceBy        LIKE '%' + @ReleaseToServiceBy        + '%')
                AND (@ReleaseDate                IS NULL OR CAST(WH.ReleaseDate                AS DATE) = CAST(@ReleaseDate                AS DATE))
                AND (@CreatedBy                  IS NULL OR WH.CreatedBy                 = TRY_CAST(@CreatedBy AS BIGINT))
                AND (@CreatedDate                IS NULL OR CAST(WH.CreatedDate                AS DATE) = CAST(@CreatedDate                AS DATE))
                AND (@DefectDescription          IS NULL OR WP.DefectDescription         LIKE '%' + @DefectDescription         + '%')
                AND (@MaintenanceAction          IS NULL OR WP.MaintenanceAction         LIKE '%' + @MaintenanceAction         + '%')
                AND (@MaintenanceTime IS NULL OR CAST(ISNULL(WP.MaintenanceTime, 0) AS VARCHAR(10)) + ' : ' + 
                RIGHT('00' + CAST(ISNULL(WP.MaintenanceTimeMinutes, 0) AS VARCHAR(2)), 2) LIKE '%' + @MaintenanceTime + '%')
                AND (@MechBy IS NULL OR ISNULL(em.FirstName,'') + CASE WHEN ISNULL(em.LastName,'') <> '' THEN ' ' + em.LastName ELSE '' END  LIKE '%' + @MechBy + '%')
                AND ( @InspBy IS NULL OR ISNULL(ei.FirstName,'') + CASE WHEN ISNULL(ei.LastName,'') <> '' THEN ' ' + ei.LastName ELSE '' END LIKE '%' + @InspBy + '%')
        )
        SELECT
            WorksheetHeaderId,
            WorksheetNumber,
            WorksheetType,
            WorkOrderNo,
			WorkOrderId,
			PNNum,
            MakeTypeId,
            MakeType,
            AircraftModelId,
            AircraftModel,
            AFHours,
            InspectionType,
			MaintenanceCategory,
            InspectionDate,
            QualitySafetyDeptSignOutBy,
            QualitySafetyDeptSignOutDate,
            QualitySafetyDeptSignInBy,
            QualitySafetyDeptSignInDate,
            ReleaseToServiceBy,
            ReleaseDate,
            CreatedBy,
            CreatedDate,
            WorksheetPartId,
            ItemNo,
            SignedBy,
            DefectDescription,
            MaintenanceAction,
			WSStatus,
            MaintenanceTime,
            MechBy,
            InspBy,
            TotalRecords
        FROM CTE
		WHERE (
			@WSStatus IS NULL
			OR REPLACE(LOWER(WSStatus), ' ', '') LIKE '%' + REPLACE(LOWER(@WSStatus), ' ', '') + '%'
		)
        ORDER BY
            CASE WHEN @SortColumn = 'WorksheetNumber'              AND @SortOrder = 'ASC'  THEN WorksheetNumber              END ASC,
            CASE WHEN @SortColumn = 'WorksheetNumber'              AND @SortOrder = 'DESC' THEN WorksheetNumber              END DESC,
            CASE WHEN @SortColumn = 'WorksheetType'                AND @SortOrder = 'ASC'  THEN WorksheetType                END ASC,
            CASE WHEN @SortColumn = 'WorksheetType'                AND @SortOrder = 'DESC' THEN WorksheetType                END DESC,
            CASE WHEN @SortColumn = 'WorkOrderNo'                  AND @SortOrder = 'ASC'  THEN WorkOrderNo                  END ASC,
            CASE WHEN @SortColumn = 'WorkOrderNo'                  AND @SortOrder = 'DESC' THEN WorkOrderNo                  END DESC,
			CASE WHEN @SortColumn = 'PNNum'						   AND @SortOrder = 'ASC'  THEN PNNum                        END ASC,
            CASE WHEN @SortColumn = 'PNNum'                        AND @SortOrder = 'DESC' THEN PNNum                        END DESC,
            CASE WHEN @SortColumn = 'MakeType'                     AND @SortOrder = 'ASC'  THEN MakeType                     END ASC,
            CASE WHEN @SortColumn = 'MakeType'                     AND @SortOrder = 'DESC' THEN MakeType                     END DESC,
            CASE WHEN @SortColumn = 'AircraftModel'                AND @SortOrder = 'ASC'  THEN AircraftModel                END ASC,
            CASE WHEN @SortColumn = 'AircraftModel'                AND @SortOrder = 'DESC' THEN AircraftModel                END DESC,
            CASE WHEN @SortColumn = 'AFHours'                      AND @SortOrder = 'ASC'  THEN AFHours                      END ASC,
            CASE WHEN @SortColumn = 'AFHours'                      AND @SortOrder = 'DESC' THEN AFHours                      END DESC,
            CASE WHEN @SortColumn = 'InspectionType'               AND @SortOrder = 'ASC'  THEN InspectionType               END ASC,
            CASE WHEN @SortColumn = 'InspectionType'               AND @SortOrder = 'DESC' THEN InspectionType               END DESC,
			CASE WHEN @SortColumn = 'MaintenanceCategory'          AND @SortOrder = 'ASC'  THEN MaintenanceCategory          END ASC,
            CASE WHEN @SortColumn = 'MaintenanceCategory'          AND @SortOrder = 'DESC' THEN MaintenanceCategory          END DESC,
            CASE WHEN @SortColumn = 'InspectionDate'               AND @SortOrder = 'ASC'  THEN InspectionDate               END ASC,
            CASE WHEN @SortColumn = 'InspectionDate'               AND @SortOrder = 'DESC' THEN InspectionDate               END DESC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignOutBy'   AND @SortOrder = 'ASC'  THEN QualitySafetyDeptSignOutBy   END ASC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignOutBy'   AND @SortOrder = 'DESC' THEN QualitySafetyDeptSignOutBy   END DESC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignOutDate' AND @SortOrder = 'ASC'  THEN QualitySafetyDeptSignOutDate END ASC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignOutDate' AND @SortOrder = 'DESC' THEN QualitySafetyDeptSignOutDate END DESC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignInBy'    AND @SortOrder = 'ASC'  THEN QualitySafetyDeptSignInBy    END ASC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignInBy'    AND @SortOrder = 'DESC' THEN QualitySafetyDeptSignInBy    END DESC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignInDate'  AND @SortOrder = 'ASC'  THEN QualitySafetyDeptSignInDate  END ASC,
            CASE WHEN @SortColumn = 'QualitySafetyDeptSignInDate'  AND @SortOrder = 'DESC' THEN QualitySafetyDeptSignInDate  END DESC,
            CASE WHEN @SortColumn = 'ReleaseToServiceBy'           AND @SortOrder = 'ASC'  THEN ReleaseToServiceBy           END ASC,
            CASE WHEN @SortColumn = 'ReleaseToServiceBy'           AND @SortOrder = 'DESC' THEN ReleaseToServiceBy           END DESC,
            CASE WHEN @SortColumn = 'ReleaseDate'                  AND @SortOrder = 'ASC'  THEN ReleaseDate                  END ASC,
            CASE WHEN @SortColumn = 'ReleaseDate'                  AND @SortOrder = 'DESC' THEN ReleaseDate                  END DESC,
            CASE WHEN @SortColumn = 'DefectDescription'            AND @SortOrder = 'ASC'  THEN DefectDescription            END ASC,
            CASE WHEN @SortColumn = 'DefectDescription'            AND @SortOrder = 'DESC' THEN DefectDescription            END DESC,
            CASE WHEN @SortColumn = 'MaintenanceAction'            AND @SortOrder = 'ASC'  THEN MaintenanceAction            END ASC,
            CASE WHEN @SortColumn = 'MaintenanceAction'            AND @SortOrder = 'DESC' THEN MaintenanceAction            END DESC,
			 CASE WHEN @SortColumn = 'WSStatus'            AND @SortOrder = 'ASC'  THEN WSStatus            END ASC,
            CASE WHEN @SortColumn = 'WSStatus'            AND @SortOrder = 'DESC' THEN WSStatus            END DESC,
            CASE WHEN @SortColumn = 'MaintenanceTime'              AND @SortOrder = 'ASC'  THEN MaintenanceTime                         END ASC,
            CASE WHEN @SortColumn = 'MaintenanceTime'              AND @SortOrder = 'DESC' THEN MaintenanceTime                         END DESC,
            CASE WHEN @SortColumn = 'MechBy'                       AND @SortOrder = 'ASC'  THEN MechBy                       END ASC,
            CASE WHEN @SortColumn = 'MechBy'                       AND @SortOrder = 'DESC' THEN MechBy                       END DESC,
            CASE WHEN @SortColumn = 'InspBy'                       AND @SortOrder = 'ASC'  THEN InspBy                       END ASC,
            CASE WHEN @SortColumn = 'InspBy'                       AND @SortOrder = 'DESC' THEN InspBy                       END DESC,
            CASE WHEN @SortColumn = 'CreatedBy'                    AND @SortOrder = 'ASC'  THEN CreatedBy                    END ASC,
            CASE WHEN @SortColumn = 'CreatedBy'                    AND @SortOrder = 'DESC' THEN CreatedBy                    END DESC,
            CASE WHEN @SortColumn = 'CreatedDate'                  AND @SortOrder = 'ASC'  THEN CreatedDate                  END ASC,
            CASE WHEN @SortColumn = 'CreatedDate'                  AND @SortOrder = 'DESC' THEN CreatedDate                  END DESC,
            WorksheetHeaderId DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetWorksheetList',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = '     + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL')
                + ', @GlobalFilter = '    + ISNULL(@GlobalFilter,    'NULL')
                + ', @WorksheetNumber = ' + ISNULL(@WorksheetNumber, 'NULL')
                + ', @WorksheetType = '   + ISNULL(@WorksheetType,   'NULL')
                + ', @WorkOrderNo = '     + ISNULL(@WorkOrderNo,     'NULL'),
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