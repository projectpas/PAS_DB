/*************************************************************           
 ** File:   [USP_AIAutoQuoteSetting_GetList]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get AI Auto Quote Setting Listing 
 ** Date:   12/08/2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author            Change Description            
 ** --   --------     -------           ---------------------------     
    1    12/08/2025   RAJESH GAMI       Created for AIAutoQuoteSetting table
	2    04/09/2025   Devendra Shekh    Added New fields: [Code], [YearId], [MonthId], [PercentId], [PercentValue]
	3    05/09/2025   Devendra Shekh    Added Params: @PercentValue, @YearName, @MonthName
	4    12/09/2025   Devendra Shekh    Added Params: @Days AND @PercentValue Filter resolved
**************************************************************
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AI_GetAutoQuoteSettingList]
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn VARCHAR(50) = NULL,
    @SortOrder INT = NULL,
    @GlobalFilter VARCHAR(50) = '',
    @QuoteSettingName VARCHAR(100) = NULL,
	@Sequence INT = NULL,
    @QuoteSendReview VARCHAR(100) = NULL,
    @CreatedBy VARCHAR(50) = NULL,
    @CreatedDate DATETIME = NULL,
    @MasterCompanyId BIGINT = NULL,
	@EmployeeId bigint,
	@PercentValue DECIMAL(18,2) = NULL,
	@YearName VARCHAR(50) = NULL,
	@MonthName VARCHAR(100) = NULL,
	@Days INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Count INT;
        DECLARE @RecordFrom INT;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	    SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		DECLARE @CurrntEeTimeZoneDesc VARCHAR(100) = '';
		DECLARE @PercenValStr NVARCHAR(10) = NULL;
		SET @PercenValStr = CASE WHEN @PercentValue = FLOOR(@PercentValue) THEN CAST(CAST(@PercentValue AS INT) AS NVARCHAR(10)) ELSE CAST(@PercentValue AS NVARCHAR(10)) END;
				
				SELECT 
						@CurrntEeTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

        SET @RecordFrom = (@PageNumber - 1) * @PageSize;

        IF @SortColumn IS NULL
        BEGIN
            SET @SortColumn = UPPER('Sequence');
            SET @SortOrder = 1;
        END
        ELSE
        BEGIN
            SET @SortColumn = UPPER(@SortColumn);
        END

        ;WITH Result AS (
            SELECT
                AI.AIAutoQouteSettingId,
                AI.QuoteSettingNameId,
                AI.QuoteSettingName,
                ISNULL(AI.Sequence,0)[Sequence],
                AI.QuoteSendReviewId,
                AI.QuoteSendReview,
                AI.CreatedBy,
                AI.UpdatedBy,
				case when CAST(AI.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(AI.[CreatedDate], @CurrntEeTimeZoneDesc) as Date))end CreatedDate,
				case when CAST(AI.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(AI.UpdatedDate, @CurrntEeTimeZoneDesc) as Date))end UpdatedDate,
                ISNULL(AI.IsDeleted,0)IsDeleted,
                ISNULL(AI.IsActive,0)IsActive,
				AI.Code,
				AI.YearId,
				AI.MonthId,
				AI.PercentId,
				AI.PercentValue,
				YE.YearName,
				MN.[MonthName],
				AI.[Days]
            FROM dbo.AIAutoQouteSetting AI WITH (NOLOCK)
			LEFT JOIN [dbo].[Years] YE WITH(NOLOCK) ON AI.YearId = YE.YearId
			LEFT JOIN [dbo].[Months] MN WITH(NOLOCK) ON AI.MonthId = MN.MonthId
            WHERE AI.MasterCompanyId = @MasterCompanyId
				  AND ISNULL(AI.IsDeleted, 0) = 0
        ),
        ResultCount AS (
            SELECT COUNT(*) AS TotalItems FROM Result
        )
        SELECT *
        INTO #TempTbl
        FROM Result
        WHERE
            ((@GlobalFilter <> '' AND (
                QuoteSettingName LIKE '%' + @GlobalFilter + '%' OR
                QuoteSendReview LIKE '%' + @GlobalFilter + '%' OR
				YearName LIKE '%' + @GlobalFilter + '%' OR
				[MonthName] LIKE '%' + @GlobalFilter + '%' OR
				(CAST([Sequence] AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
				(CAST([Days] AS VARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
				(CAST([PercentValue] AS NVARCHAR(10)) LIKE '%' + CAST(@GlobalFilter AS NVARCHAR(10)) + '%') OR
                CreatedBy LIKE '%' + @GlobalFilter + '%'
            ))
            OR
            (@GlobalFilter = '' AND
                (ISNULL(@QuoteSettingName, '') = '' OR QuoteSettingName LIKE '%' + @QuoteSettingName + '%') AND
                (ISNULL(@QuoteSendReview, '') = '' OR QuoteSendReview LIKE '%' + @QuoteSendReview + '%') AND
                (ISNULL(@CreatedBy, '') = '' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
                (ISNULL(@YearName, '') = '' OR YearName LIKE '%' + @YearName + '%') AND
                (ISNULL(@MonthName, '') = '' OR [MonthName] LIKE '%' + @MonthName + '%') AND
				(IsNull(@Sequence, 0) = 0 OR CAST([Sequence] as VARCHAR(10)) like @Sequence) AND
				(IsNull(@Days, 0) = 0 OR CAST([Days] as VARCHAR(10)) LIKE '%' + CAST(@Days AS VARCHAR(10)) + '%') AND
				(ISNULL(@PercenValStr, '') = '' OR CAST([PercentValue] AS NVARCHAR(10)) LIKE '%' + CAST(@PercenValStr AS NVARCHAR(10)) + '%') AND
                (ISNULL(@CreatedDate, '') = '' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE))
            ));

        SELECT @Count = COUNT(*) FROM #TempTbl;

        SELECT *, @Count AS NumberOfItems
        FROM #TempTbl
        ORDER BY
		    CASE WHEN (@SortOrder = 1  AND @SortColumn = 'SEQUENCE') THEN Sequence END ASC,
			CASE WHEN (@SortOrder = -1  AND @SortColumn = 'SEQUENCE') THEN Sequence END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'QUOTESETTINGNAME') THEN QuoteSettingName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTESETTINGNAME') THEN QuoteSettingName END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'QUOTESENDREVIEW') THEN QuoteSendReview END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTESENDREVIEW') THEN QuoteSendReview END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CREATEDBY') THEN CreatedBy END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDBY') THEN CreatedBy END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CREATEDDATE') THEN CreatedDate END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE') THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'YEARNAME') THEN YearName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'YEARNAME') THEN YearName END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'MONTHNAME') THEN [MonthName] END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MONTHNAME') THEN [MonthName] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'PERCENTVALUE') THEN PercentValue END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PERCENTVALUE') THEN PercentValue END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'DAYS') THEN [Days] END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'DAYS') THEN [Days] END DESC
        OFFSET @RecordFrom ROWS
        FETCH NEXT @PageSize ROWS ONLY;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_AI_GetAutoQuoteSettingList]',
                @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END