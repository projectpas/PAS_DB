/*************************************************************     
** Author:  <Amit Ghediya>    
** Create date: <05/04/2026>    
** Description: <This Proc Is used to Get Aircraft AircraftEffectivity>    
    
Exec [USP_GetAircraftEffectivity]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
   1    05/05/2026  Amit Ghediya		Created  
     
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetAircraftEffectivity]
(
    @PageNumber INT,
    @PageSize INT,
    @SortColumn VARCHAR(50) = NULL,
    @SortOrder  VARCHAR(4)      = 'DESC',
    @GlobalFilter VARCHAR(50) = NULL,

    @MakeTypeId BIGINT = NULL,
    @AircraftModelId BIGINT = NULL,
    @AircraftSubModel VARCHAR(100) = NULL,
    @SerialNum VARCHAR(100) = NULL,

    @PartNumber VARCHAR(100) = NULL,
    @PartDescription VARCHAR(200) = NULL,

    @IsDeleted BIT = NULL,
    @IsActive BIT = NULL,
    @MasterCompanyId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @RecordFrom INT = (@PageNumber - 1) * @PageSize;
        DECLARE @Count INT;

        SET @SortColumn = UPPER(ISNULL(@SortColumn, 'CREATEDDATE'));

        ;WITH Result AS
        (
            SELECT
                AE.AircraftEffectivityId,
                AE.AircraftPublicationId,
                AE.MakeTypeId,
                MT.Name AS MakeType,

                AE.AircraftModelId,
                AM.Name AS AircraftModel,

                AE.AircraftSubModel,
                AE.SerialNum,

                AE.ItemMasterId,
                IM.PartNumber,
                IM.PartDescription,

                AE.Notes,
                AE.MasterCompanyId,
                AE.IsActive,
                AE.IsDeleted,
                AE.CreatedBy,
                AE.UpdatedBy,
                AE.CreatedDate,
                AE.UpdatedDate

            FROM dbo.AircraftEffectivity AE WITH(NOLOCK)

            LEFT JOIN dbo.MakeType MT WITH(NOLOCK) 
                ON AE.MakeTypeId = MT.MakeTypeId

            LEFT JOIN dbo.AircraftModel AM WITH(NOLOCK) 
                ON AE.AircraftModelId = AM.AircraftModelId

            LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) 
                ON AE.ItemMasterId = IM.ItemMasterId

            WHERE AE.MasterCompanyId = @MasterCompanyId
        )

        SELECT * INTO #TempResult
        FROM Result
        WHERE
        (
            (@GlobalFilter <> '' AND (
                MakeType LIKE '%' + @GlobalFilter + '%' OR
                AircraftModel LIKE '%' + @GlobalFilter + '%' OR
                AircraftSubModel LIKE '%' + @GlobalFilter + '%' OR
                SerialNum LIKE '%' + @GlobalFilter + '%' OR
                PartNumber LIKE '%' + @GlobalFilter + '%' OR
                PartDescription LIKE '%' + @GlobalFilter + '%'
            ))
            OR
            (@GlobalFilter = '' AND
                (ISNULL(@MakeTypeId,0)=0 OR MakeTypeId = @MakeTypeId) AND
                (ISNULL(@AircraftModelId,0)=0 OR AircraftModelId = @AircraftModelId) AND
                (ISNULL(@AircraftSubModel,'')='' OR AircraftSubModel LIKE '%' + @AircraftSubModel + '%') AND
                (ISNULL(@SerialNum,'')='' OR SerialNum LIKE '%' + @SerialNum + '%') AND
                (ISNULL(@PartNumber,'')='' OR PartNumber LIKE '%' + @PartNumber + '%') AND
                (ISNULL(@PartDescription,'')='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
                (ISNULL(@IsActive, AE.IsActive) = AE.IsActive) AND
                (ISNULL(@IsDeleted, AE.IsDeleted) = AE.IsDeleted)
            )
        );

        -- Total count
        SELECT @Count = COUNT(*) FROM #TempResult;

        -- Final result with paging
        SELECT *, @Count AS TotalCount
        FROM #TempResult
        ORDER BY
            CASE WHEN @SortOrder = 'ASC' AND @SortColumn = 'MAKETYPE' THEN MakeType END ASC,
            CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'MAKETYPE' THEN MakeType END DESC,

            CASE WHEN @SortOrder = 'ASC' AND @SortColumn = 'AIRCRAFTMODEL' THEN AircraftModel END ASC,
            CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'AIRCRAFTMODEL' THEN AircraftModel END DESC,

            CASE WHEN @SortOrder = 'ASC' AND @SortColumn = 'SERIALNUM' THEN SerialNum END ASC,
            CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SERIALNUM' THEN SerialNum END DESC,

            CASE WHEN @SortOrder = 'ASC' AND @SortColumn = 'PARTNUMBER' THEN PartNumber END ASC,
            CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'PARTNUMBER' THEN PartNumber END DESC,

            CASE WHEN @SortOrder = 'ASC' AND @SortColumn = 'CREATEDDATE' THEN CreatedDate END ASC,
            CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CREATEDDATE' THEN CreatedDate END DESC,

            AircraftEffectivityId DESC
        OFFSET @RecordFrom ROWS
        FETCH NEXT @PageSize ROWS ONLY;

    END TRY

    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetAircraftEffectivity',
                @ProcedureParameters VARCHAR(3000),
                @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
              '@PageNumber=' + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(20))
            + ', @PageSize=' + CAST(ISNULL(@PageSize, 0) AS VARCHAR(20))
            + ', @MasterCompanyId=' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20));

        EXEC spLogException
             @DatabaseName = @DatabaseName,
             @AdhocComments = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName = @ApplicationName,
             @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected error occurred. Error number: %d',
            16, 1, @ErrorLogID
        );

        RETURN 1;
    END CATCH
END