/*************************************************************           
 ** File:		 [USP_GetLegalEntityContactList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Contact List.
 ** Purpose:         
 ** Date:   16-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    16-July-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityContactList] @LegalEntityId=1,@EmployeeId=236,@Tag=NULL,@Attention=NULL,@FirstName=NULL,@MiddleName=NULL,@LastName=NULL,@ContactTitle=NULL,
										 @Email=NULL,@WorkPhone=NULL,@MobilePhone=NULL,@Fax=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@StatusID=1,
										 @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N''
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityContactList]
@LegalEntityId BIGINT,
@EmployeeId BIGINT,
@Tag VARCHAR(255) = NULL,
@Attention VARCHAR(250) = NULL,
@FirstName VARCHAR(100),
@MiddleName VARCHAR(30) = NULL,
@LastName VARCHAR(30),
@ContactTitle VARCHAR(30) = NULL,
@Email VARCHAR(200) = NULL,
@WorkPhone VARCHAR(20) = NULL,
@MobilePhone VARCHAR(20) = NULL,
@Fax VARCHAR(20) = NULL,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2,
@UpdatedBy VARCHAR(256),
@UpdatedDate DATETIME2,
@IsDeleted BIT = NULL,
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
			SELECT DISTINCT	
				CON.[ContactId],
				ISNULL(CON.[Tag], '') AS Tag,
				ISNULL(CON.[ContactTagId], '') AS ContactTagId,
				ISNULL(CON.[Attention], '') AS Attention,
				ISNULL(CON.[FirstName], '') AS FirstName,
				ISNULL(CON.[MiddleName], '') AS MiddleName,
				ISNULL(CON.[LastName], '') AS LastName,
				ISNULL(CON.[ContactTitle], '') AS ContactTitle,
				ISNULL(CON.[Email], '') AS Email,
				ISNULL(CON.[WorkPhone], '') AS WorkPhone,
				ISNULL(CON.[MobilePhone], '') AS MobilePhone,
				ISNULL(CON.[Fax], '') AS Fax,
				CASE WHEN LECONT.[IsDefaultContact] = 1 THEN 1 ELSE 0 END AS IsDefaultContact,
				CON.[CreatedBy],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(CON.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CON.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(CON.[CreatedDate] AS DATETIME)) END AS CreatedDate,
				CON.[UpdatedBy],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(CON.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CON.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(CON.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,	
				ISNULL(CON.[IsActive], 0) AS IsActive,
				ISNULL(CON.[IsDeleted], 0) AS IsDeleted,
				LECONT.[LegalEntityContactId]
			FROM [DBO].[Contact] CON WITH (NOLOCK)
			LEFT JOIN [DBO].[LegalEntityContact] LECONT WITH (NOLOCK) ON CON.[ContactId] = LECONT.[ContactId]
			WHERE LECONT.[LegalEntityId] = @LegalEntityId
				  AND (@IsActive IS NULL OR CON.[IsActive] = @IsActive) AND (@IsDeleted IS NULL OR CON.[IsDeleted] = @IsDeleted))
	
		SELECT * INTO #TempResult FROM Result
		WHERE ((@GlobalFilter <>'' AND (([Tag] LIKE '%' +@GlobalFilter+'%') OR
			([Attention] LIKE '%' +@GlobalFilter+'%') OR	
			([FirstName] LIKE '%' +@GlobalFilter+'%') OR
			([MiddleName] LIKE '%' +@GlobalFilter+'%') OR
			([LastName] LIKE '%' +@GlobalFilter+'%') OR
			([ContactTitle] LIKE '%' +@GlobalFilter+'%') OR
			([Email] LIKE '%' +@GlobalFilter+'%') OR
			([WorkPhone] LIKE '%' +@GlobalFilter+'%') OR
			([MobilePhone] LIKE '%' +@GlobalFilter+'%') OR
			([Fax] LIKE '%' +@GlobalFilter+'%') OR
			([CreatedBy] LIKE '%' +@GlobalFilter+'%') OR
			([UpdatedBy] LIKE '%' +@GlobalFilter+'%'))) OR   
			(@GlobalFilter='' AND (ISNULL(@Tag,'') ='' OR [Tag] LIKE '%' + @Tag+'%') AND
			(ISNULL(@Attention,'') ='' OR [Attention] LIKE '%' + @Attention+'%') AND
			(ISNULL(@FirstName,'') ='' OR [FirstName] LIKE '%' + @FirstName+'%') AND
			(ISNULL(@MiddleName,'') ='' OR [MiddleName] LIKE '%' + @MiddleName+'%') AND
			(ISNULL(@LastName,'') ='' OR [LastName] LIKE '%' + @LastName+'%') AND
			(ISNULL(@ContactTitle,'') ='' OR [ContactTitle] LIKE '%' + @ContactTitle+'%') AND
			(ISNULL(@Email,'') ='' OR [Email] LIKE '%' + @Email+'%') AND
			(ISNULL(@WorkPhone,'') ='' OR [WorkPhone] LIKE '%' + @WorkPhone+'%') AND
			(ISNULL(@MobilePhone,'') ='' OR [MobilePhone] LIKE '%' + @MobilePhone+'%') AND	
			(ISNULL(@Fax,'') ='' OR [Fax] LIKE '%' + @Fax+'%') AND
			(ISNULL(@CreatedBy,'') ='' OR [CreatedBy] LIKE '%' + @CreatedBy+'%') AND
			(ISNULL(@UpdatedBy,'') ='' OR [UpdatedBy] LIKE '%' + @UpdatedBy+'%') AND						
			(ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS Date) = CAST(@CreatedDate AS date)) AND
			(ISNULL(@UpdatedDate,'') ='' OR CAST([UpdatedDate] AS date) = CAST(@UpdatedDate AS date))))

		SELECT @Count = COUNT(*) FROM #TempResult;	

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='Tag') THEN [Tag] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Attention') THEN [Attention] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='FirstName') THEN [FirstName] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='MiddleName') THEN [MiddleName] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='LastName') THEN [LastName] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='ContactTitle') THEN [ContactTitle] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Email') THEN [Email] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='WorkPhone') THEN [WorkPhone] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='MobilePhone') THEN [MobilePhone] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Fax') THEN [Fax] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy') THEN [CreatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy') THEN [UpdatedBy] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate') THEN [CreatedDate] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate') THEN [UpdatedDate] END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Tag') THEN [Tag] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Attention') THEN [Attention] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='FirstName') THEN [FirstName] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='MiddleName') THEN [MiddleName] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LastName') THEN [LastName] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ContactTitle') THEN [ContactTitle] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Email') THEN [Email] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkPhone') THEN [WorkPhone] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='MobilePhone') THEN [MobilePhone] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Fax') THEN [Fax] END DESC,
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityContactList'
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