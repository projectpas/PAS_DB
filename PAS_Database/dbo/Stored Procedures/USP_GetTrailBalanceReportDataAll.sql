
/*************************************************************
 ** File:    [USP_GetTrailBalanceReportData]
 ** Author:  Hemant Saliya
 ** Description: Retrieves Trial Balance Report Data (Partner number and stockline usage)
 ** Date:    06/20/2023
 **
 ** PARAMETERS: See parameter list below
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
    14   05/08/2026   -               Multi-period support: @FromAccountingPeriodId / @ToAccountingPeriodId;
                                      single result set with PeriodName column; @AccountingPeriodId retained
                                      for backward compatibility (maps to ToAccountingPeriodId when used alone)
 **************************************************************
 -- Multi-period example:
 exec dbo.USP_GetTrailBalanceReportDataAll @masterCompanyId=21, @managementStructureId=41,
      @FromAccountingPeriodId=322, @ToAccountingPeriodId=325,
      @IsSupressZero=1, @IsShortMS=1, @strFilter=N'70!71'

 -- Single-period (backward-compatible):
 exec dbo.USP_GetTrailBalanceReportData @masterCompanyId=21, @managementStructureId=41,
      @AccountingPeriodId=325, @IsSupressZero=1, @IsShortMS=1, @strFilter=N'70!71'
*************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportDataAll]
(
    @masterCompanyId            VARCHAR(50)  = NULL,
    @managementStructureId      VARCHAR(50)  = NULL,
    -- Legacy single-period param kept for backward compatibility
    @AccountingPeriodId         BIGINT       = NULL,
    -- New multi-period params
    @FromAccountingPeriodId     BIGINT       = NULL,
    @ToAccountingPeriodId       BIGINT       = NULL,
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
        -- Backward compatibility: map legacy @AccountingPeriodId to range params
        ---------------------------------------------------------------------------
        IF @FromAccountingPeriodId IS NULL AND @ToAccountingPeriodId IS NULL
        BEGIN
            SET @FromAccountingPeriodId = @AccountingPeriodId;
            SET @ToAccountingPeriodId   = @AccountingPeriodId;
        END
        ELSE IF @FromAccountingPeriodId IS NULL
            SET @FromAccountingPeriodId = @ToAccountingPeriodId;
        ELSE IF @ToAccountingPeriodId IS NULL
            SET @ToAccountingPeriodId   = @FromAccountingPeriodId;

        ---------------------------------------------------------------------------
        -- Variable Declarations
        ---------------------------------------------------------------------------
        DECLARE @BatchMSModuleId            BIGINT;
        DECLARE @PostedBatchStatusId        BIGINT;
        DECLARE @StatisticalGLAccountTypeId BIGINT;
        DECLARE @PeriodReportLayOutId       BIGINT;
        DECLARE @TotalCreditAmount          DECIMAL(18, 2);
        DECLARE @TotalDebitAmount           DECIMAL(18, 2);
        DECLARE @GlobalFromDate             DATETIME = NULL;  -- earliest FromDate across all selected periods

        ---------------------------------------------------------------------------
        -- Lookup: Period Report Layout ID
        ---------------------------------------------------------------------------
        SELECT @PeriodReportLayOutId = [ReportLayOutId]
        FROM   dbo.ReportLayOut WITH (NOLOCK)
        WHERE  UPPER([ReportLayOutName]) = 'TRIAL BALANCE(PERIOD)';

        ---------------------------------------------------------------------------
        -- Temp Table: MS Filter levels
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL DROP TABLE #TEMPMSFilter;

        CREATE TABLE #TEMPMSFilter
        (
            ID       BIGINT IDENTITY(1, 1),
            LevelIds VARCHAR(MAX)
        );

        INSERT INTO #TEMPMSFilter (LevelIds)
        SELECT Item FROM DBO.SPLITSTRING(@strFilter, '!');

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

        ---------------------------------------------------------------------------
        -- Pre-parse filter values into temp tables
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
        -- Build the list of selected periods from the range
        -- Each row = one period to iterate over
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#SelectedPeriods') IS NOT NULL DROP TABLE #SelectedPeriods;

        CREATE TABLE #SelectedPeriods
        (
            RowNum              INT IDENTITY(1,1),
            AccountingPeriodId  BIGINT,
            PeriodName          VARCHAR(100),
            FiscalYear          VARCHAR(20),
            PeriodType          VARCHAR(100),
            PeriodEndDate       DATETIME,   -- AC.ToDate  (used for #AccPeriodTable_All upper bound)
            ToDate              DATETIME    -- AC.EndDate (original @ToDate semantics)
        );

        INSERT INTO #SelectedPeriods (AccountingPeriodId, PeriodName, FiscalYear, PeriodType, PeriodEndDate, ToDate)
        SELECT
            AC.AccountingCalendarId,
            UPPER(AC.PeriodName),
            AC.FiscalYear,
            AC.PeriodType,
            AC.ToDate,      -- PeriodEndDate
            AC.EndDate      -- ToDate
        FROM dbo.AccountingCalendar AC WITH (NOLOCK)
        WHERE AC.MasterCompanyId = @masterCompanyId
          AND AC.IsDeleted       = 0
          AND ISNULL(AC.IsAdjustPeriod, 0) = 0
          AND AC.AccountingCalendarId BETWEEN @FromAccountingPeriodId AND @ToAccountingPeriodId
          AND AC.LegalEntityId IN
              (
                  SELECT MSL.LegalEntityId
                  FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
                  WHERE  MSL.ID IN (SELECT Item FROM #L1)
              )
        ORDER BY AC.FiscalYear, AC.[Period];

        ---------------------------------------------------------------------------
        -- Batch Status & Statistical GL Account Type (looked up once)
        ---------------------------------------------------------------------------
        SET @BatchMSModuleId = 72;

        SELECT @PostedBatchStatusId = Id
        FROM   dbo.BatchStatus WITH (NOLOCK)
        WHERE  [Name] = 'Posted';

        SELECT @StatisticalGLAccountTypeId = ISNULL(GLAccountClassId, 0)
        FROM   dbo.GLAccountClass WITH (NOLOCK)
        WHERE  UPPER(GLAccountClassName) = 'STATISTICAL'
          AND  MasterCompanyId           = @masterCompanyId
          AND  ISNULL(IsDeleted, 0)      = 0
          AND  ISNULL(IsActive,  0)      = 1;

        -- Global earliest FromDate (across all selected periods & their legal entities)
        SELECT @GlobalFromDate = MIN(FromDate)
        FROM dbo.AccountingCalendar WITH (NOLOCK)
        WHERE MasterCompanyId = @masterCompanyId
          AND IsDeleted       = 0
          AND LegalEntityId IN
              (
                  SELECT MSL.LegalEntityId
                  FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
                  WHERE  MSL.ID IN (SELECT Item FROM #L1)
              );

        ---------------------------------------------------------------------------
        -- Final output table — accumulates rows for every period
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#FinalOutput') IS NOT NULL DROP TABLE #FinalOutput;

        CREATE TABLE #FinalOutput
        (
            PeriodName          VARCHAR(100),
            AccountingPeriodId  BIGINT,
            GlAccountId         BIGINT,
            AccountNum          VARCHAR(200),
            AccountName         VARCHAR(200),
            EntityStructureId   BIGINT,
            Level1Name          VARCHAR(100),
            Level2Name          VARCHAR(100),
            Level3Name          VARCHAR(100),
            Level4Name          VARCHAR(100),
            Level5Name          VARCHAR(100),
            Level6Name          VARCHAR(100),
            Level7Name          VARCHAR(100),
            Level8Name          VARCHAR(100),
            Level9Name          VARCHAR(100),
            Level10Name         VARCHAR(100),
            MonthlyCreditAmount DECIMAL(18, 2),
            MonthlyDebitAmount  DECIMAL(18, 2),
            YTDCreditAmount     DECIMAL(18, 2),
            YTDDebitAmount      DECIMAL(18, 2),
            Balance             DECIMAL(18, 2),
            TotalCreditAmount   DECIMAL(18, 2),
            TotalDebitAmount    DECIMAL(18, 2),
            SequenceNumber      INT
        );

        ---------------------------------------------------------------------------
        -- Entity Structure Setup (computed once, reused for all periods)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#tmpEntityStructureSetup') IS NOT NULL DROP TABLE #tmpEntityStructureSetup;

        CREATE TABLE #tmpEntityStructureSetup
        (
            ID                BIGINT IDENTITY(1, 1),
            EntityStructureId BIGINT,
            LegalEntityId     BIGINT,
            MasterCompanyId   INT,
            Level1Name        VARCHAR(100),
            Level2Name        VARCHAR(100),
            Level3Name        VARCHAR(100),
            Level4Name        VARCHAR(100),
            Level5Name        VARCHAR(100),
            Level6Name        VARCHAR(100),
            Level7Name        VARCHAR(100),
            Level8Name        VARCHAR(100),
            Level9Name        VARCHAR(100),
            Level10Name       VARCHAR(100)
        );

        INSERT INTO #tmpEntityStructureSetup
            (EntityStructureId, MasterCompanyId, LegalEntityId,
             Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
             Level6Name, Level7Name, Level8Name, Level9Name, Level10Name)
        SELECT
            ESS.EntityStructureId,
            ESS.MasterCompanyId,
            MSL1.LegalEntityId,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code  AS VARCHAR(250)) + ' - ' + MSL1.[Description]  ELSE CAST(MSL1.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code  AS VARCHAR(250)) + ' - ' + MSL2.[Description]  ELSE CAST(MSL2.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code  AS VARCHAR(250)) + ' - ' + MSL3.[Description]  ELSE CAST(MSL3.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code  AS VARCHAR(250)) + ' - ' + MSL4.[Description]  ELSE CAST(MSL4.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code  AS VARCHAR(250)) + ' - ' + MSL5.[Description]  ELSE CAST(MSL5.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code  AS VARCHAR(250)) + ' - ' + MSL6.[Description]  ELSE CAST(MSL6.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code  AS VARCHAR(250)) + ' - ' + MSL7.[Description]  ELSE CAST(MSL7.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code  AS VARCHAR(250)) + ' - ' + MSL8.[Description]  ELSE CAST(MSL8.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code  AS VARCHAR(250)) + ' - ' + MSL9.[Description]  ELSE CAST(MSL9.Code  AS VARCHAR(250)) END,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE CAST(MSL10.Code AS VARCHAR(250)) END
        FROM      dbo.EntityStructureSetup        ESS
        LEFT JOIN dbo.ManagementStructureLevel     MSL1  WITH (NOLOCK) ON ESS.Level1Id  = MSL1.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL2  WITH (NOLOCK) ON ESS.Level2Id  = MSL2.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL3  WITH (NOLOCK) ON ESS.Level3Id  = MSL3.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL4  WITH (NOLOCK) ON ESS.Level4Id  = MSL4.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL5  WITH (NOLOCK) ON ESS.Level5Id  = MSL5.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL6  WITH (NOLOCK) ON ESS.Level6Id  = MSL6.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL7  WITH (NOLOCK) ON ESS.Level7Id  = MSL7.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL8  WITH (NOLOCK) ON ESS.Level8Id  = MSL8.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL9  WITH (NOLOCK) ON ESS.Level9Id  = MSL9.ID
        LEFT JOIN dbo.ManagementStructureLevel     MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
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
            MSL1.Code,  MSL1.[Description], MSL2.Code,  MSL2.[Description],
            MSL3.Code,  MSL3.[Description], MSL4.Code,  MSL4.[Description],
            MSL5.Code,  MSL5.[Description], MSL6.Code,  MSL6.[Description],
            MSL7.Code,  MSL7.[Description], MSL8.Code,  MSL8.[Description],
            MSL9.Code,  MSL9.[Description], MSL10.Code, MSL10.[Description];

        ---------------------------------------------------------------------------
        -- LOOP: Process each period in the selected range
        ---------------------------------------------------------------------------
        DECLARE
            @LoopRow            INT = 1,
            @TotalPeriods       INT,
            @CurPeriodId        BIGINT,
            @CurPeriodName      VARCHAR(100),
            @CurFiscalYear      VARCHAR(20),
            @CurPeriodType      VARCHAR(100),
            @CurPeriodEndDate   DATETIME,
            @CurToDate          DATETIME;

        SELECT @TotalPeriods = COUNT(1) FROM #SelectedPeriods;

        WHILE @LoopRow <= @TotalPeriods
        BEGIN

            -- ---- Load current period metadata ----
            SELECT
                @CurPeriodId      = AccountingPeriodId,
                @CurPeriodName    = PeriodName,
                @CurFiscalYear    = FiscalYear,
                @CurPeriodType    = PeriodType,
                @CurPeriodEndDate = PeriodEndDate,
                @CurToDate        = ToDate
            FROM #SelectedPeriods
            WHERE RowNum = @LoopRow;

            -- ---- Working temp tables for this period ----
            IF OBJECT_ID(N'tempdb..#TEMP')        IS NOT NULL DROP TABLE #TEMP;
            IF OBJECT_ID(N'tempdb..#Temptbl')     IS NOT NULL DROP TABLE #Temptbl;
            IF OBJECT_ID(N'tempdb..#TempResults') IS NOT NULL DROP TABLE #TempResults;
            IF OBJECT_ID(N'tempdb..#AccPeriodTable_All') IS NOT NULL DROP TABLE #AccPeriodTable_All;

            CREATE TABLE #TEMP
            (
                ID                BIGINT IDENTITY(1, 1),
                GlAccountId       BIGINT NULL,
                EntityStructureId BIGINT,
                MasterCompanyId   INT,
                Level1Name        VARCHAR(100), Level2Name  VARCHAR(100),
                Level3Name        VARCHAR(100), Level4Name  VARCHAR(100),
                Level5Name        VARCHAR(100), Level6Name  VARCHAR(100),
                Level7Name        VARCHAR(100), Level8Name  VARCHAR(100),
                Level9Name        VARCHAR(100), Level10Name VARCHAR(100),
                Credit            DECIMAL(18, 2),
                Debit             DECIMAL(18, 2),
                SequenceNumber    INT
            );

            CREATE TABLE #Temptbl
            (
                ID                BIGINT IDENTITY(1, 1),
                GlAccountId       BIGINT,
                EntityStructureId BIGINT,
                MasterCompanyId   INT,
                Level1Name        VARCHAR(100), Level2Name  VARCHAR(100),
                Level3Name        VARCHAR(100), Level4Name  VARCHAR(100),
                Level5Name        VARCHAR(100), Level6Name  VARCHAR(100),
                Level7Name        VARCHAR(100), Level8Name  VARCHAR(100),
                Level9Name        VARCHAR(100), Level10Name VARCHAR(100),
                CreditAmount      DECIMAL(18, 2),
                DebitAmount       DECIMAL(18, 2),
                SequenceNumber    INT
            );

            CREATE TABLE #TempResults
            (
                ID                  BIGINT IDENTITY(1, 1),
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
                MonthlyCreditAmount DECIMAL(18, 2),
                MonthlyDebitAmount  DECIMAL(18, 2),
                YTDCreditAmount     DECIMAL(18, 2),
                YTDDebitAmount      DECIMAL(18, 2),
                SequenceNumber      INT
            );

            CREATE TABLE #AccPeriodTable_All
            (
                ID            BIGINT IDENTITY(1, 1),
                AccountcalID  BIGINT       NULL,
                LegalEntityId BIGINT       NULL,
                FiscalYear    BIGINT       NULL,
                PeriodName    VARCHAR(100) NULL,
                FromDate      DATETIME     NULL,
                ToDate        DATETIME     NULL
            );

            -- ---- Accounting periods from beginning up to current period ----
            INSERT INTO #AccPeriodTable_All (AccountcalID, LegalEntityId, FiscalYear, PeriodName, FromDate, ToDate)
            SELECT
                AC.AccountingCalendarId,
                AC.LegalEntityId,
                @CurFiscalYear,
                AC.PeriodName,
                AC.FromDate,
                AC.ToDate
            FROM dbo.AccountingCalendar AC WITH (NOLOCK)
            WHERE AC.LegalEntityId IN
                  (
                      SELECT MSL.LegalEntityId
                      FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
                      WHERE  MSL.ID IN (SELECT Item FROM #L1)
                  )
              AND AC.IsDeleted                  = 0
              AND ISNULL(AC.IsAdjustPeriod, 0)  = 0
              AND CAST(AC.FromDate AS DATE)     >= CAST(@GlobalFromDate        AS DATE)
              AND CAST(AC.ToDate   AS DATE)     <= CAST(@CurPeriodEndDate      AS DATE)
            ORDER BY AC.FiscalYear, AC.[Period];

            -- Additional matching periods by PeriodName (multi-entity support)
            INSERT INTO #AccPeriodTable_All (AccountcalID, LegalEntityId, FiscalYear, PeriodName, FromDate, ToDate)
            SELECT DISTINCT
                AC.AccountingCalendarId,
                tmpAC.LegalEntityId,
                @CurFiscalYear,
                AC.PeriodName,
                AC.FromDate,
                AC.ToDate
            FROM      dbo.AccountingCalendar AC    WITH (NOLOCK)
            JOIN      #AccPeriodTable_All    tmpAC ON tmpAC.PeriodName = AC.PeriodName;

            -- ---- YTD Data (#TEMP) ----
            ;WITH RESULT AS
            (
                SELECT
                    CB.GlAccountId,
                    MSD.EntityMSID AS EntityStructureId,
                    CB.[MasterCompanyId],
                    SUM(ISNULL(CB.CreditAmount, 0)) AS Credit,
                    SUM(ISNULL(CB.DebitAmount,  0)) AS Debit,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code  AS VARCHAR(250)) + ' - ' + MSL1.[Description]  ELSE CAST(MSL1.Code  AS VARCHAR(250)) END AS Level1Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code  AS VARCHAR(250)) + ' - ' + MSL2.[Description]  ELSE CAST(MSL2.Code  AS VARCHAR(250)) END AS Level2Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code  AS VARCHAR(250)) + ' - ' + MSL3.[Description]  ELSE CAST(MSL3.Code  AS VARCHAR(250)) END AS Level3Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code  AS VARCHAR(250)) + ' - ' + MSL4.[Description]  ELSE CAST(MSL4.Code  AS VARCHAR(250)) END AS Level4Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code  AS VARCHAR(250)) + ' - ' + MSL5.[Description]  ELSE CAST(MSL5.Code  AS VARCHAR(250)) END AS Level5Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code  AS VARCHAR(250)) + ' - ' + MSL6.[Description]  ELSE CAST(MSL6.Code  AS VARCHAR(250)) END AS Level6Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code  AS VARCHAR(250)) + ' - ' + MSL7.[Description]  ELSE CAST(MSL7.Code  AS VARCHAR(250)) END AS Level7Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code  AS VARCHAR(250)) + ' - ' + MSL8.[Description]  ELSE CAST(MSL8.Code  AS VARCHAR(250)) END AS Level8Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code  AS VARCHAR(250)) + ' - ' + MSL9.[Description]  ELSE CAST(MSL9.Code  AS VARCHAR(250)) END AS Level9Name,
                    CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
                    GC.SequenceNumber
                FROM       dbo.CommonBatchDetails                              CB   WITH (NOLOCK)
                INNER JOIN dbo.BatchDetails                                    BD   WITH (NOLOCK) ON CB.JournalBatchDetailId         = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
                INNER JOIN dbo.BatchHeader                                     B    WITH (NOLOCK) ON BD.JournalBatchHeaderId         = B.JournalBatchHeaderId
                INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD  WITH (NOLOCK) ON MSD.ReferenceId                 = CB.CommonJournalBatchDetailId AND MSD.ModuleId = @BatchMSModuleId
                INNER JOIN dbo.GLAccount                                       GL   WITH (NOLOCK) ON CB.GlAccountId                  = GL.GLAccountId AND CB.MasterCompanyId = GL.MasterCompanyId
                                                                                                 AND (@StatisticalGLAccountTypeId IS NULL OR @StatisticalGLAccountTypeId = 0 OR GL.GLAccountTypeId <> @StatisticalGLAccountTypeId)
                LEFT  JOIN dbo.GLAccountClass                                  GC   WITH (NOLOCK) ON GL.GLAccountTypeId              = GC.GLAccountClassId
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL1 WITH (NOLOCK) ON MSD.Level1Id                   = MSL1.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL2 WITH (NOLOCK) ON MSD.Level2Id                   = MSL2.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL3 WITH (NOLOCK) ON MSD.Level3Id                   = MSL3.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL4 WITH (NOLOCK) ON MSD.Level4Id                   = MSL4.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL5 WITH (NOLOCK) ON MSD.Level5Id                   = MSL5.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL6 WITH (NOLOCK) ON MSD.Level6Id                   = MSL6.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL7 WITH (NOLOCK) ON MSD.Level7Id                   = MSL7.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL8 WITH (NOLOCK) ON MSD.Level8Id                   = MSL8.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL9 WITH (NOLOCK) ON MSD.Level9Id                   = MSL9.ID
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL10 WITH (NOLOCK) ON MSD.Level10Id                 = MSL10.ID
                WHERE ISNULL(CB.IsDeleted,          0) = 0
                  AND ISNULL(BD.IsDeleted,          0) = 0
                  AND ISNULL(B.IsDeleted,           0) = 0
                  AND ISNULL(CB.IsVersionIncrease,  0) = 0
                  AND CB.MasterCompanyId              = @masterCompanyId
                  AND BD.AccountingPeriodId IN (SELECT DISTINCT AccountcalID FROM #AccPeriodTable_All)
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
                    CB.GlAccountId, MSD.EntityMSID, CB.[MasterCompanyId],
                    MSL1.Code, MSL1.[Description], MSL2.Code,  MSL2.[Description],
                    MSL3.Code, MSL3.[Description], MSL4.Code,  MSL4.[Description],
                    MSL5.Code, MSL5.[Description], MSL6.Code,  MSL6.[Description],
                    MSL7.Code, MSL7.[Description], MSL8.Code,  MSL8.[Description],
                    MSL9.Code, MSL9.[Description], MSL10.Code, MSL10.[Description],
                    GC.SequenceNumber
            )
            INSERT INTO #TEMP
                (GlAccountId, EntityStructureId, MasterCompanyId, Credit, Debit,
                 Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                 Level6Name, Level7Name, Level8Name, Level9Name, Level10Name, SequenceNumber)
            SELECT
                GlAccountId, EntityStructureId, MasterCompanyId,
                SUM(ISNULL(Credit, 0)), SUM(ISNULL(Debit, 0)),
                Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                Level6Name, Level7Name, Level8Name, Level9Name, Level10Name, SequenceNumber
            FROM RESULT
            GROUP BY
                GlAccountId, EntityStructureId, MasterCompanyId,
                Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                Level6Name, Level7Name, Level8Name, Level9Name, Level10Name, SequenceNumber;

            -- ---- Monthly Data for this period (#Temptbl) ----
            -- "Monthly" = this specific period only, so filter #AccPeriodTable_All to current period
            INSERT INTO #Temptbl
                (GlAccountId, EntityStructureId, MasterCompanyId,
                 Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                 Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                 CreditAmount, DebitAmount, SequenceNumber)
            SELECT DISTINCT
                CMB.GlAccountId,
                MSD.EntityMSID AS EntityStructureId,
                CMB.[MasterCompanyId],
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code  AS VARCHAR(250)) + ' - ' + MSL1.[Description]  ELSE CAST(MSL1.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code  AS VARCHAR(250)) + ' - ' + MSL2.[Description]  ELSE CAST(MSL2.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code  AS VARCHAR(250)) + ' - ' + MSL3.[Description]  ELSE CAST(MSL3.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code  AS VARCHAR(250)) + ' - ' + MSL4.[Description]  ELSE CAST(MSL4.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code  AS VARCHAR(250)) + ' - ' + MSL5.[Description]  ELSE CAST(MSL5.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code  AS VARCHAR(250)) + ' - ' + MSL6.[Description]  ELSE CAST(MSL6.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code  AS VARCHAR(250)) + ' - ' + MSL7.[Description]  ELSE CAST(MSL7.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code  AS VARCHAR(250)) + ' - ' + MSL8.[Description]  ELSE CAST(MSL8.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code  AS VARCHAR(250)) + ' - ' + MSL9.[Description]  ELSE CAST(MSL9.Code  AS VARCHAR(250)) END,
                CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE CAST(MSL10.Code AS VARCHAR(250)) END,
                SUM(ISNULL(CMB.CreditAmount, 0)),
                SUM(ISNULL(CMB.DebitAmount,  0)),
                GC.SequenceNumber
            FROM       dbo.CommonBatchDetails                              CMB  WITH (NOLOCK)
            INNER JOIN dbo.BatchDetails                                    BD   WITH (NOLOCK) ON CMB.JournalBatchDetailId         = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
            INNER JOIN dbo.BatchHeader                                     B    WITH (NOLOCK) ON BD.JournalBatchHeaderId          = B.JournalBatchHeaderId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD  WITH (NOLOCK) ON MSD.ReferenceId                  = CMB.CommonJournalBatchDetailId AND MSD.ModuleId = @BatchMSModuleId
            INNER JOIN dbo.GLAccount                                       GL   WITH (NOLOCK) ON CMB.GlAccountId                  = GL.GLAccountId AND CMB.MasterCompanyId = GL.MasterCompanyId
                                                                                             AND (@StatisticalGLAccountTypeId IS NULL OR @StatisticalGLAccountTypeId = 0 OR GL.GLAccountTypeId <> @StatisticalGLAccountTypeId)
            LEFT  JOIN dbo.GLAccountClass                                  GC   WITH (NOLOCK) ON GL.GLAccountTypeId               = GC.GLAccountClassId
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL1 WITH (NOLOCK) ON MSD.Level1Id                    = MSL1.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL2 WITH (NOLOCK) ON MSD.Level2Id                    = MSL2.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL3 WITH (NOLOCK) ON MSD.Level3Id                    = MSL3.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL4 WITH (NOLOCK) ON MSD.Level4Id                    = MSL4.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL5 WITH (NOLOCK) ON MSD.Level5Id                    = MSL5.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL6 WITH (NOLOCK) ON MSD.Level6Id                    = MSL6.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL7 WITH (NOLOCK) ON MSD.Level7Id                    = MSL7.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL8 WITH (NOLOCK) ON MSD.Level8Id                    = MSL8.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL9 WITH (NOLOCK) ON MSD.Level9Id                    = MSL9.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL10 WITH (NOLOCK) ON MSD.Level10Id                  = MSL10.ID
            WHERE ISNULL(CMB.IsDeleted,         0) = 0
              AND ISNULL(BD.IsDeleted,          0) = 0
              AND ISNULL(B.IsDeleted,           0) = 0
              AND ISNULL(CMB.IsVersionIncrease, 0) = 0
              AND CMB.MasterCompanyId              = @masterCompanyId
              AND BD.AccountingPeriodId            = @CurPeriodId   -- current period only for "monthly"
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
                CMB.GlAccountId, MSD.EntityMSID, CMB.[MasterCompanyId],
                MSL1.Code, MSL1.[Description], MSL2.Code,  MSL2.[Description],
                MSL3.Code, MSL3.[Description], MSL4.Code,  MSL4.[Description],
                MSL5.Code, MSL5.[Description], MSL6.Code,  MSL6.[Description],
                MSL7.Code, MSL7.[Description], MSL8.Code,  MSL8.[Description],
                MSL9.Code, MSL9.[Description], MSL10.Code, MSL10.[Description],
                GC.SequenceNumber;

            -- ---- Total amounts for this period ----
            SET @TotalCreditAmount = 0;
            SET @TotalDebitAmount  = 0;

            ;WITH BatchResult AS
            (
                SELECT
                    CMB.GlAccountId,
                    MSD.EntityMSID              AS EntityStructureId,
                    ISNULL(CMB.CreditAmount, 0) AS CreditAmount,
                    ISNULL(CMB.DebitAmount,  0) AS DebitAmount
                FROM       dbo.CommonBatchDetails                              CMB  WITH (NOLOCK)
                INNER JOIN dbo.BatchDetails                                    BD   WITH (NOLOCK) ON CMB.JournalBatchDetailId         = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
                INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD  WITH (NOLOCK) ON MSD.ReferenceId                  = CMB.CommonJournalBatchDetailId AND MSD.ModuleId = @BatchMSModuleId
                LEFT  JOIN dbo.ManagementStructureLevel                        MSL1 WITH (NOLOCK) ON MSD.Level1Id                    = MSL1.ID
                WHERE ISNULL(CMB.IsDeleted,         0) = 0
                  AND ISNULL(BD.IsDeleted,          0) = 0
                  AND ISNULL(CMB.IsVersionIncrease, 0) = 0
                  AND CMB.MasterCompanyId              = @masterCompanyId
                  AND BD.AccountingPeriodId            = @CurPeriodId
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
            ),
            AmountResult AS
            (
                SELECT
                    GlAccountId, EntityStructureId,
                    CASE WHEN (SUM(DebitAmount) - SUM(CreditAmount)) > 0 THEN 0
                         ELSE ABS(SUM(DebitAmount) - SUM(CreditAmount))
                    END AS CreditAmount,
                    CASE WHEN (SUM(DebitAmount) - SUM(CreditAmount)) > 0 THEN SUM(DebitAmount) - SUM(CreditAmount)
                         ELSE 0
                    END AS DebitAmount
                FROM BatchResult
                GROUP BY GlAccountId, EntityStructureId
            )
            SELECT
                @TotalCreditAmount = SUM(CreditAmount),
                @TotalDebitAmount  = SUM(DebitAmount)
            FROM AmountResult;

            -- ---- Populate #TempResults (YTD amounts) ----
            INSERT INTO #TempResults
                (GlAccountId, EntityStructureId, MasterCompanyId, AccountNum, AccountName,
                 Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                 Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                 YTDDebitAmount, YTDCreditAmount, SequenceNumber)
            SELECT DISTINCT
                YTD.GlAccountId,
                YTD.EntityStructureId,
                YTD.MasterCompanyId,
                GL.AccountCode,
                GL.AccountName,
                YTD.Level1Name, YTD.Level2Name, YTD.Level3Name, YTD.Level4Name, YTD.Level5Name,
                YTD.Level6Name, YTD.Level7Name, YTD.Level8Name, YTD.Level9Name, YTD.Level10Name,
                CASE WHEN (ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)) > 0
                     THEN ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0) ELSE 0
                END,
                CASE WHEN (ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)) > 0
                     THEN 0 ELSE ABS(ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0))
                END,
                YTD.SequenceNumber
            FROM #TEMP YTD
            INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId     = GL.GLAccountId
                                                      AND YTD.MasterCompanyId = GL.MasterCompanyId;

            -- Update Monthly Credit Amount
            UPDATE #TempResults
            SET MonthlyCreditAmount = results.CreditAmount
            FROM
            (
                SELECT
                    T1.GlAccountId, T1.EntityStructureId,
                    CASE WHEN (SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0))) > 0
                         THEN 0
                         ELSE ABS(SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0)))
                    END AS CreditAmount
                FROM  #TempResults T1
                JOIN  #Temptbl     T2 ON T1.GlAccountId = T2.GlAccountId AND T1.EntityStructureId = T2.EntityStructureId
                GROUP BY T1.GlAccountId, T1.EntityStructureId
            ) results
            WHERE results.GlAccountId       = #TempResults.GlAccountId
              AND results.EntityStructureId = #TempResults.EntityStructureId;

            -- Update Monthly Debit Amount
            UPDATE #TempResults
            SET MonthlyDebitAmount = results.DebitAmount
            FROM
            (
                SELECT
                    T1.GlAccountId, T1.EntityStructureId,
                    CASE WHEN (SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0))) > 0
                         THEN SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0))
                         ELSE 0
                    END AS DebitAmount
                FROM  #TempResults T1
                JOIN  #Temptbl     T2 ON T1.GlAccountId = T2.GlAccountId AND T1.EntityStructureId = T2.EntityStructureId
                GROUP BY T1.GlAccountId, T1.EntityStructureId
            ) results
            WHERE results.GlAccountId       = #TempResults.GlAccountId
              AND results.EntityStructureId = #TempResults.EntityStructureId;

            -- ---- Append to final output table ----
            IF (@IsSupressZero = 1)
            BEGIN
                IF (@PeriodReportLayOutId = @ReportLayoutId)
                BEGIN
                    INSERT INTO #FinalOutput
                        (PeriodName, AccountingPeriodId, GlAccountId, AccountNum, AccountName,
                         EntityStructureId, Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                         Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                         MonthlyCreditAmount, MonthlyDebitAmount, YTDCreditAmount, YTDDebitAmount,
                         Balance, TotalCreditAmount, TotalDebitAmount, SequenceNumber)
                    SELECT
                        @CurPeriodName, @CurPeriodId,
                        GlAccountId, AccountNum, AccountName, EntityStructureId,
                        Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                        Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                        MonthlyCreditAmount, MonthlyDebitAmount, YTDCreditAmount, YTDDebitAmount,
                        (ISNULL(YTDDebitAmount, 0) - ISNULL(YTDCreditAmount, 0)),
                        @TotalCreditAmount, @TotalDebitAmount, SequenceNumber
                    FROM #TempResults
                    WHERE YTDCreditAmount > 0 OR YTDDebitAmount > 0;
                END
                ELSE
                BEGIN
                    INSERT INTO #FinalOutput
                        (PeriodName, AccountingPeriodId, GlAccountId, AccountNum, AccountName,
                         EntityStructureId, Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                         Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                         MonthlyCreditAmount, MonthlyDebitAmount, YTDCreditAmount, YTDDebitAmount,
                         Balance, TotalCreditAmount, TotalDebitAmount, SequenceNumber)
                    SELECT
                        @CurPeriodName, @CurPeriodId,
                        GlAccountId, AccountNum, AccountName, EntityStructureId,
                        Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                        Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                        MonthlyCreditAmount, MonthlyDebitAmount, YTDCreditAmount, YTDDebitAmount,
                        (ISNULL(YTDDebitAmount, 0) - ISNULL(YTDCreditAmount, 0)),
                        @TotalCreditAmount, @TotalDebitAmount, SequenceNumber
                    FROM #TempResults
                    WHERE MonthlyCreditAmount > 0 OR MonthlyDebitAmount > 0
                       OR YTDCreditAmount     > 0 OR YTDDebitAmount     > 0;
                END
            END
            ELSE
            BEGIN
                -- No suppression: include all GL accounts
                INSERT INTO #TempResults (GlAccountId, MasterCompanyId, AccountNum, AccountName)
                SELECT GL.GlAccountId, GL.MasterCompanyId, GL.AccountCode, GL.AccountName
                FROM   dbo.GLAccount GL
                WHERE  GL.GlAccountId    NOT IN (SELECT GlAccountId FROM #TempResults)
                  AND  GL.MasterCompanyId = @masterCompanyId
                  AND  GL.IsActive        = 1
                  AND  GL.IsDeleted       = 0;

                UPDATE #TempResults
                SET
                    Level1Name  = ESS.Level1Name, Level2Name  = ESS.Level2Name,
                    Level3Name  = ESS.Level3Name, Level4Name  = ESS.Level4Name,
                    Level5Name  = ESS.Level5Name, Level6Name  = ESS.Level6Name,
                    Level7Name  = ESS.Level7Name, Level8Name  = ESS.Level8Name,
                    Level9Name  = ESS.Level9Name, Level10Name = ESS.Level10Name
                FROM #tmpEntityStructureSetup ESS
                WHERE ESS.ID = (SELECT MIN(ID) FROM #tmpEntityStructureSetup)
                  AND ISNULL(#TempResults.Level1Name, '') = '';

                INSERT INTO #FinalOutput
                    (PeriodName, AccountingPeriodId, GlAccountId, AccountNum, AccountName,
                     EntityStructureId, Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                     Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                     MonthlyCreditAmount, MonthlyDebitAmount, YTDCreditAmount, YTDDebitAmount,
                     Balance, TotalCreditAmount, TotalDebitAmount, SequenceNumber)
                SELECT
                    @CurPeriodName, @CurPeriodId,
                    GlAccountId, AccountNum, AccountName, EntityStructureId,
                    Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
                    Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
                    MonthlyCreditAmount, MonthlyDebitAmount, YTDCreditAmount, YTDDebitAmount,
                    (ISNULL(YTDDebitAmount, 0) - ISNULL(YTDCreditAmount, 0)),
                    @TotalCreditAmount, @TotalDebitAmount, SequenceNumber
                FROM #TempResults;
            END

            SET @LoopRow = @LoopRow + 1;

        END -- WHILE

        ---------------------------------------------------------------------------
        -- Final SELECT: all periods, ordered by period then account number
        ---------------------------------------------------------------------------
        SELECT
            PeriodName,
            AccountingPeriodId,
            GlAccountId,
            EntityStructureId,
            AccountNum,
            AccountName,
            Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
            Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
            MonthlyCreditAmount AS Credit,
            MonthlyDebitAmount  AS Debit,
            YTDCreditAmount     AS CR,
            YTDDebitAmount      AS DR,
            Balance,
            TotalCreditAmount,
            TotalDebitAmount
        FROM #FinalOutput
        ORDER BY
            AccountingPeriodId,
            TRY_CAST(AccountNum AS BIGINT);

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