
/*************************************************************
 ** File:   [USP_PublicApi_GetCustomerBillingAddresses]
 ** Author: Bhargav Saliya
 ** Description: Active bill-to addresses (PAS customer Billing tab, same columns as dbo.GetCustomerBillingAddresses)
 **              of the customers on one page (@CustomerIds: comma separated), primary address first.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/customers (billing addresses)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetCustomerBillingAddresses] @MasterCompanyId = 1, @CustomerIds = '1,2,3'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetCustomerBillingAddresses]
    @MasterCompanyId INT,
    @CustomerIds     VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            B.[CustomerId],   -- used by the API to attach the addresses; not returned to clients
            NULLIF(LTRIM(RTRIM(B.[SiteName])), '') AS [SiteName],
            NULLIF(LTRIM(RTRIM(A.[Line1])), '') AS [Address1],
            NULLIF(LTRIM(RTRIM(A.[Line2])), '') AS [Address2],
            NULLIF(LTRIM(RTRIM(A.[Line3])), '') AS [Address3],
            NULLIF(LTRIM(RTRIM(A.[City])), '') AS [City],
            NULLIF(LTRIM(RTRIM(A.[StateOrProvince])), '') AS [State],
            NULLIF(LTRIM(RTRIM(A.[PostalCode])), '') AS [ZipCode],
            CO.[countries_name] AS [Country],
            NULLIF(LTRIM(RTRIM(B.[Attention])), '') AS [Attention],
            NULLIF(LTRIM(RTRIM(B.[Email])), '') AS [Email],
            NULLIF(LTRIM(RTRIM(B.[TagName])), '') AS [Tag],
            IDP.[Status] AS [InvoiceDeliveryPreference],
            CAST(ISNULL(B.[IsPrimary], 0) AS BIT) AS [IsPrimary]
        FROM [dbo].[CustomerBillingAddress] B WITH (NOLOCK)
        INNER JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = B.[CustomerId] AND CU.[MasterCompanyId] = @MasterCompanyId
        INNER JOIN [dbo].[Address] A WITH (NOLOCK) ON A.[AddressId] = B.[AddressId]
        LEFT JOIN [dbo].[Countries] CO WITH (NOLOCK) ON CO.[countries_id] = A.[CountryId]
        LEFT JOIN [dbo].[InvoiceDeliveryPrefStatus] IDP WITH (NOLOCK) ON IDP.[InvDelPrefStatusId] = B.[InvDelPrefStatusId]
        WHERE B.[CustomerId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@CustomerIds, ','))
          AND ISNULL(B.[IsDeleted], 0) = 0
          AND ISNULL(B.[IsActive], 0) = 1
        ORDER BY B.[CustomerId], CAST(ISNULL(B.[IsPrimary], 0) AS BIT) DESC, B.[CustomerBillingAddressId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetCustomerBillingAddresses'
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