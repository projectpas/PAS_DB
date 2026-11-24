/*************************************************************
 ** File:        [usp_PopulateCustomerAging]
 ** Author:      Claude
 ** Description: Reads outstanding invoices from BillingInvoicing,
 **              calculates each invoice's due date using the
 **              customer's credit terms (NetDays), and
 **              inserts/updates aggregated aging buckets into
 **              the CustomerAging table.
 **
 ** Due Date Logic:
 **   - COD / PREPAID  →  DueDate = InvoiceDate  (due immediately)
 **   - All others     →  DueDate = InvoiceDate + NetDays
 **
 ** Aging Buckets (based on DaysOverdue = AsOfDate - DueDate):
 **   Current   : DaysOverdue <= 0   (not yet due)
 **   1-30      : DaysOverdue  1 – 30
 **   31-60     : DaysOverdue 31 – 60
 **   61-90     : DaysOverdue 61 – 90
 **   91-120    : DaysOverdue 91 – 120
 **   120+      : DaysOverdue > 120
 **
 ** PARAMETERS:
 **   @MasterCompanyId  INT            Required. Company scope.
 **   @AsOfDate         DATE           Optional. Defaults to today (UTC).
 **   @CustomerId       BIGINT         Optional. Limits run to one customer.
 **   @CreatedBy        VARCHAR(256)   Optional. Audit user. Defaults to 'System'.
 **
 **************************************************************
 ** Change History
 **------------------------------------------------------------
 ** #   Date          Author    Description
 ** 1   2026-04-16    Claude    Created
 EXEC usp_PopulateCustomerAging 1,NULL,92
 *************************************************************/
