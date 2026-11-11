
/*=========================================================================================
  2. STORED PROCEDURES - TOKEN ENDPOINT AND TOKEN VALIDATION
=========================================================================================*/

/*************************************************************
 ** File:   [USP_PublicApi_GetCredentialByClientId]
 ** Author: Moin Bloch
 ** Description: 2.1 Credential lookup for POST /api/v1/auth/token. Status flags are returned, not filtered,
 **                  so the caller always runs the hash check and every failure costs the same time.
 ** Purpose: PAS_PUBLIC_API - POST /api/v1/auth/token
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetCredentialByClientId] @ClientId = 'pas_1_af6cc51954e814c2fc9426d6e667f913'
************************************************************************/
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