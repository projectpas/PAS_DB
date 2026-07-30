
/*************************************************************
 ** File:    [USP_GetTrailBalanceReportColumns]
 ** Author:  Hemant Saliya
 ** Description: Returns dynamic accounting period column metadata
 **              for the Trial Balance multi-period grid.
 **              Called by UI BEFORE running the main report SP so
 **              the grid can build its column headers dynamically.
 **
 **              Result set contains one row per period column,
 **              plus fixed summary column descriptors at the end.
 **
 ** Date:    05/14/2026
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author          Change Description
 ** --   ----------   --------------  --------------------------------
    1    05/14/2026   Hemant Saliya   Created — companion SP to
                                      USP_GetTrailBalanceReportData_MultiplePerod
                                      to supply dynamic column headers to UI.
 **************************************************************
 -- Example:
 exec dbo.USP_GetTrailBalanceReportColumns
      @masterCompanyId      = 21,
      @StartAccountingPeriodId = 322,
      @EndAccountingPeriodId   = 325,
      @strFilter            = N'70!71'
*************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportColumns]
(
    @masterCompanyId             VARCHAR(50)  = NULL,
    @StartAccountingPeriodId     BIGINT       = NULL,
    @EndAccountingPeriodId       BIGINT       = NULL,
    @strFilter                   VARCHAR(MAX) = NULL
)
AS
BEGIN
    BEGIN TRY
    BEGIN

        ---------------------------------------------------------------------------
        -- Null-safety: if only one period param supplied, default the other
        ---------------------------------------------------------------------------
        IF @StartAccountingPeriodId IS NULL SET @StartAccountingPeriodId = @EndAccountingPeriodId;
        IF @EndAccountingPeriodId   IS NULL SET @EndAccountingPeriodId   = @StartAccountingPeriodId;

        ---------------------------------------------------------------------------
        -- Parse MS filter Level 1 only — needed to resolve Legal Entities
        -- (same logic as the main SP so period resolution is identical)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#ColTEMPMSFilter') IS NOT NULL DROP TABLE #ColTEMPMSFilter;
        CREATE TABLE #ColTEMPMSFilter (ID BIGINT IDENTITY(1,1), LevelIds VARCHAR(MAX));
        INSERT INTO #ColTEMPMSFilter (LevelIds)
        SELECT Item FROM DBO.SPLITSTRING(@strFilter, '!');

        DECLARE @level1 VARCHAR(MAX) = NULL;
        SELECT  @level1 = LevelIds FROM #ColTEMPMSFilter WHERE ID = 1;

        IF OBJECT_ID(N'tempdb..#ColL1') IS NOT NULL DROP TABLE #ColL1;
        CREATE TABLE #ColL1 (Item VARCHAR(MAX));
        IF ISNULL(@level1, '') <> ''
            INSERT INTO #ColL1 SELECT Item FROM DBO.SPLITSTRING(@level1, ',');

        ---------------------------------------------------------------------------
        -- Resolve Legal Entities from Level 1 filter
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#ColLegalEntities') IS NOT NULL DROP TABLE #ColLegalEntities;
        CREATE TABLE #ColLegalEntities (LegalEntityId BIGINT PRIMARY KEY);

        INSERT INTO #ColLegalEntities (LegalEntityId)
        SELECT DISTINCT MSL.LegalEntityId
        FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
        WHERE  MSL.ID IN (SELECT Item FROM #ColL1)
          AND  MSL.LegalEntityId IS NOT NULL;

        ---------------------------------------------------------------------------
        -- Build the period column list — exactly mirrors #SelectedPeriods in
        -- the main SP so column names are guaranteed to match.
        --
        -- ColumnType values:
        --   'PERIOD'  — one per selected accounting period (monthly balance column)
        --   'YTD'     — single column: cumulative balance through last period
        --   'TOTAL'   — single column: sum of all period monthly balances
        --
        -- FieldKey   — the programmatic key used in the pivot result set
        --              (matches the column alias produced by the main SP)
        -- ColumnLabel — the human-readable header to display in the UI grid
        -- SortOrder   — use this to sequence columns left → right in the grid
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#PeriodColumns') IS NOT NULL DROP TABLE #PeriodColumns;
        CREATE TABLE #PeriodColumns
        (
            SortOrder   INT,
            ColumnType  VARCHAR(50),   -- 'PERIOD' | 'YTD' | 'TOTAL'
            fieldName    VARCHAR(60),   -- programmatic key (matches SP pivot alias)
            headerName VARCHAR(60),   -- display label for UI grid header
            AccountingPeriodId BIGINT, -- NULL for summary columns
			fieldGridWidth INT,
        );

        -- ---- Dynamic period columns (one row per selected period) ----
        INSERT INTO #PeriodColumns (SortOrder, ColumnType, fieldName, headerName, AccountingPeriodId, fieldGridWidth)
        SELECT
            ROW_NUMBER() OVER (ORDER BY AC.FiscalYear, AC.[Period]) AS SortOrder,
            'PERIOD'                                                 AS ColumnType,
            -- FieldKey matches the alias generated in the main SP:
            --   "[Mar 2026]", "[Apr 2026]", etc.
            LEFT(DATENAME(MONTH, AC.ToDate), 3) + '_' + CAST(YEAR(AC.ToDate) AS VARCHAR(4)) AS FieldKey,
            -- ColumnLabel — same value, used as grid header text
            LEFT(DATENAME(MONTH, AC.ToDate), 3) + ' ' + CAST(YEAR(AC.ToDate) AS VARCHAR(4)) AS ColumnLabel,
            AC.AccountingCalendarId,
			100
        FROM dbo.AccountingCalendar AC WITH (NOLOCK)
        WHERE AC.MasterCompanyId             = @masterCompanyId
          AND AC.IsDeleted                   = 0
          AND ISNULL(AC.IsAdjustPeriod, 0)   = 0
          AND AC.AccountingCalendarId BETWEEN @StartAccountingPeriodId AND @EndAccountingPeriodId
          AND AC.LegalEntityId IN (SELECT LegalEntityId FROM #ColLegalEntities);

        -- ---- Fixed summary columns appended after period columns ----
        DECLARE @MaxSort INT;
        SELECT  @MaxSort = ISNULL(MAX(SortOrder), 0) FROM #PeriodColumns;

        ---- YTD Balance — cumulative from beginning through last selected period
        --INSERT INTO #PeriodColumns (SortOrder, ColumnType, fieldName, headerName, AccountingPeriodId, fieldGridWidth)
        --VALUES (@MaxSort + 1, 'YTD', 'ytdBalance', 'YTD Balance', NULL, 100);

        -- Total Balance — sum of all selected period monthly balances
        INSERT INTO #PeriodColumns (SortOrder, ColumnType, fieldName, headerName, AccountingPeriodId, fieldGridWidth)
        VALUES (@MaxSort + 2, 'TOTAL', 'totalBalance', 'Total Balance', NULL, 100);

		INSERT INTO #PeriodColumns (SortOrder, ColumnType, fieldName, headerName, AccountingPeriodId, fieldGridWidth)
		VALUES (0, 'accountNum', 'accountNum', 'Account Num', NULL, 100);

		INSERT INTO #PeriodColumns (SortOrder, ColumnType, fieldName, headerName, AccountingPeriodId, fieldGridWidth)
		VALUES (0, 'accountName', 'accountName', 'Account Name', NULL, 100);

        ---------------------------------------------------------------------------
        -- Return result to UI
        -- UI iterates this result and builds one grid column per row.
        -- Fixed columns (AccountNum, AccountName, MS levels) are added by the UI
        -- separately and do not appear here.
        ---------------------------------------------------------------------------
        SELECT
            SortOrder,
            ColumnType,
            fieldName,
            headerName,
            AccountingPeriodId,
			fieldGridWidth
        FROM #PeriodColumns
        ORDER BY SortOrder;

    END
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100) = DB_NAME(),
            @AdhocComments       VARCHAR(150) = 'USP_GetTrailBalanceReportColumns',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''',
            @ApplicationName     VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END