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
	2    04/09/2025   Devendra Shekh    Added New fiels: [Code], [YearId], [MonthId], [PercentId], [PercentValue]
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
	@EmployeeId bigint
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
				AI.PercentValue
            FROM dbo.AIAutoQouteSetting AI WITH (NOLOCK)
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
				(CAST([Sequence] AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
                CreatedBy LIKE '%' + @GlobalFilter + '%'
            ))
            OR
            (@GlobalFilter = '' AND
                (ISNULL(@QuoteSettingName, '') = '' OR QuoteSettingName LIKE '%' + @QuoteSettingName + '%') AND
                (ISNULL(@QuoteSendReview, '') = '' OR QuoteSendReview LIKE '%' + @QuoteSendReview + '%') AND
                (ISNULL(@CreatedBy, '') = '' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
				(IsNull(@Sequence, 0) = 0 OR CAST([Sequence] as VARCHAR(10)) like @Sequence) AND
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
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE') THEN CreatedDate END DESC
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