/*************************************************************           
 ** File:		 [USP_LegalEntityGetDomesticShipViaList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Domestic Shipvia List.
 ** Purpose:         
 ** Date:   19-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    19-June-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityGetDomesticShipViaList] @LegalEntityShippingAddressId=51,@EmployeeId=226,@Shipvia=NULL,@ShipAccountinfo=NULL,@ShippingTerms=NULL,@Memo=NULL,@CreatedBy=NULL,@CreatedDate=NULL,
												 @UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@StatusID=1,@PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N''
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_LegalEntityGetDomesticShipViaList]
@LegalEntityShippingAddressId BIGINT,
@EmployeeId BIGINT,
@Shipvia NVARCHAR(200),
@ShipAccountinfo VARCHAR(200),
@ShippingTerms NVARCHAR(MAX),
@Memo NVARCHAR(MAX),
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
				LS.[LegalEntityShippingId],
				LS.[LegalEntityShippingAddressId],
				ISNULL(LS.[ShipViaId], 0) AS [ShipviaId],
				LS.[ShippingAccountinfo] AS [ShipAccountinfo],
				ISNULL(SV.[Name], '') AS [Shipvia],
				ISNULL(LS.[ShippingTermsId], 0) AS [ShippingTermsId],
				ST.[Name] AS [ShippingTerms],
				LS.[Memo],
				ISNULL(LS.[IsPrimary], 0) AS [IsPrimary],
			    LS.[CreatedBy],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(LS.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(LS.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(LS.[CreatedDate] AS DATETIME)) END AS CreatedDate,
				LS.[UpdatedBy],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(LS.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(LS.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(LS.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
				ISNULL(LS.[IsActive], 0) AS [IsActive],
				ISNULL(LS.[IsDeleted], 0) AS [IsDeleted]
		FROM [DBO].[LegalEntityShipping] LS WITH (NOLOCK)
		LEFT JOIN [DBO].[ShippingVia] SV WITH (NOLOCK) ON LS.[ShipViaId] = SV.[ShippingViaId]
		LEFT JOIN [DBO].[ShippingTerms] ST WITH (NOLOCK) ON LS.[ShippingTermsId] = ST.[ShippingTermsId]
		WHERE LS.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId
		AND (@IsActive IS NULL OR LS.[IsActive] = @IsActive) AND (@IsDeleted IS NULL OR LS.[IsDeleted] = @IsDeleted))

		SELECT * INTO #TempResult FROM Result
		WHERE ((@GlobalFilter <>'' AND (([Shipvia] LIKE '%' +@GlobalFilter+'%') OR
			([ShipAccountinfo] LIKE '%' +@GlobalFilter+'%') OR
			([ShippingTerms] LIKE '%' +@GlobalFilter+'%') OR	
			([Memo] LIKE '%' +@GlobalFilter+'%') OR
			([CreatedBy] LIKE '%' +@GlobalFilter+'%') OR			
			([UpdatedBy] LIKE '%' +@GlobalFilter+'%'))) OR			
			(@GlobalFilter='' AND (ISNULL(@Shipvia,'') ='' OR [Shipvia] LIKE '%' + @Shipvia+'%') AND
			(ISNULL(@ShipAccountinfo,'') ='' OR [ShipAccountinfo] LIKE '%' + @ShipAccountinfo+'%') AND
			(ISNULL(@ShippingTerms,'') ='' OR [ShippingTerms] LIKE '%' + @ShippingTerms+'%') AND
			(ISNULL(@Memo,'') ='' OR [Memo] LIKE '%' + @Memo+'%') AND			
			(ISNULL(@CreatedBy,'') ='' OR [CreatedBy] LIKE '%' + @CreatedBy+'%') AND
			(ISNULL(@UpdatedBy,'') ='' OR [UpdatedBy] LIKE '%' + @UpdatedBy+'%') AND						
			(ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS Date) = CAST(@CreatedDate AS date)) AND
			(ISNULL(@UpdatedDate,'') ='' OR CAST([UpdatedDate] AS date) = CAST(@UpdatedDate AS date))))

		SELECT @Count = COUNT(*) FROM #TempResult;	

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='Shipvia') THEN [Shipvia] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='ShipAccountinfo') THEN [ShipAccountinfo] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='ShippingTerms') THEN [ShippingTerms] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Memo') THEN [Memo] END ASC,		
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy') THEN [CreatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy') THEN [UpdatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate') THEN [CreatedDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate') THEN [UpdatedDate] END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Shipvia') THEN [Shipvia] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ShipAccountinfo') THEN [ShipAccountinfo] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ShippingTerms') THEN [ShippingTerms] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Memo') THEN [Memo] END DESC,			
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
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityGetDomesticShipViaList'
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