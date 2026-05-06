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
    @SortOrder  INT,
    @GlobalFilter VARCHAR(50) = NULL,
    @AircraftType VARCHAR(50) = NULL,
    @AircraftModel VARCHAR(50) = NULL,
    @AircraftSubModel VARCHAR(100) = NULL,
    @SerialNum VARCHAR(100) = NULL,
	@Notes VARCHAR(100) = NULL,
    @PartNumber VARCHAR(100) = NULL,
    @PartDescription VARCHAR(200) = NULL,
    @IsDeleted BIT = NULL,
    @IsActive BIT = NULL,
    @MasterCompanyId BIGINT,
	@CreatedDate datetime,  
	@UpdatedDate  datetime,  
	@CreatedBy  varchar(50),  
	@UpdatedBy  varchar(50)
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
                MT.Description AS AircraftType,
                AE.AircraftModelId,
                AM.ModelName AS AircraftModel,
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
            LEFT JOIN dbo.aircrafttype MT WITH(NOLOCK) ON AE.MakeTypeId = MT.AircraftTypeId
            LEFT JOIN dbo.AircraftModel AM WITH(NOLOCK) ON AE.AircraftModelId = AM.AircraftModelId
            LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON AE.ItemMasterId = IM.ItemMasterId
            WHERE AE.MasterCompanyId = @MasterCompanyId
        )

        SELECT * INTO #TempResult
        FROM Result
        WHERE
        (
            (@GlobalFilter <> '' AND (
                aircraftType LIKE '%' + @GlobalFilter + '%' OR
                AircraftModel LIKE '%' + @GlobalFilter + '%' OR
                AircraftSubModel LIKE '%' + @GlobalFilter + '%' OR
                SerialNum LIKE '%' + @GlobalFilter + '%' OR
				Notes LIKE '%' + @GlobalFilter + '%' OR
                PartNumber LIKE '%' + @GlobalFilter + '%' OR
                PartDescription LIKE '%' + @GlobalFilter + '%' OR
				CreatedBy LIKE '%' + @GlobalFilter + '%' OR
				UpdatedBy LIKE '%' + @GlobalFilter + '%'
            ))
            OR
            (@GlobalFilter = '' AND
                --(ISNULL(@AircraftType,0)=0 OR AircraftType = @AircraftType) AND
                --(ISNULL(@AircraftModel,0)=0 OR AircraftModel = @AircraftModel) AND
				(ISNULL(@AircraftType,'')='' OR AircraftType LIKE '%' + @AircraftType + '%') AND
				(ISNULL(@AircraftModel,'')='' OR AircraftModel LIKE '%' + @AircraftModel + '%') AND
                (ISNULL(@AircraftSubModel,'')='' OR AircraftSubModel LIKE '%' + @AircraftSubModel + '%') AND
                (ISNULL(@SerialNum,'')='' OR SerialNum LIKE '%' + @SerialNum + '%') AND
				(ISNULL(@Notes,'')='' OR Notes LIKE '%' + @Notes + '%') AND
                (ISNULL(@PartNumber,'')='' OR PartNumber LIKE '%' + @PartNumber + '%') AND
                (ISNULL(@PartDescription,'')='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
				(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as DATE)=Cast(@CreatedDate as DATE)) AND  
				  (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as DATE)=Cast(@UpdatedDate as DATE)) and  
				  (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
				  (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%')  
            )
        );

        -- Total count
        SELECT @Count = COUNT(*) FROM #TempResult;

        -- Final result with paging
        SELECT *, @Count AS TotalCount
        FROM #TempResult
        ORDER BY
            CASE WHEN @SortOrder = 1 AND @SortColumn = 'AircraftType' THEN AircraftType END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'AircraftType' THEN AircraftType END DESC,

            CASE WHEN @SortOrder = 1 AND @SortColumn = 'AIRCRAFTMODEL' THEN AircraftModel END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'AIRCRAFTMODEL' THEN AircraftModel END DESC,

            CASE WHEN @SortOrder = 1 AND @SortColumn = 'SERIALNUM' THEN SerialNum END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'SERIALNUM' THEN SerialNum END DESC,

			CASE WHEN @SortOrder = 1 AND @SortColumn = 'Notes' THEN Notes END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'Notes' THEN Notes END DESC,

            CASE WHEN @SortOrder = 1 AND @SortColumn = 'PARTNUMBER' THEN PartNumber END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PARTNUMBER' THEN PartNumber END DESC,

			CASE WHEN @SortOrder = 1 AND @SortColumn = 'PartDescription' THEN PartDescription END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PartDescription' THEN PartDescription END DESC,

            CASE WHEN @SortOrder = 1 AND @SortColumn = 'CREATEDDATE' THEN CreatedDate END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CREATEDDATE' THEN CreatedDate END DESC,

			CASE WHEN @SortOrder = 1 AND @SortColumn = 'UpdatedDate' THEN UpdatedDate END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'UpdatedDate' THEN UpdatedDate END DESC,

			CASE WHEN @SortOrder = 1 AND @SortColumn = 'CreatedBy' THEN CreatedBy END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CreatedBy' THEN CreatedBy END DESC,

			CASE WHEN @SortOrder = 1 AND @SortColumn = 'UpdatedBy' THEN UpdatedBy END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'UpdatedBy' THEN UpdatedBy END DESC,

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