/*************************************************************
 ** File:        [uspbatch_UpdateCustomerARAgingBalance]
 ** Author:      HEMANT SALIYA
 ** Description: Batch job procedure – computes AR aging buckets
 **              per customer per day and upserts into CustomerAging.
 **              Covers Work Order, Sales Order, and Exchange SO invoices.
 **              Designed to be run once daily via SQL Server Agent.
 ** Date:        04-20-2026
 **
 ** PARAMETERS:
 **   @MasterCompanyId  INT           – target company; NULL = all companies
 **   @UpdatedBy        VARCHAR(256)  – auditing identity (default 'System')
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** S NO  Date         Author          Change Description
 ** ---   ----------   -----------     --------------------------
 **  1    04-20-2026   HEMANT SALIYA   Created (Excuded CM/Stand Alone CM, MANUAL JOURNAL and SUSPENSE AND UNAPPLIED CASH)
 **
 ** EXEC uspbatch_UpdateCustomerARAgingBalance @MasterCompanyId = 21, @UpdatedBy = 'System'
 **************************************************************/
CREATE     PROCEDURE [dbo].[uspbatch_UpdateCustomerARAgingBalance]
    @MasterCompanyId INT          = NULL    
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        -- Always snapshot at today's UTC date so the job is idempotent:
        -- re-running on the same day overwrites (MERGE UPDATE) the existing row.
        DECLARE @AsOfDate      DATE         = CAST(GETUTCDATE() AS DATE);
        DECLARE @InvoiceStatus VARCHAR(20)  = 'Invoiced';
		DECLARE @UpdatedBy    VARCHAR(256) = 'System';

        DECLARE @workOrderModuleId  INT;
        DECLARE @salesOrderModuleId INT;
		DECLARE @CMPostedStatusId INT;

        SELECT @workOrderModuleId  = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'WorkOrder';
        SELECT @salesOrderModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'SalesOrder';
		SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';  

        -- ----------------------------------------------------------------
        -- Staging table: one row per invoice (not yet aggregated by customer)
        -- ----------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#ARAgingCalc') IS NOT NULL
            DROP TABLE #ARAgingCalc;

        CREATE TABLE #ARAgingCalc (
            [CustomerId]      BIGINT         NOT NULL,
            [MasterCompanyId] INT            NOT NULL,
            [CurrentAmount]   DECIMAL(18, 6) NOT NULL DEFAULT(0),  -- not yet due (DueDate >= today)
            [Days1_30]        DECIMAL(18, 6) NOT NULL DEFAULT(0),  -- 1–30 days past due
            [Days31_60]       DECIMAL(18, 6) NOT NULL DEFAULT(0),  -- 31–60 days past due
            [Days61_90]       DECIMAL(18, 6) NOT NULL DEFAULT(0),  -- 61–90 days past due
            [Days91_120]      DECIMAL(18, 6) NOT NULL DEFAULT(0),  -- 91–120 days past due
            [Days120Plus]     DECIMAL(18, 6) NOT NULL DEFAULT(0),  -- > 120 days past due
            [InvoiceCount]    INT            NOT NULL DEFAULT(0)
        );

        -- ================================================================
        -- 1. WORK ORDER INVOICES  (BillingInvoicing + WorkOrder)
        -- ================================================================
        -- Aging bucket logic (mirrors usprpt_GetARAgingAsOfNowReport):
        --   DueDateAdj = InvoiceDate + (COD/CIA/CreditCard/PREPAID → -1 day, else WO.NetDays)
        --   DueDateBase = InvoiceDate + WO.NetDays   (used for upper-bound of each bucket)
        --
        --   Current   : DATEDIFF(DueDateAdj,  today) <= 0
        --   1–30      : DATEDIFF(DueDateAdj,  today) > 0  AND DATEDIFF(DueDateBase, today) <= 30
        --   31–60     : DATEDIFF(DueDateAdj,  today) > 30 AND DATEDIFF(DueDateBase, today) <= 60
        --   61–90     : DATEDIFF(DueDateAdj,  today) > 60 AND DATEDIFF(DueDateBase, today) <= 90
        --   91–120    : DATEDIFF(DueDateAdj,  today) > 90 AND DATEDIFF(DueDateBase, today) <= 120
        --   120+      : DATEDIFF(DueDateAdj,  today) > 120

        INSERT INTO #ARAgingCalc
               ([CustomerId], [MasterCompanyId],
                [CurrentAmount], [Days1_30], [Days31_60], [Days61_90], [Days91_120], [Days120Plus],
                [InvoiceCount])
        SELECT
            WO.[CustomerId],
            WO.[MasterCompanyId],
            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(WO.[NetDays], 0) END AS DATE),
                    @AsOfDate) <= 0
                THEN BI.[RemainingAmount] ELSE 0 END)                                   AS [CurrentAmount],

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(WO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 0
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(WO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 30
                THEN BI.[RemainingAmount] ELSE 0 END)                                   AS [Days1_30],

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(WO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 30
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(WO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 60
                THEN BI.[RemainingAmount] ELSE 0 END)                                   AS [Days31_60],

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(WO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 60
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(WO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 90
                THEN BI.[RemainingAmount] ELSE 0 END)                                   AS [Days61_90],

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(WO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 90
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(WO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 120
                THEN BI.[RemainingAmount] ELSE 0 END)                                   AS [Days91_120],

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(WO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 120
                THEN BI.[RemainingAmount] ELSE 0 END)                                   AS [Days120Plus],

            COUNT(1)                                                                    AS [InvoiceCount]

        FROM [dbo].[BillingInvoicing]  BI  WITH(NOLOCK)
        INNER JOIN [dbo].[WorkOrder]   WO  WITH(NOLOCK) ON WO.[WorkOrderId]    = BI.[ReferenceId]
        LEFT  JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = WO.[CreditTermId]
        WHERE BI.[InvoiceStatus]               = @InvoiceStatus
          AND ISNULL(BI.[IsVersionIncrease], 0) = 0
          AND ISNULL(BI.[IsPerformaInvoice],  0) = 0
          AND ISNULL(BI.[RemainingAmount],     0) > 0
          AND CAST(BI.[InvoiceDate] AS DATE)   <= @AsOfDate
          AND BI.[ModuleId]                    = @workOrderModuleId
          AND (WO.[MasterCompanyId] = @MasterCompanyId OR @MasterCompanyId IS NULL)
        GROUP BY WO.[CustomerId], WO.[MasterCompanyId];

        -- ================================================================
        -- 2. SALES ORDER INVOICES  (BillingInvoicing + SalesOrder)
        -- ================================================================
        INSERT INTO #ARAgingCalc
               ([CustomerId], [MasterCompanyId],
                [CurrentAmount], [Days1_30], [Days31_60], [Days61_90], [Days91_120], [Days120Plus],
                [InvoiceCount])
        SELECT
            SO.[CustomerId],
            SO.[MasterCompanyId],
            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(SO.[NetDays], 0) END AS DATE),
                    @AsOfDate) <= 0
                THEN BI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(SO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 0
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(SO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 30
                THEN BI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(SO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 30
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(SO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 60
                THEN BI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(SO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 60
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(SO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 90
                THEN BI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(SO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 90
                 AND DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME) + ISNULL(SO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 120
                THEN BI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(BI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(SO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 120
                THEN BI.[RemainingAmount] ELSE 0 END),

            COUNT(1)

        FROM [dbo].[BillingInvoicing] BI  WITH(NOLOCK)
        INNER JOIN [dbo].[SalesOrder]  SO  WITH(NOLOCK) ON SO.[SalesOrderId]    = BI.[ReferenceId]
        LEFT  JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = SO.[CreditTermId]
        WHERE BI.[InvoiceStatus]               = @InvoiceStatus
          AND ISNULL(BI.[IsPerformaInvoice],  0) = 0
          AND ISNULL(BI.[RemainingAmount],     0) > 0
          AND CAST(BI.[InvoiceDate] AS DATE)   <= @AsOfDate
          AND BI.[ModuleId]                    = @salesOrderModuleId
          AND (SO.[MasterCompanyId] = @MasterCompanyId OR @MasterCompanyId IS NULL)
        GROUP BY SO.[CustomerId], SO.[MasterCompanyId];

        -- ================================================================
        -- 3. EXCHANGE SALES ORDER INVOICES  (ExchangeSalesOrderBillingInvoicing)
        -- ================================================================
        INSERT INTO #ARAgingCalc
               ([CustomerId], [MasterCompanyId],
                [CurrentAmount], [Days1_30], [Days31_60], [Days61_90], [Days91_120], [Days120Plus],
                [InvoiceCount])
        SELECT
            ESO.[CustomerId],
            ESO.[MasterCompanyId],
            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(ESO.[NetDays], 0) END AS DATE),
                    @AsOfDate) <= 0
                THEN ESOBI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(ESO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 0
                 AND DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 30
                THEN ESOBI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(ESO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 30
                 AND DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 60
                THEN ESOBI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(ESO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 60
                 AND DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 90
                THEN ESOBI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(ESO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 90
                 AND DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays], 0) AS DATE),
                    @AsOfDate) <= 120
                THEN ESOBI.[RemainingAmount] ELSE 0 END),

            SUM(CASE WHEN DATEDIFF(DAY,
                    CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME)
                         + CASE WHEN CTM.[Code] IN ('COD','CIA','CreditCard','PREPAID') THEN -1
                                ELSE ISNULL(ESO.[NetDays], 0) END AS DATE),
                    @AsOfDate) > 120
                THEN ESOBI.[RemainingAmount] ELSE 0 END),

            COUNT(1)

        FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH(NOLOCK)
        INNER JOIN [dbo].[ExchangeSalesOrder]           ESO   WITH(NOLOCK) ON ESO.[ExchangeSalesOrderId] = ESOBI.[ExchangeSalesOrderId]
        LEFT  JOIN [dbo].[CreditTerms]                  CTM   WITH(NOLOCK) ON CTM.[CreditTermsId]        = ESO.[CreditTermId]
        WHERE ESOBI.[InvoiceStatus]              = @InvoiceStatus
          AND ISNULL(ESOBI.[RemainingAmount], 0) > 0
          AND CAST(ESOBI.[InvoiceDate] AS DATE)  <= @AsOfDate
          AND (ESO.[MasterCompanyId] = @MasterCompanyId OR @MasterCompanyId IS NULL)
        GROUP BY ESO.[CustomerId], ESO.[MasterCompanyId];

		-- ================================================================
        -- 4. CREDIT MEMO  ()
        -- ================================================================

		INSERT INTO #ARAgingCalc
               ([CustomerId], [MasterCompanyId],
                [CurrentAmount], [Days1_30], [Days31_60], [Days61_90], [Days91_120], [Days120Plus],
                [InvoiceCount])
		SELECT CM.CustomerId, CM.[MasterCompanyId], SUM(CMD.[Amount]), 0, 0, 0, 0, 0, SUM(CMD.[Amount])
		FROM [dbo].[CreditMemo] CM WITH (NOLOCK)  
			INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.IsDeleted = 0  AND CMD.IsDeleted = 0  
		WHERE CM.StatusId = @CMPostedStatusId
			AND CAST(CM.[InvoiceDate] AS DATE)  <= @AsOfDate
			AND (CM.[MasterCompanyId] = @MasterCompanyId OR @MasterCompanyId IS NULL)
		GROUP BY CM.[CustomerId], CM.[MasterCompanyId];

		-- ================================================================
        -- 5. STAND ALONE CREDIT MEMO  ()
        -- ================================================================

		INSERT INTO #ARAgingCalc
               ([CustomerId], [MasterCompanyId],
                [CurrentAmount], [Days1_30], [Days31_60], [Days61_90], [Days91_120], [Days120Plus],
                [InvoiceCount])
		SELECT CM.CustomerId, CM.[MasterCompanyId], SUM(CMD.[Amount]), 0, 0, 0, 0, 0, SUM(CMD.[Amount])
		FROM [dbo].[CreditMemo] CM WITH (NOLOCK)  
			INNER JOIN [dbo].[StandAloneCreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.IsDeleted = 0  AND CMD.IsDeleted = 0  
		WHERE CM.StatusId = @CMPostedStatusId
			AND CAST(CM.[InvoiceDate] AS DATE)  <= @AsOfDate
			AND (CM.[MasterCompanyId] = @MasterCompanyId OR @MasterCompanyId IS NULL)
		GROUP BY CM.[CustomerId], CM.[MasterCompanyId];


        -- ================================================================
        -- 6. MERGE aggregated aging into CustomerAging
        --    One row per (CustomerId, MasterCompanyId, AsOfDate).
        --    Re-running on the same day performs UPDATE (idempotent).
        -- ================================================================
        MERGE [dbo].[CustomerAging] AS TGT
        USING (
            SELECT
                agg.[CustomerId],
                agg.[MasterCompanyId],
                UPPER(ISNULL(C.[Name],         ''))  AS [CustomerName],
                UPPER(ISNULL(C.[CustomerCode], ''))  AS [CustomerCode],
                CF.[CreditTermsId],
                CT.[Name]                            AS [CreditTermName],
                CAST(CT.[NetDays] AS TINYINT)        AS [NetDays],
                CF.[CreditLimit],
                SUM(agg.[InvoiceCount])              AS [TotalInvoices],
                SUM(agg.[CurrentAmount]
                  + agg.[Days1_30]
                  + agg.[Days31_60]
                  + agg.[Days61_90]
                  + agg.[Days91_120]
                  + agg.[Days120Plus])               AS [TotalOutstanding],
                SUM(agg.[CurrentAmount])             AS [CurrentAmount],
                SUM(agg.[Days1_30])                  AS [Days1_30],
                SUM(agg.[Days31_60])                 AS [Days31_60],
                SUM(agg.[Days61_90])                 AS [Days61_90],
                SUM(agg.[Days91_120])                AS [Days91_120],
                SUM(agg.[Days120Plus])               AS [Days120Plus]
            FROM #ARAgingCalc agg
            INNER JOIN [dbo].[Customer]         C   WITH(NOLOCK) ON C.[CustomerId]    = agg.[CustomerId]
            LEFT  JOIN [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.[CustomerId]   = agg.[CustomerId]
            LEFT  JOIN [dbo].[CreditTerms]       CT WITH(NOLOCK) ON CT.[CreditTermsId] = CF.[CreditTermsId]
            GROUP BY
                agg.[CustomerId],
                agg.[MasterCompanyId],
                C.[Name],
                C.[CustomerCode],
                CF.[CreditTermsId],
                CT.[Name],
                CT.[NetDays],
                CF.[CreditLimit]
        ) AS SRC
        ON  TGT.[CustomerId]      = SRC.[CustomerId]
        AND TGT.[MasterCompanyId] = SRC.[MasterCompanyId]
        AND TGT.[AsOfDate]        = @AsOfDate

        WHEN MATCHED THEN
            UPDATE SET
                TGT.[CustomerName]     = SRC.[CustomerName],
                TGT.[CustomerCode]     = SRC.[CustomerCode],
                TGT.[CreditTermsId]    = SRC.[CreditTermsId],
                TGT.[CreditTermName]   = SRC.[CreditTermName],
                TGT.[NetDays]          = SRC.[NetDays],
                TGT.[CreditLimit]      = SRC.[CreditLimit],
                TGT.[TotalInvoices]    = SRC.[TotalInvoices],
                TGT.[TotalOutstanding] = SRC.[TotalOutstanding],
                TGT.[CurrentAmount]    = SRC.[CurrentAmount],
                TGT.[Days1_30]         = SRC.[Days1_30],
                TGT.[Days31_60]        = SRC.[Days31_60],
                TGT.[Days61_90]        = SRC.[Days61_90],
                TGT.[Days91_120]       = SRC.[Days91_120],
                TGT.[Days120Plus]      = SRC.[Days120Plus],
                TGT.[UpdatedDate]      = GETDATE(),
                TGT.[UpdatedBy]        = @UpdatedBy,
                TGT.[IsActive]         = 1,
                TGT.[IsDeleted]        = 0

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                [CustomerId],    [CustomerName],    [CustomerCode],
                [CreditTermsId], [CreditTermName],  [NetDays],      [CreditLimit],
                [AsOfDate],
                [TotalInvoices], [TotalOutstanding],
                [CurrentAmount], [Days1_30], [Days31_60], [Days61_90], [Days91_120], [Days120Plus],
                [MasterCompanyId],
                [CreatedBy],     [UpdatedBy],
                [CreatedDate],   [UpdatedDate],
                [IsActive],      [IsDeleted]
            )
            VALUES (
                SRC.[CustomerId],    SRC.[CustomerName],    SRC.[CustomerCode],
                SRC.[CreditTermsId], SRC.[CreditTermName],  SRC.[NetDays],      SRC.[CreditLimit],
                @AsOfDate,
                SRC.[TotalInvoices], SRC.[TotalOutstanding],
                SRC.[CurrentAmount], SRC.[Days1_30], SRC.[Days31_60], SRC.[Days61_90], SRC.[Days91_120], SRC.[Days120Plus],
                SRC.[MasterCompanyId],
                @UpdatedBy, @UpdatedBy,
                GETDATE(),  GETDATE(),
                1,          0
            );

    END TRY

    BEGIN CATCH

        DECLARE @ErrorLogID           INT,
                @DatabaseName         VARCHAR(100) = DB_NAME(),
                @AdhocComments        VARCHAR(150) = '[uspbatch_UpdateCustomerARAgingBalance]',
                @ProcedureParameters  VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20)) + '''',
                @ApplicationName      VARCHAR(100) = 'PAS';

        EXEC [dbo].[Splogexception]
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);

    END CATCH

END