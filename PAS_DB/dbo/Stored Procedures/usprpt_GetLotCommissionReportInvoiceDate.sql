/*************************************************************
 ** File:   [usprpt_GetLotCommissionReportInvoiceDate]
 ** Author: Kishor Makwana (AI-assisted via Claude)
 ** Description: [PN-17830] Custom Commission Setup - BAG. "Commission Payment Tracking"
 **              report (Invoice Date tab): for each cash receipt posted against a
 **              consignment Lot, apportions the cash between Consignee/Consignor per the
 **              Lot's own LotConsignment percent setup, nets the Consignor's gross portion
 **              against the Lot's COGS/Repair, Freight and Other Cost, and tracks a running
 **              Owed-to-Consignor balance. Also surfaces already-issued "Payment to Consignor"
 **              AP checks (VendorReadyToPayHeader/Details + VendorPaymentDetails) alongside the
 **              cash-receipt rows. Identical calculation/output to
 **              usprpt_GetLotCommissionReportCashPosted - the only difference is the date
 **              range filters against dbo.BillingInvoicing.InvoiceDate instead of
 **              dbo.CustomerPayments.PostedDate.
 ** Date:   03/September/2026
 ** PARAMETERS: @PageNumber, @PageSize, @mastercompanyid, @xmlFilter
 **             (Filters: "From Invoice Date", "To Invoice Date", "PN", "Invoice Num",
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
 **************************************************************
 EXEC usprpt_GetLotCommissionReportInvoiceDate @PageNumber=1,@PageSize=100,@mastercompanyid=1,@xmlFilter='<ArrayOfFilter><Filter><FieldName>From Invoice Date</FieldName><FieldValue>1/1/2026</FieldValue></Filter><Filter><FieldName>To Invoice Date</FieldName><FieldValue>9/2/2026</FieldValue></Filter></ArrayOfFilter>'
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetLotCommissionReportInvoiceDate]
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

  DECLARE @FromInvoiceDate VARCHAR(MAX) = NULL,
    @ToInvoiceDate VARCHAR(MAX) = NULL,
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
      @FromInvoiceDate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'From Invoice Date' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @FromInvoiceDate END,
      @ToInvoiceDate   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'To Invoice Date'   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToInvoiceDate END,
      @PN              = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'PN'                THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @PN END,
      @InvoiceNum      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Invoice Num'       THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @InvoiceNum END,
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

    DECLARE @FromInvoiceDt DATE = TRY_CONVERT(DATE, @FromInvoiceDate, 101);
    DECLARE @ToInvoiceDt DATE = TRY_CONVERT(DATE, @ToInvoiceDate, 101);

    DECLARE @LotModuleId INT;
    SELECT @LotModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Lot';

    DECLARE @POTransInType VARCHAR(50) = 'Trans In (PO)', @ROTransInType VARCHAR(50) = 'Trans In (RO)';

    DECLARE @SOModuleId INT = 10, @WOModuleId INT = 15;
    SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
    SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

    IF ISNULL(@PageSize,0) = 0
    BEGIN
      DECLARE @ReceiptRowCount INT, @PaymentRowCount INT;

      SELECT @ReceiptRowCount = COUNT(1)
      FROM (
        SELECT DISTINCT CP.ReceiptId, IPY.PaymentId, LT.LotId
        FROM dbo.CustomerPayments CP WITH (NOLOCK)
        INNER JOIN dbo.InvoicePayments IPY WITH (NOLOCK) ON IPY.ReceiptId = CP.ReceiptId AND ISNULL(IPY.IsDeleted,0) = 0
        INNER JOIN dbo.BillingInvoicing BI WITH (NOLOCK) ON BI.BillingInvoicingId = IPY.SOBillingInvoicingId
        INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId AND BII.ModuleId = @SOModuleId
        INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = BII.SubReferenceId
        INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = BII.ItemMasterId
        LEFT JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = SOP.LotId AND ISNULL(LT.IsDeleted,0) = 0
        LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
        WHERE LT.MasterCompanyId = @mastercompanyid
          AND ISNULL(CP.IsDeleted,0) = 0
          AND (@FromInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) >= @FromInvoiceDt)
          AND (@ToInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) <= @ToInvoiceDt)
          AND (ISNULL(@InvoiceNum,'') = '' OR BI.InvoiceNo LIKE '%' + @InvoiceNum + '%')
          AND (ISNULL(@PN,'') = '' OR BII.ItemMasterId = @PN)
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

        UNION

        SELECT DISTINCT CP.ReceiptId, IPY.PaymentId, LT.LotId
        FROM dbo.CustomerPayments CP WITH (NOLOCK)
        INNER JOIN dbo.InvoicePayments IPY WITH (NOLOCK) ON IPY.ReceiptId = CP.ReceiptId AND ISNULL(IPY.IsDeleted,0) = 0
        INNER JOIN dbo.BillingInvoicing BI WITH (NOLOCK) ON BI.BillingInvoicingId = IPY.SOBillingInvoicingId
        INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId AND BII.ModuleId = @WOModuleId
        INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = BII.ItemMasterId
        LEFT JOIN dbo.Stockline STK WITH (NOLOCK) ON STK.StockLineId = BII.StocklineId
        LEFT JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = STK.LotId AND ISNULL(LT.IsDeleted,0) = 0
        LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
        WHERE LT.MasterCompanyId = @mastercompanyid
          AND ISNULL(CP.IsDeleted,0) = 0
          AND (@FromInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) >= @FromInvoiceDt)
          AND (@ToInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) <= @ToInvoiceDt)
          AND (ISNULL(@InvoiceNum,'') = '' OR BI.InvoiceNo LIKE '%' + @InvoiceNum + '%')
          AND (ISNULL(@PN,'') = '' OR BII.ItemMasterId = @PN)
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
      ) CountX

      SELECT @PaymentRowCount = COUNT(1)
      FROM dbo.VendorReadyToPayHeader VRPH WITH (NOLOCK)
      INNER JOIN dbo.VendorReadyToPayDetails VRPD WITH (NOLOCK) ON VRPD.ReadyToPayId = VRPH.ReadyToPayId
      INNER JOIN dbo.VendorPaymentDetails VPD WITH (NOLOCK) ON VPD.VendorPaymentDetailsId = VRPD.VendorPaymentDetailsId
      WHERE ISNULL(VRPD.IsGenerated,0) = 1
        AND ISNULL(VRPD.IsVoidedCheck,0) = 0
        AND ISNULL(VRPH.IsDeleted,0) = 0
        AND VRPH.MasterCompanyId = @mastercompanyid
        AND (@FromInvoiceDt IS NULL OR CAST(VRPD.CheckDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(VRPD.CheckDate AS DATE) <= @ToInvoiceDt)

      -- [PN-17853] 04-Sep-2026: count the new "blank line" branch (LOTOtherCostDetails IsNA=1 rows) too,
      -- so @PageSize (when the caller asks for a full/auto page via @PageSize=0) isn't undercounted.
      DECLARE @NARowCount INT;
      SELECT @NARowCount = COUNT(DISTINCT LT.LotId)
      FROM dbo.LOTOtherCostDetails LOC WITH (NOLOCK)
      INNER JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = LOC.LotId AND ISNULL(LT.IsDeleted,0) = 0
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
      WHERE LT.MasterCompanyId = @mastercompanyid
        AND ISNULL(LOC.IsDeleted,0) = 0
        AND ISNULL(LOC.IsNA,0) = 1
        AND (@FromInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) <= @ToInvoiceDt)
        AND (ISNULL(@InvoiceNum,'') = '')
        AND (ISNULL(@PN,'') = '')
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

      SET @PageSize = ISNULL(@ReceiptRowCount,0) + ISNULL(@PaymentRowCount,0) + ISNULL(@NARowCount,0)
      
      SET @PageSize = CASE WHEN ISNULL(@PageSize,0) = 0 THEN 1 ELSE @PageSize END
    END
    SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

    ;WITH CashCTE AS (
      SELECT DISTINCT
        CP.ReceiptNo,
        CP.ReceiptId, IPY.PaymentId,
        CP.PostedDate AS CashReceiptDate,
        CP.Reference AS CustomerPaymentRef,
        BI.InvoiceNo AS InvoiceNum,
        LT.LotId, LT.LotNumber,
        BI.BillingInvoicingId,
        -- [PN-17853] 04-Sep-2026: new InvoiceAmount output column (FieldsMaster) - also used below to
        -- compute LessCOGSRepair's payment-percentage (Rajesh, 04-Sep-2026).
        BI.GrandTotal AS InvoiceAmount,
        IPY.PaymentAmount AS CashReceipt,
        ROUND(ISNULL(IPY.PaymentAmount,0) * ISNULL(ISNULL(CRP.PercentValue, CRMP.PercentValue),0) / 100, 2) AS ConsigneePortion,
        ROUND(ISNULL(IPY.PaymentAmount,0) * ISNULL(ISNULL(CRP1.PercentValue, CRMP1.PercentValue),0) / 100, 2) AS ConsignorPortionGross,
        CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) END AS level1,
        CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) END AS level2,
        CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) END AS level3,
        CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) END AS level4,
        IM.PartNumber AS pn
      FROM dbo.CustomerPayments CP WITH (NOLOCK)
      INNER JOIN dbo.InvoicePayments IPY WITH (NOLOCK) ON IPY.ReceiptId = CP.ReceiptId AND ISNULL(IPY.IsDeleted,0) = 0
      INNER JOIN dbo.BillingInvoicing BI WITH (NOLOCK) ON BI.BillingInvoicingId = IPY.SOBillingInvoicingId
      INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId AND BII.ModuleId = @SOModuleId
      INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = BII.SubReferenceId
      INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = BII.ItemMasterId
      LEFT JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = SOP.LotId AND ISNULL(LT.IsDeleted,0) = 0
      LEFT JOIN dbo.LotConsignment LG WITH (NOLOCK) ON LG.LotId = LT.LotId
      LEFT JOIN dbo.[Percent] CRP  WITH (NOLOCK) ON CRP.PercentId  = LG.PercentId
      LEFT JOIN dbo.[Percent] CRP1 WITH (NOLOCK) ON CRP1.PercentId = LG.ConsignorPercentId
      LEFT JOIN dbo.[Percent] CRMP  WITH (NOLOCK) ON CRMP.PercentId  = LG.MarginPercentId
      LEFT JOIN dbo.[Percent] CRMP1 WITH (NOLOCK) ON CRMP1.PercentId = LG.MarginConsignorPercentId
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
      LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
      WHERE LT.MasterCompanyId = @mastercompanyid
        AND ISNULL(CP.IsDeleted,0) = 0
        AND (@FromInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) <= @ToInvoiceDt)
        AND (ISNULL(@InvoiceNum,'') = '' OR BI.InvoiceNo LIKE '%' + @InvoiceNum + '%')
        AND (ISNULL(@PN,'') = '' OR BII.ItemMasterId = @PN)
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

      UNION

      SELECT DISTINCT
        CP.ReceiptNo,
        CP.ReceiptId, IPY.PaymentId,
        CP.PostedDate AS CashReceiptDate,
        CP.Reference AS CustomerPaymentRef,
        BI.InvoiceNo AS InvoiceNum,
        LT.LotId, LT.LotNumber,
        BI.BillingInvoicingId,
        -- [PN-17853] 04-Sep-2026: new InvoiceAmount output column (FieldsMaster) - also used below to
        -- compute LessCOGSRepair's payment-percentage (Rajesh, 04-Sep-2026).
        BI.GrandTotal AS InvoiceAmount,
        IPY.PaymentAmount AS CashReceipt,
        ROUND(ISNULL(IPY.PaymentAmount,0) * ISNULL(ISNULL(CRP.PercentValue, CRMP.PercentValue),0) / 100, 2) AS ConsigneePortion,
        ROUND(ISNULL(IPY.PaymentAmount,0) * ISNULL(ISNULL(CRP1.PercentValue, CRMP1.PercentValue),0) / 100, 2) AS ConsignorPortionGross,
        CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) END AS level1,
        CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) END AS level2,
        CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) END AS level3,
        CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) END AS level4,
        IM.PartNumber AS pn
      FROM dbo.CustomerPayments CP WITH (NOLOCK)
      INNER JOIN dbo.InvoicePayments IPY WITH (NOLOCK) ON IPY.ReceiptId = CP.ReceiptId AND ISNULL(IPY.IsDeleted,0) = 0
      INNER JOIN dbo.BillingInvoicing BI WITH (NOLOCK) ON BI.BillingInvoicingId = IPY.SOBillingInvoicingId
      INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId AND BII.ModuleId = @WOModuleId
      INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = BII.ItemMasterId
      LEFT JOIN dbo.Stockline STK WITH (NOLOCK) ON STK.StockLineId = BII.StocklineId
      LEFT JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = STK.LotId AND ISNULL(LT.IsDeleted,0) = 0
      LEFT JOIN dbo.LotConsignment LG WITH (NOLOCK) ON LG.LotId = LT.LotId
      LEFT JOIN dbo.[Percent] CRP  WITH (NOLOCK) ON CRP.PercentId  = LG.PercentId
      LEFT JOIN dbo.[Percent] CRP1 WITH (NOLOCK) ON CRP1.PercentId = LG.ConsignorPercentId
      LEFT JOIN dbo.[Percent] CRMP  WITH (NOLOCK) ON CRMP.PercentId  = LG.MarginPercentId
      LEFT JOIN dbo.[Percent] CRMP1 WITH (NOLOCK) ON CRMP1.PercentId = LG.MarginConsignorPercentId
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
      LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
      WHERE LT.MasterCompanyId = @mastercompanyid
        AND ISNULL(CP.IsDeleted,0) = 0
        AND (@FromInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(BI.InvoiceDate AS DATE) <= @ToInvoiceDt)
        AND (ISNULL(@InvoiceNum,'') = '' OR BI.InvoiceNo LIKE '%' + @InvoiceNum + '%')
        AND (ISNULL(@PN,'') = '' OR BII.ItemMasterId = @PN)
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
    ),
    CalcCTE AS (
      SELECT
        G.*,
        ROW_NUMBER() OVER (PARTITION BY G.LotId ORDER BY G.CashReceiptDate, G.ReceiptId, G.PaymentId) AS LotRowSeq,
        LotCost.LessCOGSRepair, LotCost.LessFreight, LotCost.LessOtherCost
      FROM CashCTE G
      CROSS APPLY (
        SELECT
          -- [PN-17853] 04-Sep-2026: LessCOGSRepair now prorates the invoice's own stockline UnitCost basis
          -- by how much of THIS invoice this specific cash receipt represents (CashReceipt / InvoiceAmount) -
          -- e.g. InvoiceAmount=1000, CashReceipt=600 (60% paid), stockline UnitCost sum=500 -> LessCOGSRepair
          -- = 500 * 60% = 300 (Rajesh, 04-Sep-2026). Replaces the old Lot.InitialPOCost + RepairCost basis.
          ROUND(
            ISNULL((
              SELECT SUM(ISNULL(STK2.UnitCost,0))
              FROM dbo.BillingInvoicingItems BII2 WITH (NOLOCK)
              INNER JOIN dbo.Stockline STK2 WITH (NOLOCK) ON STK2.StockLineId = BII2.StocklineId
              WHERE BII2.BillingInvoicingId = G.BillingInvoicingId AND ISNULL(BII2.IsDeleted,0) = 0
            ),0)
            * ISNULL(G.CashReceipt,0)
            / NULLIF(ISNULL(G.InvoiceAmount,0),0)
          , 2) AS LessCOGSRepair,
          -- [PN-17853] 04-Sep-2026: LessFreight/LessOtherCost now come from LOTOtherCostDetails (the Other
          -- Cost tab's manual entries), scoped to this Lot + this invoice's own stockline(s), and to the
          -- report's date range via LOTOtherCostDetails.PostedDate - replaces the old PO/RO Freight/Charges
          -- basis (Rajesh, 04-Sep-2026).
          ISNULL((
            SELECT SUM(ISNULL(LOC.UnReconciledFreight,0) + ISNULL(LOC.ManualAdjFreight,0))
            FROM dbo.LOTOtherCostDetails LOC WITH (NOLOCK)
            WHERE LOC.LotId = G.LotId
              AND ISNULL(LOC.IsDeleted,0) = 0
              AND ISNULL(LOC.IsNA,0) = 0
              AND LOC.StocklineId IN (
                SELECT BII3.StocklineId FROM dbo.BillingInvoicingItems BII3 WITH (NOLOCK)
                WHERE BII3.BillingInvoicingId = G.BillingInvoicingId AND ISNULL(BII3.IsDeleted,0) = 0 AND BII3.StocklineId IS NOT NULL
              )
              AND (@FromInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) >= @FromInvoiceDt)
              AND (@ToInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) <= @ToInvoiceDt)
          ),0) AS LessFreight,
          ISNULL((
            SELECT SUM(ISNULL(LOC.UnReconciledCharges,0) + ISNULL(LOC.ManualAdjCharges,0))
            FROM dbo.LOTOtherCostDetails LOC WITH (NOLOCK)
            WHERE LOC.LotId = G.LotId
              AND ISNULL(LOC.IsDeleted,0) = 0
              AND ISNULL(LOC.IsNA,0) = 0
              AND LOC.StocklineId IN (
                SELECT BII4.StocklineId FROM dbo.BillingInvoicingItems BII4 WITH (NOLOCK)
                WHERE BII4.BillingInvoicingId = G.BillingInvoicingId AND ISNULL(BII4.IsDeleted,0) = 0 AND BII4.StocklineId IS NOT NULL
              )
              AND (@FromInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) >= @FromInvoiceDt)
              AND (@ToInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) <= @ToInvoiceDt)
          ),0) AS LessOtherCost
      ) LotCost
    ),
    AppliedCTE AS (
      SELECT
        *,
        -- [PN-17853] 04-Sep-2026: LessCOGSRepair/LessFreight/LessOtherCost are now computed per-row as this
        -- specific payment's own proportional/date-scoped share (see the CROSS APPLY above), not a
        -- Lot-wide total - so, unlike before, they are no longer zeroed out on every row but the first for
        -- a given Lot (Rajesh, 04-Sep-2026).
        ISNULL(LessCOGSRepair,0) AS LessCOGSRepairApplied,
        ISNULL(LessFreight,0) AS LessFreightApplied,
        ISNULL(LessOtherCost,0) AS LessOtherCostApplied
      FROM CalcCTE
    ),
    DueCTE AS (
      SELECT
        *,
        (ConsignorPortionGross - LessCOGSRepairApplied - LessFreightApplied - LessOtherCostApplied) AS DueToConsignor,
        CAST(0 AS DECIMAL(18,2)) AS PaidToConsignor
      FROM AppliedCTE
    ),
    OwedCTE AS (
      SELECT *
      FROM DueCTE
    ),
    PaymentCTE AS (
      SELECT
        CAST(VRPD.ControlNumber AS VARCHAR(100)) AS ReceiptNo,
        VRPD.CheckDate AS CashReceiptDateRaw,
        CAST(VRPD.CheckNumber AS VARCHAR(100)) AS CustomerPaymentRef,
        CAST(CASE WHEN ISNULL(RRH.ReceivingReconciliationId,0) > 0 THEN RRH.InvoiceNum  WHEN ISNULL(NPIH.NonPOInvoiceId,0) > 0 THEN NPIH.InvoiceNumber ELSE '' END AS VARCHAR(100)) AS InvoiceNum,
        CAST(ISNULL(LotResolved.LotNumber,'') AS VARCHAR(100)) AS LotNumber,
        CAST(0 AS DECIMAL(20,2)) AS CashReceipt,
        CAST(0 AS DECIMAL(20,2)) AS ConsigneePortion,
        CAST(0 AS DECIMAL(20,2)) AS ConsignorPortionGross,
        CAST(0 AS DECIMAL(20,2)) AS InvoiceAmount,
        CAST(0 AS DECIMAL(20,2)) AS lessCogsRepair,
        CAST(0 AS DECIMAL(20,2)) AS lessFreight,
        CAST(0 AS DECIMAL(20,2)) AS lessOtherCost,
        CAST(0 AS DECIMAL(20,2)) AS DueToConsignor,
        -ISNULL(VRPD.PaymentMade,0) AS PaidToConsignor,
        CAST(NULL AS VARCHAR(10)) AS PaymentDate,
        CAST(NULL AS VARCHAR(100)) AS PaymentRef,
        CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) END AS level1,
        CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) END AS level2,
        CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) END AS level3,
        CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) END AS level4,
        CAST(NULL AS VARCHAR(100)) AS pn
      FROM dbo.VendorReadyToPayHeader VRPH WITH (NOLOCK)
      INNER JOIN dbo.VendorReadyToPayDetails VRPD WITH (NOLOCK) ON VRPD.ReadyToPayId = VRPH.ReadyToPayId
      INNER JOIN dbo.VendorPaymentDetails VPD WITH (NOLOCK) ON VPD.VendorPaymentDetailsId = VRPD.VendorPaymentDetailsId
      LEFT JOIN dbo.NonPOInvoiceHeader NPIH WITH (NOLOCK) ON NPIH.NonPOInvoiceId = VRPD.NonPOInvoiceId
      LEFT JOIN dbo.ReceivingReconciliationHeader RRH WITH (NOLOCK) ON RRH.ReceivingReconciliationId = VRPD.ReceivingReconciliationId
      OUTER APPLY (
        SELECT TOP 1 LT2.LotNumber, LT2.LotId, LT2.ManagementStructureId
        FROM dbo.ReceivingReconciliationDetails RRD2 WITH (NOLOCK)
        INNER JOIN dbo.Stockline STK2 WITH (NOLOCK) ON STK2.StockLineId = RRD2.StocklineId
        INNER JOIN dbo.Lot LT2 WITH (NOLOCK) ON LT2.LotId = STK2.LotId AND ISNULL(LT2.IsDeleted,0) = 0
        WHERE RRD2.ReceivingReconciliationId = RRH.ReceivingReconciliationId
        ORDER BY RRD2.ReceivingReconciliationDetailId
      ) LotResolved
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LotResolved.LotId AND MSD.EntityMSID = LotResolved.ManagementStructureId
      LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
      WHERE ISNULL(VRPD.IsGenerated,0) = 1
        AND ISNULL(VRPD.IsVoidedCheck,0) = 0
        AND ISNULL(VRPH.IsDeleted,0) = 0
        AND VRPH.MasterCompanyId = @mastercompanyid
        AND (@FromInvoiceDt IS NULL OR CAST(VRPD.CheckDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(VRPD.CheckDate AS DATE) <= @ToInvoiceDt)
        AND (
          ISNULL(@InvoiceNum,'') = ''
          OR (ISNULL(RRH.ReceivingReconciliationId,0) > 0 AND RRH.InvoiceNum LIKE '%' + @InvoiceNum + '%')
          OR (ISNULL(NPIH.NonPOInvoiceId,0) > 0 AND NPIH.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
        )
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
    ),
    -- [PN-17853] 04-Sep-2026: "blank line" branch - one row per Lot with LOTOtherCostDetails IsNA=1
    -- (Other Cost entries with no Part/Stockline) rows in the report's date range, showing only
    -- lessFreight/lessOtherCost (everything else blank/zero) (Rajesh, 04-Sep-2026: "need to display
    -- LessFreight and LessOtherCost with single blank line just only Freight and Charges"). Excluded
    -- when @InvoiceNum/@PN are filtered, since an IsNA row has neither.
    NACTE AS (
      SELECT
        CAST(NULL AS VARCHAR(100)) AS ReceiptNo,
        CAST(NULL AS DATETIME2(7)) AS CashReceiptDateRaw,
        CAST(NULL AS VARCHAR(100)) AS CustomerPaymentRef,
        CAST(NULL AS VARCHAR(100)) AS InvoiceNum,
        LT.LotNumber AS LOTNum,
        CAST(0 AS DECIMAL(20,2)) AS CashReceipt,
        CAST(0 AS DECIMAL(20,2)) AS ConsigneePortion,
        CAST(0 AS DECIMAL(20,2)) AS ConsignorPortionGross,
        CAST(0 AS DECIMAL(20,2)) AS InvoiceAmount,
        CAST(0 AS DECIMAL(20,2)) AS lessCogsRepair,
        SUM(ISNULL(LOC.UnReconciledFreight,0) + ISNULL(LOC.ManualAdjFreight,0)) AS lessFreight,
        SUM(ISNULL(LOC.UnReconciledCharges,0) + ISNULL(LOC.ManualAdjCharges,0)) AS lessOtherCost,
        -SUM(ISNULL(LOC.UnReconciledFreight,0) + ISNULL(LOC.ManualAdjFreight,0)
             + ISNULL(LOC.UnReconciledCharges,0) + ISNULL(LOC.ManualAdjCharges,0)) AS DueToConsignor,
        CAST(0 AS DECIMAL(18,2)) AS PaidToConsignor,
        CAST(NULL AS VARCHAR(10)) AS PaymentDate,
        CAST(NULL AS VARCHAR(100)) AS PaymentRef,
        CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) END AS level1,
        CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) END AS level2,
        CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) END AS level3,
        CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) END AS level4,
        CAST(NULL AS VARCHAR(100)) AS pn,
        CAST(NULL AS BIGINT) AS ReceiptId
      FROM dbo.LOTOtherCostDetails LOC WITH (NOLOCK)
      INNER JOIN dbo.Lot LT WITH (NOLOCK) ON LT.LotId = LOC.LotId AND ISNULL(LT.IsDeleted,0) = 0
      LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @LotModuleId AND MSD.ReferenceID = LT.LotId AND MSD.EntityMSID = LT.ManagementStructureId
      LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
      LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
      WHERE LT.MasterCompanyId = @mastercompanyid
        AND ISNULL(LOC.IsDeleted,0) = 0
        AND ISNULL(LOC.IsNA,0) = 1
        AND (@FromInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(LOC.PostedDate AS DATE) <= @ToInvoiceDt)
        AND (ISNULL(@InvoiceNum,'') = '')
        AND (ISNULL(@PN,'') = '')
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
      GROUP BY LT.LotNumber, MSD.Level1Name, MSD.Level2Name, MSD.Level3Name, MSD.Level4Name,
        MSL1.Code, MSL1.[Description], MSL2.Code, MSL2.[Description], MSL3.Code, MSL3.[Description], MSL4.Code, MSL4.[Description]
    ),
    AllRowsCTE AS (
      SELECT
        ReceiptNo,
        CashReceiptDate AS CashReceiptDateRaw,
        CustomerPaymentRef,
        InvoiceNum,
        LotNumber AS LOTNum,
        CashReceipt,
        ConsigneePortion,
        ConsignorPortionGross,
        InvoiceAmount,
        LessCOGSRepairApplied AS lessCogsRepair,
        LessFreightApplied AS lessFreight,
        LessOtherCostApplied AS lessOtherCost,
        DueToConsignor,
        PaidToConsignor,
        CAST(NULL AS VARCHAR(10)) AS PaymentDate,
        CAST(NULL AS VARCHAR(100)) AS PaymentRef,
        level1, level2, level3, level4, pn,
        ReceiptId
      FROM OwedCTE

      UNION ALL

      SELECT
        ReceiptNo,
        CashReceiptDateRaw,
        CustomerPaymentRef,
        InvoiceNum,
        LotNumber AS LOTNum,
        CashReceipt,
        ConsigneePortion,
        ConsignorPortionGross,
        InvoiceAmount,
        lessCogsRepair,
        lessFreight,
        lessOtherCost,
        DueToConsignor,
        PaidToConsignor,
        PaymentDate,
        PaymentRef,
        level1, level2, level3, level4, pn,
        CAST(NULL AS BIGINT) AS ReceiptId
      FROM PaymentCTE

      UNION ALL

      SELECT
        ReceiptNo,
        CashReceiptDateRaw,
        CustomerPaymentRef,
        InvoiceNum,
        LOTNum,
        CashReceipt,
        ConsigneePortion,
        ConsignorPortionGross,
        InvoiceAmount,
        lessCogsRepair,
        lessFreight,
        lessOtherCost,
        DueToConsignor,
        PaidToConsignor,
        PaymentDate,
        PaymentRef,
        level1, level2, level3, level4, pn,
        ReceiptId
      FROM NACTE
    ),
    RunningBalanceCTE AS (
      SELECT
        *,
        (DueToConsignor + PaidToConsignor) AS OwedToConsignor
      FROM AllRowsCTE
    )
    SELECT
      COUNT(1) OVER () AS TotalRecordsCount,
      SUM(DueToConsignor) OVER () AS TotalDueToConsignor,
      SUM(PaidToConsignor) OVER () AS TotalPaidToConsignor,
      SUM(DueToConsignor + PaidToConsignor) OVER () AS TotalOwedToConsignor,
      ReceiptNo,
      FORMAT(CashReceiptDateRaw, 'MM-dd-yyyy') AS CashReceiptDate,
      CustomerPaymentRef,
      InvoiceNum,
      LOTNum,
      CashReceipt,
      ConsigneePortion,
      ConsignorPortionGross,
      InvoiceAmount,
      lessCogsRepair,
      lessFreight,
      lessOtherCost,
      DueToConsignor,
      PaidToConsignor,
      OwedToConsignor,
      PaymentDate,
      PaymentRef,
      level1, level2, level3, level4, pn
    FROM RunningBalanceCTE
    ORDER BY
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CashReceiptDate')  THEN CashReceiptDateRaw END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CashReceiptDate')  THEN CashReceiptDateRaw END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'LOTNum')           THEN LOTNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LOTNum')           THEN LOTNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'InvoiceNum')       THEN InvoiceNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'InvoiceNum')       THEN InvoiceNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'DueToConsignor')   THEN DueToConsignor END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'DueToConsignor')   THEN DueToConsignor END DESC,
      CashReceiptDateRaw ASC, ReceiptId ASC
    OFFSET ((@PageNumber - 1) * @PageSize) ROWS
    FETCH NEXT @PageSize ROWS ONLY;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
      @DatabaseName VARCHAR(100) = DB_NAME()
      -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
      ,@AdhocComments VARCHAR(150) = '[usprpt_GetLotCommissionReportInvoiceDate]'
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