
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
    11   09/October/2026   Claude (Rajesh Gami)   [PN-18257] New "Lot Num" header filter (LotId, single or
         comma-separated). Date filter now also reads the renamed labels "From/To Deposit Date"
         (and "From/To Cash Deposit Date"); old "From/To Cash Post Date" still accepted. Child LOT rows
         (LotDetails JSON) now also carry partNumber, consigneeName (LotConsignment ConsigneeId +
         ConsigneeTypeId -> Vendor / Customer / Company(LegalEntity) / Others(ConsigneeName)) and the
         Revenue/Margin Consignee/Consignor percentages.
         Management structure level names extended from level1-4 to level1-10 (MSL5..MSL10 joins).
    12   09/October/2026   Claude (Rajesh Gami)   [PN-18257] "Initiate Payment" (multi-line Non PO invoice):
         IsNonPOGenerated / npoNumber now come from NonPOInvoicePartDetails.ReceiptId (line level; header
         and line not deleted) instead of CustomerPayments.IsNonPOGenerated + NonPOInvoiceHeader.ReceiptId.
         npoNumber lists every Non PO invoice that pays the receipt. Child JSON also returns
         consigneeTypeId / consigneeId (the LOT's Consignor) so the screen can check "same Consignor".
    13   09/October/2026   Claude (Rajesh Gami)   [PN-18257] LOT Other Cost entries WITHOUT a stockline
         (LOTOtherCostDetails IsNA = 1 / StocklineId NULL, posted within the From/To dates) are added -
         full amount, not prorated - to Freight / Other Cost of only the FIRST child row of that LOT in the
         report (ordered by Deposit Date, Receipt, Invoice); the LOT's other rows don't repeat it.
    14   09/October/2026   Claude (Rajesh Gami)   [PN-18257] Vendor (Consignor) payments - Paid to Consignor at
         LOT (child) level: generated, non-voided, non-deleted checks (VendorReadyToPayDetails, CheckDate up to
         the To date) paid against Non PO invoices created by "Initiate Payment". Each check is spread over its
         invoice's lines by line amount; a line is matched to the child row by NonPOInvoicePartDetails.ReceiptId
         + Item (= LOT Number). Owed to Consignor = Due - Paid. Parent / totals = sum of children.
    15   09/October/2026   Claude (Rajesh Gami)   [PN-18257] Readability only (no logic change): short aliases /
         CTE names (X, L, A, P, OC, C, LN, CH, NA, FR, RD, T, LP, PN, PCT, LC, V, LE, PR, H, InvLines, InvPaid)
         renamed to descriptive names (BaseRow, LotLineSource, LotLineCalc, ReceiptPay, LotStockOtherCost,
         LotChildSum, LotLine, LotChild, LotNACost, FirstRow, PaidTarget, LotPaid, LatestConsignment,
         ConsignorVendor/Customer/LegalEntity, LotParent, ParentHeader, NonPOInvoiceLines, NonPOInvoicePaid ...).
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
    @Level10 VARCHAR(MAX) = NULL,
    @LotIds VARCHAR(MAX) = NULL      -- [PN-18257] "Lot Num" filter (LotId / comma-separated LotIds)

  BEGIN TRY
    SELECT
      @FromCashPostDate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') IN ('From Cash Post Date','From Deposit Date','From Cash Deposit Date') THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @FromCashPostDate END,
      @ToCashPostDate   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') IN ('To Cash Post Date','To Deposit Date','To Cash Deposit Date') THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToCashPostDate END,
      @PN               = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'PN'                 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @PN END,
      @InvoiceNum       = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Invoice Num'        THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @InvoiceNum END,
      @LotIds           = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') IN ('Lot Num','LOT Num','LotNum','Lot Number') THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @LotIds END,
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

    -- UI filters "From/To Deposit Date" (previously "From/To Cash Post Date") filter on CustomerPayments.DepositDate.
    SET @LotIds = NULLIF(NULLIF(LTRIM(RTRIM(@LotIds)),''),'0');
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
      PartNumber                  VARCHAR(100) NULL,       -- ItemMaster.partnumber of the invoice line
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
      level4                      VARCHAR(500) NULL,
      level5                      VARCHAR(500) NULL,
      level6                      VARCHAR(500) NULL,
      level7                      VARCHAR(500) NULL,
      level8                      VARCHAR(500) NULL,
      level9                      VARCHAR(500) NULL,
      level10                     VARCHAR(500) NULL
    );

    INSERT INTO #LotCommissionBase
    (
      ReceiptId, ReceiptNo, DepositDate, CustomerPmtReference, IsNonPOGenerated, PaymentId, CashReceipt,
      BillingInvoicingId, InvoiceNum, InvoiceDate, InvoiceTotal, BillingInvoicingItemId, StocklineId, LineAmount, LineCOGS, PartNumber,
      LotId, LotNumber, LotTransInOutId, LotCalculationId, IsRevenue, IsMargin, IsFixedAmount, FixedAmount,
      RevenueConsigneePercentage, RevenueConsignorPercent, MarginConsigneerPercentage, MarginConsignorPercentage,
      level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
    )
    SELECT
      BaseRow.ReceiptId, BaseRow.ReceiptNo, BaseRow.DepositDate, BaseRow.CustomerPmtReference, BaseRow.IsNonPOGenerated, BaseRow.PaymentId, BaseRow.CashReceipt,
      BaseRow.BillingInvoicingId, BaseRow.InvoiceNum, BaseRow.InvoiceDate, BaseRow.InvoiceTotal, BaseRow.BillingInvoicingItemId, BaseRow.StocklineId, BaseRow.LineAmount, BaseRow.LineCOGS, BaseRow.PartNumber,
      BaseRow.LotId, BaseRow.LotNumber, BaseRow.LotTransInOutId, BaseRow.LotCalculationId, BaseRow.IsRevenue, BaseRow.IsMargin, BaseRow.IsFixedAmount, BaseRow.FixedAmount,
      BaseRow.RevenueConsigneePercentage, BaseRow.RevenueConsignorPercent, BaseRow.MarginConsigneerPercentage, BaseRow.MarginConsignorPercentage,
      BaseRow.level1, BaseRow.level2, BaseRow.level3, BaseRow.level4, BaseRow.level5, BaseRow.level6, BaseRow.level7, BaseRow.level8, BaseRow.level9, BaseRow.level10
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
        IM.partnumber               AS PartNumber,
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
        CASE WHEN UPPER(MSD.Level5Name) IS NOT NULL THEN UPPER(MSD.Level5Name) ELSE UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) END AS level5,
        CASE WHEN UPPER(MSD.Level6Name) IS NOT NULL THEN UPPER(MSD.Level6Name) ELSE UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) END AS level6,
        CASE WHEN UPPER(MSD.Level7Name) IS NOT NULL THEN UPPER(MSD.Level7Name) ELSE UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) END AS level7,
        CASE WHEN UPPER(MSD.Level8Name) IS NOT NULL THEN UPPER(MSD.Level8Name) ELSE UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) END AS level8,
        CASE WHEN UPPER(MSD.Level9Name) IS NOT NULL THEN UPPER(MSD.Level9Name) ELSE UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) END AS level9,
        CASE WHEN UPPER(MSD.Level10Name) IS NOT NULL THEN UPPER(MSD.Level10Name) ELSE UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) END AS level10,
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
      LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = BII.ItemMasterId
      LEFT JOIN dbo.[Percent] CRP   WITH (NOLOCK) ON CRP.PercentId   = LCAL.PercentId
      LEFT JOIN dbo.[Percent] CRP1  WITH (NOLOCK) ON CRP1.PercentId  = LCAL.RevenueConsignorPercentId
      LEFT JOIN dbo.[Percent] CRMP  WITH (NOLOCK) ON CRMP.PercentId  = LCAL.MarginPercentId
      LEFT JOIN dbo.[Percent] CRMP1 WITH (NOLOCK) ON CRMP1.PercentId = LCAL.MarginConsignorPercentId
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
      LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL5  WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL6  WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL7  WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL8  WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL9  WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
      WHERE LT.MasterCompanyId = @mastercompanyid
        AND ISNULL(CP.IsDeleted,0) = 0
        AND ISNULL(BII.IsDeleted,0) = 0
        AND (@FromDepositDt IS NULL OR CAST(CP.DepositDate AS DATE) >= @FromDepositDt)
        AND (@ToDepositDt   IS NULL OR CAST(CP.DepositDate AS DATE) <= @ToDepositDt)
        AND (ISNULL(@InvoiceNum,'') = '' OR BI.InvoiceNo LIKE '%' + @InvoiceNum + '%')
        AND (@LotIds IS NULL OR LT.LotId IN (SELECT Item FROM DBO.SPLITSTRING(@LotIds,',')))
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
    ) BaseRow
    WHERE BaseRow.RN = 1;

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
    SELECT ReceiptInvoice.ReceiptId, ReceiptInvoice.BillingInvoicingId, SUM(ReceiptInvoice.CashReceipt), MAX(ReceiptInvoice.InvoiceTotal),
           CASE WHEN ISNULL(MAX(ReceiptInvoice.InvoiceTotal),0) = 0 THEN 0
                ELSE CAST(SUM(ReceiptInvoice.CashReceipt) AS DECIMAL(38,12)) / MAX(ReceiptInvoice.InvoiceTotal) END
    FROM (SELECT DISTINCT ReceiptId, BillingInvoicingId, PaymentId, CashReceipt, InvoiceTotal FROM #LotCommissionBase) ReceiptInvoice
    GROUP BY ReceiptInvoice.ReceiptId, ReceiptInvoice.BillingInvoicingId;

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
      AND EXISTS (SELECT 1 FROM #LotCommissionBase BaseRow WHERE BaseRow.LotId = LOC.LotId AND BaseRow.StocklineId = LOC.StocklineId)
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

    ;WITH LotLineSource AS (
      SELECT DISTINCT BaseRow.ReceiptId, BaseRow.BillingInvoicingId, BaseRow.BillingInvoicingItemId, BaseRow.LotId, BaseRow.LotNumber, BaseRow.StocklineId,
             BaseRow.LineAmount, BaseRow.LineCOGS, BaseRow.IsRevenue, BaseRow.IsMargin, BaseRow.IsFixedAmount, BaseRow.FixedAmount,
             BaseRow.RevenueConsigneePercentage, BaseRow.RevenueConsignorPercent, BaseRow.MarginConsigneerPercentage, BaseRow.MarginConsignorPercentage
      FROM #LotCommissionBase BaseRow
    ),
    LotLineCalc AS (
      SELECT LotLineSource.*, ReceiptPay.ReceivedPct,
             ROUND(ISNULL(LotLineSource.LineAmount,0) * ReceiptPay.ReceivedPct, 2)        AS AllocatedAmount,
             ROUND(ISNULL(LotLineSource.LineCOGS,0)   * ReceiptPay.ReceivedPct, 2)        AS COGSRepair,
             ROUND(ISNULL(LotStockOtherCost.Freight,0)   * ReceiptPay.ReceivedPct, 2)        AS Freight,
             ROUND(ISNULL(LotStockOtherCost.OtherCost,0) * ReceiptPay.ReceivedPct, 2)        AS OtherCost,
             ROUND(ISNULL(LotLineSource.FixedAmount,0) * ReceiptPay.ReceivedPct, 2)       AS FixedAllocated
      FROM LotLineSource
      INNER JOIN #LotCommissionPay ReceiptPay ON ReceiptPay.ReceiptId = LotLineSource.ReceiptId AND ReceiptPay.BillingInvoicingId = LotLineSource.BillingInvoicingId
      LEFT JOIN #LotOtherCost LotStockOtherCost ON LotStockOtherCost.LotId = LotLineSource.LotId AND LotStockOtherCost.StocklineId = LotLineSource.StocklineId
    )
    INSERT INTO #LotCommissionLine
    (
      ReceiptId, BillingInvoicingId, BillingInvoicingItemId, LotId, LotNumber, ReceivedPct, LineAmount, AllocatedAmount,
      COGSRepair, Freight, OtherCost, ConsigneePortion, ConsignorPortionGross
    )
    SELECT
      LotLineCalc.ReceiptId, LotLineCalc.BillingInvoicingId, LotLineCalc.BillingInvoicingItemId, LotLineCalc.LotId, LotLineCalc.LotNumber, LotLineCalc.ReceivedPct, LotLineCalc.LineAmount, LotLineCalc.AllocatedAmount,
      LotLineCalc.COGSRepair, LotLineCalc.Freight, LotLineCalc.OtherCost,
      CASE
        WHEN ISNULL(LotLineCalc.IsFixedAmount,0) = 1 THEN LotLineCalc.FixedAllocated
        WHEN ISNULL(LotLineCalc.IsRevenue,0) = 1 AND ISNULL(LotLineCalc.IsMargin,0) = 1 THEN
             ROUND(LotLineCalc.AllocatedAmount * ISNULL(LotLineCalc.RevenueConsigneePercentage,0) / 100, 2)
           + ROUND((LotLineCalc.AllocatedAmount - LotLineCalc.COGSRepair) * ISNULL(LotLineCalc.MarginConsigneerPercentage,0) / 100, 2)
        WHEN ISNULL(LotLineCalc.IsMargin,0) = 1 THEN
             ROUND((LotLineCalc.AllocatedAmount - LotLineCalc.COGSRepair) * ISNULL(LotLineCalc.MarginConsigneerPercentage,0) / 100, 2)
        WHEN ISNULL(LotLineCalc.IsRevenue,0) = 1 THEN
             ROUND(LotLineCalc.AllocatedAmount * ISNULL(LotLineCalc.RevenueConsigneePercentage,0) / 100, 2)
        ELSE
             ROUND(LotLineCalc.AllocatedAmount * ISNULL(ISNULL(LotLineCalc.RevenueConsigneePercentage, LotLineCalc.MarginConsigneerPercentage),0) / 100, 2)
      END AS ConsigneePortion,
      CASE
        WHEN ISNULL(LotLineCalc.IsFixedAmount,0) = 1 THEN LotLineCalc.AllocatedAmount - LotLineCalc.FixedAllocated
        WHEN ISNULL(LotLineCalc.IsRevenue,0) = 1 AND ISNULL(LotLineCalc.IsMargin,0) = 1 THEN
             ROUND(LotLineCalc.AllocatedAmount * ISNULL(LotLineCalc.RevenueConsignorPercent,0) / 100, 2)
           + ROUND((LotLineCalc.AllocatedAmount - LotLineCalc.COGSRepair) * ISNULL(LotLineCalc.MarginConsignorPercentage,0) / 100, 2)
        WHEN ISNULL(LotLineCalc.IsMargin,0) = 1 THEN
             ROUND((LotLineCalc.AllocatedAmount - LotLineCalc.COGSRepair) * ISNULL(LotLineCalc.MarginConsignorPercentage,0) / 100, 2)
        WHEN ISNULL(LotLineCalc.IsRevenue,0) = 1 THEN
             ROUND(LotLineCalc.AllocatedAmount * ISNULL(LotLineCalc.RevenueConsignorPercent,0) / 100, 2)
        ELSE
             ROUND(LotLineCalc.AllocatedAmount * ISNULL(ISNULL(LotLineCalc.RevenueConsignorPercent, LotLineCalc.MarginConsignorPercentage),0) / 100, 2)
      END AS ConsignorPortionGross
    FROM LotLineCalc;

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
      OwedToConsignor        DECIMAL(18,2) NULL,
      PartNumber                  VARCHAR(MAX) NULL,
      ConsigneeName               VARCHAR(500) NULL,
      ConsigneeTypeId             INT NULL,
      ConsigneeId                 BIGINT NULL,
      RevenueConsigneePercentage  DECIMAL(18,2) NULL,
      RevenueConsignorPercent     DECIMAL(18,2) NULL,
      MarginConsigneerPercentage  DECIMAL(18,2) NULL,
      MarginConsignorPercentage   DECIMAL(18,2) NULL
    );

    INSERT INTO #LotCommissionChild
    (
      ReceiptId, BillingInvoicingId, LotId, LotNum, LotAmount, ReceivedPercent, AllocatedAmount, ConsigneePortion,
      ConsignorPortionGross, LessCogsRepair, LessFreight, LessOtherCost, DueToConsignor, PaidToConsignor, OwedToConsignor
    )
    SELECT
      LotChildSum.ReceiptId, LotChildSum.BillingInvoicingId, LotChildSum.LotId, LotChildSum.LotNumber, LotChildSum.LotAmount, LotChildSum.ReceivedPercent, LotChildSum.AllocatedAmount,
      LotChildSum.ConsigneePortion, LotChildSum.ConsignorPortionGross, LotChildSum.COGSRepair, LotChildSum.Freight, LotChildSum.OtherCost,
      LotChildSum.ConsignorPortionGross - LotChildSum.COGSRepair + LotChildSum.Freight + LotChildSum.OtherCost                       AS DueToConsignor,
      CAST(0 AS DECIMAL(18,2))                                                               AS PaidToConsignor,
      (LotChildSum.ConsignorPortionGross - LotChildSum.COGSRepair + LotChildSum.Freight + LotChildSum.OtherCost) - CAST(0 AS DECIMAL(18,2)) AS OwedToConsignor
    FROM (
      SELECT
        LotLine.ReceiptId, LotLine.BillingInvoicingId, LotLine.LotId, LotLine.LotNumber,
        SUM(ISNULL(LotLine.LineAmount,0))            AS LotAmount,
        ROUND(MAX(LotLine.ReceivedPct) * 100, 2)     AS ReceivedPercent,
        SUM(ISNULL(LotLine.AllocatedAmount,0))       AS AllocatedAmount,
        SUM(ISNULL(LotLine.ConsigneePortion,0))      AS ConsigneePortion,
        SUM(ISNULL(LotLine.ConsignorPortionGross,0)) AS ConsignorPortionGross,
        SUM(ISNULL(LotLine.COGSRepair,0))            AS COGSRepair,
        SUM(ISNULL(LotLine.Freight,0))               AS Freight,
        SUM(ISNULL(LotLine.OtherCost,0))             AS OtherCost
      FROM #LotCommissionLine LotLine
      GROUP BY LotLine.ReceiptId, LotLine.BillingInvoicingId, LotLine.LotId, LotLine.LotNumber
    ) LotChildSum;

    -- [PN-18257] LOT Other Cost entries with no stockline (IsNA): shown once per LOT, on its first row only.
    IF OBJECT_ID(N'tempdb..#LotNAOtherCost') IS NOT NULL DROP TABLE #LotNAOtherCost;
    CREATE TABLE #LotNAOtherCost
    (
      LotId      BIGINT NOT NULL PRIMARY KEY,
      Freight    DECIMAL(18,2) NULL,
      OtherCost  DECIMAL(18,2) NULL
    );

    INSERT INTO #LotNAOtherCost (LotId, Freight, OtherCost)
    SELECT LOC.LotId,
           SUM(ISNULL(LOC.UnReconciledFreight,0) + ISNULL(LOC.ManualAdjFreight,0)),
           SUM(ISNULL(LOC.UnReconciledCharges,0) + ISNULL(LOC.ManualAdjCharges,0))
    FROM dbo.LOTOtherCostDetails LOC WITH (NOLOCK)
    WHERE ISNULL(LOC.IsDeleted,0) = 0
      AND (ISNULL(LOC.IsNA,0) = 1 OR LOC.StocklineId IS NULL)
      AND (@FromDepositDt IS NULL OR CAST(LOC.PostedDate AS DATE) >= @FromDepositDt)
      AND (@ToDepositDt   IS NULL OR CAST(LOC.PostedDate AS DATE) <= @ToDepositDt)
      AND EXISTS (SELECT 1 FROM #LotCommissionChild LotChild WHERE LotChild.LotId = LOC.LotId)
    GROUP BY LOC.LotId;

    ;WITH FirstLotRow AS (
      SELECT LotChild.ReceiptId, LotChild.BillingInvoicingId, LotChild.LotId,
             ROW_NUMBER() OVER (PARTITION BY LotChild.LotId ORDER BY ReceiptInvoiceInfo.DepositDate, LotChild.ReceiptId, ReceiptInvoiceInfo.InvoiceNum, LotChild.BillingInvoicingId) AS RN
      FROM #LotCommissionChild LotChild
      OUTER APPLY (SELECT TOP 1 BaseRow.DepositDate, BaseRow.InvoiceNum FROM #LotCommissionBase BaseRow
                   WHERE BaseRow.ReceiptId = LotChild.ReceiptId AND BaseRow.BillingInvoicingId = LotChild.BillingInvoicingId) ReceiptInvoiceInfo
    )
    UPDATE LotChild SET
      LotChild.LessFreight     = ISNULL(LotChild.LessFreight,0)     + ISNULL(LotNACost.Freight,0),
      LotChild.LessOtherCost   = ISNULL(LotChild.LessOtherCost,0)   + ISNULL(LotNACost.OtherCost,0),
      LotChild.DueToConsignor  = ISNULL(LotChild.DueToConsignor,0)  + ISNULL(LotNACost.Freight,0) + ISNULL(LotNACost.OtherCost,0),
      LotChild.OwedToConsignor = ISNULL(LotChild.OwedToConsignor,0) + ISNULL(LotNACost.Freight,0) + ISNULL(LotNACost.OtherCost,0)
    FROM #LotCommissionChild LotChild
    INNER JOIN FirstLotRow FirstRow ON FirstRow.ReceiptId = LotChild.ReceiptId AND FirstRow.BillingInvoicingId = LotChild.BillingInvoicingId AND FirstRow.LotId = LotChild.LotId AND FirstRow.RN = 1
    INNER JOIN #LotNAOtherCost LotNACost ON LotNACost.LotId = LotChild.LotId;

    /*=====================================================================================
      STEP 4b : Paid to Consignor (vendor payments) - LOT level.
                Check (VendorReadyToPayDetails) -> Non PO invoice -> its lines (ReceiptId + Item = LOT Number).
                A check is spread over the invoice lines by line amount (partial payments too).
    =====================================================================================*/
    IF OBJECT_ID(N'tempdb..#LotConsignorPaid') IS NOT NULL DROP TABLE #LotConsignorPaid;
    CREATE TABLE #LotConsignorPaid
    (
      ReceiptId  BIGINT NOT NULL,
      LotNum     VARCHAR(250) NOT NULL,
      PaidAmount DECIMAL(18,2) NULL,
      PRIMARY KEY (ReceiptId, LotNum)
    );

    ;WITH NonPOInvoiceLines AS (
      SELECT NPD.NonPOInvoiceId,
             NPD.ReceiptId,
             UPPER(LTRIM(RTRIM(ISNULL(NPD.Item,''))))                                          AS LotNum,
             ISNULL(NPD.ExtendedPrice, ISNULL(NPD.Amount,0) * ISNULL(NPD.Qty,1))              AS LineAmount,
             SUM(ISNULL(NPD.ExtendedPrice, ISNULL(NPD.Amount,0) * ISNULL(NPD.Qty,1)))
                 OVER (PARTITION BY NPD.NonPOInvoiceId)                                         AS InvoiceLinesTotal
      FROM dbo.NonPOInvoicePartDetails NPD WITH (NOLOCK)
      INNER JOIN dbo.NonPOInvoiceHeader NPH WITH (NOLOCK) ON NPH.NonPOInvoiceId = NPD.NonPOInvoiceId AND ISNULL(NPH.IsDeleted,0) = 0
      WHERE ISNULL(NPD.IsDeleted,0) = 0
        AND NPD.NonPOInvoiceId IN (SELECT ReceiptLine.NonPOInvoiceId FROM dbo.NonPOInvoicePartDetails ReceiptLine WITH (NOLOCK)
                                   WHERE ReceiptLine.ReceiptId IN (SELECT DISTINCT ReceiptId FROM #LotCommissionChild))
    ),
    NonPOInvoicePaid AS (
      SELECT VRPD.NonPOInvoiceId, SUM(ISNULL(VRPD.PaymentMade,0)) AS PaidAmount
      FROM dbo.VendorReadyToPayDetails VRPD WITH (NOLOCK)
      INNER JOIN dbo.VendorReadyToPayHeader VRPH WITH (NOLOCK) ON VRPH.ReadyToPayId = VRPD.ReadyToPayId
      WHERE ISNULL(VRPD.IsGenerated,0) = 1
        AND ISNULL(VRPD.IsVoidedCheck,0) = 0
        AND ISNULL(VRPD.IsDeleted,0) = 0
        AND ISNULL(VRPH.IsDeleted,0) = 0
        AND VRPH.MasterCompanyId = @mastercompanyid
        AND (@ToDepositDt IS NULL OR CAST(VRPD.CheckDate AS DATE) <= @ToDepositDt)
        AND VRPD.NonPOInvoiceId IN (SELECT DISTINCT NonPOInvoiceId FROM NonPOInvoiceLines)
      GROUP BY VRPD.NonPOInvoiceId
    )
    INSERT INTO #LotConsignorPaid (ReceiptId, LotNum, PaidAmount)
    SELECT InvoiceLine.ReceiptId, InvoiceLine.LotNum,
           ROUND(SUM(InvoicePaid.PaidAmount * InvoiceLine.LineAmount / NULLIF(InvoiceLine.InvoiceLinesTotal,0)), 2)
    FROM NonPOInvoiceLines InvoiceLine
    INNER JOIN NonPOInvoicePaid InvoicePaid ON InvoicePaid.NonPOInvoiceId = InvoiceLine.NonPOInvoiceId
    WHERE ISNULL(InvoiceLine.ReceiptId,0) > 0 AND InvoiceLine.LotNum <> ''
    GROUP BY InvoiceLine.ReceiptId, InvoiceLine.LotNum;

    -- same Receipt + LOT on more than one child row (LOT billed on 2 invoices of one receipt):
    -- split the paid amount over those rows by their Due to Consignor (equally when Due is 0).
    ;WITH PaidTargetRows AS (
      SELECT LotChild.ReceiptId, LotChild.BillingInvoicingId, LotChild.LotId, UPPER(LTRIM(RTRIM(LotChild.LotNum))) AS LotNum,
             ISNULL(LotChild.DueToConsignor,0) AS Due,
             SUM(ISNULL(LotChild.DueToConsignor,0)) OVER (PARTITION BY LotChild.ReceiptId, UPPER(LTRIM(RTRIM(LotChild.LotNum)))) AS DueTotal,
             COUNT(1) OVER (PARTITION BY LotChild.ReceiptId, UPPER(LTRIM(RTRIM(LotChild.LotNum))))                        AS RowCnt
      FROM #LotCommissionChild LotChild
    )
    UPDATE LotChild SET
      LotChild.PaidToConsignor = ROUND(CASE WHEN PaidTarget.RowCnt = 1 OR PaidTarget.DueTotal = 0 THEN LotPaid.PaidAmount / PaidTarget.RowCnt
                                      ELSE LotPaid.PaidAmount * PaidTarget.Due / PaidTarget.DueTotal END, 2),
      LotChild.OwedToConsignor = ISNULL(LotChild.DueToConsignor,0)
                           - ROUND(CASE WHEN PaidTarget.RowCnt = 1 OR PaidTarget.DueTotal = 0 THEN LotPaid.PaidAmount / PaidTarget.RowCnt
                                        ELSE LotPaid.PaidAmount * PaidTarget.Due / PaidTarget.DueTotal END, 2)
    FROM #LotCommissionChild LotChild
    INNER JOIN PaidTargetRows PaidTarget ON PaidTarget.ReceiptId = LotChild.ReceiptId AND PaidTarget.BillingInvoicingId = LotChild.BillingInvoicingId AND PaidTarget.LotId = LotChild.LotId
    INNER JOIN #LotConsignorPaid LotPaid ON LotPaid.ReceiptId = LotChild.ReceiptId AND LotPaid.LotNum = PaidTarget.LotNum;

    -- [PN-18257] Child info columns: Part Num(s), Revenue/Margin Consignee/Consignor %, Consignee name.
    UPDATE LotChild SET
      LotChild.PartNumber                 = LotPartNumbers.PartNumbers,
      LotChild.RevenueConsigneePercentage = LotPercent.RevenueConsigneePercentage,
      LotChild.RevenueConsignorPercent    = LotPercent.RevenueConsignorPercent,
      LotChild.MarginConsigneerPercentage = LotPercent.MarginConsigneerPercentage,
      LotChild.MarginConsignorPercentage  = LotPercent.MarginConsignorPercentage
    FROM #LotCommissionChild LotChild
    OUTER APPLY (
      SELECT STRING_AGG(CAST(DistinctPart.PartNumber AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY DistinctPart.PartNumber) AS PartNumbers
      FROM (SELECT DISTINCT BaseRow.PartNumber FROM #LotCommissionBase BaseRow
            WHERE BaseRow.ReceiptId = LotChild.ReceiptId AND BaseRow.BillingInvoicingId = LotChild.BillingInvoicingId AND BaseRow.LotId = LotChild.LotId
              AND ISNULL(BaseRow.PartNumber,'') <> '') DistinctPart
    ) LotPartNumbers
    OUTER APPLY (
      SELECT MAX(BaseRow.RevenueConsigneePercentage) AS RevenueConsigneePercentage,
             MAX(BaseRow.RevenueConsignorPercent)    AS RevenueConsignorPercent,
             MAX(BaseRow.MarginConsigneerPercentage) AS MarginConsigneerPercentage,
             MAX(BaseRow.MarginConsignorPercentage)  AS MarginConsignorPercentage
      FROM #LotCommissionBase BaseRow
      WHERE BaseRow.ReceiptId = LotChild.ReceiptId AND BaseRow.BillingInvoicingId = LotChild.BillingInvoicingId AND BaseRow.LotId = LotChild.LotId
    ) LotPercent;

    -- Consignee name from the LOT's (latest active) LotConsignment: ConsigneeTypeId is a Module
    -- (Vendor / Customer / Company / Others) and ConsigneeId points to that module's record.
    DECLARE @VendorModuleId INT, @CustomerModuleId INT, @CompanyModuleId INT;
    SELECT @VendorModuleId   = ModuleId FROM dbo.Module WITH (NOLOCK) WHERE ModuleName = 'Vendor';
    SELECT @CustomerModuleId = ModuleId FROM dbo.Module WITH (NOLOCK) WHERE ModuleName = 'Customer';
    SELECT @CompanyModuleId  = ModuleId FROM dbo.Module WITH (NOLOCK) WHERE ModuleName = 'Company';

    UPDATE LotChild SET
      LotChild.ConsigneeTypeId = LatestConsignment.ConsigneeTypeId,
      LotChild.ConsigneeId     = LatestConsignment.ConsigneeId,
      LotChild.ConsigneeName = CASE
                           WHEN LatestConsignment.ConsigneeTypeId = @VendorModuleId   THEN ISNULL(ConsignorVendor.VendorName, LatestConsignment.ConsigneeName)
                           WHEN LatestConsignment.ConsigneeTypeId = @CustomerModuleId THEN ISNULL(ConsignorCustomer.[Name], LatestConsignment.ConsigneeName)
                           WHEN LatestConsignment.ConsigneeTypeId = @CompanyModuleId  THEN ISNULL(ConsignorLegalEntity.[Name], LatestConsignment.ConsigneeName)
                           ELSE LatestConsignment.ConsigneeName
                         END
    FROM #LotCommissionChild LotChild
    CROSS APPLY (
      SELECT TOP 1 LotCons.ConsigneeTypeId, LotCons.ConsigneeId, LotCons.ConsigneeName
      FROM dbo.LotConsignment LotCons WITH (NOLOCK)
      WHERE LotCons.LotId = LotChild.LotId AND ISNULL(LotCons.IsDeleted,0) = 0
      ORDER BY LotCons.ConsignmentId DESC
    ) LatestConsignment
    LEFT JOIN dbo.Vendor ConsignorVendor       WITH (NOLOCK) ON LatestConsignment.ConsigneeTypeId = @VendorModuleId   AND ConsignorVendor.VendorId        = LatestConsignment.ConsigneeId
    LEFT JOIN dbo.Customer ConsignorCustomer     WITH (NOLOCK) ON LatestConsignment.ConsigneeTypeId = @CustomerModuleId AND ConsignorCustomer.CustomerId      = LatestConsignment.ConsigneeId
    LEFT JOIN dbo.LegalEntity ConsignorLegalEntity WITH (NOLOCK) ON LatestConsignment.ConsigneeTypeId = @CompanyModuleId  AND ConsignorLegalEntity.LegalEntityId  = LatestConsignment.ConsigneeId;

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
      npoNumber              VARCHAR(MAX) NULL,
      level1                 VARCHAR(500) NULL,
      level2                 VARCHAR(500) NULL,
      level3                 VARCHAR(500) NULL,
      level4                 VARCHAR(500) NULL,
      level5                 VARCHAR(500) NULL,
      level6                 VARCHAR(500) NULL,
      level7                 VARCHAR(500) NULL,
      level8                 VARCHAR(500) NULL,
      level9                 VARCHAR(500) NULL,
      level10                VARCHAR(500) NULL,
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
      LotChild.ReceiptId, LotChild.BillingInvoicingId,
      MAX(ReceiptPay.CashReceipt),
      ROUND(MAX(ReceiptPay.ReceivedPct) * 100, 2),
      STRING_AGG(CAST(LotChild.LotNum AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY LotChild.LotNum),
      -- single LOT -> its LotId (used by "Initiate Consignor Payment"); several LOTs -> first one
      MIN(LotChild.LotId),
      SUM(LotChild.LotAmount), SUM(LotChild.AllocatedAmount), SUM(LotChild.ConsigneePortion), SUM(LotChild.ConsignorPortionGross),
      SUM(LotChild.LessCogsRepair), SUM(LotChild.LessFreight), SUM(LotChild.LessOtherCost),
      SUM(LotChild.DueToConsignor), SUM(LotChild.PaidToConsignor), SUM(LotChild.OwedToConsignor)
    FROM #LotCommissionChild LotChild
    INNER JOIN #LotCommissionPay ReceiptPay ON ReceiptPay.ReceiptId = LotChild.ReceiptId AND ReceiptPay.BillingInvoicingId = LotChild.BillingInvoicingId
    GROUP BY LotChild.ReceiptId, LotChild.BillingInvoicingId;

    -- Header info (receipt / invoice / MS levels of the first LOT) + NPO number + child JSON.
    UPDATE LotParent SET
      LotParent.ReceiptNo          = ParentHeader.ReceiptNo,
      LotParent.CashReceiptDateRaw = ParentHeader.DepositDate,
      LotParent.CustomerPaymentRef = ParentHeader.CustomerPmtReference,
      LotParent.InvoiceNum         = ParentHeader.InvoiceNum,
      LotParent.InvoiceDate        = ParentHeader.InvoiceDate,
      LotParent.InvoiceAmount      = ParentHeader.InvoiceTotal,
      LotParent.IsNonPOGenerated   = CASE WHEN NonPOInvoices.NPONumber IS NOT NULL THEN 1 ELSE 0 END,
      LotParent.level1 = ParentHeader.level1, LotParent.level2 = ParentHeader.level2, LotParent.level3 = ParentHeader.level3, LotParent.level4 = ParentHeader.level4,
      LotParent.level5 = ParentHeader.level5, LotParent.level6 = ParentHeader.level6, LotParent.level7 = ParentHeader.level7, LotParent.level8 = ParentHeader.level8, LotParent.level9 = ParentHeader.level9, LotParent.level10 = ParentHeader.level10,
      LotParent.npoNumber          = NonPOInvoices.NPONumber,
      LotParent.LotDetails         = (
        SELECT LotChild.LotId                 AS lotId,
               LotChild.LotNum                AS lotNum,
               LotChild.LotAmount             AS lotAmount,
               LotChild.ReceivedPercent       AS receivedPercent,
               LotChild.AllocatedAmount       AS allocatedAmount,
               LotChild.ConsigneePortion      AS consigneePortion,
               LotChild.ConsignorPortionGross AS consignorPortionGross,
               LotChild.LessCogsRepair        AS lessCogsRepair,
               LotChild.LessFreight           AS lessFreight,
               LotChild.LessOtherCost         AS lessOtherCost,
               LotChild.DueToConsignor        AS dueToConsignor,
               LotChild.PaidToConsignor       AS paidToConsignor,
               LotChild.OwedToConsignor       AS owedToConsignor,
               LotChild.PartNumber                 AS partNumber,
               LotChild.ConsigneeName              AS consigneeName,
               LotChild.ConsigneeTypeId            AS consigneeTypeId,
               LotChild.ConsigneeId                AS consigneeId,
               LotChild.RevenueConsigneePercentage AS revenueConsigneePercentage,
               LotChild.RevenueConsignorPercent    AS revenueConsignorPercent,
               LotChild.MarginConsigneerPercentage AS marginConsigneerPercentage,
               LotChild.MarginConsignorPercentage  AS marginConsignorPercentage
        FROM #LotCommissionChild LotChild
        WHERE LotChild.ReceiptId = LotParent.ReceiptId AND LotChild.BillingInvoicingId = LotParent.BillingInvoicingId
        ORDER BY LotChild.LotNum
        FOR JSON PATH, INCLUDE_NULL_VALUES
      )
    FROM #LotCommissionParent LotParent
    CROSS APPLY (
      SELECT TOP 1 BaseRow.ReceiptNo, BaseRow.DepositDate, BaseRow.CustomerPmtReference, BaseRow.InvoiceNum, BaseRow.InvoiceDate, BaseRow.InvoiceTotal,
                   BaseRow.IsNonPOGenerated, BaseRow.level1, BaseRow.level2, BaseRow.level3, BaseRow.level4,
                   BaseRow.level5, BaseRow.level6, BaseRow.level7, BaseRow.level8, BaseRow.level9, BaseRow.level10
      FROM #LotCommissionBase BaseRow
      WHERE BaseRow.ReceiptId = LotParent.ReceiptId AND BaseRow.BillingInvoicingId = LotParent.BillingInvoicingId
      ORDER BY BaseRow.LotNumber
    ) ParentHeader
    -- [PN-18257] Non PO invoice(s) whose lines pay this Cash Receipt (line level ReceiptId)
    OUTER APPLY (
      SELECT STRING_AGG(CAST(NPOList.NPONumber AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY NPOList.NPONumber) AS NPONumber
      FROM (
        SELECT DISTINCT NPOHeader.NPONumber
        FROM dbo.NonPOInvoicePartDetails NPOLine WITH (NOLOCK)
        INNER JOIN dbo.NonPOInvoiceHeader NPOHeader WITH (NOLOCK) ON NPOHeader.NonPOInvoiceId = NPOLine.NonPOInvoiceId
        WHERE NPOLine.ReceiptId = LotParent.ReceiptId
          AND ISNULL(NPOLine.IsDeleted,0) = 0
          AND ISNULL(NPOHeader.IsDeleted,0) = 0
      ) NPOList
    ) NonPOInvoices;

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
      level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
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
