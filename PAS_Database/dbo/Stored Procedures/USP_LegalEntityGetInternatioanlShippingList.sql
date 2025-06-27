/*************************************************************           
 ** File:		 [USP_LegalEntityGetInternatioanlShippingList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity International Shipping List.
 ** Purpose:         
 ** Date:   26-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    26-June-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityGetInternatioanlShippingList] @LegalEntityId=41,@EmployeeId=226,@ExportLicense=NULL,@Description=NULL,@StartDate=NULL,@ExpirationDate=NULL,@Amount=NULL,@Country=NULL,
													   @CreatedDate=NULL,@CreatedBy=NULL,@UpdatedDate=NULL,@UpdatedBy=NULL,@IsDeleted=0,@StatusID=1,@PageSize=10,@PageNumber=1,@SortColumn=NULL,
													   @SortOrder=-1,@GlobalFilter=N''
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_LegalEntityGetInternatioanlShippingList]
@LegalEntityId BIGINT,
@EmployeeId BIGINT,
@ExportLicense VARCHAR(200) = NULL,
@Description VARCHAR(250) = NULL,
@StartDate DATETIME,
@ExpirationDate DATETIME,
@Amount VARCHAR(100),
@Country VARCHAR(64),
@CreatedDate DATETIME2,
@CreatedBy VARCHAR(256),
@UpdatedDate DATETIME2,
@UpdatedBy VARCHAR(256),
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
				Shp.[LegalEntityInternationalShippingId],
				Shp.[ExportLicense],
				ISNULL(Shp.[Description], '') AS [Description],
				Shp.[StartDate],
				Shp.[ExpirationDate],
				CAST((CASE WHEN Shp.[Amount] = 0 THEN '' ELSE Shp.[Amount] END) AS VARCHAR) AS Amount,			
				ISNULL(Shcon.[nice_name], '') AS Country,
				CASE WHEN [Shp].[ShipToCountryId] = 0 THEN 0 ELSE Shcon.[countries_id] END AS Countryid,
				CASE WHEN [Shp].[IsPrimary] = 1 THEN 1 ELSE 0 END AS IsPrimary,
				Shp.[CreatedBy],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(Shp.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(Shp.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(Shp.[CreatedDate] AS DATETIME)) END AS CreatedDate,
				Shp.[UpdatedBy],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(Shp.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(Shp.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(Shp.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
				ISNULL(Shp.[IsActive], 0) AS [IsActive],
				ISNULL(Shp.[IsDeleted], 0) AS [IsDeleted]
			FROM [DBO].[LegalEntityInternationalShipping] Shp WITH(NOLOCK)
			LEFT JOIN [DBO].[Countries] Shcon WITH(NOLOCK) ON Shp.[ShipToCountryId] = Shcon.[countries_id]
			WHERE Shp.[LegalEntityId] = @LegalEntityId
			AND (@IsActive IS NULL OR Shp.[IsActive] = @IsActive) AND (@IsDeleted IS NULL OR Shp.[IsDeleted] = @IsDeleted))

		SELECT * INTO #TempResult FROM Result
		WHERE ((@GlobalFilter <>'' AND (([ExportLicense] LIKE '%' +@GlobalFilter+'%') OR
			([Description] LIKE '%' +@GlobalFilter+'%') OR			
			([Amount] LIKE '%' +@GlobalFilter+'%') OR
			([Country] LIKE '%' +@GlobalFilter+'%') OR
			([CreatedBy] LIKE '%' +@GlobalFilter+'%') OR
			([UpdatedBy] LIKE '%' +@GlobalFilter+'%'))) OR			
			(@GlobalFilter='' AND (ISNULL(@ExportLicense,'') ='' OR [ExportLicense] LIKE '%' + @ExportLicense+'%') AND
			(ISNULL(@Description,'') ='' OR [Description] LIKE '%' + @Description+'%') AND
			(ISNULL(@StartDate,'') ='' OR CAST([StartDate] AS Date) = CAST(@StartDate AS date)) AND
			(ISNULL(@ExpirationDate,'') ='' OR CAST([ExpirationDate] AS Date) = CAST(@ExpirationDate AS date)) AND
			(ISNULL(@Amount,'') ='' OR [Amount] LIKE '%' + @Amount+'%') AND
			(ISNULL(@Country,'') ='' OR [Country] LIKE '%' + @Country+'%') AND
			(ISNULL(@CreatedBy,'') ='' OR [CreatedBy] LIKE '%' + @CreatedBy+'%') AND
			(ISNULL(@UpdatedBy,'') ='' OR [UpdatedBy] LIKE '%' + @UpdatedBy+'%') AND						
			(ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS Date) = CAST(@CreatedDate AS date)) AND
			(ISNULL(@UpdatedDate,'') ='' OR CAST([UpdatedDate] AS date) = CAST(@UpdatedDate AS date))))

		SELECT @Count = COUNT(*) FROM #TempResult;	

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='ExportLicense') THEN [ExportLicense] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Description') THEN [Description] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='StartDate') THEN [StartDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='ExpirationDate') THEN [ExpirationDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Amount') THEN [Amount] END ASC,	
		CASE WHEN (@SortOrder=1 AND @SortColumn='Country') THEN [Country] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate') THEN [CreatedDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy') THEN [CreatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate') THEN [UpdatedDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy') THEN [UpdatedBy] END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ExportLicense') THEN [ExportLicense] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Description') THEN [Description] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='StartDate') THEN [StartDate] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate') THEN [ExpirationDate] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount') THEN [Amount] END DESC,		
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Country') THEN [Country] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate') THEN [CreatedDate] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy') THEN [CreatedBy] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate') THEN [UpdatedDate] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy') THEN [UpdatedBy] END DESC		
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityGetInternatioanlShippingList'
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