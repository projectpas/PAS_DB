
/*=========================================================================================
  4. STORED PROCEDURES - DATA ENDPOINTS
=========================================================================================*/

---------------------------------------------------------------------------------------------
-- 4.1 GET /api/v1/customers. TEMPLATE for data endpoints: always filter by the token's
--     @MasterCompanyId. Classification, City, State, ZipCode, Country and Contact follow the
--     same logic as dbo.GetCustomerList (PAS customer list).
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetCustomerList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerModule INT = 1;

    SELECT
        C.[CustomerId],
        C.[CustomerCode],
        C.[Name],
        C.[Email],
        C.[CustomerPhone],
        STUFF((SELECT ', ' + CCL.[Description]
               FROM [dbo].[ClassificationMapping] CM WITH (NOLOCK)
               INNER JOIN [dbo].[CustomerClassification] CCL WITH (NOLOCK)
                   ON CCL.[CustomerClassificationId] = CM.[ClasificationId] AND CCL.[MasterCompanyId] = @MasterCompanyId
               WHERE CM.[ReferenceId] = C.[CustomerId] AND CM.[ModuleId] = @CustomerModule
               FOR XML PATH('')), 1, 2, '') AS [Classification],
        A.[City],
        A.[StateOrProvince] AS [State],
        LTRIM(RTRIM(A.[PostalCode])) AS [ZipCode],
        CO.[countries_name] AS [Country],
        NULLIF(LTRIM(RTRIM(ISNULL(CT.[FirstName], '') + ' ' + ISNULL(CT.[LastName], ''))), '') AS [Contact],
        C.[IsActive],
        C.[UpdatedDate],
        COUNT(1) OVER () AS [TotalRecords]
    FROM [dbo].[Customer] C WITH (NOLOCK)
    LEFT JOIN [dbo].[Address] A WITH (NOLOCK) ON A.[AddressId] = C.[AddressId]
    LEFT JOIN [dbo].[Countries] CO WITH (NOLOCK) ON CO.[countries_id] = A.[CountryId]
    OUTER APPLY (
        SELECT TOP (1) CCN.[ContactId]
        FROM [dbo].[CustomerContact] CCN WITH (NOLOCK)
        WHERE CCN.[CustomerId] = C.[CustomerId] AND CCN.[IsDefaultContact] = 1
        ORDER BY CCN.[CustomerContactId]
    ) DC
    LEFT JOIN [dbo].[Contact] CT WITH (NOLOCK) ON CT.[ContactId] = DC.[ContactId]
    WHERE C.[MasterCompanyId] = @MasterCompanyId
      AND C.[IsDeleted] = 0
    ORDER BY C.[CustomerId]
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END