
/*************************************************************
 ** File:   [USP_PublicApi_GetSalesOrderList]
 ** Author: Moin Bloch
 ** Description: 4.8 GET /api/v1/salesorders. SO headers the employee can see (same rules as the PAS Sales Order list). SalesOrderAmount = sum of the part lines' net sale amount
 **              (the PAS list "SO Amount").
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/salesorders (headers)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetSalesOrderList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderList]
    @MasterCompanyId  INT,
    @EmployeeId       BIGINT,
    @PageNumber       INT,
    @PageSize         INT,
    @SalesOrderNumber VARCHAR(50) = NULL,
    @Status           VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MSModuleId INT = 17; -- Sales Order (SalesOrderManagementStructureDetails.ModuleID), as in SearchSOViewData

    ;WITH PagedSO AS
    (
        SELECT SO.[SalesOrderId], COUNT(1) OVER () AS [TotalRecords]
        FROM [dbo].[SalesOrder] SO WITH (NOLOCK)
        INNER JOIN [dbo].[MasterSalesOrderStatus] MST WITH (NOLOCK) ON MST.[Id] = SO.[StatusId]
        WHERE SO.[MasterCompanyId] = @MasterCompanyId
          AND SO.[IsDeleted] = 0
          AND (@SalesOrderNumber IS NULL OR SO.[SalesOrderNumber] = @SalesOrderNumber)
          AND (@Status IS NULL OR MST.[Name] = @Status)
          AND EXISTS (SELECT 1 FROM [dbo].[Customer] C WITH (NOLOCK) WHERE C.[CustomerId] = SO.[CustomerId])
          AND EXISTS (SELECT 1 FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK)
                      WHERE MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = SO.[SalesOrderId])
          AND EXISTS (SELECT 1 FROM [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
                      INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId
                      WHERE RMS.[EntityStructureId] = SO.[ManagementStructureId])
        ORDER BY SO.[SalesOrderId]
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
    )
    SELECT
        SO.[SalesOrderId],   -- used by the API to attach parts, shipping and billing; not returned to clients
        SO.[SalesOrderNumber],
        SO.[VersionNumber],
        SO.[TypeName] AS [SalesOrderType],
        MST.[Name] AS [Status],
        SO.[OpenDate],
        SO.[ShippedDate],
        SO.[ApprovedDate],
        C.[CustomerCode],
        SO.[CustomerName],
        SO.[AccountTypeName] AS [CustomerType],
        CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(CT.[FirstName])), ''), NULLIF(LTRIM(RTRIM(CT.[LastName])), '')) AS [CustomerContact],
        CT.[WorkPhone] AS [CustomerContactPhone],
        CT.[Email] AS [CustomerContactEmail],
        SO.[CustomerReference],
        SO.[ContractReference],
        SO.[CreditTermName] AS [CreditTerms],
        SO.[CreditLimit],
        FC.[Code] AS [FunctionalCurrency],
        RC.[Code] AS [ReportCurrency],
        CASE WHEN SO.[ForeignExchangeRate] > 0 THEN SO.[ForeignExchangeRate] ELSE NULL END AS [ForeignExchangeRate],
        CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(SP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(SP.[LastName])), '')) AS [SalesPerson],
        CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(CSR.[FirstName])), ''), NULLIF(LTRIM(RTRIM(CSR.[LastName])), '')) AS [CustomerServiceRep],
        SO.[EmployeeName] AS [Employee],
        MSD.[Level1Name] AS [LegalEntity],
        MSD.[Level2Name] AS [BusinessUnit],
        MSD.[Level3Name] AS [Division],
        MSD.[Level4Name] AS [Department],
        ISNULL(PP.[PartsCount], 0) AS [PartsCount],
        ISNULL(PP.[SalesOrderAmount], 0) AS [SalesOrderAmount],
        ISNULL(SO.[TotalFreight], 0) AS [TotalFreight],
        ISNULL(SO.[TotalCharges], 0) AS [TotalCharges],
        SO.[CreatedDate],
        SO.[UpdatedDate],
        P.[TotalRecords]
    FROM PagedSO P
    INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.[SalesOrderId] = P.[SalesOrderId]
    INNER JOIN [dbo].[MasterSalesOrderStatus] MST WITH (NOLOCK) ON MST.[Id] = SO.[StatusId]
    LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = SO.[CustomerId]
    LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK) ON CC.[CustomerContactId] = SO.[CustomerContactId]
    LEFT JOIN [dbo].[Contact] CT WITH (NOLOCK) ON CT.[ContactId] = CC.[ContactId]
    LEFT JOIN [dbo].[Employee] SP WITH (NOLOCK) ON SP.[EmployeeId] = SO.[SalesPersonId]
    LEFT JOIN [dbo].[Employee] CSR WITH (NOLOCK) ON CSR.[EmployeeId] = SO.[CustomerSeviceRepId]
    LEFT JOIN [dbo].[Currency] FC WITH (NOLOCK) ON FC.[CurrencyId] = SO.[FunctionalCurrencyId]
    LEFT JOIN [dbo].[Currency] RC WITH (NOLOCK) ON RC.[CurrencyId] = SO.[ReportCurrencyId]
    -- Plain level names (AllMSlevels is HTML for the PAS screen).
    OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                 FROM [dbo].[SalesOrderManagementStructureDetails] M WITH (NOLOCK)
                 WHERE M.[ModuleID] = @MSModuleId AND M.[ReferenceID] = SO.[SalesOrderId]) MSD
    OUTER APPLY (
        SELECT COUNT(1) AS [PartsCount], SUM(PC.[NetSaleAmount]) AS [SalesOrderAmount]
        FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK)
        LEFT JOIN [dbo].[SalesOrderPartCost] PC WITH (NOLOCK) ON PC.[SalesOrderPartId] = SOP.[SalesOrderPartId] AND PC.[IsDeleted] = 0
        WHERE SOP.[SalesOrderId] = SO.[SalesOrderId] AND SOP.[IsDeleted] = 0
    ) PP
    ORDER BY SO.[SalesOrderId]
    OPTION (RECOMPILE);
END