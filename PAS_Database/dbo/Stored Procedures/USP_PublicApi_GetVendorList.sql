
/*************************************************************
 ** File:   [USP_PublicApi_GetVendorList]
 ** Author: Moin Bloch
 ** Description: 4.19 Vendors of the company, oldest first. Classification and Contact (default contact) follow
 **              the same logic as dbo.ProcVendorList (PAS Vendor List).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/vendors
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetVendorList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetVendorList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @VendorCode      VARCHAR(100) = NULL,
    @IsActive        BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @VendorModule INT = 3;

        ;WITH PagedVendor AS
        (
            SELECT V.[VendorId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[Vendor] V WITH (NOLOCK)
            WHERE V.[MasterCompanyId] = @MasterCompanyId
              AND V.[IsDeleted] = 0
              AND (@VendorCode IS NULL OR V.[VendorCode] = @VendorCode)
              AND (@IsActive IS NULL OR V.[IsActive] = @IsActive)
            ORDER BY V.[VendorId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            V.[VendorId],   -- used by the API to attach the contacts; not returned to clients
            V.[VendorCode],
            V.[VendorName],
            NULLIF(LTRIM(RTRIM(V.[DoingBusinessAsName])), '') AS [DoingBusinessAsName],
            VT.[Description] AS [VendorType],
            V.[VendorEmail] AS [Email],
            V.[VendorPhone] AS [Phone],
            NULLIF(LTRIM(RTRIM(V.[VendorPhoneExt])), '') AS [PhoneExtension],
            NULLIF(LTRIM(RTRIM(V.[VendorURL])), '') AS [Website],
            STUFF((SELECT ', ' + VC.[ClassificationName]
                   FROM [dbo].[ClassificationMapping] CM WITH (NOLOCK)
                   INNER JOIN [dbo].[VendorClassification] VC WITH (NOLOCK) ON VC.[VendorClassificationId] = CM.[ClasificationId]
                   WHERE CM.[ReferenceId] = V.[VendorId] AND CM.[ModuleId] = @VendorModule
                   FOR XML PATH('')), 1, 2, '') AS [Classification],
            A.[City],
            A.[StateOrProvince] AS [State],
            LTRIM(RTRIM(A.[PostalCode])) AS [ZipCode],
            CO.[countries_name] AS [Country],
            NULLIF(LTRIM(RTRIM(ISNULL(CT.[FirstName], '') + ' ' + ISNULL(CT.[LastName], ''))), '') AS [Contact],
            PV.[VendorCode] AS [ParentVendorCode],
            PV.[VendorName] AS [ParentVendorName],
            CAST(ISNULL(V.[IsVendorAlsoCustomer], 0) AS BIT) AS [IsVendorAlsoCustomer],
            C.[CustomerCode] AS [RelatedCustomerCode],
            C.[Name] AS [RelatedCustomerName],
            CAST(ISNULL(V.[IsPreferredVendor], 0) AS BIT) AS [IsPreferredVendor],
            CAST(ISNULL(V.[IsCertified], 0) AS BIT) AS [IsCertified],
            NULLIF(LTRIM(RTRIM(V.[LicenseNumber])), '') AS [LicenseNumber],
            NULLIF(LTRIM(RTRIM(V.[VendorContractReference])), '') AS [ContractReference],
            CTR.[Name] AS [CreditTerms],
            V.[CreditLimit],
            CU.[Code] AS [Currency],
            D.[DiscontValue] AS [DiscountPercent],
            CAST(ISNULL(V.[Is1099Required], 0) AS BIT) AS [Is1099Required],
            NULLIF(LTRIM(RTRIM(V.[ResaleNumber])), '') AS [ResaleNumber],
            NULLIF(LTRIM(RTRIM(V.[VatNumber])), '') AS [VatNumber],
            CAST(ISNULL(V.[IsVendorOnHold], 0) AS BIT) AS [IsOnHold],
            CAST(ISNULL(V.[IsTradeRestricted], 0) AS BIT) AS [IsTradeRestricted],
            V.[IsActive],
            V.[CreatedDate],
            V.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedVendor P
        INNER JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.[VendorId] = P.[VendorId]
        LEFT JOIN [dbo].[VendorType] VT WITH (NOLOCK) ON VT.[VendorTypeId] = V.[VendorTypeId]
        LEFT JOIN [dbo].[Address] A WITH (NOLOCK) ON A.[AddressId] = V.[AddressId]
        LEFT JOIN [dbo].[Countries] CO WITH (NOLOCK) ON CO.[countries_id] = A.[CountryId]
        OUTER APPLY (
            SELECT TOP (1) VCN.[ContactId]
            FROM [dbo].[VendorContact] VCN WITH (NOLOCK)
            WHERE VCN.[VendorId] = V.[VendorId] AND VCN.[IsDefaultContact] = 1
            ORDER BY VCN.[VendorContactId]
        ) DC
        LEFT JOIN [dbo].[Contact] CT WITH (NOLOCK) ON CT.[ContactId] = DC.[ContactId]
        LEFT JOIN [dbo].[Vendor] PV WITH (NOLOCK) ON PV.[VendorId] = V.[VendorParentId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = V.[RelatedCustomerId]
        LEFT JOIN [dbo].[CreditTerms] CTR WITH (NOLOCK) ON CTR.[CreditTermsId] = V.[CreditTermsId]
        LEFT JOIN [dbo].[Currency] CU WITH (NOLOCK) ON CU.[CurrencyId] = V.[CurrencyId]
        LEFT JOIN [dbo].[Discount] D WITH (NOLOCK) ON D.[DiscountId] = V.[DiscountId]
        ORDER BY V.[VendorId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetVendorList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@VendorCode, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@IsActive, '') AS VARCHAR(100))
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