CREATE   PROCEDURE [dbo].[usp_PopulateCustomerAging]
    @MasterCompanyId  INT,
    @AsOfDate         DATE         = NULL,
    @CustomerId       BIGINT       = NULL,
    @CreatedBy        VARCHAR(256) = 'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- Default to today (UTC) when no snapshot date is supplied
    IF @AsOfDate IS NULL
        SET @AsOfDate = CAST(GETUTCDATE() AS DATE);

	DECLARE @InvoiceStatus VARCHAR(20)='INVOICED'
	DECLARE @workOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WORKORDER')

    BEGIN TRY

        -- ----------------------------------------------------------------
        -- STEP 1 – Compute per-invoice due date and days overdue
        -- ----------------------------------------------------------------
        ;WITH InvoiceAging AS
        (
            SELECT
                bi.BillingInvoicingId,
                bi.CustomerId,
                bi.InvoiceNo,
                bi.InvoiceDate,
                bi.RemainingAmount,
                bi.MasterCompanyId,
                WO.CreditTermId as CreditTermsId,
                WO.CreditLimit,
                ct.[Name]    AS CreditTermName,
                ct.NetDays,
                ct.Code      AS CreditTermCode,

                -- Due date: COD/PREPAID are due on the invoice date itself
                CASE
                    WHEN ct.Code IN ('COD', 'PREPAID','COD', 'CREDITCARD')
                        THEN CAST(bi.InvoiceDate AS DATE)
                    ELSE
                        CAST(DATEADD(DAY, ISNULL(wo.NetDays, 0), CAST(bi.InvoiceDate AS DATE)) AS DATE)
                END AS DueDate,

                -- Days overdue: positive = overdue, negative/zero = still current
                CASE
                    WHEN ct.Code IN ('COD', 'PREPAID','COD', 'CREDITCARD')
                        THEN DATEDIFF(DAY, CAST(bi.InvoiceDate AS DATE), @AsOfDate)
                    ELSE
                        DATEDIFF(DAY,
                            CAST(DATEADD(DAY, ISNULL(wo.NetDays, 0), CAST(bi.InvoiceDate AS DATE)) AS DATE),
                            @AsOfDate)
                END AS DaysOverdue

            FROM  [dbo].[BillingInvoicing]   bi  WITH (NOLOCK)
			JOIN  [dbo].[WorkOrder] wo WITH (NOLOCK) ON wo.WorkOrderId = bi.ReferenceId      
			JOIN  [dbo].[Customer] c  WITH (NOLOCK) ON c.CustomerId = WO.CustomerId
			JOIN  [dbo].[CreditTerms] ct WITH(NOLOCK) ON ct.CreditTermsId = WO.CreditTermId 

            WHERE ISNULL(bi.IsActive,0)          = 1
              AND ISNULL(bi.IsDeleted,0)         = 0
              AND ISNULL(bi.IsPerformaInvoice,0) = 0           -- exclude proforma / draft invoices
              AND ISNULL(bi.RemainingAmount,0)   > 0            -- skip fully paid invoices
			  AND ISNULL(bi.[IsVersionIncrease],0) = 0
              AND bi.MasterCompanyId   = @MasterCompanyId
			  AND bi.[InvoiceStatus] = @InvoiceStatus
			  AND bi.ModuleId = @workOrderModuleId
              AND CAST(bi.InvoiceDate AS DATE) <= @AsOfDate   -- only invoices raised on/before snapshot date
              AND (@CustomerId IS NULL OR bi.CustomerId = @CustomerId)
        ),

        -- ----------------------------------------------------------------
        -- STEP 2 – Aggregate into aging buckets per customer
        -- ----------------------------------------------------------------
        CustomerAgingData AS
        (
            SELECT
                ia.CustomerId,
                --ia.CreditTermsId,
                --ia.CreditTermName,
                --ia.NetDays,
                --ia.CreditLimit,
                ia.MasterCompanyId,
                COUNT(ia.BillingInvoicingId)                                              AS TotalInvoices,
                SUM(ia.RemainingAmount)                                                   AS TotalOutstanding,

                SUM(CASE WHEN ia.DaysOverdue <= 0                        THEN ia.RemainingAmount ELSE 0 END) AS CurrentAmount,
                SUM(CASE WHEN ia.DaysOverdue BETWEEN  1 AND  30          THEN ia.RemainingAmount ELSE 0 END) AS Days1_30,
                SUM(CASE WHEN ia.DaysOverdue BETWEEN 31 AND  60          THEN ia.RemainingAmount ELSE 0 END) AS Days31_60,
                SUM(CASE WHEN ia.DaysOverdue BETWEEN 61 AND  90          THEN ia.RemainingAmount ELSE 0 END) AS Days61_90,
                SUM(CASE WHEN ia.DaysOverdue BETWEEN 91 AND 120          THEN ia.RemainingAmount ELSE 0 END) AS Days91_120,
                SUM(CASE WHEN ia.DaysOverdue  > 120                      THEN ia.RemainingAmount ELSE 0 END) AS Days120Plus
            FROM InvoiceAging ia
            GROUP BY
                ia.CustomerId,
                --ia.CreditTermsId,
                --ia.CreditTermName,
                --ia.NetDays,
                --ia.CreditLimit,
                ia.MasterCompanyId
        )

		Select * from CustomerAgingData

        -- ----------------------------------------------------------------
        -- STEP 3 – UPSERT into CustomerAging
        --          Key: (CustomerId, AsOfDate, MasterCompanyId)
        --          → UPDATE if snapshot row already exists
        --          → INSERT if it is a new snapshot
        -- ----------------------------------------------------------------
        --MERGE [dbo].[CustomerAging] AS target
        --USING
        --(
        --    SELECT
        --        cad.CustomerId,
        --        c.[Name]          AS CustomerName,
        --        c.CustomerCode,
        --        cad.CreditTermsId,
        --        cad.CreditTermName,
        --        cad.NetDays,
        --        cad.CreditLimit,
        --        @AsOfDate         AS AsOfDate,
        --        cad.TotalInvoices,
        --        cad.TotalOutstanding,
        --        cad.CurrentAmount,
        --        cad.Days1_30,
        --        cad.Days31_60,
        --        cad.Days61_90,
        --        cad.Days91_120,
        --        cad.Days120Plus,
        --        cad.MasterCompanyId
        --    FROM CustomerAgingData cad
        --    JOIN [dbo].[Customer] c WITH (NOLOCK) ON c.CustomerId = cad.CustomerId
        --) AS source
        --    ON  target.CustomerId      = source.CustomerId
        --    AND target.AsOfDate        = source.AsOfDate
        --    AND target.MasterCompanyId = source.MasterCompanyId

        ---- Row already exists for this customer + date → refresh figures
        --WHEN MATCHED THEN UPDATE SET
        --    target.CustomerName      = source.CustomerName,
        --    target.CustomerCode      = source.CustomerCode,
        --    target.CreditTermsId     = source.CreditTermsId,
        --    target.CreditTermName    = source.CreditTermName,
        --    target.NetDays           = source.NetDays,
        --    target.CreditLimit       = source.CreditLimit,
        --    target.TotalInvoices     = source.TotalInvoices,
        --    target.TotalOutstanding  = source.TotalOutstanding,
        --    target.CurrentAmount     = source.CurrentAmount,
        --    target.Days1_30          = source.Days1_30,
        --    target.Days31_60         = source.Days31_60,
        --    target.Days61_90         = source.Days61_90,
        --    target.Days91_120        = source.Days91_120,
        --    target.Days120Plus       = source.Days120Plus,
        --    target.UpdatedBy         = @CreatedBy,
        --    target.UpdatedDate       = GETDATE()

        ---- New snapshot row for this customer + date
        --WHEN NOT MATCHED BY TARGET THEN INSERT
        --(
        --    CustomerId, CustomerName, CustomerCode,
        --    CreditTermsId, CreditTermName, NetDays, CreditLimit,
        --    AsOfDate,
        --    TotalInvoices, TotalOutstanding,
        --    CurrentAmount, Days1_30, Days31_60, Days61_90, Days91_120, Days120Plus,
        --    MasterCompanyId,
        --    CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
        --)
        --VALUES
        --(
        --    source.CustomerId, source.CustomerName, source.CustomerCode,
        --    source.CreditTermsId, source.CreditTermName, source.NetDays, source.CreditLimit,
        --    source.AsOfDate,
        --    source.TotalInvoices, source.TotalOutstanding,
        --    source.CurrentAmount, source.Days1_30, source.Days31_60, source.Days61_90, source.Days91_120, source.Days120Plus,
        --    source.MasterCompanyId,
        --    @CreatedBy, @CreatedBy, GETDATE(), GETDATE(), 1, 0
        --);

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
        DECLARE @ErrorState    INT            = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

END