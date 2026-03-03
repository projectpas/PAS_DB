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
	3    27-JAN-2026    RAJESH GAMI        Add InvoiceNumber
	4    05-FEB-2026    Amit Ghediya       Add filter
	5    09-FEB-2026    Rajesh Gami        Added NONSTOCK, ASSET Management Structure JOIN in Receiving Reconciliation
	6    16-FEB-2026    Amit Ghediya       Update NPO Invoice date from postedate to invoiced date.
	7    23-FEB-2026    Moin Bloch         Update Due date Getting From Direct Table.
	8    02-MAR-2026    Moin Bloch         Updated Due date For Manual JE
  --[dbo].[usprpt_GetAPAgingReport] 1,'2026-01-27',3654,2,null,null
***************************************************************************************************/        
CREATE   PROCEDURE [dbo].[usprpt_GetAPAgingReport]       
	@PageNumber int = 1,      
	@PageSize int = NULL,      
	@mastercompanyid int,      
	@xmlFilter XML,
	@SortColumn VARCHAR(50)=NULL,
	@SortOrder INT = NULL
AS        
BEGIN        
  SET NOCOUNT ON;        
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
        
  DECLARE @vendorId varchar(40) = NULL, 
  @Typeid varchar(40) = NULL, 
  @fromdate datetime,@todate datetime,@exludedebit varchar(40) = NULL,@tagtype varchar(50) = NULL,      
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
    --BEGIN TRANSACTION                     
      DECLARE @ModuleID INT = 2, @NonStockModuleID INT = 11 , @AssetModuleID INT =42; -- MS Module ID      
      DECLARE @Count BIGINT =0,@PostStatusId INT, @CMPostedStatusId INT,@MSModuleId INT = 0,@CMMSModuleID BIGINT = 61,@invoiceNum varchar(30) = '';
	  SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';
	  SELECT @CMPostedStatusId = [Id] FROM [dbo].[CreditMemoStatus] WHERE [Name] = 'Posted';
      SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	  SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	  SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='CreditMemoHeader';

	  DECLARE 
			  @VendorName VARCHAR(MAX) = NULL,
			  @VendorCode VARCHAR(MAX) = NULL,
			  @InvoiceAmount VARCHAR(MAX) = NULL,
			  @BalanceAmount VARCHAR(MAX) = NULL,
			  @Amountpaidbylessthen0days VARCHAR(MAX) = NULL,
			  @Amountpaidby30days VARCHAR(MAX) = NULL,
			  @Amountpaidby60days VARCHAR(MAX) = NULL,
			  @Amountpaidby90days VARCHAR(MAX) = NULL,
			  @Amountpaidby120days VARCHAR(MAX) = NULL,
			  @Amountpaidbymorethan120days VARCHAR(MAX) = NULL,
			  @DaysPastDue VARCHAR(MAX) = NULL,
			  @InvoiceDate datetime = NULL,
			  @InvoiceNo VARCHAR(MAX) = NULL,
			  @Terms VARCHAR(MAX) = NULL,
			  @DueDate datetime = NULL;

			  SELECT @todate = GETUTCDATE(),      
	  @vendorId = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Vendor Name(Optional)'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @vendorId END, 
	  @Typeid = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='viewType'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Typeid END,
	  --@exludedebit = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Exclude Debit Bal'       
	  --THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @exludedebit END,      
	  @tagtype=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @tagtype END,      
	  @level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,      
	  @level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,      
	  @level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,      
	  @level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,      
	  @level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,      
	  @level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,      
	  @level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,      
	  @level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,      
	  @level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,      
	  @level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 END,
	  
	  @VendorName=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='vendorName' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @VendorName end,
	  @VendorCode=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='vendorCode' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @VendorCode end,
	  @InvoiceAmount=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='invoiceAmount' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @InvoiceAmount end,
	 @BalanceAmount=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='balanceAmount' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @BalanceAmount end,
		@Amountpaidbylessthen0days=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='amountpaidbylessthen0days' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Amountpaidbylessthen0days end,
		@Amountpaidby30days=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='amountpaidby30days' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Amountpaidby30days end,
		@Amountpaidby60days=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='amountpaidby60days' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Amountpaidby60days end,
		@Amountpaidby90days=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='amountpaidby90days' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Amountpaidby90days end,
		@Amountpaidby120days=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='amountpaidby120days' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Amountpaidby120days end,
		@Amountpaidbymorethan120days=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='amountpaidbymorethan120days' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Amountpaidbymorethan120days end,
		@DaysPastDue=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='daysPastDue' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @DaysPastDue end,
		@InvoiceDate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='invoiceDate' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @InvoiceDate end,
		@InvoiceNo =case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='invoiceNo' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @InvoiceNo end,
		@Terms =case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='terms' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Terms end,
		@DueDate =case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='dueDate' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @DueDate end

   FROM      
    @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)
		
	
   IF ISNULL(@PageSize,0)=0      
   BEGIN  
			SELECT * INTO #tempReceivingReconciliationCount FROM 
			(SELECT rrh.ReceivingReconciliationId AS ReceivingReconciliationId 
					FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
			  INNER JOIN [dbo].[ReceivingReconciliationDetails] rrd WITH (NOLOCK) on rrh.ReceivingReconciliationId  = rrd.ReceivingReconciliationId AND rrd.[Type] > 0    
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId=rrh.VendorId      
			  LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId      
			  LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'STOCK'
			  LEFT JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'NONSTOCK'
			  LEFT JOIN dbo.AssetManagementStructureDetails AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID AND AMSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'ASSET' 
			  LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID                  
			  WHERE rrh.VendorId = ISNULL(@vendorId,rrh.VendorId)        
			  AND CAST(rrh.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) 
			  AND vpd.RemainingAmount > 0 
			  --AND rrh.InvoiceNum = ISNULL(@invoiceNum,rrh.InvoiceNum)
			  AND rrh.MasterCompanyId = @mastercompanyid			  
			  AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (	ISNULL(@Level1,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					)
				)
				AND (	ISNULL(@Level2,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					)
				)
				AND (	ISNULL(@Level3,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					)
				)
				AND (	ISNULL(@Level4,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					)
				)
				AND (	ISNULL(@Level5,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					)
				)
				AND (	ISNULL(@Level6,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					)
				)
				AND (	ISNULL(@Level7,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					)
				)
				AND (	ISNULL(@Level8,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					)
				)
				AND (	ISNULL(@Level9,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					)
				)
				AND (	ISNULL(@Level10,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					)
				)

			  --AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  --AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  --AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  --AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  --AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  --AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  --AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  --AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  --AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  --AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))       
			GROUP BY rrh.ReceivingReconciliationId )R

			SELECT * INTO #tempCreditMemoCount FROM 
			(SELECT DISTINCT (VCD.[VendorCreditMemoId]) AS VendorCreditMemoId		
			 FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)       
			  INNER JOIN [dbo].[VendorCreditMemoDetail] VCD WITH (NOLOCK) on VCM.VendorCreditMemoId = VCD.VendorCreditMemoId 
			  INNER JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VCM.CurrencyId  
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
			   LEFT JOIN [dbo].[EntityStructureSetup] SES WITH (NOLOCK) ON SES.EntityStructureId = SMSD.EntityMSID  	
			 WHERE VCM.[VendorId] = ISNULL(@vendorId,VCM.[VendorId])  			  
			  AND CAST(VCM.[CreatedDate] AS DATE) <= CAST(@ToDate AS DATE) AND VCM.[MasterCompanyId] = @mastercompanyid   
			  AND VCM.[VendorCreditMemoStatusId] = @CMPostedStatusId
			  AND ISNULL(VCD.ApplierdAmt, 0) > 0 
			  --AND VCM.VendorCreditMemoNumber = ISNULL(@invoiceNum,VCM.VendorCreditMemoNumber)
			  AND (ISNULL(@tagtype,'')='' OR SES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (ISNULL(@Level1,'') ='' OR SMSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  AND (ISNULL(@Level2,'') ='' OR SMSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  AND (ISNULL(@Level3,'') ='' OR SMSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  AND (ISNULL(@Level4,'') ='' OR SMSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  AND (ISNULL(@Level5,'') ='' OR SMSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  AND (ISNULL(@Level6,'') ='' OR SMSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  AND (ISNULL(@Level7,'') ='' OR SMSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  AND (ISNULL(@Level8,'') ='' OR SMSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  AND (ISNULL(@Level9,'') ='' OR SMSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))))S
		   
		    SELECT * INTO #tempManualJECount FROM 
			(SELECT MJD.ReferenceId AS BillingInvoicingId
			FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
			INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
			INNER JOIN [dbo].[Vendor] V  WITH (NOLOCK) ON V.VendorId = MJD.ReferenceId 
			INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
			 LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 		   
			LEFT JOIN  [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId
			 LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON  MSD.Level1Id = MSL1.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON  MSD.Level2Id = MSL2.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON  MSD.Level3Id = MSL3.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON  MSD.Level4Id = MSL4.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON  MSD.Level5Id = MSL5.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON  MSD.Level6Id = MSL6.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON  MSD.Level7Id = MSL7.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON  MSD.Level8Id = MSL8.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON  MSD.Level9Id = MSL9.ID
			 LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID	
		   WHERE MJD.ReferenceId = ISNULL(@vendorId,MJD.ReferenceId)   
		    AND MJH.[ManualJournalStatusId] = @PostStatusId
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@ToDate AS DATE) AND MJH.JournalNumber  = ISNULL(@invoiceNum,MJH.JournalNumber)
			AND MJH.mastercompanyid = @mastercompanyid      
			AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))      
			AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))) T

			SELECT * INTO #tempNonPODetailsCount FROM 
			(SELECT NPH.NonPOInvoiceId AS NonPOInvoiceId 
					FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)       
			  INNER JOIN [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK) on NPH.NonPOInvoiceId  = NPD.NonPOInvoiceId
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON NPH.NonPOInvoiceId = vpd.NonPOInvoiceId      
			  --LEFT JOIN dbo.VendorReadyToPayDetails vrp WITH (NOLOCK) ON NPH.NonPOInvoiceId = vrp.NonPOInvoiceId
			  --LEFT JOIN dbo.VendorReadyToPayHeader rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId=NPH.VendorId      
			  LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId      
			  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = NPH.CurrencyId      
			  LEFT JOIN dbo.NonPOInvoiceManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
			  LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID                  
			  WHERE NPH.VendorId = ISNULL(@vendorId,NPH.VendorId)        
			  AND CAST(NPH.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) 
			  AND vpd.RemainingAmount > 0  
			  --AND NPH.NPONumber  = ISNULL(@invoiceNum,NPH.NPONumber)
			  AND NPH.MasterCompanyId = @mastercompanyid			  
			  AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))        
			GROUP BY NPH.NonPOInvoiceId )U

       SELECT @PageSize=COUNT(*)       
			FROM (
					Select * from #tempReceivingReconciliationCount
					UNION ALL
					Select * from #tempCreditMemoCount
					UNION ALL
					Select * from #tempManualJECount
					UNION ALL
					Select * from #tempNonPODetailsCount		
		) TEMP 
   END    
   SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END      
   SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END      
    IF(@Typeid = 1)
	BEGIN
	--	Receiving Reconciliation  --
		SELECT * INTO #tempReceivingReconciliation FROM 
		(SELECT DISTINCT (V.VendorId) AS VendorId, ISNULL(V.[VendorName],'') 'vendorName' ,  ISNULL(V.VendorCode,'') 'vendorCode' ,  (rrh.CurrencyName) AS  'currencyCode', ISNULL(vpd.OriginalAmount,0) AS 'BalanceAmount',      
                    ISNULL(vpd.RemainingAmount,0)  AS 'CurrentlAmount',  ISNULL(vpd.PaymentMade,0)  AS 'PaymentAmount', (rrh.ReceivingReconciliationNumber) AS 'InvoiceNo',rrh.InvoiceNum as 'invoiceNumber',  rrh.InvoiceDate AS InvoiceDate,ISNULL(ctm.NetDays,0) AS NetDays, 
					(CASE WHEN DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) <= 0 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
			
					(CASE WHEN DATEDIFF(DAY, CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 30 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 60 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 90 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 120 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 120 THEN vpd.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
					(rrh.ManagementStructureId) AS ManagementStructureId, 'AP-Inv' AS 'DocType','' AS 'vendorRef', '' AS 'Salesperson',ctm.Name AS 'Terms', '0' AS 'FixRateAmount', rrh.InvoiceTotal AS 'InvoiceAmount',
					0 AS 'cmAmount',0 AS CreditMemoAmount,	--DATEADD(DAY, ctm.NetDays,rrh.InvoiceDate) AS 'DueDate', 
					rrh.DueDate AS 'DueDate', 										
					UPPER(COALESCE(MSD.Level1Name, NMSD.Level1Name, AMSD.Level1Name)) AS Level1,
					UPPER(COALESCE(MSD.Level2Name, NMSD.Level2Name, AMSD.Level2Name)) AS Level2,
					UPPER(COALESCE(MSD.Level3Name, NMSD.Level3Name, AMSD.Level3Name)) AS Level3,
					UPPER(COALESCE(MSD.Level4Name, NMSD.Level4Name, AMSD.Level4Name)) AS Level4,
					UPPER(COALESCE(MSD.Level5Name, NMSD.Level5Name, AMSD.Level5Name)) AS Level5,
					UPPER(COALESCE(MSD.Level6Name, NMSD.Level6Name, AMSD.Level6Name)) AS Level6,
					UPPER(COALESCE(MSD.Level7Name, NMSD.Level7Name, AMSD.Level7Name)) AS Level7,
					UPPER(COALESCE(MSD.Level8Name, NMSD.Level8Name, AMSD.Level8Name)) AS Level8,
					UPPER(COALESCE(MSD.Level9Name, NMSD.Level9Name, AMSD.Level9Name)) AS Level9,
					UPPER(COALESCE(MSD.Level10Name, NMSD.Level10Name, AMSD.Level10Name)) AS Level10

					,rrh.MasterCompanyId,0 AS IsCreditMemo,0 AS StatusId
				   ,vpd.PaymentMade AS InvoicePaidAmount
				   ,CASE WHEN (DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
         FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
			  INNER JOIN [dbo].[ReceivingReconciliationDetails] rrd WITH (NOLOCK) on rrh.ReceivingReconciliationId  = rrd.ReceivingReconciliationId AND rrd.[Type] > 0       
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId=rrh.VendorId     
			  --INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = rrh.CurrencyId     
			  --LEFT JOIN [dbo].[VendorReadyToPayDetails] vrp WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vrp.ReceivingReconciliationId
			  --LEFT JOIN [dbo].[VendorReadyToPayHeader] rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			  LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId			  
			  LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'STOCK'
			  LEFT JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'NONSTOCK'
			  LEFT JOIN dbo.AssetManagementStructureDetails AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID AND AMSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'ASSET' 
			  LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK)ON ES.EntityStructureId = MSD.EntityMSID                
			  WHERE rrh.[VendorId] = ISNULL(@vendorId,rrh.VendorId)        
			  AND CAST(rrh.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) AND rrh.[MasterCompanyId] = @mastercompanyid   
			  AND vpd.RemainingAmount > 0
			  AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (	ISNULL(@Level1,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					)
				)
				AND (	ISNULL(@Level2,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					)
				)
				AND (	ISNULL(@Level3,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					)
				)
				AND (	ISNULL(@Level4,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					)
				)
				AND (	ISNULL(@Level5,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					)
				)
				AND (	ISNULL(@Level6,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					)
				)
				AND (	ISNULL(@Level7,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					)
				)
				AND (	ISNULL(@Level8,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					)
				)
				AND (	ISNULL(@Level9,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					)
				)
				AND (	ISNULL(@Level10,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					)
				)
			  ) A

	-- Credit Memo --
		SELECT * INTO #tempCreditMemo FROM 
		 (SELECT DISTINCT (VCM.[VendorId]) AS VendorId,ISNULL(VEN.[VendorName],'') 'vendorName' ,  ISNULL(VEN.[VendorCode],'') 'vendorCode' ,(CR.[Code]) AS  'currencyCode',   
					ISNULL(VCD.ApplierdAmt,0) AS 'BalanceAmount',ISNULL(VCD.ApplierdAmt,0)  AS 'CurrentlAmount',ISNULL(VCD.ApplierdAmt,0)  AS 'PaymentAmount',(VCM.VendorCreditMemoNumber) AS 'InvoiceNo','' as 'invoiceNumber', 					
					 VCM.CreatedDate AS InvoiceDate,ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END), GETUTCDATE()) <= 0 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 30 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 60 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 90 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 120 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 120 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidbymorethan120days,
					(SMSD.EntityMSID) AS ManagementStructureId, 'Credit Memo' AS 'DocType','' AS 'vendorRef', '' AS 'Salesperson', ctm.Name AS 'Terms', '0' AS 'FixRateAmount', 
					VCD.ApplierdAmt AS 'InvoiceAmount', VCD.ApplierdAmt AS 'cmAmount',VCD.ApplierdAmt AS CreditMemoAmount,DATEADD(DAY, ctm.NetDays,NULL) AS 'DueDate',  
					UPPER(SMSD.Level1Name) AS level1, UPPER(SMSD.Level2Name) AS level2, UPPER(SMSD.Level3Name) AS level3,UPPER(SMSD.Level4Name) AS level4,UPPER(SMSD.Level5Name) AS level5,       
					UPPER(SMSD.Level6Name) AS level6, UPPER(SMSD.Level7Name) AS level7,UPPER(SMSD.Level8Name) AS level8, UPPER(SMSD.Level9Name) AS level9,UPPER(SMSD.Level10Name) AS level10,
					VCM.MasterCompanyId,1 AS IsCreditMemo,VCM.VendorCreditMemoStatusId AS StatusId,0 AS InvoicePaidAmount
					,CASE WHEN (DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
			 FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)       
			  INNER JOIN [dbo].[VendorCreditMemoDetail] VCD WITH (NOLOCK) on VCM.VendorCreditMemoId = VCD.VendorCreditMemoId 
			  INNER JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VCM.CurrencyId  
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
			   LEFT JOIN [dbo].[EntityStructureSetup] SES WITH (NOLOCK) ON SES.EntityStructureId = SMSD.EntityMSID  	
			 WHERE VCM.[VendorId] = ISNULL(@vendorId,VCM.[VendorId])  			  
			  AND CAST(VCM.[CreatedDate] AS DATE) <= CAST(@ToDate AS DATE) AND VCM.[MasterCompanyId] = @mastercompanyid   
			  AND VCM.[VendorCreditMemoStatusId] = @CMPostedStatusId
			  AND ISNULL(VCD.ApplierdAmt, 0) > 0
			  AND (ISNULL(@tagtype,'')='' OR SES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (ISNULL(@Level1,'') ='' OR SMSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  AND (ISNULL(@Level2,'') ='' OR SMSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  AND (ISNULL(@Level3,'') ='' OR SMSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  AND (ISNULL(@Level4,'') ='' OR SMSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  AND (ISNULL(@Level5,'') ='' OR SMSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  AND (ISNULL(@Level6,'') ='' OR SMSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  AND (ISNULL(@Level7,'') ='' OR SMSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  AND (ISNULL(@Level8,'') ='' OR SMSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  AND (ISNULL(@Level9,'') ='' OR SMSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))))B
		
	
	-- Manual JE ---
		SELECT * INTO #tempManualJE FROM 
			(SELECT DISTINCT (MJD.ReferenceId) AS VendorId, ISNULL(V.[VendorName],'') 'vendorName' ,ISNULL(V.VendorCode,'') 'vendorCode' , (CR.Code) AS  'currencyCode',  
					 0 AS 'BalanceAmount',       -- need to discuss
					 0 AS 'CurrentlAmount',      -- need to discuss
			         0 AS 'PaymentAmount', UPPER(MJH.JournalNumber) AS 'InvoiceNo','' as 'invoiceNumber', MJH.[PostedDate] AS InvoiceDate, ISNULL(CTM.NetDays,0) AS NetDays,
			   (CASE WHEN DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
					 WHEN ctm.Code='CIA' THEN -1      
					 WHEN ctm.Code='CreditCard' THEN -1      
					 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) <= 0 THEN  ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 30 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby30days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0) , GETUTCDATE())<= 60 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby60days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 90 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby90days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 120 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby120days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
               MJD.ManagementStructureId AS ManagementStructureId,UPPER('Manual Journal Adjustment') AS 'DocType','' AS 'vendorRef', ''AS 'Salesperson',ctm.Name AS 'Terms', '0' AS 'FixRateAmount', 			        
			   ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) AS 'InvoiceAmount', 0 AS 'cmAmount',0 AS CreditMemoAmount, DATEADD(DAY, ctm.NetDays,MJH.[PostedDate]) AS 'DueDate', 
			   UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1, UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,       
			   UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3, UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,       
			   UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5, UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,       
			   UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7, UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,       
			   UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9, UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
			   MJH.MasterCompanyId,0 AS IsCreditMemo,0 AS StatusId,
			   0 AS InvoicePaidAmount   -- need to discuss 		
			   ,CASE WHEN (DATEDIFF(DAY, CAST(MJH.PostedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(MJH.PostedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
		FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
		  INNER JOIN [dbo].[Vendor] V  WITH (NOLOCK) ON V.VendorId = MJD.ReferenceId 
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 		   
		   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId
		   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON  MSD.Level1Id = MSL1.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON  MSD.Level2Id = MSL2.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON  MSD.Level3Id = MSL3.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON  MSD.Level4Id = MSL4.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON  MSD.Level5Id = MSL5.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON  MSD.Level6Id = MSL6.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON  MSD.Level7Id = MSL7.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON  MSD.Level8Id = MSL8.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON  MSD.Level9Id = MSL9.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
	   WHERE MJD.ReferenceId = ISNULL(@vendorId,MJD.ReferenceId)    
			AND MJH.[ManualJournalStatusId] = @PostStatusId
			AND MJD.[ReferenceTypeId] = 2 
			--AND ISNULL(MJD.Credit,0) - ISNULL(MJD.Debit,0) <> 0
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@ToDate AS DATE) AND MJH.MasterCompanyId = @mastercompanyid    
			AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			AND (ISNULL(@Level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
		GROUP BY MJD.ReferenceId,V.[VendorName],V.VendorCode,CR.Code,MJH.JournalNumber, 
			MJH.[PostedDate],CTM.NetDays,MJD.UpdatedBy,MJD.ManagementStructureId,CTM.[Name],ctm.Code,
			MSL1.Code,MSL1.[Description],
			MSL2.Code, MSL2.[Description],
			MSL3.Code, MSL3.[Description],
			MSL4.Code, MSL4.[Description],
			MSL5.Code, MSL5.[Description],
			MSL6.Code, MSL6.[Description],
			MSL7.Code, MSL7.[Description],
			MSL8.Code, MSL8.[Description],
			MSL9.Code, MSL9.[Description],
			MSL10.Code , MSL10.[Description],
			MJH.MasterCompanyId

		HAVING SUM(ISNULL(MJD.Credit, 0)) - SUM(ISNULL(MJD.Debit, 0)) <> 0)C
		
	
	--	NonPO Details  --
		SELECT * INTO #tempNonPODetails FROM 
		(SELECT DISTINCT (V.VendorId) AS VendorId, ISNULL(V.[VendorName],'') 'vendorName' , ISNULL(V.VendorCode,'') 'vendorCode' ,(CR.Code) AS  'currencyCode',ISNULL(vpd.RemainingAmount,0) AS 'BalanceAmount',      
                    ISNULL(vpd.RemainingAmount,0)  AS 'CurrentlAmount',ISNULL(vpd.PaymentMade,0)  AS 'PaymentAmount', (NPH.NPONumber) AS 'InvoiceNo',NPH.InvoiceNumber as 'invoiceNumber',  NPH.InvoiceDate AS InvoiceDate, ISNULL(ctm.NetDays,0) AS NetDays, 
					(CASE WHEN DATEDIFF(DAY, CAST(NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) <= 0 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 30 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())<= 60 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 90 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE()) <= 120 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END), GETUTCDATE()) > 120 THEN vpd.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
					(NPH.ManagementStructureId) AS ManagementStructureId, 'NPO-Inv' AS 'DocType','' AS 'vendorRef','' AS 'Salesperson',ctm.Name AS 'Terms','0' AS 'FixRateAmount',      
					vpd.RemainingAmount AS 'InvoiceAmount',0 AS 'cmAmount',0 AS CreditMemoAmount,NPH.DueDate AS 'DueDate',UPPER(MSD.Level1Name) AS level1,        
					UPPER(MSD.Level2Name) AS level2,UPPER(MSD.Level3Name) AS level3, UPPER(MSD.Level4Name) AS level4,UPPER(MSD.Level5Name) AS level5,UPPER(MSD.Level6Name) AS level6,       
					UPPER(MSD.Level7Name) AS level7, UPPER(MSD.Level8Name) AS level8,UPPER(MSD.Level9Name) AS level9,UPPER(MSD.Level10Name) AS level10,NPH.MasterCompanyId,
					0 AS IsCreditMemo,0 AS StatusId ,0 AS InvoicePaidAmount
					,CASE WHEN (DATEDIFF(DAY, CAST(NPH.DueDate AS DATETIME) , GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(NPH.DueDate AS DATETIME) , GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
         FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)    
			   INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId=NPH.VendorId      
			   INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON NPH.NonPOInvoiceId = vpd.NonPOInvoiceId
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = NPH.CurrencyId
			   --LEFT JOIN [dbo].[VendorReadyToPayDetails] vrp WITH (NOLOCK) ON NPH.NonPOInvoiceId = vrp.NonPOInvoiceId
			   --LEFT JOIN [dbo].[VendorReadyToPayHeader] rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
			   LEFT JOIN [dbo].[NonPOInvoiceManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
			   LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
			   OUTER APPLY (SELECT npdd.[NonPOInvoiceId], SUM(npdd.ExtendedPrice) as InvoiceTotal FROM [dbo].[NonPOInvoicePartDetails] npdd WITH(NOLOCK)
							WHERE npdd.[NonPOInvoiceId] = NPH.NonPOInvoiceId GROUP BY npdd.[NonPOInvoiceId]) PartData
			  WHERE NPH.[VendorId] = ISNULL(@vendorId,NPH.VendorId)        
			  AND CAST(NPH.PostedDate AS DATE) <= CAST(@ToDate AS DATE) AND NPH.[MasterCompanyId] = @mastercompanyid   
			  AND vpd.RemainingAmount > 0
			  AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))))D
	
		;WITH CTE AS (   
               SELECT * FROM #tempReceivingReconciliation
			   UNION ALL
			   SELECT * FROM #tempCreditMemo
			   UNION ALL
			   SELECT * FROM #tempManualJE
			   UNION ALL
			   SELECT * FROM #tempNonPODetails
		)    
	, Result AS(      
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

   ) , ResultCount AS(SELECT COUNT(VendorId) AS totalItems FROM Result)     
  
   ,WithTotal (MastercompanyId, 
               TotalInvoiceAmount, --TotalcmAmount, TotalcmAmountUsed, 
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
			--(SELECT COUNT(1) FROM Result rs WHERE fc.vendorId = rs.vendorId) AS vendorCOUNT,
			--MAX(FC.rNo) rNo,
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
			--,CONVERT(INT,(SUM(ISNULL(DaysPastDue,0))/2)) AS DaysPastDue
			,DaysPastDue
			
   INTO #TempResult1 FROM  Result FC
   INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
   GROUP BY VendorId,vendorName,vendorCode,level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
            ,TotalInvoiceAmount,TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days, TotalAmountpaidby60days,
			TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,WC.cmAmount
			,DaysPastDue
    
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
			,CONVERT(INT,(SUM(ISNULL(DaysPastDue,0))/(MAX(ISNULL(FC.rNo,1))))) AS DaysPastDue
			--,DaysPastDue
			
   INTO #TempResult1Final FROM  cteFinal FC
   GROUP BY VendorId,vendorName,vendorCode,level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
            ,TotalInvoiceAmount,TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days, TotalAmountpaidby60days,
			TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,cmAmount
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
	
	FROM #TempResult1Final 
    --ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN 1 ELSE 1       
    --END      
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
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbymorethan120days') THEN Amountpaidbymorethan120days END DESC
	OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
    
	/**** ELSE PART *****/   

	END
	ELSE
	BEGIN
		--	Receiving Reconciliation  --
		SELECT * INTO #tempReceivingReconciliationElse FROM 
		(SELECT DISTINCT (V.VendorId) AS VendorId,  ISNULL(V.[VendorName],'') 'vendorName' , ISNULL(V.VendorCode,'') 'vendorCode' , (rrh.CurrencyName) AS  'currencyCode',      
                    ISNULL(vpd.OriginalAmount,0) AS 'BalanceAmount',  ISNULL(vpd.RemainingAmount,0)  AS 'CurrentlAmount',  ISNULL(vpd.PaymentMade,0)  AS 'PaymentAmount',      
                    (rrh.ReceivingReconciliationNumber) AS 'InvoiceNo',rrh.InvoiceNum as 'invoiceNumber', rrh.InvoiceDate AS InvoiceDate, ISNULL(ctm.NetDays,0) AS NetDays,      						
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST( rrh.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN vpd.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
					(rrh.ManagementStructureId) AS ManagementStructureId, (CASE WHEN rrd.[Type] = 1 THEN 'PO-Inv' WHEN rrd.[Type] = 2 THEN 'RO-Inv' END) AS 'DocType',
					'' AS 'vendorRef', '' AS 'Salesperson', ctm.Name AS 'Terms', '0' AS 'FixRateAmount',rrh.InvoiceTotal AS 'InvoiceAmount',      
					0 AS 'cmAmount',0 AS CreditMemoAmount,--DATEADD(DAY, ctm.NetDays,rrh.InvoiceDate) AS 'DueDate',     
					rrh.DueDate AS 'DueDate',    
					UPPER(COALESCE(MSD.Level1Name, NMSD.Level1Name, AMSD.Level1Name)) AS Level1,
					UPPER(COALESCE(MSD.Level2Name, NMSD.Level2Name, AMSD.Level2Name)) AS Level2,
					UPPER(COALESCE(MSD.Level3Name, NMSD.Level3Name, AMSD.Level3Name)) AS Level3,
					UPPER(COALESCE(MSD.Level4Name, NMSD.Level4Name, AMSD.Level4Name)) AS Level4,
					UPPER(COALESCE(MSD.Level5Name, NMSD.Level5Name, AMSD.Level5Name)) AS Level5,
					UPPER(COALESCE(MSD.Level6Name, NMSD.Level6Name, AMSD.Level6Name)) AS Level6,
					UPPER(COALESCE(MSD.Level7Name, NMSD.Level7Name, AMSD.Level7Name)) AS Level7,
					UPPER(COALESCE(MSD.Level8Name, NMSD.Level8Name, AMSD.Level8Name)) AS Level8,
					UPPER(COALESCE(MSD.Level9Name, NMSD.Level9Name, AMSD.Level9Name)) AS Level9,
					UPPER(COALESCE(MSD.Level10Name, NMSD.Level10Name, AMSD.Level10Name)) AS Level10
					,rrh.MasterCompanyId,0 AS IsCreditMemo,0 AS StatusId ,vpd.PaymentMade AS InvoicePaidAmount
					,CASE WHEN (DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(rrh.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
         FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
			  INNER JOIN [dbo].[ReceivingReconciliationDetails] rrd WITH (NOLOCK) on rrh.ReceivingReconciliationId  = rrd.ReceivingReconciliationId AND rrd.[Type] > 0       
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
			   --LEFT JOIN [dbo].[VendorReadyToPayDetails] vrp WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vrp.ReceivingReconciliationId
			   --LEFT JOIN [dbo].[VendorReadyToPayHeader] rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId = rrh.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
			  --INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = rrh.CurrencyId      
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'STOCK'
			   LEFT JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NonStockModuleID AND NMSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'NONSTOCK'
			   LEFT JOIN dbo.AssetManagementStructureDetails AMSD WITH (NOLOCK) ON AMSD.ModuleID = @AssetModuleID AND AMSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'ASSET' 
			   LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID			    
			  --WHERE rrh.[VendorId] = ISNULL(@vendorId,rrh.VendorId)  			  
			  --AND CAST(rrh.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) AND rrh.[MasterCompanyId] = @mastercompanyid      
			  --AND vpd.RemainingAmount > 0  --AND rrh.InvoiceNum = ISNULL(@invoiceNum,rrh.InvoiceNum)
			  WHERE rrh.[VendorId] = ISNULL(@vendorId,rrh.VendorId)        
			  AND CAST(rrh.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) AND rrh.[MasterCompanyId] = @mastercompanyid   
			  AND vpd.RemainingAmount > 0 --AND rrh.InvoiceNum = rrh.InvoiceNum
			  AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (	ISNULL(@Level1,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level1Id IN (SELECT Item FROM dbo.SplitString(@Level1, ',')))
					)
				)
				AND (	ISNULL(@Level2,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level2Id IN (SELECT Item FROM dbo.SplitString(@Level2, ',')))
					)
				)
				AND (	ISNULL(@Level3,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level3Id IN (SELECT Item FROM dbo.SplitString(@Level3, ',')))
					)
				)
				AND (	ISNULL(@Level4,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level4Id IN (SELECT Item FROM dbo.SplitString(@Level4, ',')))
					)
				)
				AND (	ISNULL(@Level5,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level5Id IN (SELECT Item FROM dbo.SplitString(@Level5, ',')))
					)
				)
				AND (	ISNULL(@Level6,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level6Id IN (SELECT Item FROM dbo.SplitString(@Level6, ',')))
					)
				)
				AND (	ISNULL(@Level7,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level7Id IN (SELECT Item FROM dbo.SplitString(@Level7, ',')))
					)
				)
				AND (	ISNULL(@Level8,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level8Id IN (SELECT Item FROM dbo.SplitString(@Level8, ',')))
					)
				)
				AND (	ISNULL(@Level9,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level9Id IN (SELECT Item FROM dbo.SplitString(@Level9, ',')))
					)
				)
				AND (	ISNULL(@Level10,'') = ''
					OR (
						(UPPER(rrd.StockType) = 'STOCK'    AND MSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					 OR (UPPER(rrd.StockType) = 'NONSTOCK' AND NMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					 OR (UPPER(rrd.StockType) = 'ASSET'    AND AMSD.Level10Id IN (SELECT Item FROM dbo.SplitString(@Level10, ',')))
					)
				)
			  ) F

			-- SELECT * FROM #tempReceivingReconciliationElse
		-- Credit Memo --
		SELECT * INTO #tempCreditMemoElse FROM 
		(SELECT DISTINCT (VCM.[VendorId]) AS VendorId,
					ISNULL(VEN.[VendorName],'') 'vendorName' , ISNULL(VEN.[VendorCode],'') 'vendorCode' ,(CR.[Code]) AS  'currencyCode',   
					ISNULL(VCD.ApplierdAmt,0) AS 'BalanceAmount', ISNULL(VCD.ApplierdAmt,0)  AS 'CurrentlAmount',ISNULL(VCD.ApplierdAmt,0)  AS 'PaymentAmount',  
					(VCM.VendorCreditMemoNumber) AS 'InvoiceNo','' as 'invoiceNumber', VCM.CreatedDate AS InvoiceDate,ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN VCD.ApplierdAmt ELSE 0 END) AS Amountpaidbymorethan120days,
					(SMSD.EntityMSID) AS ManagementStructureId,'Credit Memo' AS 'DocType','' AS 'vendorRef','' AS 'Salesperson',      
					ctm.Name AS 'Terms','0' AS 'FixRateAmount',VCD.ApplierdAmt AS 'InvoiceAmount', VCD.ApplierdAmt AS 'cmAmount', 
					VCD.ApplierdAmt AS CreditMemoAmount,DATEADD(DAY, ctm.NetDays,NULL) AS 'DueDate',  
					UPPER(SMSD.Level1Name) AS level1,UPPER(SMSD.Level2Name) AS level2, UPPER(SMSD.Level3Name) AS level3, UPPER(SMSD.Level4Name) AS level4,UPPER(SMSD.Level5Name) AS level5,       
					UPPER(SMSD.Level6Name) AS level6,UPPER(SMSD.Level7Name) AS level7, UPPER(SMSD.Level8Name) AS level8, UPPER(SMSD.Level9Name) AS level9,UPPER(SMSD.Level10Name) AS level10,
					VCM.MasterCompanyId,1 AS IsCreditMemo,VCM.VendorCreditMemoStatusId AS StatusId,0 AS InvoicePaidAmount
					,CASE WHEN (DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
			 FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)       
			  INNER JOIN [dbo].[VendorCreditMemoDetail] VCD WITH (NOLOCK) on VCM.VendorCreditMemoId = VCD.VendorCreditMemoId 
			  INNER JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VCM.CurrencyId  
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
			   LEFT JOIN [dbo].[EntityStructureSetup] SES WITH (NOLOCK) ON SES.EntityStructureId = SMSD.EntityMSID  	
			 WHERE VCM.[VendorId] = ISNULL(@vendorId,VCM.[VendorId])  			  
			  AND CAST(VCM.[CreatedDate] AS DATE) <= CAST(@ToDate AS DATE) AND VCM.[MasterCompanyId] = @mastercompanyid   
			  AND VCM.[VendorCreditMemoStatusId] = @CMPostedStatusId
			  AND ISNULL(VCD.ApplierdAmt, 0) > 0 
			  --AND VCM.VendorCreditMemoNumber = ISNULL(@invoiceNum,VCM.VendorCreditMemoNumber)
			  AND (ISNULL(@tagtype,'')='' OR SES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			  AND (ISNULL(@Level1,'') ='' OR SMSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  AND (ISNULL(@Level2,'') ='' OR SMSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  AND (ISNULL(@Level3,'') ='' OR SMSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  AND (ISNULL(@Level4,'') ='' OR SMSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  AND (ISNULL(@Level5,'') ='' OR SMSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  AND (ISNULL(@Level6,'') ='' OR SMSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  AND (ISNULL(@Level7,'') ='' OR SMSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  AND (ISNULL(@Level8,'') ='' OR SMSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  AND (ISNULL(@Level9,'') ='' OR SMSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))) G

			 --select * from #tempCreditMemoElse
		-- Manual JE ---
		SELECT * INTO #tempManualJEElse FROM
		(SELECT DISTINCT (MJD.ReferenceId) AS VendorId, ISNULL(V.[VendorName],'') 'vendorName' , ISNULL(V.VendorCode,'') 'vendorCode' ,   (CR.Code) AS  'currencyCode',  
					 0 AS 'BalanceAmount',       -- need to discuss
					 0 AS 'CurrentlAmount',      -- need to discuss
			         0 AS 'PaymentAmount', UPPER(MJH.JournalNumber) AS 'InvoiceNo','' as 'invoiceNumber', MJH.[PostedDate] AS InvoiceDate,      
			         ISNULL(CTM.NetDays,0) AS NetDays,
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
					 WHEN ctm.Code='CIA' THEN -1      
					 WHEN ctm.Code='CreditCard' THEN -1      
					 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL (ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby30days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby60days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby90days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidby120days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
               MJD.ManagementStructureId AS ManagementStructureId, 
			   UPPER('Manual Journal Adjustment') AS 'DocType', '' AS 'vendorRef',''AS 'Salesperson',ctm.Name AS 'Terms', '0' AS 'FixRateAmount', 			        			   			   
			   ISNULL(SUM(MJD.Credit),0) - ISNULL(SUM(MJD.Debit),0) AS 'InvoiceAmount',0 AS 'cmAmount', 0 AS CreditMemoAmount, DATEADD(DAY, ctm.NetDays, MJH.[PostedDate]) AS 'DueDate', 
			   UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1,UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,       
			   UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3,  UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,       
			   UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5, UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,       
			   UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7, UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,       
			   UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9, UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
			   MJH.MasterCompanyId,
			   0 AS IsCreditMemo,
			   0 AS StatusId,
			   0 AS InvoicePaidAmount   -- need to discuss 
			  ,CASE WHEN (DATEDIFF(DAY, CAST(MJH.PostedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(MJH.PostedDate AS DATETIME) + ISNULL(ctm.NetDays,0), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
		FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId AND MJD.ReferenceTypeId = 2 
		  INNER JOIN [dbo].[Vendor] V  WITH (NOLOCK) ON V.VendorId = MJD.ReferenceId 
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 		   
		   LEFT JOIN  [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId
		   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON  MSD.Level1Id = MSL1.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON  MSD.Level2Id = MSL2.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON  MSD.Level3Id = MSL3.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON  MSD.Level4Id = MSL4.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON  MSD.Level5Id = MSL5.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON  MSD.Level6Id = MSL6.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON  MSD.Level7Id = MSL7.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON  MSD.Level8Id = MSL8.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON  MSD.Level9Id = MSL9.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
	   WHERE MJD.ReferenceId = ISNULL(@vendorId,MJD.ReferenceId)    
			AND MJH.[ManualJournalStatusId] = @PostStatusId
			AND MJD.[ReferenceTypeId] = 2  
			--AND MJH.JournalNumber  = ISNULL(@invoiceNum,MJH.JournalNumber)
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@ToDate AS DATE) AND MJH.MasterCompanyId = @mastercompanyid    
			AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
			AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			AND (ISNULL(@Level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
			GROUP BY MJD.ReferenceId,V.[VendorName],V.VendorCode,CR.Code,MJH.JournalNumber, 
			MJH.[PostedDate],CTM.NetDays,MJD.UpdatedBy,MJD.ManagementStructureId,CTM.[Name],ctm.Code,
			MSL1.Code,MSL1.[Description],MSL2.Code, MSL2.[Description],MSL3.Code, MSL3.[Description],MSL4.Code, MSL4.[Description],MSL5.Code, MSL5.[Description],MSL6.Code, MSL6.[Description],
			MSL7.Code, MSL7.[Description],MSL8.Code, MSL8.[Description],MSL9.Code, MSL9.[Description],MSL10.Code , MSL10.[Description],MJH.MasterCompanyId
			HAVING SUM(ISNULL(MJD.Credit, 0)) - SUM(ISNULL(MJD.Debit, 0)) <> 0 ) H

			--select * from #tempManualJEElse
		--	NonPO Details  --
		SELECT * INTO #tempNonPODetailsElse FROM 
		(SELECT DISTINCT (V.VendorId) AS VendorId,ISNULL(V.[VendorName],'') 'vendorName' , ISNULL(V.VendorCode,'') 'vendorCode' ,      
						(CR.Code) AS  'currencyCode',  ISNULL(vpd.RemainingAmount,0) AS 'BalanceAmount',ISNULL(vpd.RemainingAmount,0)  AS 'CurrentlAmount',      
						ISNULL(vpd.PaymentMade,0)  AS 'PaymentAmount',(NPH.NPONumber) AS 'InvoiceNo',NPH.InvoiceNumber as 'invoiceNumber', NPH.InvoiceDate AS InvoiceDate,ISNULL(ctm.NetDays,0) AS NetDays,      						
						(CASE WHEN DATEDIFF(DAY, CAST(CAST(NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
						(CASE WHEN DATEDIFF(DAY, CAST(CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
						(CASE WHEN DATEDIFF(DAY, CAST(CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
						(CASE WHEN DATEDIFF(DAY, CAST(CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
						(CASE WHEN DATEDIFF(DAY, CAST(CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN vpd.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
						(CASE WHEN DATEDIFF(DAY, CAST(CAST( NPH.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN vpd.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
						(NPH.ManagementStructureId) AS ManagementStructureId, 'NPO-Inv' AS 'DocType','' AS 'vendorRef', '' AS 'Salesperson',ctm.Name AS 'Terms',      
						'0' AS 'FixRateAmount', vpd.RemainingAmount AS 'InvoiceAmount', 0 AS 'cmAmount',0 AS CreditMemoAmount,
						NPH.DueDate AS 'DueDate',     
						UPPER(MSD.Level1Name) AS level1,UPPER(MSD.Level2Name) AS level2,UPPER(MSD.Level3Name) AS level3,UPPER(MSD.Level4Name) AS level4,       
						UPPER(MSD.Level5Name) AS level5,UPPER(MSD.Level6Name) AS level6, UPPER(MSD.Level7Name) AS level7,UPPER(MSD.Level8Name) AS level8,UPPER(MSD.Level9Name) AS level9,UPPER(MSD.Level10Name) AS level10,
						NPH.MasterCompanyId,0 AS IsCreditMemo,0 AS StatusId,0 AS InvoicePaidAmount
						,CASE WHEN (DATEDIFF(DAY, CAST(NPH.DueDate AS DATETIME), GETUTCDATE())) > 0 THEN (DATEDIFF(DAY, CAST(NPH.DueDate AS DATETIME), GETUTCDATE())) ELSE 0 END AS 'DaysPastDue'
			 FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)       
				   INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON NPH.NonPOInvoiceId = vpd.NonPOInvoiceId      
				   --LEFT JOIN [dbo].[VendorReadyToPayDetails] vrp WITH (NOLOCK) ON NPH.NonPOInvoiceId = vrp.NonPOInvoiceId
				   --LEFT JOIN [dbo].[VendorReadyToPayHeader] rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
				   INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId = NPH.VendorId      
				   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
				   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = NPH.CurrencyId      
				   LEFT JOIN [dbo].[NonPOInvoiceManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = NPH.NonPOInvoiceId
				   LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID         
				   OUTER APPLY (SELECT npdd.[NonPOInvoiceId], SUM(npdd.ExtendedPrice) as InvoiceTotal FROM [dbo].[NonPOInvoicePartDetails] npdd WITH(NOLOCK)
							WHERE npdd.[NonPOInvoiceId] = NPH.NonPOInvoiceId GROUP BY npdd.[NonPOInvoiceId]) PartData
				  WHERE NPH.[VendorId] = ISNULL(@vendorId,NPH.VendorId)  			  
				  AND CAST(NPH.PostedDate AS DATE) <= CAST(@ToDate AS DATE) AND NPH.[MasterCompanyId] = @mastercompanyid      
				  AND vpd.RemainingAmount > 0  
				  --AND NPH.NPONumber  = ISNULL(@invoiceNum,NPH.NPONumber)
				  AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))      
				  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
				  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
				  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
				  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
				  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))) )I
		

			  -- SELECT * FROM #tempNonPODetailsElse

		;WITH CTE AS (   
			SELECT * FROM #tempReceivingReconciliationElse
			UNION ALL
			SELECT * FROM #tempCreditMemoElse
			UNION ALL
			SELECT * FROM #tempManualJEElse
		    UNION ALL
		    SELECT * FROM #tempNonPODetailsElse		
		),		
		Result AS(      
			SELECT DISTINCT      
			       (CTE.VendorId) AS VendorId ,UPPER(ISNULL(CTE.vendorName,'')) 'vendorName',UPPER(ISNULL(CTE.vendorCode,'')) 'vendorCode', UPPER(CTE.currencyCode) AS  'currencyCode',   
   		   		   CASE WHEN CTE.IsCreditMemo = 0 THEN (ISNULL(CTE.InvoiceAmount,0) - ISNULL(CTE.InvoicePaidAmount,0)) ELSE ISNULL(CTE.CreditMemoAmount,0) END AS 'BalanceAmount', 
				   UPPER(CTE.InvoiceNo) AS 'InvoiceNo',  
				   UPPER(ISNULL(CTE.invoiceNumber,'')) as invoiceNumber,
				   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CTE.InvoiceDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END 'InvoiceDate',       				  				   
				   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END AS 'Amountpaidbylessthen0days',   							
				   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby30days) END,0) END AS 'Amountpaidby30days',   							
		           CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby60days) END,0) END AS 'Amountpaidby60days',   							
		           CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby90days) END,0) END AS 'Amountpaidby90days',   							
		           CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby120days) END,0) END AS 'Amountpaidby120days',   							
				   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN CTE.Amountpaidbymorethan120days ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbymorethan120days) END,0) END AS 'Amountpaidbymorethan120days',   							
				   ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount', 
				   UPPER(CTE.DocType) AS DocType,
				   UPPER(CTE.Terms) AS Terms,  
				   --CASE WHEN CTE.IsCreditMemo = 0 THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(DATEADD(DAY, CTE.NetDays,CTE.InvoiceDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 107) END ELSE NULL END 'DueDate',
				   CASE WHEN CTE.IsCreditMemo = 0 THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CTE.DueDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 107) END ELSE NULL END 'DueDate',
				   ISNULL(CTE.FixRateAmount,0) AS 'FixRateAmount',    
				   UPPER(CTE.level1) AS level1, UPPER(CTE.level2) AS level2,       
				   UPPER(CTE.level3) AS level3, UPPER(CTE.level4) AS level4,       
				   UPPER(CTE.level5) AS level5, UPPER(CTE.level6) AS level6,       
				   UPPER(CTE.level7) AS level7, UPPER(CTE.level8) AS level8,       
				   UPPER(CTE.level9) AS level9, UPPER(CTE.level10) AS level10,
				   CTE.MasterCompanyId,
				   DaysPastDue
			FROM CTE AS CTE WITH (NOLOCK)   			
			INNER JOIN dbo.Vendor AS V WITH (NOLOCK) ON V.VendorId = CTE.VendorId    	  
			WHERE V.MasterCompanyId = @MasterCompanyId   
			AND (ISNULL(@VendorName,'') ='' OR CTE.vendorName LIKE '%' + @VendorName + '%')
			AND (ISNULL(@VendorCode,'') ='' OR CTE.vendorCode LIKE '%' + @VendorCode + '%')
			AND (ISNULL(@InvoiceAmount,'') ='' OR CTE.InvoiceAmount LIKE '%' + @InvoiceAmount + '%')
			AND (ISNULL(@BalanceAmount,'') ='' OR BalanceAmount LIKE '%' + @BalanceAmount + '%')
			AND (ISNULL(@InvoiceNo,'') ='' OR InvoiceNo LIKE '%' + @InvoiceNo + '%')
			AND (ISNULL(@InvoiceDate, '') = '' OR CAST(InvoiceDate AS Date) = CAST(@InvoiceDate AS date))
			AND (ISNULL(@Terms,'') ='' OR CTE.Terms LIKE '%' + @Terms + '%')
			AND (ISNULL(@DueDate, '') = '' OR CAST(dueDate AS Date) = CAST(@DueDate AS date))
			AND (ISNULL(@Amountpaidbylessthen0days,'') ='' OR Amountpaidbylessthen0days LIKE '%' + @Amountpaidbylessthen0days + '%')
			AND (ISNULL(@Amountpaidby30days,'') ='' OR Amountpaidby30days LIKE '%' + @Amountpaidby30days + '%')
			AND (ISNULL(@Amountpaidby60days,'') ='' OR Amountpaidby60days LIKE '%' + @Amountpaidby60days + '%')
			AND (ISNULL(@Amountpaidby90days,'') ='' OR Amountpaidby90days LIKE '%' + @Amountpaidby90days + '%')
			AND (ISNULL(@Amountpaidby120days,'') ='' OR Amountpaidby120days LIKE '%' + @Amountpaidby120days + '%')
			AND (ISNULL(@Amountpaidbymorethan120days,'') ='' OR Amountpaidbymorethan120days LIKE '%' + @Amountpaidbymorethan120days + '%')
		),
		ResultCount AS (SELECT COUNT(VendorId) AS totalItems FROM Result)  
		
	   ,WithTotal (MastercompanyId, TotalInvoiceAmount, TotalBalanceAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days) 
			  AS (SELECT MastercompanyId, 
				FORMAT(SUM(InvoiceAmount), 'N', 'en-us') TotalInvoiceAmount,			
				FORMAT(SUM(BalanceAmount), 'N', 'en-us') TotalBalanceAmount,
				FORMAT(SUM(Amountpaidbylessthen0days), 'N', 'en-us') TotalAmountpaidbylessthen0days,
				FORMAT(SUM(Amountpaidby30days), 'N', 'en-us') TotalAmountpaidby30days,
				FORMAT(SUM(Amountpaidby60days), 'N', 'en-us') TotalAmountpaidby60days,
				FORMAT(SUM(Amountpaidby90days), 'N', 'en-us') TotalAmountpaidby90days,
				FORMAT(SUM(Amountpaidby120days), 'N', 'en-us') TotalAmountpaidby120days,
				FORMAT(SUM(Amountpaidbymorethan120days), 'N', 'en-us') TotalAmountpaidbymorethan120days				
				FROM Result
				GROUP BY MastercompanyId)

		  SELECT VendorId, 
		         UPPER(vendorName) vendorName, 
		         UPPER(vendorCode) vendorCode, 
				 UPPER(InvoiceNo) InvoiceNo,
				 UPPER(invoiceNumber) invoiceNumber,
				 InvoiceDate,
				 InvoiceAmount,
				 BalanceAmount,				
				 Amountpaidbylessthen0days,
				 Amountpaidby30days,
				 Amountpaidby60days,
				 Amountpaidby90days,
				 Amountpaidby120days,
				 Amountpaidbymorethan120days,
				 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,	
				 DocType,
				 Terms,
				 DueDate,
				 currencyCode,
				 FixRateAmount,
				 TotalInvoiceAmount, 
			     TotalBalanceAmount,
			     TotalAmountpaidbylessthen0days,
			     TotalAmountpaidby30days, 
			     TotalAmountpaidby60days,
			     TotalAmountpaidby90days, 
			     TotalAmountpaidby120days, 
			     TotalAmountpaidbymorethan120days,DaysPastDue				 
		  INTO #TempResult2 FROM  Result FC
		  INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId

		  
		  SELECT @Count = COUNT(VendorId) FROM #TempResult2  

		  SELECT @Count AS TotalRecordsCount,
		         vendorName, 
		         vendorCode, 
				 InvoiceNo,
				 invoiceNumber,
				 InvoiceDate,
   	             FORMAT(ISNULL(InvoiceAmount,0), 'N', 'en-us') AS 'InvoiceAmount',
	             FORMAT(ISNULL(BalanceAmount,0), 'N', 'en-us') AS 'BalanceAmount',	
	             FORMAT(ISNULL(Amountpaidbylessthen0days,0), 'N', 'en-us') AS 'Amountpaidbylessthen0days',
	             FORMAT(ISNULL(Amountpaidby30days,0), 'N', 'en-us') AS 'Amountpaidby30days',
	             FORMAT(ISNULL(Amountpaidby60days,0), 'N', 'en-us') AS 'Amountpaidby60days',
	             FORMAT(ISNULL(Amountpaidby90days,0), 'N', 'en-us') AS 'Amountpaidby90days',
	             FORMAT(ISNULL(Amountpaidby120days,0), 'N', 'en-us') AS 'Amountpaidby120days',
	             FORMAT(ISNULL(Amountpaidbymorethan120days,0), 'N', 'en-us') AS 'Amountpaidbymorethan120days',
				 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				 DocType,
				 Terms,
				 DueDate,
				 currencyCode,
				 FixRateAmount,
				 TotalInvoiceAmount,
				 TotalBalanceAmount,
				 TotalAmountpaidbylessthen0days, 
	             TotalAmountpaidby30days, 
				 TotalAmountpaidby60days, 
				 TotalAmountpaidby90days, 
				 TotalAmountpaidby120days, 
				 TotalAmountpaidbymorethan120days,DaysPastDue
			FROM #TempResult2      

		--	ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN InvoiceDate ELSE InvoiceDate 
		--END
		ORDER BY  					 
			CASE WHEN (@SortOrder=1  AND @SortColumn='vendorName') THEN vendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorName') THEN vendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='vendorCode') THEN vendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorCode') THEN vendorCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceAmount') THEN InvoiceAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceAmount') THEN InvoiceAmount END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='BalanceAmount') THEN BalanceAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BalanceAmount') THEN BalanceAmount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceDate') THEN InvoiceDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceDate') THEN InvoiceDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='invoiceNo') THEN invoiceNo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='invoiceNo') THEN invoiceNo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='terms') THEN terms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='terms') THEN terms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='dueDate') THEN dueDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='dueDate') THEN dueDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='currencyCode') THEN currencyCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='currencyCode') THEN currencyCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='fixRateAmount') THEN fixRateAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='fixRateAmount') THEN fixRateAmount END DESC,
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
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbymorethan120days') THEN Amountpaidbymorethan120days END DESC
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
		
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