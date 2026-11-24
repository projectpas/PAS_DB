
/*************************************************************
 ** File:   [USP_PublicApi_GetEmployeeApiRequestLog]
 ** Author: Moin Bloch
 ** Description: 5.4 Public API calls of one employee for one API (EmployeeApiUsage.ApiName), newest first by default.
 **              @Result: All, Success (status 200-299) or Failed. Rows logged before EmployeeApiRequestLog.ApiName
 **              existed get their API name from the path (same rule as USP_PublicApi_SaveRequestLog; 404 = "(unmatched)").
 **              @SortColumn: createdDate, httpMethod, requestPath, queryString, statusCode, durationMs, ipAddress, clientId.
 ** Purpose: PAS - Employee screen, Public API tab (popup behind Total Calls / Successful / Failed)
 ** Date:   17/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    17/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetEmployeeApiRequestLog] @MasterCompanyId = 1, @EmployeeId = 2, @ApiName = 'customers', @Result = 'Failed', @PageNumber = 1, @PageSize = 10
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetEmployeeApiRequestLog]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT,
    @ApiName         VARCHAR(100),
    @Result          VARCHAR(10) = 'All',
    @PageNumber      INT = 1,
    @PageSize        INT = 10,
    @SortColumn      VARCHAR(50) = NULL,
    @SortOrder       INT = -1,
    @GlobalFilter    VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @SortColumn = ISNULL(NULLIF(@SortColumn, ''), 'createdDate');
        SET @GlobalFilter = NULLIF(LTRIM(RTRIM(@GlobalFilter)), '');

        ;WITH Calls AS
        (
            SELECT L.[EmployeeApiRequestLogId], L.[CreatedDate], L.[ClientId], L.[HttpMethod], L.[RequestPath], L.[QueryString],
                   L.[StatusCode], L.[DurationMs], L.[IpAddress], L.[UserAgent],
                   -- Older rows: 404 = URL the API does not have ("(unmatched)"); otherwise the API name from the path.
                   COALESCE(L.[ApiName],
                            CASE WHEN L.[StatusCode] = 404 THEN '(unmatched)'
                                 WHEN EXISTS (SELECT 1 FROM [dbo].[EmployeeApiUsage] U WITH (NOLOCK)
                                              WHERE U.[EmployeeId] = L.[EmployeeId] AND U.[ApiName] = P.[PathApiName])
                                 THEN P.[PathApiName] ELSE '(unmatched)' END) AS [ApiName]
            FROM [dbo].[EmployeeApiRequestLog] L WITH (NOLOCK)
            CROSS APPLY (SELECT LOWER(L.[RequestPath]) AS [Path]) X
            CROSS APPLY (SELECT CASE
                             WHEN X.[Path] LIKE '/api/v1/auth/token%' THEN 'token'
                             WHEN X.[Path] LIKE '/api/v1/_%' THEN SUBSTRING(X.[Path], 9, ISNULL(NULLIF(CHARINDEX('/', X.[Path] + '/', 9), 0), 109) - 9)
                             WHEN X.[Path] LIKE '/api/publicapiintegration/_%' THEN SUBSTRING(X.[Path], 27, ISNULL(NULLIF(CHARINDEX('/', X.[Path] + '/', 27), 0), 127) - 27)
                             WHEN X.[Path] LIKE '/api/publicapiintegration%' THEN '(root)'
                             ELSE '' END AS [PathApiName]) P
            WHERE L.[EmployeeId] = @EmployeeId
              AND L.[MasterCompanyId] = @MasterCompanyId
        ),
        Filtered AS
        (
            SELECT C.*, COUNT(1) OVER () AS [TotalRecords]
            FROM Calls C
            WHERE C.[ApiName] = LOWER(@ApiName)
              AND (@Result = 'All'
                   OR (@Result = 'Success' AND C.[StatusCode] BETWEEN 200 AND 299)
                   OR (@Result = 'Failed' AND C.[StatusCode] NOT BETWEEN 200 AND 299))
              AND (@GlobalFilter IS NULL
                   OR C.[HttpMethod] LIKE '%' + @GlobalFilter + '%'
                   OR C.[RequestPath] LIKE '%' + @GlobalFilter + '%'
                   OR C.[QueryString] LIKE '%' + @GlobalFilter + '%'
                   OR CAST(C.[StatusCode] AS VARCHAR(10)) LIKE '%' + @GlobalFilter + '%'
                   OR C.[IpAddress] LIKE '%' + @GlobalFilter + '%'
                   OR C.[ClientId] LIKE '%' + @GlobalFilter + '%'
                   OR C.[UserAgent] LIKE '%' + @GlobalFilter + '%')
        )
        SELECT F.[CreatedDate], F.[ClientId], F.[HttpMethod], F.[RequestPath], F.[QueryString], F.[StatusCode],
               F.[DurationMs], F.[IpAddress], F.[UserAgent], F.[TotalRecords]
        FROM Filtered F
        ORDER BY
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'createdDate' THEN F.[CreatedDate] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'createdDate' THEN F.[CreatedDate] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'httpMethod'  THEN F.[HttpMethod] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'httpMethod'  THEN F.[HttpMethod] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'requestPath' THEN F.[RequestPath] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'requestPath' THEN F.[RequestPath] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'queryString' THEN F.[QueryString] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'queryString' THEN F.[QueryString] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'statusCode'  THEN F.[StatusCode] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'statusCode'  THEN F.[StatusCode] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'durationMs'  THEN F.[DurationMs] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'durationMs'  THEN F.[DurationMs] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'ipAddress'   THEN F.[IpAddress] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'ipAddress'   THEN F.[IpAddress] END DESC,
            CASE WHEN @SortOrder = 1  AND @SortColumn = 'clientId'    THEN F.[ClientId] END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'clientId'    THEN F.[ClientId] END DESC,
            F.[EmployeeApiRequestLogId] DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetEmployeeApiRequestLog'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@ApiName, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@Result, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
                                                   + '@Parameter9 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END