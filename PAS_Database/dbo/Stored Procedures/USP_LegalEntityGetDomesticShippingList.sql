/*************************************************************           
 ** File:		 [USP_LegalEntityGetDomesticShippingList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Domestic Shipping List.
 ** Purpose:         
 ** Date:   13-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    13-June-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityGetDomesticShippingList] @LegalEntityId=1,@EmployeeId=226,@TagName=NULL,@SiteName=NULL,@Attention=NULL,@Address1=NULL,@Address2=NULL,@City=NULL,@State=NULL,
												  @PostalCode=NULL,@Country=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@StatusID=1,@PageSize=10,
												  @PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'' 
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_LegalEntityGetDomesticShippingList]
@LegalEntityId BIGINT,
@EmployeeId BIGINT,
@TagName VARCHAR(250) = NULL,
@SiteName VARCHAR(256),
@Attention VARCHAR(100),
@Address1 VARCHAR(50),
@Address2 VARCHAR(50) = NULL,
@City VARCHAR(50),
@State VARCHAR(50),
@PostalCode VARCHAR(20),
@Country VARCHAR(64),
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2,
@UpdatedBy VARCHAR(256),
@UpdatedDate DATETIME2,
@IsDeleted BIT,
@StatusID INT = NULL,
@PageSize INT,
@PageNumber INT,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT,
@GlobalFilter VARCHAR(100) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT = 1;
		DECLARE @Count INT;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			[DBO].[Employee] E WITH (NOLOCK) 
		LEFT JOIN 
			[DBO].[TimeZone] ETZ WITH (NOLOCK) 
			ON E.[TimeZoneId] = ETZ.[TimeZoneId]
		LEFT JOIN 
			[DBO].[LegalEntity] LE WITH (NOLOCK) 
			ON E.[LegalEntityId] = LE.LegalEntityId
		LEFT JOIN 
			[DBO].[TimeZone] LTZ WITH (NOLOCK) 
			ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE 
			E.[EmployeeId] = @EmployeeId; -- Use appropriate filter for the specific employee	 
			
		IF(@StatusID = 0)
		BEGIN
			SET @IsActive = 0;
		END
		ELSE IF(@StatusID = 1)
		BEGIN
			SET @IsActive = 1;
		END
		ELSE
		BEGIN
			SET @IsActive = NULL;
		END

		SET @RecordFrom = (@PageNumber-1) * @PageSize;
			
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END

		;WITH Result AS(		
			SELECT 
				Shp.[LegalEntityShippingAddressId],
				ISNULL(Shp.[SiteName], '') AS [SiteName],
				ISNULL(Shp.[TagName], '') AS [TagName],
				ISNULL(Shp.[ContactTagId], '') AS [ContactTagId],
				ISNULL(Shp.[Attention], '') AS [Attention],
				ISNULL(Ad.[Line1], '') AS [Address1],
				ISNULL(Ad.[Line2], '') AS [Address2],
				ISNULL(Ad.[City], '') AS [City],
				ISNULL(Ad.[StateOrProvince], '') AS [State],
				ISNULL(Ad.[PostalCode], '') AS [PostalCode],
				ISNULL(Co.[countries_name], '') AS [Country],				
				ISNULL(Co.[countries_id], 0) AS [CountryId],
				ISNULL(Shp.[IsPrimary], 0) AS [IsPrimary],
				Shp.[CreatedBy],			
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(Shp.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(Shp.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(Shp.[CreatedDate] AS DATETIME)) END AS CreatedDate,
				[Shp].[UpdatedBy],			
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(Shp.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(Shp.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(Shp.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
				ISNULL(Shp.[IsActive], 0) AS [IsActive],
				ISNULL(Shp.[IsDeleted], 0) AS [IsDeleted]
			FROM [DBO].[LegalEntityShippingAddress] AS Shp WITH(NOLOCK)
			LEFT JOIN [DBO].[Address] AS Ad WITH (NOLOCK) ON Shp.AddressId = Ad.AddressId
			LEFT JOIN [DBO].[Countries] AS Co WITH (NOLOCK) ON Ad.CountryId = Co.countries_id
			WHERE Shp.LegalEntityId = @LegalEntityId
			AND (@IsActive IS NULL OR Shp.[IsActive] = @IsActive) AND (@IsDeleted IS NULL OR Shp.[IsDeleted] = @IsDeleted))		


		SELECT * INTO #TempResult FROM Result
		WHERE ((@GlobalFilter <>'' AND (([SiteName] LIKE '%' +@GlobalFilter+'%') OR
			([TagName] LIKE '%' +@GlobalFilter+'%') OR
			([Attention] LIKE '%' +@GlobalFilter+'%') OR	
			([Address1] LIKE '%' +@GlobalFilter+'%') OR
			([Address2] LIKE '%' +@GlobalFilter+'%') OR
			([City] LIKE '%' +@GlobalFilter+'%') OR
			([State] LIKE '%' +@GlobalFilter+'%') OR
			([PostalCode] LIKE '%' +@GlobalFilter+'%') OR
			([Country] LIKE '%' +@GlobalFilter+'%') OR
			([CreatedBy] LIKE '%' +@GlobalFilter+'%') OR
			([UpdatedBy] LIKE '%' +@GlobalFilter+'%'))) OR			
			(@GlobalFilter='' AND (ISNULL(@SiteName,'') ='' OR [SiteName] LIKE '%' + @SiteName+'%') AND
			(ISNULL(@TagName,'') ='' OR [TagName] LIKE '%' + @TagName+'%') AND
			(ISNULL(@Attention,'') ='' OR [Attention] LIKE '%' + @Attention+'%') AND
			(ISNULL(@Address1,'') ='' OR [Address1] LIKE '%' + @Address1+'%') AND
			(ISNULL(@Address2,'') ='' OR [Address2] LIKE '%' + @Address2+'%') AND
			(ISNULL(@City,'') ='' OR [City] LIKE '%' + @City+'%') AND
			(ISNULL(@State,'') ='' OR [State] LIKE '%' + @State+'%') AND
			(ISNULL(@PostalCode,'') ='' OR [PostalCode] LIKE '%' + @PostalCode+'%') AND
			(ISNULL(@Country,'') ='' OR [Country] LIKE '%' + @Country+'%') AND			
			(ISNULL(@CreatedBy,'') ='' OR [CreatedBy] LIKE '%' + @CreatedBy+'%') AND
			(ISNULL(@UpdatedBy,'') ='' OR [UpdatedBy] LIKE '%' + @UpdatedBy+'%') AND						
			(ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS Date) = CAST(@CreatedDate AS date)) AND
			(ISNULL(@UpdatedDate,'') ='' OR CAST([UpdatedDate] AS date) = CAST(@UpdatedDate AS date))))

		SELECT @Count = COUNT(*) FROM #TempResult;	

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='TagName') THEN [TagName] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='SiteName') THEN [SiteName] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Attention') THEN [Attention] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Address1') THEN [Address1] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Address2') THEN [Address2] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='City') THEN [City] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='State') THEN [State] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='PostalCode') THEN [PostalCode] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Country') THEN [Country] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy') THEN [CreatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy') THEN [UpdatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate') THEN [CreatedDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate') THEN [UpdatedDate] END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='TagName') THEN [TagName] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='SiteName') THEN [SiteName] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Attention') THEN [Attention] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Address1') THEN [Address1] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Address2') THEN [Address2] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='City') THEN [City] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='State') THEN [State] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='PostalCode') THEN [PostalCode] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Country') THEN [Country] END DESC,		
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy') THEN [CreatedBy] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy') THEN [UpdatedBy] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate') THEN [CreatedDate] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate') THEN [UpdatedDate] END DESC
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityGetDomesticShippingList'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END