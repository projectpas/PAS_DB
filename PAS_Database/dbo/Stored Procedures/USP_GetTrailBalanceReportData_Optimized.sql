
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
	13   05/23/2025   Hemant Saliya  Changed Logic to get trila Balance from beggining
 **************************************************************

 exec dbo.USP_GetTrailBalanceReportData @masterCompanyId=1,  @managementStructureId=1,  @AccountingPeriodId=135, @IsSupressZero=1, @IsShortMS=1, @strFilter=N'1!2,7!3,11,10!4,12'
 exec dbo.USP_GetTrailBalanceReportData @masterCompanyId=21, @managementStructureId=41, @AccountingPeriodId=194, @IsSupressZero=1, @IsShortMS=1, @strFilter=N'5!8!11,10!12'
*************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportData_Optimized]
(
    @masterCompanyId        VARCHAR(50)  = NULL,
    @managementStructureId  VARCHAR(50)  = NULL,
    @AccountingPeriodId     BIGINT       = NULL,
    @IsSupressZero          BIT          = NULL,
    @IsShortMS              BIT          = NULL,
    @strFilter              VARCHAR(MAX) = NULL,
    @ReportLayoutId         BIGINT       = NULL
)
AS
BEGIN
    BEGIN TRY
    BEGIN

        ---------------------------------------------------------------------------
        -- Variable Declarations
        ---------------------------------------------------------------------------
        DECLARE @PeriodType                 VARCHAR(100)    = '';
        DECLARE @FiscalYear                 VARCHAR(20)     = '';
        DECLARE @FromDate                   DATETIME        = NULL;
        DECLARE @ToDate                     DATETIME        = NULL;
        DECLARE @PeriodEndDate              DATETIME        = NULL;
        DECLARE @BatchMSModuleId            BIGINT;
        DECLARE @PostedBatchStatusId        BIGINT;
        DECLARE @StatisticalGLAccountTypeId BIGINT;
        DECLARE @PeriodName                 VARCHAR(100)    = '';
        DECLARE @xml                        XML;
        DECLARE @PeriodReportLayOutId       BIGINT;
        DECLARE @TotalCreditAmount          DECIMAL(18, 2);
        DECLARE @TotalDebitAmount           DECIMAL(18, 2);

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
        -- Drop and Create Working Temp Tables
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#TEMP')        IS NOT NULL DROP TABLE #TEMP;
        IF OBJECT_ID(N'tempdb..#Temptbl')     IS NOT NULL DROP TABLE #Temptbl;
        IF OBJECT_ID(N'tempdb..#TempResults') IS NOT NULL DROP TABLE #TempResults;

        CREATE TABLE #TEMP
        (
            ID               BIGINT IDENTITY(1, 1),
            GlAccountId      BIGINT NULL,
            EntityStructureId BIGINT,
            MasterCompanyId  INT,
            Level1Name       VARCHAR(100),
            Level2Name       VARCHAR(100),
            Level3Name       VARCHAR(100),
            Level4Name       VARCHAR(100),
            Level5Name       VARCHAR(100),
            Level6Name       VARCHAR(100),
            Level7Name       VARCHAR(100),
            Level8Name       VARCHAR(100),
            Level9Name       VARCHAR(100),
            Level10Name      VARCHAR(100),
            Credit           DECIMAL(18, 2),
            Debit            DECIMAL(18, 2),
            SequenceNumber   INT
        );

        CREATE TABLE #Temptbl
        (
            ID               BIGINT IDENTITY(1, 1),
            GlAccountId      BIGINT,
            EntityStructureId BIGINT,
            MasterCompanyId  INT,
            Level1Name       VARCHAR(100),
            Level2Name       VARCHAR(100),
            Level3Name       VARCHAR(100),
            Level4Name       VARCHAR(100),
            Level5Name       VARCHAR(100),
            Level6Name       VARCHAR(100),
            Level7Name       VARCHAR(100),
            Level8Name       VARCHAR(100),
            Level9Name       VARCHAR(100),
            Level10Name      VARCHAR(100),
            CreditAmount     DECIMAL(18, 2),
            DebitAmount      DECIMAL(18, 2),
            SequenceNumber   INT
        );

        CREATE TABLE #TempResults
        (
            ID                  BIGINT IDENTITY(1, 1),
            GlAccountId         BIGINT,
            AccountNum          VARCHAR(200),
            AccountName         VARCHAR(200),
            EntityStructureId   BIGINT,
            MasterCompanyId     INT,
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
            SequenceNumber      INT
        );

        CREATE TABLE #TempFinalResults
        (
            ID               BIGINT IDENTITY(1, 1),
            GlAccountId      BIGINT,
            AccountNum       VARCHAR(200),
            AccountName      VARCHAR(200),
            EntityStructureId BIGINT,
            Level1Name       VARCHAR(100),
            Level2Name       VARCHAR(100),
            Level3Name       VARCHAR(100),
            Level4Name       VARCHAR(100),
            Level5Name       VARCHAR(100),
            Level6Name       VARCHAR(100),
            Level7Name       VARCHAR(100),
            Level8Name       VARCHAR(100),
            Level9Name       VARCHAR(100),
            Level10Name      VARCHAR(100),
            Credit           DECIMAL(18, 2),
            Debit            DECIMAL(18, 2),
            CR               DECIMAL(18, 2),
            DR               DECIMAL(18, 2),
            SequenceNumber   INT
        );

        CREATE TABLE #tmpEntityStructureSetup
        (
            ID               BIGINT IDENTITY(1, 1),
            EntityStructureId BIGINT,
            LegalEntityId    BIGINT,
            MasterCompanyId  INT,
            Level1Name       VARCHAR(100),
            Level2Name       VARCHAR(100),
            Level3Name       VARCHAR(100),
            Level4Name       VARCHAR(100),
            Level5Name       VARCHAR(100),
            Level6Name       VARCHAR(100),
            Level7Name       VARCHAR(100),
            Level8Name       VARCHAR(100),
            Level9Name       VARCHAR(100),
            Level10Name      VARCHAR(100)
        );

        ---------------------------------------------------------------------------
        -- Lookup: Accounting Calendar, Batch Status, Statistical GL Account Type
        ---------------------------------------------------------------------------
        SELECT
            @ToDate        = EndDate,
            @FiscalYear    = FiscalYear,
			@PeriodType    = PeriodType,
            @PeriodEndDate = ToDate,
            @PeriodName    = UPPER(PeriodName)
        FROM dbo.AccountingCalendar WITH (NOLOCK)
        WHERE AccountingCalendarId = @AccountingPeriodId;

        SET @BatchMSModuleId = 72; -- BATCH MS MODULE ID

        SELECT @PostedBatchStatusId = Id
        FROM   dbo.BatchStatus WITH (NOLOCK)
        WHERE  [Name] = 'Posted';

        SELECT @StatisticalGLAccountTypeId = ISNULL(GLAccountClassId, 0)
        FROM   dbo.GLAccountClass WITH (NOLOCK)
        WHERE  UPPER(GLAccountClassName) = 'STATISTICAL'
          AND  MasterCompanyId           = @MasterCompanyId
          AND  ISNULL(IsDeleted, 0)      = 0
          AND  ISNULL(IsActive, 0)       = 1;

		SELECT @FromDate = MIN(FromDate) 
		FROM dbo.AccountingCalendar WITH(NOLOCK) 
		WHERE MasterCompanyId = @MasterCompanyId AND LegalEntityId IN
              (
                  SELECT MSL.LegalEntityId
                  FROM   dbo.ManagementStructureLevel MSL WITH (NOLOCK)
                  WHERE  MSL.ID IN (SELECT Item FROM #L1)
              ) AND IsDeleted = 0 

        ---------------------------------------------------------------------------
        -- Build Accounting Period Table (all periods up to selected period)
        ---------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#AccPeriodTable_All') IS NOT NULL DROP TABLE #AccPeriodTable_All;

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

        -- Insert periods for Level1 legal entities
        INSERT INTO #AccPeriodTable_All (AccountcalID, LegalEntityId, FiscalYear, PeriodName, FromDate, ToDate)
        SELECT
            AC.AccountingCalendarId,
            AC.LegalEntityId,
            @FiscalYear,
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
          AND AC.IsDeleted             = 0
          AND CAST(AC.Fromdate AS DATE) >= CAST(@FromDate AS DATE)
          AND CAST(AC.ToDate   AS DATE) <= CAST(@PeriodEndDate   AS DATE)
          AND ISNULL(AC.IsAdjustPeriod, 0) = 0
        ORDER BY AC.FiscalYear, AC.[Period];

        -- Insert any additional matching periods by PeriodName
        INSERT INTO #AccPeriodTable_All (AccountcalID, LegalEntityId, FiscalYear, PeriodName, FromDate, ToDate)
        SELECT DISTINCT
            AC.AccountingCalendarId,
            tmpAC.LegalEntityId,
            @FiscalYear,
            AC.PeriodName,
            AC.FromDate,
            AC.ToDate
        FROM      dbo.AccountingCalendar  AC    WITH (NOLOCK)
        JOIN      #AccPeriodTable_All     tmpAC ON tmpAC.PeriodName = AC.PeriodName;

        ---------------------------------------------------------------------------
        -- YTD Data: All periods in fiscal year up to selected period (#TEMP)
        ---------------------------------------------------------------------------
        ;WITH RESULT AS
        (
            SELECT
                CB.GlAccountId,
                MSD.EntityMSID                                                                                                                    AS EntityStructureId,
                CB.[MasterCompanyId],
                SUM(ISNULL(CB.CreditAmount, 0))                                                                                                   AS Credit,
                SUM(ISNULL(CB.DebitAmount,  0))                                                                                                   AS Debit,
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
            INNER JOIN dbo.BatchDetails                                    BD   WITH (NOLOCK) ON CB.JournalBatchDetailId       = BD.JournalBatchDetailId AND BD.StatusId  = @PostedBatchStatusId
            INNER JOIN dbo.BatchHeader                                     B    WITH (NOLOCK) ON BD.JournalBatchHeaderId       = B.JournalBatchHeaderId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD  WITH (NOLOCK) ON MSD.ReferenceId               = CB.CommonJournalBatchDetailId AND MSD.ModuleId = @BatchMSModuleId
            INNER JOIN dbo.GLAccount                                       GL   WITH (NOLOCK) ON CB.GlAccountId                = GL.GLAccountId
                                                                                              AND CB.MasterCompanyId           = GL.MasterCompanyId
                                                                                              AND (   @StatisticalGLAccountTypeId IS NULL
                                                                                                   OR @StatisticalGLAccountTypeId = 0
                                                                                                   OR GL.GLAccountTypeId     <> @StatisticalGLAccountTypeId)
            LEFT  JOIN dbo.GLAccountClass                                  GC   WITH (NOLOCK) ON GL.GLAccountTypeId            = GC.GLAccountClassId
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL1 WITH (NOLOCK) ON MSD.Level1Id                  = MSL1.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL2 WITH (NOLOCK) ON MSD.Level2Id                  = MSL2.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL3 WITH (NOLOCK) ON MSD.Level3Id                  = MSL3.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL4 WITH (NOLOCK) ON MSD.Level4Id                  = MSL4.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL5 WITH (NOLOCK) ON MSD.Level5Id                  = MSL5.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL6 WITH (NOLOCK) ON MSD.Level6Id                  = MSL6.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL7 WITH (NOLOCK) ON MSD.Level7Id                  = MSL7.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL8 WITH (NOLOCK) ON MSD.Level8Id                  = MSL8.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL9 WITH (NOLOCK) ON MSD.Level9Id                  = MSL9.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL10 WITH (NOLOCK) ON MSD.Level10Id                = MSL10.ID
            WHERE CB.IsDeleted                    = 0
              AND CB.MasterCompanyId              = @MasterCompanyId
              AND BD.IsDeleted                    = 0
              AND B.IsDeleted                     = 0
              AND ISNULL(CB.IsVersionIncrease, 0) = 0
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
                MSL1.Code,  MSL1.[Description],
                MSL2.Code,  MSL2.[Description],
                MSL3.Code,  MSL3.[Description],
                MSL4.Code,  MSL4.[Description],
                MSL5.Code,  MSL5.[Description],
                MSL6.Code,  MSL6.[Description],
                MSL7.Code,  MSL7.[Description],
                MSL8.Code,  MSL8.[Description],
                MSL9.Code,  MSL9.[Description],
                MSL10.Code, MSL10.[Description],
                GC.SequenceNumber
        )
        INSERT INTO #TEMP
            (GlAccountId, EntityStructureId, MasterCompanyId, Credit, Debit,
             Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
             Level6Name, Level7Name, Level8Name, Level9Name, Level10Name, SequenceNumber)
        SELECT
            GlAccountId, EntityStructureId, MasterCompanyId,
            SUM(ISNULL(Credit, 0)),
            SUM(ISNULL(Debit,  0)),
            Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
            Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
            SequenceNumber
        FROM RESULT
        GROUP BY
            GlAccountId, EntityStructureId, MasterCompanyId,
            Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
            Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
            SequenceNumber;

        ---------------------------------------------------------------------------
        -- Entity Structure Setup (for non-suppressed zero path)
        ---------------------------------------------------------------------------
        INSERT INTO #tmpEntityStructureSetup
            (EntityStructureId, MasterCompanyId, LegalEntityId,
             Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
             Level6Name, Level7Name, Level8Name, Level9Name, Level10Name)
        SELECT
            ESS.EntityStructureId,
            ESS.MasterCompanyId,
            MSL1.LegalEntityId,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code  AS VARCHAR(250)) + ' - ' + MSL1.[Description]  ELSE CAST(MSL1.Code  AS VARCHAR(250)) END AS Level1Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code  AS VARCHAR(250)) + ' - ' + MSL2.[Description]  ELSE CAST(MSL2.Code  AS VARCHAR(250)) END AS Level2Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code  AS VARCHAR(250)) + ' - ' + MSL3.[Description]  ELSE CAST(MSL3.Code  AS VARCHAR(250)) END AS Level3Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code  AS VARCHAR(250)) + ' - ' + MSL4.[Description]  ELSE CAST(MSL4.Code  AS VARCHAR(250)) END AS Level4Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code  AS VARCHAR(250)) + ' - ' + MSL5.[Description]  ELSE CAST(MSL5.Code  AS VARCHAR(250)) END AS Level5Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code  AS VARCHAR(250)) + ' - ' + MSL6.[Description]  ELSE CAST(MSL6.Code  AS VARCHAR(250)) END AS Level6Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code  AS VARCHAR(250)) + ' - ' + MSL7.[Description]  ELSE CAST(MSL7.Code  AS VARCHAR(250)) END AS Level7Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code  AS VARCHAR(250)) + ' - ' + MSL8.[Description]  ELSE CAST(MSL8.Code  AS VARCHAR(250)) END AS Level8Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code  AS VARCHAR(250)) + ' - ' + MSL9.[Description]  ELSE CAST(MSL9.Code  AS VARCHAR(250)) END AS Level9Name,
            CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name
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
        WHERE ESS.MasterCompanyId = @MasterCompanyId
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
            MSL1.Code,  MSL1.[Description],
            MSL2.Code,  MSL2.[Description],
            MSL3.Code,  MSL3.[Description],
            MSL4.Code,  MSL4.[Description],
            MSL5.Code,  MSL5.[Description],
            MSL6.Code,  MSL6.[Description],
            MSL7.Code,  MSL7.[Description],
            MSL8.Code,  MSL8.[Description],
            MSL9.Code,  MSL9.[Description],
            MSL10.Code, MSL10.[Description];

        ---------------------------------------------------------------------------
        -- Monthly Data: Current period only (#Temptbl)
        ---------------------------------------------------------------------------
        INSERT INTO #Temptbl
            (GlAccountId, EntityStructureId, MasterCompanyId,
             Level1Name, Level2Name, Level3Name, Level4Name, Level5Name,
             Level6Name, Level7Name, Level8Name, Level9Name, Level10Name,
             CreditAmount, DebitAmount, SequenceNumber)
        SELECT DISTINCT
            CMB.GlAccountId,
            MSD.EntityMSID                                                                                                                    AS EntityStructureId,
            CMB.[MasterCompanyId],
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
            SUM(ISNULL(CMB.CreditAmount, 0)) AS CreditAmount,
            SUM(ISNULL(CMB.DebitAmount,  0)) AS DebitAmount,
            GC.SequenceNumber
        FROM       dbo.CommonBatchDetails                              CMB  WITH (NOLOCK)
        INNER JOIN dbo.BatchDetails                                    BD   WITH (NOLOCK) ON CMB.JournalBatchDetailId       = BD.JournalBatchDetailId
                                                                                          AND BD.StatusId                  = @PostedBatchStatusId
        INNER JOIN dbo.BatchHeader                                     B    WITH (NOLOCK) ON BD.JournalBatchHeaderId        = B.JournalBatchHeaderId
        INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD  WITH (NOLOCK) ON MSD.ReferenceId                = CMB.CommonJournalBatchDetailId
                                                                                          AND MSD.ModuleId                 = @BatchMSModuleId
        INNER JOIN dbo.GLAccount                                       GL   WITH (NOLOCK) ON CMB.GlAccountId               = GL.GLAccountId
                                                                                          AND CMB.MasterCompanyId          = GL.MasterCompanyId
                                                                                          AND (   @StatisticalGLAccountTypeId IS NULL
                                                                                               OR @StatisticalGLAccountTypeId = 0
                                                                                               OR GL.GLAccountTypeId      <> @StatisticalGLAccountTypeId)
        LEFT  JOIN dbo.GLAccountClass                                  GC   WITH (NOLOCK) ON GL.GLAccountTypeId             = GC.GLAccountClassId
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL1 WITH (NOLOCK) ON MSD.Level1Id                  = MSL1.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL2 WITH (NOLOCK) ON MSD.Level2Id                  = MSL2.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL3 WITH (NOLOCK) ON MSD.Level3Id                  = MSL3.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL4 WITH (NOLOCK) ON MSD.Level4Id                  = MSL4.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL5 WITH (NOLOCK) ON MSD.Level5Id                  = MSL5.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL6 WITH (NOLOCK) ON MSD.Level6Id                  = MSL6.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL7 WITH (NOLOCK) ON MSD.Level7Id                  = MSL7.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL8 WITH (NOLOCK) ON MSD.Level8Id                  = MSL8.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL9 WITH (NOLOCK) ON MSD.Level9Id                  = MSL9.ID
        LEFT  JOIN dbo.ManagementStructureLevel                        MSL10 WITH (NOLOCK) ON MSD.Level10Id                = MSL10.ID
        WHERE CMB.IsDeleted                    = 0
          AND BD.IsDeleted                     = 0
          AND B.IsDeleted                      = 0
          AND CMB.MasterCompanyId              = @MasterCompanyId
          AND ISNULL(CMB.IsVersionIncrease, 0) = 0
          AND BD.AccountingPeriodId IN
              (
                  SELECT AccountcalID
                  FROM   #AccPeriodTable_All
                  WHERE  UPPER(PeriodName) = @PeriodName
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
            CMB.GlAccountId, MSD.EntityMSID, CMB.[MasterCompanyId],
            MSL1.Code,  MSL1.[Description],
            MSL2.Code,  MSL2.[Description],
            MSL3.Code,  MSL3.[Description],
            MSL4.Code,  MSL4.[Description],
            MSL5.Code,  MSL5.[Description],
            MSL6.Code,  MSL6.[Description],
            MSL7.Code,  MSL7.[Description],
            MSL8.Code,  MSL8.[Description],
            MSL9.Code,  MSL9.[Description],
            MSL10.Code, MSL10.[Description],
            GC.SequenceNumber;

        ---------------------------------------------------------------------------
        -- Calculate Total Monthly Credit / Debit Amounts
        ---------------------------------------------------------------------------
        ;WITH BatchResult AS
        (
            SELECT
                CMB.GlAccountId,
                MSD.EntityMSID                AS EntityStructureId,
                ISNULL(CMB.CreditAmount, 0)   AS CreditAmount,
                ISNULL(CMB.DebitAmount,  0)   AS DebitAmount
            FROM       dbo.CommonBatchDetails                              CMB  WITH (NOLOCK)
            INNER JOIN dbo.BatchDetails                                    BD   WITH (NOLOCK) ON CMB.JournalBatchDetailId       = BD.JournalBatchDetailId
                                                                                              AND BD.StatusId                  = @PostedBatchStatusId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails       MSD  WITH (NOLOCK) ON MSD.ReferenceId                = CMB.CommonJournalBatchDetailId
                                                                                              AND MSD.ModuleId                 = @BatchMSModuleId
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL1 WITH (NOLOCK) ON MSD.Level1Id                  = MSL1.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL2 WITH (NOLOCK) ON MSD.Level2Id                  = MSL2.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL3 WITH (NOLOCK) ON MSD.Level3Id                  = MSL3.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL4 WITH (NOLOCK) ON MSD.Level4Id                  = MSL4.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL5 WITH (NOLOCK) ON MSD.Level5Id                  = MSL5.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL6 WITH (NOLOCK) ON MSD.Level6Id                  = MSL6.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL7 WITH (NOLOCK) ON MSD.Level7Id                  = MSL7.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL8 WITH (NOLOCK) ON MSD.Level8Id                  = MSL8.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL9 WITH (NOLOCK) ON MSD.Level9Id                  = MSL9.ID
            LEFT  JOIN dbo.ManagementStructureLevel                        MSL10 WITH (NOLOCK) ON MSD.Level10Id                = MSL10.ID
            WHERE CMB.IsDeleted                    = 0
              AND BD.IsDeleted                     = 0
              AND CMB.MasterCompanyId              = @MasterCompanyId
              AND ISNULL(CMB.IsVersionIncrease, 0) = 0
              AND BD.AccountingPeriodId IN
                  (
                      SELECT AccountcalID
                      FROM   #AccPeriodTable_All
                      WHERE  UPPER(PeriodName) = @PeriodName
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
        )
        ,AmountResult AS
        (
            SELECT
                GlAccountId,
                EntityStructureId,
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

        ---------------------------------------------------------------------------
        -- Shared: Populate #TempResults (YTD amounts) — common to both branches
        ---------------------------------------------------------------------------
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
                 THEN ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)
                 ELSE 0
            END AS YTDDebitAmount,
            CASE WHEN (ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)) > 0
                 THEN 0
                 ELSE ABS(ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0))
            END AS YTDCreditAmount,
            YTD.SequenceNumber
        FROM      #TEMP      YTD
        INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId     = GL.GLAccountId
                                                  AND YTD.MasterCompanyId = GL.MasterCompanyId;

        -- Update Monthly Credit Amount
        UPDATE #TempResults
        SET MonthlyCreditAmount = results.CreditAmount
        FROM
        (
            SELECT
                T1.GlAccountId,
                T1.EntityStructureId,
                CASE WHEN (SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0))) > 0
                     THEN 0
                     ELSE ABS(SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0)))
                END AS CreditAmount
            FROM  #TempResults T1
            JOIN  #Temptbl     T2 ON T1.GlAccountId      = T2.GlAccountId
                                  AND T1.EntityStructureId = T2.EntityStructureId
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
                T1.GlAccountId,
                T1.EntityStructureId,
                CASE WHEN (SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0))) > 0
                     THEN SUM(ISNULL(T2.DebitAmount, 0)) - SUM(ISNULL(T2.CreditAmount, 0))
                     ELSE 0
                END AS DebitAmount
            FROM  #TempResults T1
            JOIN  #Temptbl     T2 ON T1.GlAccountId       = T2.GlAccountId
                                  AND T1.EntityStructureId = T2.EntityStructureId
            GROUP BY T1.GlAccountId, T1.EntityStructureId
        ) results
        WHERE results.GlAccountId       = #TempResults.GlAccountId
          AND results.EntityStructureId = #TempResults.EntityStructureId;

        ---------------------------------------------------------------------------
        -- Final Output: Branch on @IsSupressZero
        ---------------------------------------------------------------------------
        IF (@IsSupressZero = 1)
        BEGIN
            -- Suppress Zero: only show accounts with monthly activity
            IF (@PeriodReportLayOutId = @ReportLayoutId)
            BEGIN
                SELECT
                    GlAccountId, EntityStructureId,
                    AccountNum, AccountName,
                    Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
                    Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
                    MonthlyCreditAmount AS Credit,
                    MonthlyDebitAmount  AS Debit,
                    YTDCreditAmount     AS CR,
                    YTDDebitAmount      AS DR,
					(ISNULL(MonthlyDebitAmount, 0) - ISNULL(MonthlyCreditAmount, 0)) AS Balance,
                    @TotalCreditAmount  AS TotalCreditAmount,
                    @TotalDebitAmount   AS TotalDebitAmount
                FROM #TempResults
                WHERE MonthlyCreditAmount > 0
                   OR MonthlyDebitAmount  > 0
                ORDER BY CAST(AccountNum AS BIGINT);
            END
            ELSE
            BEGIN
                SELECT
                    GlAccountId, EntityStructureId,
                    AccountNum, AccountName,
                    Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
                    Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
                    MonthlyCreditAmount AS Credit,
                    MonthlyDebitAmount  AS Debit,
                    YTDCreditAmount     AS CR,
                    YTDDebitAmount      AS DR,
					(ISNULL(MonthlyDebitAmount, 0) - ISNULL(MonthlyCreditAmount, 0)) AS Balance,
                    @TotalCreditAmount  AS TotalCreditAmount,
                    @TotalDebitAmount   AS TotalDebitAmount
                FROM #TempResults
                WHERE MonthlyCreditAmount > 0
                   OR MonthlyDebitAmount  > 0
                   OR YTDCreditAmount     > 0
                   OR YTDDebitAmount      > 0
                ORDER BY CAST(AccountNum AS BIGINT);
            END
        END
        ELSE
        BEGIN
            -- No suppression: include all GL accounts, assign MS structure if missing

            -- Insert GL accounts not yet in results
            INSERT INTO #TempResults (GlAccountId, MasterCompanyId, AccountNum, AccountName)
            SELECT
                GL.GlAccountId,
                GL.MasterCompanyId,
                GL.AccountCode,
                GL.AccountName
            FROM dbo.GLAccount GL
            WHERE GL.GlAccountId    NOT IN (SELECT GlAccountId FROM #TempResults)
              AND GL.MasterCompanyId = @masterCompanyId
              AND GL.IsActive        = 1
              AND GL.IsDeleted       = 0;

            -- Assign MS level names to any rows still missing them (set-based, replaces WHILE loop)
            UPDATE #TempResults
            SET
                Level1Name  = ESS.Level1Name,
                Level2Name  = ESS.Level2Name,
                Level3Name  = ESS.Level3Name,
                Level4Name  = ESS.Level4Name,
                Level5Name  = ESS.Level5Name,
                Level6Name  = ESS.Level6Name,
                Level7Name  = ESS.Level7Name,
                Level8Name  = ESS.Level8Name,
                Level9Name  = ESS.Level9Name,
                Level10Name = ESS.Level10Name
            FROM #tmpEntityStructureSetup ESS
            WHERE ESS.ID = (SELECT MIN(ID) FROM #tmpEntityStructureSetup)
              AND ISNULL(#TempResults.Level1Name, '') = '';

            SELECT
                GlAccountId, EntityStructureId,
                AccountNum, AccountName,
                Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
                Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
                MonthlyCreditAmount AS Credit,
                MonthlyDebitAmount  AS Debit,
                YTDCreditAmount     AS CR,
                YTDDebitAmount      AS DR,
				(ISNULL(MonthlyDebitAmount, 0) - ISNULL(MonthlyCreditAmount, 0)) AS Balance,
                @TotalCreditAmount  AS TotalCreditAmount,
                @TotalDebitAmount   AS TotalDebitAmount
            FROM #TempResults
            ORDER BY CAST(AccountNum AS BIGINT);
        END

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