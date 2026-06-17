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
** 2    20/05/2026	 Moin Bloch			Added IsMtceRecordUpdated [PN-16449]
** 3    22/05/2026	 Moin Bloch			Fixed Duplicate Issue [PN-16449]
** 4    22/05/2026	 Moin Bloch			Fixed Duplicate Issue [PN-16449]
** 5    22/05/2026	 Amit Ghediya	    Get WSheet & wo data [PN-16546]
** 6    22/05/2026	 Bhargav Saliya		Added MtceRecordUpdated Filter [PN-16567]
** 7    10/06/2026	 Amit Ghediya		Update name WorksheetNumber to WorksheetNum due to use in other [PN-16797]
** 8    15/06/2026	 Amit Ghediya		Update TotalRecords when filter not worked.
** 9    16/06/2026	 Amit Ghediya		Get AircraftPublicationId [PN-16797]
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
@MasterCompanyId INT,
@InspectionDate  DATETIME        = NULL,
@WorksheetNumber VARCHAR(100)    = NULL,
@WorkSheetCompletedBy VARCHAR(100) = NULL,
@WorkOrderNum VARCHAR(100) = NULL,
@WorkOrderStatus VARCHAR(100) = NULL,
@WorkSheetStatus VARCHAR(100) = NULL,
@OpenDate  DATETIME        = NULL,
@MtceRecordUpdated VARCHAR(50)     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @ManufactureTypeId INT;
        DECLARE @VendorTypeId INT;

        SET @VendorTypeId = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Vendor');
		SET @ManufactureTypeId = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Manufacturer');

        ;WITH CTE AS
        (
            SELECT DISTINCT
                ARH.AircraftRegistryId,
                ARH.TailNum AS TailNumber,
                ARH.MakeType AS AircraftMake,
                ARH.AircraftModel,
                ARH.SerialNum AS SerialNumber,
                PUB.PubDate,
                PUT.Name AS PublicationType,
                PUB.PubNum,
                PUB.RevisionNum,
                CASE
                    WHEN PUB.PublishedById = @ManufactureTypeId
                        THEN ISNULL(M.Name,'')
                    WHEN PUB.PublishedById = @VendorTypeId
                        THEN ISNULL(V.VendorName,'')
                    ELSE ISNULL(PUB.PublishedByOthers,'')
                END AS PublishedBy,
				PUB.AircraftPublicationId,
                CASE
                    WHEN EXISTS
                    (
                        SELECT 1
                        FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                        WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId
                        AND ISNULL(AMP.IsMtceRecordUpdated,0) = 1 AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                    )
                    THEN 1
                    ELSE 0
                END AS IsMtceRecordUpdated,
                '' AS MELNumber,
                (
                    SELECT TOP 1 WSH.WorksheetNumber
                    FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                    LEFT JOIN dbo.WorksheetHeader WSH WITH(NOLOCK)
                        ON WSH.ProgramId = AMP.ProgramId
                    WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ) AS WorksheetNum,
                (
                    SELECT TOP 1 WSH.CreatedDate
                    FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                    LEFT JOIN dbo.WorksheetHeader WSH WITH(NOLOCK)
                        ON WSH.ProgramId = AMP.ProgramId
                    WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ) AS InspectionDate,
                (
                    SELECT TOP 1 WSH.CreatedBy
                    FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                    LEFT JOIN dbo.WorksheetHeader WSH WITH(NOLOCK)
                        ON WSH.ProgramId = AMP.ProgramId
                    WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ) AS WorkSheetCompletedBy,
				(
					SELECT TOP 1
						CASE
							WHEN AMP.ProgramId IS NULL OR WSH.WorksheetHeaderId IS NULL
							THEN NULL

							-- No worksheet created → Open
							WHEN WSH.WorksheetHeaderId IS NULL
							THEN 'Open'

							-- Worksheet exists but no Work Order linked → Open
							WHEN WOP2.WorkOrderId IS NULL
							THEN 'Open'

							-- Work Order exists and status = 2 → Closed
							WHEN ISNULL(WO2.WorkOrderStatusId, 0) = 2
							THEN 'Closed'

							WHEN UPPER(ISNULL(WOP2.WorkOrderStatus, '')) = 'CLOSED'
							THEN 'Closed'

							WHEN ISNULL(
									CASE
										WHEN ISNULL(WSH.AircraftInstalledPartDetailsId, 0) > 0
										THEN WOP2.WorkOrderStatusId
										ELSE WO2.WorkOrderStatusId
									END, 0) = 2
							THEN 'Closed'

							-- Work Order exists and not closed → In Process
							ELSE 'In Process'
						END
					FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
					LEFT JOIN dbo.WorksheetHeader WSH WITH(NOLOCK) ON WSH.ProgramId = AMP.ProgramId
					LEFT JOIN [dbo].[WorkOrderPartNumber] WOP2 WITH(NOLOCK) ON WOP2.ProgramId = AMP.ProgramId
					LEFT JOIN [dbo].[WorkOrder] WO2 WITH(NOLOCK) ON WO2.WorkOrderId = WOP2.WorkOrderId
					WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
				) AS WorkSheetStatus,
                (
                    SELECT TOP 1 WO.WorkOrderNum
                    FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                    LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)
                        ON WOPN.ProgramId = AMP.ProgramId
                    LEFT JOIN dbo.WorkOrder WO WITH(NOLOCK)
                        ON WO.WorkOrderId = WOPN.WorkOrderId
                    WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ) AS WorkOrderNum,
                (
                    SELECT TOP 1 WO.OpenDate
                    FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                    LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)
                        ON WOPN.ProgramId = AMP.ProgramId
					LEFT JOIN dbo.WorkOrder WO WITH(NOLOCK)
                        ON WO.WorkOrderId = WOPN.WorkOrderId
                    WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ) AS OpenDate,
                (
                    SELECT TOP 1 WOPN.WorkOrderStatus
                    FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
                    LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)
                        ON WOPN.ProgramId = AMP.ProgramId
                    WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ) AS WorkOrderStatus,
                ARH.IsActive,
                ARH.IsDeleted,
                ARH.UpdatedDate,
                ARH.UpdatedBy,
                ARH.CreatedDate,
                ARH.CreatedBy,
                ARH.MasterCompanyId,
                CASE WHEN EXISTS (SELECT 1 FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK) WHERE AMP.AircraftRegistryId = ARH.AircraftRegistryId AND ISNULL(AMP.IsMtceRecordUpdated, 0) = 1)
                THEN 'YES' ELSE 'NO' END AS MtceRecordUpdated
             FROM [dbo].[AircraftRegistryHeader] ARH WITH(NOLOCK) 			
			INNER JOIN [dbo].[AircraftEffectivity] ACE WITH(NOLOCK) ON ARH.[MakeTypeId] = ACE.[MakeTypeId] AND ARH.[SerialNum] = ACE.[SerialNum]
			INNER JOIN [dbo].[AircraftPublication] PUB WITH(NOLOCK) ON ACE.[AircraftPublicationId] = PUB.[AircraftPublicationId]
			 LEFT JOIN [dbo].[PublicationType] PUT WITH(NOLOCK) ON PUB.[PublicationTypeId] = PUT.[PublicationTypeId]
			 LEFT JOIN [dbo].[Manufacturer] M WITH(NOLOCK) ON PUB.[PublishedByRefId] = M.[ManufacturerId]
			 LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON PUB.[PublishedByRefId] = V.[VendorId]
            WHERE ARH.MasterCompanyId = @MasterCompanyId  AND (@IsDeleted IS NULL OR ARH.IsDeleted = @IsDeleted)
        )

        SELECT *,
			COUNT(1) OVER() AS TotalRecords
        FROM CTE
        WHERE
        (
            @GlobalFilter IS NULL
            OR TailNumber LIKE '%' + @GlobalFilter + '%'
            OR AircraftMake LIKE '%' + @GlobalFilter + '%'
            OR AircraftModel LIKE '%' + @GlobalFilter + '%'
            OR SerialNumber LIKE '%' + @GlobalFilter + '%'
            OR PublicationType LIKE '%' + @GlobalFilter + '%'
            OR PubNum LIKE '%' + @GlobalFilter + '%'
            OR RevisionNum LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorksheetNum,'') LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkSheetCompletedBy,'') LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkOrderNum,'') LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkOrderStatus,'') LIKE '%' + @GlobalFilter + '%'
			OR ISNULL(WorkSheetStatus,'') LIKE '%' + @GlobalFilter + '%'
            OR PublishedBy LIKE '%' + @GlobalFilter + '%'
        )

        AND (NULLIF(@TailNumber,'') IS NULL OR TailNumber LIKE '%' + @TailNumber + '%')
        AND (NULLIF(@AircraftMake,'') IS NULL OR AircraftMake LIKE '%' + @AircraftMake + '%')
        AND (NULLIF(@AircraftModel,'') IS NULL OR AircraftModel LIKE '%' + @AircraftModel + '%')
        AND (NULLIF(@SerialNumber,'') IS NULL OR SerialNumber LIKE '%' + @SerialNumber + '%')
        AND (NULLIF(@PublicationType,'') IS NULL OR PublicationType LIKE '%' + @PublicationType + '%')
        AND (NULLIF(@PubNum,'') IS NULL OR PubNum LIKE '%' + @PubNum + '%')
        AND (NULLIF(@RevisionNum,'') IS NULL OR RevisionNum LIKE '%' + @RevisionNum + '%')
        AND (NULLIF(@PublishedBy,'') IS NULL OR PublishedBy LIKE '%' + @PublishedBy + '%')
        AND (NULLIF(@WorksheetNumber,'') IS NULL OR ISNULL(WorksheetNum,'') LIKE '%' + @WorksheetNumber + '%')
		AND (@InspectionDate  IS NULL OR CAST(InspectionDate AS DATE) = CAST(@InspectionDate AS DATE))
		AND (@OpenDate  IS NULL OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE))
        AND (NULLIF(@WorkSheetCompletedBy,'') IS NULL OR ISNULL(WorkSheetCompletedBy,'') LIKE '%' + @WorkSheetCompletedBy + '%')
        AND (NULLIF(@WorkOrderNum,'') IS NULL OR ISNULL(WorkOrderNum,'') LIKE '%' + @WorkOrderNum + '%')
        AND (NULLIF(@WorkOrderStatus,'') IS NULL OR ISNULL(WorkOrderStatus,'') LIKE '%' + @WorkOrderStatus + '%')
		AND (NULLIF(@WorkSheetStatus,'') IS NULL OR ISNULL(WorkSheetStatus,'') LIKE '%' + @WorkSheetStatus + '%')
        AND (ISNULL(@MtceRecordUpdated, '') = '' OR (CASE WHEN ISNULL([IsMtceRecordUpdated],0) = 1 THEN 'YES' ELSE 'NO' END) LIKE '%' + @MtceRecordUpdated + '%' )

        ORDER BY

            CASE WHEN @SortColumn = 'TailNumber' AND @SortOrder = 'ASC' THEN TailNumber END ASC,
            CASE WHEN @SortColumn = 'TailNumber' AND @SortOrder = 'DESC' THEN TailNumber END DESC,

            CASE WHEN @SortColumn = 'AircraftMake' AND @SortOrder = 'ASC' THEN AircraftMake END ASC,
            CASE WHEN @SortColumn = 'AircraftMake' AND @SortOrder = 'DESC' THEN AircraftMake END DESC,

            CASE WHEN @SortColumn = 'AircraftModel' AND @SortOrder = 'ASC' THEN AircraftModel END ASC,
            CASE WHEN @SortColumn = 'AircraftModel' AND @SortOrder = 'DESC' THEN AircraftModel END DESC,

            CASE WHEN @SortColumn = 'SerialNumber' AND @SortOrder = 'ASC' THEN SerialNumber END ASC,
            CASE WHEN @SortColumn = 'SerialNumber' AND @SortOrder = 'DESC' THEN SerialNumber END DESC,

            CASE WHEN @SortColumn = 'WorksheetNum' AND @SortOrder = 'ASC' THEN WorksheetNum END ASC,
            CASE WHEN @SortColumn = 'WorksheetNum' AND @SortOrder = 'DESC' THEN WorksheetNum END DESC,

			CASE WHEN @SortColumn = 'InspectionDate' AND @SortOrder = 'ASC' THEN InspectionDate END ASC,
            CASE WHEN @SortColumn = 'InspectionDate' AND @SortOrder = 'DESC' THEN InspectionDate END DESC,

			CASE WHEN @SortColumn = 'OpenDate' AND @SortOrder = 'ASC' THEN OpenDate END ASC,
            CASE WHEN @SortColumn = 'OpenDate' AND @SortOrder = 'DESC' THEN OpenDate END DESC,

            CASE WHEN @SortColumn = 'WorkSheetCompletedBy' AND @SortOrder = 'ASC' THEN WorkSheetCompletedBy END ASC,
            CASE WHEN @SortColumn = 'WorkSheetCompletedBy' AND @SortOrder = 'DESC' THEN WorkSheetCompletedBy END DESC,

            CASE WHEN @SortColumn = 'WorkOrderNum' AND @SortOrder = 'ASC' THEN WorkOrderNum END ASC,
            CASE WHEN @SortColumn = 'WorkOrderNum' AND @SortOrder = 'DESC' THEN WorkOrderNum END DESC,

            CASE WHEN @SortColumn = 'WorkOrderStatus' AND @SortOrder = 'ASC' THEN WorkOrderStatus END ASC,
            CASE WHEN @SortColumn = 'WorkOrderStatus' AND @SortOrder = 'DESC' THEN WorkOrderStatus END DESC,

			CASE WHEN @SortColumn = 'WorkSheetStatus' AND @SortOrder = 'ASC' THEN WorkSheetStatus END ASC,
            CASE WHEN @SortColumn = 'WorkSheetStatus' AND @SortOrder = 'DESC' THEN WorkSheetStatus END DESC,

            CASE WHEN @SortColumn = 'MtceRecordUpdated' AND @SortOrder = 'ASC'  THEN [MtceRecordUpdated] END ASC,
            CASE WHEN @SortColumn = 'MtceRecordUpdated' AND @SortOrder = 'DESC' THEN [MtceRecordUpdated] END DESC,

            AircraftRegistryId DESC

        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY

    BEGIN CATCH

        THROW;

    END CATCH
END