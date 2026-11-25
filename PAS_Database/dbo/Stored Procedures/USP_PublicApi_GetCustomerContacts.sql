
/*************************************************************
 ** File:   [USP_PublicApi_GetCustomerContacts]
 ** Author: Bhargav Saliya
 ** Description: Active contacts of the customers on one page (@CustomerIds: comma separated), default contact first.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/customers (contacts)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetCustomerContacts] @MasterCompanyId = 1, @CustomerIds = '1,2,3'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetCustomerContacts]
    @MasterCompanyId INT,
    @CustomerIds     VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            CC.[CustomerId],   -- used by the API to attach the contacts; not returned to clients
            NULLIF(LTRIM(RTRIM(C.[Prefix])), '') AS [Prefix],
            NULLIF(LTRIM(RTRIM(C.[FirstName])), '') AS [FirstName],
            NULLIF(LTRIM(RTRIM(C.[MiddleName])), '') AS [MiddleName],
            NULLIF(LTRIM(RTRIM(C.[LastName])), '') AS [LastName],
            NULLIF(LTRIM(RTRIM(C.[Suffix])), '') AS [Suffix],
            NULLIF(LTRIM(RTRIM(C.[ContactTitle])), '') AS [Title],
            NULLIF(LTRIM(RTRIM(C.[Email])), '') AS [Email],
            NULLIF(LTRIM(RTRIM(C.[WorkPhone])), '') AS [WorkPhone],
            NULLIF(LTRIM(RTRIM(C.[WorkPhoneExtn])), '') AS [WorkPhoneExtension],
            NULLIF(LTRIM(RTRIM(C.[MobilePhone])), '') AS [MobilePhone],
            NULLIF(LTRIM(RTRIM(C.[AlternatePhone])), '') AS [AlternatePhone],
            NULLIF(LTRIM(RTRIM(C.[Fax])), '') AS [Fax],
            NULLIF(LTRIM(RTRIM(C.[Attention])), '') AS [Attention],
            CTG.[TagName] AS [Tag],
            CAST(ISNULL(CC.[IsDefaultContact], 0) AS BIT) AS [IsDefaultContact],
            CAST(ISNULL(CC.[IsRestrictedParty], 0) AS BIT) AS [IsRestrictedParty]
        FROM [dbo].[CustomerContact] CC WITH (NOLOCK)
        INNER JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = CC.[CustomerId] AND CU.[MasterCompanyId] = @MasterCompanyId
        INNER JOIN [dbo].[Contact] C WITH (NOLOCK) ON C.[ContactId] = CC.[ContactId]
        LEFT JOIN [dbo].[ContactTag] CTG WITH (NOLOCK) ON CTG.[ContactTagId] = C.[ContactTagId]
        WHERE CC.[CustomerId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@CustomerIds, ','))
          AND ISNULL(CC.[IsDeleted], 0) = 0
          AND ISNULL(CC.[IsActive], 0) = 1
        ORDER BY CC.[CustomerId], CAST(ISNULL(CC.[IsDefaultContact], 0) AS BIT) DESC, CC.[CustomerContactId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetCustomerContacts'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@CustomerIds, '') AS VARCHAR(100))
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