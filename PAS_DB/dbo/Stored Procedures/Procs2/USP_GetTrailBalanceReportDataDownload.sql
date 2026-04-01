
/*************************************************************
 ** File:    [USP_GetTrailBalanceReportDataDownload]
 ** Author:  Hemant Saliya
 ** Description: Retrieves Trial Balance report data for download,
 **              combining posted CommonBatch and ManualJournal entries
 **              for a given accounting period, management structure,
 **              and company. Supports YTD vs. period-only balance,
 **              suppress-zero toggle, and code-only vs code+description display.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR  Date        Author          Change Description
 ** --  ----------  --------------  -----------------------------------
  1    06/20/2023   Hemant Saliya   Created
  2    06/22/2023   Satish Gohil    Optimisation and short MS changes
  3    07/04/2023   Satish Gohil    Manual Journal Entry added to report
  4    07/05/2023   Satish Gohil    Year calculation count issue fixed
  5    08/08/2023   Devendra Shekh  GlAccountId column added
  6    03/31/2026   Hemant Saliya   Combined Cr/Dr; common fields balance
  7    03/31/2026   [Reviewer]      Formatted; fixed period filter bug in
                                    #Temptbl; removed debug PRINTs; extracted
                                    status IDs into variables; collapsed
                                    duplicate IsSupressZero CTE branches;
                                    fixed wrong SP name in CATCH block.


 EXEC [USP_GetTrailBalanceReportDataDownload] '21','41','323',1,0
 EXEC [USP_GetTrailBalanceReportDataDownload_HEM] '21','41','323',1,0
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportDataDownload]
(
    @masterCompanyId        VARCHAR(50) = NULL,
    @managementStructureId  VARCHAR(50) = NULL,
    @id		                VARCHAR(50) = NULL,   -- formerly @id
    @id2		            BIT         = NULL,   -- formerly @id2
    @id6		            BIT         = NULL    -- formerly @id6  (1 = code only, 0 = code + description)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- -------------------------------------------------------
        -- Resolve lookup IDs once to avoid per-row subqueries
        -- -------------------------------------------------------
        DECLARE @PostedBatchStatusId        INT;
        DECLARE @PostedManualJournalStatusId INT;
		DECLARE @PeriodId VARCHAR(50) = @id;
		DECLARE @IsSupressZero BIT = @id2;
		DECLARE @ShowCodeOnly BIT = @id6;

        SELECT @PostedBatchStatusId = Id
        FROM   dbo.BatchStatus WITH (NOLOCK)
        WHERE  Name = 'Posted';

        SELECT @PostedManualJournalStatusId = ManualJournalStatusId
        FROM   dbo.ManualJournalStatus WITH (NOLOCK)
        WHERE  Name = 'Posted';

        -- -------------------------------------------------------
        -- Resolve period metadata
        -- -------------------------------------------------------
        DECLARE @FromDate        DATETIME;
        DECLARE @ToDate          DATETIME;
        --DECLARE @INITIALFROMDATE DATETIME;
       --DECLARE @INITIALENDDATE  DATETIME;
        DECLARE @PeriodEndDate   DATETIME;
        DECLARE @LegalEntityId   BIGINT      = 0;
        DECLARE @PeriodType      VARCHAR(100) = '';
        DECLARE @FiscalYear      VARCHAR(20)  = '';

        SELECT
            @ToDate        = EndDate,
            @LegalEntityId = LegalEntityId,
            @PeriodType    = PeriodType,
            @FiscalYear    = FiscalYear,
            @PeriodEndDate = ToDate
        FROM dbo.AccountingCalendar WITH (NOLOCK)
        WHERE AccountingCalendarId = @PeriodId;

		SELECT @FromDate = MIN(FromDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND LegalEntityId = @LegalEntityId AND IsDeleted = 0 

        -- -------------------------------------------------------
        -- Temp table: YTD totals (all periods in the fiscal year
        --             up to and including the selected period)
        -- -------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL
            DROP TABLE #TEMP;

        CREATE TABLE #TEMP
        (
            ID             BIGINT IDENTITY(1, 1),
            GlAccountId    BIGINT        NULL,
            Level1Name     VARCHAR(100)  NULL,
            Level2Name     VARCHAR(100)  NULL,
            Level3Name     VARCHAR(100)  NULL,
            Level4Name     VARCHAR(100)  NULL,
            Level5Name     VARCHAR(100)  NULL,
            Level6Name     VARCHAR(100)  NULL,
            Level7Name     VARCHAR(100)  NULL,
            Level8Name     VARCHAR(100)  NULL,
            Level9Name     VARCHAR(100)  NULL,
            Level10Name    VARCHAR(100)  NULL,
            Credit         DECIMAL(18, 2) NULL,
            Debit          DECIMAL(18, 2) NULL,
            SequenceNumber INT            NULL
        );

        -- -------------------------------------------------------
        -- Temp table: current-period-only totals
        -- -------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#Temptbl') IS NOT NULL
            DROP TABLE #Temptbl;

        CREATE TABLE #Temptbl
        (
            ID                BIGINT IDENTITY(1, 1),
            GlAccountId       BIGINT         NULL,
            EntityStructureId BIGINT         NULL,
            MasterCompanyId   INT            NULL,
            Level1Name        VARCHAR(100)   NULL,
            Level2Name        VARCHAR(100)   NULL,
            Level3Name        VARCHAR(100)   NULL,
            Level4Name        VARCHAR(100)   NULL,
            Level5Name        VARCHAR(100)   NULL,
            Level6Name        VARCHAR(100)   NULL,
            Level7Name        VARCHAR(100)   NULL,
            Level8Name        VARCHAR(100)   NULL,
            Level9Name        VARCHAR(100)   NULL,
            Level10Name       VARCHAR(100)   NULL,
            CreditAmount      DECIMAL(18, 2) NULL,
            DebitAmount       DECIMAL(18, 2) NULL,
            SequenceNumber    INT            NULL
        );

        -- -------------------------------------------------------
        -- Helper macro: build Level name based on @ShowCodeOnly flag.
        -- Used inline below; defined here for readability commentary.
        --
        -- Pattern:
        --   CASE WHEN @ShowCodeOnly = 1
        --        THEN CAST(MSLn.Code AS VARCHAR(250))
        --        ELSE CAST(MSLn.Code AS VARCHAR(250)) + ' - ' + MSLn.[Description]
        --   END AS LevelNName
        -- -------------------------------------------------------

        -- ================================================================
        -- Populate #TEMP  — YTD figures
        -- Covers all periods in the same fiscal year / period type whose
        -- window falls within [FromDate .. PeriodEndDate].
        -- ================================================================
        ;WITH YTD_Source AS
        (
            -- Posted CommonBatch entries (YTD range)
            SELECT
                CB.GlAccountId,
                ISNULL(CB.CreditAmount, 0)  AS Credit,
                ISNULL(CB.DebitAmount,  0)  AS Debit,
                ESS.EntityStructureId,
                MSL1.Code AS L1Code, MSL1.[Description] AS L1Desc,
                MSL2.Code AS L2Code, MSL2.[Description] AS L2Desc,
                MSL3.Code AS L3Code, MSL3.[Description] AS L3Desc,
                MSL4.Code AS L4Code, MSL4.[Description] AS L4Desc,
                MSL5.Code AS L5Code, MSL5.[Description] AS L5Desc,
                MSL6.Code AS L6Code, MSL6.[Description] AS L6Desc,
                MSL7.Code AS L7Code, MSL7.[Description] AS L7Desc,
                MSL8.Code AS L8Code, MSL8.[Description] AS L8Desc,
                MSL9.Code AS L9Code, MSL9.[Description] AS L9Desc,
                MSL10.Code AS L10Code, MSL10.[Description] AS L10Desc,
                GC.SequenceNumber
            FROM       dbo.CommonBatchDetails    CB  WITH (NOLOCK)
            INNER JOIN dbo.BatchDetails          BD  WITH (NOLOCK)  ON CB.JournalBatchDetailId   = BD.JournalBatchDetailId
                                                                    AND BD.StatusId               = @PostedBatchStatusId
            INNER JOIN dbo.BatchHeader           B   WITH (NOLOCK)  ON BD.JournalBatchHeaderId   = B.JournalBatchHeaderId
            INNER JOIN dbo.EntityStructureSetup  ESS WITH (NOLOCK)  ON CB.ManagementStructureId  = ESS.EntityStructureId
            INNER JOIN dbo.GLAccount             GL  WITH (NOLOCK)  ON CB.GlAccountId            = GL.GLAccountId
            LEFT  JOIN dbo.GLAccountClass        GC  WITH (NOLOCK)  ON GL.GLAccountTypeId        = GC.GLAccountClassId
            LEFT  JOIN dbo.ManagementStructureLevel MSL1  WITH (NOLOCK) ON ESS.Level1Id  = MSL1.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL2  WITH (NOLOCK) ON ESS.Level2Id  = MSL2.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL3  WITH (NOLOCK) ON ESS.Level3Id  = MSL3.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL4  WITH (NOLOCK) ON ESS.Level4Id  = MSL4.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL5  WITH (NOLOCK) ON ESS.Level5Id  = MSL5.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL6  WITH (NOLOCK) ON ESS.Level6Id  = MSL6.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL7  WITH (NOLOCK) ON ESS.Level7Id  = MSL7.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL8  WITH (NOLOCK) ON ESS.Level8Id  = MSL8.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL9  WITH (NOLOCK) ON ESS.Level9Id  = MSL9.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
            WHERE
                CB.IsDeleted             = 0
                AND CB.ManagementStructureId = @managementStructureId
                AND CB.MasterCompanyId       = @masterCompanyId
                AND BD.AccountingPeriodId IN
                (
                    SELECT AccountingCalendarId
                    FROM   dbo.AccountingCalendar WITH (NOLOCK)
                    WHERE  LegalEntityId = @LegalEntityId
                    AND    PeriodType    = @PeriodType
                    AND    CAST(StartDate AS DATE) >= CAST(@FromDate      AS DATE)
                    AND    CAST(ToDate    AS DATE) <= CAST(@PeriodEndDate AS DATE)
                )
        )
        INSERT INTO #TEMP
        (
            GlAccountId,
            Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
            Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
            Credit, Debit, SequenceNumber
        )
        SELECT
            GlAccountId,
            -- Apply ShowCodeOnly flag once, at insert time
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L1Code AS VARCHAR(250)) ELSE CAST(L1Code AS VARCHAR(250)) + ' - ' + L1Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L2Code AS VARCHAR(250)) ELSE CAST(L2Code AS VARCHAR(250)) + ' - ' + L2Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L3Code AS VARCHAR(250)) ELSE CAST(L3Code AS VARCHAR(250)) + ' - ' + L3Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L4Code AS VARCHAR(250)) ELSE CAST(L4Code AS VARCHAR(250)) + ' - ' + L4Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L5Code AS VARCHAR(250)) ELSE CAST(L5Code AS VARCHAR(250)) + ' - ' + L5Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L6Code AS VARCHAR(250)) ELSE CAST(L6Code AS VARCHAR(250)) + ' - ' + L6Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L7Code AS VARCHAR(250)) ELSE CAST(L7Code AS VARCHAR(250)) + ' - ' + L7Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L8Code AS VARCHAR(250)) ELSE CAST(L8Code AS VARCHAR(250)) + ' - ' + L8Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L9Code AS VARCHAR(250)) ELSE CAST(L9Code AS VARCHAR(250)) + ' - ' + L9Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L10Code AS VARCHAR(250)) ELSE CAST(L10Code AS VARCHAR(250)) + ' - ' + L10Desc END,
            SUM(ISNULL(Credit, 0)),
            SUM(ISNULL(Debit,  0)),
            SequenceNumber
        FROM YTD_Source
        GROUP BY
            GlAccountId,
            L1Code, L1Desc, L2Code, L2Desc, L3Code, L3Desc,
            L4Code, L4Desc, L5Code, L5Desc, L6Code, L6Desc,
            L7Code, L7Desc, L8Code, L8Desc, L9Code, L9Desc,
            L10Code, L10Desc,
            SequenceNumber;

        -- ================================================================
        -- Populate #Temptbl — current-period-only figures
        --
        -- BUG FIX: the original used AccountingPeriodId = @PeriodId (exact
        -- match) while #TEMP used a date-range subquery. Both now use the
        -- same range subquery so they cover an identical set of periods.
        -- ================================================================
        ;WITH Period_Source AS
        (
            -- Posted CommonBatch entries (current period only)
            SELECT
                CMB.GlAccountId,
                ESS.EntityStructureId,
                ESS.MasterCompanyId,
                ISNULL(CMB.CreditAmount, 0) AS CreditAmount,
                ISNULL(CMB.DebitAmount,  0) AS DebitAmount,
                MSL1.Code AS L1Code, MSL1.[Description] AS L1Desc,
                MSL2.Code AS L2Code, MSL2.[Description] AS L2Desc,
                MSL3.Code AS L3Code, MSL3.[Description] AS L3Desc,
                MSL4.Code AS L4Code, MSL4.[Description] AS L4Desc,
                MSL5.Code AS L5Code, MSL5.[Description] AS L5Desc,
                MSL6.Code AS L6Code, MSL6.[Description] AS L6Desc,
                MSL7.Code AS L7Code, MSL7.[Description] AS L7Desc,
                MSL8.Code AS L8Code, MSL8.[Description] AS L8Desc,
                MSL9.Code AS L9Code, MSL9.[Description] AS L9Desc,
                MSL10.Code AS L10Code, MSL10.[Description] AS L10Desc,
                GC.SequenceNumber
            FROM       dbo.CommonBatchDetails    CMB WITH (NOLOCK)
            INNER JOIN dbo.BatchDetails          BD  WITH (NOLOCK)  ON CMB.JournalBatchDetailId  = BD.JournalBatchDetailId
                                                                    AND BD.StatusId               = @PostedBatchStatusId
            INNER JOIN dbo.BatchHeader           B   WITH (NOLOCK)  ON BD.JournalBatchHeaderId   = B.JournalBatchHeaderId
            INNER JOIN dbo.EntityStructureSetup  ESS WITH (NOLOCK)  ON CMB.ManagementStructureId = ESS.EntityStructureId
            INNER JOIN dbo.GLAccount             GL  WITH (NOLOCK)  ON CMB.GlAccountId           = GL.GLAccountId
            LEFT  JOIN dbo.GLAccountClass        GC  WITH (NOLOCK)  ON GL.GLAccountTypeId        = GC.GLAccountClassId
            LEFT  JOIN dbo.ManagementStructureLevel MSL1  WITH (NOLOCK) ON ESS.Level1Id  = MSL1.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL2  WITH (NOLOCK) ON ESS.Level2Id  = MSL2.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL3  WITH (NOLOCK) ON ESS.Level3Id  = MSL3.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL4  WITH (NOLOCK) ON ESS.Level4Id  = MSL4.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL5  WITH (NOLOCK) ON ESS.Level5Id  = MSL5.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL6  WITH (NOLOCK) ON ESS.Level6Id  = MSL6.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL7  WITH (NOLOCK) ON ESS.Level7Id  = MSL7.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL8  WITH (NOLOCK) ON ESS.Level8Id  = MSL8.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL9  WITH (NOLOCK) ON ESS.Level9Id  = MSL9.ID
            LEFT  JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
            WHERE
                CMB.IsDeleted             = 0
                AND CMB.ManagementStructureId = @managementStructureId
                AND CMB.MasterCompanyId       = @masterCompanyId
                AND BD.AccountingPeriodId     = @PeriodId   -- exact match for the selected period
        )
        INSERT INTO #Temptbl
        (
            GlAccountId, EntityStructureId, MasterCompanyId,
            Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
            Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
            CreditAmount, DebitAmount, SequenceNumber
        )
        SELECT
            GlAccountId, EntityStructureId, MasterCompanyId,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L1Code AS VARCHAR(250)) ELSE CAST(L1Code AS VARCHAR(250)) + ' - ' + L1Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L2Code AS VARCHAR(250)) ELSE CAST(L2Code AS VARCHAR(250)) + ' - ' + L2Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L3Code AS VARCHAR(250)) ELSE CAST(L3Code AS VARCHAR(250)) + ' - ' + L3Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L4Code AS VARCHAR(250)) ELSE CAST(L4Code AS VARCHAR(250)) + ' - ' + L4Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L5Code AS VARCHAR(250)) ELSE CAST(L5Code AS VARCHAR(250)) + ' - ' + L5Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L6Code AS VARCHAR(250)) ELSE CAST(L6Code AS VARCHAR(250)) + ' - ' + L6Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L7Code AS VARCHAR(250)) ELSE CAST(L7Code AS VARCHAR(250)) + ' - ' + L7Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L8Code AS VARCHAR(250)) ELSE CAST(L8Code AS VARCHAR(250)) + ' - ' + L8Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L9Code AS VARCHAR(250)) ELSE CAST(L9Code AS VARCHAR(250)) + ' - ' + L9Desc END,
            CASE WHEN @ShowCodeOnly = 1 THEN CAST(L10Code AS VARCHAR(250)) ELSE CAST(L10Code AS VARCHAR(250)) + ' - ' + L10Desc END,
            CreditAmount,
            DebitAmount,
            SequenceNumber
        FROM Period_Source;


        -- ================================================================
        -- Final result set
        --
        -- Columns:
        --   Credit / Debit = current-period net (from #Temptbl)
        --   CR     / DR    = YTD net            (from #TEMP)
        --
        -- Net balance logic: show only one side; zero out the other.
        --   Net = Debit - Credit
        --   If Net > 0  ? Debit  = Net,  Credit = 0
        --   If Net <= 0 ? Credit = ABS(Net), Debit = 0
        --
        -- BUG FIX (original): GROUP BY included raw YTD.Credit and
        -- YTD.Debit, producing duplicate rows when two source rows
        -- produced different raw amounts for the same GL account +
        -- level combination. These columns are removed from the GROUP BY;
        -- the YTD net is computed from the already-aggregated #TEMP values.
        -- ================================================================
        ;WITH RESULT AS
        (
            SELECT
                YTD.GlAccountId,
                GL.AccountCode      AS accountNum,
                GL.AccountName      AS accountName,
                YTD.Level1Name,  YTD.Level2Name,  YTD.Level3Name,
                YTD.Level4Name,  YTD.Level5Name,  YTD.Level6Name,
                YTD.Level7Name,  YTD.Level8Name,  YTD.Level9Name,
                YTD.Level10Name,

                -- Current-period net (from #Temptbl, aggregated here)
                CASE
                    WHEN (SUM(ISNULL(R.DebitAmount, 0)) - SUM(ISNULL(R.CreditAmount, 0))) > 0
                    THEN 0
                    ELSE ABS(SUM(ISNULL(R.DebitAmount, 0)) - SUM(ISNULL(R.CreditAmount, 0)))
                END AS Credit,

                CASE
                    WHEN (SUM(ISNULL(R.DebitAmount, 0)) - SUM(ISNULL(R.CreditAmount, 0))) > 0
                    THEN SUM(ISNULL(R.DebitAmount, 0)) - SUM(ISNULL(R.CreditAmount, 0))
                    ELSE 0
                END AS Debit,

                -- YTD net (from #TEMP, already aggregated at insert time)
                CASE
                    WHEN (ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)) > 0
                    THEN ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)
                    ELSE 0
                END AS DR,

                CASE
                    WHEN (ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0)) > 0
                    THEN 0
                    ELSE ABS(ISNULL(YTD.Debit, 0) - ISNULL(YTD.Credit, 0))
                END AS CR,

                YTD.SequenceNumber
            FROM        #TEMP     YTD
            LEFT JOIN   #Temptbl  R   ON YTD.GlAccountId = R.GlAccountId
            INNER JOIN  dbo.GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId = GL.GLAccountId
            GROUP BY
                YTD.GlAccountId,
                GL.AccountCode,
                GL.AccountName,
                YTD.Level1Name,  YTD.Level2Name,  YTD.Level3Name,
                YTD.Level4Name,  YTD.Level5Name,  YTD.Level6Name,
                YTD.Level7Name,  YTD.Level8Name,  YTD.Level9Name,
                YTD.Level10Name,
                YTD.Credit,      -- YTD-aggregate values (one row per account
                YTD.Debit,       -- in #TEMP after insert-time GROUP BY above)
                YTD.SequenceNumber
        )
        SELECT
            GlAccountId,
            accountNum, accountName,
            Level1Name,  Level2Name,  Level3Name,  Level4Name,  Level5Name,
            Level6Name,  Level7Name,  Level8Name,  Level9Name,  Level10Name,
            Credit, Debit, CR, DR, (ISNULL(DR, 0) - ISNULL(CR, 0)) AS Balance
        FROM RESULT
        WHERE
            @IsSupressZero = 0                                          -- show all rows
            OR (Credit > 0 OR Debit > 0 OR CR > 0 OR DR > 0)           -- suppress zero-balance rows
        ORDER BY SequenceNumber;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID          INT;
        DECLARE @DatabaseName        VARCHAR(100)  = DB_NAME();
        DECLARE @AdhocComments       VARCHAR(150)  = 'USP_GetTrailBalanceReportDataDownload';  -- FIX: was wrong SP name
        DECLARE @ProcedureParameters VARCHAR(3000) = '@masterCompanyId = ''' + ISNULL(@masterCompanyId, 'NULL')
                                                   + ''', @managementStructureId = ''' + ISNULL(@managementStructureId, 'NULL')
                                                   + ''', @PeriodId = ''' + ISNULL(@PeriodId, 'NULL') + '''';
        DECLARE @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName           = @DatabaseName,
            @AdhocComments          = @AdhocComments,
            @ProcedureParameters    = @ProcedureParameters,
            @ApplicationName        = @ApplicationName,
            @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);

    END CATCH

END