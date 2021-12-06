

CREATE PROCEDURE [dbo].[ProcItemMasterStockList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@IsHazardousMaterial  varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@Manufacturerdesc varchar(50) = NULL,
@Classificationdesc varchar(50) = NULL,
@ItemGroup varchar(50) = NULL,
@NationalStockNumber varchar(50) = NULL,
@IsSerialized varchar(50) = NULL,
@IsTimeLife varchar(50) = NULL,
@StockType varchar(50) = NULL,
@ItemType varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END
		IF(@IsHazardousMaterial='')
		BEGIN
			SET @IsHazardousMaterial=NULL;
		END
		
		;WITH Result AS(
				SELECT DISTINCT im.ItemMasterId,
				       im.PartNumber,
					   im.PartDescription,
					   (ISNULL(im.ManufacturerName,'')) 'Manufacturerdesc',
					   im.ItemClassificationName 'Classificationdesc',
					   (ISNULL(im.ItemGroup,'')) 'ItemGroup',
					   im.NationalStockNumber,	
					   CASE WHEN im.IsSerialized = 1 THEN 'Yes' ELSE 'No' END AS IsSerialized,
					   CASE WHEN im.IsTimeLife = 1 THEN 'Yes' ELSE 'No' END AS IsTimeLife,
					   --CAST(im.IsSerialized AS varchar) 'IsSerialized',	
					   --CAST(im.IsTimeLife AS varchar) 'IsTimeLife',
					   im.IsActive,
					   ItemType = CASE WHEN im.ItemTypeId = 1 THEN 'Stock' ELSE 'NonStock' END,					   
					   CAST(im.IsHazardousMaterial AS varchar) 'IsHazardousMaterial',
					   StockType = (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
										 WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' 
					                     WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER' 
										 ELSE 'OEM'
									END),                       
					   im.CreatedDate,
                       im.UpdatedDate,
					   im.CreatedBy,
                       im.UpdatedBy,	
					   im.IsDeleted
			   FROM dbo.ItemMaster im WITH (NOLOCK)		                 
		 	  WHERE ((im.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR im.IsActive=@IsActive) AND (@IsHazardousMaterial IS NULL OR im.IsHazardousMaterial=@IsHazardousMaterial))			     
					AND im.MasterCompanyId=@MasterCompanyId AND im.ItemTypeId = 1 	
			), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(Manufacturerdesc LIKE '%' +@GlobalFilter+'%') OR					
					(Classificationdesc LIKE '%' +@GlobalFilter+'%') OR						
					(ItemGroup LIKE '%' +@GlobalFilter+'%') OR						
					(NationalStockNumber LIKE '%' +@GlobalFilter+'%') OR										
					(IsSerialized LIKE '%' +@GlobalFilter+'%') OR
					(IsTimeLife LIKE '%' +@GlobalFilter+'%') OR
					(ItemType LIKE '%' +@GlobalFilter+'%') OR
					--(IsHazardousMaterial LIKE '%' +@GlobalFilter+'%') OR					
					(StockType LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@Manufacturerdesc,'') ='' OR Manufacturerdesc LIKE '%' + @Manufacturerdesc + '%') AND
					(ISNULL(@Classificationdesc,'') ='' OR Classificationdesc LIKE '%' + @Classificationdesc + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(ISNULL(@NationalStockNumber,'') ='' OR NationalStockNumber LIKE '%' + @NationalStockNumber + '%') AND				
					(ISNULL(@IsSerialized,'') ='' OR IsSerialized LIKE '%' + @IsSerialized + '%') AND
					(ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
					(ISNULL(@ItemType,'') ='' OR ItemType LIKE '%' + @ItemType + '%') AND
					--(ISNULL(@IsHazardousMaterial,'') ='' OR IsHazardousMaterial LIKE '%' + @IsHazardousMaterial + '%') AND					
					(ISNULL(@StockType,'') ='' OR StockType LIKE '%' + @StockType + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(ItemMasterId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Classificationdesc')  THEN Classificationdesc END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Classificationdesc')  THEN Classificationdesc END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ItemType')  THEN ItemType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemType')  THEN ItemType END DESC,
			--CASE WHEN (@SortOrder=1  AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END ASC,
			--CASE WHEN (@SortOrder=-1 AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='StockType')  THEN StockType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StockType')  THEN StockType END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END TRY

	BEGIN CATCH	

		     DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProcItemMasterStockList'
			,@ProcedureParameters VARCHAR(3000) = 
			     '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') as Varchar(100))
				 + ' @Parameter2 = ''' +  CAST(ISNULL(@PageSize, '') as Varchar(100))
				 + ' @Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') as Varchar(100))
				 + ' @Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') as Varchar(100))
				 + ' @Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') as Varchar(100))
				 + ' @Parameter6 = ''' + CAST(ISNULL(@StatusId, '') as Varchar(100))
				 + ' @Parameter7 = ''' + CAST(ISNULL(@IsHazardousMaterial, '') as Varchar(100))
				 + ' @Parameter8 = ''' + CAST(ISNULL(@PartNumber , '') as Varchar(100))
				 + ' @Parameter9 = ''' + CAST(ISNULL(@PartDescription, '') as Varchar(100))
				 + ' @Parameter10 = ''' + CAST(ISNULL(@Manufacturerdesc , '') as Varchar(100))
				 + ' @Parameter11 = ''' + CAST(ISNULL(@Classificationdesc, '') as Varchar(100))
				 + ' @Parameter12 = ''' + CAST(ISNULL(@ItemGroup, '') as Varchar(100))
				 + ' @Parameter13 = ''' + CAST(ISNULL(@IsSerialized  , '') as Varchar(100))
				 + ' @Parameter14 = ''' + CAST(ISNULL(@IsTimeLife   , '') as Varchar(100))
				 + ' @Parameter15 = ''' + CAST(ISNULL(@StockType  , '') as Varchar(100))
				 + ' @Parameter16 = ''' + CAST(ISNULL(@ItemType  , '') as Varchar(100))
				 + ' @Parameter17 = ''' + CAST(ISNULL(@CreatedBy  , '') as Varchar(100))
				 + ' @Parameter18 = ''' + CAST(ISNULL(@CreatedDate   , '') as Varchar(100))
				 + ' @Parameter19 = ''' + CAST(ISNULL(@UpdatedBy   , '') as Varchar(100))
				 + ' @Parameter20 = ''' + CAST(ISNULL(@UpdatedDate    , '') as Varchar(100))
				 + ' @Parameter21 = ''' + CAST(ISNULL(@IsDeleted    , '') as Varchar(100))
				 + ' @Parameter22 = ''' + CAST(ISNULL(@MasterCompanyId   , '') as Varchar(100))
				,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);

	END CATCH
END