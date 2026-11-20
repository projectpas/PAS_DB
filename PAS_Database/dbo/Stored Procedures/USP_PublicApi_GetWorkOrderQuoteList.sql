
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteList]
 ** Author: Moin Bloch
 ** Description: 4.23 Quote headers of the company, oldest first. Same quotes as the PAS Work Order Quote list (GetWorkOrderQuoteList).
 **              @Status is the quote status (Open, Closed, Cancelled, Delayed, Approved, Pending).
 **              @OpenDateFrom / @OpenDateTo: open date range, both inclusive (dates only).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorderquotes (headers)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderQuoteList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderQuoteList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @QuoteNumber     VARCHAR(50) = NULL,
    @WorkOrderNumber VARCHAR(50) = NULL,
    @Status          VARCHAR(50) = NULL,
    @OpenDateFrom    DATE = NULL,
    @OpenDateTo      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH PagedQuote AS
        (
            SELECT Q.[WorkOrderQuoteId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = Q.[WorkOrderId]
            INNER JOIN [dbo].[WorkOrderQuoteStatus] QS WITH (NOLOCK) ON QS.[WorkOrderQuoteStatusId] = Q.[QuoteStatusId]
            WHERE Q.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(Q.[IsDeleted], 0) = 0
              AND (@QuoteNumber IS NULL OR Q.[QuoteNumber] = @QuoteNumber)
              AND (@WorkOrderNumber IS NULL OR WO.[WorkOrderNum] = @WorkOrderNumber)
              AND (@Status IS NULL OR QS.[Description] = @Status)
              AND (@OpenDateFrom IS NULL OR Q.[OpenDate] >= @OpenDateFrom)
              AND (@OpenDateTo IS NULL OR Q.[OpenDate] < DATEADD(DAY, 1, @OpenDateTo))
              -- Same quotes as the PAS list: an existing customer and WO status, and a stock part with a stage.
              AND EXISTS (SELECT 1 FROM [dbo].[Customer] C WITH (NOLOCK) WHERE C.[CustomerId] = Q.[CustomerId])
              AND EXISTS (SELECT 1 FROM [dbo].[WorkOrderStatus] WS WITH (NOLOCK) WHERE WS.[Id] = WO.[WorkOrderStatusId])
              AND EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] P WITH (NOLOCK)
                          INNER JOIN [dbo].[WorkOrderStage] ST WITH (NOLOCK) ON ST.[WorkOrderStageId] = P.[WorkOrderStageId]
                          INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = P.[ItemMasterId]
                          WHERE P.[WorkOrderId] = Q.[WorkOrderId] AND ISNULL(IM.[IsNonStock], 0) = 0)
            ORDER BY Q.[WorkOrderQuoteId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            Q.[WorkOrderQuoteId],   -- used by the API to attach the quoted parts; not returned to clients
            Q.[QuoteNumber],
            Q.[VersionNo] AS [VersionNumber],
            QS.[Description] AS [Status],
            WO.[WorkOrderNum] AS [WorkOrderNumber],
            Q.[OpenDate],
            CASE WHEN Q.[QuoteDueDate] < '19000101' THEN NULL ELSE Q.[QuoteDueDate] END AS [QuoteDueDate],   -- 0001-01-01 = not set
            Q.[ValidForDays],
            CASE WHEN Q.[ExpirationDate] < '19000101' THEN NULL ELSE Q.[ExpirationDate] END AS [ExpirationDate],
            Q.[SentDate],
            Q.[ApprovedDate],
            C.[CustomerCode],
            ISNULL(NULLIF(LTRIM(RTRIM(Q.[CustomerName])), ''), C.[Name]) AS [CustomerName],
            ISNULL(NULLIF(LTRIM(RTRIM(Q.[CustomerContact])), ''), DC.[ContactName]) AS [CustomerContact],
            NULLIF(LTRIM(RTRIM(C.[Email])), '') AS [CustomerEmail],
            NULLIF(LTRIM(RTRIM(C.[CustomerPhone])), '') AS [CustomerPhone],
            NULLIF(LTRIM(RTRIM(C.[ContractReference])), '') AS [CustomerReference],
            NULLIF(LTRIM(RTRIM(Q.[CreditTerms])), '') AS [CreditTerms],
            Q.[CreditLimit],
            CUR.[Code] AS [Currency],
            RCUR.[Code] AS [ReportCurrency],
            CASE WHEN Q.[ForeignExchangeRate] > 0 THEN Q.[ForeignExchangeRate] ELSE NULL END AS [ForeignExchangeRate],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(SP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(SP.[LastName])), '')) AS [SalesPerson],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(CSR.[FirstName])), ''), NULLIF(LTRIM(RTRIM(CSR.[LastName])), '')) AS [CustomerServiceRep],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(EMP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(EMP.[LastName])), '')) AS [Employee],
            (SELECT COUNT(1) FROM [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
             WHERE D.[WorkOrderQuoteId] = Q.[WorkOrderQuoteId] AND ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsActive], 1) = 1) AS [MPNCount],
            Q.[CreatedDate],
            Q.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedQuote P
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK) ON Q.[WorkOrderQuoteId] = P.[WorkOrderQuoteId]
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = Q.[WorkOrderId]
        INNER JOIN [dbo].[WorkOrderQuoteStatus] QS WITH (NOLOCK) ON QS.[WorkOrderQuoteStatusId] = Q.[QuoteStatusId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = Q.[CustomerId]
        -- Default customer contact and the customer's primary sales person (PAS shows it as CSR).
        OUTER APPLY (SELECT TOP (1) CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(CN.[FirstName])), ''), NULLIF(LTRIM(RTRIM(CN.[LastName])), '')) AS [ContactName]
                     FROM [dbo].[CustomerContact] CC WITH (NOLOCK)
                     INNER JOIN [dbo].[Contact] CN WITH (NOLOCK) ON CN.[ContactId] = CC.[ContactId]
                     WHERE CC.[CustomerId] = Q.[CustomerId] AND CC.[IsDefaultContact] = 1
                     ORDER BY CC.[CustomerContactId]) DC
        OUTER APPLY (SELECT TOP (1) CS.[PrimarySalesPersonId] FROM [dbo].[CustomerSales] CS WITH (NOLOCK)
                     WHERE CS.[CustomerId] = Q.[CustomerId] ORDER BY CS.[CustomerSalesId]) CSX
        LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON CUR.[CurrencyId] = Q.[CurrencyId]
        LEFT JOIN [dbo].[Currency] RCUR WITH (NOLOCK) ON RCUR.[CurrencyId] = Q.[ReportCurrencyId]
        LEFT JOIN [dbo].[Employee] SP WITH (NOLOCK) ON SP.[EmployeeId] = COALESCE(Q.[SalesPersonId], WO.[SalesPersonId])
        LEFT JOIN [dbo].[Employee] CSR WITH (NOLOCK) ON CSR.[EmployeeId] = CSX.[PrimarySalesPersonId]
        LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON EMP.[EmployeeId] = COALESCE(Q.[EmployeeId], WO.[EmployeeId])
        ORDER BY Q.[WorkOrderQuoteId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderQuoteList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@QuoteNumber, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@WorkOrderNumber, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@OpenDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@OpenDateTo, '') AS VARCHAR(100))
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