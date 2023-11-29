/*************************************************************           
 ** File:   [USP_BulkStock_GetStockList]           
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used to Get Stock Listing 
 ** Date:   02/10/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date					Author  			Change Description            
 ** --   --------			-------					---------------------------     
    1    02/10/2023			AMIT GHEDIYA			Created
	2    25/10/2023			AMIT GHEDIYA			Add Management Structure wise filter list.
	3    30/10/2023			AMIT GHEDIYA			Get Serialized data when Qty,UnitCost,IntraCompany,InterComapny wise filter list.
*******************************************************************************
*******************************************************************************/
CREATE       PROCEDURE [dbo].[USP_BulkStock_GetStockList] 
	@PageNumber INT = 1,
	@PageSize INT = 10,
	@SortColumn VARCHAR(50)=NULL,
	@SortOrder INT = NULL,
	@GlobalFilter VARCHAR(50) = '',	
	@ReferenceNumber VARCHAR(50) = NULL,
	@PartNumber VARCHAR(50) = NULL,
	@PartDescription VARCHAR(50) = NULL,
	@Manufacturer VARCHAR(50) = NULL,
	@Condition VARCHAR(50) = NULL,
	@ControlNumber VARCHAR(50) = NULL,
	@IdNumber VARCHAR(50) = NULL,
	@QuantityAvailable VARCHAR(50) = NULL,
	@UnitCost VARCHAR(50) = NULL,
	@SerialNumber VARCHAR(100) = NULL,
	@StockLineNumber VARCHAR(50) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@Status VARCHAR(50) = NULL,
	@ManagementStructureId BIGINT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY  
		DECLARE @Count INT;
		DECLARE @RecordFrom INT;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CreatedDate')
			SET @SortOrder = -1
		END 
		ELSE
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
		END

		IF(@Status = 'Quantity')
		BEGIN
			;WITH Result AS (	
				SELECT IM.[partnumber] AS 'PartNumber',
					   IM.[PartDescription],
					   IM.[ItemMasterId],
					   MF.[Name] AS 'Manufacturer',
					   SL.[SerialNumber],
					   SL.[StockLineNumber],
					   SL.[Condition],
					   SL.[ControlNumber],
					   SL.[IdNumber],
					   SL.[QuantityAvailable],
					   SL.[UnitCost],
					   SL.[ManagementStructureId],
					   SL.[StockLineId],
					   SL.[isSerialized],
					   0 AS [IsSelected]
					FROM [dbo].[Stockline] SL WITH (NOLOCK)
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
						LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON SL.[ManufacturerId] = MF.[ManufacturerId]
					WHERE ISNULL(SL.[IsDeleted],0) = 0 AND ISNULL(SL.[IsActive],1) = 1 
					AND SL.[MasterCompanyId] = @MasterCompanyId AND SL.[IsParent] = 1
					AND SL.[QuantityOnHand] > 0 AND SL.[QuantityAvailable] > 0
					AND SL.[IsCustomerStock] = 0 AND IsParent = 1
			), ResultCount AS(SELECT COUNT([StockLineId]) AS totalItems FROM Result) 
		
			SELECT * INTO #TempResult FROM  Result 
				WHERE 
				 ((@GlobalFilter <>'' AND (([PartNumber] LIKE '%' + @GlobalFilter + '%') OR
						([PartDescription] LIKE '%' + @GlobalFilter + '%') OR
						([Manufacturer] LIKE '%' + @GlobalFilter + '%') OR
						([Condition] LIKE '%' + @GlobalFilter + '%') OR
						([ControlNumber] LIKE '%' + @GlobalFilter + '%') OR
						([IdNumber] LIKE '%' + @GlobalFilter + '%') OR
						(CAST([QuantityAvailable] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						(CAST([UnitCost] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						([SerialNumber] LIKE '%' + @GlobalFilter + '%') OR
						([StockLineNumber] LIKE '%' + @GlobalFilter + '%')))					
						OR
						(@GlobalFilter = '' AND (ISNULL(@PartNumber, '') = '' OR [PartNumber] LIKE '%' + @PartNumber + '%') AND
						(ISNULL(@PartDescription, '') = '' OR [PartDescription] LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer, '') = '' OR [Manufacturer] LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@Condition, '') = '' OR [Condition] LIKE '%' + @Condition + '%') AND
						(ISNULL(@ControlNumber, '') = '' OR [ControlNumber] LIKE '%' + @ControlNumber + '%') AND
						(ISNULL(@IdNumber, '') = '' OR [IdNumber] LIKE '%' + @IdNumber + '%') AND
						(ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') = '' OR CAST([QuantityAvailable] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') = '' OR CAST([UnitCost] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(@SerialNumber, '') = '' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@StockLineNumber, '') = '' OR [StockLineNumber] LIKE '%' + @StockLineNumber + '%'))   
					  )

			SELECT @Count = COUNT([StockLineId]) FROM #TempResult

			SELECT @Count AS NumberOfItems, [StockLineId],[isSerialized],[ItemMasterId],[PartNumber],[PartDescription],[Manufacturer],[Condition],[SerialNumber],[QuantityAvailable],[UnitCost],[StockLineNumber],[IdNumber],[ControlNumber],[IsSelected], @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder = 1  AND @SortColumn='PartNumber') THEN PartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='PartDescription') THEN PartDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription') THEN PartDescription END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='Manufacturer') THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='Manufacturer') THEN Manufacturer END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='Condition') THEN Condition END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='Condition') THEN Condition END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='ControlNumber') THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='ControlNumber') THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='IdNumber') THEN IdNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='IdNumber') THEN IdNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='UnitCost') THEN UnitCost END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='UnitCost') THEN UnitCost END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='StockLineNumber') THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='StockLineNumber') THEN StockLineNumber END DESC	
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY	
		END
		ELSE IF(@Status = 'Unit Price')
		BEGIN
			;WITH Result AS (	
				SELECT IM.[partnumber] AS 'PartNumber',
					   IM.[PartDescription],
					   IM.[ItemMasterId],
					   MF.[Name] AS 'Manufacturer',
					   SL.[SerialNumber],
					   SL.[StockLineNumber],
					   SL.[Condition],
					   SL.[ControlNumber],
					   SL.[IdNumber],
					   SL.[QuantityAvailable],
					   SL.[UnitCost],
					   SL.[ManagementStructureId],
					   SL.[StockLineId],
					   SL.[isSerialized],
					   0 AS [IsSelected]
					FROM [dbo].[Stockline] SL WITH (NOLOCK)
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
						LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON SL.[ManufacturerId] = MF.[ManufacturerId]
					WHERE ISNULL(SL.[IsDeleted],0) = 0 AND ISNULL(SL.[IsActive],1) = 1 
					AND SL.[MasterCompanyId] = @MasterCompanyId AND SL.[IsParent] = 1
					AND SL.[QuantityOnHand] > 0 AND SL.[QuantityAvailable] > 0
					AND SL.[IsCustomerStock] = 0 AND IsParent = 1
			), ResultCount AS(SELECT COUNT([StockLineId]) AS totalItems FROM Result) 
		
			SELECT * INTO #TempUnitResult FROM  Result 
				WHERE 
				 ((@GlobalFilter <>'' AND (([PartNumber] LIKE '%' + @GlobalFilter + '%') OR
						([PartDescription] LIKE '%' + @GlobalFilter + '%') OR
						([Manufacturer] LIKE '%' + @GlobalFilter + '%') OR
						([Condition] LIKE '%' + @GlobalFilter + '%') OR
						([ControlNumber] LIKE '%' + @GlobalFilter + '%') OR
						([IdNumber] LIKE '%' + @GlobalFilter + '%') OR
						(CAST([QuantityAvailable] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						(CAST([UnitCost] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						([SerialNumber] LIKE '%' + @GlobalFilter + '%') OR
						([StockLineNumber] LIKE '%' + @GlobalFilter + '%')))					
						OR
						(@GlobalFilter = '' AND (ISNULL(@PartNumber, '') = '' OR [PartNumber] LIKE '%' + @PartNumber + '%') AND
						(ISNULL(@PartDescription, '') = '' OR [PartDescription] LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer, '') = '' OR [Manufacturer] LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@Condition, '') = '' OR [Condition] LIKE '%' + @Condition + '%') AND
						(ISNULL(@ControlNumber, '') = '' OR [ControlNumber] LIKE '%' + @ControlNumber + '%') AND
						(ISNULL(@IdNumber, '') = '' OR [IdNumber] LIKE '%' + @IdNumber + '%') AND
						(ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') = '' OR CAST([QuantityAvailable] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') = '' OR CAST([UnitCost] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(@SerialNumber, '') = '' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@StockLineNumber, '') = '' OR [StockLineNumber] LIKE '%' + @StockLineNumber + '%'))   
					  )

			SELECT @Count = COUNT([StockLineId]) FROM #TempUnitResult

			SELECT @Count AS NumberOfItems, [StockLineId],[isSerialized],[ItemMasterId],[PartNumber],[PartDescription],[Manufacturer],[Condition],[SerialNumber],[QuantityAvailable],[UnitCost],[StockLineNumber],[IdNumber],[ControlNumber],[IsSelected], @Count AS NumberOfItems FROM #TempUnitResult
			ORDER BY  
				CASE WHEN (@SortOrder = 1  AND @SortColumn='PartNumber') THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='PartDescription') THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription') THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='Manufacturer') THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='Manufacturer') THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='Condition') THEN Condition END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='Condition') THEN Condition END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='ControlNumber') THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='ControlNumber') THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='IdNumber') THEN IdNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='IdNumber') THEN IdNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='UnitCost') THEN UnitCost END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='UnitCost') THEN UnitCost END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='StockLineNumber') THEN StockLineNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='StockLineNumber') THEN StockLineNumber END DESC	
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY	
		END
		ELSE IF(@Status = 'Intercompany Transfer' OR @Status = 'Intracompany Transfer')
		BEGIN
			;WITH Result AS (	
				SELECT IM.[partnumber] AS 'PartNumber',
					   IM.[PartDescription],
					   IM.[ItemMasterId],
					   MF.[Name] AS 'Manufacturer',
					   SL.[SerialNumber],
					   SL.[StockLineNumber],
					   SL.[Condition],
					   SL.[ControlNumber],
					   SL.[IdNumber],
					   SL.[QuantityAvailable],
					   SL.[UnitCost],
					   SL.[ManagementStructureId],
					   SL.[StockLineId],
					   SL.[isSerialized],
					   0 AS [IsSelected]
					FROM [dbo].[Stockline] SL WITH (NOLOCK)
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
						LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON SL.[ManufacturerId] = MF.[ManufacturerId]
					WHERE ISNULL(SL.[IsDeleted],0) = 0 AND ISNULL(SL.[IsActive],1) = 1 
					AND SL.[MasterCompanyId] = @MasterCompanyId AND SL.[IsParent] = 1
					AND SL.[QuantityOnHand] > 0 AND SL.[QuantityAvailable] > 0
					AND SL.[IsCustomerStock] = 0 AND SL.[IsParent] = 1 
					AND SL.[ManagementStructureId] = @ManagementStructureId
			), ResultCount AS(SELECT COUNT([StockLineId]) AS totalItems FROM Result) 
		
			SELECT * INTO #TempIntraInterResult FROM  Result 
				WHERE 
				 ((@GlobalFilter <>'' AND (([PartNumber] LIKE '%' + @GlobalFilter + '%') OR
						([PartDescription] LIKE '%' + @GlobalFilter + '%') OR
						([Manufacturer] LIKE '%' + @GlobalFilter + '%') OR
						([Condition] LIKE '%' + @GlobalFilter + '%') OR
						([ControlNumber] LIKE '%' + @GlobalFilter + '%') OR
						([IdNumber] LIKE '%' + @GlobalFilter + '%') OR
						(CAST([QuantityAvailable] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						(CAST([UnitCost] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						([SerialNumber] LIKE '%' + @GlobalFilter + '%') OR
						([StockLineNumber] LIKE '%' + @GlobalFilter + '%')))					
						OR
						(@GlobalFilter = '' AND (ISNULL(@PartNumber, '') = '' OR [PartNumber] LIKE '%' + @PartNumber + '%') AND
						(ISNULL(@PartDescription, '') = '' OR [PartDescription] LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer, '') = '' OR [Manufacturer] LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@Condition, '') = '' OR [Condition] LIKE '%' + @Condition + '%') AND
						(ISNULL(@ControlNumber, '') = '' OR [ControlNumber] LIKE '%' + @ControlNumber + '%') AND
						(ISNULL(@IdNumber, '') = '' OR [IdNumber] LIKE '%' + @IdNumber + '%') AND
						(ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') = '' OR CAST([QuantityAvailable] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') = '' OR CAST([UnitCost] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(@SerialNumber, '') = '' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@StockLineNumber, '') = '' OR [StockLineNumber] LIKE '%' + @StockLineNumber + '%'))   
					  )

			SELECT @Count = COUNT([StockLineId]) FROM #TempIntraInterResult

			SELECT @Count AS NumberOfItems, [StockLineId],[isSerialized],[ItemMasterId],[PartNumber],[PartDescription],[Manufacturer],[Condition],[SerialNumber],[QuantityAvailable],[UnitCost],[StockLineNumber],[IdNumber],[ControlNumber],[IsSelected], @Count AS NumberOfItems FROM #TempIntraInterResult
			ORDER BY  
				CASE WHEN (@SortOrder = 1  AND @SortColumn='PartNumber') THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='PartDescription') THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription') THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='Manufacturer') THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='Manufacturer') THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='Condition') THEN Condition END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='Condition') THEN Condition END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='ControlNumber') THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='ControlNumber') THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='IdNumber') THEN IdNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='IdNumber') THEN IdNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='UnitCost') THEN UnitCost END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='UnitCost') THEN UnitCost END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='StockLineNumber') THEN StockLineNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='StockLineNumber') THEN StockLineNumber END DESC	
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY	
		END
		ELSE
		BEGIN
			;WITH Result AS (	
				SELECT IM.[partnumber] AS 'PartNumber',
					   IM.[PartDescription],
					   IM.[ItemMasterId],
					   MF.[Name] AS 'Manufacturer',
					   SL.[SerialNumber],
					   SL.[StockLineNumber],
					   SL.[Condition],
					   SL.[ControlNumber],
					   SL.[IdNumber],
					   SL.[QuantityAvailable],
					   SL.[UnitCost],
					   SL.[ManagementStructureId],
					   SL.[StockLineId],
					   SL.[isSerialized],
					   0 AS [IsSelected]
					FROM [dbo].[Stockline] SL WITH (NOLOCK)
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
						LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON SL.[ManufacturerId] = MF.[ManufacturerId]
					WHERE ISNULL(SL.[IsDeleted],0) = 0 AND ISNULL(SL.[IsActive],1) = 1 
					AND SL.[MasterCompanyId] = @MasterCompanyId AND SL.[IsParent] = 1
					AND SL.[QuantityOnHand] > 0 AND SL.[QuantityAvailable] > 0
					AND SL.[IsCustomerStock] = 0 AND SL.[isSerialized] = 0 AND SL.[IsParent] = 1 
			), ResultCount AS(SELECT COUNT([StockLineId]) AS totalItems FROM Result) 
		
			SELECT * INTO #TempOtherResult FROM  Result 
				WHERE 
				 ((@GlobalFilter <>'' AND (([PartNumber] LIKE '%' + @GlobalFilter + '%') OR
						([PartDescription] LIKE '%' + @GlobalFilter + '%') OR
						([Manufacturer] LIKE '%' + @GlobalFilter + '%') OR
						([Condition] LIKE '%' + @GlobalFilter + '%') OR
						([ControlNumber] LIKE '%' + @GlobalFilter + '%') OR
						([IdNumber] LIKE '%' + @GlobalFilter + '%') OR
						(CAST([QuantityAvailable] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						(CAST([UnitCost] AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
						([SerialNumber] LIKE '%' + @GlobalFilter + '%') OR
						([StockLineNumber] LIKE '%' + @GlobalFilter + '%')))					
						OR
						(@GlobalFilter = '' AND (ISNULL(@PartNumber, '') = '' OR [PartNumber] LIKE '%' + @PartNumber + '%') AND
						(ISNULL(@PartDescription, '') = '' OR [PartDescription] LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer, '') = '' OR [Manufacturer] LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@Condition, '') = '' OR [Condition] LIKE '%' + @Condition + '%') AND
						(ISNULL(@ControlNumber, '') = '' OR [ControlNumber] LIKE '%' + @ControlNumber + '%') AND
						(ISNULL(@IdNumber, '') = '' OR [IdNumber] LIKE '%' + @IdNumber + '%') AND
						(ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') = '' OR CAST([QuantityAvailable] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') = '' OR CAST([UnitCost] AS VARCHAR(200)) Like '%' +  ISNULL(CAST(@UnitCost AS VARCHAR(200)),'') +'%') AND  
						(ISNULL(@SerialNumber, '') = '' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@StockLineNumber, '') = '' OR [StockLineNumber] LIKE '%' + @StockLineNumber + '%'))   
					  )

			SELECT @Count = COUNT([StockLineId]) FROM #TempOtherResult

			SELECT @Count AS NumberOfItems, [StockLineId],[isSerialized],[ItemMasterId],[PartNumber],[PartDescription],[Manufacturer],[Condition],[SerialNumber],[QuantityAvailable],[UnitCost],[StockLineNumber],[IdNumber],[ControlNumber],[IsSelected], @Count AS NumberOfItems FROM #TempOtherResult
			ORDER BY  
				CASE WHEN (@SortOrder = 1  AND @SortColumn='PartNumber') THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='PartDescription') THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription') THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='Manufacturer') THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='Manufacturer') THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='Condition') THEN Condition END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='Condition') THEN Condition END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='ControlNumber') THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='ControlNumber') THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='IdNumber') THEN IdNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='IdNumber') THEN IdNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='QuantityAvailable') THEN QuantityAvailable END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='UnitCost') THEN UnitCost END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='UnitCost') THEN UnitCost END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn='StockLineNumber') THEN StockLineNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='StockLineNumber') THEN StockLineNumber END DESC	
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY	
		END
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
		    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments VARCHAR(150) = '[USP_BulkStock_GetStockList]'
			,@ProcedureParameters VARCHAR(3000)  = '@PageNumber = '''+ ISNULL(@PageNumber, '') + ''',  
             @PageSize = ' + ISNULL(@PageSize,'') + ',   
             @SortColumn = ' + ISNULL(@SortColumn,'') + ',   
             @SortOrder = ' + ISNULL(@SortOrder,'') + ',   
             @GlobalFilter = ' + ISNULL(@GlobalFilter,'') + ',
			 @ReferenceNumber = ' + ISNULL(@ReferenceNumber,'') + ',
			 @PartNumber = ' + ISNULL(@PartNumber,'') + ',
			 @SerialNumber = ' + ISNULL(@SerialNumber,'') + ',
			 @StockLineNumber = ' + ISNULL(@StockLineNumber,'') + ',
			 @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)) ,'') +''
            ,@ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END