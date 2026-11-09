
/*=========================================================================================
  2. STORED PROCEDURES - TOKEN ENDPOINT AND TOKEN VALIDATION
=========================================================================================*/

---------------------------------------------------------------------------------------------
-- 2.1 Credential lookup for POST /api/v1/auth/token. Status flags are returned, not filtered,
--     so the caller always runs the hash check and every failure costs the same time.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetCredentialByClientId]
    @ClientId VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        C.[EmployeeId],
        C.[MasterCompanyId],
        C.[ClientId],
        C.[ClientSecretHash],
        C.[CredentialVersion],
        C.[IsApiAccessEnabled],
        E.[IsActive],
        E.[IsDeleted]
    FROM [dbo].[EmployeeApiCredential] C WITH (NOLOCK)
    INNER JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = C.[EmployeeId]
    WHERE C.[ClientId] = @ClientId;
END