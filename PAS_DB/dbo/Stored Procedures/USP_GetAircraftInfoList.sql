/*************************************************************
 ** File:        [USP_GetAircraftInfoList]
 ** Author:      Nakul
 ** Description: Returns the tenant-scoped, paginated Aircraft Profile list.
 ** Date:        14/07/2026
 *************************************************************
 ** Change History
 *************************************************************
 ** PR   Date         Author   Change Description
 ** --   ----------   -------  ------------------------------------------
 ** 1    15/07/2026   Nakul    Created Aircraft Profile list procedure.[PN-17264]
 *************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAircraftInfoList]
    @PageNumber       INT          = 1,
    @PageSize         INT          = 10,
    @SortColumn       VARCHAR(50)  = 'aircraftInfoId',
    @SortOrder        VARCHAR(4)   = 'DESC',
    @GlobalFilter     VARCHAR(100) = NULL,
    @MakeType         VARCHAR(100) = NULL,
    @Manufacturer     VARCHAR(100) = NULL,
    @AircraftModel    VARCHAR(100) = NULL,
    @AircraftSubModel VARCHAR(100) = NULL,
    @IsSerialized     BIT          = NULL,
    @IsTimeLife       BIT          = NULL,
    @CreatedBy        VARCHAR(100) = NULL,
    @CreatedDate      DATE         = NULL,
    @UpdatedBy        VARCHAR(100) = NULL,
    @UpdatedDate      DATE         = NULL,
    @MasterCompanyId  INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @PageNumber = CASE WHEN @PageNumber < 1 THEN 1 ELSE @PageNumber END;
        SET @PageSize = CASE WHEN @PageSize < 1 THEN 10 WHEN @PageSize > 500 THEN 500 ELSE @PageSize END;
        SET @SortOrder = CASE WHEN UPPER(@SortOrder) = 'ASC' THEN 'ASC' ELSE 'DESC' END;

        ;WITH AircraftProfiles AS
        (
            SELECT
                AI.AircraftInfoId,
                AI.ACMakeTypeName AS MakeType,
                M.Name AS Manufacturer,
                AI.ACModelName AS AircraftModel,
                AI.ACSubModel AS AircraftSubModel,
                IM.IsSerialized,
                IM.IsTimeLife,
                AI.CreatedBy,
                AI.CreatedDate,
                AI.UpdatedBy,
                AI.UpdatedDate,
                COUNT_BIG(1) OVER () AS TotalRecords
            FROM dbo.AircraftInfo AS AI
            INNER JOIN dbo.ItemMaster AS IM
                ON IM.ItemMasterId = AI.ItemMasterId
                AND IM.MasterCompanyId = AI.MasterCompanyId
            LEFT JOIN dbo.Manufacturer AS M
                ON M.ManufacturerId = IM.ManufacturerId
                AND M.MasterCompanyId = AI.MasterCompanyId
                AND M.IsDeleted = 0
            WHERE AI.MasterCompanyId = @MasterCompanyId
                AND IM.IsDeleted = 0
                AND AI.IsDeleted = 0
                AND (
                    @GlobalFilter IS NULL
                    OR AI.ACMakeTypeName LIKE '%' + @GlobalFilter + '%'
                    OR M.Name LIKE '%' + @GlobalFilter + '%'
                    OR AI.ACModelName LIKE '%' + @GlobalFilter + '%'
                    OR AI.ACSubModel LIKE '%' + @GlobalFilter + '%'
                    OR AI.CreatedBy LIKE '%' + @GlobalFilter + '%'
                    OR AI.UpdatedBy LIKE '%' + @GlobalFilter + '%'
                )
                AND (@MakeType IS NULL OR AI.ACMakeTypeName LIKE '%' + @MakeType + '%')
                AND (@Manufacturer IS NULL OR M.Name LIKE '%' + @Manufacturer + '%')
                AND (@AircraftModel IS NULL OR AI.ACModelName LIKE '%' + @AircraftModel + '%')
                AND (@AircraftSubModel IS NULL OR AI.ACSubModel LIKE '%' + @AircraftSubModel + '%')
                AND (@IsSerialized IS NULL OR IM.IsSerialized = @IsSerialized)
                AND (@IsTimeLife IS NULL OR IM.IsTimeLife = @IsTimeLife)
                AND (@CreatedBy IS NULL OR AI.CreatedBy LIKE '%' + @CreatedBy + '%')
                AND (@CreatedDate IS NULL OR CAST(AI.CreatedDate AS DATE) = @CreatedDate)
                AND (@UpdatedBy IS NULL OR AI.UpdatedBy LIKE '%' + @UpdatedBy + '%')
                AND (@UpdatedDate IS NULL OR CAST(AI.UpdatedDate AS DATE) = @UpdatedDate)
        )
        SELECT
            MakeType,
            Manufacturer,
            AircraftModel,
            AircraftSubModel,
            IsSerialized,
            IsTimeLife,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            TotalRecords
        FROM AircraftProfiles
        ORDER BY
            CASE WHEN @SortColumn = 'makeType' AND @SortOrder = 'ASC' THEN MakeType END ASC,
            CASE WHEN @SortColumn = 'makeType' AND @SortOrder = 'DESC' THEN MakeType END DESC,
            CASE WHEN @SortColumn = 'manufacturer' AND @SortOrder = 'ASC' THEN Manufacturer END ASC,
            CASE WHEN @SortColumn = 'manufacturer' AND @SortOrder = 'DESC' THEN Manufacturer END DESC,
            CASE WHEN @SortColumn = 'aircraftModel' AND @SortOrder = 'ASC' THEN AircraftModel END ASC,
            CASE WHEN @SortColumn = 'aircraftModel' AND @SortOrder = 'DESC' THEN AircraftModel END DESC,
            CASE WHEN @SortColumn = 'aircraftSubModel' AND @SortOrder = 'ASC' THEN AircraftSubModel END ASC,
            CASE WHEN @SortColumn = 'aircraftSubModel' AND @SortOrder = 'DESC' THEN AircraftSubModel END DESC,
            CASE WHEN @SortColumn = 'isSerialized' AND @SortOrder = 'ASC' THEN IsSerialized END ASC,
            CASE WHEN @SortColumn = 'isSerialized' AND @SortOrder = 'DESC' THEN IsSerialized END DESC,
            CASE WHEN @SortColumn = 'isTimeLife' AND @SortOrder = 'ASC' THEN IsTimeLife END ASC,
            CASE WHEN @SortColumn = 'isTimeLife' AND @SortOrder = 'DESC' THEN IsTimeLife END DESC,
            CASE WHEN @SortColumn = 'createdBy' AND @SortOrder = 'ASC' THEN CreatedBy END ASC,
            CASE WHEN @SortColumn = 'createdBy' AND @SortOrder = 'DESC' THEN CreatedBy END DESC,
            CASE WHEN @SortColumn = 'createdDate' AND @SortOrder = 'ASC' THEN CreatedDate END ASC,
            CASE WHEN @SortColumn = 'createdDate' AND @SortOrder = 'DESC' THEN CreatedDate END DESC,
            CASE WHEN @SortColumn = 'updatedBy' AND @SortOrder = 'ASC' THEN UpdatedBy END ASC,
            CASE WHEN @SortColumn = 'updatedBy' AND @SortOrder = 'DESC' THEN UpdatedBy END DESC,
            CASE WHEN @SortColumn = 'updatedDate' AND @SortOrder = 'ASC' THEN UpdatedDate END ASC,
            CASE WHEN @SortColumn = 'updatedDate' AND @SortOrder = 'DESC' THEN UpdatedDate END DESC,
            CASE WHEN @SortColumn = 'aircraftInfoId' AND @SortOrder = 'ASC' THEN AircraftInfoId END ASC,
            AircraftInfoId DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments VARCHAR(150) = 'USP_GetAircraftInfoList',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL')
                + ', @PageNumber = ' + ISNULL(CAST(@PageNumber AS VARCHAR(20)), 'NULL'),
            @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
                exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   =  @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
        END CATCH  
END;