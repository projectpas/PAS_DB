
/*************************************************************
 ** File:   [USP_PublicApi_GetExplorerAccess]
 ** Author: Moin Bloch
 ** Description: 6.4 Can this employee use the API Explorer: active, not deleted, and Public API access enabled
 **              (Employee screen > Public API tab). Also returns the name shown on the Explorer page.
 **              HasTwoFactor: two-factor authentication on, same rule as the PAS login (SMS, Microsoft / Google
 **              Authenticator or Email); the Explorer does not support two-factor, so these employees are refused.
 **              IsEmployeeActive: active and not deleted, so the caller can tell a missing / switched-off key apart.
 ** Purpose: PAS_PUBLIC_API - API Explorer login
 ** Date:   19/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    19/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)
    3    20/11/2026   Moin Bloch    Added IsEmployeeActive (message for a missing API key)

  EXEC [dbo].[USP_PublicApi_GetExplorerAccess] @MasterCompanyId = 1, @EmployeeId = 2
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetExplorerAccess]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP (1)
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(E.[FirstName])), ''), NULLIF(LTRIM(RTRIM(E.[LastName])), '')) AS [EmployeeName],
            CAST(CASE WHEN E.[IsActive] = 1 AND ISNULL(E.[IsDeleted], 0) = 0 THEN 1 ELSE 0 END AS BIT) AS [IsEmployeeActive],
            CAST(CASE WHEN E.[IsActive] = 1 AND ISNULL(E.[IsDeleted], 0) = 0 AND C.[IsApiAccessEnabled] = 1 THEN 1 ELSE 0 END AS BIT) AS [HasAccess],
            CAST(CASE WHEN E.[TwoFactorAuthentication] = 1 AND E.[TwoFactorAuthenticationType] IN (1, 2, 3, 4) THEN 1 ELSE 0 END AS BIT) AS [HasTwoFactor]
        FROM [dbo].[Employee] E WITH (NOLOCK)
        LEFT JOIN [dbo].[EmployeeApiCredential] C WITH (NOLOCK)
            ON C.[EmployeeId] = E.[EmployeeId] AND C.[MasterCompanyId] = @MasterCompanyId
        WHERE E.[EmployeeId] = @EmployeeId
          AND E.[MasterCompanyId] = @MasterCompanyId;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetExplorerAccess'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
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