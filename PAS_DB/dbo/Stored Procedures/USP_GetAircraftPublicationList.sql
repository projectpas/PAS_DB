/************************************************************
** File:        [USP_GetAircraftPublicationList]
** Author:      Amit Ghediya
** Description: Get Aircraft Registry data from Aircraft Publication List Data
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
**  1    01/05/2026  Amit Ghediya		Created
**  2    27/05/2026  Code Review		Fix VerifiedBy name space; add IsActive filter; remove unused pemp JOIN
**  3    07/07/2026  Code Review		GET ComplianceDate,Ractification [PN-17153]
**  2    08/07/2026  Amit Ghediya		Get Applicability,MEL [PN-17157]
**  4    10/07/2026  Amit Ghediya		RactificationDate (date) renamed to Ractification (free text)
**  5    10/07/2026  Amit Ghediya		WO,Ws Filter [PN-17160]
**  6    16/07/2026  Amit Ghediya       Show MakeType, AircraftRegistryNumber, SerialNum of the
**                                      matched aircraft (via AircraftMaintenanceProgram -> registry)
**  7    16/07/2026  Amit Ghediya       Worksheet/WorkOrder/WorksheetStatus OUTER APPLYs now also
**                                      scope by AMP.AircraftRegistryId = AR.AircraftRegistryId --
**                                      previously they only filtered by AircraftPublicationId, so
**                                      when a publication matched multiple aircraft, every matched
**                                      aircraft's row showed the SAME globally-latest WS/WO across
**                                      all of them instead of its own (e.g. a worksheet created only
**                                      for AR-000037 was showing up against other aircraft too).
************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetAircraftPublicationList]
    @PageNumber         INT             = 1,
    @PageSize           INT             = 10,
    @SortColumn         VARCHAR(100)    = 'AircraftPublicationId',
    @SortOrder          VARCHAR(4)      = 'DESC',
    @GlobalFilter       VARCHAR(100)    = NULL,

    @AircraftPublicationNumber     VARCHAR(100)    = NULL,
    @PublicationType      VARCHAR(100)    = NULL,
    @PubNum   VARCHAR(100)    = NULL,
    @RevisionNum            VARCHAR(50)     = NULL,
    @AircraftSection          VARCHAR(100)    = NULL,

    @Subject     VARCHAR(100)    = NULL,
	@PublishedBy     VARCHAR(100)    = NULL,
	@ComplianceCategory     VARCHAR(100)    = NULL,
	@Timeframe     VARCHAR(100)    = NULL,
	@PurposeReasonBackground     VARCHAR(100)    = NULL,

	@EntryDate   DATETIME        = NULL,
	@VerifiedBy     VARCHAR(100)    = NULL,
	@PubDate   DATETIME        = NULL,
	@CreatedDate   DATETIME        = NULL,
	@CreatedBy     VARCHAR(100)    = NULL,

	@UpdatedDate   DATETIME        = NULL,
	@UpdatedBy     VARCHAR(100)    = NULL,
    @IsActive           BIT             = NULL,
	@MasterCompanyId    INT,
	@IsDeleted          BIT             = 0,

	@FromPubDate   DATETIME        = NULL,
	@ToPubDate   DATETIME        = NULL,
	@ComplianceDate		  DATETIME     = NULL,
	@Ractification        VARCHAR(MAX) = NULL,
	@Applicability    VARCHAR(50)  = NULL,
	@MEL			  VARCHAR(50)  = NULL,

	@WorksheetNumber      VARCHAR(100) = NULL,
	@WorksheetDate       DATETIME     = NULL,
	@WorkSheetStatus      VARCHAR(100) = NULL,

	@WorkOrderNo         VARCHAR(100) = NULL,
	@OpenDate             DATETIME     = NULL,
	@WorkOrderStatus      VARCHAR(100) = NULL,

	@MakeType               VARCHAR(100) = NULL,
	@AircraftRegistryNumber VARCHAR(100) = NULL,
	@SerialNum              VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

		DECLARE @ManufactureTypeId int;
		DECLARE @VendorTypeId int;

		SET @VendorTypeId = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) WHERE ModuleName = 'Vendor');
		SET @ManufactureTypeId = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) WHERE ModuleName = 'Manufacturer');

        WITH CTE AS
        (
            SELECT
                AP.AircraftPublicationId,
                AP.AircraftPublicationNumber,
                PT.[Name] AS  PublicationType,
                AP.PubNum,
                AP.RevisionNum,
                ASE.Section AS AircraftSection,
                AP.[Subject] AS Subject,
				CASE WHEN AP.PublishedById = @ManufactureTypeId THEN ISNULL(M.[Name],'') WHEN AP.PublishedById = @VendorTypeId THEN ISNULL(V.VendorName,'') ELSE ISNULL(AP.PublishedByOthers,'') END  AS PublishedBy,
                AP.ComplianceCategory,
                AP.Timeframe,
                AP.PurposeReasonBackground,
                AP.EntryDate,
                EMP.FirstName + ' ' + EMP.LastName AS VerifiedBy,
				AP.PubDate,
				AP.CreatedDate,
				AP.CreatedBy,
				AP.UpdatedDate,
				AP.UpdatedBy,
                AP.IsActive,
                AP.IsDeleted,
				AP.MasterCompanyId,
				AP.ComplianceDate,
				AP.Ractification,
				AP.Applicability,
				AP.MEL,
				AR.AircraftRegistryId     AS AircraftRegistryId,
				AR.MakeType               AS MakeType,
				AR.AircraftRegistryNumber AS AircraftRegistryNumber,
				AR.SerialNum              AS SerialNum,
				WS.WorksheetNumber AS WorkSheetNumber,
                WS.WorksheetHeaderId AS WorkSheetId,
                WS.CreatedDate       AS WorkSheetDate,
                WSS.WorkSheetStatus  AS WorkSheetStatus,
                WOX.WorkOrderNum     AS WorkOrderNo,
                WOX.WorkOrderId,
                WOX.OpenDate,
                WOX.WorkOrderStatus,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[AircraftPublication] AS AP WITH (NOLOCK)
			LEFT JOIN dbo.PublicationType PT WITH (NOLOCK) ON AP.PublicationTypeId = PT.PublicationTypeId
			LEFT JOIN dbo.AircraftSection ASE WITH (NOLOCK) ON AP.AircraftSectionId = ASE.AircraftSectionId
			LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = AP.VerifiedBy
			LEFT JOIN [dbo].[Manufacturer] M with (NOLOCK) ON AP.PublishedByRefId = M.ManufacturerId
			LEFT JOIN [dbo].[Vendor] V with (NOLOCK) ON AP.PublishedByRefId = V.VendorId
			-- Matched aircraft (via AircraftMaintenanceProgram -> AircraftRegistryHeader) for this publication.
			-- One row PER matched aircraft (publication columns repeat). DISTINCT dedupes when an
			-- aircraft has more than one program row for the same publication. LEFT JOIN so a
			-- publication with no created maintenance still returns a single row (aircraft cols NULL).
			LEFT JOIN (
				SELECT DISTINCT
					   AMP.AircraftPublicationId,
					   AMP.AircraftRegistryId,
					   ARH.MakeType,
					   ARH.AircraftRegistryNumber,
					   ARH.SerialNum
				FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
				INNER JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK)
					   ON ARH.AircraftRegistryId = AMP.AircraftRegistryId
				WHERE ISNULL(AMP.IsDeleted, 0) = 0
			) AR ON AR.AircraftPublicationId = AP.AircraftPublicationId
			-- Aggregate flag
            OUTER APPLY (
                SELECT MAX(CAST(ISNULL(AMP.IsMtceRecordUpdated, 0) AS INT)) AS IsMtceRecordUpdated
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                WHERE AMP.AircraftPublicationId = AP.AircraftPublicationId
                  AND AMP.AircraftRegistryId    = AR.AircraftRegistryId
            ) MR
            -- Latest worksheet -- scoped to THIS row's matched aircraft, not just the publication,
            -- so each matched-aircraft row shows its own worksheet instead of whichever aircraft's
            -- worksheet happens to sort first across the whole publication.
            OUTER APPLY (
                SELECT TOP (1)
                       WSH.WorksheetNumber, WSH.WorksheetHeaderId, WSH.CreatedDate, WSH.CreatedBy
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                LEFT JOIN dbo.WorksheetHeader WSH WITH (NOLOCK)
                       ON WSH.ProgramId = AMP.ProgramId
                WHERE AMP.AircraftPublicationId = AP.AircraftPublicationId
                  AND AMP.AircraftRegistryId    = AR.AircraftRegistryId
                ORDER BY WSH.CreatedDate DESC, WSH.WorksheetHeaderId DESC
            ) WS
            -- Latest work order -- same per-aircraft scoping as above
            OUTER APPLY (
                SELECT TOP (1)
                       WO.WorkOrderNum, WO.WorkOrderId, WO.OpenDate, WOPN.WorkOrderStatus
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK)
                       ON WOPN.ProgramId = AMP.ProgramId
                LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK)
                       ON WO.WorkOrderId = WOPN.WorkOrderId
                WHERE AMP.AircraftPublicationId = AP.AircraftPublicationId
                  AND AMP.AircraftRegistryId    = AR.AircraftRegistryId
                ORDER BY WO.WorkOrderId DESC
            ) WOX
            -- Worksheet status -- same per-aircraft scoping as above
            OUTER APPLY (
                SELECT TOP (1)
                    CASE
                        WHEN AMP.ProgramId IS NULL OR WSH.WorksheetHeaderId IS NULL THEN NULL
                        WHEN WSH.WorksheetHeaderId IS NULL THEN 'Open'
                        WHEN WOP2.WorkOrderId IS NULL THEN 'Open'
                        WHEN ISNULL(WO2.WorkOrderStatusId, 0) = 2 THEN 'Closed'
                        WHEN UPPER(ISNULL(WOP2.WorkOrderStatus, '')) = 'CLOSED' THEN 'Closed'
                        WHEN ISNULL(
                                CASE WHEN ISNULL(WSH.AircraftInstalledPartDetailsId, 0) > 0
                                     THEN WOP2.WorkOrderStatusId ELSE WO2.WorkOrderStatusId END, 0) = 2
                             THEN 'Closed'
                        ELSE 'In Process'
                    END AS WorkSheetStatus
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                LEFT JOIN dbo.WorksheetHeader WSH WITH (NOLOCK)
                       ON WSH.ProgramId = AMP.ProgramId
                LEFT JOIN dbo.WorkOrderPartNumber WOP2 WITH (NOLOCK)
                       ON WOP2.ProgramId = AMP.ProgramId
                LEFT JOIN dbo.WorkOrder WO2 WITH (NOLOCK)
                       ON WO2.WorkOrderId = WOP2.WorkOrderId
                WHERE AMP.AircraftPublicationId = AP.AircraftPublicationId
                  AND AMP.AircraftRegistryId    = AR.AircraftRegistryId
                ORDER BY WSH.WorksheetHeaderId DESC, WOP2.WorkOrderId DESC
            ) WSS
            WHERE
                AP.MasterCompanyId = @MasterCompanyId
                AND (@IsDeleted IS NULL OR AP.IsDeleted = @IsDeleted)
				AND (@IsActive IS NULL OR AP.IsActive = @IsActive)
				AND ((@FromPubDate IS NULL AND @ToPubDate IS NULL)
						OR CAST(AP.PubDate AS DATE) BETWEEN
						CAST(@FromPubDate AS DATE)
						AND CAST(@ToPubDate AS DATE)
					)
                AND (
					NULLIF(@GlobalFilter, '') IS NULL
					OR AP.AircraftPublicationNumber LIKE '%' + @GlobalFilter + '%'
					OR PT.Name LIKE '%' + @GlobalFilter + '%'
					OR AP.PubNum LIKE '%' + @GlobalFilter + '%'
					OR AP.RevisionNum LIKE '%' + @GlobalFilter + '%'
					OR ASE.Section LIKE '%' + @GlobalFilter + '%'
					OR AP.Subject LIKE '%' + @GlobalFilter + '%'
					OR AP.ComplianceCategory LIKE '%' + @GlobalFilter + '%'
					OR AP.Timeframe LIKE '%' + @GlobalFilter + '%'
					OR AP.PurposeReasonBackground LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(AR.MakeType, '')               LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(AR.AircraftRegistryNumber, '') LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(AR.SerialNum, '')              LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(WS.WorksheetNumber, '')       LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(WOX.WorkOrderNum, '')       LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(WOX.WorkOrderStatus, '')    LIKE '%' + @GlobalFilter + '%'
					OR ISNULL(WSS.WorkSheetStatus, '')    LIKE '%' + @GlobalFilter + '%'
                )
				AND (NULLIF(@AircraftPublicationNumber, '') IS NULL OR AP.AircraftPublicationNumber LIKE '%' + @AircraftPublicationNumber + '%')
				AND (NULLIF(@PublicationType, '') IS NULL OR PT.[Name] LIKE '%' + @PublicationType + '%')
				AND (NULLIF(@PubNum, '') IS NULL OR AP.PubNum LIKE '%' + @PubNum + '%')
				AND (NULLIF(@RevisionNum, '') IS NULL OR AP.RevisionNum LIKE '%' + @RevisionNum + '%')
				AND (NULLIF(@AircraftSection, '') IS NULL OR ASE.Section LIKE '%' + @AircraftSection + '%')
				AND (NULLIF(@Subject, '') IS NULL OR AP.[Subject] LIKE '%' + @Subject + '%')
				AND (NULLIF(@PublishedBy, '') IS NULL OR CASE WHEN AP.PublishedById = @ManufactureTypeId THEN ISNULL(M.[Name],'') WHEN AP.PublishedById = @VendorTypeId THEN ISNULL(V.VendorName,'') ELSE ISNULL(AP.PublishedByOthers,'') END LIKE '%' + @PublishedBy + '%')
				AND (NULLIF(@ComplianceCategory, '') IS NULL OR AP.ComplianceCategory LIKE '%' + @ComplianceCategory + '%')
				AND (NULLIF(@Timeframe, '') IS NULL OR AP.Timeframe LIKE '%' + @Timeframe + '%')
				AND (NULLIF(@PurposeReasonBackground, '') IS NULL OR AP.PurposeReasonBackground LIKE '%' + @PurposeReasonBackground + '%')
				AND (@EntryDate IS NULL OR CAST(AP.EntryDate AS DATE) = CAST(@EntryDate AS DATE))
				AND (NULLIF(@VerifiedBy, '') IS NULL OR CAST(EMP.FirstName + ' ' + EMP.LastName AS VARCHAR) LIKE '%' + @VerifiedBy + '%')
				AND (@PubDate IS NULL OR CAST(AP.PubDate AS DATE) = CAST(@PubDate AS DATE))
				AND (@CreatedDate IS NULL OR CAST(AP.CreatedDate AS DATE) = CAST(@CreatedDate AS DATE))
				AND (NULLIF(@CreatedBy, '') IS NULL OR AP.CreatedBy LIKE '%' + @CreatedBy + '%')
				AND (@UpdatedDate IS NULL OR CAST(AP.UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE))
				AND (NULLIF(@UpdatedBy, '') IS NULL OR AP.UpdatedBy LIKE '%' + @UpdatedBy + '%')
				AND (@ComplianceDate       IS NULL OR CAST(AP.ComplianceDate       AS DATE) = CAST(@ComplianceDate AS DATE))
				AND (NULLIF(@Ractification, '') IS NULL OR AP.Ractification LIKE '%' + @Ractification + '%')
				AND (ISNULL(@Applicability, '') = '' OR (CASE WHEN ISNULL(AP.[Applicability], 0) = 1 THEN 'YES' ELSE 'NO' END) LIKE '%' + @Applicability + '%')
				AND (ISNULL(@MEL, '') = '' OR (CASE WHEN ISNULL(AP.[MEL], 0) = 1 THEN 'YES' ELSE 'NO' END) LIKE '%' + @MEL + '%')

				AND (NULLIF(@MakeType, '')               IS NULL OR ISNULL(AR.MakeType, '')               LIKE '%' + @MakeType + '%')
				AND (NULLIF(@AircraftRegistryNumber, '') IS NULL OR ISNULL(AR.AircraftRegistryNumber, '') LIKE '%' + @AircraftRegistryNumber + '%')
				AND (NULLIF(@SerialNum, '')              IS NULL OR ISNULL(AR.SerialNum, '')              LIKE '%' + @SerialNum + '%')

				AND (NULLIF(@WorksheetNumber, '')   IS NULL OR ISNULL(WS.WorksheetNumber, '')        LIKE '%' + @WorksheetNumber + '%')
				AND (@WorksheetDate IS NULL OR CAST(WS.CreatedDate AS DATE) = CAST(@WorksheetDate AS DATE))
				AND (NULLIF(@WorkSheetStatus, '')     IS NULL OR ISNULL(WSS.WorkSheetStatus, '')     LIKE '%' + @WorkSheetStatus + '%')

				AND (NULLIF(@WorkOrderNo, '')   IS NULL OR ISNULL(WOX.WorkOrderNum, '')        LIKE '%' + @WorkOrderNo + '%')
				AND (@OpenDate IS NULL OR CAST(WOX.OpenDate AS DATE) = CAST(@OpenDate AS DATE))
				AND (NULLIF(@WorkOrderStatus, '')     IS NULL OR ISNULL(WOX.WorkOrderStatus, '')     LIKE '%' + @WorkOrderStatus + '%')
        )
        SELECT
            AircraftPublicationId,
            AircraftPublicationNumber,
            PublicationType,
            PubNum,
            RevisionNum,
            AircraftSection,
            [Subject],
            PublishedBy,
            ComplianceCategory,
            Timeframe,
            PurposeReasonBackground,
            EntryDate,
            VerifiedBy,
			PubDate,
			CreatedDate,
			CreatedBy,
			UpdatedDate,
			UpdatedBy,
            IsActive,
            IsDeleted,
			MasterCompanyId,
			ComplianceDate,
			Ractification,
			Applicability,
			MEL,
			AircraftRegistryId,
			MakeType,
			AircraftRegistryNumber,
			SerialNum,
			WorksheetNumber,
            WorkSheetId,
            WorkSheetDate,
            WorkSheetStatus,
            WorkOrderNo,
            WorkOrderId,
            OpenDate,
            WorkOrderStatus,
            TotalRecords
        FROM CTE
        ORDER BY
			CASE WHEN @SortColumn = 'AircraftPublicationNumber' AND @SortOrder = 'ASC'  THEN AircraftPublicationNumber END ASC,
			CASE WHEN @SortColumn = 'AircraftPublicationNumber' AND @SortOrder = 'DESC' THEN AircraftPublicationNumber END DESC,
			CASE WHEN @SortColumn = 'PublicationType' AND @SortOrder = 'ASC'  THEN PublicationType END ASC,
			CASE WHEN @SortColumn = 'PublicationType' AND @SortOrder = 'DESC' THEN PublicationType END DESC,
			CASE WHEN @SortColumn = 'PubNum' AND @SortOrder = 'ASC'  THEN PubNum END ASC,
			CASE WHEN @SortColumn = 'PubNum' AND @SortOrder = 'DESC' THEN PubNum END DESC,
			CASE WHEN @SortColumn = 'RevisionNum' AND @SortOrder = 'ASC'  THEN RevisionNum END ASC,
			CASE WHEN @SortColumn = 'RevisionNum' AND @SortOrder = 'DESC' THEN RevisionNum END DESC,
			CASE WHEN @SortColumn = 'AircraftSection' AND @SortOrder = 'ASC'  THEN AircraftSection END ASC,
			CASE WHEN @SortColumn = 'AircraftSection' AND @SortOrder = 'DESC' THEN AircraftSection END DESC,
			CASE WHEN @SortColumn = 'Subject' AND @SortOrder = 'ASC'  THEN Subject END ASC,
			CASE WHEN @SortColumn = 'Subject' AND @SortOrder = 'DESC' THEN Subject END DESC,
			CASE WHEN @SortColumn = 'PublishedBy' AND @SortOrder = 'ASC'  THEN PublishedBy END ASC,
			CASE WHEN @SortColumn = 'PublishedBy' AND @SortOrder = 'DESC' THEN PublishedBy END DESC,
			CASE WHEN @SortColumn = 'ComplianceCategory' AND @SortOrder = 'ASC'  THEN ComplianceCategory END ASC,
			CASE WHEN @SortColumn = 'ComplianceCategory' AND @SortOrder = 'DESC' THEN ComplianceCategory END DESC,
			CASE WHEN @SortColumn = 'Timeframe' AND @SortOrder = 'ASC'  THEN Timeframe END ASC,
			CASE WHEN @SortColumn = 'Timeframe' AND @SortOrder = 'DESC' THEN Timeframe END DESC,
			CASE WHEN @SortColumn = 'PurposeReasonBackground' AND @SortOrder = 'ASC'  THEN PurposeReasonBackground END ASC,
			CASE WHEN @SortColumn = 'PurposeReasonBackground' AND @SortOrder = 'DESC' THEN PurposeReasonBackground END DESC,
			CASE WHEN @SortColumn = 'EntryDate' AND @SortOrder = 'ASC'  THEN EntryDate END ASC,
			CASE WHEN @SortColumn = 'EntryDate' AND @SortOrder = 'DESC' THEN EntryDate END DESC,
			CASE WHEN @SortColumn = 'VerifiedBy' AND @SortOrder = 'ASC'  THEN VerifiedBy END ASC,
			CASE WHEN @SortColumn = 'VerifiedBy' AND @SortOrder = 'DESC' THEN VerifiedBy END DESC,
			CASE WHEN @SortColumn = 'PubDate' AND @SortOrder = 'ASC'  THEN PubDate END ASC,
			CASE WHEN @SortColumn = 'PubDate' AND @SortOrder = 'DESC' THEN PubDate END DESC,
			CASE WHEN @SortColumn = 'CreatedDate' AND @SortOrder = 'ASC'  THEN CreatedDate END ASC,
			CASE WHEN @SortColumn = 'CreatedDate' AND @SortOrder = 'DESC' THEN CreatedDate END DESC,
			CASE WHEN @SortColumn = 'CreatedBy' AND @SortOrder = 'ASC'  THEN CreatedBy END ASC,
			CASE WHEN @SortColumn = 'CreatedBy' AND @SortOrder = 'DESC' THEN CreatedBy END DESC,
			CASE WHEN @SortColumn = 'UpdatedDate' AND @SortOrder = 'ASC'  THEN UpdatedDate END ASC,
			CASE WHEN @SortColumn = 'UpdatedDate' AND @SortOrder = 'DESC' THEN UpdatedDate END DESC,
			CASE WHEN @SortColumn = 'UpdatedBy' AND @SortOrder = 'ASC'  THEN UpdatedBy END ASC,
			CASE WHEN @SortColumn = 'UpdatedBy' AND @SortOrder = 'DESC' THEN UpdatedBy END DESC,
			CASE WHEN @SortColumn = 'ComplianceDate'  AND @SortOrder = 'ASC'  THEN ComplianceDate END ASC,
            CASE WHEN @SortColumn = 'ComplianceDate'  AND @SortOrder = 'DESC' THEN ComplianceDate END DESC,
		    CASE WHEN @SortColumn = 'Ractification'   AND @SortOrder = 'ASC'  THEN Ractification END ASC,
            CASE WHEN @SortColumn = 'Ractification'   AND @SortOrder = 'DESC' THEN Ractification END DESC,
			CASE WHEN @SortColumn = 'Applicability'    AND @SortOrder = 'ASC'  THEN Applicability END ASC,
            CASE WHEN @SortColumn = 'Applicability'    AND @SortOrder = 'DESC' THEN Applicability END DESC,
			CASE WHEN @SortColumn = 'Mel'    AND @SortOrder = 'ASC'  THEN MEL END ASC,
            CASE WHEN @SortColumn = 'Mel'    AND @SortOrder = 'DESC' THEN MEL END DESC,
			CASE WHEN @SortColumn = 'MakeType'    AND @SortOrder = 'ASC'  THEN MakeType END ASC,
            CASE WHEN @SortColumn = 'MakeType'    AND @SortOrder = 'DESC' THEN MakeType END DESC,
			CASE WHEN @SortColumn = 'AircraftRegistryNumber'    AND @SortOrder = 'ASC'  THEN AircraftRegistryNumber END ASC,
            CASE WHEN @SortColumn = 'AircraftRegistryNumber'    AND @SortOrder = 'DESC' THEN AircraftRegistryNumber END DESC,
			CASE WHEN @SortColumn = 'SerialNum'    AND @SortOrder = 'ASC'  THEN SerialNum END ASC,
            CASE WHEN @SortColumn = 'SerialNum'    AND @SortOrder = 'DESC' THEN SerialNum END DESC,
			CASE WHEN @SortColumn = 'WorksheetNumber'    AND @SortOrder = 'ASC'  THEN WorksheetNumber END ASC,
            CASE WHEN @SortColumn = 'WorksheetNumber'    AND @SortOrder = 'DESC' THEN WorksheetNumber END DESC,
			CASE WHEN @SortColumn = 'WorksheetDate' AND @SortOrder = 'ASC'  THEN WorksheetDate END ASC,
			CASE WHEN @SortColumn = 'WorksheetDate' AND @SortOrder = 'DESC' THEN WorksheetDate END DESC,
			CASE WHEN @SortColumn = 'WorkSheetStatus'    AND @SortOrder = 'ASC'  THEN WorkSheetStatus END ASC,
            CASE WHEN @SortColumn = 'WorkSheetStatus'    AND @SortOrder = 'DESC' THEN WorkSheetStatus END DESC,
			CASE WHEN @SortColumn = 'WorkOrderNo'    AND @SortOrder = 'ASC'  THEN WorkOrderNo END ASC,
            CASE WHEN @SortColumn = 'WorkOrderNo'    AND @SortOrder = 'DESC' THEN WorkOrderNo END DESC,
			CASE WHEN @SortColumn = 'OpenDate' AND @SortOrder = 'ASC'  THEN OpenDate END ASC,
			CASE WHEN @SortColumn = 'OpenDate' AND @SortOrder = 'DESC' THEN OpenDate END DESC,
			CASE WHEN @SortColumn = 'WorkOrderStatus'    AND @SortOrder = 'ASC'  THEN WorkOrderStatus END ASC,
            CASE WHEN @SortColumn = 'WorkOrderStatus'    AND @SortOrder = 'DESC' THEN WorkOrderStatus END DESC,
			AircraftPublicationId DESC, SerialNum ASC
        OFFSET  (@PageNumber - 1) * @PageSize ROWS
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
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftPublicationList',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = '    + ISNULL(CAST(@MasterCompanyId   AS VARCHAR(20)), 'NULL')
                + ', @IsDeleted = '      + ISNULL(CAST(@IsDeleted         AS VARCHAR(5)),  'NULL')
                + ', @AircraftPublicationNumber = '+ ISNULL(CAST(@AircraftPublicationNumber AS VARCHAR(20)), 'NULL')
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
