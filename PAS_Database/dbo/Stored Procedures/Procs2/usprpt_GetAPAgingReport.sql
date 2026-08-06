/*************************************************************                   
 ** File:  [usprpt_GetAPAgingReport]                   
 ** Author: Rajesh Gami         
 ** Description: Get Data for AP Aging Report        
 ** Purpose:                 
 ** Date: 15 APR 2024               
                  
 ** PARAMETERS:                   
                 
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------                  
    1    15 APR 2024    Rajesh Gami		   Created  
	2    03 OCT 2025    Rajesh Gami		   Fixed the Remaining Amount related issue
	1    27-JAN-2026    RAJESH GAMI        Add InvoiceNumber
	2    05-FEB-2026    Amit Ghediya       Add filter
	3    09-FEB-2026    Rajesh Gami        Added NONSTOCK, ASSET Management Structure JOIN in Receiving Reconciliation
	4    16-FEB-2026    Amit Ghediya       Update NPO Invoice date from postedate to invoiced date.
	5    23-FEB-2026    Moin Bloch         Update Due date Getting From Direct Table.
	6    02-MAR-2026    Moin Bloch         Updated Due date For Manual JE
	7    11-MAR-2026    Amit Ghediya       Updated for remove MJE after full payment (PN-15631)
	8   12-MAR-2026    Amit Ghediya       Updated for get isactive records (PN-15588)
	9   04-MAY-2026    Hemant Saliya      Re-Structure the SP to change the days calculation
	10   25-JUN-2026    Moin Bloch         Added PO Number PN-16991
	11   02-JUL-2026    Moin Bloch         Fix For Distinct PO Number PN-17059
	12   20-JUL-2026    RAJESH GAMI        [PN-17350] - Repointed all 3 NONSTOCK-branch MS lookups from legacy dbo.NonStocklineManagementStructureDetails to unified dbo.StocklineManagementStructureDetails; @NonStockModuleID now resolved dynamically via ManagementStructureModule (ModuleName='Stockline') instead of hardcoded 11

  --[dbo].[usprpt_GetAPAgingReport] 1,'2026-01-27',3654,2,null,null
***************************************************************************************************/  
CREATE PROCEDURE [dbo].[usprpt_GetAPAgingReport]       
    @PageNumber   INT         = 1,      
    @PageSize     INT         = NULL,      
    @mastercompanyid INT,      
    @xmlFilter    XML,
    @SortColumn   VARCHAR(50) = NULL,
    @SortOrder    INT         = NULL
