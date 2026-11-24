/*************************************************************
 ** File:   [USP_PublicApi_GetSalesOrderQuoteList]
 ** Author: Moin Bloch
 ** Description: Quote headers the employee can see, oldest first. Same quotes as the PAS Sales Order Quote list (SearchSOQViewData).
 **              @Status is the quote status (Open, Closed, Sent, Approved, Cancelled, Expired, Partially Approved, Pending,
 **              Rejected, Fulfilling, Shipped, Invoiced). @SalesOrderNumber: quotes converted to that sales order.
 **              @OpenDateFrom / @OpenDateTo: open date range, both inclusive (dates only).
 **              QuoteDate = when the quote was entered in PAS; SalesOrderNumber = the sales orders created from the quote
 **              (comma separated when more than one).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/salesorderquotes (headers)
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetSalesOrderQuoteList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderQuoteList]
    @MasterCompanyId  INT,
    @EmployeeId       BIGINT,
    @PageNumber       INT,
    @PageSize         INT,
    @QuoteNumber      VARCHAR(50) = NULL,
    @SalesOrderNumber VARCHAR(50) = NULL,
    @Status           VARCHAR(50) = NULL,
    @OpenDateFrom     DATE = NULL,
    @OpenDateTo       DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Sales Order Quote management structure module (SalesOrderManagementStructureDetails.ModuleID), as in SearchSOQViewData.
        DECLARE @MSModuleId INT = (SELECT TOP (1) [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK)
                                   WHERE [ModuleName] = 'SalesOrderQuote');

        ;WITH PagedQuote AS
        (
            SELECT Q.[SalesOrderQuoteId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[SalesOrderQuote] Q WITH (NOLOCK)
            INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] QS WITH (NOLOCK) ON QS.[Id] = Q.[StatusId]
            WHERE Q.[MasterCompanyId] = @MasterCompanyId
              AND Q.[IsDeleted] = 0
              AND (@QuoteNumber IS NULL OR Q.[SalesOrderQuoteNumber] = @QuoteNumber)
              AND (@SalesOrderNumber IS NULL OR EXISTS (SELECT 1 FROM [dbo].[SalesOrder] SO WITH (NOLOCK)
                                                        WHERE SO.[SalesOrderQuoteId] = Q.[SalesOrderQuoteId] AND SO.[IsDeleted] = 0
                                                          AND SO.[SalesOrderNumber] = @SalesOrderNumber))
              AND (@Status IS NULL OR QS.[Name] = @Status)
              AND (@OpenDateFrom IS NULL OR Q.[OpenDate] >= @OpenDateFrom)
              AND (@OpenDateTo IS NULL OR Q.[OpenDate] < DATEADD(DAY, 1, @OpenDateTo))
              -- Same quotes as the PAS list: a quote management structure that one of the employee's roles can see.
              AND EXISTS (SELECT 1 FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK)
                          WHERE MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = Q.[SalesOrderQuoteId])
              AND EXISTS (SELECT 1 FROM [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
                          INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId
                          WHERE RMS.[EntityStructureId] = Q.[ManagementStructureId])
            ORDER BY Q.[SalesOrderQuoteId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            Q.[SalesOrderQuoteId],   -- used by the API to attach the quoted parts; not returned to clients
            Q.[SalesOrderQuoteNumber] AS [QuoteNumber],
            Q.[VersionNumber],
            Q.[CreatedDate] AS [QuoteDate],   -- when the quote was entered in PAS
            Q.[OpenDate],
            QS.[Name] AS [Status],
            NULLIF(LTRIM(RTRIM(Q.[AccountTypeName])), '') AS [CustomerType],
            ISNULL(C.[Name], NULLIF(LTRIM(RTRIM(Q.[CustomerName])), '')) AS [CustomerName],   -- the customer's name, as the PAS print
            ISNULL(C.[CustomerCode], Q.[CustomerCode]) AS [CustomerCode],
            NULLIF(LTRIM(RTRIM(Q.[CustomerReference])), '') AS [CustomerReference],
            SON.[SalesOrderNumber],
            CASE WHEN Q.[ApprovedDate] > '19000101' THEN Q.[ApprovedDate] END AS [ApprovedDate],   -- PAS keeps 0001-01-01 until approved
            NULLIF(CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(SP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(SP.[LastName])), '')), '') AS [SalesPerson],
            NULLIF(LTRIM(RTRIM(Q.[CreatedBy])), '') AS [CreatedBy],
            MS.[Level1Name] AS [LegalEntity],
            MS.[Level2Name] AS [BusinessUnit],
            MS.[Level3Name] AS [Division],
            MS.[Level4Name] AS [Department],
            (SELECT COUNT(1) FROM [dbo].[SalesOrderQuotePartV1] D WITH (NOLOCK)
             WHERE D.[SalesOrderQuoteId] = Q.[SalesOrderQuoteId] AND D.[IsDeleted] = 0) AS [MPNCount],
            P.[TotalRecords]
        FROM PagedQuote P
        INNER JOIN [dbo].[SalesOrderQuote] Q WITH (NOLOCK) ON Q.[SalesOrderQuoteId] = P.[SalesOrderQuoteId]
        INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] QS WITH (NOLOCK) ON QS.[Id] = Q.[StatusId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = Q.[CustomerId]
        LEFT JOIN [dbo].[Employee] SP WITH (NOLOCK) ON SP.[EmployeeId] = Q.[SalesPersonId]
        -- Sales orders created from the quote, oldest first.
        OUTER APPLY (SELECT STRING_AGG(S.[SalesOrderNumber], ', ') WITHIN GROUP (ORDER BY S.[SalesOrderId]) AS [SalesOrderNumber]
                     FROM [dbo].[SalesOrder] S WITH (NOLOCK)
                     WHERE S.[SalesOrderQuoteId] = Q.[SalesOrderQuoteId] AND S.[IsDeleted] = 0) SON
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                     FROM [dbo].[SalesOrderManagementStructureDetails] M WITH (NOLOCK)
                     WHERE M.[ModuleID] = @MSModuleId AND M.[ReferenceID] = Q.[SalesOrderQuoteId]
                     ORDER BY M.[MSDetailsId]) MS
        ORDER BY Q.[SalesOrderQuoteId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetSalesOrderQuoteList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@QuoteNumber, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@SalesOrderNumber, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@OpenDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter9 = ''' + CAST(ISNULL(@OpenDateTo, '') AS VARCHAR(100))
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