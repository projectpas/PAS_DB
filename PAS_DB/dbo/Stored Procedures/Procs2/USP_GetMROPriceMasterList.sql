/*********************           
 ** File:   [USP_GetMROPriceMasterList]         
 ** Author: Priyansh Patel
 ** Description: This stored procedure returns all MRO Price Master records
 **               
 ** Date:  27/10/2025

 **********************           
  ** Change History           
 **********************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    27/10/2025    Priyansh Patel   Created
	2	 10/11/2025	   Priyansh Patel	Updated column name UnitPrice to FlatRatePrice
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

**********************/
-- Example: EXEC [USP_GetMROPriceMasterList] 0, 0, 1, 1, 10

CREATE PROCEDURE [dbo].[USP_GetMROPriceMasterList] 
    @ItemMasterId BIGINT = NULL, 
    @IsDeleted BIT = 0,
    @MasterCompanyId INT,
    @PageNumber INT = 1,         
    @PageSize INT = 10 ,
    @HasChild BIT = 0
	
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

        BEGIN TRY
           DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

			IF @ItemMasterId=0
			BEGIN
				SET @ItemMasterId=NULL
			END

				IF OBJECT_ID('tempdb..#PagedParents') IS NOT NULL
					DROP TABLE #PagedParents;

				CREATE TABLE #PagedParents
					(
						ItemMasterId INT,
						PartNumber NVARCHAR(100),           
						PartDescription NVARCHAR(MAX),    
						ManufacturerName NVARCHAR(255)      
					);


				IF @HasChild = 0
				BEGIN
					;WITH ParentCTE AS (
						SELECT 
							IM.ItemMasterId,
							IM.PartNumber,
							IM.PartDescription,
							IM.ManufacturerName,
							ROW_NUMBER() OVER (ORDER BY IM.ItemMasterId Desc) AS RowNum
						FROM dbo.ItemMaster IM WITH (NOLOCK)
						WHERE 
							IM.MasterCompanyId = @MasterCompanyId
							AND (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)
							AND IM.IsActive = 1
							AND IM.IsDeleted = @IsDeleted
					 AND ISNULL(IM.IsNonStock,0) = 0 )
					INSERT INTO #PagedParents (ItemMasterId, PartNumber, PartDescription, ManufacturerName)
					SELECT 
						ItemMasterId, 
						PartNumber, 
						PartDescription, 
						ManufacturerName
					FROM ParentCTE
					WHERE RowNum > @Offset AND RowNum <= (@Offset + @PageSize);
				END
				ELSE
				BEGIN
					INSERT INTO #PagedParents (ItemMasterId, PartNumber, PartDescription, ManufacturerName)
					SELECT DISTINCT
						IM.ItemMasterId,
						IM.PartNumber,
						IM.PartDescription,
						IM.ManufacturerName
					FROM dbo.ItemMaster IM WITH (NOLOCK)
					INNER JOIN dbo.MROPriceMaster MPM WITH (NOLOCK)
						ON IM.ItemMasterId = MPM.ItemMasterId
						AND (MPM.IsActive = 1 OR MPM.IsActive IS NULL)
						AND (MPM.IsDeleted = @IsDeleted OR MPM.IsDeleted IS NULL)
					WHERE 
						 (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)
						AND IM.MasterCompanyId = @MasterCompanyId
						AND IM.IsActive = 1
						AND IM.IsDeleted = @IsDeleted AND ISNULL(IM.IsNonStock,0) = 0 ;
				END



    -- Get child records
    SELECT 
        MPM.MROPriceMasterId,
        IM.ItemMasterId,
        UPPER(IM.PartNumber) AS PartNumber,
        UPPER(IM.PartDescription) AS PartDescription,
        UPPER(IM.ManufacturerName) AS ManufacturerName,
        MPM.MasterCompanyId,
        MPM.CustomerId,
        MPM.WorkscopeId,
        MPM.FlatRatePrice,
        MPM.CurrencyId,
        MPM.StartDate,
        MPM.EndDate,
        MPM.CreatedBy,
        MPM.CreatedDate,
        MPM.UpdatedBy,
        MPM.UpdatedDate,
        MPM.IsActive,
        MPM.IsDeleted
    FROM dbo.ItemMaster IM WITH (NOLOCK)
    LEFT JOIN dbo.MROPriceMaster MPM WITH (NOLOCK)
        ON IM.ItemMasterId = MPM.ItemMasterId
		AND ( MPM.IsActive IS NULL OR  MPM.IsActive = 1) 
		AND ( MPM.IsDeleted IS NULL OR  MPM.IsDeleted = @IsDeleted)
    WHERE 
        IM.ItemMasterId IN (SELECT ItemMasterId FROM #PagedParents)
        AND IM.MasterCompanyId = @MasterCompanyId
        AND IM.IsActive = 1
        AND IM.IsDeleted = @IsDeleted
		
     AND ISNULL(IM.IsNonStock,0) = 0 ORDER BY IM.ItemMasterId DESC;

    -- Total count
    SELECT COUNT(DISTINCT IM.ItemMasterId) AS TotalRecords
    FROM dbo.ItemMaster IM WITH (NOLOCK)
    WHERE 
		 (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)
       AND IM.MasterCompanyId = @MasterCompanyId
        AND IM.IsActive = 1
        AND IM.IsDeleted = @IsDeleted AND ISNULL(IM.IsNonStock,0) = 0 ;

    END TRY


 BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
		-----------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = '[USP_GetMROPriceMasterList]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@ItemMasterId=''' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(100)) + ''',
                     @MasterCompanyId=''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''',
                     @IsDeleted=''' + CAST(ISNULL(@IsDeleted, 0) AS VARCHAR(100)) + ''',
					 @PageNumber=''' + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(100)) + ''',
                     @PageSize=''' + CAST(ISNULL(@PageSize, 0) AS VARCHAR(100)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END