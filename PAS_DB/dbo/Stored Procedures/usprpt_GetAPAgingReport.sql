/*************************************************************                   
 ** File:  [usprpt_GetAPAgingReport]                   
 ** Author: Rajesh Gami         
 ** Description: Get Data for AP Aging Report        
 ** Purpose:                 
 ** Date:   28-Aug-2023               
                  
 ** PARAMETERS:                   
                 
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------                  
    1    28-Aug-2023    Rajesh Gami		   Created        
	2    25-SEP-2023    Moin Bloch         Manual Journal Entry Posted Status and Posted date
	3    27-SEP-2023    Moin Bloch         Modify(Updated InvoiceDate insted of OpenDate)
	 
***************************************************************************************************/        
CREATE   PROCEDURE [dbo].[usprpt_GetAPAgingReport]       
@PageNumber int = 1,      
@PageSize int = NULL,      
@mastercompanyid int,      
@xmlFilter XML   
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
             
      DECLARE @ModuleID INT = 2; -- MS Module ID      
      DECLARE @Count BIGINT =0   
	  DECLARE @PostStatusId INT;
	  SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';

	  DECLARE @CMApprovedStatusId INT;
	  SELECT @CMApprovedStatusId = [Id] FROM [dbo].[CreditMemoStatus] WHERE [Name] = 'Approved';

      SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
      DECLARE @MSModuleId INT = 0	

	  SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	
	  
	  DECLARE @CMMSModuleID BIGINT = 61;
	  SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='CreditMemoHeader';
	
	  DECLARE @FulfillingCreditMemoStatus bigint
	  SELECT @FulfillingCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Fulfilling';
      
    SELECT @todate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='AS of Date'       
	  THEN CONVERT(DATE,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @todate END,      
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
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 END      
   FROM      
    @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)    
		      
  --  IF(ISNULL(@exludedebit,'')='' OR @exludedebit IS NULL)      
  --  BEGIN      
		--SET @exludedebit =2;      
  --  END      
      
   IF ISNULL(@PageSize,0)=0      
   BEGIN  
   PRINT @PageSize

       SELECT @PageSize=COUNT(*)       
			FROM (SELECT rrh.ReceivingReconciliationId AS ReceivingReconciliationId 
					FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
			  INNER JOIN [dbo].[ReceivingReconciliationDetails] rrd WITH (NOLOCK) on rrh.ReceivingReconciliationId  = rrd.ReceivingReconciliationId     
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
			  LEFT JOIN dbo.VendorReadyToPayDetails vrp WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vrp.ReceivingReconciliationId
			  LEFT JOIN dbo.VendorReadyToPayHeader rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId=rrh.VendorId      
			  LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId      
			  --LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
			  --INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
			  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = rrh.CurrencyId      
			  LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'STOCK'
			  LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID                  
			  WHERE rrh.VendorId = ISNULL(@vendorId,rrh.VendorId)        
			  AND CAST(rrh.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND rrh.MasterCompanyId = @mastercompanyid      
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
			GROUP BY rrh.ReceivingReconciliationId 
			
			UNION ALL
 
	   SELECT DISTINCT (VCM.[VendorId]) AS VendorId		
			 FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)       
			  INNER JOIN [dbo].[VendorCreditMemoDetail] VCD WITH (NOLOCK) on VCM.VendorCreditMemoId = VCD.VendorCreditMemoId 
			  INNER JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VCM.CurrencyId  
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
			   LEFT JOIN [dbo].[EntityStructureSetup] SES ON SES.EntityStructureId = SMSD.EntityMSID  	
			 WHERE VCM.[VendorId] = ISNULL(@vendorId,VCM.[VendorId])  			  
			  AND CAST(VCM.[CreatedDate] AS DATE) <= CAST(@ToDate AS DATE) AND VCM.[MasterCompanyId] = @mastercompanyid   
			  AND VCM.[VendorCreditMemoStatusId] = @CMApprovedStatusId
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
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

	UNION ALL

		 SELECT MJD.ReferenceId AS BillingInvoicingId
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
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@ToDate AS DATE) AND MJH.mastercompanyid = @mastercompanyid      
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
			AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))) 
		   
		) TEMP 

   END      
      
   SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END      
   SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END      

    IF(@Typeid = 1)
	BEGIN

    ;WITH CTE AS (   
	
	--	Receiving Reconciliation  --

             SELECT DISTINCT (V.VendorId) AS VendorId,      
                    ISNULL(V.[VendorName],'') 'vendorName' ,      
                    ISNULL(V.VendorCode,'') 'vendorCode' ,      
                    --(CT.CustomerTypeName) 'CustomertType' ,      
                    (CR.Code) AS  'currencyCode',      
                    ISNULL(vpd.OriginalAmount,0) AS 'BalanceAmount',      
                    ISNULL(vpd.RemainingAmount,0)  AS 'CurrentlAmount',      
                    ISNULL(vpd.PaymentMade,0)  AS 'PaymentAmount',      
                    (rrh.InvoiceNum) AS 'InvoiceNo',      
                    rrh.InvoiceDate AS InvoiceDate,      
                    ISNULL(ctm.NetDays,0) AS NetDays, 
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
					(rtp.ManagementStructureId) AS ManagementStructureId,      
					'AP-Inv' AS 'DocType',      
					'' AS 'vendorRef',      
					'' AS 'Salesperson',      
					ctm.Name AS 'Terms',      
					'0' AS 'FixRateAmount',      
					rrh.InvoiceTotal AS 'InvoiceAmount',
					0 AS 'cmAmount',
					0 AS CreditMemoAmount,
					vpd.DueDate AS 'DueDate',      
					UPPER(MSD.Level1Name) AS level1,        
					UPPER(MSD.Level2Name) AS level2,       
					UPPER(MSD.Level3Name) AS level3,       
					UPPER(MSD.Level4Name) AS level4,       
					UPPER(MSD.Level5Name) AS level5,       
					UPPER(MSD.Level6Name) AS level6,       
					UPPER(MSD.Level7Name) AS level7,       
					UPPER(MSD.Level8Name) AS level8,       
					UPPER(MSD.Level9Name) AS level9,       
					UPPER(MSD.Level10Name) AS level10,
					rrh.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId
				   ,0 AS InvoicePaidAmount
         FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
			  INNER JOIN [dbo].[ReceivingReconciliationDetails] rrd WITH (NOLOCK) on rrh.ReceivingReconciliationId  = rrd.ReceivingReconciliationId     
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
			   LEFT JOIN [dbo].VendorReadyToPayDetails vrp WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vrp.ReceivingReconciliationId
			   LEFT JOIN [dbo].VendorReadyToPayHeader rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId=rrh.VendorId      
			  LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
			  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = rrh.CurrencyId      
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'STOCK'
			   LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID                
			  WHERE rrh.[VendorId] = ISNULL(@vendorId,rrh.VendorId)        
			  AND CAST(rrh.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) AND rrh.[MasterCompanyId] = @mastercompanyid      
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

	UNION ALL

	-- Credit Memo --

		 SELECT DISTINCT (VCM.[VendorId]) AS VendorId,
					ISNULL(VEN.[VendorName],'') 'vendorName' ,      
					ISNULL(VEN.[VendorCode],'') 'vendorCode' ,  
					(CR.[Code]) AS  'currencyCode',   
					ISNULL(VCD.OriginalAmt,0) AS 'BalanceAmount', 
					ISNULL(VCD.OriginalAmt,0)  AS 'CurrentlAmount',   
					ISNULL(VCD.OriginalAmt,0)  AS 'PaymentAmount',  
					(VCM.VendorCreditMemoNumber) AS 'InvoiceNo', 					
					 VCM.CreatedDate AS InvoiceDate,      
                    ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidbymorethan120days,
					(SMSD.EntityMSID) AS ManagementStructureId,   
					'Credit Memo' AS 'DocType',
					'' AS 'vendorRef',      
					'' AS 'Salesperson',      
					ctm.Name AS 'Terms',      
					'0' AS 'FixRateAmount', 
					VCD.OriginalAmt AS 'InvoiceAmount', 
					VCD.OriginalAmt AS 'cmAmount', 
					VCD.OriginalAmt AS CreditMemoAmount,
					NULL AS 'DueDate',  
					UPPER(SMSD.Level1Name) AS level1,        
					UPPER(SMSD.Level2Name) AS level2,       
					UPPER(SMSD.Level3Name) AS level3,       
					UPPER(SMSD.Level4Name) AS level4,       
					UPPER(SMSD.Level5Name) AS level5,       
					UPPER(SMSD.Level6Name) AS level6,       
					UPPER(SMSD.Level7Name) AS level7,       
					UPPER(SMSD.Level8Name) AS level8,       
					UPPER(SMSD.Level9Name) AS level9,       
					UPPER(SMSD.Level10Name) AS level10,
					VCM.MasterCompanyId,
					1 AS IsCreditMemo,
					VCM.VendorCreditMemoStatusId AS StatusId,
					0 AS InvoicePaidAmount
			 FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)       
			  INNER JOIN [dbo].[VendorCreditMemoDetail] VCD WITH (NOLOCK) on VCM.VendorCreditMemoId = VCD.VendorCreditMemoId 
			  INNER JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VCM.CurrencyId  
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
			   LEFT JOIN [dbo].[EntityStructureSetup] SES ON SES.EntityStructureId = SMSD.EntityMSID  	
			 WHERE VCM.[VendorId] = ISNULL(@vendorId,VCM.[VendorId])  			  
			  AND CAST(VCM.[CreatedDate] AS DATE) <= CAST(@ToDate AS DATE) AND VCM.[MasterCompanyId] = @mastercompanyid   
			  AND VCM.[VendorCreditMemoStatusId] = @CMApprovedStatusId
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
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

	-- Manual JE ---

	UNION ALL

			SELECT DISTINCT (MJD.ReferenceId) AS VendorId,      
                    ISNULL(V.[VendorName],'') 'vendorName' ,      
                    ISNULL(V.VendorCode,'') 'vendorCode' ,      
                    (CR.Code) AS  'currencyCode',  
					 MJD.Credit AS 'BalanceAmount',       -- need to discuss
					 MJD.Credit AS 'CurrentlAmount',      -- need to discuss
			         MJD.Credit AS 'PaymentAmount',      
					 UPPER(MJH.JournalNumber) AS 'InvoiceNo',  
					 MJH.[PostedDate] AS InvoiceDate,      
			         ISNULL(CTM.NetDays,0) AS NetDays,
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
					 WHEN ctm.Code='CIA' THEN -1      
					 WHEN ctm.Code='CreditCard' THEN -1      
					 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN MJD.Credit ELSE 0 END) AS AmountpaidbylessTHEN0days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN MJD.Credit ELSE 0 END) AS Amountpaidby30days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN MJD.Credit ELSE 0 END) AS Amountpaidby60days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN MJD.Credit ELSE 0 END) AS Amountpaidby90days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN MJD.Credit ELSE 0 END) AS Amountpaidby120days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN MJD.Credit ELSE 0 END) AS Amountpaidbymorethan120days,
               MJD.ManagementStructureId AS ManagementStructureId, 
			   UPPER('Manual Journal Adjustment') AS 'DocType', 
			   '' AS 'vendorRef',   
			   ''AS 'Salesperson',	   
			   ctm.Name AS 'Terms',   
			   '0' AS 'FixRateAmount', 			        
			   (ISNULL(MJD.Credit,0) - ISNULL(MJD.Debit,0)) AS 'InvoiceAmount', 
			   0 AS 'cmAmount',
			   0 AS CreditMemoAmount,
			   NULL AS 'DueDate', 
			   UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1,        
			   UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,       
			   UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3,       
			   UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,       
			   UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5,       
			   UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,       
			   UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7,       
			   UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,       
			   UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9,       
			   UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
			   MJH.MasterCompanyId,
			   0 AS IsCreditMemo,
			   0 AS StatusId,
			   0 AS InvoicePaidAmount   -- need to discuss 							    
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
	)    
      
  , Result AS(      
    SELECT DISTINCT       
        (CTE.VendorId) AS VendorId ,      
        ((ISNULL(CTE.vendorName,''))) 'vendorName' ,      
        ((ISNULL(CTE.vendorCode,''))) 'vendorCode' ,      
		--(ISNULL(CTE.InvoiceAmount,0) - ISNULL(CTE.InvoicePaidAmount,0)) AS 'BalanceAmount',
	    --ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) AS 'Amountpaidbylessthen0days',   											
	    --ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) AS 'Amountpaidby30days',                            					  
		--ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) AS 'Amountpaidby60days',
		--ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) AS 'Amountpaidby90days',
		--ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) AS 'Amountpaidby120days',
		--ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) AS 'Amountpaidbymorethan120days',  		
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.InvoiceAmount - ISNULL(CTE.InvoicePaidAmount,0)),0) ELSE ISNULL(CTE.CreditMemoAmount,0) END AS 'BalanceAmount',
	    CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END  AS 'Amountpaidbylessthen0days',   							
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE 0 END AS 'Amountpaidby30days',                            					  
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE 0 END AS 'Amountpaidby60days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE 0 END AS 'Amountpaidby90days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE 0 END AS 'Amountpaidby120days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE 0 END AS 'Amountpaidbymorethan120days',  		
		ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount',      
        UPPER(CTE.level1) AS level1,        
        UPPER(CTE.level2) AS level2,       
        UPPER(CTE.level3) AS level3,       
        UPPER(CTE.level4) AS level4,       
        UPPER(CTE.level5) AS level5,       
        UPPER(CTE.level6) AS level6,       
        UPPER(CTE.level7) AS level7,       
        UPPER(CTE.level8) AS level8,       
        UPPER(CTE.level9) AS level9,       
        UPPER(CTE.level10) AS level10,
		CTE.MasterCompanyId,
		--ISNULL(crm.ApplierdAmt,0) AS cmAmount  --  commented by moin
		0 AS cmAmount
      FROM CTE AS CTE WITH (NOLOCK)       
      INNER JOIN dbo.Vendor AS v WITH (NOLOCK) ON v.VendorId = CTE.VendorId    
	  --LEFT JOIN dbo.VendorCreditMemo vcm WITH (NOLOCK) ON CTE.VendorId = ISNULL(vcm.VendorRMAId,vcm.VendorId)    
	  --LEFT JOIN dbo.VendorCreditMemoDetail crm WITH (NOLOCK) ON vcm.VendorCreditMemoId = crm.VendorCreditMemoId
      WHERE V.MasterCompanyId = @MasterCompanyId 
      
   ) , ResultCount AS(SELECT COUNT(VendorId) AS totalItems FROM Result)      
   ,WithTotal (MastercompanyId, 
               TotalInvoiceAmount, --TotalcmAmount, TotalcmAmountUsed, 
               TotalBalanceAmount, 
			   --TotalCurrentlAmount, 
			   TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, 
			   TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,cmAmount) 
			  AS (SELECT MastercompanyId, 
				SUM(InvoiceAmount) TotalInvoiceAmount,
				--FORMAT(SUM(cmAmount), 'N', 'en-us') TotalcmAmount,
				--FORMAT(SUM(cmAmountUsed), 'N', 'en-us') TotalcmAmountUsed,
				SUM(BalanceAmount) TotalBalanceAmount,
				--FORMAT(SUM(CurrentlAmount), 'N', 'en-us') TotalCurrentlAmount,
				SUM(Amountpaidbylessthen0days) TotalAmountpaidbylessthen0days,
				SUM(Amountpaidby30days) TotalAmountpaidby30days,
				SUM(Amountpaidby60days) TotalAmountpaidby60days,
				SUM(Amountpaidby90days) TotalAmountpaidby90days,
				SUM(Amountpaidby120days) TotalAmountpaidby120days,
				SUM(Amountpaidbymorethan120days) TotalAmountpaidbymorethan120days,
				SUM(cmAmount) cmAmount
		   FROM Result GROUP BY MastercompanyId)

   SELECT	VendorId, 
            vendorName, 
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
			TotalInvoiceAmount, 
			TotalBalanceAmount,
			TotalAmountpaidbylessthen0days,
			TotalAmountpaidby30days, 
			TotalAmountpaidby60days,
			TotalAmountpaidby90days, 
			TotalAmountpaidby120days, 
			TotalAmountpaidbymorethan120days
			,WC.cmAmount
			
   INTO #TempResult1 FROM  Result FC
   INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
   GROUP BY VendorId,vendorName,vendorCode,level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
            ,TotalInvoiceAmount,TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days, TotalAmountpaidby60days,
			TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,WC.cmAmount
      
    SELECT @Count = COUNT(VendorId) FROM #TempResult1      
      
    SELECT @Count AS TotalRecordsCount,
	VendorId, 
	vendorName, 
	vendorCode, 
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
	TotalBalanceAmount, 
	--TotalCurrentlAmount, 
	TotalAmountpaidbylessthen0days, 
	TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days,cmAmount
	FROM #TempResult1      

    ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN 1 ELSE 1       
        
    END      
        
	OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
  
    /**** ELSE PART *****/   

	END
	ELSE
	BEGIN
		 ;WITH CTE AS (    
				   SELECT DISTINCT (V.VendorId) AS VendorId,      
                    ISNULL(V.[VendorName],'') 'vendorName' ,      
                    ISNULL(V.VendorCode,'') 'vendorCode' ,      
                    (CR.Code) AS  'currencyCode',      
                    ISNULL(vpd.OriginalAmount,0) AS 'BalanceAmount',      
                    ISNULL(vpd.RemainingAmount,0)  AS 'CurrentlAmount',      
                    ISNULL(vpd.PaymentMade,0)  AS 'PaymentAmount',      
                    (rrh.InvoiceNum) AS 'InvoiceNo',      
                    rrh.InvoiceDate AS InvoiceDate,      
                    ISNULL(ctm.NetDays,0) AS NetDays,      						
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
					(rtp.ManagementStructureId) AS ManagementStructureId,      					
					(CASE WHEN rrd.[Type] = 1 THEN 'PO-Inv' ELSE 'RO-Inv' END) AS 'DocType',
					'' AS 'vendorRef',      
					'' AS 'Salesperson',      
					ctm.Name AS 'Terms',      
					'0' AS 'FixRateAmount',      
					rrh.InvoiceTotal AS 'InvoiceAmount',      
					0 AS 'cmAmount',
					0 AS CreditMemoAmount,
					--vpd.DueDate AS 'DueDate',      
					DATEADD(DAY, ctm.NetDays,rrh.InvoiceDate) AS 'DueDate',     
					UPPER(MSD.Level1Name) AS level1,        
					UPPER(MSD.Level2Name) AS level2,       
					UPPER(MSD.Level3Name) AS level3,       
					UPPER(MSD.Level4Name) AS level4,       
					UPPER(MSD.Level5Name) AS level5,       
					UPPER(MSD.Level6Name) AS level6,       
					UPPER(MSD.Level7Name) AS level7,       
					UPPER(MSD.Level8Name) AS level8,       
					UPPER(MSD.Level9Name) AS level9,       
					UPPER(MSD.Level10Name) AS level10,
					rrh.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId
				   ,0 AS InvoicePaidAmount
         FROM [dbo].[ReceivingReconciliationHeader] rrh WITH (NOLOCK)       
			  INNER JOIN [dbo].[ReceivingReconciliationDetails] rrd WITH (NOLOCK) on rrh.ReceivingReconciliationId  = rrd.ReceivingReconciliationId     
			  INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vpd.ReceivingReconciliationId      
			   LEFT JOIN [dbo].[VendorReadyToPayDetails] vrp WITH (NOLOCK) ON rrh.ReceivingReconciliationId = vrp.ReceivingReconciliationId
			   LEFT JOIN [dbo].[VendorReadyToPayHeader] rtp WITH (NOLOCK) ON  vrp.ReadyToPayId = rtp.ReadyToPayId
			  INNER JOIN [dbo].[Vendor] v  WITH (NOLOCK) ON v.VendorId = rrh.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = v.CreditTermsId
			  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = rrh.CurrencyId      
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = rrd.StocklineId and UPPER(rrd.StockType)= 'STOCK'
			   LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID                
			  WHERE rrh.[VendorId] = ISNULL(@vendorId,rrh.VendorId)  			  
			  AND CAST(rrh.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) AND rrh.[MasterCompanyId] = @mastercompanyid      
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

		UNION ALL

			 SELECT DISTINCT (VCM.[VendorId]) AS VendorId,
					ISNULL(VEN.[VendorName],'') 'vendorName' ,      
					ISNULL(VEN.[VendorCode],'') 'vendorCode' ,  
					(CR.[Code]) AS  'currencyCode',   
					ISNULL(VCD.OriginalAmt,0) AS 'BalanceAmount', 
					ISNULL(VCD.OriginalAmt,0)  AS 'CurrentlAmount',   
					ISNULL(VCD.OriginalAmt,0)  AS 'PaymentAmount',  
					(VCM.VendorCreditMemoNumber) AS 'InvoiceNo', 					
					 VCM.CreatedDate AS InvoiceDate,      
                    ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(VCM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN CTM.Code='CIA' THEN -1
																	WHEN CTM.Code='CreditCard' THEN -1
																	WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN VCD.OriginalAmt ELSE 0 END) AS Amountpaidbymorethan120days,
					(SMSD.EntityMSID) AS ManagementStructureId,   
					'Credit Memo' AS 'DocType',
					'' AS 'vendorRef',      
					'' AS 'Salesperson',      
					ctm.Name AS 'Terms',      
					'0' AS 'FixRateAmount', 
					VCD.OriginalAmt AS 'InvoiceAmount', 
					VCD.OriginalAmt AS 'cmAmount', 
					VCD.OriginalAmt AS CreditMemoAmount,
					NULL AS 'DueDate',  
					UPPER(SMSD.Level1Name) AS level1,        
					UPPER(SMSD.Level2Name) AS level2,       
					UPPER(SMSD.Level3Name) AS level3,       
					UPPER(SMSD.Level4Name) AS level4,       
					UPPER(SMSD.Level5Name) AS level5,       
					UPPER(SMSD.Level6Name) AS level6,       
					UPPER(SMSD.Level7Name) AS level7,       
					UPPER(SMSD.Level8Name) AS level8,       
					UPPER(SMSD.Level9Name) AS level9,       
					UPPER(SMSD.Level10Name) AS level10,
					VCM.MasterCompanyId,
					1 AS IsCreditMemo,
					VCM.VendorCreditMemoStatusId AS StatusId,
					0 AS InvoicePaidAmount
			 FROM [dbo].[VendorCreditMemo] VCM WITH (NOLOCK)       
			  INNER JOIN [dbo].[VendorCreditMemoDetail] VCD WITH (NOLOCK) on VCM.VendorCreditMemoId = VCD.VendorCreditMemoId 
			  INNER JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.VendorId = VCM.VendorId      
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = VEN.CreditTermsId
			   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VCM.CurrencyId  
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @ModuleID AND SMSD.ReferenceID = VCD.StockLineId 
			   LEFT JOIN [dbo].[EntityStructureSetup] SES ON SES.EntityStructureId = SMSD.EntityMSID  	
			 WHERE VCM.[VendorId] = ISNULL(@vendorId,VCM.[VendorId])  			  
			  AND CAST(VCM.[CreatedDate] AS DATE) <= CAST(@ToDate AS DATE) AND VCM.[MasterCompanyId] = @mastercompanyid   
			  AND VCM.[VendorCreditMemoStatusId] = @CMApprovedStatusId
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
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

		-- Manual JE ---

	UNION ALL

			SELECT DISTINCT (MJD.ReferenceId) AS VendorId,      
                    ISNULL(V.[VendorName],'') 'vendorName' ,      
                    ISNULL(V.VendorCode,'') 'vendorCode' ,      
                    (CR.Code) AS  'currencyCode',  
					 MJD.Credit AS 'BalanceAmount',       -- need to discuss
					 MJD.Credit AS 'CurrentlAmount',      -- need to discuss
			         MJD.Credit AS 'PaymentAmount',      
					 UPPER(MJH.JournalNumber) AS 'InvoiceNo',  
					 MJH.[PostedDate] AS InvoiceDate,      
			         ISNULL(CTM.NetDays,0) AS NetDays,
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
					 WHEN ctm.Code='CIA' THEN -1      
					 WHEN ctm.Code='CreditCard' THEN -1      
					 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN MJD.Credit ELSE 0 END) AS AmountpaidbylessTHEN0days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN MJD.Credit ELSE 0 END) AS Amountpaidby30days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN MJD.Credit ELSE 0 END) AS Amountpaidby60days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN MJD.Credit ELSE 0 END) AS Amountpaidby90days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN MJD.Credit ELSE 0 END) AS Amountpaidby120days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN MJD.Credit ELSE 0 END) AS Amountpaidbymorethan120days,
               MJD.ManagementStructureId AS ManagementStructureId, 
			   UPPER('Manual Journal Adjustment') AS 'DocType', 
			   '' AS 'vendorRef',   
			   ''AS 'Salesperson',	   
			   ctm.Name AS 'Terms',   
			   '0' AS 'FixRateAmount', 			        
			   (ISNULL(MJD.Credit,0) - ISNULL(MJD.Debit,0)) AS 'InvoiceAmount', 
			   0 AS 'cmAmount',
			   0 AS CreditMemoAmount,
			   NULL AS 'DueDate', 
			   UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1,        
			   UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,       
			   UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3,       
			   UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,       
			   UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5,       
			   UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,       
			   UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7,       
			   UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,       
			   UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9,       
			   UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
			   MJH.MasterCompanyId,
			   0 AS IsCreditMemo,
			   0 AS StatusId,
			   0 AS InvoicePaidAmount   -- need to discuss 							    
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

		),		
		Result AS(      
			SELECT DISTINCT      
			       (CTE.VendorId) AS VendorId ,      
			       ISNULL(CTE.vendorName,'') 'vendorName',      
                   ISNULL(CTE.vendorCode,'') 'vendorCode',
				   UPPER(CTE.currencyCode) AS  'currencyCode',   
   		   		   CASE WHEN CTE.IsCreditMemo = 0 THEN (ISNULL(CTE.InvoiceAmount,0) - ISNULL(CTE.InvoicePaidAmount,0)) ELSE ISNULL(CTE.CreditMemoAmount,0) END AS 'BalanceAmount', 
				   UPPER(CTE.InvoiceNo) AS 'InvoiceNo',      
				   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CTE.InvoiceDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END 'InvoiceDate',       				  				   
				   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END AS 'Amountpaidbylessthen0days',   							
				   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE 0 END AS 'Amountpaidby30days',                            					  
				   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE 0 END AS 'Amountpaidby60days',
		           CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE 0 END AS 'Amountpaidby90days',
		           CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE 0 END AS 'Amountpaidby120days',
		           CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE 0 END AS 'Amountpaidbymorethan120days',  
				   ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount', 
				   UPPER(CTE.DocType) AS DocType,
				   UPPER(CTE.Terms) AS Terms,  
				   CASE WHEN CTE.IsCreditMemo = 0 THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(DATEADD(DAY, CTE.NetDays,CTE.InvoiceDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 107) END ELSE NULL END 'DueDate',
				   ISNULL(CTE.FixRateAmount,0) AS 'FixRateAmount',    
				   UPPER(CTE.level1) AS level1,        
				   UPPER(CTE.level2) AS level2,       
				   UPPER(CTE.level3) AS level3,       
				   UPPER(CTE.level4) AS level4,       
				   UPPER(CTE.level5) AS level5,       
				   UPPER(CTE.level6) AS level6,       
				   UPPER(CTE.level7) AS level7,       
				   UPPER(CTE.level8) AS level8,       
				   UPPER(CTE.level9) AS level9,       
				   UPPER(CTE.level10) AS level10,
				   CTE.MasterCompanyId						 	   
			FROM CTE AS CTE WITH (NOLOCK)   			
			INNER JOIN dbo.Vendor AS V WITH (NOLOCK) ON V.VendorId = CTE.VendorId    	  
			WHERE V.MasterCompanyId = @MasterCompanyId       
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
		         vendorName, 
		         vendorCode, 
				 InvoiceNo,
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
			     TotalAmountpaidbymorethan120days				 
		  INTO #TempResult2 FROM  Result FC
		  INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId

		  SELECT @Count = COUNT(VendorId) FROM #TempResult2  
		  
		  SELECT @Count AS TotalRecordsCount,
		         vendorName, 
		         vendorCode, 
				 InvoiceNo,
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
				 TotalAmountpaidbymorethan120days
			FROM #TempResult2      

			ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN InvoiceDate ELSE InvoiceDate  
		END

		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
		
	END
	   	
  END TRY        
        
  BEGIN CATCH        
          
    DECLARE @ErrorLogID int,        
            @DatabaseName varchar(100) = DB_NAME(),       
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
            @AdhocComments varchar(150) = '[usprpt_GetARAgingReport]',        
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +        
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +        
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +        
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(MAX)),      
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