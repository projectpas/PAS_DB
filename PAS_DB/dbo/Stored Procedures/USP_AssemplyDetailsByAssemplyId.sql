/*************************************************************           
 ** File:   [USP_AssemplyDetailsByAssemplyId]           
 ** Author:   BHARGAV SALIYA
 ** Description: This stored procedure is used AssemplyDetailsList for get Assemply details
 ** Purpose:         
 ** Date:   09 Nov 2023      
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    09 Nov 2023   BHARGAV SALIYA               Created
    2    21 Now 2023   BHARGAV SALIYA               MappingItemMasterId                                              
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AssemplyDetailsByAssemplyId]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,

@Partnumber varchar(50) = NULL,
@PartDescription varchar(50) = null,
@Quantity varchar(50) = NULL,
@PopulateWoMaterialList varchar(50) = NULL,
@WorkScope varchar(50) = null,
@Provision varchar(50) = null,
@Memo varchar(500) = null,
@MasterCompanyId BIGINT = NULL, 
@ItemMasterId  BIGINT, 
@MappingItemMasterId INT = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL
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

		print 11
			;WITH Result AS(
				SELECT DISTINCT
						AP.AssemplyId,
						IM.ItemMasterId,
						AP.MappingItemMasterId,
						IM.Partnumber,
						IMP.Partnumber AS AltPartNo,
						IMP.PartDescription,
						AP.Quantity,
						case when AP.PopulateWoMaterialList = 1 then 'yes' else 'no' end as PopulateWoMaterialList,
						AP.WorkScopeId,
						AP.ProvisionId,
						WS.WorkScopeCode AS WorkScope,
						PS.Description AS Provision,
						AP.Memo,
						AP.CreatedDate,
						AP.UpdatedDate,
						Upper(AP.CreatedBy) AS CreatedBy,
						Upper(AP.UpdatedBy) AS UpdatedBy,
						AP.IsActive,
						AP.IsDeleted
				FROM [dbo].[Assemply] AP WITH (NOLOCK)
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = AP.ItemMasterId
				INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON AP.MappingItemMasterId = IMP.ItemMasterId
				LEFT JOIN [dbo].[WorkScope] WS WITH (NOLOCK) ON WS.WorkScopeId = AP.WorkScopeId
				LEFT JOIN [dbo].[Provision] PS WITH (NOLOCK) ON PS.ProvisionId = AP.ProvisionId

				WHERE ((AP.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR AP.IsActive=@IsActive)) AND AP.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId = @ItemMasterId
				
			), ResultCount AS(SELECT COUNT(AssemplyId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((Partnumber LIKE '%' +@GlobalFilter+'%') OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(CAST(Quantity AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR
					(PopulateWoMaterialList LIKE '%' +@GlobalFilter+'%') OR
					(WorkScope LIKE '%' +@GlobalFilter+'%') OR
					(Provision LIKE '%' +@GlobalFilter+'%') OR
					(Memo LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@Partnumber,'') ='' OR Partnumber LIKE '%' + @Partnumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND	
					(ISNULL(@Quantity,'') ='' OR CAST(Quantity AS VARCHAR) LIKE '%' + @Quantity + '%') AND	
					(ISNULL(@PopulateWoMaterialList,'') ='' OR PopulateWoMaterialList LIKE '%' + @PopulateWoMaterialList + '%') AND
					(ISNULL(@WorkScope,'') ='' OR WorkScope LIKE '%' + @WorkScope + '%') AND
					(ISNULL(@Provision,'') ='' OR Provision LIKE '%' + @Provision + '%') AND
					(ISNULL(@Memo,'') ='' OR Memo LIKE '%' + @Memo + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					)

			SELECT @Count = COUNT(AssemplyId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='Partnumber')  THEN Partnumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Partnumber')  THEN Partnumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Quantity')  THEN Quantity END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Quantity')  THEN Quantity END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PopulateWoMaterialList')  THEN PopulateWoMaterialList END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PopulateWoMaterialList')  THEN PopulateWoMaterialList END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScope')  THEN WorkScope END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScope')  THEN WorkScope END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Provision')  THEN Provision END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Provision')  THEN Provision END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Memo')  THEN Memo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Memo')  THEN Memo END DESC,
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
			,@AdhocComments VARCHAR(150) = 'USP_AssemplyDetailsByAssemplyId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Partnumber, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@PartDescription, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@Quantity, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@PopulateWoMaterialList , '') AS varchar(100))	
			   + '@Parameter11 = ''' + CAST(ISNULL(@WorkScope , '') AS varchar(100))		  
			  + '@Parameter18 = ''' + CAST(ISNULL(@Provision, '') AS varchar(100))	                                           
			  + '@Parameter19 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))	                                           
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))	                                           
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
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