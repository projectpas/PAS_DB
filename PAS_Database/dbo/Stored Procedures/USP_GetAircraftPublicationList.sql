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

************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAircraftPublicationList]
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
	@ToPubDate   DATETIME        = NULL
AS
BEGIN
    --SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
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
                EMP.FirstName + EMP.LastName AS VerifiedBy,
				AP.PubDate,
				AP.CreatedDate,
				AP.CreatedBy,
				AP.UpdatedDate,
				AP.UpdatedBy,
                AP.IsActive,
                AP.IsDeleted,
				AP.MasterCompanyId,
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[AircraftPublication] AS AP WITH (NOLOCK)
			LEFT JOIN dbo.PublicationType PT WITH (NOLOCK) ON AP.PublicationTypeId = PT.PublicationTypeId
			LEFT JOIN dbo.AircraftSection ASE WITH (NOLOCK) ON AP.AircraftSectionId = ASE.AircraftSectionId
			LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = AP.VerifiedBy
			LEFT JOIN [dbo].[Module] pemp WITH (NOLOCK) ON AP.PublishedById = pemp.ModuleId 
			LEFT JOIN [dbo].[Manufacturer] M with (NOLOCK) ON AP.PublishedByRefId = M.ManufacturerId
			LEFT JOIN [dbo].[Vendor] V with (NOLOCK) ON AP.PublishedByRefId = V.VendorId
            WHERE
                AP.MasterCompanyId = @MasterCompanyId
                AND (@IsDeleted IS NULL OR AP.IsDeleted = @IsDeleted)
				AND ((@FromPubDate IS NULL AND @ToPubDate IS NULL)
						OR CAST(AP.PubDate AS DATE) BETWEEN 
						CAST(@FromPubDate AS DATE) 
						AND CAST(@ToPubDate AS DATE)
					)
                AND (
     --               @GlobalFilter IS NULL
     --               OR AP.AircraftPublicationNumber  LIKE '%' + @GlobalFilter + '%'
     --               OR PT.[Name] LIKE '%' + @GlobalFilter + '%'
					--OR AP.[PubNum] LIKE '%' + @GlobalFilter + '%'
					--OR AP.[RevisionNum] LIKE '%' + @GlobalFilter + '%'
					--OR ASE.[Section] LIKE '%' + @GlobalFilter + '%'
					--OR AP.[Subject] LIKE '%' + @GlobalFilter + '%'
					--OR AP.ComplianceCategory LIKE '%' + @GlobalFilter + '%'
					--OR AP.Timeframe LIKE '%' + @GlobalFilter + '%'
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
                )
    --            AND (@AircraftPublicationNumber          IS NULL OR AP.AircraftPublicationNumber         LIKE '%' + @AircraftPublicationNumber         + '%')
    --            AND (@PublicationType     IS NULL OR PT.[Name]    LIKE '%' + @PublicationType    + '%')
				--AND (@PubNum     IS NULL OR AP.[PubNum]    LIKE '%' + @PubNum    + '%')
				--AND (@RevisionNum     IS NULL OR RevisionNum    LIKE '%' + @RevisionNum    + '%')
				--AND (@AircraftSection     IS NULL OR Section    LIKE '%' + @AircraftSection    + '%')
				--AND (@Subject     IS NULL OR [Subject]    LIKE '%' + @Subject    + '%')
				--AND (@ComplianceCategory     IS NULL OR ComplianceCategory    LIKE '%' + @ComplianceCategory    + '%')
				AND (NULLIF(@AircraftPublicationNumber, '') IS NULL OR AP.AircraftPublicationNumber LIKE '%' + @AircraftPublicationNumber + '%')
				AND (NULLIF(@PublicationType, '') IS NULL OR PT.[Name] LIKE '%' + @PublicationType + '%')
				AND (NULLIF(@PubNum, '') IS NULL OR AP.PubNum LIKE '%' + @PubNum + '%')
				AND (NULLIF(@RevisionNum, '') IS NULL OR AP.RevisionNum LIKE '%' + @RevisionNum + '%')
				AND (NULLIF(@AircraftSection, '') IS NULL OR ASE.Section LIKE '%' + @AircraftSection + '%')
				AND (NULLIF(@Subject, '') IS NULL OR AP.[Subject] LIKE '%' + @Subject + '%')
				AND (NULLIF(@PublishedBy, '') IS NULL OR CASE WHEN AP.PublishedById = @ManufactureTypeId THEN ISNULL(M.[Name],'') WHEN AP.PublishedById = @VendorTypeId THEN ISNULL(V.VendorName,'') ELSE ISNULL(AP.PublishedByOthers,'') END LIKE '%' + @PublishedBy + '%') -- placeholder
				AND (NULLIF(@ComplianceCategory, '') IS NULL OR AP.ComplianceCategory LIKE '%' + @ComplianceCategory + '%')
				AND (NULLIF(@Timeframe, '') IS NULL OR AP.Timeframe LIKE '%' + @Timeframe + '%')
				AND (NULLIF(@PurposeReasonBackground, '') IS NULL OR AP.PurposeReasonBackground LIKE '%' + @PurposeReasonBackground + '%')
				AND (@EntryDate IS NULL OR CAST(AP.EntryDate AS DATE) = CAST(@EntryDate AS DATE))
				AND (NULLIF(@VerifiedBy, '') IS NULL OR CAST(EMP.FirstName + EMP.LastName AS VARCHAR) LIKE '%' + @VerifiedBy + '%')
				AND (@PubDate IS NULL OR CAST(AP.PubDate AS DATE) = CAST(@PubDate AS DATE))
				AND (@CreatedDate IS NULL OR CAST(AP.CreatedDate AS DATE) = CAST(@CreatedDate AS DATE))
				AND (NULLIF(@CreatedBy, '') IS NULL OR AP.CreatedBy LIKE '%' + @CreatedBy + '%')
				AND (@UpdatedDate IS NULL OR CAST(AP.UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE))
				AND (NULLIF(@UpdatedBy, '') IS NULL OR AP.UpdatedBy LIKE '%' + @UpdatedBy + '%')
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
            TotalRecords
        FROM CTE
        ORDER BY
   --         CASE WHEN @SortColumn = 'AircraftPublicationNumber'           AND @SortOrder = 'ASC'  THEN AircraftPublicationNumber          END ASC,
   --         CASE WHEN @SortColumn = 'AircraftPublicationNumber'           AND @SortOrder = 'DESC' THEN AircraftPublicationNumber          END DESC,

			--CASE WHEN @SortColumn = 'Name'           AND @SortOrder = 'ASC'  THEN PublicationType          END ASC,
   --         CASE WHEN @SortColumn = 'Name'           AND @SortOrder = 'DESC' THEN PublicationType          END DESC,

			--CASE WHEN @SortColumn = 'PubNum'           AND @SortOrder = 'ASC'  THEN PubNum          END ASC,
   --         CASE WHEN @SortColumn = 'PubNum'           AND @SortOrder = 'DESC' THEN PubNum          END DESC,
           
   --         CASE WHEN @SortColumn = 'CreatedDate'        AND @SortOrder = 'ASC'  THEN CreatedDate       END ASC,
   --         CASE WHEN @SortColumn = 'CreatedDate'        AND @SortOrder = 'DESC' THEN CreatedDate       END DESC,
   --         AircraftPublicationId DESC
   -- AircraftPublicationNumber
			CASE WHEN @SortColumn = 'AircraftPublicationNumber' AND @SortOrder = 'ASC'  THEN AircraftPublicationNumber END ASC,
			CASE WHEN @SortColumn = 'AircraftPublicationNumber' AND @SortOrder = 'DESC' THEN AircraftPublicationNumber END DESC,

			-- PublicationType (FIXED from Name)
			CASE WHEN @SortColumn = 'PublicationType' AND @SortOrder = 'ASC'  THEN PublicationType END ASC,
			CASE WHEN @SortColumn = 'PublicationType' AND @SortOrder = 'DESC' THEN PublicationType END DESC,

			-- PubNum
			CASE WHEN @SortColumn = 'PubNum' AND @SortOrder = 'ASC'  THEN PubNum END ASC,
			CASE WHEN @SortColumn = 'PubNum' AND @SortOrder = 'DESC' THEN PubNum END DESC,

			-- RevisionNum
			CASE WHEN @SortColumn = 'RevisionNum' AND @SortOrder = 'ASC'  THEN RevisionNum END ASC,
			CASE WHEN @SortColumn = 'RevisionNum' AND @SortOrder = 'DESC' THEN RevisionNum END DESC,

			-- AircraftSection
			CASE WHEN @SortColumn = 'AircraftSection' AND @SortOrder = 'ASC'  THEN AircraftSection END ASC,
			CASE WHEN @SortColumn = 'AircraftSection' AND @SortOrder = 'DESC' THEN AircraftSection END DESC,

			-- Subject
			CASE WHEN @SortColumn = 'Subject' AND @SortOrder = 'ASC'  THEN Subject END ASC,
			CASE WHEN @SortColumn = 'Subject' AND @SortOrder = 'DESC' THEN Subject END DESC,

			-- PublishedBy
			CASE WHEN @SortColumn = 'PublishedBy' AND @SortOrder = 'ASC'  THEN PublishedBy END ASC,
			CASE WHEN @SortColumn = 'PublishedBy' AND @SortOrder = 'DESC' THEN PublishedBy END DESC,

			-- ComplianceCategory
			CASE WHEN @SortColumn = 'ComplianceCategory' AND @SortOrder = 'ASC'  THEN ComplianceCategory END ASC,
			CASE WHEN @SortColumn = 'ComplianceCategory' AND @SortOrder = 'DESC' THEN ComplianceCategory END DESC,

			-- Timeframe
			CASE WHEN @SortColumn = 'Timeframe' AND @SortOrder = 'ASC'  THEN Timeframe END ASC,
			CASE WHEN @SortColumn = 'Timeframe' AND @SortOrder = 'DESC' THEN Timeframe END DESC,

			-- PurposeReasonBackground
			CASE WHEN @SortColumn = 'PurposeReasonBackground' AND @SortOrder = 'ASC'  THEN PurposeReasonBackground END ASC,
			CASE WHEN @SortColumn = 'PurposeReasonBackground' AND @SortOrder = 'DESC' THEN PurposeReasonBackground END DESC,

			-- EntryDate
			CASE WHEN @SortColumn = 'EntryDate' AND @SortOrder = 'ASC'  THEN EntryDate END ASC,
			CASE WHEN @SortColumn = 'EntryDate' AND @SortOrder = 'DESC' THEN EntryDate END DESC,

			-- VerifiedBy
			CASE WHEN @SortColumn = 'VerifiedBy' AND @SortOrder = 'ASC'  THEN VerifiedBy END ASC,
			CASE WHEN @SortColumn = 'VerifiedBy' AND @SortOrder = 'DESC' THEN VerifiedBy END DESC,

			-- PubDate
			CASE WHEN @SortColumn = 'PubDate' AND @SortOrder = 'ASC'  THEN PubDate END ASC,
			CASE WHEN @SortColumn = 'PubDate' AND @SortOrder = 'DESC' THEN PubDate END DESC,

			-- CreatedDate
			CASE WHEN @SortColumn = 'CreatedDate' AND @SortOrder = 'ASC'  THEN CreatedDate END ASC,
			CASE WHEN @SortColumn = 'CreatedDate' AND @SortOrder = 'DESC' THEN CreatedDate END DESC,

			-- CreatedBy
			CASE WHEN @SortColumn = 'CreatedBy' AND @SortOrder = 'ASC'  THEN CreatedBy END ASC,
			CASE WHEN @SortColumn = 'CreatedBy' AND @SortOrder = 'DESC' THEN CreatedBy END DESC,

			-- UpdatedDate
			CASE WHEN @SortColumn = 'UpdatedDate' AND @SortOrder = 'ASC'  THEN UpdatedDate END ASC,
			CASE WHEN @SortColumn = 'UpdatedDate' AND @SortOrder = 'DESC' THEN UpdatedDate END DESC,

			-- UpdatedBy
			CASE WHEN @SortColumn = 'UpdatedBy' AND @SortOrder = 'ASC'  THEN UpdatedBy END ASC,
			CASE WHEN @SortColumn = 'UpdatedBy' AND @SortOrder = 'DESC' THEN UpdatedBy END DESC,

			-- Default fallback
			AircraftPublicationId DESC
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