/*************************************************************
 ** File:   [USP_PublicApi_GetBillingInvoicingList]
 ** Author: Moin Bloch
 ** Description: 4.29 Customer invoices like the PAS Customer Invoice List, oldest first.
 **              @DocumentType is WorkOrder, SalesOrder or Exchange. @DocumentNumber is the WO / SO / exchange SO number.
 **              @InvoiceNumber, @CustomerCode and @InvoiceStatus (Billed, Invoiced, Reviewed, Pending) are exact.
 **              @InvoiceDateFrom / @InvoiceDateTo: invoice date range, both inclusive (dates only).
 **              Deposit / NetAmountDue as on the printed invoice: a standard invoice shows the order's proforma deposits
 **              less the deposits already used; exchange invoices have no deposit.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/billinginvoicing (invoices)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetBillingInvoicingList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetBillingInvoicingList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @InvoiceNumber   VARCHAR(50)  = NULL,
    @DocumentType    VARCHAR(20)  = NULL,
    @DocumentNumber  VARCHAR(50)  = NULL,
    @CustomerCode    VARCHAR(100) = NULL,
    @InvoiceStatus   VARCHAR(50)  = NULL,
    @InvoiceDateFrom DATE         = NULL,
    @InvoiceDateTo   DATE         = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @WOModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrder');
        DECLARE @SOModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesOrder');
        DECLARE @WOMSModuleId INT = 12;   -- WorkOrderMPN (WorkOrderManagementStructureDetails.ModuleID)
        DECLARE @SOMSModuleId INT = 17;   -- SalesOrder (SalesOrderManagementStructureDetails.ModuleID)
        DECLARE @EXMSModuleId INT = 19;   -- ExchangeSalesOrder (ExchangeManagementStructureDetails.ModuleID)

        DECLARE @Page TABLE ([RowNo] INT, [IsExchange] BIT, [InvoicingId] BIGINT, [DocumentType] VARCHAR(20), [TotalRecords] INT);

        ;WITH Invoices AS
        (
            -- Work order invoices: the PAS list needs a current invoice line and a WO part with a management structure and a workflow.
            SELECT CAST(0 AS BIT) AS [IsExchange], BI.[BillingInvoicingId] AS [InvoicingId], 'WorkOrder' AS [DocumentType],
                   BI.[InvoiceNo], BI.[InvoiceDate], BI.[InvoiceStatus], WO.[WorkOrderNum] AS [DocumentNumber], C.[CustomerCode]
            FROM [dbo].[BillingInvoicing] BI WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = BI.[ReferenceId]
            INNER JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = WO.[CustomerId]
            WHERE BI.[MasterCompanyId] = @MasterCompanyId
              AND BI.[ModuleId] = @WOModuleId
              AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0
              AND ISNULL(BI.[IsVersionIncrease], 0) = 0
              AND ISNULL(BI.[IsStandardInvoicePosted], 0) <> 1
              AND EXISTS (SELECT 1 FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
                          WHERE I.[BillingInvoicingId] = BI.[BillingInvoicingId] AND ISNULL(I.[IsVersionIncrease], 0) = 0)
              AND EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
                          INNER JOIN [dbo].[WorkOrderManagementStructureDetails] M WITH (NOLOCK) ON M.[ModuleID] = @WOMSModuleId AND M.[ReferenceID] = WOP.[ID]
                          INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkOrderPartNoId] = WOP.[ID]
                          WHERE WOP.[WorkOrderId] = WO.[WorkOrderId])
            UNION ALL
            -- Sales order invoices.
            SELECT CAST(0 AS BIT), BI.[BillingInvoicingId], 'SalesOrder',
                   BI.[InvoiceNo], BI.[InvoiceDate], BI.[InvoiceStatus], SO.[SalesOrderNumber], C.[CustomerCode]
            FROM [dbo].[BillingInvoicing] BI WITH (NOLOCK)
            LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.[SalesOrderId] = BI.[ReferenceId]
            LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = SO.[CustomerId]
            WHERE BI.[MasterCompanyId] = @MasterCompanyId
              AND BI.[ModuleId] = @SOModuleId
              AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0
              AND ISNULL(BI.[IsVersionIncrease], 0) = 0
              AND ISNULL(BI.[IsStandardInvoicePosted], 0) <> 1
            UNION ALL
            -- Exchange invoices: the PAS list needs a line that is not deleted.
            SELECT CAST(1 AS BIT), X.[SOBillingInvoicingId], 'Exchange',
                   X.[InvoiceNo], X.[InvoiceDate], X.[InvoiceStatus], ESO.[ExchangeSalesOrderNumber], C.[CustomerCode]
            FROM [dbo].[ExchangeSalesOrderBillingInvoicing] X WITH (NOLOCK)
            LEFT JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.[ExchangeSalesOrderId] = X.[ExchangeSalesOrderId]
            LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = X.[CustomerId]
            WHERE X.[MasterCompanyId] = @MasterCompanyId
              AND X.[IsActive] = 1 AND X.[IsDeleted] = 0
              AND EXISTS (SELECT 1 FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] I WITH (NOLOCK)
                          WHERE I.[SOBillingInvoicingId] = X.[SOBillingInvoicingId] AND I.[IsDeleted] = 0)
        )
        INSERT INTO @Page ([RowNo], [IsExchange], [InvoicingId], [DocumentType], [TotalRecords])
        SELECT ROW_NUMBER() OVER (ORDER BY [InvoiceDate], [IsExchange], [InvoicingId]), [IsExchange], [InvoicingId], [DocumentType], COUNT(1) OVER ()
        FROM Invoices
        WHERE (@InvoiceNumber IS NULL OR [InvoiceNo] = @InvoiceNumber)
          AND (@DocumentType IS NULL OR [DocumentType] = @DocumentType)
          AND (@DocumentNumber IS NULL OR [DocumentNumber] = @DocumentNumber)
          AND (@CustomerCode IS NULL OR [CustomerCode] = @CustomerCode)
          AND (@InvoiceStatus IS NULL OR [InvoiceStatus] = @InvoiceStatus)
          AND (@InvoiceDateFrom IS NULL OR [InvoiceDate] >= @InvoiceDateFrom)
          AND (@InvoiceDateTo IS NULL OR [InvoiceDate] < DATEADD(DAY, 1, @InvoiceDateTo))
        ORDER BY [InvoiceDate], [IsExchange], [InvoicingId]
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

        SELECT
            -- IsExchange / InvoicingId are used by the API to attach the invoice lines; not returned to clients.
            P.[IsExchange],
            P.[InvoicingId],
            BI.[InvoiceNo] AS [InvoiceNumber],
            BI.[InvoiceDate],
            BI.[InvoiceStatus],
            CAST(ISNULL(BI.[IsPerformaInvoice], 0) AS BIT) AS [IsProforma],
            P.[DocumentType],
            WO.[WorkOrderNum] AS [DocumentNumber],
            C.[Name] AS [CustomerName],
            C.[CustomerCode],
            CT.[CustomerTypeName] AS [CustomerType],
            CR.[CustomerReference],
            WQ.[QuoteNumber],
            WQ.[VersionNo] AS [QuoteVersion],
            CUR.[Code] AS [Currency],
            ISNULL(BI.[SalesTax], 0) AS [SalesTax],
            ISNULL(BI.[OtherTax], 0) AS [OtherTax],
            ISNULL(BI.[GrandTotal], 0) AS [InvoiceAmount],
            D.[Deposit],
            ISNULL(BI.[GrandTotal], 0) - D.[Deposit] AS [NetAmountDue],
            MS.[Level1Name] AS [LegalEntity],
            MS.[Level2Name] AS [BusinessUnit],
            MS.[Level3Name] AS [Division],
            MS.[Level4Name] AS [Department],
            (SELECT COUNT(1) FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
             WHERE I.[BillingInvoicingId] = BI.[BillingInvoicingId] AND ISNULL(I.[IsDeleted], 0) = 0) AS [MPNCount],
            P.[TotalRecords],
            P.[RowNo]
        FROM @Page P
        INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.[BillingInvoicingId] = P.[InvoicingId]
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = BI.[ReferenceId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = WO.[CustomerId]
        LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON CT.[CustomerTypeId] = C.[CustomerTypeId]
        LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON CUR.[CurrencyId] = BI.[CurrencyId]
        -- Customer reference is kept per WO part: the references of the invoiced parts.
        OUTER APPLY (SELECT STRING_AGG(R.[CustomerReference], ', ') WITHIN GROUP (ORDER BY R.[CustomerReference]) AS [CustomerReference]
                     FROM (SELECT DISTINCT NULLIF(LTRIM(RTRIM(WOP.[CustomerReference])), '') AS [CustomerReference]
                           FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
                           INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.[ID] = I.[SubReferenceId]
                           WHERE I.[BillingInvoicingId] = BI.[BillingInvoicingId]) R) CR
        -- Latest quote of the WO.
        OUTER APPLY (SELECT TOP (1) Q.[QuoteNumber], Q.[VersionNo] FROM [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
                     WHERE Q.[WorkOrderId] = WO.[WorkOrderId] AND ISNULL(Q.[IsDeleted], 0) = 0
                     ORDER BY Q.[WorkOrderQuoteId] DESC) WQ
        -- Management structure of the invoiced WO part.
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                     FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
                     INNER JOIN [dbo].[WorkOrderManagementStructureDetails] M WITH (NOLOCK) ON M.[ModuleID] = @WOMSModuleId AND M.[ReferenceID] = I.[SubReferenceId]
                     WHERE I.[BillingInvoicingId] = BI.[BillingInvoicingId]
                     ORDER BY I.[BillingInvoicingItemId]) MS
        -- Deposit as printed: the order's proforma deposits less the used deposits (NULL when the order has no proforma).
        OUTER APPLY (SELECT CAST(SUM(ISNULL(PF.[DepositAmount], 0)) - SUM(ISNULL(PF.[UsedDeposit], 0)) AS DECIMAL(18, 2)) AS [Available]
                     FROM [dbo].[BillingInvoicing] PF WITH (NOLOCK)
                     WHERE PF.[ReferenceId] = BI.[ReferenceId] AND PF.[ModuleId] = BI.[ModuleId] AND ISNULL(PF.[IsPerformaInvoice], 0) = 1) PD
        CROSS APPLY (SELECT CASE WHEN ISNULL(BI.[IsPerformaInvoice], 0) = 0 AND ISNULL(BI.[DepositAmount], 0) >= PD.[Available]
                                 THEN PD.[Available] ELSE ISNULL(BI.[DepositAmount], 0) END AS [Deposit]) D
        WHERE P.[DocumentType] = 'WorkOrder'

        UNION ALL

        SELECT
            P.[IsExchange],
            P.[InvoicingId],
            BI.[InvoiceNo],
            BI.[InvoiceDate],
            BI.[InvoiceStatus],
            CAST(ISNULL(BI.[IsPerformaInvoice], 0) AS BIT),
            P.[DocumentType],
            SO.[SalesOrderNumber],
            C.[Name],
            C.[CustomerCode],
            CT.[CustomerTypeName],
            NULLIF(LTRIM(RTRIM(SO.[CustomerReference])), ''),
            SQ.[SalesOrderQuoteNumber],
            SQ.[VersionNumber],
            CUR.[Code],
            ISNULL(BI.[SalesTax], 0),
            ISNULL(BI.[OtherTax], 0),
            ISNULL(BI.[GrandTotal], 0),
            D.[Deposit],
            ISNULL(BI.[GrandTotal], 0) - D.[Deposit],
            MS.[Level1Name],
            MS.[Level2Name],
            MS.[Level3Name],
            MS.[Level4Name],
            (SELECT COUNT(1) FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
             WHERE I.[BillingInvoicingId] = BI.[BillingInvoicingId] AND ISNULL(I.[IsDeleted], 0) = 0),
            P.[TotalRecords],
            P.[RowNo]
        FROM @Page P
        INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.[BillingInvoicingId] = P.[InvoicingId]
        LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.[SalesOrderId] = BI.[ReferenceId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = SO.[CustomerId]
        LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON CT.[CustomerTypeId] = C.[CustomerTypeId]
        LEFT JOIN [dbo].[SalesOrderQuote] SQ WITH (NOLOCK) ON SQ.[SalesOrderQuoteId] = SO.[SalesOrderQuoteId]
        LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON CUR.[CurrencyId] = BI.[CurrencyId]
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                     FROM [dbo].[SalesOrderManagementStructureDetails] M WITH (NOLOCK)
                     WHERE M.[ModuleID] = @SOMSModuleId AND M.[ReferenceID] = BI.[ReferenceId]
                     ORDER BY M.[MSDetailsId]) MS
        OUTER APPLY (SELECT CAST(SUM(ISNULL(PF.[DepositAmount], 0)) - SUM(ISNULL(PF.[UsedDeposit], 0)) AS DECIMAL(18, 2)) AS [Available]
                     FROM [dbo].[BillingInvoicing] PF WITH (NOLOCK)
                     WHERE PF.[ReferenceId] = BI.[ReferenceId] AND PF.[ModuleId] = BI.[ModuleId] AND ISNULL(PF.[IsPerformaInvoice], 0) = 1) PD
        CROSS APPLY (SELECT CASE WHEN ISNULL(BI.[IsPerformaInvoice], 0) = 0 AND ISNULL(BI.[DepositAmount], 0) >= PD.[Available]
                                 THEN PD.[Available] ELSE ISNULL(BI.[DepositAmount], 0) END AS [Deposit]) D
        WHERE P.[DocumentType] = 'SalesOrder'

        UNION ALL

        SELECT
            P.[IsExchange],
            P.[InvoicingId],
            X.[InvoiceNo],
            X.[InvoiceDate],
            X.[InvoiceStatus],
            CAST(0 AS BIT),
            P.[DocumentType],
            ESO.[ExchangeSalesOrderNumber],
            C.[Name],
            C.[CustomerCode],
            CT.[CustomerTypeName],
            NULLIF(LTRIM(RTRIM(ESO.[CustomerReference])), ''),
            EQ.[ExchangeQuoteNumber],
            EQ.[VersionNumber],
            CUR.[Code],
            ISNULL(X.[SalesTax], 0),
            ISNULL(X.[OtherTax], 0),
            ISNULL(X.[GrandTotal], 0),
            CAST(0 AS DECIMAL(18, 2)),
            ISNULL(X.[GrandTotal], 0),
            MS.[Level1Name],
            MS.[Level2Name],
            MS.[Level3Name],
            MS.[Level4Name],
            (SELECT COUNT(1) FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] I WITH (NOLOCK)
             WHERE I.[SOBillingInvoicingId] = X.[SOBillingInvoicingId] AND I.[IsDeleted] = 0),
            P.[TotalRecords],
            P.[RowNo]
        FROM @Page P
        INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] X WITH (NOLOCK) ON X.[SOBillingInvoicingId] = P.[InvoicingId]
        LEFT JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.[ExchangeSalesOrderId] = X.[ExchangeSalesOrderId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = X.[CustomerId]
        LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON CT.[CustomerTypeId] = C.[CustomerTypeId]
        LEFT JOIN [dbo].[ExchangeQuote] EQ WITH (NOLOCK) ON EQ.[ExchangeQuoteId] = ESO.[ExchangeQuoteId]
        LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON CUR.[CurrencyId] = X.[CurrencyId]
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                     FROM [dbo].[ExchangeManagementStructureDetails] M WITH (NOLOCK)
                     WHERE M.[ModuleID] = @EXMSModuleId AND M.[ReferenceID] = X.[ExchangeSalesOrderId]
                     ORDER BY M.[MSDetailsId]) MS
        WHERE P.[DocumentType] = 'Exchange'
        ORDER BY [RowNo]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetBillingInvoicingList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@InvoiceNumber, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@DocumentType, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@DocumentNumber, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@CustomerCode, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@InvoiceStatus, '') AS VARCHAR(100))
                                                   + '@Parameter9 = ''' + CAST(ISNULL(@InvoiceDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter10 = ''' + CAST(ISNULL(@InvoiceDateTo, '') AS VARCHAR(100))
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