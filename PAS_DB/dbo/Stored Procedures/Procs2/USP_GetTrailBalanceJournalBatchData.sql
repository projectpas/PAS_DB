/*************************************************************
 ** File:    [USP_GetTrailBalanceJournalBatchData]
 ** Author:  Devendra Shekh
 ** Description: Retrieves Trial Balance journal batch details by GL Account ID
 ** Date:    07/24/2023
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author          Change Description
 ** --   ----------   -------------   --------------------------------
    1    07/24/2023   Devendra Shekh  Created
    2    08/08/2023   Devendra Shekh  Ambiguous column error resolved
    3    08/10/2023   Devendra Shekh  Modified the SP
    4    09/01/2023   Hemant Saliya   Added MS Filters
    5    01/25/2024   Hemant Saliya   Remove Manual Journal from Reports
    6    04/08/2024   Hemant Saliya   Added Management Structure Filters & Get AC Based on LE
    7    10/07/2025   Bhargav Saliya  Added ReferenceNumber field
    8    09/02/2026   Bhargav Saliya  Added JournalTypeName field
	9    03/04/2026   Moin Bloch      Added Pagination PN-15886
	10   06/04/2026   Moin Bloch      Added @Balance Field PN-15886
	11   06/04/2026   Moin Bloch      Fix For Future data comming PN-15990
	12   08/16/2026   <You>           Replaced single @id with @StartAccountingPeriodId /
	                                   @EndAccountingPeriodId. Class-aware balance window,
	                                   aligned to USP_GetTrailBalanceReportData_MultiplePerod
	                                   so drill-down detail reconciles to the report cell:
	                                     Balance Sheet (Asset/Liabilities/Owners Equity)
	                                        = all periods with ToDate <= End period (from beginning)
	                                     Income Statement (Revenue/Expense)
	                                        = current fiscal year (End period FiscalYear) to End period
	                                     Other/unclassified = full history (report fallback)

 **************************************************************

 EXEC [USP_GetTrailBalanceJournalBatchData]
      @PageSize = 10, @PageNumber = 1, @SortColumn = NULL, @SortOrder = 2,
      @masterCompanyId = '1', @managementStructureId = '1',
      @StartAccountingPeriodId = '318',   -- start of the selected range
      @EndAccountingPeriodId   = '329',   -- end / "current" period selected
      @GlAccId = 134,
      @xmlFilter = N'
 <?xml version="1.0" encoding="utf-16"?>
 <ArrayOfFilter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <Filter><FieldName>Level1</FieldName><FieldValue>5</FieldValue></Filter>
   <Filter><FieldName>Level2</FieldName><FieldValue>8</FieldValue></Filter>
   <Filter><FieldName>Level3</FieldName><FieldValue>11,10</FieldValue></Filter>
   <Filter><FieldName>Level4</FieldName><FieldValue>12</FieldValue></Filter>
   <Filter><FieldName>Level5</FieldName><FieldValue /></Filter>
   <Filter><FieldName>Level6</FieldName><FieldValue /></Filter>
   <Filter><FieldName>Level7</FieldName><FieldValue /></Filter>
   <Filter><FieldName>Level8</FieldName><FieldValue /></Filter>
   <Filter><FieldName>Level9</FieldName><FieldValue /></Filter>
   <Filter><FieldName>Level10</FieldName><FieldValue /></Filter>
 </ArrayOfFilter>'
*************************************************************/

