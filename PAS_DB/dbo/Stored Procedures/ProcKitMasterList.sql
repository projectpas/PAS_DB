/*
exec ProcKitMasterList @PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@ItemMasterId=20372,@PartNumber=NULL,@PartDescription=NULL,@Manufacturer=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@MasterCompanyId=1
*/
CREATE   PROCEDURE [dbo].[ProcKitMasterList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@ItemMasterId bigint = NULL,
@KitNumber varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@Manufacturer varchar(50) = NULL,
@CustomerName varchar(50) = NULL,
@Qty varchar(50) = NULL,
@UnitCost varchar(50) = NULL,
@StocklineUnitCost varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@listtype varchar(50) = NULL,
@WorkScopeName varchar(50) = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

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

		IF(@listtype='all')
		BEGIN
			SET @ItemMasterId=0
		END 

		--IF(@Qty=0)
		--BEGIN
		--	SET @Qty= null
		--END 
		--IF(@UnitCost=0)
		--BEGIN
		--	SET @UnitCost=null
		--END 
		--IF(@StocklineUnitCost=0)
		--BEGIN
		--	SET @StocklineUnitCost=null
		--END 

		;WITH Result AS(
				SELECT DISTINCT
					  kitm.KitId,
					  kitm.KitNumber,
					  kitm.ItemMasterId,
				      kitm.PartNumber,
					  kitm.PartDescription,
					  kitm.Manufacturer,
					  kitm.CustomerId,
					  kitm.CustomerName AS customerName,
					  wos.WorkScopeCode AS WorkScopeName,
					  kitm.KitCost,
					  kitm.KitCost AS UnitCost,
					  (SELECT ISNULL(COUNT(kimm.KitItemMasterMappingId),0) FROM [dbo].[KitItemMasterMapping] kimm WITH (NOLOCK) WHERE kimm.KitId = kitm.KitId AND kimm.IsDeleted = 0) AS Qty,
					  --(SELECT ISNULL(SUM(ISNULL(kimm.StocklineUnitCost,0)),0) FROM DBO.KitItemMasterMapping kimm WITH (NOLOCK) WHERE kimm.KitId = kitm.KitId AND kimm.IsDeleted = 0) AS StocklineUnitCost,
					  --(SELECT TOP 1 ISNULL(SUM(ISNULL(STL.UnitCost,0)),0) FROM [dbo].[KitItemMasterMapping] KIM WITH (NOLOCK) 
							--LEFT JOIN [dbo].[Stockline] STL WITH (NOLOCK) ON KIM.ItemMasterId = STL.ItemMasterId AND KIM.ConditionId = STL.ConditionId
							--WHERE KIM.KitId = kitm.KitId AND KIM.IsDeleted = 0) AS StocklineUnitCost,
					  0 AS StocklineUnitCost,
					  kitm.IsActive,
					  kitm.CreatedDate,
                      kitm.UpdatedDate,
					  kitm.CreatedBy,
                      kitm.UpdatedBy,
					  kitm.IsDeleted
			   FROM [dbo].[KitMaster] kitm WITH (NOLOCK)
			   LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON kitm.WorkScopeId=wos.WorkScopeId
		 	  WHERE ((kitm.IsDeleted = @IsDeleted) AND (@IsActive IS NULL OR kitm.IsActive = @IsActive))			     
					AND kitm.MasterCompanyId = @MasterCompanyId AND (@ItemMasterId = 0 OR kitm.ItemMasterId = @ItemMasterId)
			), ResultCount AS(SELECT COUNT(KitId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(Manufacturer LIKE '%' +@GlobalFilter+'%') OR
					(KitNumber LIKE '%' +@GlobalFilter+'%') OR
					(UnitCost LIKE '%' +@GlobalFilter+'%') OR
					(StocklineUnitCost LIKE '%' +@GlobalFilter+'%') OR
					(Qty LIKE '%' +@GlobalFilter+'%') OR
					(CustomerName LIKE '%' +@GlobalFilter+'%') OR
					(WorkScopeName LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
					(ISNULL(@KitNumber,'') ='' OR KitNumber LIKE '%' + @KitNumber + '%') AND
					(ISNULL(@WorkScopeName,'') ='' OR WorkScopeName LIKE '%' + @WorkScopeName + '%') AND
					(IsNull(@Qty,'') ='' OR  Qty= @Qty) AND 
		            (IsNull(@UnitCost,'') ='' OR UnitCost= @UnitCost) AND 
					(IsNull(@StocklineUnitCost,'') ='' OR StocklineUnitCost= @StocklineUnitCost) AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)))
				   )

			SELECT @Count = COUNT(ItemMasterId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScopeName')  THEN WorkScopeName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScopeName')  THEN WorkScopeName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END DESC,
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
			,@AdhocComments VARCHAR(150) = 'ProcKitMasterList'
			,@ProcedureParameters VARCHAR(3000) = 
			     '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') as Varchar(100))
				 + ' @Parameter2 = ''' +  CAST(ISNULL(@PageSize, '') as Varchar(100))
				 + ' @Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') as Varchar(100))
				 + ' @Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') as Varchar(100))
				 + ' @Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') as Varchar(100))
				 + ' @Parameter8 = ''' + CAST(ISNULL(@PartNumber , '') as Varchar(100))
				 + ' @Parameter9 = ''' + CAST(ISNULL(@PartDescription, '') as Varchar(100))
				 + ' @Parameter10 = ''' + CAST(ISNULL(@Manufacturer , '') as Varchar(100))
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
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END