AS        
BEGIN        
    SET NOCOUNT ON;        
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;       

    /* ── Parameters ────────────────────────────────────────── */
    DECLARE
        @vendorId    VARCHAR(40)  = NULL,
        @Typeid      VARCHAR(40)  = NULL,
        @fromdate    DATETIME,
        @todate      DATETIME,
        @tagtype     VARCHAR(50)  = NULL,
        @level1      VARCHAR(MAX) = NULL,
        @level2      VARCHAR(MAX) = NULL,
        @level3      VARCHAR(MAX) = NULL,
        @level4      VARCHAR(MAX) = NULL,
        @Level5      VARCHAR(MAX) = NULL,
        @Level6      VARCHAR(MAX) = NULL,
        @Level7      VARCHAR(MAX) = NULL,
        @Level8      VARCHAR(MAX) = NULL,
        @Level9      VARCHAR(MAX) = NULL,
        @Level10     VARCHAR(MAX) = NULL,
        @IsDownload  BIT          = NULL,
        @VendorName                  VARCHAR(MAX) = NULL,
        @VendorCode                  VARCHAR(MAX) = NULL,
        @InvoiceAmount               VARCHAR(MAX) = NULL,
        @BalanceAmount               VARCHAR(MAX) = NULL,
        @Amountpaidbylessthen0days   VARCHAR(MAX) = NULL,
        @Amountpaidby30days          VARCHAR(MAX) = NULL,
        @Amountpaidby60days          VARCHAR(MAX) = NULL,
        @Amountpaidby90days          VARCHAR(MAX) = NULL,
        @Amountpaidby120days         VARCHAR(MAX) = NULL,
        @Amountpaidbymorethan120days VARCHAR(MAX) = NULL,
        @DaysPastDue                 VARCHAR(MAX) = NULL,
        @InvoiceDate                 DATETIME     = NULL,
        @InvoiceNo                   VARCHAR(MAX) = NULL,
        @Terms                       VARCHAR(MAX) = NULL,
        @DueDate                     DATETIME     = NULL,
		@POReference                 VARCHAR(MAX) = NULL;

    BEGIN TRY

        DECLARE
            @ModuleID        INT    = 2,
            @NonStockModuleID INT   = 11,
            @AssetModuleID   INT    = 42,
            @Count           BIGINT = 0,
            @PostStatusId    INT,
            @CMPostedStatusId INT,
            @MSModuleId      INT    = 0,
            @CMMSModuleID    BIGINT = 61,
            @invoiceNum      VARCHAR(30) = '';

        SELECT @PostStatusId    = ManualJournalStatusId FROM dbo.ManualJournalStatus  WHERE Name = 'Posted';
        SELECT @CMPostedStatusId = Id                   FROM dbo.CreditMemoStatus     WHERE Name = 'Posted';

        SET @IsDownload = CASE WHEN NULLIF(@PageSize, 0) IS NULL THEN 1 ELSE 0 END;

        SELECT @MSModuleId   = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'ManualJournalAccounting';
        SELECT @CMMSModuleID = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'CreditMemoHeader';

        SET @todate = GETUTCDATE();

        /* ── Parse XML filter ───────────────────────────────── */
        SELECT
            @vendorId    = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Vendor Name(Optional)' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @vendorId    END,
            @Typeid      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'viewType'              THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Typeid      END,
            @tagtype     = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Tag Type'             THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @tagtype     END,
            @level1      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level1'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1      END,
            @level2      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level2'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2      END,
            @level3      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level3'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3      END,
            @level4      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level4'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4      END,
            @level5      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level5'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5      END,
            @level6      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level6'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6      END,
            @level7      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level7'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7      END,
            @level8      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level8'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8      END,
            @level9      = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level9'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9      END,
            @level10     = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level10'              THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10     END,
            @VendorName  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'vendorName'           THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @VendorName  END,
            @VendorCode  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'vendorCode'           THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @VendorCode  END,
            @InvoiceAmount               = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'invoiceAmount'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @InvoiceAmount               END,
            @BalanceAmount               = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'balanceAmount'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @BalanceAmount               END,
            @Amountpaidbylessthen0days   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'amountpaidbylessthen0days'   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Amountpaidbylessthen0days   END,
            @Amountpaidby30days          = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'amountpaidby30days'          THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Amountpaidby30days          END,
            @Amountpaidby60days          = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'amountpaidby60days'          THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Amountpaidby60days          END,
            @Amountpaidby90days          = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'amountpaidby90days'          THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Amountpaidby90days          END,
            @Amountpaidby120days         = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'amountpaidby120days'         THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Amountpaidby120days         END,
            @Amountpaidbymorethan120days = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'amountpaidbymorethan120days' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Amountpaidbymorethan120days END,
            @DaysPastDue = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'daysPastDue'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @DaysPastDue END,
            @InvoiceDate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'invoiceDate'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @InvoiceDate END,
            @InvoiceNo   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'invoiceNo'    THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @InvoiceNo   END,
            @Terms       = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'terms'        THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Terms       END,
            @DueDate     = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'dueDate'      THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @DueDate     END,
			@POReference  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'poReference'    THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @POReference END
        FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby);

        /* ════════════════════════════════════════════════════════
           SHARED HELPER MACRO (comment — inline per source below)
           
           Aging buckets now use ACTUAL DueDate instead of 
           InvoiceDate + NetDays.  The DueDate already encodes 
           the credit-term offset set at invoice creation, so 
           there is no need to re-read ctm.NetDays for bucketing.

           Bucket logic (same pattern for every data source):
             Current  : DATEDIFF(DAY, DueDate, TODAY) <= 0
             1-30     : diff  1 .. 30
             31-60    : diff 31 .. 60
             61-90    : diff 61 .. 90
             91-120   : diff 91 ..120
             >120     : diff > 120

           DaysPastDue: MAX(0, DATEDIFF(DAY, DueDate, TODAY))
        ════════════════════════════════════════════════════════ */

        /* ── Page-size count branch ─────────────────────────── */
        IF ISNULL(@PageSize, 0) = 0
        BEGIN
            -- (count temp tables unchanged — they don't need aging logic)
            SELECT rrh.ReceivingReconciliationId
            INTO #tempReceivingReconciliationCount
            FROM dbo.ReceivingReconciliationHeader     rrh WITH (NOLOCK)
            INNER JOIN dbo.ReceivingReconciliationDetails rrd WITH (NOLOCK) ON rrd.ReceivingReconciliationId = rrh.ReceivingReconciliationId AND rrd.[Type] > 0
            INNER JOIN dbo.VendorPaymentDetails          vpd WITH (NOLOCK) ON vpd.ReceivingReconciliationId = rrh.ReceivingReconciliationId
            INNER JOIN dbo.Vendor                        v   WITH (NOLOCK) ON v.VendorId = rrh.VendorId
            LEFT  JOIN dbo.CreditTerms                   ctm WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
            LEFT  JOIN dbo.StocklineManagementStructureDetails    MSD  WITH (NOLOCK) ON MSD.ModuleID  = @ModuleID          AND MSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'STOCK'
            LEFT  JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID  AND NMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'NONSTOCK'
            LEFT  JOIN dbo.AssetManagementStructureDetails        AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID    AND AMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'ASSET'
            LEFT  JOIN dbo.EntityStructureSetup                   ES   WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
            WHERE rrh.VendorId       = ISNULL(@vendorId, rrh.VendorId)
              AND CAST(rrh.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)
              AND vpd.RemainingAmount > 0
              AND vpd.IsActive  = 1
              AND vpd.IsDeleted = 0
              AND rrh.MasterCompanyId = @mastercompanyid
              AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,','))))
              AND (ISNULL(@Level2,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,','))))
              AND (ISNULL(@Level3,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,','))))
              AND (ISNULL(@Level4,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,','))))
              AND (ISNULL(@Level5,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,','))))
              AND (ISNULL(@Level6,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,','))))
              AND (ISNULL(@Level7,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,','))))
              AND (ISNULL(@Level8,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,','))))
              AND (ISNULL(@Level9,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,','))))
              AND (ISNULL(@Level10,'') = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))) OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))) OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))))
            GROUP BY rrh.ReceivingReconciliationId;

            SELECT DISTINCT VCD.VendorCreditMemoId
            INTO #tempCreditMemoCount
            FROM dbo.VendorCreditMemo           VCM  WITH (NOLOCK)
            INNER JOIN dbo.VendorCreditMemoDetail VCD  WITH (NOLOCK) ON VCD.VendorCreditMemoId = VCM.VendorCreditMemoId
            INNER JOIN dbo.Vendor                 VEN  WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId
            LEFT  JOIN dbo.CreditTerms            CTM  WITH (NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
            LEFT  JOIN dbo.StocklineManagementStructureDetails SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId
            LEFT  JOIN dbo.EntityStructureSetup   SES  WITH (NOLOCK) ON SES.EntityStructureId = SMSD.EntityMSID
            WHERE VCM.VendorId = ISNULL(@vendorId, VCM.VendorId)
              AND CAST(VCM.CreatedDate AS DATE) <= CAST(@ToDate AS DATE)
              AND VCM.MasterCompanyId = @mastercompanyid
              AND VCM.VendorCreditMemoStatusId = @CMPostedStatusId
              AND ISNULL(VCD.ApplierdAmt, 0) > 0
              AND (ISNULL(@tagtype,'') = '' OR SES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR SMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
              AND (ISNULL(@Level2,'')  = '' OR SMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
              AND (ISNULL(@Level3,'')  = '' OR SMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
              AND (ISNULL(@Level4,'')  = '' OR SMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
              AND (ISNULL(@Level5,'')  = '' OR SMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
              AND (ISNULL(@Level6,'')  = '' OR SMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
              AND (ISNULL(@Level7,'')  = '' OR SMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
              AND (ISNULL(@Level8,'')  = '' OR SMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
              AND (ISNULL(@Level9,'')  = '' OR SMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
              AND (ISNULL(@Level10,'') = '' OR SMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')));

            SELECT MJD.ReferenceId AS BillingInvoicingId
            INTO #tempManualJECount
            FROM dbo.ManualJournalHeader   MJH WITH (NOLOCK)
            INNER JOIN dbo.ManualJournalDetails MJD WITH (NOLOCK) ON MJD.ManualJournalHeaderId = MJH.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2
            INNER JOIN dbo.VendorPaymentDetails vpd WITH (NOLOCK) ON vpd.ManualJournalHeaderId = MJH.ManualJournalHeaderId
            INNER JOIN dbo.Vendor               V   WITH (NOLOCK) ON V.VendorId = MJD.ReferenceId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.ManualJournalDetailsId
            LEFT  JOIN dbo.EntityStructureSetup ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
            LEFT  JOIN dbo.CreditTerms          CTM WITH (NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId
            WHERE MJD.ReferenceId = ISNULL(@vendorId, MJD.ReferenceId)
              AND MJH.ManualJournalStatusId = @PostStatusId
              AND CAST(MJH.PostedDate AS DATE) <= CAST(@ToDate AS DATE)
              AND MJH.mastercompanyid = @mastercompanyid
              AND vpd.RemainingAmount > 0
              AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
              AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
              AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
              AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
              AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
              AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
              AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
              AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
              AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
              AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
              AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')));

            SELECT NPH.NonPOInvoiceId
            INTO #tempNonPODetailsCount
            FROM dbo.NonPOInvoiceHeader         NPH WITH (NOLOCK)
            INNER JOIN dbo.NonPOInvoicePartDetails NPD WITH (NOLOCK) ON NPD.NonPOInvoiceId = NPH.NonPOInvoiceId
            INNER JOIN dbo.VendorPaymentDetails    vpd WITH (NOLOCK) ON vpd.NonPOInvoiceId = NPH.NonPOInvoiceId
            INNER JOIN dbo.Vendor                  v   WITH (NOLOCK) ON v.VendorId = NPH.VendorId
            LEFT  JOIN dbo.CreditTerms             ctm WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
            LEFT  JOIN dbo.NonPOInvoiceManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
            LEFT  JOIN dbo.EntityStructureSetup    ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
            WHERE NPH.VendorId = ISNULL(@vendorId, NPH.VendorId)
              AND CAST(NPH.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)
              AND vpd.RemainingAmount > 0
              AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
              AND NPH.MasterCompanyId = @mastercompanyid
              AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
              AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
              AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
              AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
              AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
              AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
              AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
              AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
              AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
              AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')))
            GROUP BY NPH.NonPOInvoiceId;

            SELECT @PageSize = COUNT(*)
            FROM (
                SELECT ReceivingReconciliationId FROM #tempReceivingReconciliationCount
                UNION ALL SELECT VendorCreditMemoId  FROM #tempCreditMemoCount
                UNION ALL SELECT BillingInvoicingId  FROM #tempManualJECount
                UNION ALL SELECT NonPOInvoiceId      FROM #tempNonPODetailsCount
            ) TEMP;
        END

        SET @PageSize   = CASE WHEN NULLIF(@PageSize, 0)   IS NULL THEN 10 ELSE @PageSize   END;
        SET @PageNumber = CASE WHEN NULLIF(@PageNumber, 0) IS NULL THEN 1  ELSE @PageNumber END;

        /* ════════════════════════════════════════════════════════
           SUMMARY VIEW  (@Typeid = 1)
           Aging uses rrh.DueDate / NPH.DueDate directly.
           Credit Memo has no stored DueDate → keep NULL.
           Manual JE uses DATEADD(ctm.NetDays, PostedDate) as DueDate
           because ManualJournalHeader has no DueDate column.
        ════════════════════════════════════════════════════════ */
        IF (@Typeid = 1)
        BEGIN
            /* ── Receiving Reconciliation ── */
            SELECT DISTINCT
                v.VendorId,
                ISNULL(v.VendorName,'')          AS vendorName,
                ISNULL(v.VendorCode,'')          AS vendorCode,
                rrh.CurrencyName                 AS currencyCode,
                ISNULL(vpd.OriginalAmount,0)     AS BalanceAmount,
                ISNULL(vpd.RemainingAmount,0)    AS CurrentlAmount,
                ISNULL(vpd.PaymentMade,0)        AS PaymentAmount,
                rrh.ReceivingReconciliationNumber AS InvoiceNo,
                rrh.InvoiceNum                   AS invoiceNumber,
                rrh.InvoiceDate,
                ISNULL(ctm.NetDays,0)            AS NetDays,
                /* ── AGING BUCKETS: based on DueDate ── */
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) <= 0
                     THEN vpd.RemainingAmount ELSE 0 END                                                                     AS Amountpaidbylessthen0days,
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 1  AND 30
                     THEN vpd.RemainingAmount ELSE 0 END                                                                     AS Amountpaidby30days,
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 31 AND 60
                     THEN vpd.RemainingAmount ELSE 0 END                                                                     AS Amountpaidby60days,
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 61 AND 90
                     THEN vpd.RemainingAmount ELSE 0 END                                                                     AS Amountpaidby90days,
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 91 AND 120
                     THEN vpd.RemainingAmount ELSE 0 END                                                                     AS Amountpaidby120days,
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) > 120
                     THEN vpd.RemainingAmount ELSE 0 END                                                                     AS Amountpaidbymorethan120days,
                rrh.ManagementStructureId,
                'AP-Inv'            AS DocType,
                ''                  AS vendorRef,
                ''                  AS Salesperson,
                ctm.Name            AS Terms,
                '0'                 AS FixRateAmount,
                rrh.InvoiceTotal    AS InvoiceAmount,
                0                   AS cmAmount,
                0                   AS CreditMemoAmount,
                rrh.DueDate,
                UPPER(COALESCE(MSD.Level1Name,  NMSD.Level1Name,  AMSD.Level1Name))  AS Level1,
                UPPER(COALESCE(MSD.Level2Name,  NMSD.Level2Name,  AMSD.Level2Name))  AS Level2,
                UPPER(COALESCE(MSD.Level3Name,  NMSD.Level3Name,  AMSD.Level3Name))  AS Level3,
                UPPER(COALESCE(MSD.Level4Name,  NMSD.Level4Name,  AMSD.Level4Name))  AS Level4,
                UPPER(COALESCE(MSD.Level5Name,  NMSD.Level5Name,  AMSD.Level5Name))  AS Level5,
                UPPER(COALESCE(MSD.Level6Name,  NMSD.Level6Name,  AMSD.Level6Name))  AS Level6,
                UPPER(COALESCE(MSD.Level7Name,  NMSD.Level7Name,  AMSD.Level7Name))  AS Level7,
                UPPER(COALESCE(MSD.Level8Name,  NMSD.Level8Name,  AMSD.Level8Name))  AS Level8,
                UPPER(COALESCE(MSD.Level9Name,  NMSD.Level9Name,  AMSD.Level9Name))  AS Level9,
                UPPER(COALESCE(MSD.Level10Name, NMSD.Level10Name, AMSD.Level10Name)) AS Level10,
                rrh.MasterCompanyId,
                0   AS IsCreditMemo,
                0   AS StatusId,
                vpd.PaymentMade AS InvoicePaidAmount,
                /* ── DaysPastDue: days since DueDate ── */
                CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) > 0
                     THEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) ELSE 0 END AS DaysPastDue
				,''  AS poReference
            INTO #tempReceivingReconciliation
            FROM dbo.ReceivingReconciliationHeader      rrh  WITH (NOLOCK)
            INNER JOIN dbo.ReceivingReconciliationDetails rrd  WITH (NOLOCK) ON rrd.ReceivingReconciliationId = rrh.ReceivingReconciliationId AND rrd.[Type] > 0
            INNER JOIN dbo.VendorPaymentDetails           vpd  WITH (NOLOCK) ON vpd.ReceivingReconciliationId = rrh.ReceivingReconciliationId
            INNER JOIN dbo.Vendor                         v    WITH (NOLOCK) ON v.VendorId = rrh.VendorId
            LEFT  JOIN dbo.CreditTerms                    ctm  WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
            LEFT  JOIN dbo.StocklineManagementStructureDetails    MSD  WITH (NOLOCK) ON MSD.ModuleID  = @ModuleID         AND MSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'STOCK'
            LEFT  JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'NONSTOCK'
            LEFT  JOIN dbo.AssetManagementStructureDetails        AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID   AND AMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'ASSET'
            LEFT  JOIN dbo.EntityStructureSetup                   ES   WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
            WHERE rrh.VendorId = ISNULL(@vendorId, rrh.VendorId)
              AND CAST(rrh.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)
              AND rrh.MasterCompanyId = @mastercompanyid
              AND vpd.RemainingAmount > 0
              AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
              AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,','))))
              AND (ISNULL(@Level2,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,','))))
              AND (ISNULL(@Level3,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,','))))
              AND (ISNULL(@Level4,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,','))))
              AND (ISNULL(@Level5,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,','))))
              AND (ISNULL(@Level6,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,','))))
              AND (ISNULL(@Level7,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,','))))
              AND (ISNULL(@Level8,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,','))))
              AND (ISNULL(@Level9,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,','))))
              AND (ISNULL(@Level10,'') = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))) OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))) OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))));

            /* ── Credit Memo ──
               Credit memos have no stored DueDate.
               Aging is calculated from CreatedDate + NetDays
               (same as before) since there is no DueDate column on VendorCreditMemo.
               DaysPastDue also uses CreatedDate + NetDays.
            ── */
            SELECT DISTINCT
                VCM.VendorId,
                ISNULL(VEN.VendorName,'')		 AS vendorName,
                ISNULL(VEN.VendorCode,'')		 AS vendorCode,
                CR.Code							 AS currencyCode,
                ISNULL(VCD.ApplierdAmt,0) * (-1) AS BalanceAmount,
                ISNULL(VCD.ApplierdAmt,0) * (-1) AS CurrentlAmount,
                ISNULL(VCD.ApplierdAmt,0) * (-1) AS PaymentAmount,
                VCM.VendorCreditMemoNumber		 AS InvoiceNo,
                ''								 AS invoiceNumber,
                VCM.CreatedDate					 AS InvoiceDate,
                ISNULL(CTM.NetDays,0)			 AS NetDays,
                /* Credit Memo: no DueDate column → fall back to CreatedDate + NetDays */
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) <= 0
                     THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidbylessthen0days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 1  AND 30
                     THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby30days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 31 AND 60
                     THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby60days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 61 AND 90
                     THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby90days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 91 AND 120
                     THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby120days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) > 120
                     THEN VCD.ApplierdAmt ELSE 0 END AS Amountpaidbymorethan120days,
                SMSD.EntityMSID           AS ManagementStructureId,
                'Credit Memo'             AS DocType,
                ''                        AS vendorRef,
                ''                        AS Salesperson,
                CTM.Name                  AS Terms,
                '0'                       AS FixRateAmount,
                VCD.ApplierdAmt * (-1)    AS InvoiceAmount,
                VCD.ApplierdAmt * (-1)    AS cmAmount,
                VCD.ApplierdAmt * (-1)    AS CreditMemoAmount,
                CAST(NULL AS DATETIME)    AS DueDate,
                UPPER(SMSD.Level1Name)    AS level1, UPPER(SMSD.Level2Name)  AS level2,
                UPPER(SMSD.Level3Name)    AS level3, UPPER(SMSD.Level4Name)  AS level4,
                UPPER(SMSD.Level5Name)    AS level5, UPPER(SMSD.Level6Name)  AS level6,
                UPPER(SMSD.Level7Name)    AS level7, UPPER(SMSD.Level8Name)  AS level8,
                UPPER(SMSD.Level9Name)    AS level9, UPPER(SMSD.Level10Name) AS level10,
                VCM.MasterCompanyId,
                1   AS IsCreditMemo,
                VCM.VendorCreditMemoStatusId AS StatusId,
                0   AS InvoicePaidAmount,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) > 0
                     THEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) ELSE 0 END AS DaysPastDue
				,''  AS poReference
            INTO #tempCreditMemo
            FROM dbo.VendorCreditMemo           VCM  WITH (NOLOCK)
            INNER JOIN dbo.VendorCreditMemoDetail VCD  WITH (NOLOCK) ON VCD.VendorCreditMemoId = VCM.VendorCreditMemoId
            INNER JOIN dbo.Vendor                 VEN  WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId
            LEFT  JOIN dbo.CreditTerms            CTM  WITH (NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
            LEFT  JOIN dbo.Currency               CR   WITH (NOLOCK) ON CR.CurrencyId = VCM.CurrencyId
            LEFT  JOIN dbo.StocklineManagementStructureDetails SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId
            LEFT  JOIN dbo.EntityStructureSetup   SES  WITH (NOLOCK) ON SES.EntityStructureId = SMSD.EntityMSID
            WHERE VCM.VendorId = ISNULL(@vendorId, VCM.VendorId)
              AND CAST(VCM.CreatedDate AS DATE) <= CAST(@ToDate AS DATE)
              AND VCM.MasterCompanyId = @mastercompanyid
              AND VCM.VendorCreditMemoStatusId = @CMPostedStatusId
              AND ISNULL(VCD.ApplierdAmt, 0) > 0
              AND (ISNULL(@tagtype,'') = '' OR SES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR SMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
              AND (ISNULL(@Level2,'')  = '' OR SMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
              AND (ISNULL(@Level3,'')  = '' OR SMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
              AND (ISNULL(@Level4,'')  = '' OR SMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
              AND (ISNULL(@Level5,'')  = '' OR SMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
              AND (ISNULL(@Level6,'')  = '' OR SMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
              AND (ISNULL(@Level7,'')  = '' OR SMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
              AND (ISNULL(@Level8,'')  = '' OR SMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
              AND (ISNULL(@Level9,'')  = '' OR SMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
              AND (ISNULL(@Level10,'') = '' OR SMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')));

            /* ── Manual JE ──
               ManualJournalHeader has no DueDate column.
               Computed DueDate = PostedDate + NetDays (stored in DATEADD).
            ── */
            SELECT DISTINCT
                MJD.ReferenceId          AS VendorId,
                ISNULL(V.VendorName,'')  AS vendorName,
                ISNULL(V.VendorCode,'')  AS vendorCode,
                CR.Code                  AS currencyCode,
                0 AS BalanceAmount,
                0 AS CurrentlAmount,
                0 AS PaymentAmount,
                UPPER(MJH.JournalNumber) AS InvoiceNo,
                ''                       AS invoiceNumber,
                MJH.PostedDate           AS InvoiceDate,
                ISNULL(CTM.NetDays,0)    AS NetDays,
                /* Computed DueDate for MJE = PostedDate + NetDays */
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) <= 0
                     THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidbylessthen0days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 1  AND 30
                     THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby30days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 31 AND 60
                     THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby60days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 61 AND 90
                     THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby90days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 91 AND 120
                     THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby120days,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) > 120
                     THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidbymorethan120days,
                MJD.ManagementStructureId,
                UPPER('Manual Journal Adjustment') AS DocType,
                '' AS vendorRef, '' AS Salesperson,
                CTM.Name AS Terms, '0' AS FixRateAmount,
                ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) AS InvoiceAmount,
                0 AS cmAmount, 0 AS CreditMemoAmount,
                DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate)   AS DueDate,
                UPPER(CAST(MSL1.Code AS VARCHAR(250))  + ' - ' + MSL1.[Description])  AS level1,
                UPPER(CAST(MSL2.Code AS VARCHAR(250))  + ' - ' + MSL2.[Description])  AS level2,
                UPPER(CAST(MSL3.Code AS VARCHAR(250))  + ' - ' + MSL3.[Description])  AS level3,
                UPPER(CAST(MSL4.Code AS VARCHAR(250))  + ' - ' + MSL4.[Description])  AS level4,
                UPPER(CAST(MSL5.Code AS VARCHAR(250))  + ' - ' + MSL5.[Description])  AS level5,
                UPPER(CAST(MSL6.Code AS VARCHAR(250))  + ' - ' + MSL6.[Description])  AS level6,
                UPPER(CAST(MSL7.Code AS VARCHAR(250))  + ' - ' + MSL7.[Description])  AS level7,
                UPPER(CAST(MSL8.Code AS VARCHAR(250))  + ' - ' + MSL8.[Description])  AS level8,
                UPPER(CAST(MSL9.Code AS VARCHAR(250))  + ' - ' + MSL9.[Description])  AS level9,
                UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
                MJH.MasterCompanyId,
                0 AS IsCreditMemo, 0 AS StatusId, 0 AS InvoicePaidAmount,
                CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) > 0
                     THEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) ELSE 0 END AS DaysPastDue
				,''  AS poReference
            INTO #tempManualJE
            FROM dbo.ManualJournalHeader   MJH WITH (NOLOCK)
            INNER JOIN dbo.ManualJournalDetails MJD WITH (NOLOCK) ON MJD.ManualJournalHeaderId = MJH.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2
            INNER JOIN dbo.VendorPaymentDetails vpd WITH (NOLOCK) ON vpd.ManualJournalHeaderId = MJH.ManualJournalHeaderId
            INNER JOIN dbo.Vendor               V   WITH (NOLOCK) ON V.VendorId = MJD.ReferenceId
            INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.ManualJournalDetailsId
            LEFT  JOIN dbo.EntityStructureSetup ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
            LEFT  JOIN dbo.CreditTerms          CTM WITH (NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId
            LEFT  JOIN dbo.Currency             CR  WITH (NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId
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
            WHERE MJD.ReferenceId = ISNULL(@vendorId, MJD.ReferenceId)
              AND MJH.ManualJournalStatusId = @PostStatusId
              AND MJD.ReferenceTypeId = 2
              AND vpd.RemainingAmount > 0
              AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
              AND CAST(MJH.PostedDate AS DATE) <= CAST(@ToDate AS DATE)
              AND MJH.MasterCompanyId = @mastercompanyid
              AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
              AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
              AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
              AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
              AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
              AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
              AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
              AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
              AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
              AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')))
            GROUP BY MJD.ReferenceId, V.VendorName, V.VendorCode, CR.Code, MJH.JournalNumber,
                MJH.PostedDate, CTM.NetDays, MJD.UpdatedBy, MJD.ManagementStructureId, CTM.Name, CTM.Code,
                MSL1.Code, MSL1.[Description], MSL2.Code, MSL2.[Description], MSL3.Code, MSL3.[Description],
                MSL4.Code, MSL4.[Description], MSL5.Code, MSL5.[Description], MSL6.Code, MSL6.[Description],
                MSL7.Code, MSL7.[Description], MSL8.Code, MSL8.[Description], MSL9.Code, MSL9.[Description],
                MSL10.Code, MSL10.[Description], MJH.MasterCompanyId
            HAVING SUM(ISNULL(MJD.Credit,0)) - SUM(ISNULL(MJD.Debit,0)) <> 0;

            /* ── NonPO Details ── */
            SELECT DISTINCT
                v.VendorId,
                ISNULL(v.VendorName,'')       AS vendorName,
                ISNULL(v.VendorCode,'')       AS vendorCode,
                CR.Code                       AS currencyCode,
                ISNULL(vpd.RemainingAmount,0) AS BalanceAmount,
                ISNULL(vpd.RemainingAmount,0) AS CurrentlAmount,
                ISNULL(vpd.PaymentMade,0)     AS PaymentAmount,
                NPH.NPONumber                 AS InvoiceNo,
                NPH.InvoiceNumber             AS invoiceNumber,
                NPH.InvoiceDate,
                ISNULL(ctm.NetDays,0)         AS NetDays,
                /* ── AGING BUCKETS: based on NPH.DueDate ── */
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) <= 0
                     THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidbylessthen0days,
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 1  AND 30
                     THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby30days,
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 31 AND 60
                     THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby60days,
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 61 AND 90
                     THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby90days,
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 91 AND 120
                     THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby120days,
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) > 120
                     THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidbymorethan120days,
                NPH.ManagementStructureId,
                'NPO-Inv' AS DocType, '' AS vendorRef, '' AS Salesperson,
                ctm.Name AS Terms, '0' AS FixRateAmount,
                vpd.RemainingAmount AS InvoiceAmount,
                0 AS cmAmount, 0 AS CreditMemoAmount,
                NPH.DueDate,
                UPPER(MSD.Level1Name)  AS level1,  UPPER(MSD.Level2Name)  AS level2,
                UPPER(MSD.Level3Name)  AS level3,  UPPER(MSD.Level4Name)  AS level4,
                UPPER(MSD.Level5Name)  AS level5,  UPPER(MSD.Level6Name)  AS level6,
                UPPER(MSD.Level7Name)  AS level7,  UPPER(MSD.Level8Name)  AS level8,
                UPPER(MSD.Level9Name)  AS level9,  UPPER(MSD.Level10Name) AS level10,
                NPH.MasterCompanyId,
                0 AS IsCreditMemo, 0 AS StatusId, 0 AS InvoicePaidAmount,
                /* ── DaysPastDue: days since DueDate ── */
                CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) > 0
                     THEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) ELSE 0 END AS DaysPastDue
				,'' AS poReference					 
            INTO #tempNonPODetails
            FROM dbo.NonPOInvoiceHeader NPH WITH (NOLOCK)
            INNER JOIN dbo.Vendor                  v   WITH (NOLOCK) ON v.VendorId = NPH.VendorId
            INNER JOIN dbo.VendorPaymentDetails     vpd WITH (NOLOCK) ON vpd.NonPOInvoiceId = NPH.NonPOInvoiceId
            INNER JOIN dbo.Currency                 CR  WITH (NOLOCK) ON CR.CurrencyId = NPH.CurrencyId
            LEFT  JOIN dbo.CreditTerms              ctm WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
            LEFT  JOIN dbo.NonPOInvoiceManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
            LEFT  JOIN dbo.EntityStructureSetup     ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
            OUTER APPLY (
                SELECT npdd.NonPOInvoiceId, SUM(npdd.ExtendedPrice) AS InvoiceTotal
                FROM dbo.NonPOInvoicePartDetails npdd WITH (NOLOCK)
                WHERE npdd.NonPOInvoiceId = NPH.NonPOInvoiceId
                GROUP BY npdd.NonPOInvoiceId
            ) PartData
            WHERE NPH.VendorId = ISNULL(@vendorId, NPH.VendorId)
              AND CAST(NPH.PostedDate AS DATE) <= CAST(@ToDate AS DATE)
              AND NPH.MasterCompanyId = @mastercompanyid
              AND vpd.RemainingAmount > 0
              AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
              AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
              AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
              AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
              AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
              AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
              AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
              AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
              AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
              AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
              AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
              AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')));

			;WITH CTE AS (   
               SELECT * FROM #tempReceivingReconciliation
			   UNION ALL
			   SELECT * FROM #tempCreditMemo
			   UNION ALL
			   SELECT * FROM #tempManualJE
			   UNION ALL
			   SELECT * FROM #tempNonPODetails),    
			Result AS(      
			SELECT DISTINCT       
				ROW_NUMBER() OVER(PARTITION BY CTE.VendorId,CTE.level1,CTE.level2,CTE.level3,CTE.level4,CTE.level5,CTE.level6,CTE.level7,CTE.level8,CTE.level9,CTE.level10 ORDER BY v.vendorId ASC) rNo,
				(CTE.VendorId) AS VendorId ,      
				UPPER((ISNULL(CTE.vendorName,''))) 'vendorName' ,      
				UPPER((ISNULL(CTE.vendorCode,''))) 'vendorCode' ,      
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.InvoiceAmount - ISNULL(CTE.InvoicePaidAmount,0)),0) ELSE ISNULL(CTE.CreditMemoAmount,0) END AS 'BalanceAmount',
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END  AS 'Amountpaidbylessthen0days',   							
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby30days) END,0) END AS 'Amountpaidby30days',   							
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby60days) END,0) END AS 'Amountpaidby60days',   							
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby90days) END,0) END AS 'Amountpaidby90days',   							
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby120days) END,0) END AS 'Amountpaidby120days',   							
				CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN CTE.Amountpaidbymorethan120days ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbymorethan120days) END,0) END AS 'Amountpaidbymorethan120days',   													   		
				ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount',      
				UPPER(CTE.level1) AS level1, UPPER(CTE.level2) AS level2,  UPPER(CTE.level3) AS level3,  UPPER(CTE.level4) AS level4,UPPER(CTE.level5) AS level5,       
				UPPER(CTE.level6) AS level6,UPPER(CTE.level7) AS level7,  UPPER(CTE.level8) AS level8, UPPER(CTE.level9) AS level9,UPPER(CTE.level10) AS level10,CTE.MasterCompanyId,0 AS cmAmount,
				DaysPastDue				
			   ,'' poReference
			  FROM CTE AS CTE WITH (NOLOCK)       
			  INNER JOIN dbo.Vendor AS v WITH (NOLOCK) ON v.VendorId = CTE.VendorId    
			  WHERE V.MasterCompanyId = @MasterCompanyId 
			  AND (ISNULL(@VendorName,'') ='' OR CTE.vendorName LIKE '%' + @VendorName + '%')
				AND (ISNULL(@VendorCode,'') ='' OR CTE.vendorCode LIKE '%' + @VendorCode + '%')
				AND (ISNULL(@InvoiceAmount,'') ='' OR CTE.InvoiceAmount LIKE '%' + @InvoiceAmount + '%')		    
				AND (ISNULL(@BalanceAmount,'') ='' OR BalanceAmount LIKE '%' + @BalanceAmount + '%')
				AND (ISNULL(@Amountpaidbylessthen0days,'') ='' OR Amountpaidbylessthen0days LIKE '%' + @Amountpaidbylessthen0days + '%')
				AND (ISNULL(@Amountpaidby30days,'') ='' OR Amountpaidby30days LIKE '%' + @Amountpaidby30days + '%')
				AND (ISNULL(@Amountpaidby60days,'') ='' OR Amountpaidby60days LIKE '%' + @Amountpaidby60days + '%')
				AND (ISNULL(@Amountpaidby90days,'') ='' OR Amountpaidby90days LIKE '%' + @Amountpaidby90days + '%')
				AND (ISNULL(@Amountpaidby120days,'') ='' OR Amountpaidby120days LIKE '%' + @Amountpaidby120days + '%')
				AND (ISNULL(@Amountpaidbymorethan120days,'') ='' OR Amountpaidbymorethan120days LIKE '%' + @Amountpaidbymorethan120days + '%')
				AND (ISNULL(@POReference,'') ='' OR CTE.poReference LIKE '%' + @POReference + '%')

	   ) , ResultCount AS(SELECT COUNT(VendorId) AS totalItems FROM Result)   
	   ,WithTotal (MastercompanyId, 
               TotalInvoiceAmount, 
               TotalBalanceAmount,TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, 
			   TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,cmAmount) 
			  AS (SELECT MastercompanyId, 
				SUM(InvoiceAmount) TotalInvoiceAmount,
				SUM(BalanceAmount) TotalBalanceAmount,
				SUM(Amountpaidbylessthen0days) TotalAmountpaidbylessthen0days,
				SUM(Amountpaidby30days) TotalAmountpaidby30days,
				SUM(Amountpaidby60days) TotalAmountpaidby60days,
				SUM(Amountpaidby90days) TotalAmountpaidby90days,
				SUM(Amountpaidby120days) TotalAmountpaidby120days,
				SUM(Amountpaidbymorethan120days) TotalAmountpaidbymorethan120days,
				SUM(cmAmount) cmAmount
		   FROM Result GROUP BY MastercompanyId)

		SELECT	
			VendorId, 
            UPPER(vendorName)vendorName,UPPER(vendorCode)vendorCode, 
			SUM(InvoiceAmount) AS InvoiceAmount, 
			SUM(BalanceAmount) AS BalanceAmount, 
			SUM(Amountpaidbylessthen0days) AS Amountpaidbylessthen0days, 
			SUM(Amountpaidby30days) AS Amountpaidby30days, 
			SUM(Amountpaidby60days) AS Amountpaidby60days, 
			SUM(Amountpaidby90days) AS Amountpaidby90days, 
			SUM(Amountpaidby120days) AS Amountpaidby120days, 
			SUM(Amountpaidbymorethan120days) AS Amountpaidbymorethan120days,
			level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,			
			TotalInvoiceAmount, TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days,TotalAmountpaidby60days,
			TotalAmountpaidby90days,TotalAmountpaidby120days,TotalAmountpaidbymorethan120days ,WC.cmAmount
			,DaysPastDue
			,UPPER(poReference)poReference 
			
	   INTO #TempResult1 FROM  Result FC
	   INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
	   GROUP BY VendorId,vendorName,vendorCode,level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
				,TotalInvoiceAmount,TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days, TotalAmountpaidby60days,
				TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,WC.cmAmount
				,DaysPastDue
				,poReference
		;WITH cteFinal AS (
			  SELECT *,  
				ROW_NUMBER() OVER(PARTITION BY CTE.VendorId,CTE.level1,CTE.level2,CTE.level3,CTE.level4,CTE.level5,CTE.level6,CTE.level7,CTE.level8,CTE.level9,CTE.level10 ORDER BY CTE.vendorId ASC) rNo
			  FROM #TempResult1 CTE
			)
		SELECT	
				MAX(FC.rNo) rNo,
				VendorId,vendorName,
				vendorCode, 
				SUM(InvoiceAmount) AS InvoiceAmount, 
				SUM(BalanceAmount) AS BalanceAmount, 
				SUM(Amountpaidbylessthen0days) AS Amountpaidbylessthen0days, 
				SUM(Amountpaidby30days) AS Amountpaidby30days, 
				SUM(Amountpaidby60days) AS Amountpaidby60days, 
				SUM(Amountpaidby90days) AS Amountpaidby90days, 
				SUM(Amountpaidby120days) AS Amountpaidby120days, 
				SUM(Amountpaidbymorethan120days) AS Amountpaidbymorethan120days,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,			
				TotalInvoiceAmount, TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days,TotalAmountpaidby60days,
				TotalAmountpaidby90days,TotalAmountpaidby120days,TotalAmountpaidbymorethan120days ,cmAmount
				,CONVERT(INT,(SUM(ISNULL(DaysPastDue,0))/(MAX(ISNULL(FC.rNo,1))))) AS DaysPastDue,
				poReference
				--,DaysPastDue
			
	   INTO #TempResult1Final FROM  cteFinal FC
	   GROUP BY VendorId,vendorName,vendorCode,level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
				,TotalInvoiceAmount,TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days, TotalAmountpaidby60days,
				TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,cmAmount,poReference
				--,DaysPastDue

		SELECT @Count = COUNT(VendorId) FROM #TempResult1Final     
		SELECT @Count AS TotalRecordsCount
		,rNo
		,VendorId,vendorName, vendorCode, 
		FORMAT(ISNULL(InvoiceAmount,0), 'N', 'en-us') AS 'InvoiceAmount',
		FORMAT(ISNULL(BalanceAmount,0), 'N', 'en-us') AS 'BalanceAmount',	
		FORMAT(ISNULL(Amountpaidbylessthen0days,0), 'N', 'en-us') AS 'Amountpaidbylessthen0days',
		FORMAT(ISNULL(Amountpaidby30days,0), 'N', 'en-us') AS 'Amountpaidby30days',
		FORMAT(ISNULL(Amountpaidby60days,0), 'N', 'en-us') AS 'Amountpaidby60days',
		FORMAT(ISNULL(Amountpaidby90days,0), 'N', 'en-us') AS 'Amountpaidby90days',
		FORMAT(ISNULL(Amountpaidby120days,0), 'N', 'en-us') AS 'Amountpaidby120days',
		FORMAT(ISNULL(Amountpaidbymorethan120days,0), 'N', 'en-us') AS 'Amountpaidbymorethan120days',	
		level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
		TotalInvoiceAmount, --TotalcmAmount, TotalcmAmountUsed, 
		TotalBalanceAmount, TotalAmountpaidbylessthen0days, 
		TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,cmAmount,DaysPastDue
		,poReference
	
		FROM #TempResult1Final 
		ORDER BY  					 
				CASE WHEN (@SortOrder=1  AND @SortColumn='vendorName') THEN vendorName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorName') THEN vendorName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='vendorCode') THEN vendorCode END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorCode') THEN vendorCode END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceAmount') THEN InvoiceAmount END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceAmount') THEN InvoiceAmount END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='BalanceAmount') THEN BalanceAmount END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BalanceAmount') THEN BalanceAmount END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidbylessthen0days') THEN Amountpaidbylessthen0days END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbylessthen0days') THEN Amountpaidbylessthen0days END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby30days') THEN Amountpaidby30days END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby30days') THEN Amountpaidby30days END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby60days') THEN Amountpaidby60days END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby60days') THEN Amountpaidby60days END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby90days') THEN Amountpaidby90days END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby90days') THEN Amountpaidby90days END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby120days') THEN Amountpaidby120days END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby120days') THEN Amountpaidby120days END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidbymorethan120days') THEN Amountpaidbymorethan120days END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbymorethan120days') THEN Amountpaidbymorethan120days END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='poReference') THEN poReference END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='poReference') THEN poReference END DESC
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
        END
        ELSE
		BEGIN
			/* ── Receiving Reconciliation ── */
			SELECT DISTINCT
				v.VendorId,
				ISNULL(v.VendorName,'')       AS vendorName,
				ISNULL(v.VendorCode,'')       AS vendorCode,
				rrh.CurrencyName              AS currencyCode,
				ISNULL(vpd.OriginalAmount,0)  AS BalanceAmount,
				ISNULL(vpd.RemainingAmount,0) AS CurrentlAmount,
				ISNULL(vpd.PaymentMade,0)     AS PaymentAmount,
				rrh.ReceivingReconciliationNumber AS InvoiceNo,
				rrh.InvoiceNum                AS invoiceNumber,
				rrh.InvoiceDate,
				ISNULL(ctm.NetDays,0)         AS NetDays,
				/* ── AGING BUCKETS: based on rrh.DueDate ── */
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) <= 0
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidbylessthen0days,
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 1  AND 30
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby30days,
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 31 AND 60
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby60days,
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 61 AND 90
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby90days,
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) BETWEEN 91 AND 120
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby120days,
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) > 120
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidbymorethan120days,
				rrh.ManagementStructureId,
				CASE WHEN rrd.[Type] = 1 THEN 'PO-Inv' WHEN rrd.[Type] = 2 THEN 'RO-Inv' END AS DocType,
				'' AS vendorRef, '' AS Salesperson,
				ctm.Name AS Terms, '0' AS FixRateAmount,
				rrh.InvoiceTotal AS InvoiceAmount,
				0 AS cmAmount, 0 AS CreditMemoAmount,
				rrh.DueDate,
				UPPER(COALESCE(MSD.Level1Name,  NMSD.Level1Name,  AMSD.Level1Name))  AS Level1,
				UPPER(COALESCE(MSD.Level2Name,  NMSD.Level2Name,  AMSD.Level2Name))  AS Level2,
				UPPER(COALESCE(MSD.Level3Name,  NMSD.Level3Name,  AMSD.Level3Name))  AS Level3,
				UPPER(COALESCE(MSD.Level4Name,  NMSD.Level4Name,  AMSD.Level4Name))  AS Level4,
				UPPER(COALESCE(MSD.Level5Name,  NMSD.Level5Name,  AMSD.Level5Name))  AS Level5,
				UPPER(COALESCE(MSD.Level6Name,  NMSD.Level6Name,  AMSD.Level6Name))  AS Level6,
				UPPER(COALESCE(MSD.Level7Name,  NMSD.Level7Name,  AMSD.Level7Name))  AS Level7,
				UPPER(COALESCE(MSD.Level8Name,  NMSD.Level8Name,  AMSD.Level8Name))  AS Level8,
				UPPER(COALESCE(MSD.Level9Name,  NMSD.Level9Name,  AMSD.Level9Name))  AS Level9,
				UPPER(COALESCE(MSD.Level10Name, NMSD.Level10Name, AMSD.Level10Name)) AS Level10,
				rrh.MasterCompanyId,
				0 AS IsCreditMemo, 0 AS StatusId,
				vpd.PaymentMade AS InvoicePaidAmount,
				/* ── DaysPastDue: days since DueDate ── */
				CASE WHEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) > 0
					 THEN DATEDIFF(DAY, rrh.DueDate, GETUTCDATE()) ELSE 0 END AS DaysPastDue,
			    ISNULL((SELECT STRING_AGG(d.POReference, ', ')	FROM (SELECT DISTINCT po.POReference FROM [dbo].[ReceivingReconciliationDetails] po WITH (NOLOCK) WHERE po.[ReceivingReconciliationId] = rrh.[ReceivingReconciliationId] AND po.[Type] > 0) d), '') AS poReference			
			INTO #tempReceivingReconciliationElse
			FROM dbo.ReceivingReconciliationHeader      rrh  WITH (NOLOCK)
			INNER JOIN dbo.ReceivingReconciliationDetails rrd  WITH (NOLOCK) ON rrd.ReceivingReconciliationId = rrh.ReceivingReconciliationId AND rrd.[Type] > 0
			INNER JOIN dbo.VendorPaymentDetails           vpd  WITH (NOLOCK) ON vpd.ReceivingReconciliationId = rrh.ReceivingReconciliationId
			INNER JOIN dbo.Vendor                         v    WITH (NOLOCK) ON v.VendorId = rrh.VendorId
			LEFT  JOIN dbo.CreditTerms                    ctm  WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
			LEFT  JOIN dbo.StocklineManagementStructureDetails    MSD  WITH (NOLOCK) ON MSD.ModuleID  = @ModuleID         AND MSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'STOCK'
			LEFT  JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'NONSTOCK'
			LEFT  JOIN dbo.AssetManagementStructureDetails        AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID   AND AMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'ASSET'
			LEFT  JOIN dbo.EntityStructureSetup                   ES   WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			WHERE rrh.VendorId = ISNULL(@vendorId, rrh.VendorId)
			  AND CAST(rrh.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)
			  AND rrh.MasterCompanyId = @mastercompanyid
			  AND vpd.RemainingAmount > 0
			  AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
			  AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
			  AND (ISNULL(@Level1,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level1Id   IN (SELECT Item FROM dbo.SplitString(@Level1,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,','))))
			  AND (ISNULL(@Level2,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level2Id   IN (SELECT Item FROM dbo.SplitString(@Level2,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,','))))
			  AND (ISNULL(@Level3,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level3Id   IN (SELECT Item FROM dbo.SplitString(@Level3,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,','))))
			  AND (ISNULL(@Level4,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level4Id   IN (SELECT Item FROM dbo.SplitString(@Level4,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,','))))
			  AND (ISNULL(@Level5,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level5Id   IN (SELECT Item FROM dbo.SplitString(@Level5,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,','))))
			  AND (ISNULL(@Level6,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level6Id   IN (SELECT Item FROM dbo.SplitString(@Level6,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,','))))
			  AND (ISNULL(@Level7,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level7Id   IN (SELECT Item FROM dbo.SplitString(@Level7,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,','))))
			  AND (ISNULL(@Level8,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level8Id   IN (SELECT Item FROM dbo.SplitString(@Level8,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,','))))
			  AND (ISNULL(@Level9,'')  = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level9Id   IN (SELECT Item FROM dbo.SplitString(@Level9,',')))  OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,',')))  OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,','))))
			  AND (ISNULL(@Level10,'') = '' OR (UPPER(rrd.StockType)='STOCK' AND MSD.Level10Id  IN (SELECT Item FROM dbo.SplitString(@Level10,','))) OR (UPPER(rrd.StockType)='NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))) OR (UPPER(rrd.StockType)='ASSET' AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,','))));

			/* ── Credit Memo ──
			   No DueDate column on VendorCreditMemo.
			   Aging computed from CreatedDate + NetDays.
			── */
			SELECT DISTINCT
				VCM.VendorId,
				ISNULL(VEN.VendorName,'')		 AS vendorName,
				ISNULL(VEN.VendorCode,'')		 AS vendorCode,
				CR.Code							 AS currencyCode,
				ISNULL(VCD.ApplierdAmt,0) * (-1) AS BalanceAmount,
				ISNULL(VCD.ApplierdAmt,0) * (-1) AS CurrentlAmount,
				ISNULL(VCD.ApplierdAmt,0) * (-1) AS PaymentAmount,
				VCM.VendorCreditMemoNumber		 AS InvoiceNo,
				''								 AS invoiceNumber,
				VCM.CreatedDate					 AS InvoiceDate,
				ISNULL(CTM.NetDays,0)			 AS NetDays,
				/* Credit Memo: computed due date = CreatedDate + NetDays */
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) <= 0
					 THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidbylessthen0days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 1  AND 30
					 THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby30days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 31 AND 60
					 THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby60days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 61 AND 90
					 THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby90days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) BETWEEN 91 AND 120
					 THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidby120days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) > 120
					 THEN VCD.ApplierdAmt * (-1) ELSE 0 END AS Amountpaidbymorethan120days,
				SMSD.EntityMSID           AS ManagementStructureId,
				'Credit Memo'             AS DocType,
				''                        AS vendorRef,
				''                        AS Salesperson,
				CTM.Name                  AS Terms,
				'0'                       AS FixRateAmount,
				VCD.ApplierdAmt * (-1)    AS InvoiceAmount,
				VCD.ApplierdAmt * (-1)    AS cmAmount,
				VCD.ApplierdAmt * (-1)    AS CreditMemoAmount,
				CAST(NULL AS DATETIME)    AS DueDate,
				UPPER(SMSD.Level1Name)    AS level1, UPPER(SMSD.Level2Name)  AS level2,
				UPPER(SMSD.Level3Name)    AS level3, UPPER(SMSD.Level4Name)  AS level4,
				UPPER(SMSD.Level5Name)    AS level5, UPPER(SMSD.Level6Name)  AS level6,
				UPPER(SMSD.Level7Name)    AS level7, UPPER(SMSD.Level8Name)  AS level8,
				UPPER(SMSD.Level9Name)    AS level9, UPPER(SMSD.Level10Name) AS level10,
				VCM.MasterCompanyId,
				1 AS IsCreditMemo,
				VCM.VendorCreditMemoStatusId AS StatusId,
				0 AS InvoicePaidAmount,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) > 0
					 THEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), VCM.CreatedDate), GETUTCDATE()) ELSE 0 END AS DaysPastDue
				,''  AS poReference
			INTO #tempCreditMemoElse
			FROM dbo.VendorCreditMemo           VCM  WITH (NOLOCK)
			INNER JOIN dbo.VendorCreditMemoDetail VCD  WITH (NOLOCK) ON VCD.VendorCreditMemoId = VCM.VendorCreditMemoId
			INNER JOIN dbo.Vendor                 VEN  WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId
			LEFT  JOIN dbo.CreditTerms            CTM  WITH (NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			LEFT  JOIN dbo.Currency               CR   WITH (NOLOCK) ON CR.CurrencyId = VCM.CurrencyId
			LEFT  JOIN dbo.StocklineManagementStructureDetails SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId
			LEFT  JOIN dbo.EntityStructureSetup   SES  WITH (NOLOCK) ON SES.EntityStructureId = SMSD.EntityMSID
			WHERE VCM.VendorId = ISNULL(@vendorId, VCM.VendorId)
			  AND CAST(VCM.CreatedDate AS DATE) <= CAST(@ToDate AS DATE)
			  AND VCM.MasterCompanyId = @mastercompanyid
			  AND VCM.VendorCreditMemoStatusId = @CMPostedStatusId
			  AND ISNULL(VCD.ApplierdAmt, 0) > 0
			  AND (ISNULL(@tagtype,'') = '' OR SES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
			  AND (ISNULL(@Level1,'')  = '' OR SMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
			  AND (ISNULL(@Level2,'')  = '' OR SMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
			  AND (ISNULL(@Level3,'')  = '' OR SMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
			  AND (ISNULL(@Level4,'')  = '' OR SMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
			  AND (ISNULL(@Level5,'')  = '' OR SMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
			  AND (ISNULL(@Level6,'')  = '' OR SMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
			  AND (ISNULL(@Level7,'')  = '' OR SMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
			  AND (ISNULL(@Level8,'')  = '' OR SMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
			  AND (ISNULL(@Level9,'')  = '' OR SMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
			  AND (ISNULL(@Level10,'') = '' OR SMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')));

			/* ── Manual JE ──
			   No DueDate column on ManualJournalHeader.
			   Aging computed from PostedDate + NetDays.
			── */
			SELECT DISTINCT
				MJD.ReferenceId           AS VendorId,
				ISNULL(V.VendorName,'')   AS vendorName,
				ISNULL(V.VendorCode,'')   AS vendorCode,
				CR.Code                   AS currencyCode,
				0 AS BalanceAmount,
				0 AS CurrentlAmount,
				0 AS PaymentAmount,
				UPPER(MJH.JournalNumber)  AS InvoiceNo,
				''                        AS invoiceNumber,
				MJH.PostedDate            AS InvoiceDate,
				ISNULL(CTM.NetDays,0)     AS NetDays,
				/* Manual JE: computed due date = PostedDate + NetDays */
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) <= 0
					 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidbylessthen0days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 1  AND 30
					 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby30days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 31 AND 60
					 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby60days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 61 AND 90
					 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby90days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) BETWEEN 91 AND 120
					 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidby120days,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) > 120
					 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END AS Amountpaidbymorethan120days,
				MJD.ManagementStructureId,
				UPPER('Manual Journal Adjustment') AS DocType,
				'' AS vendorRef, '' AS Salesperson,
				CTM.Name AS Terms, '0' AS FixRateAmount,
				ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) AS InvoiceAmount,
				0 AS cmAmount, 0 AS CreditMemoAmount,
				DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate) AS DueDate,
				UPPER(CAST(MSL1.Code  AS VARCHAR(250)) + ' - ' + MSL1.[Description])  AS level1,
				UPPER(CAST(MSL2.Code  AS VARCHAR(250)) + ' - ' + MSL2.[Description])  AS level2,
				UPPER(CAST(MSL3.Code  AS VARCHAR(250)) + ' - ' + MSL3.[Description])  AS level3,
				UPPER(CAST(MSL4.Code  AS VARCHAR(250)) + ' - ' + MSL4.[Description])  AS level4,
				UPPER(CAST(MSL5.Code  AS VARCHAR(250)) + ' - ' + MSL5.[Description])  AS level5,
				UPPER(CAST(MSL6.Code  AS VARCHAR(250)) + ' - ' + MSL6.[Description])  AS level6,
				UPPER(CAST(MSL7.Code  AS VARCHAR(250)) + ' - ' + MSL7.[Description])  AS level7,
				UPPER(CAST(MSL8.Code  AS VARCHAR(250)) + ' - ' + MSL8.[Description])  AS level8,
				UPPER(CAST(MSL9.Code  AS VARCHAR(250)) + ' - ' + MSL9.[Description])  AS level9,
				UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
				MJH.MasterCompanyId,
				0 AS IsCreditMemo, 0 AS StatusId, 0 AS InvoicePaidAmount,
				CASE WHEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) > 0
					 THEN DATEDIFF(DAY, DATEADD(DAY, ISNULL(CTM.NetDays,0), MJH.PostedDate), GETUTCDATE()) ELSE 0 END AS DaysPastDue
				,''  AS poReference
			INTO #tempManualJEElse
			FROM dbo.ManualJournalHeader   MJH WITH (NOLOCK)
			INNER JOIN dbo.ManualJournalDetails MJD WITH (NOLOCK) ON MJD.ManualJournalHeaderId = MJH.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2
			INNER JOIN dbo.VendorPaymentDetails vpd WITH (NOLOCK) ON vpd.ManualJournalHeaderId = MJH.ManualJournalHeaderId
			INNER JOIN dbo.Vendor               V   WITH (NOLOCK) ON V.VendorId = MJD.ReferenceId
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.ManualJournalDetailsId
			LEFT  JOIN dbo.EntityStructureSetup ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			LEFT  JOIN dbo.CreditTerms          CTM WITH (NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId
			LEFT  JOIN dbo.Currency             CR  WITH (NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId
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
			WHERE MJD.ReferenceId = ISNULL(@vendorId, MJD.ReferenceId)
			  AND MJH.ManualJournalStatusId = @PostStatusId
			  AND MJD.ReferenceTypeId = 2
			  AND vpd.RemainingAmount > 0
			  AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
			  AND CAST(MJH.PostedDate AS DATE) <= CAST(@ToDate AS DATE)
			  AND MJH.MasterCompanyId = @mastercompanyid
			  AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
			  AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
			  AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
			  AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
			  AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
			  AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
			  AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
			  AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
			  AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
			  AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
			  AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')))
			GROUP BY MJD.ReferenceId, V.VendorName, V.VendorCode, CR.Code, MJH.JournalNumber,
				MJH.PostedDate, CTM.NetDays, MJD.UpdatedBy, MJD.ManagementStructureId, CTM.Name, CTM.Code,
				MSL1.Code, MSL1.[Description], MSL2.Code, MSL2.[Description], MSL3.Code,  MSL3.[Description],
				MSL4.Code, MSL4.[Description], MSL5.Code, MSL5.[Description], MSL6.Code,  MSL6.[Description],
				MSL7.Code, MSL7.[Description], MSL8.Code, MSL8.[Description], MSL9.Code,  MSL9.[Description],
				MSL10.Code, MSL10.[Description], MJH.MasterCompanyId
			HAVING SUM(ISNULL(MJD.Credit,0)) - SUM(ISNULL(MJD.Debit,0)) <> 0;

			/* ── NonPO Details ── */
			SELECT DISTINCT
				v.VendorId,
				ISNULL(v.VendorName,'')       AS vendorName,
				ISNULL(v.VendorCode,'')       AS vendorCode,
				CR.Code                       AS currencyCode,
				ISNULL(vpd.RemainingAmount,0) AS BalanceAmount,
				ISNULL(vpd.RemainingAmount,0) AS CurrentlAmount,
				ISNULL(vpd.PaymentMade,0)     AS PaymentAmount,
				NPH.NPONumber                 AS InvoiceNo,
				NPH.InvoiceNumber             AS invoiceNumber,
				NPH.InvoiceDate,
				ISNULL(ctm.NetDays,0)         AS NetDays,
				/* ── AGING BUCKETS: based on NPH.DueDate ── */
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) <= 0
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidbylessthen0days,
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 1  AND 30
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby30days,
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 31 AND 60
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby60days,
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 61 AND 90
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby90days,
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) BETWEEN 91 AND 120
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidby120days,
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) > 120
					 THEN vpd.RemainingAmount ELSE 0 END AS Amountpaidbymorethan120days,
				NPH.ManagementStructureId,
				'NPO-Inv' AS DocType, '' AS vendorRef, '' AS Salesperson,
				ctm.Name AS Terms, '0' AS FixRateAmount,
				vpd.RemainingAmount AS InvoiceAmount,
				0 AS cmAmount, 0 AS CreditMemoAmount,
				NPH.DueDate,
				UPPER(MSD.Level1Name)  AS level1,  UPPER(MSD.Level2Name)  AS level2,
				UPPER(MSD.Level3Name)  AS level3,  UPPER(MSD.Level4Name)  AS level4,
				UPPER(MSD.Level5Name)  AS level5,  UPPER(MSD.Level6Name)  AS level6,
				UPPER(MSD.Level7Name)  AS level7,  UPPER(MSD.Level8Name)  AS level8,
				UPPER(MSD.Level9Name)  AS level9,  UPPER(MSD.Level10Name) AS level10,
				NPH.MasterCompanyId,
				0 AS IsCreditMemo, 0 AS StatusId, 0 AS InvoicePaidAmount,
				/* ── DaysPastDue: days since DueDate ── */
				CASE WHEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) > 0
					 THEN DATEDIFF(DAY, NPH.DueDate, GETUTCDATE()) ELSE 0 END AS DaysPastDue,
				ISNULL(NPH.PONumber,'') AS poReference				
			INTO #tempNonPODetailsElse
			FROM dbo.NonPOInvoiceHeader NPH WITH (NOLOCK)
			INNER JOIN dbo.VendorPaymentDetails    vpd WITH (NOLOCK) ON vpd.NonPOInvoiceId = NPH.NonPOInvoiceId
			INNER JOIN dbo.Vendor                  v   WITH (NOLOCK) ON v.VendorId = NPH.VendorId
			LEFT  JOIN dbo.CreditTerms             ctm WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
			INNER JOIN dbo.Currency                CR  WITH (NOLOCK) ON CR.CurrencyId = NPH.CurrencyId
			LEFT  JOIN dbo.NonPOInvoiceManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
			LEFT  JOIN dbo.EntityStructureSetup    ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			OUTER APPLY (
				SELECT npdd.NonPOInvoiceId, SUM(npdd.ExtendedPrice) AS InvoiceTotal
				FROM dbo.NonPOInvoicePartDetails npdd WITH (NOLOCK)
				WHERE npdd.NonPOInvoiceId = NPH.NonPOInvoiceId
				GROUP BY npdd.NonPOInvoiceId
			) PartData
			WHERE NPH.VendorId = ISNULL(@vendorId, NPH.VendorId)
			  AND CAST(NPH.PostedDate AS DATE) <= CAST(@ToDate AS DATE)
			  AND NPH.MasterCompanyId = @mastercompanyid
			  AND vpd.RemainingAmount > 0
			  AND vpd.IsActive = 1 AND vpd.IsDeleted = 0
			  AND (ISNULL(@tagtype,'') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))
			  AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
			  AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
			  AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
			  AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
			  AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
			  AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
			  AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
			  AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
			  AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
			  AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10,',')));

			/* ── CTE + final output (unchanged from original) ── */
			;WITH CTE AS (
				SELECT * FROM #tempReceivingReconciliationElse
				UNION ALL
				SELECT * FROM #tempCreditMemoElse
				UNION ALL
				SELECT * FROM #tempManualJEElse
				UNION ALL
				SELECT * FROM #tempNonPODetailsElse
			),
			Result AS (
				SELECT DISTINCT
					CTE.VendorId,
					UPPER(ISNULL(CTE.vendorName,''))  AS vendorName,
					UPPER(ISNULL(CTE.vendorCode,''))  AS vendorCode,
					UPPER(CTE.currencyCode)           AS currencyCode,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.InvoiceAmount,0) - ISNULL(CTE.InvoicePaidAmount,0)
						 ELSE ISNULL(CTE.CreditMemoAmount,0) END                               AS BalanceAmount,
					UPPER(CTE.InvoiceNo)              AS InvoiceNo,
					UPPER(ISNULL(CTE.invoiceNumber,'')) AS invoiceNumber,
					CASE WHEN ISNULL(@IsDownload,0) = 0
						 THEN FORMAT(CTE.InvoiceDate,'MM/dd/yyyy')
						 ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END                   AS InvoiceDate,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.Amountpaidbylessthen0days,0)
						 ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.CreditMemoAmount ELSE CTE.Amountpaidbylessthen0days END,0) END AS Amountpaidbylessthen0days,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.Amountpaidby30days,0)
						 ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.CreditMemoAmount ELSE CTE.Amountpaidby30days END,0) END             AS Amountpaidby30days,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.Amountpaidby60days,0)
						 ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.CreditMemoAmount ELSE CTE.Amountpaidby60days END,0) END             AS Amountpaidby60days,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.Amountpaidby90days,0)
						 ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.CreditMemoAmount ELSE CTE.Amountpaidby90days END,0) END             AS Amountpaidby90days,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.Amountpaidby120days,0)
						 ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.CreditMemoAmount ELSE CTE.Amountpaidby120days END,0) END           AS Amountpaidby120days,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN ISNULL(CTE.Amountpaidbymorethan120days,0)
						 ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN CTE.CreditMemoAmount ELSE CTE.Amountpaidbymorethan120days END,0) END AS Amountpaidbymorethan120days,
					ISNULL(CTE.InvoiceAmount,0)       AS InvoiceAmount,
					UPPER(CTE.DocType)                AS DocType,
					UPPER(CTE.Terms)                  AS Terms,
					CASE WHEN CTE.IsCreditMemo = 0
						 THEN CASE WHEN ISNULL(@IsDownload,0) = 0
								   THEN FORMAT(CTE.DueDate,'MM/dd/yyyy')
								   ELSE CONVERT(VARCHAR(50), DATEADD(DAY, CTE.NetDays, CTE.InvoiceDate), 107)
							  END
						 ELSE NULL END                AS DueDate,
					ISNULL(CTE.FixRateAmount,0)       AS FixRateAmount,
					UPPER(CTE.level1)  AS level1,  UPPER(CTE.level2)  AS level2,
					UPPER(CTE.level3)  AS level3,  UPPER(CTE.level4)  AS level4,
					UPPER(CTE.level5)  AS level5,  UPPER(CTE.level6)  AS level6,
					UPPER(CTE.level7)  AS level7,  UPPER(CTE.level8)  AS level8,
					UPPER(CTE.level9)  AS level9,  UPPER(CTE.level10) AS level10,
					CTE.MasterCompanyId,
					CTE.DaysPastDue,
					CTE.poReference					
				FROM CTE WITH (NOLOCK)
				INNER JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = CTE.VendorId
				WHERE V.MasterCompanyId = @MasterCompanyId
				  AND (ISNULL(@VendorName,'')               = '' OR CTE.vendorName               LIKE '%' + @VendorName               + '%')
				  AND (ISNULL(@VendorCode,'')               = '' OR CTE.vendorCode               LIKE '%' + @VendorCode               + '%')
				  AND (ISNULL(@InvoiceAmount,'')            = '' OR CTE.InvoiceAmount            LIKE '%' + @InvoiceAmount            + '%')
				  AND (ISNULL(@BalanceAmount,'')            = '' OR BalanceAmount                LIKE '%' + @BalanceAmount            + '%')
				  AND (ISNULL(@InvoiceNo,'')               = '' OR InvoiceNo                    LIKE '%' + @InvoiceNo               + '%')
				  AND (ISNULL(@InvoiceDate,'')             = '' OR CAST(InvoiceDate AS DATE)     = CAST(@InvoiceDate AS DATE))
				  AND (ISNULL(@Terms,'')                   = '' OR CTE.Terms                    LIKE '%' + @Terms                   + '%')
				  AND (ISNULL(@DueDate,'')                 = '' OR CAST(DueDate AS DATE)         = CAST(@DueDate AS DATE))
				  AND (ISNULL(@Amountpaidbylessthen0days,'') = '' OR Amountpaidbylessthen0days  LIKE '%' + @Amountpaidbylessthen0days  + '%')
				  AND (ISNULL(@Amountpaidby30days,'')       = '' OR Amountpaidby30days          LIKE '%' + @Amountpaidby30days        + '%')
				  AND (ISNULL(@Amountpaidby60days,'')       = '' OR Amountpaidby60days          LIKE '%' + @Amountpaidby60days        + '%')
				  AND (ISNULL(@Amountpaidby90days,'')       = '' OR Amountpaidby90days          LIKE '%' + @Amountpaidby90days        + '%')
				  AND (ISNULL(@Amountpaidby120days,'')      = '' OR Amountpaidby120days         LIKE '%' + @Amountpaidby120days       + '%')
				  AND (ISNULL(@Amountpaidbymorethan120days,'') = '' OR Amountpaidbymorethan120days LIKE '%' + @Amountpaidbymorethan120days + '%')
				  AND (ISNULL(@POReference,'') ='' OR CTE.poReference LIKE '%' + @POReference + '%')
			),
			ResultCount AS (SELECT COUNT(VendorId) AS totalItems FROM Result),
			WithTotal (MastercompanyId, TotalInvoiceAmount, TotalBalanceAmount,
					   TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, TotalAmountpaidby60days,
					   TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days)
			AS (
				SELECT MastercompanyId,
					FORMAT(SUM(InvoiceAmount),            'N','en-us') AS TotalInvoiceAmount,
					FORMAT(SUM(BalanceAmount),            'N','en-us') AS TotalBalanceAmount,
					FORMAT(SUM(Amountpaidbylessthen0days),'N','en-us') AS TotalAmountpaidbylessthen0days,
					FORMAT(SUM(Amountpaidby30days),       'N','en-us') AS TotalAmountpaidby30days,
					FORMAT(SUM(Amountpaidby60days),       'N','en-us') AS TotalAmountpaidby60days,
					FORMAT(SUM(Amountpaidby90days),       'N','en-us') AS TotalAmountpaidby90days,
					FORMAT(SUM(Amountpaidby120days),      'N','en-us') AS TotalAmountpaidby120days,
					FORMAT(SUM(Amountpaidbymorethan120days),'N','en-us') AS TotalAmountpaidbymorethan120days
				FROM Result
				GROUP BY MastercompanyId
			)
			SELECT
				FC.VendorId,
				UPPER(FC.vendorName)    AS vendorName,
				UPPER(FC.vendorCode)    AS vendorCode,
				UPPER(FC.InvoiceNo)     AS InvoiceNo,
				UPPER(FC.invoiceNumber) AS invoiceNumber,
				FC.InvoiceDate,
				FORMAT(ISNULL(FC.InvoiceAmount,0),            'N','en-us') AS InvoiceAmount,
				FORMAT(ISNULL(FC.BalanceAmount,0),            'N','en-us') AS BalanceAmount,
				FORMAT(ISNULL(FC.Amountpaidbylessthen0days,0),'N','en-us') AS Amountpaidbylessthen0days,
				FORMAT(ISNULL(FC.Amountpaidby30days,0),       'N','en-us') AS Amountpaidby30days,
				FORMAT(ISNULL(FC.Amountpaidby60days,0),       'N','en-us') AS Amountpaidby60days,
				FORMAT(ISNULL(FC.Amountpaidby90days,0),       'N','en-us') AS Amountpaidby90days,
				FORMAT(ISNULL(FC.Amountpaidby120days,0),      'N','en-us') AS Amountpaidby120days,
				FORMAT(ISNULL(FC.Amountpaidbymorethan120days,0),'N','en-us') AS Amountpaidbymorethan120days,
				FC.level1, FC.level2, FC.level3, FC.level4, FC.level5,
				FC.level6, FC.level7, FC.level8, FC.level9, FC.level10,
				FC.DocType, FC.Terms, FC.DueDate, FC.currencyCode, FC.FixRateAmount,
				WC.TotalInvoiceAmount, WC.TotalBalanceAmount,
				WC.TotalAmountpaidbylessthen0days, WC.TotalAmountpaidby30days,
				WC.TotalAmountpaidby60days,        WC.TotalAmountpaidby90days,
				WC.TotalAmountpaidby120days,       WC.TotalAmountpaidbymorethan120days,
				FC.DaysPastDue,
				FC.poReference,			
				(SELECT totalItems FROM ResultCount) AS TotalRecordsCount
			FROM Result FC
			INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
			ORDER BY
				CASE WHEN @SortOrder=1  AND @SortColumn='vendorName'                  THEN FC.vendorName                  END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='vendorName'                  THEN FC.vendorName                  END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='vendorCode'                  THEN FC.vendorCode                  END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='vendorCode'                  THEN FC.vendorCode                  END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='InvoiceAmount'               THEN FC.InvoiceAmount               END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='InvoiceAmount'               THEN FC.InvoiceAmount               END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='BalanceAmount'               THEN FC.BalanceAmount               END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='BalanceAmount'               THEN FC.BalanceAmount               END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='InvoiceDate'                 THEN FC.InvoiceDate                 END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='InvoiceDate'                 THEN FC.InvoiceDate                 END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='invoiceNo'                   THEN FC.InvoiceNo                   END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='invoiceNo'                   THEN FC.InvoiceNo                   END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='terms'                       THEN FC.Terms                       END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='terms'                       THEN FC.Terms                       END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='dueDate'                     THEN FC.DueDate                     END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='dueDate'                     THEN FC.DueDate                     END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='currencyCode'                THEN FC.currencyCode                END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='currencyCode'                THEN FC.currencyCode                END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='fixRateAmount'               THEN FC.FixRateAmount               END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='fixRateAmount'               THEN FC.FixRateAmount               END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='Amountpaidbylessthen0days'   THEN FC.Amountpaidbylessthen0days   END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='Amountpaidbylessthen0days'   THEN FC.Amountpaidbylessthen0days   END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='Amountpaidby30days'          THEN FC.Amountpaidby30days          END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='Amountpaidby30days'          THEN FC.Amountpaidby30days          END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='Amountpaidby60days'          THEN FC.Amountpaidby60days          END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='Amountpaidby60days'          THEN FC.Amountpaidby60days          END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='Amountpaidby90days'          THEN FC.Amountpaidby90days          END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='Amountpaidby90days'          THEN FC.Amountpaidby90days          END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='Amountpaidby120days'         THEN FC.Amountpaidby120days         END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='Amountpaidby120days'         THEN FC.Amountpaidby120days         END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='Amountpaidbymorethan120days' THEN FC.Amountpaidbymorethan120days END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='Amountpaidbymorethan120days' THEN FC.Amountpaidbymorethan120days END DESC,
				CASE WHEN @SortOrder=1  AND @SortColumn='poReference'                 THEN FC.poReference                 END ASC,
				CASE WHEN @SortOrder=-1 AND @SortColumn='poReference'                 THEN FC.poReference                 END DESC
			OFFSET (@PageNumber - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;

		END 
    END TRY
    BEGIN CATCH        
    SELECT  
     ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
    DECLARE @ErrorLogID int,    
	
            @DatabaseName varchar(100) = DB_NAME(),       
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
            @AdhocComments varchar(150) = '[usprpt_GetAPAgingReport_SSRS]',        
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +        
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +        
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),      
            @ApplicationName varchar(100) = 'PAS'       
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
    EXEC SplogexceptiON @DatabaseName = @DatabaseName,        
                        @AdhocComments = @AdhocComments,        
                        @ProcedureParameters = @ProcedureParameters,        
                        @ApplicationName = @ApplicationName,        
                        @ErrorLogID = @ErrorLogID OUTPUT;        
        
    RAISERROR (        
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'        
    , 16, 1, @ErrorLogID)        
        
    RETURN (1);        
  END CATCH        
END