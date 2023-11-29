

CREATE PROCEDURE [dbo].[ProcLegalEntityList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@Name varchar(50) = NULL,
@CompanyName varchar(50) = NULL,
@CompanyCode varchar(50) = NULL,
@Address1 varchar(50) = NULL,
@Address2 varchar(50) = NULL,
@MasterCompany varchar(50) = NULL,
@City varchar(50) = NULL,
@StateOrProvince varchar(50) = NULL,
@PostalCode varchar(50) = NULL,
@Country varchar(50) = NULL,
@PhoneNumber varchar(50) = NULL,
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
		
		--BEGIN TRANSACTION
		--BEGIN

		;WITH Result AS(
				SELECT DISTINCT t.LegalEntityId,
                       (ISNULL(Upper(t.[Name]),'')) 'Name' ,
					   (ISNULL(Upper(t.CompanyCode),'')) 'CompanyCode' ,
                       (ISNULL(t.[Name],'')) 'MasterCompany' ,
					   (ISNULL(Upper(ad.Line1),'')) 'Address1',
					   (ISNULL(Upper(ad.Line2),'')) 'Address2',
					   (ISNULL(Upper(ad.City),'')) 'City',                      
                       (ISNULL(Upper(ad.StateOrProvince),'')) 'StateOrProvince',      
                       (ISNULL(ad.PostalCode,'')) 'PostalCode',
					   (ISNULL(cont.countries_name,'')) 'Country',
					   (ISNULL(t.PhoneNumber,'')) 'PhoneNumber',
					   (ISNULL(atd.Link,'')) 'Link',  
					   (ISNULL(t.CompanyName,'')) 'CompanyName',	
                       t.IsActive,
                       t.IsDeleted,
					   t.CreatedDate,
                       t.UpdatedDate,
					   Upper(t.CreatedBy) CreatedBy,
                       Upper(t.UpdatedBy) UpdatedBy			
			   FROM dbo.LegalEntity t WITH (NOLOCK) LEFT JOIN dbo.[Address] ad WITH (NOLOCK) ON t.AddressId = ad.AddressId
									  LEFT JOIN dbo.[Countries] cont WITH (NOLOCK) ON ad.CountryId = cont.countries_id							   
							          LEFT JOIN dbo.[AttachmentDetails] atd WITH (NOLOCK) ON t.AttachmentId = atd.AttachmentId 			                 
		 	  WHERE ((t.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR t.IsActive=@IsActive))			     
					AND t.MasterCompanyId=@MasterCompanyId	
			), ResultCount AS(SELECT COUNT(LegalEntityId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([Name] LIKE '%' +@GlobalFilter+'%') OR
			        (CompanyCode LIKE '%' +@GlobalFilter+'%') OR	
					(MasterCompany LIKE '%' +@GlobalFilter+'%') OR					
					(Address1 LIKE '%' +@GlobalFilter+'%') OR						
					(Address2 LIKE '%' +@GlobalFilter+'%') OR						
					(City LIKE '%' +@GlobalFilter+'%') OR										
					(StateOrProvince LIKE '%' +@GlobalFilter+'%') OR
					(PostalCode LIKE '%' +@GlobalFilter+'%') OR
					(Country LIKE '%' +@GlobalFilter+'%') OR
					(PhoneNumber LIKE '%' +@GlobalFilter+'%') OR					
					(CompanyName LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@Name,'') ='' OR [Name] LIKE '%' + @Name+'%') AND
					(ISNULL(@CompanyCode,'') ='' OR CompanyCode LIKE '%' + @CompanyCode + '%') AND
					(ISNULL(@MasterCompany,'') ='' OR MasterCompany LIKE '%' + @MasterCompany + '%') AND
					(ISNULL(@Address1,'') ='' OR Address1 LIKE '%' + @Address1 + '%') AND
					(ISNULL(@Address2,'') ='' OR Address2 LIKE '%' + @Address2 + '%') AND
					(ISNULL(@City,'') ='' OR City LIKE '%' + @City + '%') AND				
					(ISNULL(@StateOrProvince,'') ='' OR StateOrProvince LIKE '%' + @StateOrProvince + '%') AND
					(ISNULL(@PostalCode,'') ='' OR PostalCode LIKE '%' + @PostalCode + '%') AND
					(ISNULL(@Country,'') ='' OR Country LIKE '%' + @Country + '%') AND
					(ISNULL(@PhoneNumber,'') ='' OR PhoneNumber LIKE '%' + @PhoneNumber + '%') AND					
					(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(LegalEntityId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='Name')  THEN [Name] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Name')  THEN [Name] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyCode')  THEN CompanyCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyCode')  THEN CompanyCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MasterCompany')  THEN MasterCompany END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MasterCompany')  THEN MasterCompany END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Address1')  THEN Address1 END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Address1')  THEN Address1 END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Address2')  THEN Address2 END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Address2')  THEN Address2 END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='StateOrProvince')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StateOrProvince')  THEN StateOrProvince END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='PostalCode')  THEN PostalCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PostalCode')  THEN PostalCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Country')  THEN Country END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Country')  THEN Country END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PhoneNumber')  THEN PhoneNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PhoneNumber')  THEN PhoneNumber END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,			
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
			,@AdhocComments VARCHAR(150) = 'ProcLegalEntityList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Name, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@CompanyName, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@CompanyCode , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@Address1 , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@Address2, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@MasterCompany, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@City, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@StateOrProvince, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@PostalCode , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@Country , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@PhoneNumber , '') AS varchar(100))		  
			  + '@Parameter18 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter23 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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