CREATE PROCEDURE [dbo].[USP_GetTrailBalanceJournalBatchData]
(
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@JournalNumber VARCHAR(100) = NULL,
	@JournalTypeName VARCHAR(150) = NULL,
	@GLAccount VARCHAR(100) = NULL,
	@PeriodNames VARCHAR(100) = NULL,
	@ReferenceNumber VARCHAR(150) = NULL,
	@Balance VARCHAR(50) = NULL,
    @masterCompanyId         VARCHAR(50)  = NULL,
    @managementStructureId   VARCHAR(50)  = NULL,
    @StartAccountingPeriodId VARCHAR(50)  = NULL,   -- was @id : start of the selected period range
    @EndAccountingPeriodId   VARCHAR(50)  = NULL,   -- NEW    : end / "current" period selected
    @GlAccId                 BIGINT,
    @xmlFilter               XML,
	@EmployeeId BIGINT = NULL
)
AS
BEGIN
    BEGIN TRY
    BEGIN
		DECLARE @CustomerRefundModuleId BIGINT = 0;
		DECLARE @RecordFrom INT;
		DECLARE @TotalRecordsCount INT;
		SET @RecordFrom = (@PageNumber-1) * @PageSize;

		SELECT @CustomerRefundModuleId = [ModuleId] FROM [dbo].[Module] WHERE [ModuleName] = 'CustomerRefund';
        ---------------------------------------------------------------------------
        -- Variable Declarations
        ---------------------------------------------------------------------------
        DECLARE @BatchMSModuleId     BIGINT;
        DECLARE @PostedBatchStatusId BIGINT;
        DECLARE @PeriodName          VARCHAR(100);
		DECLARE @FromDate DATETIME = NULL,@ToDate DATETIME = NULL,@PeriodEndDate DATETIME = NULL;

        -- Account-class driven balance window (mirrors USP_GetTrailBalanceReportData_MultiplePerod)
        DECLARE @EndFiscalYear     VARCHAR(20) = NULL;  -- fiscal year of the selected (End) period
        DECLARE @AccountClassId    BIGINT      = NULL;  -- GLAccount.GLAccountTypeId of @GlAccId
        DECLARE @IsBalanceSheet    BIT         = 0;     -- 1 = Asset / Liabilities / Owners Equity
        DECLARE @IsIncomeStatement BIT         = 0;     -- 1 = Revenue / Expense

        -- Class IDs resolved by name, scoped to MasterCompany (IDs are company-scoped).
        DECLARE @AssetClassId        BIGINT;
        DECLARE @LiabilityClassId    BIGINT;
        DECLARE @OwnersEquityClassId BIGINT;
        DECLARE @RevenueClassId      BIGINT;
        DECLARE @ExpenseClassId      BIGINT;

        DECLARE
            @level1  VARCHAR(MAX) = NULL,
            @level2  VARCHAR(MAX) = NULL,
            @level3  VARCHAR(MAX) = NULL,
            @level4  VARCHAR(MAX) = NULL,
            @level5  VARCHAR(MAX) = NULL,
            @level6  VARCHAR(MAX) = NULL,
            @level7  VARCHAR(MAX) = NULL,
            @level8  VARCHAR(MAX) = NULL,
            @level9  VARCHAR(MAX) = NULL,
            @level10 VARCHAR(MAX) = NULL;

        SET @BatchMSModuleId = 72; -- BATCH MS MODULE ID

        SELECT @PostedBatchStatusId = Id
        FROM   dbo.BatchStatus WITH (NOLOCK)
        WHERE  [Name] = 'Posted';

        ---------------------------------------------------------------------------
        -- Parse XML Filter into level variables
        ---------------------------------------------------------------------------
        SELECT
            @level1  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level1'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level1  END,
            @level2  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level2'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level2  END,
            @level3  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level3'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level3  END,
            @level4  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level4'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level4  END,
            @level5  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level5'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level5  END,
            @level6  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level6'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level6  END,
            @level7  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level7'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level7  END,
            @level8  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level8'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level8  END,
            @level9  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level9'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level9  END,
            @level10 = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level10' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @level10 END
        FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby);

        ---------------------------------------------------------------------------
        -- Pre-parse filter values into temp tables (avoid repeated SPLITSTRING calls)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#L1')  IS NOT NULL DROP TABLE #L1;
        IF OBJECT_ID(N'tempdb..#L2')  IS NOT NULL DROP TABLE #L2;
        IF OBJECT_ID(N'tempdb..#L3')  IS NOT NULL DROP TABLE #L3;
        IF OBJECT_ID(N'tempdb..#L4')  IS NOT NULL DROP TABLE #L4;
        IF OBJECT_ID(N'tempdb..#L5')  IS NOT NULL DROP TABLE #L5;
        IF OBJECT_ID(N'tempdb..#L6')  IS NOT NULL DROP TABLE #L6;
        IF OBJECT_ID(N'tempdb..#L7')  IS NOT NULL DROP TABLE #L7;
        IF OBJECT_ID(N'tempdb..#L8')  IS NOT NULL DROP TABLE #L8;
        IF OBJECT_ID(N'tempdb..#L9')  IS NOT NULL DROP TABLE #L9;
        IF OBJECT_ID(N'tempdb..#L10') IS NOT NULL DROP TABLE #L10;

        CREATE TABLE #L1  (Item VARCHAR(MAX));
        CREATE TABLE #L2  (Item VARCHAR(MAX));
        CREATE TABLE #L3  (Item VARCHAR(MAX));
        CREATE TABLE #L4  (Item VARCHAR(MAX));
        CREATE TABLE #L5  (Item VARCHAR(MAX));
        CREATE TABLE #L6  (Item VARCHAR(MAX));
        CREATE TABLE #L7  (Item VARCHAR(MAX));
        CREATE TABLE #L8  (Item VARCHAR(MAX));
        CREATE TABLE #L9  (Item VARCHAR(MAX));
        CREATE TABLE #L10 (Item VARCHAR(MAX));

        IF ISNULL(@level1,  '') <> '' INSERT INTO #L1  SELECT Item FROM DBO.SPLITSTRING(@level1,  ',');
        IF ISNULL(@level2,  '') <> '' INSERT INTO #L2  SELECT Item FROM DBO.SPLITSTRING(@level2,  ',');
        IF ISNULL(@level3,  '') <> '' INSERT INTO #L3  SELECT Item FROM DBO.SPLITSTRING(@level3,  ',');
        IF ISNULL(@level4,  '') <> '' INSERT INTO #L4  SELECT Item FROM DBO.SPLITSTRING(@level4,  ',');
        IF ISNULL(@level5,  '') <> '' INSERT INTO #L5  SELECT Item FROM DBO.SPLITSTRING(@level5,  ',');
        IF ISNULL(@level6,  '') <> '' INSERT INTO #L6  SELECT Item FROM DBO.SPLITSTRING(@level6,  ',');
        IF ISNULL(@level7,  '') <> '' INSERT INTO #L7  SELECT Item FROM DBO.SPLITSTRING(@level7,  ',');
        IF ISNULL(@level8,  '') <> '' INSERT INTO #L8  SELECT Item FROM DBO.SPLITSTRING(@level8,  ',');
        IF ISNULL(@level9,  '') <> '' INSERT INTO #L9  SELECT Item FROM DBO.SPLITSTRING(@level9,  ',');
        IF ISNULL(@level10, '') <> '' INSERT INTO #L10 SELECT Item FROM DBO.SPLITSTRING(@level10, ',');

        ---------------------------------------------------------------------------
        -- Build Accounting Period Table for the selected window across all Level1 LEs
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#AccPeriodTable') IS NOT NULL DROP TABLE #AccPeriodTable;

        CREATE TABLE #AccPeriodTable
        (
            ID                   BIGINT IDENTITY(1, 1) NOT NULL,
            AccountingCalendarId BIGINT       NOT NULL,
            PeriodName           VARCHAR(100) NULL,
            FromDate             DATETIME     NULL,
            ToDate               DATETIME     NULL
        );

        ---------------------------------------------------------------------------
        -- 1) Resolve the END (selected / drilled) period: its ToDate is the upper
        --    bound of the window, its FiscalYear scopes the income-statement window.
        --    (Mirrors #SelectedPeriods.PeriodEndDate / FiscalYear in the TB report.)
        ---------------------------------------------------------------------------
        SELECT @PeriodName    = UPPER(PeriodName),
               @PeriodEndDate = [ToDate],
               @EndFiscalYear = [FiscalYear]
        FROM [dbo].[AccountingCalendar] WITH (NOLOCK)
        WHERE [AccountingCalendarId] = @EndAccountingPeriodId;

        ---------------------------------------------------------------------------
        -- 2) Resolve the GL-account-class IDs by name (MasterCompany scoped),
        --    exactly as USP_GetTrailBalanceReportData_MultiplePerod does.
        --      Balance sheet   = Asset / Liabilities / Owners Equity
        --      Income statement = Revenue / Expense
        ---------------------------------------------------------------------------
        SELECT
            @AssetClassId        = MAX(CASE WHEN UPPER(GLAccountClassName) = 'ASSET'         THEN GLAccountClassId END),
            @LiabilityClassId    = MAX(CASE WHEN UPPER(GLAccountClassName) = 'LIABILITIES'   THEN GLAccountClassId END),
            @OwnersEquityClassId = MAX(CASE WHEN UPPER(GLAccountClassName) = 'OWNERS EQUITY' THEN GLAccountClassId END),
            @RevenueClassId      = MAX(CASE WHEN UPPER(GLAccountClassName) = 'REVENUE'       THEN GLAccountClassId END),
            @ExpenseClassId      = MAX(CASE WHEN UPPER(GLAccountClassName) = 'EXPENSE'       THEN GLAccountClassId END)
        FROM   dbo.GLAccountClass WITH (NOLOCK)
        WHERE  MasterCompanyId      = @masterCompanyId
          AND  ISNULL(IsDeleted, 0) = 0
          AND  ISNULL(IsActive,  0) = 1;

        SET @AssetClassId        = ISNULL(@AssetClassId,        -1);
        SET @LiabilityClassId    = ISNULL(@LiabilityClassId,    -1);
        SET @OwnersEquityClassId = ISNULL(@OwnersEquityClassId, -1);
        SET @RevenueClassId      = ISNULL(@RevenueClassId,      -1);
        SET @ExpenseClassId      = ISNULL(@ExpenseClassId,      -1);

        -- Class of the requested account (single account per call).
        SELECT @AccountClassId = GL.GLAccountTypeId
        FROM   dbo.GLAccount GL WITH (NOLOCK)
        WHERE  GL.GLAccountId     = @GlAccId
          AND  GL.MasterCompanyId = @masterCompanyId;

        SET @IsBalanceSheet    = CASE WHEN @AccountClassId IN (@AssetClassId, @LiabilityClassId, @OwnersEquityClassId) THEN 1 ELSE 0 END;
        SET @IsIncomeStatement = CASE WHEN @AccountClassId IN (@RevenueClassId, @ExpenseClassId)                       THEN 1 ELSE 0 END;

        ---------------------------------------------------------------------------
        -- 3) Materialise the class-aware period window (period IDs, like the TB
        --    report's #AllPeriodsForYTD for TargetPeriodId = @EndAccountingPeriodId):
        --
        --      Balance sheet  -> every period with ToDate <= End period ToDate
        --                        (cumulative from the very beginning).
        --      Income stmt    -> same, but restricted to the End period's FiscalYear
        --                        (current-fiscal-year-to-date).
        --      Anything else  -> full history (same fallback as the report).
        --
        --    @StartAccountingPeriodId is intentionally NOT used here: the report's
        --    window depends only on the target period, so the drill-down must too.
        ---------------------------------------------------------------------------
        INSERT INTO #AccPeriodTable (AccountingCalendarId, PeriodName, FromDate, ToDate)
        SELECT DISTINCT
            AC.AccountingCalendarId,
            REPLACE(AC.PeriodName, ' - ', ''),
            AC.FromDate,
            AC.ToDate
        FROM dbo.AccountingCalendar AC WITH (NOLOCK)
        WHERE AC.MasterCompanyId           = @masterCompanyId
          AND AC.IsDeleted                 = 0
          AND ISNULL(AC.IsAdjustPeriod, 0) = 0
          AND AC.LegalEntityId IN
              (
                  SELECT MSL.LegalEntityId
                  FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
                  WHERE  MSL.ID IN (SELECT Item FROM #L1)
              )
          AND CAST(AC.ToDate AS DATE) <= CAST(@PeriodEndDate AS DATE)
          -- Income statement accounts reset each fiscal year; balance sheet / other keep full history.
          AND (@IsIncomeStatement = 0 OR AC.FiscalYear = @EndFiscalYear);

        ---------------------------------------------------------------------------
        -- Final Result Set
        ---------------------------------------------------------------------------
        SELECT
            CBD.GlAccountId,
			CBD.ReferenceId,
			CBD.ReferenceModule,
			CM.IsStandAloneCM,
            (GL.AccountCode + ' - ' + GL.AccountName)  AS GlAccount,
			ISNULL(SUM(CBD.DebitAmount), 0)  - ISNULL(SUM(CBD.CreditAmount),  0)  AS Balance,
            BD.AccountingPeriod                         AS PeriodName,
            BD.JournalTypeNumber                        AS JournalNumber,
            ISNULL(CBD.ReferenceNumber, '')             AS ReferenceNumber,
            CBD.JournalTypeName
		INTO #TempResults
        FROM       dbo.CommonBatchDetails                              CBD WITH (NOLOCK)
        INNER JOIN dbo.BatchDetails                                    BD  WITH (NOLOCK) ON CBD.JournalBatchDetailId       = BD.JournalBatchDetailId
                                                                                        AND BD.StatusId                   = @PostedBatchStatusId
        INNER JOIN dbo.BatchHeader                                     B   WITH (NOLOCK) ON BD.JournalBatchHeaderId        = B.JournalBatchHeaderId
        INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD WITH (NOLOCK) ON MSD.ReferenceId                = CBD.CommonJournalBatchDetailId
                                                                                        AND MSD.ModuleId                  = @BatchMSModuleId
        INNER JOIN dbo.GLAccount                                       GL  WITH (NOLOCK) ON CBD.GlAccountId                = GL.GLAccountId
		LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH (NOLOCK) ON CBD.JournalBatchDetailId = CMBD.JournalBatchDetailId
		LEFT JOIN [dbo].[RefundCreditMemoMapping] RFCM WITH (NOLOCK) ON CMBD.ReferenceId  = RFCM.CustomerRefundId AND RFCM.CustomerRefundId =
		(
			SELECT TOP 1 RCMP.[CustomerRefundId] FROM [dbo].[RefundCreditMemoMapping] RCMP WITH (NOLOCK)
			WHERE RCMP.[CustomerRefundId] = RFCM.[CustomerRefundId]
		) AND CMBD.ModuleId = @CustomerRefundModuleId
		LEFT JOIN  dbo.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = RFCM.CreditMemoHeaderId
        WHERE BD.AccountingPeriodId IN (SELECT AccountingCalendarId FROM #AccPeriodTable)
          AND CBD.GlAccountId                    = @GlAccId
          AND CBD.MasterCompanyId                = @masterCompanyId
          AND CBD.ManagementStructureId          = @managementStructureId
          AND CBD.IsDeleted                      = 0
          AND BD.IsDeleted                       = 0
          AND B.IsDeleted                        = 0
          AND ISNULL(CBD.IsVersionIncrease, 0)   = 0
		  AND (ISNULL(@JournalNumber,'') ='' OR BD.JournalTypeNumber  LIKE '%' + @JournalNumber+'%')
		  AND (ISNULL(@JournalTypeName,'') ='' OR CBD.JournalTypeName LIKE '%' + @JournalTypeName+'%')
		  AND (ISNULL(@GLAccount,'') ='' OR (UPPER(GL.AccountCode) + '-' + UPPER(GL.AccountName)) LIKE '%' + @GLAccount+'%')
		  AND (ISNULL(@PeriodNames,'') ='' OR BD.AccountingPeriod LIKE '%' + @PeriodNames+'%')
		  AND (ISNULL(@ReferenceNumber,'') ='' OR CBD.ReferenceNumber LIKE '%' + @ReferenceNumber+'%')
          AND MSD.[Level1Id] IN (SELECT Item FROM #L1)
          AND (NOT EXISTS (SELECT 1 FROM #L2)  OR MSD.[Level2Id]  IN (SELECT Item FROM #L2))
          AND (NOT EXISTS (SELECT 1 FROM #L3)  OR MSD.[Level3Id]  IN (SELECT Item FROM #L3))
          AND (NOT EXISTS (SELECT 1 FROM #L4)  OR MSD.[Level4Id]  IN (SELECT Item FROM #L4))
          AND (NOT EXISTS (SELECT 1 FROM #L5)  OR MSD.[Level5Id]  IN (SELECT Item FROM #L5))
          AND (NOT EXISTS (SELECT 1 FROM #L6)  OR MSD.[Level6Id]  IN (SELECT Item FROM #L6))
          AND (NOT EXISTS (SELECT 1 FROM #L7)  OR MSD.[Level7Id]  IN (SELECT Item FROM #L7))
          AND (NOT EXISTS (SELECT 1 FROM #L8)  OR MSD.[Level8Id]  IN (SELECT Item FROM #L8))
          AND (NOT EXISTS (SELECT 1 FROM #L9)  OR MSD.[Level9Id]  IN (SELECT Item FROM #L9))
          AND (NOT EXISTS (SELECT 1 FROM #L10) OR MSD.[Level10Id] IN (SELECT Item FROM #L10))
        GROUP BY
            CBD.GlAccountId,
			CBD.ReferenceId,
			CBD.ReferenceModule,
			CM.IsStandAloneCM,
            BD.AccountingPeriod,
            BD.JournalTypeNumber,
            GL.AccountCode,
            GL.AccountName,
            CBD.ReferenceNumber,
            CBD.JournalTypeName
			HAVING
			(
				CAST(ISNULL(@Balance,'') AS VARCHAR) = ''
				OR CAST(ISNULL(SUM(CBD.DebitAmount), 0) - ISNULL(SUM(CBD.CreditAmount), 0) AS VARCHAR) LIKE '%' + CAST(ISNULL(@Balance,'') AS VARCHAR) + '%'
			)

		SET @TotalRecordsCount = (SELECT COUNT(JournalNumber) FROM #TempResults);

		SELECT *, @TotalRecordsCount as NumberOfItems
		FROM #TempResults
		ORDER BY JournalNumber DESC
		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY

    END
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100) = DB_NAME(),
            @AdhocComments       VARCHAR(150) = 'USP_GetTrailBalanceJournalBatchData',
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