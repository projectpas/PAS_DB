
/*************************************************************
 ** File:    [USP_GetTrailBalanceReportData]
 ** Author:  Hemant Saliya
 ** Description: Retrieves Trial Balance Report Data.
 **              Multi-period pivoted output: one Debit/Credit column
 **              pair per period + Total columns (mirrors Income Statement
 **              Trend layout).
 **              YTD = cumulative from the very first posted transaction
 **              (e.g. Jan-2020) through the end of each selected period.
 ** Date:    06/20/2023
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author          Change Description
 ** --   ----------   --------------  --------------------------------
    1    06/20/2023   Hemant Saliya   Created
    2    06/22/2023   Satish Gohil    Optimisation and short MS changes
    3    07/04/2023   Satish Gohil    Manual Journal Entry added in Report
    4    07/05/2023   Satish Gohil    Year calculation count issue fixed
    5    08/08/2023   Devendra Shekh  GLAccountId column added
    6    09/01/2023   Hemant Saliya   Added MS Filters
    7    10/23/2023   Hemant Saliya   Updated for All GL Account List
    8    01/25/2024   Hemant Saliya   Remove Manual Journal from Reports
    9    07/24/2024   Moin Bloch      Added IsDeleted flag
    10   07/25/2024   Moin Bloch      Added ReportLayoutId
    11   10/30/2024   Devendra Shekh  Added MasterCompanyId join for GLAccount in #TempResults insert
    12   05/23/2025   Hemant Saliya   Handle condition for statistical GL account
    13   05/24/2025   Hemant Saliya   Changed Logic to get trial Balance from beginning
    14   05/08/2026   -               Multi-period pivoted output (Income Statement trend style).
                                      YTD fixed: accumulates from absolute first period ever
                                      (not fiscal year start) through each selected period's
                                      end date. #AccPAll now filters purely on ToDate with no
                                      FromDate lower bound so cross-fiscal-year history is
                                      always included.
 **************************************************************
 -- Pivoted multi-period example (Mar-2026 to May-2026):
 exec dbo.USP_GetTrailBalanceReportData_MultiplePerod @masterCompanyId=21, @managementStructureId=41,
      @StartAccountingPeriodId=322, @EndAccountingPeriodId=325,
      @IsSupressZero=1, @IsShortMS=1, @strFilter=N'70!71'

 exec dbo.USP_GetTrailBalanceReportDataAll @masterCompanyId=21, @managementStructureId=41,
      @StartAccountingPeriodId=324, @EndAccountingPeriodId=325,
      @IsSupressZero=1, @IsShortMS=1, @strFilter=N'70!71'

 -- Single-period (backward-compatible):
 exec dbo.USP_GetTrailBalanceReportData @masterCompanyId=21, @managementStructureId=41,
      @AccountingPeriodId=325, @IsSupressZero=1, @IsShortMS=1, @strFilter=N'70!71'
*************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportData_MultiplePerod]
(
    @masterCompanyId            VARCHAR(50)  = NULL,
    @managementStructureId      VARCHAR(50)  = NULL,
    @StartAccountingPeriodId     BIGINT       = NULL,
    @EndAccountingPeriodId       BIGINT       = NULL,
    @IsSupressZero              BIT          = NULL,
    @IsShortMS                  BIT          = NULL,
    @strFilter                  VARCHAR(MAX) = NULL,
    @ReportLayoutId             BIGINT       = NULL
)
AS
BEGIN
    BEGIN TRY
    BEGIN

        ---------------------------------------------------------------------------
        -- Backward compatibility: map @AccountingPeriodId → range params
        ---------------------------------------------------------------------------
       
        IF @StartAccountingPeriodId IS NULL SET @StartAccountingPeriodId = @EndAccountingPeriodId;
        IF @EndAccountingPeriodId   IS NULL SET @EndAccountingPeriodId   = @StartAccountingPeriodId;

        ---------------------------------------------------------------------------
        -- Variable Declarations
        ---------------------------------------------------------------------------
        DECLARE @BatchMSModuleId            BIGINT  = 72;
        DECLARE @PostedBatchStatusId        BIGINT;
        DECLARE @StatisticalGLAccountTypeId BIGINT;
        DECLARE @PeriodReportLayOutId       BIGINT;

        ---------------------------------------------------------------------------
        -- Lookup: Period Report Layout ID
        ---------------------------------------------------------------------------
        SELECT @PeriodReportLayOutId = [ReportLayOutId]
        FROM   dbo.ReportLayOut WITH (NOLOCK)
        WHERE  UPPER([ReportLayOutName]) = 'TRIAL BALANCE(PERIOD)';

        ---------------------------------------------------------------------------
        -- MS Filter: parse @strFilter into level temp tables
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL DROP TABLE #TEMPMSFilter;
        CREATE TABLE #TEMPMSFilter (ID BIGINT IDENTITY(1,1), LevelIds VARCHAR(MAX));
        INSERT INTO #TEMPMSFilter (LevelIds) SELECT Item FROM DBO.SPLITSTRING(@strFilter, '!');

        DECLARE
            @level1  VARCHAR(MAX) = NULL, @level2  VARCHAR(MAX) = NULL,
            @level3  VARCHAR(MAX) = NULL, @level4  VARCHAR(MAX) = NULL,
            @level5  VARCHAR(MAX) = NULL, @level6  VARCHAR(MAX) = NULL,
            @level7  VARCHAR(MAX) = NULL, @level8  VARCHAR(MAX) = NULL,
            @level9  VARCHAR(MAX) = NULL, @level10 VARCHAR(MAX) = NULL;

        SELECT @level1  = LevelIds FROM #TEMPMSFilter WHERE ID = 1;
        SELECT @level2  = LevelIds FROM #TEMPMSFilter WHERE ID = 2;
        SELECT @level3  = LevelIds FROM #TEMPMSFilter WHERE ID = 3;
        SELECT @level4  = LevelIds FROM #TEMPMSFilter WHERE ID = 4;
        SELECT @level5  = LevelIds FROM #TEMPMSFilter WHERE ID = 5;
        SELECT @level6  = LevelIds FROM #TEMPMSFilter WHERE ID = 6;
        SELECT @level7  = LevelIds FROM #TEMPMSFilter WHERE ID = 7;
        SELECT @level8  = LevelIds FROM #TEMPMSFilter WHERE ID = 8;
        SELECT @level9  = LevelIds FROM #TEMPMSFilter WHERE ID = 9;
        SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10;

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

        CREATE TABLE #L1(Item VARCHAR(MAX));  CREATE TABLE #L2(Item VARCHAR(MAX));
        CREATE TABLE #L3(Item VARCHAR(MAX));  CREATE TABLE #L4(Item VARCHAR(MAX));
        CREATE TABLE #L5(Item VARCHAR(MAX));  CREATE TABLE #L6(Item VARCHAR(MAX));
        CREATE TABLE #L7(Item VARCHAR(MAX));  CREATE TABLE #L8(Item VARCHAR(MAX));
        CREATE TABLE #L9(Item VARCHAR(MAX));  CREATE TABLE #L10(Item VARCHAR(MAX));

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
        -- Batch Status & Statistical GL Account Type
        ---------------------------------------------------------------------------
        SELECT @PostedBatchStatusId = Id
        FROM   dbo.BatchStatus WITH (NOLOCK)
        WHERE  [Name] = 'Posted';

        SELECT @StatisticalGLAccountTypeId = ISNULL(GLAccountClassId, 0)
        FROM   dbo.GLAccountClass WITH (NOLOCK)
        WHERE  UPPER(GLAccountClassName) = 'STATISTICAL'
          AND  MasterCompanyId           = @masterCompanyId
          AND  ISNULL(IsDeleted, 0)      = 0
          AND  ISNULL(IsActive,  0)      = 1;

        ---------------------------------------------------------------------------
        -- Legal entities covered by the MS filter (used in every period loop)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#FilteredLegalEntities') IS NOT NULL DROP TABLE #FilteredLegalEntities;
        CREATE TABLE #FilteredLegalEntities (LegalEntityId BIGINT PRIMARY KEY);

        INSERT INTO #FilteredLegalEntities (LegalEntityId)
        SELECT DISTINCT MSL.LegalEntityId
        FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
        WHERE  MSL.ID IN (SELECT Item FROM #L1)
          AND  MSL.LegalEntityId IS NOT NULL;

        ---------------------------------------------------------------------------
        -- Resolve the selected period range
        -- PeriodEndDate = AC.ToDate  (the last calendar date of that period)
        -- This is the ONLY upper-bound used for YTD — no fiscal year restriction.
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#SelectedPeriods') IS NOT NULL DROP TABLE #SelectedPeriods;
        CREATE TABLE #SelectedPeriods
        (
            RowNum             INT IDENTITY(1,1),
            AccountingPeriodId BIGINT,
            PeriodLabel        VARCHAR(20),    -- e.g. "Mar 2026"
            FiscalYear         VARCHAR(20),
            PeriodEndDate      DATETIME,       -- AC.ToDate — upper bound for YTD periods
            SortOrder          INT
        );

        INSERT INTO #SelectedPeriods (AccountingPeriodId, PeriodLabel, FiscalYear, PeriodEndDate, SortOrder)
        SELECT
            AC.AccountingCalendarId,
            LEFT(DATENAME(MONTH, AC.ToDate), 3) + '_' + CAST(YEAR(AC.ToDate) AS VARCHAR(4)),
            AC.FiscalYear,
            AC.ToDate,          -- <<< pure date upper bound, no fiscal year logic
            AC.[Period]
        FROM dbo.AccountingCalendar AC WITH (NOLOCK)
        WHERE AC.MasterCompanyId             = @masterCompanyId
          AND AC.IsDeleted                   = 0
          AND ISNULL(AC.IsAdjustPeriod, 0)   = 0
          AND AC.AccountingCalendarId BETWEEN @StartAccountingPeriodId AND @EndAccountingPeriodId
          AND AC.LegalEntityId IN (SELECT LegalEntityId FROM #FilteredLegalEntities)
        ORDER BY AC.FiscalYear, AC.[Period];

        ---------------------------------------------------------------------------
        -- Pre-build the COMPLETE accounting period ID list for each selected
        -- period's YTD window.
        --
        -- KEY FIX: No lower-date filter at all — we include every calendar
        -- period from the dawn of time up to each period's ToDate.
        -- This means Jan-2020 transactions ARE included when running Mar-2026.
        --
        -- One row per (AccountingCalendarId, TargetPeriodId) — the join column
        -- TargetPeriodId lets the YTD query filter by period using a simple
        -- IN (SELECT AccountcalID FROM #AllPeriodsForYTD WHERE TargetPeriodId=@CurPeriodId)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#AllPeriodsForYTD') IS NOT NULL DROP TABLE #AllPeriodsForYTD;
        CREATE TABLE #AllPeriodsForYTD
        (
            TargetPeriodId  BIGINT,   -- the selected period this row belongs to
            AccountcalID    BIGINT    -- calendar period to include in that YTD window
        );

        -- For every selected period, collect ALL calendar periods whose ToDate
        -- falls on or before that selected period's PeriodEndDate.
        -- No FromDate restriction — cross-fiscal-year history included automatically.
        INSERT INTO #AllPeriodsForYTD (TargetPeriodId, AccountcalID)
        SELECT DISTINCT
            SP.AccountingPeriodId   AS TargetPeriodId,
            AC.AccountingCalendarId AS AccountcalID
        FROM #SelectedPeriods SP
        JOIN dbo.AccountingCalendar AC WITH (NOLOCK)
            ON  AC.MasterCompanyId             = @masterCompanyId
            AND AC.IsDeleted                   = 0
            AND ISNULL(AC.IsAdjustPeriod, 0)   = 0
            AND AC.LegalEntityId IN (SELECT LegalEntityId FROM #FilteredLegalEntities)
            -- ToDate of the calendar period must be <= the selected period's end date
            AND CAST(AC.ToDate AS DATE) <= CAST(SP.PeriodEndDate AS DATE);

        ---------------------------------------------------------------------------
        -- Staging table: one row per (GlAccount × EntityStructure × Period)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#Staging') IS NOT NULL DROP TABLE #Staging;
        CREATE TABLE #Staging
        (
            GlAccountId         BIGINT,
            AccountNum          VARCHAR(200),
            AccountName         VARCHAR(200),
            EntityStructureId   BIGINT,
            MasterCompanyId     INT,
            Level1Name          VARCHAR(100), Level2Name  VARCHAR(100),
            Level3Name          VARCHAR(100), Level4Name  VARCHAR(100),
            Level5Name          VARCHAR(100), Level6Name  VARCHAR(100),
            Level7Name          VARCHAR(100), Level8Name  VARCHAR(100),
            Level9Name          VARCHAR(100), Level10Name VARCHAR(100),
            SequenceNumber      INT,
            PeriodLabel         VARCHAR(20),
            AccountingPeriodId  BIGINT,
            PeriodSortOrder     INT,
            -- Monthly = activity within this calendar period only
            MonthlyDebit        DECIMAL(18,2),
            MonthlyCredit       DECIMAL(18,2),
            -- YTD = cumulative from beginning of all time → this period's end
            YTDDebit            DECIMAL(18,2),
            YTDCredit           DECIMAL(18,2)
        );

        ---------------------------------------------------------------------------
        -- Entity Structure Setup (once, reused per loop iteration)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#tmpESS') IS NOT NULL DROP TABLE #tmpESS;
        CREATE TABLE #tmpESS
        (
            ID                BIGINT IDENTITY(1,1),
            EntityStructureId BIGINT,
            LegalEntityId     BIGINT,
            MasterCompanyId   INT,
            Level1Name        VARCHAR(100), Level2Name  VARCHAR(100),
            Level3Name        VARCHAR(100), Level4Name  VARCHAR(100),
            Level5Name        VARCHAR(100), Level6Name  VARCHAR(100),
            Level7Name        VARCHAR(100), Level8Name  VARCHAR(100),
            Level9Name        VARCHAR(100), Level10Name VARCHAR(100)
        );

        INSERT INTO #tmpESS
            (EntityStructureId, MasterCompanyId, LegalEntityId,
             Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
             Level6Name, Level7Name, Level8Name, Level9Name, Level10Name)
        SELECT
            ESS.EntityStructureId, ESS.MasterCompanyId, MSL1.LegalEntityId,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL1.Code AS VARCHAR(250))+' - '+MSL1.[Description] ELSE CAST(MSL1.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL2.Code AS VARCHAR(250))+' - '+MSL2.[Description] ELSE CAST(MSL2.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL3.Code AS VARCHAR(250))+' - '+MSL3.[Description] ELSE CAST(MSL3.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL4.Code AS VARCHAR(250))+' - '+MSL4.[Description] ELSE CAST(MSL4.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL5.Code AS VARCHAR(250))+' - '+MSL5.[Description] ELSE CAST(MSL5.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL6.Code AS VARCHAR(250))+' - '+MSL6.[Description] ELSE CAST(MSL6.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL7.Code AS VARCHAR(250))+' - '+MSL7.[Description] ELSE CAST(MSL7.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL8.Code AS VARCHAR(250))+' - '+MSL8.[Description] ELSE CAST(MSL8.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL9.Code AS VARCHAR(250))+' - '+MSL9.[Description] ELSE CAST(MSL9.Code AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS=0 THEN CAST(MSL10.Code AS VARCHAR(250))+' - '+MSL10.[Description] ELSE CAST(MSL10.Code AS VARCHAR(250)) END
        FROM      dbo.EntityStructureSetup    ESS
        LEFT JOIN dbo.ManagementStructureLevel MSL1  WITH (NOLOCK) ON ESS.Level1Id  = MSL1.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL2  WITH (NOLOCK) ON ESS.Level2Id  = MSL2.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL3  WITH (NOLOCK) ON ESS.Level3Id  = MSL3.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL4  WITH (NOLOCK) ON ESS.Level4Id  = MSL4.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL5  WITH (NOLOCK) ON ESS.Level5Id  = MSL5.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL6  WITH (NOLOCK) ON ESS.Level6Id  = MSL6.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL7  WITH (NOLOCK) ON ESS.Level7Id  = MSL7.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL8  WITH (NOLOCK) ON ESS.Level8Id  = MSL8.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL9  WITH (NOLOCK) ON ESS.Level9Id  = MSL9.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
        WHERE ESS.MasterCompanyId = @masterCompanyId
          AND ESS.[Level1Id] IN (SELECT Item FROM #L1)
          AND (NOT EXISTS (SELECT 1 FROM #L2)  OR ESS.[Level2Id]  IN (SELECT Item FROM #L2))
          AND (NOT EXISTS (SELECT 1 FROM #L3)  OR ESS.[Level3Id]  IN (SELECT Item FROM #L3))
          AND (NOT EXISTS (SELECT 1 FROM #L4)  OR ESS.[Level4Id]  IN (SELECT Item FROM #L4))
          AND (NOT EXISTS (SELECT 1 FROM #L5)  OR ESS.[Level5Id]  IN (SELECT Item FROM #L5))
          AND (NOT EXISTS (SELECT 1 FROM #L6)  OR ESS.[Level6Id]  IN (SELECT Item FROM #L6))
          AND (NOT EXISTS (SELECT 1 FROM #L7)  OR ESS.[Level7Id]  IN (SELECT Item FROM #L7))
          AND (NOT EXISTS (SELECT 1 FROM #L8)  OR ESS.[Level8Id]  IN (SELECT Item FROM #L8))
          AND (NOT EXISTS (SELECT 1 FROM #L9)  OR ESS.[Level9Id]  IN (SELECT Item FROM #L9))
          AND (NOT EXISTS (SELECT 1 FROM #L10) OR ESS.[Level10Id] IN (SELECT Item FROM #L10))
        GROUP BY
            MSL1.LegalEntityId, ESS.EntityStructureId, ESS.MasterCompanyId,
            MSL1.Code, MSL1.[Description], MSL2.Code,  MSL2.[Description],
            MSL3.Code, MSL3.[Description], MSL4.Code,  MSL4.[Description],
            MSL5.Code, MSL5.[Description], MSL6.Code,  MSL6.[Description],
            MSL7.Code, MSL7.[Description], MSL8.Code,  MSL8.[Description],
            MSL9.Code, MSL9.[Description], MSL10.Code, MSL10.[Description];

        ---------------------------------------------------------------------------
        -- LOOP: one iteration per selected period — populate #Staging
        ---------------------------------------------------------------------------
        DECLARE
            @LoopRow          INT = 1,
            @TotalPeriods     INT,
            @CurPeriodId      BIGINT,
            @CurPeriodLabel   VARCHAR(20),
            @CurFiscalYear    VARCHAR(20),
            @CurPeriodEndDate DATETIME,
            @CurSortOrder     INT;

        SELECT @TotalPeriods = COUNT(1) FROM #SelectedPeriods;

        WHILE @LoopRow <= @TotalPeriods
        BEGIN
            SELECT
                @CurPeriodId      = AccountingPeriodId,
                @CurPeriodLabel   = PeriodLabel,
                @CurFiscalYear    = FiscalYear,
                @CurPeriodEndDate = PeriodEndDate,
                @CurSortOrder     = SortOrder
            FROM #SelectedPeriods
            WHERE RowNum = @LoopRow;

            -- Drop per-iteration temps
            IF OBJECT_ID(N'tempdb..#YTDRaw')   IS NOT NULL DROP TABLE #YTDRaw;
            IF OBJECT_ID(N'tempdb..#MonthRaw') IS NOT NULL DROP TABLE #MonthRaw;

            -----------------------------------------------------------------------
            -- YTD aggregation
            -- Uses #AllPeriodsForYTD filtered to this period's TargetPeriodId.
            -- This includes ALL calendar periods from Jan-2020 (or whenever the
            -- first period exists) through @CurPeriodEndDate — no fiscal boundary.
            -----------------------------------------------------------------------
            SELECT
                CB.GlAccountId,
                MSD.EntityMSID                  AS EntityStructureId,
                CB.MasterCompanyId,
                SUM(ISNULL(CB.CreditAmount, 0)) AS TotalCredit,
                SUM(ISNULL(CB.DebitAmount,  0)) AS TotalDebit,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL1.Code AS VARCHAR(250))+' - '+MSL1.[Description] ELSE CAST(MSL1.Code AS VARCHAR(250)) END AS Level1Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL2.Code AS VARCHAR(250))+' - '+MSL2.[Description] ELSE CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL3.Code AS VARCHAR(250))+' - '+MSL3.[Description] ELSE CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL4.Code AS VARCHAR(250))+' - '+MSL4.[Description] ELSE CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL5.Code AS VARCHAR(250))+' - '+MSL5.[Description] ELSE CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL6.Code AS VARCHAR(250))+' - '+MSL6.[Description] ELSE CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL7.Code AS VARCHAR(250))+' - '+MSL7.[Description] ELSE CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL8.Code AS VARCHAR(250))+' - '+MSL8.[Description] ELSE CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL9.Code AS VARCHAR(250))+' - '+MSL9.[Description] ELSE CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
                CASE WHEN @IsShortMS=0 THEN CAST(MSL10.Code AS VARCHAR(250))+' - '+MSL10.[Description] ELSE CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
                GC.SequenceNumber
            INTO #YTDRaw
            FROM       dbo.CommonBatchDetails                        CB   WITH (NOLOCK)
            INNER JOIN dbo.BatchDetails                              BD   WITH (NOLOCK)
                ON  CB.JournalBatchDetailId = BD.JournalBatchDetailId
                AND BD.StatusId             = @PostedBatchStatusId
            INNER JOIN dbo.BatchHeader                               B    WITH (NOLOCK)
                ON  BD.JournalBatchHeaderId = B.JournalBatchHeaderId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD  WITH (NOLOCK)
                ON  MSD.ReferenceId = CB.CommonJournalBatchDetailId
                AND MSD.ModuleId    = @BatchMSModuleId
            INNER JOIN dbo.GLAccount                                 GL   WITH (NOLOCK)
                ON  CB.GlAccountId      = GL.GLAccountId
                AND CB.MasterCompanyId  = GL.MasterCompanyId
                AND (   @StatisticalGLAccountTypeId IS NULL
                     OR @StatisticalGLAccountTypeId = 0
                     OR GL.GLAccountTypeId <> @StatisticalGLAccountTypeId)
            LEFT  JOIN dbo.GLAccountClass                            GC   WITH (NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
            LEFT  JOIN dbo.ManagementStructureLevel MSL1  WITH (NOLOCK) ON MSD.Level1Id  = MSL1.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL2  WITH (NOLOCK) ON MSD.Level2Id  = MSL2.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL3  WITH (NOLOCK) ON MSD.Level3Id  = MSL3.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL4  WITH (NOLOCK) ON MSD.Level4Id  = MSL4.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL5  WITH (NOLOCK) ON MSD.Level5Id  = MSL5.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL6  WITH (NOLOCK) ON MSD.Level6Id  = MSL6.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL7  WITH (NOLOCK) ON MSD.Level7Id  = MSL7.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL8  WITH (NOLOCK) ON MSD.Level8Id  = MSL8.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL9  WITH (NOLOCK) ON MSD.Level9Id  = MSL9.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
            WHERE ISNULL(CB.IsDeleted,         0) = 0
              AND ISNULL(BD.IsDeleted,         0) = 0
              AND ISNULL(B.IsDeleted,          0) = 0
              AND ISNULL(CB.IsVersionIncrease, 0) = 0
              AND CB.MasterCompanyId             = @masterCompanyId
              -- <<< KEY FIX: use pre-built YTD period list — includes all history
              AND BD.AccountingPeriodId IN
                  (
                      SELECT AccountcalID
                      FROM   #AllPeriodsForYTD
                      WHERE  TargetPeriodId = @CurPeriodId
                  )
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
                CB.GlAccountId, MSD.EntityMSID, CB.MasterCompanyId,
                MSL1.Code, MSL1.[Description], MSL2.Code,  MSL2.[Description],
                MSL3.Code, MSL3.[Description], MSL4.Code,  MSL4.[Description],
                MSL5.Code, MSL5.[Description], MSL6.Code,  MSL6.[Description],
                MSL7.Code, MSL7.[Description], MSL8.Code,  MSL8.[Description],
                MSL9.Code, MSL9.[Description], MSL10.Code, MSL10.[Description],
                GC.SequenceNumber;

            -----------------------------------------------------------------------
            -- Monthly aggregation — current period only
            -- Filters strictly to @CurPeriodId so "this month" column is exact.
            -----------------------------------------------------------------------
            SELECT
                CB.GlAccountId,
                MSD.EntityMSID                  AS EntityStructureId,
                SUM(ISNULL(CB.CreditAmount, 0)) AS MonthCredit,
                SUM(ISNULL(CB.DebitAmount,  0)) AS MonthDebit
            INTO #MonthRaw
            FROM       dbo.CommonBatchDetails                        CB   WITH (NOLOCK)
            INNER JOIN dbo.BatchDetails                              BD   WITH (NOLOCK)
                ON  CB.JournalBatchDetailId = BD.JournalBatchDetailId
                AND BD.StatusId             = @PostedBatchStatusId
            INNER JOIN dbo.BatchHeader                               B    WITH (NOLOCK)
                ON  BD.JournalBatchHeaderId = B.JournalBatchHeaderId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD  WITH (NOLOCK)
                ON  MSD.ReferenceId = CB.CommonJournalBatchDetailId
                AND MSD.ModuleId    = @BatchMSModuleId
            INNER JOIN dbo.GLAccount                                 GL   WITH (NOLOCK)
                ON  CB.GlAccountId      = GL.GLAccountId
                AND CB.MasterCompanyId  = GL.MasterCompanyId
                AND (   @StatisticalGLAccountTypeId IS NULL
                     OR @StatisticalGLAccountTypeId = 0
                     OR GL.GLAccountTypeId <> @StatisticalGLAccountTypeId)
            WHERE ISNULL(CB.IsDeleted,         0) = 0
              AND ISNULL(BD.IsDeleted,         0) = 0
              AND ISNULL(B.IsDeleted,          0) = 0
              AND ISNULL(CB.IsVersionIncrease, 0) = 0
              AND CB.MasterCompanyId             = @masterCompanyId
              --AND BD.AccountingPeriodId          = @CurPeriodId   -- this month only
			  AND BD.AccountingPeriodId IN
                  (
                      SELECT AccountcalID
                      FROM   #AllPeriodsForYTD
                      WHERE  TargetPeriodId = @CurPeriodId
                  )

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
            GROUP BY CB.GlAccountId, MSD.EntityMSID;

            -----------------------------------------------------------------------
            -- Merge YTD + Monthly into #Staging for this period
            -----------------------------------------------------------------------
            INSERT INTO #Staging
                (GlAccountId, AccountNum, AccountName, EntityStructureId, MasterCompanyId,
                 Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                 Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                 SequenceNumber, PeriodLabel, AccountingPeriodId, PeriodSortOrder,
                 MonthlyDebit, MonthlyCredit, YTDDebit, YTDCredit)
            SELECT
                Y.GlAccountId,
                GL.AccountCode,
                GL.AccountName,
                Y.EntityStructureId,
                Y.MasterCompanyId,
                Y.Level1Name, Y.Level2Name, Y.Level3Name, Y.Level4Name, Y.Level5Name,
                Y.Level6Name, Y.Level7Name, Y.Level8Name, Y.Level9Name, Y.Level10Name,
                Y.SequenceNumber,
                @CurPeriodLabel,
                @CurPeriodId,
                @CurSortOrder,
                -- Monthly Debit: net debit activity this period
                CASE WHEN ISNULL(M.MonthDebit,0) - ISNULL(M.MonthCredit,0) > 0
                     THEN ISNULL(M.MonthDebit,0) - ISNULL(M.MonthCredit,0) ELSE 0 END,
                -- Monthly Credit: net credit activity this period
                CASE WHEN ISNULL(M.MonthCredit,0) - ISNULL(M.MonthDebit,0) > 0
                     THEN ISNULL(M.MonthCredit,0) - ISNULL(M.MonthDebit,0) ELSE 0 END,
                -- YTD Debit: cumulative from beginning → this period
                CASE WHEN Y.TotalDebit - Y.TotalCredit > 0
                     THEN Y.TotalDebit - Y.TotalCredit ELSE 0 END,
                -- YTD Credit: cumulative from beginning → this period
                CASE WHEN Y.TotalCredit - Y.TotalDebit > 0
                     THEN Y.TotalCredit - Y.TotalDebit ELSE 0 END
            FROM #YTDRaw Y
            INNER JOIN dbo.GLAccount GL WITH (NOLOCK)
                ON Y.GlAccountId = GL.GLAccountId AND Y.MasterCompanyId = GL.MasterCompanyId
            LEFT JOIN #MonthRaw M
                ON Y.GlAccountId = M.GlAccountId AND Y.EntityStructureId = M.EntityStructureId;

            -- No-suppress: ensure every active GL account appears even with all zeros
            IF (@IsSupressZero = 0)
            BEGIN
                INSERT INTO #Staging
                    (GlAccountId, AccountNum, AccountName, EntityStructureId, MasterCompanyId,
                     Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                     Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                     SequenceNumber, PeriodLabel, AccountingPeriodId, PeriodSortOrder,
                     MonthlyDebit, MonthlyCredit, YTDDebit, YTDCredit)
                SELECT
                    GL.GLAccountId, GL.AccountCode, GL.AccountName,
                    NULL, GL.MasterCompanyId,
                    ESS.Level1Name, ESS.Level2Name, ESS.Level3Name, ESS.Level4Name, ESS.Level5Name,
                    ESS.Level6Name, ESS.Level7Name, ESS.Level8Name, ESS.Level9Name, ESS.Level10Name,
                    NULL, @CurPeriodLabel, @CurPeriodId, @CurSortOrder,
                    0, 0, 0, 0
                FROM dbo.GLAccount GL
                CROSS JOIN (SELECT TOP 1 * FROM #tmpESS ORDER BY ID) ESS
                WHERE GL.MasterCompanyId = @masterCompanyId
                  AND GL.IsActive        = 1
                  AND GL.IsDeleted       = 0
                  AND NOT EXISTS
                      (
                          SELECT 1 FROM #Staging S2
                          WHERE  S2.GlAccountId        = GL.GLAccountId
                            AND  S2.AccountingPeriodId = @CurPeriodId
                      );
            END

            SET @LoopRow = @LoopRow + 1;
        END -- WHILE

        ---------------------------------------------------------------------------
        -- Apply @IsSupressZero: remove accounts that are all-zero across every period
        ---------------------------------------------------------------------------
        IF (@IsSupressZero = 1)
        BEGIN
            IF (@PeriodReportLayOutId = @ReportLayoutId)
            BEGIN
                -- Period layout: keep accounts with any YTD amount in any period
                DELETE FROM #Staging
                WHERE GlAccountId NOT IN
                      (SELECT GlAccountId FROM #Staging WHERE YTDDebit > 0 OR YTDCredit > 0);
            END
            ELSE
            BEGIN
                -- Standard layout: keep accounts with any monthly OR YTD amount
                DELETE FROM #Staging
                WHERE GlAccountId NOT IN
                      (
                          SELECT GlAccountId FROM #Staging
                          WHERE  MonthlyDebit > 0 OR MonthlyCredit > 0
                              OR YTDDebit     > 0 OR YTDCredit     > 0
                      );
            END
        END

        ---------------------------------------------------------------------------
        -- Dynamic PIVOT
        --
        -- Output columns:
        --   AccountNum, AccountName, MS levels,
        --   [Mar 2026 Debit], [Mar 2026 Credit],   ← monthly activity each period
        --   [Apr 2026 Debit], [Apr 2026 Credit],
        --   [May 2026 Debit], [May 2026 Credit],
        --   [May 2026 YTD Debit], [May 2026 YTD Credit],  ← running balance to last period
        --   [Total Debit], [Total Credit], [Total Balance]
        --
        -- "Total" = sum of monthly Debits/Credits across all selected periods.
        -- "YTD" columns are the last period's cumulative balance (most useful figure).
        ---------------------------------------------------------------------------
        DECLARE
            @ColList            NVARCHAR(MAX) = N'',
            @SelectPeriodCols   NVARCHAR(MAX) = N'',
            --@TotalDebitExpr     NVARCHAR(MAX) = N'',
            --@TotalCreditExpr    NVARCHAR(MAX) = N'',
			@TotalBalanceExpr   NVARCHAR(MAX) = N'',   -- replaces separate Debit/Credit exprs
            @LastPeriodLabel    NVARCHAR(20)  = N'',
            @SQL                NVARCHAR(MAX) = N'';

        -- Capture label of the last selected period (for YTD columns)
        SELECT TOP 1 @LastPeriodLabel = PeriodLabel
        FROM #SelectedPeriods
        ORDER BY SortOrder DESC;

        -- Build column expressions in period order
        SELECT
            -- PIVOT needs every distinct metric key listed
            @ColList          = @ColList
                + N',[' + PeriodLabel + '_MD]'   -- Monthly Debit
                + N',[' + PeriodLabel + '_MC]'   -- Monthly Credit
                + N',[' + PeriodLabel + '_YD]'   -- YTD Debit
                + N',[' + PeriodLabel + '_YC]',  -- YTD Credit

			-- Single balance column per period: Debit - Credit
			@SelectPeriodCols = @SelectPeriodCols
				+ N'  (ISNULL(pvt.[' + PeriodLabel + '_MD], 0) - ISNULL(pvt.[' + PeriodLabel + '_MC], 0))'
				+ N' AS [' + PeriodLabel + '],' + CHAR(13),

			-- Accumulate total balance = sum of (monthly debit - monthly credit) across all periods
			@TotalBalanceExpr = @TotalBalanceExpr
				+ N'(ISNULL(pvt.[' + PeriodLabel + '_MD],0) - ISNULL(pvt.[' + PeriodLabel + '_MC],0))+'

		FROM #SelectedPeriods
		ORDER BY SortOrder;

		-- Remove trailing '+'
		SET @TotalBalanceExpr = LEFT(@TotalBalanceExpr, LEN(@TotalBalanceExpr) - 1);
		-- Remove leading ','
		SET @ColList = STUFF(@ColList, 1, 1, '');

		SET @SQL = N'
			;WITH Unpivoted AS
			(
				SELECT GlAccountId, AccountNum, AccountName, EntityStructureId,
					   Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
					   Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
					   SequenceNumber,
					   PeriodLabel + N''_MD'' AS Metric, MonthlyDebit  AS Amount
				FROM #Staging
				UNION ALL
				SELECT GlAccountId, AccountNum, AccountName, EntityStructureId,
					   Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
					   Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
					   SequenceNumber,
					   PeriodLabel + N''_MC'' AS Metric, MonthlyCredit AS Amount
				FROM #Staging
				UNION ALL
				SELECT GlAccountId, AccountNum, AccountName, EntityStructureId,
					   Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
					   Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
					   SequenceNumber,
					   PeriodLabel + N''_YD'' AS Metric, YTDDebit      AS Amount
				FROM #Staging
				UNION ALL
				SELECT GlAccountId, AccountNum, AccountName, EntityStructureId,
					   Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
					   Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
					   SequenceNumber,
					   PeriodLabel + N''_YC'' AS Metric, YTDCredit     AS Amount
				FROM #Staging
			),
			Pivoted AS
			(
				SELECT *
				FROM Unpivoted
				PIVOT (SUM(Amount) FOR Metric IN (' + @ColList + N')) AS pvt
			)
			SELECT
			  pvt.GlAccountId,
			  pvt.EntityStructureId,
			  pvt.AccountNum  AS accountNum,
			  pvt.AccountName AS accountName,
			  pvt.Level1Name AS level1Name,  pvt.Level2Name AS level2Name,  pvt.Level3Name as level3Name,  pvt.Level4Name as level4Name,  pvt.Level5Name as level5Name,
			  pvt.Level6Name as level6Name,  pvt.Level7Name as level7Name,  pvt.Level8Name as level8Name,  pvt.Level9Name as level9Name,  pvt.Level10Name as level10Name,
			' + @SelectPeriodCols
			  + N'  (ISNULL(pvt.[' + @LastPeriodLabel + N'_YD], 0) - ISNULL(pvt.[' + @LastPeriodLabel + N'_YC], 0)) AS [ytdBalance],' + CHAR(13)
			  + N'  (' + @TotalBalanceExpr + N') AS [totalBalance]'  + CHAR(13)
			  + N'FROM Pivoted pvt
			ORDER BY TRY_CAST(pvt.AccountNum AS BIGINT);
			';

		EXEC sp_executesql @SQL;

       

    END
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100) = DB_NAME(),
            @AdhocComments       VARCHAR(150) = 'USP_GetTrailBalanceReportData',
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