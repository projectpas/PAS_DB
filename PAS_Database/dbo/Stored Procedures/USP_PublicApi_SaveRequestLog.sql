
/*=========================================================================================
  3. STORED PROCEDURES - REQUEST LOG AND USAGE
=========================================================================================*/

/*************************************************************
 ** File:   [USP_PublicApi_SaveRequestLog]
 ** Author: Moin Bloch
 ** Description: 3.1 Request log insert + call count per API.
 **                  @ApiName is the route name sent by PAS_PUBLIC_API (token, customers, ...). When it is not
 **                  passed (PAS PublicAPIIntegrationController) it is taken from the request path.
 ** Purpose: PAS_PUBLIC_API - request log of every /api call
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_SaveRequestLog] @EmployeeId = 2, @MasterCompanyId = 1, @ClientId = 'pas_1_af6cc51954e814c2fc9426d6e667f913', @TokenId = '0b6c1d2e3f4a5b6c7d8e9f0a1b2c3d4e', @HttpMethod = 'GET', @RequestPath = '/api/v1/salesorders', @QueryString = '', @StatusCode = 200, @DurationMs = 120, @IpAddress = '', @UserAgent = ''
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_SaveRequestLog]
    @EmployeeId      BIGINT,
    @MasterCompanyId INT,
    @ClientId        VARCHAR(100),
    @TokenId         VARCHAR(50),
    @HttpMethod      VARCHAR(10),
    @RequestPath     VARCHAR(500),
    @QueryString     VARCHAR(1000),
    @StatusCode      INT,
    @DurationMs      INT,
    @IpAddress       VARCHAR(50),
    @UserAgent       NVARCHAR(500),
    @ApiName         VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[EmployeeApiRequestLog]
        ([EmployeeId], [MasterCompanyId], [ClientId], [TokenId], [HttpMethod], [RequestPath], [QueryString],
         [StatusCode], [DurationMs], [IpAddress], [UserAgent])
    VALUES
        (@EmployeeId, @MasterCompanyId, @ClientId, @TokenId, @HttpMethod, @RequestPath, @QueryString,
         @StatusCode, @DurationMs, @IpAddress, @UserAgent);

    -- Calls that cannot be tied to an employee (unknown ClientId, invalid token) stay in the log only.
    IF @EmployeeId IS NULL OR @MasterCompanyId IS NULL
        RETURN;

    IF ISNULL(@ApiName, '') = ''
    BEGIN
        -- First path segment after api/PublicAPIIntegration/ (token, customers, ...).
        DECLARE @Prefix VARCHAR(50) = '/api/publicapiintegration/';
        SET @ApiName = CASE WHEN CHARINDEX(@Prefix, LOWER(@RequestPath)) = 1 THEN LOWER(SUBSTRING(@RequestPath, LEN(@Prefix) + 1, 100)) ELSE '' END;
        IF CHARINDEX('/', @ApiName) > 0
            SET @ApiName = LEFT(@ApiName, CHARINDEX('/', @ApiName) - 1);
        IF @ApiName = ''
            SET @ApiName = '(root)';
    END
    SET @ApiName = LOWER(@ApiName);

    DECLARE @IsSuccess BIT = CASE WHEN @StatusCode BETWEEN 200 AND 299 THEN 1 ELSE 0 END;

    UPDATE [dbo].[EmployeeApiUsage] WITH (UPDLOCK, SERIALIZABLE)
    SET [TotalCalls]     = [TotalCalls] + 1,
        [SuccessCalls]   = [SuccessCalls] + @IsSuccess,
        [FailedCalls]    = [FailedCalls] + (1 - @IsSuccess),
        [LastStatusCode] = @StatusCode,
        [LastCalledDate] = GETUTCDATE()
    WHERE [EmployeeId] = @EmployeeId AND [ApiName] = @ApiName;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO [dbo].[EmployeeApiUsage]
            ([EmployeeId], [MasterCompanyId], [ApiName], [TotalCalls], [SuccessCalls], [FailedCalls], [LastStatusCode], [LastCalledDate])
        VALUES
            (@EmployeeId, @MasterCompanyId, @ApiName, 1, @IsSuccess, 1 - @IsSuccess, @StatusCode, GETUTCDATE());
    END
END