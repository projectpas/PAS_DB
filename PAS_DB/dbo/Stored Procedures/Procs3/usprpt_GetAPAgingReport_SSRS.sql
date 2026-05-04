/*************************************************************                   
 ** File:  [usprpt_GetAPAgingReport_SSRS]                   
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
    1    15 APR 2024    Rajesh Gami			Created  
	2    03 OCT 2025    Rajesh Gami			Fixed the Remaining Amount related issue
	3    27-JAN-2026    RAJESH GAMI			Add InvoiceNumber
	4    05-FEB-2026    Amit Ghediya		update for group by to pagesize reduce issue
	5    09-FEB-2026    Rajesh Gami			Added NONSTOCK, ASSET Management Structure JOIN in Receiving Reconciliation
	6	 13-Feb-2026	Devendra Shekh		Added New param @id5
	7    16-FEB-2026    Amit Ghediya        Update NPO Invoiced date from postedate to invoiced date.
	8    23-FEB-2026    Moin Bloch          Update Due date Getting From Direct Table.
	9    01-MAR-2026    Hemant Saliya       Corrected Due date for Export file.
	10   02-MAR-2026    Moin Bloch          Updated Due date For Manual JE 
	11   11-MAR-2026    Amit Ghediya        Updated for remove MJE after full payment (PN-15631)
	12   12-MAR-2026    Amit Ghediya        Updated for get isactive records (PN-15588)
	13   04-MAY-2026    Hemant Saliya       Re-Structure the SP to change the days calculation

  --[dbo].[usprpt_GetAPAgingReport_SSRS] 21,'2026-01-28',3654,2,null,null
exec usprpt_GetAPAgingReport_SSRS @mastercompanyid=21,@id='2026-01-03 00:00:00.176883244',@id2='5192',@id3='2',@id5='',@id6='',@strFilter='70!71!!!!!!!!',@id7=1
***************************************************************************************************/   
CREATE PROCEDURE [dbo].[usprpt_GetAPAgingReport_SSRS]       
@mastercompanyid INT,
@id DATETIME2,
@id2 VARCHAR(100) = null,
@id3 VARCHAR(100) = null,
@id5 VARCHAR(100) = null,
@id6 VARCHAR(50) = null,
@strFilter VARCHAR(MAX) = NULL,
@id7 BIT = NULL
AS        
BEGIN        
  SET NOCOUNT ON;        
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
        
  DECLARE @vendorId varchar(40) = NULL, 
  @Typeid varchar(40) = NULL, 
  @fromdate datetime, @todate datetime, @exludedebit varchar(40) = NULL, @tagtype varchar(50) = NULL,      
  @level1 VARCHAR(MAX) = NULL,    
  @level2 VARCHAR(MAX) = NULL,      
  @level3 VARCHAR(MAX) = NULL,      
  @level4 VARCHAR(MAX) = NULL,      
  @Level5 VARCHAR(MAX) = NULL,      
  @Level6 VARCHAR(MAX) = NULL,      
  @Level7 VARCHAR(MAX) = NULL,      
  @Level8 VARCHAR(MAX) = NULL,      
  @Level9 VARCHAR(MAX) = NULL,      
  @Level10 VARCHAR(MAX) = NULL,      
  @IsDownload BIT = NULL            
        
  BEGIN TRY        
      DECLARE @ModuleID INT = 2, @NonStockModuleID INT = 11, @AssetModuleID INT = 42;
      DECLARE @Count BIGINT = 0, @PostStatusId INT, @CMPostedStatusId INT, @MSModuleId INT = 0, 
              @CMMSModuleID BIGINT = 61, @invoiceNum varchar(30) = '', @PageSize int = 0, @PageNumber int = 1;

      SELECT @PostStatusId   = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus]  WHERE [Name] = 'Posted';
      SELECT @CMPostedStatusId = [Id]                  FROM [dbo].[CreditMemoStatus]      WHERE [Name] = 'Posted';
      SET @IsDownload = CASE WHEN NULLIF(@PageSize, 0) IS NULL THEN 1 ELSE 0 END;
      SELECT @MSModuleId   = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ManualJournalAccounting';
      SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE  ModuleName  = 'CreditMemoHeader';
		
      IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
      BEGIN    
          DROP TABLE #TEMPMSFilter;
      END

      CREATE TABLE #TEMPMSFilter (        
          ID      BIGINT IDENTITY(1,1),        
          LevelIds VARCHAR(MAX)			 
      ); 

      INSERT INTO #TEMPMSFilter (LevelIds)
      SELECT Item FROM DBO.SPLITSTRING(@strFilter, '!');

      SET @todate    = GETUTCDATE();
      SET @vendorId  = CASE WHEN @id2 = '' OR @id2 = '0' THEN NULL ELSE @id2 END;
      SET @Typeid    = @id3;
      SET @invoiceNum = CASE WHEN @id5 = '' THEN NULL ELSE @id5 END;
      SET @tagtype   = @id6;
  
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

      -- =====================================================================
      -- COUNT PHASE (only when PageSize = 0, i.e. download/full fetch)
      -- =====================================================================
      IF ISNULL(@PageSize, 0) = 0      
      BEGIN  
          SELECT * INTO #tempReceivingReconciliationCount FROM 
          (
              SELECT rrh.ReceivingReconciliationId AS ReceivingReconciliationId 
              FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
              INNER JOIN [dbo].[ReceivingReconciliationDetails]         rrd  WITH (NOLOCK) ON rrh.ReceivingReconciliationId = rrd.ReceivingReconciliationId AND rrd.[Type] > 0    
              INNER JOIN [dbo].[VendorPaymentDetails]                   vpd  WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
              INNER JOIN [dbo].[Vendor]                                 v    WITH (NOLOCK) ON v.VendorId = rrh.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                            ctm  WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId      
              LEFT JOIN  dbo.StocklineManagementStructureDetails         MSD  WITH (NOLOCK) ON MSD.ModuleID = @ModuleID        AND MSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'STOCK'
              LEFT JOIN  dbo.NonStocklineManagementStructureDetails      NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'NONSTOCK'
              LEFT JOIN  dbo.AssetManagementStructureDetails             AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID   AND AMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'ASSET' 
              LEFT JOIN  [dbo].[EntityStructureSetup]                    ES   ON ES.EntityStructureId = MSD.EntityMSID                  
              WHERE rrh.VendorId = ISNULL(@vendorId, rrh.VendorId)        
              AND CAST(rrh.InvoiceDate AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END
              AND vpd.RemainingAmount > 0
              AND rrh.MasterCompanyId = @mastercompanyid
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level1Id   IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))))
              AND (ISNULL(@Level2,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level2Id   IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))))
              AND (ISNULL(@Level3,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level3Id   IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))))
              AND (ISNULL(@Level4,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level4Id   IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))))
              AND (ISNULL(@Level5,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level5Id   IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))))
              AND (ISNULL(@Level6,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level6Id   IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))))
              AND (ISNULL(@Level7,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level7Id   IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))))
              AND (ISNULL(@Level8,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level8Id   IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))))
              AND (ISNULL(@Level9,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level9Id   IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))))
              AND (ISNULL(@Level10, '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level10Id  IN (SELECT Item FROM dbo.SplitString(@Level10, ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ','))))
          ) R;

          SELECT * INTO #tempCreditMemoCount FROM 
          (
              SELECT DISTINCT VCD.[VendorCreditMemoId] AS VendorCreditMemoId		
              FROM [dbo].[VendorCreditMemo]                          VCM  WITH (NOLOCK)       
              INNER JOIN [dbo].[VendorCreditMemoDetail]              VCD  WITH (NOLOCK) ON VCM.VendorCreditMemoId   = VCD.VendorCreditMemoId 
              INNER JOIN [dbo].[Vendor]                              VEN  WITH (NOLOCK) ON VEN.VendorId             = VCM.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                         CTM  WITH (NOLOCK) ON CTM.CreditTermsId        = VEN.CreditTermsId
              LEFT JOIN  [dbo].[Currency]                            CR   WITH (NOLOCK) ON CR.CurrencyId            = VCM.CurrencyId  
              LEFT JOIN  [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
              LEFT JOIN  [dbo].[EntityStructureSetup]                SES  WITH (NOLOCK) ON SES.EntityStructureId    = SMSD.EntityMSID  	
              WHERE VCM.[VendorId] = ISNULL(@vendorId, VCM.[VendorId])  			  
              AND CAST(VCM.[CreatedDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND VCM.[MasterCompanyId]         = @mastercompanyid   
              AND VCM.[VendorCreditMemoStatusId] = @CMPostedStatusId
              AND ISNULL(VCD.ApplierdAmt, 0) > 0 
              AND VCM.VendorCreditMemoNumber = ISNULL(@invoiceNum, VCM.VendorCreditMemoNumber)
              AND (ISNULL(@tagtype, '') = '' OR SES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR SMSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR SMSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR SMSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR SMSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR SMSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR SMSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR SMSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR SMSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR SMSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
          ) S;
		   
          SELECT * INTO #tempManualJECount FROM 
          (
              SELECT MJD.ReferenceId AS BillingInvoicingId
              FROM [dbo].[ManualJournalHeader]                            MJH  WITH (NOLOCK)   
              INNER JOIN [dbo].[ManualJournalDetails]                     MJD  WITH (NOLOCK) ON MJH.ManualJournalHeaderId  = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
              INNER JOIN [dbo].[VendorPaymentDetails]                     vpd  WITH (NOLOCK) ON MJH.ManualJournalHeaderId  = vpd.ManualJournalHeaderId
              INNER JOIN [dbo].[Vendor]                                   V    WITH (NOLOCK) ON V.VendorId                  = MJD.ReferenceId 
              INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId  AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
              LEFT JOIN  [dbo].[EntityStructureSetup]                     ES   WITH (NOLOCK) ON ES.EntityStructureId        = MSD.EntityMSID 		   
              LEFT JOIN  [dbo].[CreditTerms]                              CTM  WITH (NOLOCK) ON CTM.CreditTermsId           = V.CreditTermsId
              LEFT JOIN  [dbo].[Currency]                                 CR   WITH (NOLOCK) ON CR.CurrencyId               = MJH.FunctionalCurrencyId
              WHERE MJD.ReferenceId              = ISNULL(@vendorId, MJD.ReferenceId)   
              AND MJH.[ManualJournalStatusId]    = @PostStatusId
              AND CAST(MJH.[PostedDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND MJH.JournalNumber              = ISNULL(@invoiceNum, MJH.JournalNumber)
              AND MJH.mastercompanyid            = @mastercompanyid    
              AND vpd.RemainingAmount > 0 
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
          ) T;

          SELECT * INTO #tempNonPODetailsCount FROM 
          (
              SELECT NPH.NonPOInvoiceId AS NonPOInvoiceId 
              FROM [dbo].[NonPOInvoiceHeader]                   NPH WITH (NOLOCK)       
              INNER JOIN [dbo].[NonPOInvoicePartDetails]         NPD WITH (NOLOCK) ON NPH.NonPOInvoiceId  = NPD.NonPOInvoiceId
              INNER JOIN [dbo].[VendorPaymentDetails]            vpd WITH (NOLOCK) ON NPH.NonPOInvoiceId  = vpd.NonPOInvoiceId      
              INNER JOIN [dbo].[Vendor]                          v   WITH (NOLOCK) ON v.VendorId           = NPH.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                     ctm WITH (NOLOCK) ON ctm.CreditTermsId   = v.CreditTermsId      
              INNER JOIN [dbo].[Currency]                        CR  WITH (NOLOCK) ON CR.CurrencyId        = NPH.CurrencyId      
              LEFT JOIN  dbo.NonPOInvoiceManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID  = NPH.NonPOInvoiceId
              LEFT JOIN  [dbo].[EntityStructureSetup]            ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID                  
              WHERE NPH.VendorId              = ISNULL(@vendorId, NPH.VendorId)        
              AND CAST(NPH.InvoiceDate AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND vpd.RemainingAmount > 0  
              AND NPH.NPONumber              = ISNULL(@invoiceNum, NPH.NPONumber)
              AND NPH.MasterCompanyId        = @mastercompanyid
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))        
          ) U;

          SELECT @PageSize = COUNT(*)       
          FROM (
              SELECT * FROM #tempReceivingReconciliationCount
              UNION ALL
              SELECT * FROM #tempCreditMemoCount
              UNION ALL
              SELECT * FROM #tempManualJECount
              UNION ALL
              SELECT * FROM #tempNonPODetailsCount		
          ) TEMP;
      END;
  
      SET @PageSize   = CASE WHEN NULLIF(@PageSize, 0)   IS NULL THEN 10 ELSE @PageSize END;      
      SET @PageNumber = CASE WHEN NULLIF(@PageNumber, 0) IS NULL THEN 1  ELSE @PageNumber END;

      -- =====================================================================
      -- BRANCH 1: Summary / Grouped view (Typeid = 1)
      -- =====================================================================
      IF (@Typeid = 1)
      BEGIN
          -- -----------------------------------------------------------------
          -- Receiving Reconciliation  
          -- DueDate source: rrh.DueDate (stored on document)
          -- -----------------------------------------------------------------
          SELECT * INTO #tempReceivingReconciliation FROM 
          (
              SELECT DISTINCT
                  V.VendorId                                            AS VendorId,
                  ISNULL(V.[VendorName], '')                            AS vendorName,
                  ISNULL(V.VendorCode, '')                              AS vendorCode,
                  rrh.CurrencyName                                      AS currencyCode,
                  ISNULL(vpd.OriginalAmount, 0)                         AS BalanceAmount,
                  ISNULL(vpd.RemainingAmount, 0)                        AS CurrentlAmount,
                  ISNULL(vpd.PaymentMade, 0)                            AS PaymentAmount,
                  rrh.ReceivingReconciliationNumber                      AS InvoiceNo,
                  rrh.InvoiceNum                                        AS invoiceNumber,
                  rrh.InvoiceDate                                       AS InvoiceDate,
                  ISNULL(ctm.NetDays, 0)                                AS NetDays,

                  -- Aging buckets based on rrh.DueDate
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) <= 0
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbylessthen0days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) > 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbymorethan120days,

                  rrh.ManagementStructureId                             AS ManagementStructureId,
                  'AP-Inv'                                              AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  rrh.InvoiceTotal                                      AS InvoiceAmount,
                  0                                                     AS cmAmount,
                  0                                                     AS CreditMemoAmount,
                  rrh.DueDate                                           AS DueDate,
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
                  0                                                     AS IsCreditMemo,
                  0                                                     AS StatusId,
                  vpd.PaymentMade                                       AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[ReceivingReconciliationHeader]         rrh  WITH (NOLOCK)       
              INNER JOIN [dbo].[ReceivingReconciliationDetails]  rrd  WITH (NOLOCK) ON rrh.ReceivingReconciliationId = rrd.ReceivingReconciliationId AND rrd.[Type] > 0       
              INNER JOIN [dbo].[VendorPaymentDetails]            vpd  WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
              INNER JOIN [dbo].[Vendor]                          v    WITH (NOLOCK) ON v.VendorId  = rrh.VendorId     
              LEFT JOIN  [dbo].[CreditTerms]                     ctm  WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId			  
              LEFT JOIN  dbo.StocklineManagementStructureDetails  MSD  WITH (NOLOCK) ON MSD.ModuleID  = @ModuleID        AND MSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'STOCK'
              LEFT JOIN  dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'NONSTOCK'
              LEFT JOIN  dbo.AssetManagementStructureDetails     AMSD WITH (NOLOCK) ON AMSD.ModuleID  = @AssetModuleID   AND AMSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'ASSET' 
              LEFT JOIN  [dbo].[EntityStructureSetup]            ES   WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID                
              WHERE rrh.[VendorId]            = ISNULL(@vendorId, rrh.VendorId)        
              AND CAST(rrh.[InvoiceDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END
              AND rrh.[MasterCompanyId]       = @mastercompanyid   
              AND vpd.RemainingAmount > 0
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level1Id   IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))))
              AND (ISNULL(@Level2,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level2Id   IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))))
              AND (ISNULL(@Level3,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level3Id   IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))))
              AND (ISNULL(@Level4,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level4Id   IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))))
              AND (ISNULL(@Level5,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level5Id   IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))))
              AND (ISNULL(@Level6,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level6Id   IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))))
              AND (ISNULL(@Level7,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level7Id   IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))))
              AND (ISNULL(@Level8,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level8Id   IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))))
              AND (ISNULL(@Level9,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level9Id   IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))))
              AND (ISNULL(@Level10, '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level10Id  IN (SELECT Item FROM dbo.SplitString(@Level10, ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ','))))
          ) A;

          -- -----------------------------------------------------------------
          -- Credit Memo
          -- DueDate source: CreatedDate + NetDays (no stored DueDate on VCM)
          -- -----------------------------------------------------------------
          SELECT * INTO #tempCreditMemo FROM 
          (
              SELECT DISTINCT
                  VCM.[VendorId]                                        AS VendorId,
                  ISNULL(VEN.[VendorName], '')                          AS vendorName,
                  ISNULL(VEN.[VendorCode], '')                          AS vendorCode,
                  CR.[Code]                                             AS currencyCode,
                  ISNULL(VCD.ApplierdAmt, 0) * (-1)                     AS BalanceAmount,
                  ISNULL(VCD.ApplierdAmt, 0) * (-1)                     AS CurrentlAmount,
                  ISNULL(VCD.ApplierdAmt, 0) * (-1)                     AS PaymentAmount,
                  VCM.VendorCreditMemoNumber                            AS InvoiceNo,
                  ''                                                    AS invoiceNumber,
                  VCM.CreatedDate                                       AS InvoiceDate,
                  ISNULL(CTM.NetDays, 0)                                AS NetDays,

                  -- Aging buckets: DueDate = CreatedDate + NetDays
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) <= 0
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidbylessthen0days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) > 120
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidbymorethan120days,

                  SMSD.EntityMSID                                       AS ManagementStructureId,
                  'Credit Memo'                                         AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  VCD.ApplierdAmt * (-1)                                AS InvoiceAmount,
                  VCD.ApplierdAmt * (-1)                                AS cmAmount,
                  VCD.ApplierdAmt * (-1)                                AS CreditMemoAmount,
                  CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE) AS DueDate,
                  UPPER(SMSD.Level1Name)  AS level1,  UPPER(SMSD.Level2Name)  AS level2,
                  UPPER(SMSD.Level3Name)  AS level3,  UPPER(SMSD.Level4Name)  AS level4,
                  UPPER(SMSD.Level5Name)  AS level5,  UPPER(SMSD.Level6Name)  AS level6,
                  UPPER(SMSD.Level7Name)  AS level7,  UPPER(SMSD.Level8Name)  AS level8,
                  UPPER(SMSD.Level9Name)  AS level9,  UPPER(SMSD.Level10Name) AS level10,
                  VCM.MasterCompanyId,
                  1                                                     AS IsCreditMemo,
                  VCM.VendorCreditMemoStatusId                          AS StatusId,
                  0                                                     AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[VendorCreditMemo]                          VCM  WITH (NOLOCK)       
              INNER JOIN [dbo].[VendorCreditMemoDetail]              VCD  WITH (NOLOCK) ON VCM.VendorCreditMemoId  = VCD.VendorCreditMemoId 
              INNER JOIN [dbo].[Vendor]                              VEN  WITH (NOLOCK) ON VEN.VendorId            = VCM.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                         CTM  WITH (NOLOCK) ON CTM.CreditTermsId       = VEN.CreditTermsId
              LEFT JOIN  [dbo].[Currency]                            CR   WITH (NOLOCK) ON CR.CurrencyId           = VCM.CurrencyId  
              LEFT JOIN  [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
              LEFT JOIN  [dbo].[EntityStructureSetup]                SES  WITH (NOLOCK) ON SES.EntityStructureId   = SMSD.EntityMSID  	
              WHERE VCM.[VendorId]                = ISNULL(@vendorId, VCM.[VendorId])  			  
              AND CAST(VCM.[CreatedDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND VCM.[MasterCompanyId]           = @mastercompanyid   
              AND VCM.[VendorCreditMemoStatusId]  = @CMPostedStatusId
              AND ISNULL(VCD.ApplierdAmt, 0) > 0
              AND (ISNULL(@tagtype, '') = '' OR SES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR SMSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR SMSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR SMSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR SMSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR SMSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR SMSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR SMSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR SMSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR SMSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
          ) B;
		
          -- -----------------------------------------------------------------
          -- Manual Journal Entry
          -- DueDate source: PostedDate + NetDays (no stored DueDate on MJH)
          -- -----------------------------------------------------------------
          SELECT * INTO #tempManualJE FROM 
          (
              SELECT DISTINCT
                  MJD.ReferenceId                                       AS VendorId,
                  ISNULL(V.[VendorName], '')                            AS vendorName,
                  ISNULL(V.VendorCode, '')                              AS vendorCode,
                  CR.Code                                               AS currencyCode,
                  0                                                     AS BalanceAmount,
                  0                                                     AS CurrentlAmount,
                  0                                                     AS PaymentAmount,
                  UPPER(MJH.JournalNumber)                              AS InvoiceNo,
                  ''                                                    AS invoiceNumber,
                  MJH.[PostedDate]                                      AS InvoiceDate,
                  ISNULL(CTM.NetDays, 0)                                AS NetDays,

                  -- Aging buckets: DueDate = PostedDate + NetDays
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) <= 0
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS AmountpaidbylessTHEN0days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) > 120
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidbymorethan120days,

                  MJD.ManagementStructureId                             AS ManagementStructureId,
                  UPPER('Manual Journal Adjustment')                    AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) AS InvoiceAmount,
                  0                                                     AS cmAmount,
                  0                                                     AS CreditMemoAmount,
                  CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE) AS DueDate,
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
                  0                                                     AS IsCreditMemo,
                  0                                                     AS StatusId,
                  0                                                     AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.PostedDate) AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.PostedDate) AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[ManualJournalHeader]                            MJH  WITH (NOLOCK)   
              INNER JOIN [dbo].[ManualJournalDetails]                     MJD  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
              INNER JOIN [dbo].[VendorPaymentDetails]                     vpd  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = vpd.ManualJournalHeaderId
              INNER JOIN [dbo].[Vendor]                                   V    WITH (NOLOCK) ON V.VendorId                = MJD.ReferenceId 
              INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
              LEFT JOIN  [dbo].[EntityStructureSetup]                     ES   WITH (NOLOCK) ON ES.EntityStructureId      = MSD.EntityMSID 		   
              LEFT JOIN  [dbo].[CreditTerms]                              CTM  WITH (NOLOCK) ON CTM.CreditTermsId         = V.CreditTermsId
              LEFT JOIN  [dbo].[Currency]                                 CR   WITH (NOLOCK) ON CR.CurrencyId             = MJH.FunctionalCurrencyId
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL1 WITH (NOLOCK) ON MSD.Level1Id  = MSL1.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL2 WITH (NOLOCK) ON MSD.Level2Id  = MSL2.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL3 WITH (NOLOCK) ON MSD.Level3Id  = MSL3.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL4 WITH (NOLOCK) ON MSD.Level4Id  = MSL4.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL5 WITH (NOLOCK) ON MSD.Level5Id  = MSL5.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL6 WITH (NOLOCK) ON MSD.Level6Id  = MSL6.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL7 WITH (NOLOCK) ON MSD.Level7Id  = MSL7.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL8 WITH (NOLOCK) ON MSD.Level8Id  = MSL8.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL9 WITH (NOLOCK) ON MSD.Level9Id  = MSL9.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
              WHERE MJD.ReferenceId              = ISNULL(@vendorId, MJD.ReferenceId)    
              AND MJH.[ManualJournalStatusId]    = @PostStatusId
              AND MJD.[ReferenceTypeId]          = 2 
              AND vpd.RemainingAmount > 0 
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND CAST(MJH.[PostedDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END
              AND MJH.MasterCompanyId            = @mastercompanyid    
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
              GROUP BY MJD.ReferenceId, V.[VendorName], V.VendorCode, CR.Code, MJH.JournalNumber, 
                       MJH.[PostedDate], CTM.NetDays, MJD.UpdatedBy, MJD.ManagementStructureId, CTM.[Name], ctm.Code,
                       MSL1.Code, MSL1.[Description], MSL2.Code, MSL2.[Description], MSL3.Code, MSL3.[Description],
                       MSL4.Code, MSL4.[Description], MSL5.Code, MSL5.[Description], MSL6.Code, MSL6.[Description],
                       MSL7.Code, MSL7.[Description], MSL8.Code, MSL8.[Description], MSL9.Code, MSL9.[Description],
                       MSL10.Code, MSL10.[Description], MJH.MasterCompanyId
              HAVING SUM(ISNULL(MJD.Credit, 0)) - SUM(ISNULL(MJD.Debit, 0)) <> 0
          ) C;

          -- -----------------------------------------------------------------
          -- Non-PO Invoice
          -- DueDate source: NPH.DueDate (stored on document)
          -- -----------------------------------------------------------------
          SELECT * INTO #tempNonPODetails FROM 
          (
              SELECT DISTINCT
                  V.VendorId                                            AS VendorId,
                  ISNULL(V.[VendorName], '')                            AS vendorName,
                  ISNULL(V.VendorCode, '')                              AS vendorCode,
                  CR.Code                                               AS currencyCode,
                  ISNULL(vpd.RemainingAmount, 0)                        AS BalanceAmount,
                  ISNULL(vpd.RemainingAmount, 0)                        AS CurrentlAmount,
                  ISNULL(vpd.PaymentMade, 0)                            AS PaymentAmount,
                  NPH.NPONumber                                         AS InvoiceNo,
                  NPH.InvoiceNumber                                     AS invoiceNumber,
                  NPH.InvoiceDate                                       AS InvoiceDate,
                  ISNULL(ctm.NetDays, 0)                                AS NetDays,

                  -- Aging buckets based on NPH.DueDate (stored on document)
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) <= 0
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbylessthen0days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) > 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbymorethan120days,

                  NPH.ManagementStructureId                             AS ManagementStructureId,
                  'NPO-Inv'                                             AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  vpd.RemainingAmount                                   AS InvoiceAmount,
                  0                                                     AS cmAmount,
                  0                                                     AS CreditMemoAmount,
                  NPH.DueDate                                           AS DueDate,
                  UPPER(MSD.Level1Name)  AS level1,  UPPER(MSD.Level2Name)  AS level2,
                  UPPER(MSD.Level3Name)  AS level3,  UPPER(MSD.Level4Name)  AS level4,
                  UPPER(MSD.Level5Name)  AS level5,  UPPER(MSD.Level6Name)  AS level6,
                  UPPER(MSD.Level7Name)  AS level7,  UPPER(MSD.Level8Name)  AS level8,
                  UPPER(MSD.Level9Name)  AS level9,  UPPER(MSD.Level10Name) AS level10,
                  NPH.MasterCompanyId,
                  0                                                     AS IsCreditMemo,
                  0                                                     AS StatusId,
                  0                                                     AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[NonPOInvoiceHeader]                       NPH WITH (NOLOCK)    
              INNER JOIN [dbo].[Vendor]                              v   WITH (NOLOCK) ON v.VendorId          = NPH.VendorId      
              INNER JOIN [dbo].[VendorPaymentDetails]                vpd WITH (NOLOCK) ON NPH.NonPOInvoiceId  = vpd.NonPOInvoiceId
              INNER JOIN [dbo].[Currency]                            CR  WITH (NOLOCK) ON CR.CurrencyId       = NPH.CurrencyId
              LEFT JOIN  [dbo].[CreditTerms]                         ctm WITH (NOLOCK) ON ctm.CreditTermsId  = v.CreditTermsId
              LEFT JOIN  [dbo].[NonPOInvoiceManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
              LEFT JOIN  [dbo].[EntityStructureSetup]                ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
              OUTER APPLY (
                  SELECT npdd.[NonPOInvoiceId], SUM(npdd.ExtendedPrice) AS InvoiceTotal 
                  FROM [dbo].[NonPOInvoicePartDetails] npdd WITH (NOLOCK)
                  WHERE npdd.[NonPOInvoiceId] = NPH.NonPOInvoiceId 
                  GROUP BY npdd.[NonPOInvoiceId]
              ) PartData
              WHERE NPH.[VendorId]               = ISNULL(@vendorId, NPH.VendorId)        
              AND CAST(NPH.PostedDate AS DATE)   <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END
              AND NPH.[MasterCompanyId]          = @mastercompanyid   
              AND vpd.RemainingAmount > 0
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
          ) D;

          -- -----------------------------------------------------------------
          -- Combine, aggregate and output (Summary view)
          -- -----------------------------------------------------------------
          ;WITH CTE AS (   
              SELECT * FROM #tempReceivingReconciliation
              UNION ALL
              SELECT * FROM #tempCreditMemo
              UNION ALL
              SELECT * FROM #tempManualJE
              UNION ALL
              SELECT * FROM #tempNonPODetails
          ),    
          Result AS (      
              SELECT DISTINCT       
                  ROW_NUMBER() OVER (PARTITION BY CTE.VendorId, CTE.level1, CTE.level2, CTE.level3, CTE.level4, CTE.level5, CTE.level6, CTE.level7, CTE.level8, CTE.level9, CTE.level10 ORDER BY v.vendorId ASC) rNo,
                  CTE.VendorId,      
                  UPPER(ISNULL(CTE.vendorName, ''))  AS vendorName,      
                  UPPER(ISNULL(CTE.vendorCode, ''))  AS vendorCode,      
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.InvoiceAmount - ISNULL(CTE.InvoicePaidAmount, 0)), 0) ELSE ISNULL(CTE.CreditMemoAmount, 0) END AS BalanceAmount,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidbylessthen0days,    0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days    > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidbylessthen0days    END, 0) END AS Amountpaidbylessthen0days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby30days,           0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days           > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby30days           END, 0) END AS Amountpaidby30days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby60days,           0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days           > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby60days           END, 0) END AS Amountpaidby60days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby90days,           0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days           > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby90days           END, 0) END AS Amountpaidby90days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby120days,          0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days          > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby120days          END, 0) END AS Amountpaidby120days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidbymorethan120days,  0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days  > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidbymorethan120days  END, 0) END AS Amountpaidbymorethan120days,
                  ISNULL(CTE.InvoiceAmount, 0)   AS InvoiceAmount,      
                  UPPER(CTE.level1) AS level1, UPPER(CTE.level2) AS level2, UPPER(CTE.level3)  AS level3,
                  UPPER(CTE.level4) AS level4, UPPER(CTE.level5) AS level5, UPPER(CTE.level6)  AS level6,
                  UPPER(CTE.level7) AS level7, UPPER(CTE.level8) AS level8, UPPER(CTE.level9)  AS level9,
                  UPPER(CTE.level10) AS level10,
                  CTE.MasterCompanyId,
                  0 AS cmAmount,
                  DaysPastDue
              FROM CTE WITH (NOLOCK)       
              INNER JOIN dbo.Vendor AS v WITH (NOLOCK) ON v.VendorId = CTE.VendorId    
              WHERE V.MasterCompanyId = @MasterCompanyId 
          ),
          ResultCount AS (SELECT COUNT(VendorId) AS totalItems FROM Result),
          WithTotal AS (
              SELECT MastercompanyId, 
                     SUM(InvoiceAmount)              AS TotalInvoiceAmount,
                     SUM(BalanceAmount)              AS TotalBalanceAmount,
                     SUM(Amountpaidbylessthen0days)  AS TotalAmountpaidbylessthen0days,
                     SUM(Amountpaidby30days)         AS TotalAmountpaidby30days,
                     SUM(Amountpaidby60days)         AS TotalAmountpaidby60days,
                     SUM(Amountpaidby90days)         AS TotalAmountpaidby90days,
                     SUM(Amountpaidby120days)        AS TotalAmountpaidby120days,
                     SUM(Amountpaidbymorethan120days) AS TotalAmountpaidbymorethan120days,
                     SUM(cmAmount)                  AS cmAmount
              FROM Result 
              GROUP BY MastercompanyId
          )
          SELECT VendorId, UPPER(vendorName) AS vendorName, UPPER(vendorCode) AS vendorCode, 
                 SUM(InvoiceAmount)             AS InvoiceAmount, 
                 SUM(BalanceAmount)             AS BalanceAmount, 
                 SUM(Amountpaidbylessthen0days) AS Amountpaidbylessthen0days, 
                 SUM(Amountpaidby30days)        AS Amountpaidby30days, 
                 SUM(Amountpaidby60days)        AS Amountpaidby60days, 
                 SUM(Amountpaidby90days)        AS Amountpaidby90days, 
                 SUM(Amountpaidby120days)       AS Amountpaidby120days, 
                 SUM(Amountpaidbymorethan120days) AS Amountpaidbymorethan120days,
                 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,			
                 TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days,
                 TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,
                 WC.cmAmount, DaysPastDue
          INTO #TempResult1 
          FROM Result FC
          INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
          GROUP BY VendorId, vendorName, vendorCode, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
                   TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days,
                   TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,
                   WC.cmAmount, DaysPastDue;
    
          ;WITH cteFinal AS (
              SELECT *, ROW_NUMBER() OVER (PARTITION BY CTE.VendorId, CTE.level1, CTE.level2, CTE.level3, CTE.level4, CTE.level5, CTE.level6, CTE.level7, CTE.level8, CTE.level9, CTE.level10 ORDER BY CTE.vendorId ASC) rNo
              FROM #TempResult1 CTE
          )
          SELECT MAX(FC.rNo) AS rNo, VendorId, vendorName, vendorCode, 
                 SUM(InvoiceAmount)             AS InvoiceAmount, 
                 SUM(BalanceAmount)             AS BalanceAmount, 
                 SUM(Amountpaidbylessthen0days) AS Amountpaidbylessthen0days, 
                 SUM(Amountpaidby30days)        AS Amountpaidby30days, 
                 SUM(Amountpaidby60days)        AS Amountpaidby60days, 
                 SUM(Amountpaidby90days)        AS Amountpaidby90days, 
                 SUM(Amountpaidby120days)       AS Amountpaidby120days, 
                 SUM(Amountpaidbymorethan120days) AS Amountpaidbymorethan120days,
                 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,			
                 TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days,
                 TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,
                 cmAmount,
                 CONVERT(INT, (SUM(ISNULL(DaysPastDue, 0)) / (MAX(ISNULL(FC.rNo, 1))))) AS DaysPastDue
          INTO #TempResult1Final 
          FROM cteFinal FC
          GROUP BY VendorId, vendorName, vendorCode, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
                   TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days,
                   TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days, cmAmount;

          SELECT @Count = COUNT(VendorId) FROM #TempResult1Final;
    
          SELECT @Count AS TotalRecordsCount, rNo, VendorId, vendorName, vendorCode, 
                 FORMAT(ISNULL(InvoiceAmount,             0), 'N', 'en-us') AS InvoiceAmount,
                 FORMAT(ISNULL(BalanceAmount,             0), 'N', 'en-us') AS BalanceAmount,	
                 FORMAT(ISNULL(Amountpaidbylessthen0days, 0), 'N', 'en-us') AS Amountpaidbylessthen0days,
                 FORMAT(ISNULL(Amountpaidby30days,        0), 'N', 'en-us') AS Amountpaidby30days,
                 FORMAT(ISNULL(Amountpaidby60days,        0), 'N', 'en-us') AS Amountpaidby60days,
                 FORMAT(ISNULL(Amountpaidby90days,        0), 'N', 'en-us') AS Amountpaidby90days,
                 FORMAT(ISNULL(Amountpaidby120days,       0), 'N', 'en-us') AS Amountpaidby120days,
                 FORMAT(ISNULL(Amountpaidbymorethan120days,0), 'N', 'en-us') AS Amountpaidbymorethan120days,	
                 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
                 TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days,
                 TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,
                 cmAmount, DaysPastDue
          FROM #TempResult1Final 
          ORDER BY 1
          OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY;
      END

      -- =====================================================================
      -- BRANCH 2: Detail / line-level view (Typeid <> 1)
      -- =====================================================================
      ELSE
      BEGIN
          -- -----------------------------------------------------------------
          -- Receiving Reconciliation (ELSE branch)
          -- DueDate source: rrh.DueDate (stored on document)
          -- -----------------------------------------------------------------
          SELECT * INTO #tempReceivingReconciliationElse FROM 
          (
              SELECT DISTINCT
                  V.VendorId                                            AS VendorId,
                  ISNULL(V.[VendorName], '')                            AS vendorName,
                  ISNULL(V.VendorCode, '')                              AS vendorCode,
                  rrh.CurrencyName                                      AS currencyCode,
                  ISNULL(vpd.OriginalAmount, 0)                         AS BalanceAmount,
                  ISNULL(vpd.RemainingAmount, 0)                        AS CurrentlAmount,
                  ISNULL(vpd.PaymentMade, 0)                            AS PaymentAmount,
                  rrh.ReceivingReconciliationNumber                      AS InvoiceNo,
                  rrh.InvoiceNum                                        AS invoiceNumber,
                  rrh.InvoiceDate                                       AS InvoiceDate,
                  ISNULL(ctm.NetDays, 0)                                AS NetDays,

                  -- Aging buckets based on rrh.DueDate (stored on document)
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) <= 0
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbylessthen0days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) > 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbymorethan120days,

                  rrh.ManagementStructureId                             AS ManagementStructureId,
                  CASE WHEN rrd.[Type] = 1 THEN 'PO-Inv' WHEN rrd.[Type] = 2 THEN 'RO-Inv' END AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  rrh.InvoiceTotal                                      AS InvoiceAmount,
                  0                                                     AS cmAmount,
                  0                                                     AS CreditMemoAmount,
                  rrh.DueDate                                           AS DueDate,
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
                  0                                                     AS IsCreditMemo,
                  0                                                     AS StatusId,
                  vpd.PaymentMade                                       AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(rrh.DueDate AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[ReceivingReconciliationHeader]           rrh  WITH (NOLOCK)       
              INNER JOIN [dbo].[ReceivingReconciliationDetails]    rrd  WITH (NOLOCK) ON rrh.ReceivingReconciliationId = rrd.ReceivingReconciliationId AND rrd.[Type] > 0       
              INNER JOIN [dbo].[VendorPaymentDetails]              vpd  WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
              INNER JOIN [dbo].[Vendor]                            v    WITH (NOLOCK) ON v.VendorId   = rrh.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                       ctm  WITH (NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
              LEFT JOIN  [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID  = @ModuleID        AND MSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'STOCK'
              LEFT JOIN  dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId AND UPPER(rrd.StockType) = 'NONSTOCK'
              LEFT JOIN  dbo.AssetManagementStructureDetails       AMSD WITH (NOLOCK) ON AMSD.ModuleID  = @AssetModuleID   AND AMSD.ReferenceID  = rrd.StocklineId AND UPPER(rrd.StockType) = 'ASSET' 
              LEFT JOIN  [dbo].[EntityStructureSetup]              ES   WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID			    
              WHERE rrh.[VendorId]               = ISNULL(@vendorId, rrh.VendorId)  			  
              AND CAST(rrh.[InvoiceDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND rrh.[MasterCompanyId]          = @mastercompanyid   
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND vpd.RemainingAmount > 0  
              AND rrh.InvoiceNum                 = ISNULL(@invoiceNum, rrh.InvoiceNum)
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level1Id   IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level1Id  IN (SELECT Item FROM dbo.SplitString(@Level1,  ','))))
              AND (ISNULL(@Level2,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level2Id   IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level2Id  IN (SELECT Item FROM dbo.SplitString(@Level2,  ','))))
              AND (ISNULL(@Level3,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level3Id   IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level3Id  IN (SELECT Item FROM dbo.SplitString(@Level3,  ','))))
              AND (ISNULL(@Level4,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level4Id   IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level4Id  IN (SELECT Item FROM dbo.SplitString(@Level4,  ','))))
              AND (ISNULL(@Level5,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level5Id   IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level5Id  IN (SELECT Item FROM dbo.SplitString(@Level5,  ','))))
              AND (ISNULL(@Level6,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level6Id   IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level6Id  IN (SELECT Item FROM dbo.SplitString(@Level6,  ','))))
              AND (ISNULL(@Level7,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level7Id   IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level7Id  IN (SELECT Item FROM dbo.SplitString(@Level7,  ','))))
              AND (ISNULL(@Level8,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level8Id   IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level8Id  IN (SELECT Item FROM dbo.SplitString(@Level8,  ','))))
              AND (ISNULL(@Level9,  '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level9Id   IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level9Id  IN (SELECT Item FROM dbo.SplitString(@Level9,  ','))))
              AND (ISNULL(@Level10, '') = '' OR (UPPER(rrd.StockType) = 'STOCK' AND MSD.Level10Id  IN (SELECT Item FROM dbo.SplitString(@Level10, ','))) OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ','))) OR (UPPER(rrd.StockType) = 'ASSET' AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ','))))
          ) F;

          -- -----------------------------------------------------------------
          -- Credit Memo (ELSE branch)
          -- DueDate source: CreatedDate + NetDays
          -- -----------------------------------------------------------------
          SELECT * INTO #tempCreditMemoElse FROM 
          (
              SELECT DISTINCT
                  VCM.[VendorId]                                        AS VendorId,
                  ISNULL(VEN.[VendorName], '')                          AS vendorName,
                  ISNULL(VEN.[VendorCode], '')                          AS vendorCode,
                  CR.[Code]                                             AS currencyCode,
                  ISNULL(VCD.ApplierdAmt, 0) * (-1)                     AS BalanceAmount,
                  ISNULL(VCD.ApplierdAmt, 0) * (-1)                     AS CurrentlAmount,
                  ISNULL(VCD.ApplierdAmt, 0) * (-1)                     AS PaymentAmount,
                  VCM.VendorCreditMemoNumber                            AS InvoiceNo,
                  ''                                                    AS invoiceNumber,
                  VCM.CreatedDate                                       AS InvoiceDate,
                  ISNULL(CTM.NetDays, 0)                                AS NetDays,

                  -- Aging buckets: DueDate = CreatedDate + NetDays
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) <= 0
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidbylessthen0days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) > 120
                       THEN VCD.ApplierdAmt * (-1) ELSE 0 END                  AS Amountpaidbymorethan120days,

                  SMSD.EntityMSID                                       AS ManagementStructureId,
                  'Credit Memo'                                         AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  VCD.ApplierdAmt * (-1)                                AS InvoiceAmount,
                  VCD.ApplierdAmt * (-1)                                AS cmAmount,
                  VCD.ApplierdAmt * (-1)                                AS CreditMemoAmount,
                  CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE) AS DueDate,
                  UPPER(SMSD.Level1Name)  AS level1,  UPPER(SMSD.Level2Name)  AS level2,
                  UPPER(SMSD.Level3Name)  AS level3,  UPPER(SMSD.Level4Name)  AS level4,
                  UPPER(SMSD.Level5Name)  AS level5,  UPPER(SMSD.Level6Name)  AS level6,
                  UPPER(SMSD.Level7Name)  AS level7,  UPPER(SMSD.Level8Name)  AS level8,
                  UPPER(SMSD.Level9Name)  AS level9,  UPPER(SMSD.Level10Name) AS level10,
                  VCM.MasterCompanyId,
                  1                                                     AS IsCreditMemo,
                  VCM.VendorCreditMemoStatusId                          AS StatusId,
                  0                                                     AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(CTM.NetDays, 0), VCM.CreatedDate) AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[VendorCreditMemo]                          VCM  WITH (NOLOCK)       
              INNER JOIN [dbo].[VendorCreditMemoDetail]              VCD  WITH (NOLOCK) ON VCM.VendorCreditMemoId  = VCD.VendorCreditMemoId 
              INNER JOIN [dbo].[Vendor]                              VEN  WITH (NOLOCK) ON VEN.VendorId            = VCM.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                         CTM  WITH (NOLOCK) ON CTM.CreditTermsId       = VEN.CreditTermsId
              LEFT JOIN  [dbo].[Currency]                            CR   WITH (NOLOCK) ON CR.CurrencyId           = VCM.CurrencyId  
              LEFT JOIN  [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
              LEFT JOIN  [dbo].[EntityStructureSetup]                SES  WITH (NOLOCK) ON SES.EntityStructureId   = SMSD.EntityMSID  	
              WHERE VCM.[VendorId]                = ISNULL(@vendorId, VCM.[VendorId])  			  
              AND CAST(VCM.[CreatedDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND VCM.[MasterCompanyId]           = @mastercompanyid   
              AND VCM.[VendorCreditMemoStatusId]  = @CMPostedStatusId
              AND ISNULL(VCD.ApplierdAmt, 0) > 0 
              AND VCM.VendorCreditMemoNumber      = ISNULL(@invoiceNum, VCM.VendorCreditMemoNumber)
              AND (ISNULL(@tagtype, '') = '' OR SES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR SMSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR SMSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR SMSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR SMSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR SMSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR SMSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR SMSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR SMSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR SMSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
          ) G;

          -- -----------------------------------------------------------------
          -- Manual Journal (ELSE branch)
          -- DueDate source: PostedDate + NetDays
          -- -----------------------------------------------------------------
          SELECT * INTO #tempManualJEElse FROM
          (
              SELECT DISTINCT
                  MJD.ReferenceId                                       AS VendorId,
                  ISNULL(V.[VendorName], '')                            AS vendorName,
                  ISNULL(V.VendorCode, '')                              AS vendorCode,
                  CR.Code                                               AS currencyCode,
                  0                                                     AS BalanceAmount,
                  0                                                     AS CurrentlAmount,
                  0                                                     AS PaymentAmount,
                  UPPER(MJH.JournalNumber)                              AS InvoiceNo,
                  ''                                                    AS invoiceNumber,
                  MJH.[PostedDate]                                      AS InvoiceDate,
                  ISNULL(CTM.NetDays, 0)                                AS NetDays,

                  -- Aging buckets: DueDate = PostedDate + NetDays
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) <= 0
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS AmountpaidbylessTHEN0days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE), GETUTCDATE()) > 120
                       THEN ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) ELSE 0 END AS Amountpaidbymorethan120days,

                  MJD.ManagementStructureId                             AS ManagementStructureId,
                  UPPER('Manual Journal Adjustment')                    AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  ISNULL(SUM(MJD.Credit), 0) - ISNULL(SUM(MJD.Debit), 0) AS InvoiceAmount,
                  0                                                     AS cmAmount,
                  0                                                     AS CreditMemoAmount,
                  CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.[PostedDate]) AS DATE) AS DueDate,
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
                  0                                                     AS IsCreditMemo,
                  0                                                     AS StatusId,
                  0                                                     AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.PostedDate) AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(DATEADD(DAY, ISNULL(ctm.NetDays, 0), MJH.PostedDate) AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[ManualJournalHeader]                            MJH  WITH (NOLOCK)   
              INNER JOIN [dbo].[ManualJournalDetails]                     MJD  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
              INNER JOIN [dbo].[VendorPaymentDetails]                     vpd  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = vpd.ManualJournalHeaderId
              INNER JOIN [dbo].[Vendor]                                   V    WITH (NOLOCK) ON V.VendorId                = MJD.ReferenceId 
              INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
              LEFT JOIN  [dbo].[EntityStructureSetup]                     ES   WITH (NOLOCK) ON ES.EntityStructureId      = MSD.EntityMSID 		   
              LEFT JOIN  [dbo].[CreditTerms]                              CTM  WITH (NOLOCK) ON CTM.CreditTermsId         = V.CreditTermsId
              LEFT JOIN  [dbo].[Currency]                                 CR   WITH (NOLOCK) ON CR.CurrencyId             = MJH.FunctionalCurrencyId
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL1  WITH (NOLOCK) ON MSD.Level1Id  = MSL1.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL2  WITH (NOLOCK) ON MSD.Level2Id  = MSL2.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL3  WITH (NOLOCK) ON MSD.Level3Id  = MSL3.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL4  WITH (NOLOCK) ON MSD.Level4Id  = MSL4.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL5  WITH (NOLOCK) ON MSD.Level5Id  = MSL5.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL6  WITH (NOLOCK) ON MSD.Level6Id  = MSL6.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL7  WITH (NOLOCK) ON MSD.Level7Id  = MSL7.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL8  WITH (NOLOCK) ON MSD.Level8Id  = MSL8.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL9  WITH (NOLOCK) ON MSD.Level9Id  = MSL9.ID
              LEFT JOIN  [dbo].[ManagementStructureLevel]                 MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
              WHERE MJD.ReferenceId              = ISNULL(@vendorId, MJD.ReferenceId)    
              AND MJH.[ManualJournalStatusId]    = @PostStatusId
              AND MJD.[ReferenceTypeId]          = 2  
              AND MJH.JournalNumber              = ISNULL(@invoiceNum, MJH.JournalNumber)
              AND vpd.RemainingAmount > 0
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND CAST(MJH.[PostedDate] AS DATE) <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND MJH.MasterCompanyId            = @mastercompanyid    
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
              GROUP BY MJD.ReferenceId, V.[VendorName], V.VendorCode, CR.Code, MJH.JournalNumber, 
                       MJH.[PostedDate], CTM.NetDays, MJD.UpdatedBy, MJD.ManagementStructureId, CTM.[Name], ctm.Code,
                       MSL1.Code, MSL1.[Description], MSL2.Code, MSL2.[Description], MSL3.Code, MSL3.[Description],
                       MSL4.Code, MSL4.[Description], MSL5.Code, MSL5.[Description], MSL6.Code, MSL6.[Description],
                       MSL7.Code, MSL7.[Description], MSL8.Code, MSL8.[Description], MSL9.Code, MSL9.[Description],
                       MSL10.Code, MSL10.[Description], MJH.MasterCompanyId
              HAVING SUM(ISNULL(MJD.Credit, 0)) - SUM(ISNULL(MJD.Debit, 0)) <> 0
          ) H;

          -- -----------------------------------------------------------------
          -- Non-PO Invoice (ELSE branch)
          -- DueDate source: NPH.DueDate (stored on document)
          -- -----------------------------------------------------------------
          SELECT * INTO #tempNonPODetailsElse FROM 
          (
              SELECT DISTINCT
                  V.VendorId                                            AS VendorId,
                  ISNULL(V.[VendorName], '')                            AS vendorName,
                  ISNULL(V.VendorCode, '')                              AS vendorCode,
                  CR.Code                                               AS currencyCode,
                  ISNULL(vpd.RemainingAmount, 0)                        AS BalanceAmount,
                  ISNULL(vpd.RemainingAmount, 0)                        AS CurrentlAmount,
                  ISNULL(vpd.PaymentMade, 0)                            AS PaymentAmount,
                  NPH.NPONumber                                         AS InvoiceNo,
                  NPH.InvoiceNumber                                     AS invoiceNumber,
                  NPH.InvoiceDate                                       AS InvoiceDate,
                  ISNULL(ctm.NetDays, 0)                                AS NetDays,

                  -- Aging buckets based on NPH.DueDate (stored on document)
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) <= 0
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbylessthen0days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 1  AND 30
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby30days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 31 AND 60
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby60days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 61 AND 90
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby90days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) BETWEEN 91 AND 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidby120days,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) > 120
                       THEN vpd.RemainingAmount ELSE 0 END              AS Amountpaidbymorethan120days,

                  NPH.ManagementStructureId                             AS ManagementStructureId,
                  'NPO-Inv'                                             AS DocType,
                  ''                                                    AS vendorRef,
                  ''                                                    AS Salesperson,
                  ctm.Name                                              AS Terms,
                  '0'                                                   AS FixRateAmount,
                  vpd.RemainingAmount                                   AS InvoiceAmount,
                  0                                                     AS cmAmount,
                  0                                                     AS CreditMemoAmount,
                  NPH.DueDate                                           AS DueDate,
                  UPPER(MSD.Level1Name)  AS level1,  UPPER(MSD.Level2Name)  AS level2,
                  UPPER(MSD.Level3Name)  AS level3,  UPPER(MSD.Level4Name)  AS level4,
                  UPPER(MSD.Level5Name)  AS level5,  UPPER(MSD.Level6Name)  AS level6,
                  UPPER(MSD.Level7Name)  AS level7,  UPPER(MSD.Level8Name)  AS level8,
                  UPPER(MSD.Level9Name)  AS level9,  UPPER(MSD.Level10Name) AS level10,
                  NPH.MasterCompanyId,
                  0                                                     AS IsCreditMemo,
                  0                                                     AS StatusId,
                  0                                                     AS InvoicePaidAmount,
                  CASE WHEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE()) > 0
                       THEN DATEDIFF(DAY, CAST(NPH.DueDate AS DATE), GETUTCDATE())
                       ELSE 0 END                                       AS DaysPastDue
              FROM [dbo].[NonPOInvoiceHeader]                           NPH WITH (NOLOCK)       
              INNER JOIN [dbo].[VendorPaymentDetails]                   vpd WITH (NOLOCK) ON NPH.NonPOInvoiceId  = vpd.NonPOInvoiceId      
              INNER JOIN [dbo].[Vendor]                                 v   WITH (NOLOCK) ON v.VendorId          = NPH.VendorId      
              LEFT JOIN  [dbo].[CreditTerms]                            ctm WITH (NOLOCK) ON ctm.CreditTermsId  = v.CreditTermsId
              INNER JOIN [dbo].[Currency]                               CR  WITH (NOLOCK) ON CR.CurrencyId       = NPH.CurrencyId      
              LEFT JOIN  [dbo].[NonPOInvoiceManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID    = NPH.NonPOInvoiceId
              LEFT JOIN  [dbo].[EntityStructureSetup]                   ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID         
              OUTER APPLY (
                  SELECT npdd.[NonPOInvoiceId], SUM(npdd.ExtendedPrice) AS InvoiceTotal 
                  FROM [dbo].[NonPOInvoicePartDetails] npdd WITH (NOLOCK)
                  WHERE npdd.[NonPOInvoiceId] = NPH.NonPOInvoiceId 
                  GROUP BY npdd.[NonPOInvoiceId]
              ) PartData
              WHERE NPH.[VendorId]               = ISNULL(@vendorId, NPH.VendorId)  			  
              AND CAST(NPH.PostedDate AS DATE)   <= CASE WHEN ISNULL(@id7, 0) = 1 THEN CAST(@ToDate AS DATE) ELSE CAST(@ToDate - 1 AS DATE) END 
              AND NPH.[MasterCompanyId]          = @mastercompanyid 
              AND vpd.[IsActive] = 1 AND vpd.[IsDeleted] = 0
              AND vpd.RemainingAmount > 0  
              AND NPH.NPONumber                  = ISNULL(@invoiceNum, NPH.NPONumber)
              AND (ISNULL(@tagtype, '') = '' OR ES.OrganizationTagTypeId IN (SELECT value FROM STRING_SPLIT(ISNULL(@tagtype, ''), ',')))      
              AND (ISNULL(@Level1,  '') = '' OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',')))      
              AND (ISNULL(@Level2,  '') = '' OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',')))      
              AND (ISNULL(@Level3,  '') = '' OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',')))      
              AND (ISNULL(@Level4,  '') = '' OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',')))      
              AND (ISNULL(@Level5,  '') = '' OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',')))      
              AND (ISNULL(@Level6,  '') = '' OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',')))      
              AND (ISNULL(@Level7,  '') = '' OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',')))      
              AND (ISNULL(@Level8,  '') = '' OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',')))      
              AND (ISNULL(@Level9,  '') = '' OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',')))      
              AND (ISNULL(@Level10, '') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10, ',')))
          ) I;
		
          -- -----------------------------------------------------------------
          -- Combine, format and output (Detail view)
          -- -----------------------------------------------------------------
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
                  UPPER(ISNULL(CTE.vendorName, ''))  AS vendorName,
                  UPPER(ISNULL(CTE.vendorCode, ''))  AS vendorCode,
                  UPPER(CTE.currencyCode)            AS currencyCode,   
                  CASE WHEN CTE.IsCreditMemo = 0 THEN (ISNULL(CTE.InvoiceAmount, 0) - ISNULL(CTE.InvoicePaidAmount, 0)) ELSE ISNULL(CTE.CreditMemoAmount, 0) END AS BalanceAmount, 
                  UPPER(CTE.InvoiceNo)               AS InvoiceNo,  
                  UPPER(ISNULL(CTE.invoiceNumber, '')) AS invoiceNumber,
                  CASE WHEN ISNULL(@IsDownload, 0) = 0 THEN FORMAT(CTE.InvoiceDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END AS InvoiceDate,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidbylessthen0days,   0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days   > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidbylessthen0days   END, 0) END AS Amountpaidbylessthen0days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby30days,          0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days          > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby30days          END, 0) END AS Amountpaidby30days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby60days,          0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days          > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby60days          END, 0) END AS Amountpaidby60days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby90days,          0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days          > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby90days          END, 0) END AS Amountpaidby90days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidby120days,         0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days         > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidby120days         END, 0) END AS Amountpaidby120days,
                  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CTE.Amountpaidbymorethan120days, 0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN ISNULL(CTE.CreditMemoAmount, 0) ELSE CTE.Amountpaidbymorethan120days END, 0) END AS Amountpaidbymorethan120days,
                  ISNULL(CTE.InvoiceAmount, 0)      AS InvoiceAmount, 
                  UPPER(CTE.DocType)                AS DocType,
                  UPPER(CTE.Terms)                  AS Terms,  
                  CASE WHEN CTE.IsCreditMemo = 0 THEN CASE WHEN ISNULL(@IsDownload, 0) = 0 THEN FORMAT(CTE.DueDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.DueDate, 107) END ELSE NULL END AS DueDate,
                  ISNULL(CTE.FixRateAmount, 0)      AS FixRateAmount,    
                  UPPER(CTE.level1)  AS level1, UPPER(CTE.level2)  AS level2, UPPER(CTE.level3)  AS level3,
                  UPPER(CTE.level4)  AS level4, UPPER(CTE.level5)  AS level5, UPPER(CTE.level6)  AS level6,
                  UPPER(CTE.level7)  AS level7, UPPER(CTE.level8)  AS level8, UPPER(CTE.level9)  AS level9,
                  UPPER(CTE.level10) AS level10,
                  CTE.MasterCompanyId,
                  DaysPastDue
              FROM CTE WITH (NOLOCK)   			
              INNER JOIN dbo.Vendor AS V WITH (NOLOCK) ON V.VendorId = CTE.VendorId    	  
              WHERE V.MasterCompanyId = @MasterCompanyId       
          ),
          ResultCount AS (SELECT COUNT(VendorId) AS totalItems FROM Result),
          WithTotal AS (
              SELECT MastercompanyId, 
                     FORMAT(SUM(InvoiceAmount),             'N', 'en-us') AS TotalInvoiceAmount,			
                     FORMAT(SUM(BalanceAmount),             'N', 'en-us') AS TotalBalanceAmount,
                     FORMAT(SUM(Amountpaidbylessthen0days), 'N', 'en-us') AS TotalAmountpaidbylessthen0days,
                     FORMAT(SUM(Amountpaidby30days),        'N', 'en-us') AS TotalAmountpaidby30days,
                     FORMAT(SUM(Amountpaidby60days),        'N', 'en-us') AS TotalAmountpaidby60days,
                     FORMAT(SUM(Amountpaidby90days),        'N', 'en-us') AS TotalAmountpaidby90days,
                     FORMAT(SUM(Amountpaidby120days),       'N', 'en-us') AS TotalAmountpaidby120days,
                     FORMAT(SUM(Amountpaidbymorethan120days),'N', 'en-us') AS TotalAmountpaidbymorethan120days				
              FROM Result
              GROUP BY MastercompanyId
          )
          SELECT VendorId, UPPER(vendorName) AS vendorName, UPPER(vendorCode) AS vendorCode, 
                 UPPER(InvoiceNo) AS InvoiceNo, UPPER(invoiceNumber) AS invoiceNumber,
                 InvoiceDate, InvoiceAmount, BalanceAmount,				
                 Amountpaidbylessthen0days, Amountpaidby30days, Amountpaidby60days, Amountpaidby90days,
                 Amountpaidby120days, Amountpaidbymorethan120days,
                 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,	
                 DocType, Terms, DueDate, currencyCode, FixRateAmount,
                 TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, 
                 TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,
                 DaysPastDue				 
          INTO #TempResult2 
          FROM Result FC
          INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId;
		 
          SELECT @Count = COUNT(VendorId) FROM #TempResult2;
		 
          SELECT @Count AS TotalRecordsCount, vendorName, vendorCode, InvoiceNo, invoiceNumber, InvoiceDate,
                 FORMAT(ISNULL(InvoiceAmount,             0), 'N', 'en-us') AS InvoiceAmount,
                 FORMAT(ISNULL(BalanceAmount,             0), 'N', 'en-us') AS BalanceAmount,	
                 FORMAT(ISNULL(Amountpaidbylessthen0days, 0), 'N', 'en-us') AS Amountpaidbylessthen0days,
                 FORMAT(ISNULL(Amountpaidby30days,        0), 'N', 'en-us') AS Amountpaidby30days,
                 FORMAT(ISNULL(Amountpaidby60days,        0), 'N', 'en-us') AS Amountpaidby60days,
                 FORMAT(ISNULL(Amountpaidby90days,        0), 'N', 'en-us') AS Amountpaidby90days,
                 FORMAT(ISNULL(Amountpaidby120days,       0), 'N', 'en-us') AS Amountpaidby120days,
                 FORMAT(ISNULL(Amountpaidbymorethan120days,0), 'N', 'en-us') AS Amountpaidbymorethan120days,
                 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
                 DocType, Terms, DueDate, currencyCode, FixRateAmount,
                 TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, 
                 TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,
                 DaysPastDue
          FROM #TempResult2      
          ORDER BY InvoiceDate
          OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY;  
      END;

  END TRY        
  BEGIN CATCH        
    SELECT  
        ERROR_NUMBER()    AS ErrorNumber,  
        ERROR_SEVERITY()  AS ErrorSeverity,  
        ERROR_STATE()     AS ErrorState,  
        ERROR_PROCEDURE() AS ErrorProcedure,  
        ERROR_LINE()      AS ErrorLine,  
        ERROR_MESSAGE()   AS ErrorMessage;  

    DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME(),       
            @AdhocComments varchar(150) = '[usprpt_GetAPAgingReport_SSRS]',        
            @ProcedureParameters varchar(3000) = 
                '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +        
                '@Parameter2 = ''' + CAST(ISNULL(@PageSize,   '') AS varchar(100)) +        
                '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +        
                '@Parameter4 = ''' + CAST(ISNULL(@strFilter, '') AS varchar(MAX)),      
            @ApplicationName varchar(100) = 'PAS';       

    EXEC SplogexceptiON 
        @DatabaseName        = @DatabaseName,        
        @AdhocComments       = @AdhocComments,        
        @ProcedureParameters = @ProcedureParameters,        
        @ApplicationName     = @ApplicationName,        
        @ErrorLogID          = @ErrorLogID OUTPUT;        
        
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);        
    RETURN (1);        
  END CATCH        
END;