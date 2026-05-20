/*********************
** File:        [USP_GetAircraftTechnicalRecordList]
** Description:
** Purpose:
** Date:
**
** RETURN VALUE:
*******************************************************************************
** Change History
*******************************************************************************
** PR   Date         Author				Change Description
** --   ----------   -------------		--------------------------------
** 1    18/05/2026   Moin Bloch         Created [PN-16449]
*******************************************************************************/
--EXEC dbo.USP_GetAircraftTechnicalRecordList @PageNumber=1,@PageSize=20,@SortColumn=NULL,@SortOrder=N'ASC',
--@GlobalFilter=NULL,@TailNumber=NULL,@AircraftMake=NULL,@AircraftModel=NULL,@SerialNumber=NULL,@PubDate=NULL,
--@PublicationType=NULL,@PubNum=NULL,@RevisionNum=NULL,@PublishedBy=NULL,@IsActive=NULL,@IsDeleted=0,@MasterCompanyId=1

CREATE   PROCEDURE [dbo].[USP_GetAircraftTechnicalRecordList]
@PageNumber      INT             = 1,
@PageSize        INT             = 10,
@SortColumn      VARCHAR(100)    = 'AircraftRegistryId',
@SortOrder       VARCHAR(4)      = 'DESC',
@GlobalFilter    VARCHAR(100)    = NULL,   
@TailNumber      VARCHAR(50)     = NULL,
@AircraftMake    VARCHAR(100)    = NULL,
@AircraftModel   VARCHAR(100)    = NULL,
@SerialNumber    VARCHAR(100)    = NULL,	
@PubDate         DATETIME        = NULL,
@PublicationType VARCHAR(100)    = NULL,
@PubNum          VARCHAR(100)    = NULL,
@RevisionNum     VARCHAR(50)     = NULL,
@PublishedBy     VARCHAR(100)    = NULL,
@IsActive        BIT             = NULL,
@IsDeleted       BIT             = 0,
@MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

		DECLARE @ManufactureTypeId INT;
		DECLARE @VendorTypeId INT;

		SET @VendorTypeId = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Vendor');
		SET @ManufactureTypeId = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Manufacturer');

        WITH CTE AS
        (		
            SELECT DISTINCT
                ARH.[AircraftRegistryId],
                ARH.[TailNum] AS TailNumber,
                ARH.[MakeType] AS AircraftMake,
                ARH.[AircraftModel],
                ARH.[SerialNum] AS SerialNumber,
                PUB.[PubDate],
				PUT.[Name] AS  PublicationType,
				PUB.[PubNum],
                PUB.[RevisionNum],
				CASE WHEN PUB.PublishedById = @ManufactureTypeId THEN ISNULL(M.[Name],'') WHEN PUB.PublishedById = @VendorTypeId THEN ISNULL(V.VendorName,'') ELSE ISNULL(PUB.PublishedByOthers,'') END  AS PublishedBy,                
				0 AS IsMtceRecordUpdated,
				'' AS MELNumber,
                '' AS WorksheetNumber,
                GETDATE() AS InspectionDate,
                '' AS WorkSheetCompletedBy,
                '' AS WorkSheetStatus,
                '' AS WorkOrderNo,
                GETDATE() AS OpenDate,
                '' AS WorkOrderStatus,			
				ARH.[IsActive],
				ARH.[IsDeleted],
                ARH.[UpdatedDate],
                ARH.[UpdatedBy],
                ARH.[CreatedDate],
                ARH.[CreatedBy],
				ARH.[MasterCompanyId],
                COUNT(1) OVER () AS TotalRecords
            FROM [dbo].[AircraftRegistryHeader] ARH WITH(NOLOCK) 			
			INNER JOIN [dbo].[AircraftEffectivity] ACE WITH(NOLOCK) ON ARH.[MakeTypeId] = ACE.[MakeTypeId] AND ARH.[SerialNum] = ACE.[SerialNum]
			INNER JOIN [dbo].[AircraftPublication] PUB WITH(NOLOCK) ON ACE.[AircraftPublicationId] = PUB.[AircraftPublicationId]
			 LEFT JOIN [dbo].[PublicationType] PUT WITH(NOLOCK) ON PUB.[PublicationTypeId] = PUT.[PublicationTypeId]
			 LEFT JOIN [dbo].[Manufacturer] M WITH(NOLOCK) ON PUB.[PublishedByRefId] = M.[ManufacturerId]
			 LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON PUB.[PublishedByRefId] = V.[VendorId]
            WHERE ARH.MasterCompanyId = @MasterCompanyId  AND (@IsDeleted IS NULL OR ARH.IsDeleted = @IsDeleted)
                -- Global Filter
                AND ( @GlobalFilter IS NULL OR 
					ARH.[TailNum]  LIKE '%' + @GlobalFilter + '%' OR 
					CAST(ARH.[MakeType] AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%' OR
                    ARH.[AircraftModel]  LIKE '%' + @GlobalFilter + '%' OR 
					ARH.[SerialNum]  LIKE '%' + @GlobalFilter + '%'
					OR PUT.[Name] LIKE '%' + @GlobalFilter + '%'
					OR PUB.[PubNum] LIKE '%' + @GlobalFilter + '%'
					OR PUB.[RevisionNum] LIKE '%' + @GlobalFilter + '%'
					OR CASE WHEN PUB.[PublishedById] = @ManufactureTypeId THEN ISNULL(M.[Name], '') WHEN PUB.[PublishedById] = @VendorTypeId THEN ISNULL(V.[VendorName], '') ELSE ISNULL(PUB.[PublishedByOthers], '') END LIKE '%' + ISNULL(@GlobalFilter, '') + '%'
                )
                -- Column Filters                             
                AND (NULLIF(@TailNumber, '')      IS NULL OR ARH.[TailNum]     LIKE '%' + @TailNumber     + '%')
                AND (NULLIF(@AircraftMake, '')    IS NULL OR ARH.[MakeType]   LIKE '%' + @AircraftMake   + '%')
                AND (NULLIF(@AircraftModel, '')   IS NULL OR ARH.[AircraftModel]  LIKE '%' + @AircraftModel  + '%')
                AND (NULLIF(@SerialNumber, '')    IS NULL OR ARH.[SerialNum]   LIKE '%' + @SerialNumber   + '%')                
                AND (@IsActive                    IS NULL OR ARH.[IsActive] = @IsActive)
				AND (NULLIF(@PublicationType, '') IS NULL OR PUT.[Name] LIKE '%' + @PublicationType + '%')
				AND (NULLIF(@PubNum, '')          IS NULL OR PUB.[PubNum] LIKE '%' + @PubNum + '%')
				AND (NULLIF(@RevisionNum, '')     IS NULL OR PUB.[RevisionNum] LIKE '%' + @RevisionNum + '%')
                AND (@PubDate                     IS NULL OR CAST(PUB.[PubDate] AS DATE) = CAST(@PubDate AS DATE))
				AND (NULLIF(@PublishedBy, '')     IS NULL OR CASE WHEN PUB.[PublishedById] = @ManufactureTypeId THEN ISNULL(M.[Name],'') WHEN PUB.[PublishedById] = @VendorTypeId THEN ISNULL(V.[VendorName],'') ELSE ISNULL(PUB.[PublishedByOthers],'') END LIKE '%' + @PublishedBy + '%')                             
        )

        SELECT *
        FROM CTE
        ORDER BY            
            CASE WHEN @SortColumn = 'TailNumber'        AND @SortOrder = 'ASC'  THEN [TailNumber] END ASC,
            CASE WHEN @SortColumn = 'TailNumber'        AND @SortOrder = 'DESC' THEN [TailNumber] END DESC,
            CASE WHEN @SortColumn = 'AircraftMake'      AND @SortOrder = 'ASC'  THEN [AircraftMake] END ASC,
            CASE WHEN @SortColumn = 'AircraftMake'      AND @SortOrder = 'DESC' THEN [AircraftMake] END DESC,
            CASE WHEN @SortColumn = 'AircraftModel'     AND @SortOrder = 'ASC'  THEN [AircraftModel] END ASC,
            CASE WHEN @SortColumn = 'AircraftModel'     AND @SortOrder = 'DESC' THEN [AircraftModel] END DESC,
            CASE WHEN @SortColumn = 'SerialNumber'      AND @SortOrder = 'ASC'  THEN [SerialNumber] END ASC,
            CASE WHEN @SortColumn = 'SerialNumber'      AND @SortOrder = 'DESC' THEN [SerialNumber] END DESC,            
            CASE WHEN @SortColumn = 'CreatedDate'       AND @SortOrder = 'ASC'  THEN [CreatedDate] END ASC,
            CASE WHEN @SortColumn = 'CreatedDate'       AND @SortOrder = 'DESC' THEN [CreatedDate] END DESC,
			CASE WHEN @SortColumn = 'PublicationType'   AND @SortOrder = 'ASC'  THEN [PublicationType] END ASC,
			CASE WHEN @SortColumn = 'PublicationType'   AND @SortOrder = 'DESC' THEN [PublicationType] END DESC,			
			CASE WHEN @SortColumn = 'PubNum'            AND @SortOrder = 'ASC'  THEN [PubNum] END ASC,
			CASE WHEN @SortColumn = 'PubNum'            AND @SortOrder = 'DESC' THEN [PubNum] END DESC,			
			CASE WHEN @SortColumn = 'RevisionNum'       AND @SortOrder = 'ASC'  THEN [RevisionNum] END ASC,
			CASE WHEN @SortColumn = 'RevisionNum'       AND @SortOrder = 'DESC' THEN [RevisionNum] END DESC,
			CASE WHEN @SortColumn = 'PubDate'           AND @SortOrder = 'ASC'  THEN [PubDate] END ASC,
			CASE WHEN @SortColumn = 'PubDate'           AND @SortOrder = 'DESC' THEN [PubDate] END DESC,		
			
			[AircraftRegistryId] DESC
		    		
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY

    BEGIN CATCH      
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftTechnicalRecordList',
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