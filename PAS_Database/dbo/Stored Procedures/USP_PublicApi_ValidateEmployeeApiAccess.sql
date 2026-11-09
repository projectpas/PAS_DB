
---------------------------------------------------------------------------------------------
-- 2.3 Per-request token check: employee active, API access enabled, credential not rotated,
--     token issued by us and not revoked / regenerated / expired.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_ValidateEmployeeApiAccess]
    @EmployeeId        BIGINT,
    @ClientId          VARCHAR(100),
    @CredentialVersion INT,
    @TokenId           VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CAST(CASE WHEN EXISTS (
        SELECT 1
        FROM [dbo].[EmployeeApiCredential] C WITH (NOLOCK)
        INNER JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = C.[EmployeeId]
        WHERE C.[EmployeeId] = @EmployeeId
          AND C.[ClientId] = @ClientId
          AND C.[CredentialVersion] = @CredentialVersion
          AND C.[IsApiAccessEnabled] = 1
          AND E.[IsActive] = 1
          AND E.[IsDeleted] = 0
          AND EXISTS (SELECT 1 FROM [dbo].[EmployeeApiToken] T WITH (NOLOCK)
                      WHERE T.[TokenId] = @TokenId
                        AND T.[EmployeeId] = @EmployeeId
                        AND T.[IsRevoked] = 0
                        AND T.[ExpiryDate] > GETUTCDATE())
    ) THEN 1 ELSE 0 END AS BIT) AS [IsValid];
END