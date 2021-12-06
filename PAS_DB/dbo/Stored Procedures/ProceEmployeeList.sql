


CREATE PROCEDURE [dbo].[ProceEmployeeList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@EmployeeCode varchar(50) = NULL,
@FirstName varchar(50) = NULL,
@LastName varchar(50) = NULL,
@Jobtitle varchar(50) = NULL,
@EmployeeExpertise varchar(50) = NULL,
@Company varchar(50) = NULL,
@Paytype varchar(50) = NULL,
@ShopEmployee varchar(50) = NULL,
@StartDate datetime = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@EmployeeId bigint = NULL,
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
		
		--BEGIN TRANSACTION
		--BEGIN

		;WITH Result AS(									
		   	 SELECT DISTINCT t.EmployeeId, 
					t.EmployeeCode,
					t.FirstName,
                    t.LastName,
					(ISNULL(jot.[Description],'')) 'Jobtitle',
					(ISNULL(ee.[Description],'')) 'EmployeeExpertise',
					CASE WHEN t.EmployeeCertifyingStaff = 1 THEN 'Yes' ELSE 'No' END AS ShopEmployee,
				    (ISNULL(t.StartDate,'')) 'StartDate',					
					t.IsActive,
                    t.IsDeleted,
					t.CreatedDate,
                    t.UpdatedDate,
					t.CreatedBy,
                    t.UpdatedBy,					
				    le.[Name] AS Company,
					CASE WHEN t.IsHourly = 1 THEN 'Hourly' ELSE 'Monthly' END AS Paytype					
			   FROM dbo.Employee t WITH (NOLOCK)  LEFT JOIN dbo.EmployeeExpertise ee WITH (NOLOCK) ON t.EmployeeExpertiseId = ee.EmployeeExpertiseId
			                   LEFT JOIN dbo.JobTitle jot WITH (NOLOCK) ON t.JobTitleId = jot.JobTitleId							   
							   LEFT JOIN dbo.LegalEntity le WITH (NOLOCK) ON t.LegalEntityId  = le.LegalEntityId
			                   INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = t.ManagementStructureId		              			  
		 	  WHERE ((t.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR t.IsActive=@IsActive))
			        AND EMS.EmployeeId = @EmployeeId AND t.MasterCompanyId=@MasterCompanyId	
					AND t.FirstName <> 'TBD'
			), ResultCount AS(SELECT COUNT(EmployeeId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((EmployeeCode LIKE '%' +@GlobalFilter+'%') OR
			        (FirstName LIKE '%' +@GlobalFilter+'%') OR	
					(LastName LIKE '%' +@GlobalFilter+'%') OR					
					(Jobtitle LIKE '%' +@GlobalFilter+'%') OR						
					(EmployeeExpertise LIKE '%' +@GlobalFilter+'%') OR						
					(ShopEmployee LIKE '%' +@GlobalFilter+'%') OR										
					(Company LIKE '%' +@GlobalFilter+'%') OR
					(Paytype LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@EmployeeCode,'') ='' OR EmployeeCode LIKE '%' + @EmployeeCode+'%') AND
					(ISNULL(@FirstName,'') ='' OR FirstName LIKE '%' + @FirstName + '%') AND
					(ISNULL(@LastName,'') ='' OR LastName LIKE '%' + @LastName + '%') AND
					(ISNULL(@Jobtitle,'') ='' OR Jobtitle LIKE '%' + @Jobtitle + '%') AND
					(ISNULL(@EmployeeExpertise,'') ='' OR EmployeeExpertise LIKE '%' + @EmployeeExpertise + '%') AND
					(ISNULL(@ShopEmployee,'') ='' OR ShopEmployee LIKE '%' + @ShopEmployee + '%') AND				
					(ISNULL(@Company,'') ='' OR Company LIKE '%' + @Company + '%') AND
					(ISNULL(@Paytype,'') ='' OR Paytype LIKE '%' + @Paytype + '%') AND
					(ISNULL(@StartDate,'') ='' OR CAST(StartDate AS Date)=CAST(@StartDate AS date)) AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(EmployeeId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='EmployeeCode')  THEN EmployeeCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='EmployeeCode')  THEN EmployeeCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='FirstName')  THEN FirstName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='FirstName')  THEN FirstName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LastName')  THEN LastName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LastName')  THEN LastName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Jobtitle')  THEN Jobtitle END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Jobtitle')  THEN Jobtitle END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='EmployeeExpertise')  THEN EmployeeExpertise END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='EmployeeExpertise')  THEN EmployeeExpertise END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ShopEmployee')  THEN ShopEmployee END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ShopEmployee')  THEN ShopEmployee END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Company')  THEN Company END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Company')  THEN Company END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='Paytype')  THEN Paytype END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Paytype')  THEN Paytype END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='StartDate')  THEN StartDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StartDate')  THEN StartDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY

		--END

		--COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			--PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;
            -- temp table drop
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProceEmployeeList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@EmployeeCode, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@FirstName, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@LastName , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@Jobtitle , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@EmployeeExpertise, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@Company, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@Paytype, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@ShopEmployee, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@StartDate , '') AS varchar(100))		  
			  + '@Parameter16 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedBy , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))			
			  + '@Parameter20 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@EmployeeId , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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