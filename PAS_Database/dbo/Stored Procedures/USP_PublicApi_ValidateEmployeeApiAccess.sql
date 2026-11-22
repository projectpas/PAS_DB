
/*************************************************************
 ** File:   [USP_PublicApi_ValidateEmployeeApiAccess]
 ** Author: Moin Bloch
 ** Description: 2.3 Per-request token check: employee active, API access enabled, credential not rotated,
 **                  token issued by us and not revoked / regenerated / expired.
 ** Purpose: PAS_PUBLIC_API - every protected /api/v1 call
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_ValidateEmployeeApiAccess] @EmployeeId = 2, @ClientId = 'pas_1_af6cc51954e814c2fc9426d6e667f913', @CredentialVersion = 1, @TokenId = '0b6c1d2e3f4a5b6c7d8e9f0a1b2c3d4e'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_ValidateEmployeeApiAccess]
    @EmployeeId        BIGINT,
    @ClientId          VARCHAR(100),
    @CredentialVersion INT,
    @TokenId           VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
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
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_ValidateEmployeeApiAccess'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@ClientId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@CredentialVersion, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@TokenId, '') AS VARCHAR(100))
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