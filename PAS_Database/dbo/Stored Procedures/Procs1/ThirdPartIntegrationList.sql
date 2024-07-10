CREATE    PROCEDURE [dbo].[ThirdPartIntegrationList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@Name varchar(50) = NULL,
@CageCode varchar(50) = NULL,
@Description varchar(50) = NULL,
@IntegrationIds varchar(100) = NULL,
@APIURL varchar(50) = NULL,
@SecretKey varchar(50) = NULL,
@AccessKey varchar(50) = NULL,
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

		;WITH Result AS(
				SELECT DISTINCT
						tpi.ThirdPartInegrationId,
						l.LegalEntityId,
                       (ISNULL(Upper(l.[Name]),'')) 'Name' ,
					   (ISNULL(Upper(tpi.CageCode),'')) 'CageCode' ,
					   STUFF(
						(SELECT ', ' + convert(varchar(20), i.Description, 120)
						FROM dbo.[IntegrationPortal] i WITH (NOLOCK)
						where i.IntegrationPortalId in (SELECT Item FROM DBO.SPLITSTRING(tpi.IntegrationIds,','))
						FOR XML PATH (''))
						, 1, 1, '')  AS Description,
					   (ISNULL(tpi.APIURL,'')) 'APIURL', 
					   (ISNULL(tpi.SecretKey,'')) 'SecretKey',   	
					   (ISNULL(tpi.AccessKey,'')) 'AccessKey',  
					   tpi.IntegrationIds,
                       tpi.IsActive,
                       tpi.IsDeleted,
					   tpi.CreatedDate,
                       tpi.UpdatedDate,
					   Upper(tpi.CreatedBy) CreatedBy,
                       Upper(tpi.UpdatedBy) UpdatedBy
			   FROM dbo.ThirdPartInegration tpi WITH (NOLOCK)
									LEFT JOIN dbo.[LegalEntity] l WITH (NOLOCK) ON l.LegalEntityId = tpi.LegalEntityId
		 	  WHERE ((tpi.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR tpi.IsActive=@IsActive))			     
					AND tpi.MasterCompanyId=@MasterCompanyId	
			), ResultCount AS(SELECT COUNT(LegalEntityId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([Name] LIKE '%' +@GlobalFilter+'%') OR
			        (CageCode LIKE '%' +@GlobalFilter+'%') OR	
					(SecretKey LIKE '%' +@GlobalFilter+'%') OR
					(Description LIKE '%' +@GlobalFilter+'%') OR
					(APIURL LIKE '%' +@GlobalFilter+'%') OR
					(Name LIKE '%' +@GlobalFilter+'%') OR
					(AccessKey LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@Name,'') ='' OR [Name] LIKE '%' + @Name+'%') AND
					(ISNULL(@CageCode,'') ='' OR CageCode LIKE '%' + @CageCode + '%') AND	
					(ISNULL(@Description,'') ='' OR Description LIKE '%' + @Description + '%') AND	
					(ISNULL(@APIURL,'') ='' OR APIURL LIKE '%' + @APIURL + '%') AND
					(ISNULL(@SecretKey,'') ='' OR SecretKey LIKE '%' + @SecretKey + '%') AND	
					(ISNULL(@AccessKey,'') ='' OR AccessKey LIKE '%' + @AccessKey + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(LegalEntityId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='Name')  THEN [Name] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Name')  THEN [Name] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CageCode')  THEN CageCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CageCode')  THEN CageCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN Description END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN Description END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='APIURL')  THEN APIURL END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='APIURL')  THEN APIURL END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SecretKey')  THEN SecretKey END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SecretKey')  THEN SecretKey END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AccessKey')  THEN AccessKey END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AccessKey')  THEN AccessKey END DESC,
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
			,@AdhocComments VARCHAR(150) = 'ThirdPartIntegrationList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Name, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@CageCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@APIURL , '') AS varchar(100))	
			   + '@Parameter10 = ''' + CAST(ISNULL(@SecretKey , '') AS varchar(100))		  
			   + '@Parameter11 = ''' + CAST(ISNULL(@AccessKey , '') AS varchar(100))		  
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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