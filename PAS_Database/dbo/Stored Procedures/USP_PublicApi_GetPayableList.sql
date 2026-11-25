/*****************************************************************************************
** PAS_PUBLIC_API_017_Payable.sql
**
** GET /api/v1/payables - open payables with aging, the same rows and amounts as the PAS
** Accounts Payable Aging Report (Reports > Accounts Payable Aging Report, Detail view).
**
**     USP_PublicApi_GetPayableList    payables (paged; filters: VendorCode, DocumentType,
**                                     DocumentNumber, InvoiceNumber)
**
** The procedure runs dbo.usprpt_GetAPAgingReport (viewType 2 = Detail) and reads its result with
** INSERT ... EXEC, so the amounts always follow the PAS report. That report returns amounts as
** formatted text (e.g. 1,234.56) and dates as MM/dd/yyyy text; they are converted back here.
** If columns are added to or removed from the report's Detail result, update #APAging to match.
**
** Run on the default database AND every tenant database. Safe to run again.
*****************************************************************************************/

/*************************************************************
 ** File:   [USP_PublicApi_GetPayableList]
 ** Author: Bhargav Saliya
 ** Description: Open payables (PO / RO invoices, non-PO invoices, credit memos, manual journals, migrated invoices)
 **              with aging, from the PAS Accounts Payable Aging Report (dbo.usprpt_GetAPAgingReport, Detail view,
 **              no other filter, same as the report default). Oldest invoice date first.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/payables
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetPayableList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPayableList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @VendorCode      VARCHAR(100) = NULL,
    @DocumentType    VARCHAR(50)  = NULL,
    @DocumentNumber  VARCHAR(100) = NULL,
    @InvoiceNumber   VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID(N'tempdb..#APAging') IS NOT NULL
            DROP TABLE #APAging;

        -- Same columns, same order as the Detail result of dbo.usprpt_GetAPAgingReport.
        CREATE TABLE #APAging
        (
            [VendorId] BIGINT, [vendorName] VARCHAR(200), [vendorCode] VARCHAR(100), [InvoiceNo] VARCHAR(100), [invoiceNumber] VARCHAR(200),
            [InvoiceDate] VARCHAR(50), [InvoiceAmount] VARCHAR(50), [BalanceAmount] VARCHAR(50),
            [Amountpaidbylessthen0days] VARCHAR(50), [Amountpaidby30days] VARCHAR(50), [Amountpaidby60days] VARCHAR(50),
            [Amountpaidby90days] VARCHAR(50), [Amountpaidby120days] VARCHAR(50), [Amountpaidbymorethan120days] VARCHAR(50),
            [level1] VARCHAR(500), [level2] VARCHAR(500), [level3] VARCHAR(500), [level4] VARCHAR(500), [level5] VARCHAR(500),
            [level6] VARCHAR(500), [level7] VARCHAR(500), [level8] VARCHAR(500), [level9] VARCHAR(500), [level10] VARCHAR(500),
            [DocType] VARCHAR(100), [Terms] VARCHAR(200), [DueDate] VARCHAR(50), [currencyCode] VARCHAR(20), [FixRateAmount] VARCHAR(50),
            [TotalInvoiceAmount] VARCHAR(50), [TotalBalanceAmount] VARCHAR(50), [TotalAmountpaidbylessthen0days] VARCHAR(50),
            [TotalAmountpaidby30days] VARCHAR(50), [TotalAmountpaidby60days] VARCHAR(50), [TotalAmountpaidby90days] VARCHAR(50),
            [TotalAmountpaidby120days] VARCHAR(50), [TotalAmountpaidbymorethan120days] VARCHAR(50), [TotalPoCost] VARCHAR(50),
            [DaysPastDue] INT, [poReference] VARCHAR(MAX), [poCost] VARCHAR(50), [IsMigrated] BIT, [TotalRecordsCount] INT
        );

        -- Report default: Detail view, no vendor / level / column filters.
        DECLARE @XmlFilter XML = N'<ArrayOfFilter><Filter><FieldName>viewType</FieldName><FieldValue>2</FieldValue></Filter></ArrayOfFilter>';

        INSERT INTO #APAging
        EXEC [dbo].[usprpt_GetAPAgingReport]
             @PageNumber = 1, @PageSize = 2147483647, @mastercompanyid = @MasterCompanyId,
             @xmlFilter = @XmlFilter, @SortColumn = NULL, @SortOrder = NULL;

        ;WITH Payable AS
        (
            SELECT A.*,
                   CASE UPPER(A.[DocType]) WHEN 'PO-INV'                    THEN 'PO'
                                           WHEN 'RO-INV'                    THEN 'RO'
                                           WHEN 'CREDIT MEMO'               THEN 'CM'
                                           WHEN 'NPO-INV'                   THEN 'Non-PO Invoice'
                                           WHEN 'MANUAL JOURNAL ADJUSTMENT' THEN 'Manual Journal'
                                           WHEN 'MIGRATED-INV'              THEN 'Migrated Invoice'
                                           ELSE A.[DocType] END AS [DocumentType],
                   TRY_CONVERT(DATE, A.[InvoiceDate], 101) AS [InvoiceDateValue]
            FROM #APAging A
            WHERE (@VendorCode IS NULL OR A.[vendorCode] = @VendorCode)
              AND (@DocumentNumber IS NULL OR A.[InvoiceNo] = @DocumentNumber)
              AND (@InvoiceNumber IS NULL OR A.[invoiceNumber] = @InvoiceNumber)
        )
        SELECT
            NULLIF(P.[vendorCode], '') AS [VendorCode],
            NULLIF(P.[vendorName], '') AS [VendorName],
            NULLIF(P.[InvoiceNo], '') AS [DocumentNumber],                 -- PAS "Doc Num"
            P.[DocumentType],
            NULLIF(P.[invoiceNumber], '') AS [InvoiceNumber],              -- PAS "Invoice Num"
            P.[InvoiceDateValue] AS [InvoiceDate],
            TRY_CONVERT(DATE, P.[DueDate], 101) AS [InvoiceDueDate],
            NULLIF(P.[Terms], '') AS [InvoiceTerms],
            NULLIF(P.[currencyCode], '') AS [Currency],
            ISNULL(TRY_CAST(REPLACE(P.[InvoiceAmount], ',', '') AS DECIMAL(18,2)), 0) AS [InvoiceAmount],
            ISNULL(TRY_CAST(REPLACE(P.[BalanceAmount], ',', '') AS DECIMAL(18,2)), 0) AS [Balance],
            ISNULL(TRY_CAST(REPLACE(P.[Amountpaidbylessthen0days], ',', '') AS DECIMAL(18,2)), 0) AS [CurrentAmount],   -- PAS "Current" (not yet due)
            ISNULL(TRY_CAST(REPLACE(P.[Amountpaidby30days], ',', '') AS DECIMAL(18,2)), 0) AS [Days0To30],
            ISNULL(TRY_CAST(REPLACE(P.[Amountpaidby60days], ',', '') AS DECIMAL(18,2)), 0) AS [Days31To60],
            ISNULL(TRY_CAST(REPLACE(P.[Amountpaidby90days], ',', '') AS DECIMAL(18,2)), 0) AS [Days61To90],
            ISNULL(TRY_CAST(REPLACE(P.[Amountpaidby120days], ',', '') AS DECIMAL(18,2)), 0) AS [Days91To120],
            ISNULL(TRY_CAST(REPLACE(P.[Amountpaidbymorethan120days], ',', '') AS DECIMAL(18,2)), 0) AS [Over120Days],
            NULLIF(CONCAT_WS(' > ', NULLIF(P.[level1], ''), NULLIF(P.[level2], ''), NULLIF(P.[level3], ''), NULLIF(P.[level4], ''),
                             NULLIF(P.[level5], ''), NULLIF(P.[level6], ''), NULLIF(P.[level7], ''), NULLIF(P.[level8], ''),
                             NULLIF(P.[level9], ''), NULLIF(P.[level10], '')), '') AS [ManagementStructure],
            COUNT(1) OVER () AS [TotalRecords]
        FROM Payable P
        WHERE (@DocumentType IS NULL OR P.[DocumentType] = @DocumentType)
        ORDER BY P.[InvoiceDateValue], P.[InvoiceNo], P.[VendorId]
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY;

        DROP TABLE #APAging;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetPayableList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@VendorCode, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@DocumentType, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@DocumentNumber, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@InvoiceNumber, '') AS VARCHAR(200))
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