/*************************************************************
 ** File:   [GetCreditTermListForIntegrationView]
 ** Author:   Shrey Chandegara
 ** Description: get Credit term list
 ** Purpose:
 ** Date:   10-03-2025

 ** PARAMETERS: 

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/14/2020   Shrey Chandegara  Created

 exec GetCreditTermListForIntegrationView @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@Name=NULL,@PercentId=0,@Days=0,@NetDays=0,@MasterCompanyId=1,@IsUpdated=1
**************************************************************/
CREATE   PROCEDURE [dbo].[GetCreditTermListForIntegrationView]
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@Name VARCHAR(100) = NULL,
	@PercentId VARCHAR(50) = NULL,
	@Days VARCHAR(50) = NULL,
	@NetDays VARCHAR(50) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@Memo NVARCHAR = NULL,
	@IsUpdated BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		DECLARE @RecordFrom INT = (@PageNumber - 1) * @PageSize;
		DECLARE @IsActive BIT = 1;
		DECLARE @IsDelete BIT = 0;
		DECLARE @IsUpdate BIT = 1;
		DECLARE @Count INT;

		-- Common Table Expression for filtering
		WITH Result AS (
			SELECT 
				C.CreditTermsId,
				C.Name,
				C.PercentId,
				C.Days,
				C.NetDays,
				c.Memo
			FROM dbo.CreditTerms C WITH (NOLOCK)
			WHERE C.IsDeleted = @IsDelete 
				AND C.IsActive = @IsActive
				AND C.MasterCompanyId = @MasterCompanyId
				AND ISNULL(c.IsUpdated,0) = @IsUpdate
		), 
		ResultCount AS (
			SELECT COUNT(CreditTermsId) AS totalItems FROM Result
		)

		SELECT * INTO #TempResult FROM Result
		WHERE 
			(@GlobalFilter <> '' AND (
			(Name LIKE '%' + @GlobalFilter + '%') OR
			(PercentId  LIKE '%' + @GlobalFilter + '%') OR
			(Days  LIKE '%' + @GlobalFilter + '%') OR
			(NetDays LIKE '%' + @GlobalFilter + '%') OR
			(Memo  LIKE '%' + @GlobalFilter + '%')
			))
			OR
			(@GlobalFilter = '' 
				AND (@Name IS NULL OR Name LIKE '%' + @Name + '%') 
				AND (ISNULL(@Days,'') ='' OR Days LIKE '%' + @Days + '%')  
				AND (ISNULL(@NetDays,'') ='' OR NetDays LIKE '%' + @NetDays + '%')  
				AND (ISNULL(@PercentId,'') ='' OR PercentId LIKE '%' + @PercentId + '%')  
				AND (@Memo IS NULL OR Memo LIKE '%' +  @Memo +'%')
			)
		-- Get the total count
		SELECT @Count = COUNT(CreditTermsId) FROM #TempResult;

		-- Sorting and pagination
		SELECT *, @Count AS NumberOfItems
		FROM #TempResult
		ORDER BY 
			CASE WHEN @SortOrder = 1 AND @SortColumn = 'NAME' THEN Name END ASC,
			CASE WHEN @SortOrder = -1 AND @SortColumn = 'NAME' THEN Name END DESC,
			CASE WHEN @SortOrder = 1 AND @SortColumn = 'PERCENTID' THEN PercentId END ASC,
			CASE WHEN @SortOrder = -1 AND @SortColumn = 'PERCENTID' THEN PercentId END DESC,
			CASE WHEN @SortOrder = 1 AND @SortColumn = 'DAYS' THEN Days END ASC,
			CASE WHEN @SortOrder = -1 AND @SortColumn = 'DAYS' THEN Days END DESC,
			CASE WHEN @SortOrder = 1 AND @SortColumn = 'NETDAYS' THEN NetDays END ASC,
			CASE WHEN @SortOrder = -1 AND @SortColumn = 'NETDAYS' THEN NetDays END DESC
		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT;
		DECLARE @DatabaseName VARCHAR(100) = DB_NAME();
		DECLARE @AdhocComments VARCHAR(150) = 'GetCreditTermListForIntegrationView';
		DECLARE @ProcedureParameters VARCHAR(3000) = 
			'@PageNumber=' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100)) + ', ' +
			'@PageSize=' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) + ', ' +
			'@SortColumn=' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100)) + ', ' +
			'@SortOrder=' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100)) + ', ' +
			'@GlobalFilter=' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100)) + ', ' +
			'@Name=' + CAST(ISNULL(@Name, '') AS VARCHAR(100)) + ', ' +
			'@PercentId=' + CAST(ISNULL(@PercentId, '') AS VARCHAR(100)) + ', ' +
			'@Days=' + CAST(ISNULL(@Days, '') AS VARCHAR(100)) + ', ' +
			'@NetDays=' + CAST(ISNULL(@NetDays, '') AS VARCHAR(100)) + ', ' +
			'@MasterCompanyId=' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100));
		DECLARE @ApplicationName VARCHAR(100) = 'PAS';

		EXEC spLogException 
			@DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
			'Unexpected Error Occurred in the database. Please let the support team know of the error number: %d', 
			16, 1, @ErrorLogID
		);

		RETURN (1);
	END CATCH;
END;