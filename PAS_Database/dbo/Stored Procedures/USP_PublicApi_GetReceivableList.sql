/*****************************************************************************************
** PAS_PUBLIC_API_016_Receivable.sql
**
** GET /api/v1/receivables - open receivables with aging, the same rows and amounts as the
** PAS Customer Aging Report (Accounting > Accounts Receivable > Customer Register, Details view).
**
**     USP_PublicApi_GetReceivableList    receivables (paged; filters: CustomerCode, DocumentType,
**                                        DocumentNumber, InvoiceNumber)
**
** The procedure runs dbo.usprpt_GetARAgingAsOfNowReport (Details) and reads its result with
** INSERT ... EXEC, so the amounts always follow the PAS report. If columns are added to or removed
** from that report's Details result, update #ARAging below to match.
**
** Run on the default database AND every tenant database. Safe to run again.
*****************************************************************************************/

/*************************************************************
 ** File:   [USP_PublicApi_GetReceivableList]
 ** Author: Bhargav Saliya
 ** Description: Open receivables (invoices, credit memos, manual journals, unapplied cash) with aging,
 **              from the PAS Customer Aging Report (dbo.usprpt_GetARAgingAsOfNowReport, Details view:
 **              invoices, credits and unapplied amounts; deposits not included, same as the screen default).
 **              Oldest invoice date first.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/receivables
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetReceivableList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetReceivableList]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT,
    @PageNumber      INT,
    @PageSize        INT,
    @CustomerCode    VARCHAR(50) = NULL,
    @DocumentType    VARCHAR(50) = NULL,
    @DocumentNumber  VARCHAR(50) = NULL,
    @InvoiceNumber   VARCHAR(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID(N'tempdb..#ARAging') IS NOT NULL
            DROP TABLE #ARAging;

        -- Same columns, same order as the Details result of dbo.usprpt_GetARAgingAsOfNowReport.
        CREATE TABLE #ARAging
        (
            [BillingInvoicingId] BIGINT, [CustomerId] BIGINT, [CustomerName] VARCHAR(200), [CustomerCode] VARCHAR(50),
            [CustomerAffiliation] VARCHAR(50), [CurrencyCode] VARCHAR(50), [DocType] VARCHAR(50), [InvoiceNo] VARCHAR(50),
            [InvoiceNumber] VARCHAR(80), [InvoiceDate] DATETIME2, [DSI] INT, [DSO] INT, [DSS] INT, [DueDate] DATETIME2,
            [CustomerRef] VARCHAR(2000), [Salesperson] VARCHAR(100), [CreditTerms] VARCHAR(100),
            [BalanceAmount] DECIMAL(18,2), [CurrentAmount] DECIMAL(18,2), [PaymentAmount] DECIMAL(18,2),
            [Amountlessthan0days] DECIMAL(18,2), [Amountlessthan30days] DECIMAL(18,2), [Amountlessthan60days] DECIMAL(18,2),
            [Amountlessthan90days] DECIMAL(18,2), [Amountlessthan120days] DECIMAL(18,2), [Amountmorethan120days] DECIMAL(18,2),
            [InvoiceAmount] DECIMAL(18,2), [CMAmount] DECIMAL(18,2), [CreditMemoAmount] DECIMAL(18,2), [CreditMemoUsed] DECIMAL(18,2),
            [fxRateAmount] VARCHAR(20),
            [Level1Id] BIGINT, [Level2Id] BIGINT, [Level3Id] BIGINT, [Level4Id] BIGINT, [Level5Id] BIGINT,
            [Level6Id] BIGINT, [Level7Id] BIGINT, [Level8Id] BIGINT, [Level9Id] BIGINT, [Level10Id] BIGINT,
            [level1] VARCHAR(500), [level2] VARCHAR(500), [level3] VARCHAR(500), [level4] VARCHAR(500), [level5] VARCHAR(500),
            [level6] VARCHAR(500), [level7] VARCHAR(500), [level8] VARCHAR(500), [level9] VARCHAR(500), [level10] VARCHAR(500),
            [MasterCompanyId] INT, [StatusId] BIGINT, [IsCreditMemo] BIT, [InvoicePaidAmount] DECIMAL(18,2), [ModuleTypeId] INT,
            [LegalEntityName] VARCHAR(MAX), [ReceivedAmount] DECIMAL(18,2),
            [NumberOfItems] INT, [TotalAmount] DECIMAL(18,2), [TotalCurrentAmount] DECIMAL(18,2), [TotalReceivedAmount] DECIMAL(18,2),
            [TotalAmountlessthan0days] DECIMAL(18,2), [TotalAmountlessthan30days] DECIMAL(18,2), [TotalAmountlessthan60days] DECIMAL(18,2),
            [TotalAmountlessthan90days] DECIMAL(18,2), [TotalAmountlessthan120days] DECIMAL(18,2), [TotalAmountmorethan120days] DECIMAL(18,2)
        );

        -- Screen defaults: invoices, credits and unapplied amounts; all management structure levels.
        INSERT INTO #ARAging
        EXEC [dbo].[usprpt_GetARAgingAsOfNowReport]
             @PageNumber = 1, @PageSize = 2147483647, @SortColumn = N'InvoiceDate', @SortOrder = 1, @GlobalFilter = N'',
             @ViewType = N'Details', @IsInvoice = 1, @IsCredits = 1, @IsDeposit = 0, @IsUnappliedAmounts = 1,
             @strFilter = N'!!!!!!!!!', @EmployeeId = @EmployeeId, @MasterCompanyId = @MasterCompanyId;

        ;WITH Receivable AS
        (
            SELECT A.*,
                   CASE A.[ModuleTypeId] WHEN 1 THEN 'WO'
                                         WHEN 2 THEN 'SO'
                                         WHEN 3 THEN 'Exchange'
                                         WHEN 4 THEN 'CM'
                                         WHEN 5 THEN 'Stand Alone CM'
                                         WHEN 6 THEN 'Manual Journal'
                                         WHEN 7 THEN 'Unapplied Cash'
                                         ELSE A.[DocType] END AS [DocumentType]
            FROM #ARAging A
            WHERE (@CustomerCode IS NULL OR A.[CustomerCode] = @CustomerCode)
              AND (@DocumentNumber IS NULL OR A.[InvoiceNo] = @DocumentNumber)
              AND (@InvoiceNumber IS NULL OR A.[InvoiceNumber] = @InvoiceNumber)
        )
        SELECT
            R.[InvoiceNo] AS [DocumentNumber],
            R.[DocumentType],
            NULLIF(R.[InvoiceNumber], '') AS [InvoiceNumber],
            R.[InvoiceDate],
            NULLIF(R.[CreditTerms], '') AS [InvoiceTerms],
            -- Invoices in the report are always "Invoiced" (open); credit memos show their PAS status.
            CASE WHEN R.[ModuleTypeId] IN (1, 2, 3) THEN 'Invoiced'
                 WHEN R.[ModuleTypeId] IN (4, 5) THEN CMS.[Name]
                 WHEN R.[ModuleTypeId] = 6 THEN 'Posted'
                 WHEN R.[ModuleTypeId] = 7 THEN 'Unapplied'
                 ELSE NULL END AS [InvoiceStatus],
            R.[CurrencyCode] AS [Currency],
            R.[InvoiceAmount] AS [Amount],
            R.[CustomerName],
            R.[CustomerCode],
            R.[CustomerAffiliation] AS [CustomerType],
            NULLIF(R.[CustomerRef], '') AS [CustomerReference],
            R.[DSI],
            R.[DSO],
            ISNULL(R.[ReceivedAmount], 0) AS [ReceivedAmount],
            ISNULL(R.[CurrentAmount], 0) AS [Balance],                  -- PAS "Balance Amt"
            ISNULL(R.[Amountlessthan0days], 0) AS [CurrentAmount],      -- PAS "Current" (not yet due)
            ISNULL(R.[Amountlessthan30days], 0) AS [Days0To30],
            ISNULL(R.[Amountlessthan60days], 0) AS [Days31To60],
            ISNULL(R.[Amountlessthan90days], 0) AS [Days61To90],
            ISNULL(R.[Amountlessthan120days], 0) AS [Days91To120],
            ISNULL(R.[Amountmorethan120days], 0) AS [Over120Days],
            NULLIF(CONCAT_WS(' > ', NULLIF(R.[level1], ''), NULLIF(R.[level2], ''), NULLIF(R.[level3], ''), NULLIF(R.[level4], ''),
                             NULLIF(R.[level5], ''), NULLIF(R.[level6], ''), NULLIF(R.[level7], ''), NULLIF(R.[level8], ''),
                             NULLIF(R.[level9], ''), NULLIF(R.[level10], '')), '') AS [ManagementStructure],
            COUNT(1) OVER () AS [TotalRecords]
        FROM Receivable R
        LEFT JOIN [dbo].[CreditMemoStatus] CMS WITH (NOLOCK) ON CMS.[Id] = R.[StatusId]
        WHERE (@DocumentType IS NULL OR R.[DocumentType] = @DocumentType)
        ORDER BY R.[InvoiceDate], R.[InvoiceNo], R.[BillingInvoicingId]
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY;

        DROP TABLE #ARAging;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetReceivableList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@CustomerCode, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@DocumentType, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@DocumentNumber, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@InvoiceNumber, '') AS VARCHAR(100))
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