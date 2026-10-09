
/*************************************************************
 ** File:   [usprpt_GetLotCommissionReportCashPosted]
 ** Author: Kishor Makwana (AI-assisted via Claude)
 ** Description: [PN-17830] Custom Commission Setup - BAG. "Commission Payment Tracking"
 **              report (Cash Posted Date tab): for each cash receipt posted against a
 **              consignment Lot, apportions the cash between Consignee/Consignor per the
 **              Lot's own LotConsignment percent setup, nets the Consignor's gross portion
 **              against the Lot's COGS/Repair, Freight and Other Cost, and tracks a running
 **              Owed-to-Consignor balance. Also surfaces already-issued "Payment to Consignor"
 **              AP checks (VendorReadyToPayHeader/Details + VendorPaymentDetails) alongside the
 **              cash-receipt rows.
 ** Date:   03/September/2026
 ** PARAMETERS: @PageNumber, @PageSize, @mastercompanyid, @xmlFilter
 **             (Filters: "From Cash Post Date", "To Cash Post Date", "PN", "Invoice Num",
 **              "Level1".."Level10"), @SortColumn, @SortOrder
 ** RETURN VALUE: paged result set, one row per (cash receipt, Lot) plus one row per issued
 **              Consignor AP payment
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author                          Change Description
 ** --   --------     -------                         ---------------------------
    1    02/September/2026   Kishor Makwana (AI-assisted via Claude)   [PN-17830] Created
    2    04/September/2026   Claude (Rajesh Gami)   [PN-17853] LessCOGSRepair/LessFreight/LessOtherCost
         replaced: LessCOGSRepair is now (SUM of the invoice's stockline UnitCost) * (this cash receipt's
         % of the invoice's InvoiceAmount); LessFreight/LessOtherCost now come from LOTOtherCostDetails
         (UnReconciledFreight+ManualAdjFreight / UnReconciledCharges+ManualAdjCharges), scoped to the
         Lot + the invoice's own stockline(s) + the report's date range via LOTOtherCostDetails.PostedDate.
         These are no longer zeroed out after the first cash-receipt row per Lot (see AppliedCTE) since
         they are now inherently per-row/per-payment proportional, not a Lot-wide total. New InvoiceAmount
         output column (FieldsMaster). New blank-line branch: one row per Lot with LessFreight/LessOtherCost
         only, for LOTOtherCostDetails IsNA=1 rows (Other Cost entries with no Part/Stockline) in range.
    3    04/September/2026   Claude (Rajesh Gami)   [PN-17853] ConsigneePortion/ConsignorPortionGross now
         branch on LotConsignment.IsRevenue/IsMargin/IsFixedAmount instead of always using the
         revenue-percent (CRP/CRP1) formula: IsFixedAmount=1 uses LG.PerAmount directly (Consignor =
         CashReceipt - PerAmount); IsRevenue=1 AND IsMargin=1 sums the revenue-percent share of CashReceipt
         with the margin-percent share of (CashReceipt - LessCOGSRepair); IsMargin=1 alone uses only the
         margin-percent share of (CashReceipt - LessCOGSRepair); IsRevenue=1 alone is unchanged from before.
         LessCOGSRepair is now computed once in CashCTE (LCR CROSS APPLY) instead of being recomputed in
         CalcCTE, so both the new Consignee/Consignor branching and the existing Less* columns share one
         calculation.
    4    09/September/2026   Claude (Rajesh Gami)   [PN-17830] Added LotId to the returned result
         set (PaymentCTE, NACTE + its GROUP BY, all three AllRowsCTE UNION ALL branches, and the
         final SELECT) so the LOT Commission Report grid's "Initiate Consignor Payment" action can
         resolve the row's Lot (previously only LOTNum/LotNumber text was returned, so rowData.lotId
         was always undefined on the frontend).
    5    09/September/2026   Claude (Rajesh Gami)   [PN-17830] Added ReceiptId to the
         final SELECT output, and threaded CustomerPayments.IsNonPOGenerated through CashCTE
         (both branches, real value from CP.IsNonPOGenerated), PaymentCTE/NACTE (NULL placeholder -
         neither branch corresponds to a specific CustomerPayments row), all three AllRowsCTE
         UNION ALL branches, and the final SELECT. Lets the LOT Commission Report grid disable
         "Initiate Consignor Payment" once a NON PO invoice has already been generated for that
         cash receipt (USP_AddUpdate_NonPOInvoiceHeader now sets IsNonPOGenerated=1 on
         CustomerPayments when it stores the ReceiptId passed from that flow).
    6    10/September/2026   Claude (Rajesh Gami)   [PN-17830] Added npoNumber to the
         final SELECT output (frontend's new "Manual Inv Num" column, sourced from
         NonPOInvoiceHeader.NPONumber). Looked up in CashCTE (both branches) via an OUTER APPLY +
         TOP 1 (NOT a plain JOIN) keyed on NPOH2.ReceiptId = CP.ReceiptId AND
         ISNULL(CP.IsNonPOGenerated,0) = 1, excluding soft-deleted headers and ordered by
         NonPOInvoiceId DESC - guarantees at most one NPONumber per cash-receipt row (and so can
         never duplicate/fan-out CashCTE's rows) even though NonPOInvoiceHeader.ReceiptId has no
         DB-level unique constraint. Threaded through CalcCTE/AppliedCTE/DueCTE/OwedCTE (all
         SELECT *), explicitly through AllRowsCTE's three UNION ALL branches (NULL placeholder for
         the PaymentCTE/NACTE branches, which have no corresponding CustomerPayments row), and the
         final SELECT.
    7    11/September/2026   Claude (Rajesh Gami)   [PN-17830] PaymentCTE's LotResolved OUTER APPLY
         (resolves the Lot shown against an already-issued Consignor AP payment) now covers
         NonPOInvoiceHeader-based rows only (the ReceivingReconciliationDetails-based/RRH branch is
         intentionally not used here per Rajesh): two branches trace CP.ReceiptId = NPIH.ReceiptId
         through InvoicePayments/BillingInvoicing/BillingInvoicingItems (WO and SO ModuleId) to the
         Stockline's Lot. Both branches now feed one UNION ALL wrapped in an outer SELECT TOP 1
         (was a plain UNION, which could return two rows - one per WO/SO match - and duplicate the
         PaymentCTE row for a payment whose customer payment touches both a WO and a SO billing
         invoice item).
    8    14/September/2026   Rajesh Gami   [PN-17830] Added Qty in the COGS price (UnitCost * QtyBilled) --LessCOGSRepairCalc
    9    16/September/2026   RAJESH GAMI   [PN-17881] ConsigneePortion/ConsignorPortionGross (both the SO and
         WO branches of CashCTE) now source LG.IsRevenue/IsMargin/IsFixedAmount/PercentId/PerAmount/
         ConsignorPercentId/MarginPercentId/MarginConsignorPercentId from dbo.LotCalculationDetails
         (RevenuePercentId/FixedAmount/RevenueConsignorPercentId/MarginPercentId/MarginConsignorPercentId,
         aliased back to the same names) via an OUTER APPLY (TOP 1, LotId + Type='Trans Out (SO)', latest
         LotCalculationId) instead of a plain LEFT JOIN to dbo.LotConsignment - LotConsignment itself is no
         longer read here. The OUTER APPLY is required (not a plain join) because LotCalculationDetails has
         many rows per LotId, unlike LotConsignment's one row per LotId.
    10   08/October/2026   Claude (Rajesh Gami)   [PN-18257] Full rewrite for the Parent/Child LOT layout
         (Customer Payment side only - Vendor/Consignor payments and the IsNA "blank line" Other Cost rows
         will be added in a later step). Old version kept in
         PN-18257_Deliverables\usprpt_GetLotCommissionReportCashPosted_BEFORE_PN-18257.sql.
         - Date filter now uses CustomerPayments.DepositDate (was CP.PostedDate). UI filter names unchanged.
         - STEP 1 #LotCommissionBase : one row per (Cash Receipt payment, Invoice line) for LOT parts,
                                       from Rajesh's base query (SO -> LotTransInOutDetails ->
                                       LotCalculationDetails 'Trans Out (SO)'), de-duplicated per invoice line.
         - STEP 2 #LotCommissionPay  : Cash Receipt per (ReceiptId, Invoice) + Received % = CashReceipt / Invoice GrandTotal.
         - STEP 3 #LotCommissionLine : line-level Allocated amount (line amount x Received %), COGS, Freight,
                                       Other Cost (all x Received %), Consignee / Consignor split.
         - STEP 4 #LotCommissionChild: one row per LOT under a Cash Receipt / Invoice (sum of its lines).
         - STEP 5 #LotCommissionParent: one row per Cash Receipt / Invoice = SUM of its children, with the
                                       comma-separated LOTNum and the children as LotDetails JSON.
         - Due to Consignor = Consignor Portion (Gross) - COGS/Repair + Freight + Other Cost (per PN-18257 spec).
         - Owed to Consignor = Due - Paid (Paid = 0 until the vendor payment step).
 **************************************************************
 EXEC usprpt_GetLotCommissionReportCashPosted @PageNumber=1,@PageSize=100,@mastercompanyid=1,@xmlFilter='<ArrayOfFilter><Filter><FieldName>From Cash Post Date</FieldName><FieldValue>10/01/2026</FieldValue></Filter><Filter><FieldName>To Cash Post Date</FieldName><FieldValue>10/08/2026</FieldValue></Filter></ArrayOfFilter>'
**************************************************************/
CREATE PROCEDURE [dbo].[usprpt_GetLotCommissionReportCashPosted]
@PageNumber INT = 1,
@PageSize INT = NULL,
@mastercompanyid INT,
@xmlFilter XML,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  DECLARE @FromCashPostDate VARCHAR(MAX) = NULL,
    @ToCashPostDate VARCHAR(MAX) = NULL,
    @PN VARCHAR(MAX) = NULL,
    @InvoiceNum VARCHAR(MAX) = NULL,
    @Level1 VARCHAR(MAX) = NULL,
    @Level2 VARCHAR(MAX) = NULL,
    @Level3 VARCHAR(MAX) = NULL,
    @Level4 VARCHAR(MAX) = NULL,
    @Level5 VARCHAR(MAX) = NULL,
    @Level6 VARCHAR(MAX) = NULL,
    @Level7 VARCHAR(MAX) = NULL,
    @Level8 VARCHAR(MAX) = NULL,
    @Level9 VARCHAR(MAX) = NULL,
    @Level10 VARCHAR(MAX) = NULL

  BEGIN TRY
    SELECT
      @FromCashPostDate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'From Cash Post Date' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @FromCashPostDate END,
      @ToCashPostDate   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'To Cash Post Date'   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToCashPostDate END,
      @PN               = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'PN'                 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @PN END,
      @InvoiceNum       = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Invoice Num'        THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @InvoiceNum END,
      @Level1  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level1'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level1 END,
      @Level2  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level2'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level2 END,
      @Level3  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level3'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level3 END,
      @Level4  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level4'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level4 END,
      @Level5  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level5'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level5 END,
      @Level6  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level6'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level6 END,
      @Level7  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level7'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level7 END,
      @Level8  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level8'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level8 END,
      @Level9  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level9'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level9 END,
      @Level10 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level10' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level10 END
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)

    -- UI filter names stay "From/To Cash Post Date"; from PN-18257 they filter on CustomerPayments.DepositDate.
    DECLARE @FromDepositDt DATE = TRY_CONVERT(DATE, @FromCashPostDate, 101);
    DECLARE @ToDepositDt   DATE = TRY_CONVERT(DATE, @ToCashPostDate, 101);

    DECLARE @LotModuleId INT;
    SELECT @LotModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Lot';

    DECLARE @SOTransOutType VARCHAR(50) = 'Trans Out (SO)';

    IF OBJECT_ID(N'tempdb..#LotCommissionBase')   IS NOT NULL DROP TABLE #LotCommissionBase;
    IF OBJECT_ID(N'tempdb..#LotCommissionPay')    IS NOT NULL DROP TABLE #LotCommissionPay;
    IF OBJECT_ID(N'tempdb..#LotOtherCost')        IS NOT NULL DROP TABLE #LotOtherCost;
    IF OBJECT_ID(N'tempdb..#LotCommissionLine')   IS NOT NULL DROP TABLE #LotCommissionLine;
    IF OBJECT_ID(N'tempdb..#LotCommissionChild')  IS NOT NULL DROP TABLE #LotCommissionChild;
    IF OBJECT_ID(N'tempdb..#LotCommissionParent') IS NOT NULL DROP TABLE #LotCommissionParent;

    /*=====================================================================================
      STEP 1 : Base data - one row per (Cash Receipt payment, Invoice line) for LOT parts.
               Customer payment side only.
    =====================================================================================*/
    CREATE TABLE #LotCommissionBase
    (
      RowId                       INT IDENTITY(1,1) PRIMARY KEY,
      ReceiptId                   BIGINT NULL,
      ReceiptNo                   VARCHAR(100) NULL,
      DepositDate                 DATETIME NULL,
      CustomerPmtReference        VARCHAR(100) NULL,
      IsNonPOGenerated            BIT NULL,
      PaymentId                   BIGINT NULL,
      CashReceipt                 DECIMAL(20,2) NULL,      -- InvoicePayments.PaymentAmount (receipt -> this invoice)
      BillingInvoicingId          BIGINT NULL,
      InvoiceNum                  VARCHAR(256) NULL,
      InvoiceDate                 DATETIME NULL,
      InvoiceTotal                DECIMAL(18,2) NULL,      -- BillingInvoicing.GrandTotal (whole invoice)
      BillingInvoicingItemId      BIGINT NULL,
      StocklineId                 BIGINT NULL,
      LineAmount                  DECIMAL(18,2) NULL,      -- BillingInvoicingItems.GrandTotal (this LOT line)
      LineCOGS                    DECIMAL(18,2) NULL,      -- Stockline.UnitCost * QtyBilled
      LotId                       BIGINT NULL,
      LotNumber                   VARCHAR(200) NULL,
      LotTransInOutId             BIGINT NULL,
      LotCalculationId            BIGINT NULL,
      IsRevenue                   BIT NULL,
      IsMargin                    BIT NULL,
      IsFixedAmount               BIT NULL,
      FixedAmount                 DECIMAL(18,2) NULL,
      RevenueConsigneePercentage  DECIMAL(18,2) NULL,
      RevenueConsignorPercent     DECIMAL(18,2) NULL,
      MarginConsigneerPercentage  DECIMAL(18,2) NULL,
      MarginConsignorPercentage   DECIMAL(18,2) NULL,
      level1                      VARCHAR(500) NULL,
      level2                      VARCHAR(500) NULL,
      level3                      VARCHAR(500) NULL,
      level4                      VARCHAR(500) NULL
    );

    INSERT INTO #LotCommissionBase
    (
      ReceiptId, ReceiptNo, DepositDate, CustomerPmtReference, IsNonPOGenerated, PaymentId, CashReceipt,
      BillingInvoicingId, InvoiceNum, InvoiceDate, InvoiceTotal, BillingInvoicingItemId, StocklineId, LineAmount, LineCOGS,
      LotId, LotNumber, LotTransInOutId, LotCalculationId, IsRevenue, IsMargin, IsFixedAmount, FixedAmount,
      RevenueConsigneePercentage, RevenueConsignorPercent, MarginConsigneerPercentage, MarginConsignorPercentage,
      level1, level2, level3, level4
    )
    SELECT
      X.ReceiptId, X.ReceiptNo, X.DepositDate, X.CustomerPmtReference, X.IsNonPOGenerated, X.PaymentId, X.CashReceipt,
      X.BillingInvoicingId, X.InvoiceNum, X.InvoiceDate, X.InvoiceTotal, X.BillingInvoicingItemId, X.StocklineId, X.LineAmount, X.LineCOGS,
      X.LotId, X.LotNumber, X.LotTransInOutId, X.LotCalculationId, X.IsRevenue, X.IsMargin, X.IsFixedAmount, X.FixedAmount,
      X.RevenueConsigneePercentage, X.RevenueConsignorPercent, X.MarginConsigneerPercentage, X.MarginConsignorPercentage,
      X.level1, X.level2, X.level3, X.level4
    FROM (
      SELECT
        CP.ReceiptId,
        CP.ReceiptNo,
        CP.DepositDate,
        CP.Reference                AS CustomerPmtReference,
        CP.IsNonPOGenerated,
        IPY.PaymentId,
        IPY.PaymentAmount           AS CashReceipt,
        BI.BillingInvoicingId,
        BI.InvoiceNo                AS InvoiceNum,
        BI.InvoiceDate,
        BI.GrandTotal               AS InvoiceTotal,
        BII.BillingInvoicingItemId,
        BII.StocklineId,
        BII.GrandTotal              AS LineAmount,
        ISNULL(STK.UnitCost,0) * ISNULL(BII.QtyBilled,1) AS LineCOGS,
        LT.LotId,
        LT.LotNumber,
        LTIN.LotTransInOutId,
        LCAL.LotCalculationId,
        LCAL.IsRevenue,
        LCAL.IsMargin,
        LCAL.IsFixedAmount,
        LCAL.FixedAmount,
        CRP.PercentValue            AS RevenueConsigneePercentage,
        CRP1.PercentValue           AS RevenueConsignorPercent,
        CRMP.PercentValue           AS MarginConsigneerPercentage,
        CRMP1.PercentValue          AS MarginConsignorPercentage,
        CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) END AS level1,
        CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) END AS level2,
        CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) END AS level3,
        CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) END AS level4,
        -- One row per (payment, invoice line): if more than one Trans Out LotCalculationDetails row matches
        -- the same invoice line, keep the latest one so the line amount is never counted twice.
        ROW_NUMBER() OVER (PARTITION BY IPY.PaymentId, BII.BillingInvoicingItemId ORDER BY LCAL.LotCalculationId DESC) AS RN
      FROM dbo.BillingInvoicingItems BII WITH (NOLOCK)
      INNER JOIN dbo.BillingInvoicing BI WITH (NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId
      INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = BII.SubReferenceId
      INNER JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = SOP.LotId AND ISNULL(LT.IsDeleted,0) = 0
      INNER JOIN dbo.InvoicePayments IPY WITH (NOLOCK) ON BI.BillingInvoicingId = IPY.SOBillingInvoicingId AND ISNULL(IPY.IsDeleted,0) = 0
      INNER JOIN dbo.CustomerPayments CP WITH (NOLOCK) ON IPY.ReceiptId = CP.ReceiptId
      INNER JOIN dbo.LotTransInOutDetails LTIN WITH (NOLOCK) ON BII.StocklineId = LTIN.StockLineId AND LTIN.LotId = LT.LotId
      INNER JOIN dbo.LotCalculationDetails LCAL WITH (NOLOCK) ON LTIN.LotTransInOutId = LCAL.LotTransInOutId
                                                             AND UPPER(REPLACE(LCAL.[Type],' ','')) = UPPER(REPLACE(@SOTransOutType,' ',''))
                                                             AND SOP.SalesOrderId = LCAL.ReferenceId
                                                             AND SOP.SalesOrderPartId = LCAL.ChildId
                                                             -- [PN-18257] when the invoice line is stamped on LotCalculationDetails, use it
                                                             AND (LCAL.BillingInvoicingItemId IS NULL OR LCAL.BillingInvoicingItemId = BII.BillingInvoicingItemId)
      LEFT JOIN dbo.Stockline STK WITH (NOLOCK) ON STK.StockLineId = BII.StocklineId
      LEFT JOIN dbo.[Percent] CRP   WITH (NOLOCK) ON CRP.PercentId   = LCAL.PercentId
      LEFT JOIN dbo.[Percent] CRP1  WITH (NOLOCK) ON CRP1.PercentId  = LCAL.RevenueConsignorPercentId
      LEFT JOIN dbo.[Percent] CRMP  WITH (NOLOCK) ON CRMP.PercentId  = LCAL.MarginPercentId
      LEFT JOIN dbo.[Percent] CRMP1 WITH (NOLOCK) ON CRMP1.PercentId = LCAL.MarginConsignorPercentId
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
      LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
      WHERE LT.MasterCompanyId = @mastercompanyid
        AND ISNULL(CP.IsDeleted,0) = 0
        AND ISNULL(BII.IsDeleted,0) = 0
        AND (@FromDepositDt IS NULL OR CAST(CP.DepositDate AS DATE) >= @FromDepositDt)
        AND (@ToDepositDt   IS NULL OR CAST(CP.DepositDate AS DATE) <= @ToDepositDt)
        AND (ISNULL(@InvoiceNum,'') = '' OR BI.InvoiceNo LIKE '%' + @InvoiceNum + '%')
        AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
        AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
        AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
        AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
        AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
        AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
        AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
        AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
        AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
        AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
    ) X
    WHERE X.RN = 1;

    /*=====================================================================================
      STEP 2 : Cash Receipt per (Receipt, Invoice) and Received %.
               Received % = Cash Receipt / Invoice Amount (BillingInvoicing.GrandTotal).
               Each Cash Receipt only carries its own share, so the same invoice/LOT under two
               receipts is split, never duplicated.
    =====================================================================================*/
    CREATE TABLE #LotCommissionPay
    (
      ReceiptId           BIGINT NOT NULL,
      BillingInvoicingId  BIGINT NOT NULL,
      CashReceipt         DECIMAL(20,2) NULL,
      InvoiceTotal        DECIMAL(18,2) NULL,
      ReceivedPct         DECIMAL(18,8) NULL,     -- fraction (0.5 = 50%)
      PRIMARY KEY (ReceiptId, BillingInvoicingId)
    );

    INSERT INTO #LotCommissionPay (ReceiptId, BillingInvoicingId, CashReceipt, InvoiceTotal, ReceivedPct)
    SELECT P.ReceiptId, P.BillingInvoicingId, SUM(P.CashReceipt), MAX(P.InvoiceTotal),
           CASE WHEN ISNULL(MAX(P.InvoiceTotal),0) = 0 THEN 0
                ELSE CAST(SUM(P.CashReceipt) AS DECIMAL(38,12)) / MAX(P.InvoiceTotal) END
    FROM (SELECT DISTINCT ReceiptId, BillingInvoicingId, PaymentId, CashReceipt, InvoiceTotal FROM #LotCommissionBase) P
    GROUP BY P.ReceiptId, P.BillingInvoicingId;

    /*=====================================================================================
      STEP 3 : Line level calculation (one row per Receipt + Invoice line).
               Allocated = Line Amount x Received %; COGS / Freight / Other Cost x Received %.
               Consignee / Consignor split follows LotCalculationDetails IsFixedAmount / IsRevenue /
               IsMargin (same rules as PN-17853), applied on the Allocated amount.
    =====================================================================================*/
    -- Freight / Other Cost (LOT Other Cost tab) per LOT + stockline, posted within the report date range
    -- (LOTOtherCostDetails.PostedDate between From/To date), prorated by Received % below.
    CREATE TABLE #LotOtherCost
    (
      LotId        BIGINT NOT NULL,
      StocklineId  BIGINT NOT NULL,
      Freight      DECIMAL(18,2) NULL,
      OtherCost    DECIMAL(18,2) NULL,
      PRIMARY KEY (LotId, StocklineId)
    );

    INSERT INTO #LotOtherCost (LotId, StocklineId, Freight, OtherCost)
    SELECT LOC.LotId, LOC.StocklineId,
           SUM(ISNULL(LOC.UnReconciledFreight,0) + ISNULL(LOC.ManualAdjFreight,0)),
           SUM(ISNULL(LOC.UnReconciledCharges,0) + ISNULL(LOC.ManualAdjCharges,0))
    FROM dbo.LOTOtherCostDetails LOC WITH (NOLOCK)
    WHERE ISNULL(LOC.IsDeleted,0) = 0
      AND ISNULL(LOC.IsNA,0) = 0
      AND LOC.StocklineId IS NOT NULL
      -- Only Other Cost entries posted within the report's date range (same From/To dates as the Cash Receipt filter)
      AND (@FromDepositDt IS NULL OR CAST(LOC.PostedDate AS DATE) >= @FromDepositDt)
      AND (@ToDepositDt   IS NULL OR CAST(LOC.PostedDate AS DATE) <= @ToDepositDt)
      AND EXISTS (SELECT 1 FROM #LotCommissionBase B WHERE B.LotId = LOC.LotId AND B.StocklineId = LOC.StocklineId)
    GROUP BY LOC.LotId, LOC.StocklineId;

    CREATE TABLE #LotCommissionLine
    (
      ReceiptId               BIGINT NOT NULL,
      BillingInvoicingId      BIGINT NOT NULL,
      BillingInvoicingItemId  BIGINT NOT NULL,
      LotId                   BIGINT NULL,
      LotNumber               VARCHAR(200) NULL,
      ReceivedPct             DECIMAL(18,8) NULL,
      LineAmount              DECIMAL(18,2) NULL,
      AllocatedAmount         DECIMAL(18,2) NULL,
      COGSRepair              DECIMAL(18,2) NULL,
      Freight                 DECIMAL(18,2) NULL,
      OtherCost               DECIMAL(18,2) NULL,
      ConsigneePortion        DECIMAL(18,2) NULL,
      ConsignorPortionGross   DECIMAL(18,2) NULL
    );

    ;WITH L AS (
      SELECT DISTINCT B.ReceiptId, B.BillingInvoicingId, B.BillingInvoicingItemId, B.LotId, B.LotNumber, B.StocklineId,
             B.LineAmount, B.LineCOGS, B.IsRevenue, B.IsMargin, B.IsFixedAmount, B.FixedAmount,
             B.RevenueConsigneePercentage, B.RevenueConsignorPercent, B.MarginConsigneerPercentage, B.MarginConsignorPercentage
      FROM #LotCommissionBase B
    ),
    A AS (
      SELECT L.*, P.ReceivedPct,
             ROUND(ISNULL(L.LineAmount,0) * P.ReceivedPct, 2)        AS AllocatedAmount,
             ROUND(ISNULL(L.LineCOGS,0)   * P.ReceivedPct, 2)        AS COGSRepair,
             ROUND(ISNULL(OC.Freight,0)   * P.ReceivedPct, 2)        AS Freight,
             ROUND(ISNULL(OC.OtherCost,0) * P.ReceivedPct, 2)        AS OtherCost,
             ROUND(ISNULL(L.FixedAmount,0) * P.ReceivedPct, 2)       AS FixedAllocated
      FROM L
      INNER JOIN #LotCommissionPay P ON P.ReceiptId = L.ReceiptId AND P.BillingInvoicingId = L.BillingInvoicingId
      LEFT JOIN #LotOtherCost OC ON OC.LotId = L.LotId AND OC.StocklineId = L.StocklineId
    )
    INSERT INTO #LotCommissionLine
    (
      ReceiptId, BillingInvoicingId, BillingInvoicingItemId, LotId, LotNumber, ReceivedPct, LineAmount, AllocatedAmount,
      COGSRepair, Freight, OtherCost, ConsigneePortion, ConsignorPortionGross
    )
    SELECT
      A.ReceiptId, A.BillingInvoicingId, A.BillingInvoicingItemId, A.LotId, A.LotNumber, A.ReceivedPct, A.LineAmount, A.AllocatedAmount,
      A.COGSRepair, A.Freight, A.OtherCost,
      CASE
        WHEN ISNULL(A.IsFixedAmount,0) = 1 THEN A.FixedAllocated
        WHEN ISNULL(A.IsRevenue,0) = 1 AND ISNULL(A.IsMargin,0) = 1 THEN
             ROUND(A.AllocatedAmount * ISNULL(A.RevenueConsigneePercentage,0) / 100, 2)
           + ROUND((A.AllocatedAmount - A.COGSRepair) * ISNULL(A.MarginConsigneerPercentage,0) / 100, 2)
        WHEN ISNULL(A.IsMargin,0) = 1 THEN
             ROUND((A.AllocatedAmount - A.COGSRepair) * ISNULL(A.MarginConsigneerPercentage,0) / 100, 2)
        WHEN ISNULL(A.IsRevenue,0) = 1 THEN
             ROUND(A.AllocatedAmount * ISNULL(A.RevenueConsigneePercentage,0) / 100, 2)
        ELSE
             ROUND(A.AllocatedAmount * ISNULL(ISNULL(A.RevenueConsigneePercentage, A.MarginConsigneerPercentage),0) / 100, 2)
      END AS ConsigneePortion,
      CASE
        WHEN ISNULL(A.IsFixedAmount,0) = 1 THEN A.AllocatedAmount - A.FixedAllocated
        WHEN ISNULL(A.IsRevenue,0) = 1 AND ISNULL(A.IsMargin,0) = 1 THEN
             ROUND(A.AllocatedAmount * ISNULL(A.RevenueConsignorPercent,0) / 100, 2)
           + ROUND((A.AllocatedAmount - A.COGSRepair) * ISNULL(A.MarginConsignorPercentage,0) / 100, 2)
        WHEN ISNULL(A.IsMargin,0) = 1 THEN
             ROUND((A.AllocatedAmount - A.COGSRepair) * ISNULL(A.MarginConsignorPercentage,0) / 100, 2)
        WHEN ISNULL(A.IsRevenue,0) = 1 THEN
             ROUND(A.AllocatedAmount * ISNULL(A.RevenueConsignorPercent,0) / 100, 2)
        ELSE
             ROUND(A.AllocatedAmount * ISNULL(ISNULL(A.RevenueConsignorPercent, A.MarginConsignorPercentage),0) / 100, 2)
      END AS ConsignorPortionGross
    FROM A;

    /*=====================================================================================
      STEP 4 : Child rows - one row per LOT under a Cash Receipt / Invoice.
               Due  = Consignor Portion (Gross) - COGS/Repair + Freight + Other Cost
               Owed = Due - Paid  (Paid = 0 until vendor payments are added)
    =====================================================================================*/
    CREATE TABLE #LotCommissionChild
    (
      ReceiptId              BIGINT NOT NULL,
      BillingInvoicingId     BIGINT NOT NULL,
      LotId                  BIGINT NULL,
      LotNum                 VARCHAR(200) NULL,
      LotAmount              DECIMAL(18,2) NULL,
      ReceivedPercent        DECIMAL(18,2) NULL,
      AllocatedAmount        DECIMAL(18,2) NULL,
      ConsigneePortion       DECIMAL(18,2) NULL,
      ConsignorPortionGross  DECIMAL(18,2) NULL,
      LessCogsRepair         DECIMAL(18,2) NULL,
      LessFreight            DECIMAL(18,2) NULL,
      LessOtherCost          DECIMAL(18,2) NULL,
      DueToConsignor         DECIMAL(18,2) NULL,
      PaidToConsignor        DECIMAL(18,2) NULL,
      OwedToConsignor        DECIMAL(18,2) NULL
    );

    INSERT INTO #LotCommissionChild
    (
      ReceiptId, BillingInvoicingId, LotId, LotNum, LotAmount, ReceivedPercent, AllocatedAmount, ConsigneePortion,
      ConsignorPortionGross, LessCogsRepair, LessFreight, LessOtherCost, DueToConsignor, PaidToConsignor, OwedToConsignor
    )
    SELECT
      C.ReceiptId, C.BillingInvoicingId, C.LotId, C.LotNumber, C.LotAmount, C.ReceivedPercent, C.AllocatedAmount,
      C.ConsigneePortion, C.ConsignorPortionGross, C.COGSRepair, C.Freight, C.OtherCost,
      C.ConsignorPortionGross - C.COGSRepair + C.Freight + C.OtherCost                       AS DueToConsignor,
      CAST(0 AS DECIMAL(18,2))                                                               AS PaidToConsignor,
      (C.ConsignorPortionGross - C.COGSRepair + C.Freight + C.OtherCost) - CAST(0 AS DECIMAL(18,2)) AS OwedToConsignor
    FROM (
      SELECT
        LN.ReceiptId, LN.BillingInvoicingId, LN.LotId, LN.LotNumber,
        SUM(ISNULL(LN.LineAmount,0))            AS LotAmount,
        ROUND(MAX(LN.ReceivedPct) * 100, 2)     AS ReceivedPercent,
        SUM(ISNULL(LN.AllocatedAmount,0))       AS AllocatedAmount,
        SUM(ISNULL(LN.ConsigneePortion,0))      AS ConsigneePortion,
        SUM(ISNULL(LN.ConsignorPortionGross,0)) AS ConsignorPortionGross,
        SUM(ISNULL(LN.COGSRepair,0))            AS COGSRepair,
        SUM(ISNULL(LN.Freight,0))               AS Freight,
        SUM(ISNULL(LN.OtherCost,0))             AS OtherCost
      FROM #LotCommissionLine LN
      GROUP BY LN.ReceiptId, LN.BillingInvoicingId, LN.LotId, LN.LotNumber
    ) C;

    /*=====================================================================================
      STEP 5 : Parent rows - one row per Cash Receipt / Invoice = SUM of its children
               (so child totals always tie back to the parent). LOTNum = comma separated LOTs,
               LotDetails = child rows as JSON for the expandable grid.
    =====================================================================================*/
    CREATE TABLE #LotCommissionParent
    (
      ReceiptId              BIGINT NOT NULL,
      BillingInvoicingId     BIGINT NOT NULL,
      ReceiptNo              VARCHAR(100) NULL,
      CashReceiptDateRaw     DATETIME NULL,
      CustomerPaymentRef     VARCHAR(100) NULL,
      InvoiceNum             VARCHAR(256) NULL,
      InvoiceDate            DATETIME NULL,
      InvoiceAmount          DECIMAL(18,2) NULL,
      CashReceipt            DECIMAL(20,2) NULL,
      ReceivedPercent        DECIMAL(18,2) NULL,
      LOTNum                 VARCHAR(MAX) NULL,
      LotId                  BIGINT NULL,
      LotAmount              DECIMAL(18,2) NULL,
      AllocatedAmount        DECIMAL(18,2) NULL,
      ConsigneePortion       DECIMAL(18,2) NULL,
      ConsignorPortionGross  DECIMAL(18,2) NULL,
      LessCogsRepair         DECIMAL(18,2) NULL,
      LessFreight            DECIMAL(18,2) NULL,
      LessOtherCost          DECIMAL(18,2) NULL,
      DueToConsignor         DECIMAL(18,2) NULL,
      PaidToConsignor        DECIMAL(18,2) NULL,
      OwedToConsignor        DECIMAL(18,2) NULL,
      IsNonPOGenerated       BIT NULL,
      npoNumber              VARCHAR(150) NULL,
      level1                 VARCHAR(500) NULL,
      level2                 VARCHAR(500) NULL,
      level3                 VARCHAR(500) NULL,
      level4                 VARCHAR(500) NULL,
      LotDetails             NVARCHAR(MAX) NULL,
      PRIMARY KEY (ReceiptId, BillingInvoicingId)
    );

    INSERT INTO #LotCommissionParent
    (
      ReceiptId, BillingInvoicingId, CashReceipt, ReceivedPercent, LOTNum, LotId, LotAmount, AllocatedAmount,
      ConsigneePortion, ConsignorPortionGross, LessCogsRepair, LessFreight, LessOtherCost,
      DueToConsignor, PaidToConsignor, OwedToConsignor
    )
    SELECT
      CH.ReceiptId, CH.BillingInvoicingId,
      MAX(P.CashReceipt),
      ROUND(MAX(P.ReceivedPct) * 100, 2),
      STRING_AGG(CAST(CH.LotNum AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY CH.LotNum),
      -- single LOT -> its LotId (used by "Initiate Consignor Payment"); several LOTs -> first one
      MIN(CH.LotId),
      SUM(CH.LotAmount), SUM(CH.AllocatedAmount), SUM(CH.ConsigneePortion), SUM(CH.ConsignorPortionGross),
      SUM(CH.LessCogsRepair), SUM(CH.LessFreight), SUM(CH.LessOtherCost),
      SUM(CH.DueToConsignor), SUM(CH.PaidToConsignor), SUM(CH.OwedToConsignor)
    FROM #LotCommissionChild CH
    INNER JOIN #LotCommissionPay P ON P.ReceiptId = CH.ReceiptId AND P.BillingInvoicingId = CH.BillingInvoicingId
    GROUP BY CH.ReceiptId, CH.BillingInvoicingId;

    -- Header info (receipt / invoice / MS levels of the first LOT) + NPO number + child JSON.
    UPDATE PR SET
      PR.ReceiptNo          = H.ReceiptNo,
      PR.CashReceiptDateRaw = H.DepositDate,
      PR.CustomerPaymentRef = H.CustomerPmtReference,
      PR.InvoiceNum         = H.InvoiceNum,
      PR.InvoiceDate        = H.InvoiceDate,
      PR.InvoiceAmount      = H.InvoiceTotal,
      PR.IsNonPOGenerated   = H.IsNonPOGenerated,
      PR.level1 = H.level1, PR.level2 = H.level2, PR.level3 = H.level3, PR.level4 = H.level4,
      PR.npoNumber          = NPOH.NPONumber,
      PR.LotDetails         = (
        SELECT CH.LotId                 AS lotId,
               CH.LotNum                AS lotNum,
               CH.LotAmount             AS lotAmount,
               CH.ReceivedPercent       AS receivedPercent,
               CH.AllocatedAmount       AS allocatedAmount,
               CH.ConsigneePortion      AS consigneePortion,
               CH.ConsignorPortionGross AS consignorPortionGross,
               CH.LessCogsRepair        AS lessCogsRepair,
               CH.LessFreight           AS lessFreight,
               CH.LessOtherCost         AS lessOtherCost,
               CH.DueToConsignor        AS dueToConsignor,
               CH.PaidToConsignor       AS paidToConsignor,
               CH.OwedToConsignor       AS owedToConsignor
        FROM #LotCommissionChild CH
        WHERE CH.ReceiptId = PR.ReceiptId AND CH.BillingInvoicingId = PR.BillingInvoicingId
        ORDER BY CH.LotNum
        FOR JSON PATH, INCLUDE_NULL_VALUES
      )
    FROM #LotCommissionParent PR
    CROSS APPLY (
      SELECT TOP 1 B.ReceiptNo, B.DepositDate, B.CustomerPmtReference, B.InvoiceNum, B.InvoiceDate, B.InvoiceTotal,
                   B.IsNonPOGenerated, B.level1, B.level2, B.level3, B.level4
      FROM #LotCommissionBase B
      WHERE B.ReceiptId = PR.ReceiptId AND B.BillingInvoicingId = PR.BillingInvoicingId
      ORDER BY B.LotNumber
    ) H
    OUTER APPLY (
      SELECT TOP 1 NPOH2.NPONumber
      FROM dbo.NonPOInvoiceHeader NPOH2 WITH (NOLOCK)
      WHERE ISNULL(H.IsNonPOGenerated,0) = 1
        AND NPOH2.ReceiptId = PR.ReceiptId
        AND ISNULL(NPOH2.IsDeleted,0) = 0
      ORDER BY NPOH2.NonPOInvoiceId DESC
    ) NPOH;

    /*=====================================================================================
      STEP 6 : Paged Parent output (+ totals across all pages).
    =====================================================================================*/
    IF ISNULL(@PageSize,0) = 0
      SELECT @PageSize = CASE WHEN COUNT(1) = 0 THEN 1 ELSE COUNT(1) END FROM #LotCommissionParent;

    SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END;

    SELECT
      COUNT(1) OVER ()                    AS TotalRecordsCount,
      SUM(DueToConsignor)  OVER ()        AS TotalDueToConsignor,
      SUM(PaidToConsignor) OVER ()        AS TotalPaidToConsignor,
      SUM(OwedToConsignor) OVER ()        AS TotalOwedToConsignor,
      ReceiptNo,
      FORMAT(CashReceiptDateRaw, 'MM-dd-yyyy') AS CashReceiptDate,
      CustomerPaymentRef,
      InvoiceNum,
      FORMAT(InvoiceDate, 'MM-dd-yyyy')   AS InvoiceDate,
      LotId,
      ReceiptId,
      BillingInvoicingId,
      IsNonPOGenerated,
      npoNumber,
      LOTNum,
      InvoiceAmount,
      CashReceipt,
      ReceivedPercent,
      LotAmount,
      AllocatedAmount,
      ConsigneePortion,
      ConsignorPortionGross,
      LessCogsRepair                      AS lessCogsRepair,
      LessFreight                         AS lessFreight,
      LessOtherCost                       AS lessOtherCost,
      DueToConsignor,
      PaidToConsignor,
      OwedToConsignor,
      CAST(NULL AS VARCHAR(10))           AS PaymentDate,
      CAST(NULL AS VARCHAR(100))          AS PaymentRef,
      level1, level2, level3, level4,
      ''                                  AS pn,
      LotDetails
    FROM #LotCommissionParent
    ORDER BY
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CashReceiptDate')  THEN CashReceiptDateRaw END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CashReceiptDate')  THEN CashReceiptDateRaw END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'LOTNum')           THEN LOTNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LOTNum')           THEN LOTNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'InvoiceNum')       THEN InvoiceNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'InvoiceNum')       THEN InvoiceNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'DueToConsignor')   THEN DueToConsignor END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'DueToConsignor')   THEN DueToConsignor END DESC,
      CashReceiptDateRaw ASC, ReceiptId ASC, InvoiceNum ASC
    OFFSET ((@PageNumber - 1) * @PageSize) ROWS
    FETCH NEXT @PageSize ROWS ONLY;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
      @DatabaseName VARCHAR(100) = DB_NAME()
      -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
      ,@AdhocComments VARCHAR(150) = '[usprpt_GetLotCommissionReportCashPosted]'
      ,@ProcedureParameters VARCHAR(3000) = '@PageNumber = ''' + CAST(ISNULL(@PageNumber,'') AS VARCHAR(100)) +
        ''', @PageSize = ''' + CAST(ISNULL(@PageSize,'') AS VARCHAR(100)) +
        ''', @mastercompanyid = ''' + CAST(ISNULL(@mastercompanyid,'') AS VARCHAR(100)) +
        ''', @xmlFilter = ''' + CAST(ISNULL(@xmlFilter,'') AS VARCHAR(MAX))
      ,@ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
