/*************************************************************                   
 ** File:   [usprpt_GetARAgingReport]                   
 ** Author:  Subhash saliya          
 ** Description: Get Data for Ar Aging Report        
 ** Purpose:                 
 ** Date:      13-July-2022          
                  
 ** PARAMETERS:                   
                 
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------   
	1    13-JULY-2022  Subhash saliya      Created        
    2    20-JUNE-2023  Devendra Shekh      Changes for the total 
	3    10-JULY-2023  Moin Bloch          change date todate range >= to <=
    4    13-JULY-2023  Ayesha Sultana      Credit Memo in ARAgaing REport  
	5    17-JULY-2023  Moin Bloch          Added Credit Memo in ARAgaing REport For WO     
	6    02-AUG-2023   Moin Bloch          Grouping Wise Amount	
	7    10-AUG-2023   Moin Bloch          Comment Credit Memo Terms and Conditions
	8    11-AUG-2023   Moin Bloch          Comment Due Date for Credit memo
    9    25-AUG-2023   EKta Chandegra      Convert text into uppercase 
	10   15-SEP-2023   Moin Bloch          Added Manual Journal Entry  
	11   21-SEP-2023   Moin Bloch          Added Status Status With 'Invoiced' Amount From Billing and Invoicing of WO/SO  
	12   22-SEP-2023   Moin Bloch          Manual Journal Entry Posted Status and Posted date
	13   10-OCT-2023   Moin Bloch          Added Exclude Credit Bal condition in CreditMemo and Manual JE
	14   16-OCT-2023   Moin Bloch          Modify(Added Posted Status Insted of Fulfilling Credit Memo Status)
	15   17-OCT-2023   Moin Bloch          Modify(Added Stand Alone Credit Memo)
	16   16-NOV-2023   Moin Bloch          Modify(Added Exchange SO Invoice Records)
	17   01-DEC-2023   Moin Bloch          Modify(Added 6 decimal IN FixRateAmount)

***************************************************************************************************/        
CREATE OR ALTER PROCEDURE [dbo].[usprpt_GetARAgingReport]       
@PageNumber int = 1,      
@PageSize int = NULL,      
@mastercompanyid int,      
@xmlFilter XML   
AS        
BEGIN        
  SET NOCOUNT ON;        
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
        
  DECLARE @customerid varchar(40) = NULL, 
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
             
      DECLARE @ModuleID INT = 17; -- MS Module ID      
	  DECLARE @SOMSModuleID BIGINT = 17      
      DECLARE @WOMSModuleID BIGINT = 12      
      DECLARE @Count BIGINT =0  
	  DECLARE @MSModuleId INT = 0	
	  DECLARE @PostStatusId INT;
	  DECLARE @ESOMSModuleID BIGINT;

	  SELECT @ESOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSOHeader';
	  
	  SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	
      SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END  
	  
	  DECLARE @CMMSModuleID BIGINT = 61;
	  SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='CreditMemoHeader';
	
	  DECLARE @ClosedCreditMemoStatus bigint
	  SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Closed';

	  DECLARE @CMPostedStatusId INT
	  SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
	  			
	  SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';
	  	         
    SELECT @todate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='AS of Date'       
	  THEN CONVERT(DATE,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @todate END,      
	  @customerid = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @customerid END, 
	  @Typeid = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='viewType'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Typeid END,
	  @exludedebit = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Exclude Credit Bal'       
	  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @exludedebit END,      
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
	
    IF(ISNULL(@exludedebit,'')='')      
    BEGIN 	
		SET @exludedebit =2;      
    END      
      
   IF ISNULL(@PageSize,0)=0      
   BEGIN  
   PRINT @PageSize
    SELECT @PageSize=COUNT(*)       
    FROM (SELECT wobi.BillingInvoicingId AS BillingInvoicingId 
			FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK)       
      INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId      
      INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId      
      LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId      
      LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
      INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
      INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId      
      INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND wobii.BillingInvoicingId = wobi.BillingInvoicingId AND wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID      
      INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId      
      INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID      
       LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID               
      WHERE WO.CustomerId = ISNULL(@customerid,WO.CustomerId) 
	  AND wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' AND wobi.IsVersionIncrease = 0
      AND CAST(wobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
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
    GROUP BY wobi.BillingInvoicingId      
   
   UNION ALL     
         
   SELECT sobi.SOBillingInvoicingId AS BillingInvoicingId 
        FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK)       
      INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId      
      INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId      
       LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId      
      INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
      INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId      
      INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId      
      INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId      
      INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
       LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID 
      WHERE SO.CustomerId = ISNULL(@customerid,SO.CustomerId)  
	  AND sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' 
      AND CAST(sobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid      
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
      GROUP BY sobi.SOBillingInvoicingId    
	
	UNION ALL

	SELECT wobi.BillingInvoicingId AS BillingInvoicingId 
	     FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
		 INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
         INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK) ON CM.InvoiceId = wobi.BillingInvoicingId                			   
		 INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId      
		 INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId      
		 LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId      
		 LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
		 INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
		 INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId      
		 INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND wobii.BillingInvoicingId = wobi.BillingInvoicingId AND wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID      
		 INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId      
		 INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID      
		 LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID               
	WHERE WO.CustomerId = ISNULL(@customerid,WO.CustomerId)   
	      AND CM.StatusId = @CMPostedStatusId
		  AND (CASE WHEN @exludedebit = 2 THEN CMD.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CMD.Amount END < 0)
		  AND CAST(wobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
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
		GROUP BY wobi.BillingInvoicingId 

	UNION ALL

	 SELECT sobi.SOBillingInvoicingId AS BillingInvoicingId 
		FROM [dbo].[CreditMemo] CM WITH (NOLOCK)         
	  INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
	  INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) ON CMD.InvoiceId = sobi.SOBillingInvoicingId   
      INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId      
      INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId      
       LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId      
      INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
      INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId      
      INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId      
      INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId      
      INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
       LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID 
      WHERE SO.CustomerId=ISNULL(@customerid,SO.CustomerId) 
	  AND CM.StatusId = @CMPostedStatusId
	  AND (CASE WHEN @exludedebit = 2 THEN CMD.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CMD.Amount END < 0)
      AND CAST(sobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid      
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
      GROUP BY sobi.SOBillingInvoicingId   

	  UNION ALL

	  SELECT MJD.ReferenceId AS BillingInvoicingId
		 FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
			  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
			  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.CustomerId = MJD.ReferenceId AND MJD.ReferenceTypeId = 1 
			  INNER JOIN [dbo].[CustomerFinancial] CSF  ON CSF.CustomerId = CST.CustomerId
			  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
			   LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID 
			   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CSF.CreditTermsId      
			   LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.CustomerTypeId = CT.CustomerTypeId      
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
		   WHERE MJD.ReferenceId = ISNULL(@customerid,MJD.ReferenceId)   
		    AND MJH.[ManualJournalStatusId] = @PostStatusId
			AND (CASE WHEN @exludedebit = 2 THEN (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) END > 0 OR CASE WHEN @exludedebit = 1 THEN (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) END IS NOT NULL)
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

		UNION ALL	

	SELECT CM.CustomerId AS BillingInvoicingId
		FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
		  WHERE CM.CustomerId = ISNULL(@customerid,CM.CustomerId) AND CM.IsStandAloneCM = 1           
		    AND CM.StatusId = @CMPostedStatusId
		    AND CM.MasterCompanyId = @mastercompanyid      
		    AND (CASE WHEN @exludedebit = 2 THEN CM.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CM.Amount END < 0)
		    AND CAST(CM.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) 
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

	UNION ALL

		SELECT ESOBI.[SOBillingInvoicingId] AS BillingInvoicingId 
			FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)    
			INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
			INNER JOIN [dbo].[Customer] CUST WITH (NOLOCK) ON CUST.CustomerId = ESO.CustomerId 
			 LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
			INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CUST.CustomerTypeId = CT.CustomerTypeId
			INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK) ON ESOP.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId      
			INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] ESOBII WITH (NOLOCK) ON ESOBII.SOBillingInvoicingId = ESOBI.SOBillingInvoicingId AND ESOBII.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId      
			INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = ESOBI.CurrencyId      
			INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId      
			 LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID			
	     WHERE ESO.[CustomerId] = ISNULL(@customerid,ESO.[CustomerId])
			AND ESOBI.[RemainingAmount] > 0 
			AND ESOBI.[InvoiceStatus] = 'Invoiced' 
			AND CAST(ESOBI.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) 
			AND ESO.[MasterCompanyId] = @mastercompanyid   
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
		
		-- Work Order Order Invoicing --

             SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
                    UPPER(CR.Code) AS  'currencyCode',      
                    wobi.GrandTotal AS 'BalanceAmount',      
                    (wobi.GrandTotal - wobi.RemainingAmount  + ISNULL(wobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
                    wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)  AS 'PaymentAmount',      
                    UPPER(wobi.InvoiceNo) AS 'InvoiceNo',      
                    wobi.InvoiceDate AS InvoiceDate,      
                    ISNULL(ctm.NetDays,0) AS NetDays,   
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN wobi.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
					UPPER(C.UpdatedBy) AS UpdatedBy,      
					(wop.ManagementStructureId) AS ManagementStructureId,      
					UPPER('AR-Inv') AS 'DocType',      
					UPPER(wop.CustomerReference) AS 'CustomerRef',      
					UPPER(ISNULL(emp.FirstName,'Unassigned')) AS 'Salesperson',      
					UPPER(ctm.Name) AS 'Terms',      
					'0.000000' AS 'FixRateAmount',      
					wobi.GrandTotal AS 'InvoiceAmount',      
					--B.CMAmount AS 'CMAmount', 
					0 AS 'CMAmount',
					B.CMAmount AS CreditMemoAmount,
					ISNULL(wobi.CreditMemoUsed,0) AS CreditMemoUsed,
					(CASE WHEN ISNULL((wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)+ ISNULL(B.CMAmount,0)),0) > 0 THEN (CASE WHEN ISNULL(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					DATEADD(DAY, ctm.NetDays,wobi.InvoiceDate) AS 'DueDate',      
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
					wobi.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId,
					A.InvoicePaidAmount
         FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK)       
         INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId      
         INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId      
         LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId      
         LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
         INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
         INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId      
         INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID      
         INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId      
         INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID      
          LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID      
		 OUTER APPLY      
		 (      
			SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
			       MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
				   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
				   SUM(IPS.FxRate)  AS 'FxRate',
				   SUM( IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
			       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
				   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
				   MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount      
			 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
			 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
			 WHERE wobi.BillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId = 2 AND IPS.InvoiceType = 2 
			 GROUP BY IPS.SOBillingInvoicingId       
	     ) A      
		 OUTER APPLY      
		 (      
			 SELECT SUM(CMD.Amount) AS 'CMAmount'      
			 FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
			 INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId      
			 WHERE wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId AND CM.StatusId = @CMPostedStatusId
			 GROUP BY CMD.BillingInvoicingItemId       
		  ) B      
		  WHERE WO.CustomerId = ISNULL(@customerid,WO.CustomerId) AND wobi.IsVersionIncrease = 0   
		  AND wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' 
		  AND CAST(wobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
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

	-- Sales Order Invoicing --
  
	SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode',      
					sobi.GrandTotal AS 'BalanceAmount',      
					(sobi.GrandTotal - sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
					sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) AS 'PaymentAmount',      
					UPPER(sobi.InvoiceNo) AS 'InvoiceNo',      
					sobi.InvoiceDate AS InvoiceDate,      
					ISNULL(ctm.NetDays,0) AS NetDays,      						
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
                    UPPER(C.UpdatedBy) AS UpdatedBy,      
					(SO.ManagementStructureId) AS ManagementStructureId,      
					UPPER('AR-Inv') AS 'DocType',      
					UPPER(sop.CustomerReference) AS 'CustomerRef',      
					UPPER(ISNULL(SO.SalesPersonName,'Unassigned')) AS 'Salesperson',      
					UPPER(ctm.[Name]) AS 'Terms',      
					'0.000000' AS 'FixRateAmount',      
					sobi.GrandTotal AS 'InvoiceAmount',      
					0 AS 'CMAmount',   
					B.CMAmount AS CreditMemoAmount,
					sobi.CreditMemoUsed,
					(CASE WHEN ISNULL((sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) + Isnull(B.CMAmount,0)),0) > 0 THEN (CASE WHEN isnull(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					DATEADD(DAY, ctm.NetDays,sobi.InvoiceDate) AS 'DueDate',      
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
					sobi.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId,
					A.InvoicePaidAmount
				FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK)       
				  INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId      
				  INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId      
				   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId      
				  INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
				  INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId      
				  INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId      
				  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId      
				  INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
				   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID      
				  OUTER APPLY      
				  (      
					 SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
					        MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
							SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
							SUM(IPS.FxRate)  AS 'FxRate',
							SUM(IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
					        MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
							MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
							MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount      
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
					 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
					 WHERE sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType=1 
					 GROUP BY IPS.SOBillingInvoicingId       
				  ) A      
				  OUTER APPLY      
				  (      
					 SELECT SUM(CMD.Amount)  AS 'CMAmount'      
					 FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
					 INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId  AND CM.StatusId = @CMPostedStatusId 
					 WHERE sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId 
					 GROUP BY CMD.BillingInvoicingItemId       
				  ) B      
				  WHERE SO.CustomerId = ISNULL(@customerid,SO.CustomerId)
				  AND sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' 
				  AND CAST(sobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid      
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
				  
		UNION ALL  

		-- Credit Memo For WO Invoice --

		     SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
                    UPPER(CR.Code) AS  'currencyCode',      
                    wobi.GrandTotal AS 'BalanceAmount',      
                    (wobi.GrandTotal - wobi.RemainingAmount  + ISNULL(wobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
                    wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)  AS 'PaymentAmount',      
                    UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',      
                    wobi.InvoiceDate AS InvoiceDate,      
                    ISNULL(ctm.NetDays,0) AS NetDays,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN wobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
					UPPER(C.UpdatedBy) AS UpdatedBy,      
					(CM.ManagementStructureId) AS ManagementStructureId,      
					UPPER('Credit-Memo') AS 'DocType',      
					UPPER(wop.CustomerReference) AS 'CustomerRef',      
					UPPER(isnull(emp.FirstName,'Unassigned')) AS 'Salesperson',      
					ctm.Name AS 'Terms',  
					--'-' AS 'Terms',  
					'0.000000' AS 'FixRateAmount',      
					--wobi.GrandTotal AS 'InvoiceAmount',  
					CMD.Amount AS 'InvoiceAmount', 
					CMD.Amount AS 'CMAmount', 
					CMD.Amount AS CreditMemoAmount,
					ISNULL(wobi.CreditMemoUsed,0) AS CreditMemoUsed,
					(CASE WHEN ISNULL((wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)+ Isnull(CMD.Amount,0)),0) > 0 THEN (CASE WHEN ISNULL(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					--DATEADD(DAY, ctm.NetDays,CM.CreatedDate) AS 'DueDate',  
					NULL AS 'DueDate', 
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
				    wobi.MasterCompanyId,
					1 AS IsCreditMemo,
					CM.StatusId,
					0 AS 'InvoicePaidAmount'
		 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
		 INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
         INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK) ON CM.InvoiceId = wobi.BillingInvoicingId       
         INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId      
         INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId      
         LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId      
         LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
         INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
         INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId      
         INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON wop.ID = wobii.WorkOrderPartId AND wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID      
         INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId      
		 INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
          LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID      
		 OUTER APPLY      
		 (      
			SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
			       MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
				   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
				   SUM(IPS.FxRate)  AS 'FxRate',
				   SUM( IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
			       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
				   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
				   MAX(Isnull(IPS.BankFeeAmount,0)) AS BankFeeAmount      
			 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
			 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
			 WHERE wobi.BillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType = 2 
			 GROUP BY IPS.SOBillingInvoicingId       
	     ) A      
		 --OUTER APPLY      
		 --(      
			-- SELECT SUM(CMD.Amount)  AS 'CMAmount'      
			-- FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
			-- INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId      
			-- WHERE wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId AND CM.StatusId = 3
			-- GROUP BY CMD.BillingInvoicingItemId       
		 -- ) B      
		  WHERE WO.CustomerId = ISNULL(@customerid,WO.CustomerId) AND CMD.IsWorkOrder = 1  
		  AND CM.StatusId = @CMPostedStatusId		  
		  AND (CASE WHEN @exludedebit = 2 THEN CMD.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CMD.Amount END < 0)
		  AND CAST(wobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
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

	-- Credit Memo For SO Invoice --

	SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode',      
					sobi.GrandTotal AS 'BalanceAmount',      
					(sobi.GrandTotal - sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
					sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) AS 'PaymentAmount',      
					UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',      
					sobi.InvoiceDate AS InvoiceDate,      
					ISNULL(ctm.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,					
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
                    UPPER(C.UpdatedBy) AS UpdatedBy,      
					(CM.ManagementStructureId) AS ManagementStructureId,      
					UPPER('Credit-Memo') AS 'DocType',        
					UPPER(sop.CustomerReference) AS 'CustomerRef',      
					UPPER(ISNULL(SO.SalesPersonName,'Unassigned')) AS 'Salesperson',      
					ctm.[Name] AS 'Terms',  
					--'-' AS 'Terms',  
					'0.000000' AS 'FixRateAmount',      
					--sobi.GrandTotal AS 'InvoiceAmount',  
					CMD.Amount AS 'InvoiceAmount', 
					CMD.Amount AS 'CMAmount', 
					CMD.Amount AS CreditMemoAmount,
					sobi.CreditMemoUsed,
					(CASE WHEN ISNULL((sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) + Isnull(CMD.Amount,0)),0) > 0 THEN (CASE WHEN isnull(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					--DATEADD(DAY, ctm.NetDays,sobi.InvoiceDate) AS 'DueDate',   
					NULL AS 'DueDate', 
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
					sobi.MasterCompanyId,
					1 AS IsCreditMemo,
					CM.StatusId,
					0 AS 'InvoicePaidAmount'
			  FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
		          INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				  INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) ON CMD.InvoiceId = sobi.SOBillingInvoicingId       
				  INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId      
				  INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId      
				   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId      
				  INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
				  INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId      
				  INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId      
				  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId      
				  --INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
				  INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
				  LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID      
				  OUTER APPLY      
				  (      
					 SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
					        MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
							SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
							SUM(IPS.FxRate)  AS 'FxRate',
							SUM(IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
					        MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
							MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
							MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount      
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
					 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
					 WHERE sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType=1 
					 GROUP BY IPS.SOBillingInvoicingId       
				  ) A      
				  --OUTER APPLY      
				  --(      
					 --SELECT SUM(CMD.Amount)  AS 'CMAmount'      
					 --FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
					 --INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId  AND CM.StatusId = 3 
					 --WHERE sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId 
					 --GROUP BY CMD.BillingInvoicingItemId       
				  --) B      
				  WHERE SO.CustomerId = ISNULL(@customerid,SO.CustomerId) AND CMD.IsWorkOrder = 0           
				  AND CM.StatusId = @CMPostedStatusId				  
				  AND (CASE WHEN @exludedebit = 2 THEN CMD.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CMD.Amount END < 0)
				  AND CAST(sobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid      
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

		UNION ALL

		-- Manual Journal --

		SELECT DISTINCT (MJD.ReferenceId) AS CustomerId,
			   UPPER(ISNULL(CST.[Name],'')) 'CustName' ,      
			   UPPER(ISNULL(CST.CustomerCode,'')) 'CustomerCode' ,      
			   UPPER(CT.CustomerTypeName) 'CustomertType' ,      
			   UPPER(CR.Code) AS  'currencyCode',
			   0 AS 'BalanceAmount',       -- need to discuss
			   0 AS 'CurrentlAmount',      -- need to discuss
			   0 AS 'PaymentAmount',      
			   UPPER(MJH.JournalNumber) AS 'InvoiceNo',      
			   MJH.[PostedDate] AS InvoiceDate,      
			   ISNULL(CTM.NetDays,0) AS NetDays, 
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
					 WHEN ctm.Code='CIA' THEN -1      
					 WHEN ctm.Code='CreditCard' THEN -1      
					 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby30days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby60days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby90days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby120days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
			   UPPER(MJD.UpdatedBy) AS UpdatedBy,      
			   MJD.ManagementStructureId, 
			   UPPER('Manual Journal') AS 'DocType',      
			   '' AS 'CustomerRef',      
			   ''AS 'Salesperson',	   
			  -- '-' AS 'Terms',  
			   UPPER(CTM.[Name]) AS 'Terms',      
			   '0.000000' AS 'FixRateAmount',      
			   --(ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) AS 'InvoiceAmount', 
			   ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0)  AS 'InvoiceAmount', 
			   0  AS 'CMAmount',    
			   0 AS CreditMemoAmount,
			   0 AS CreditMemoUsed,   -- need to discuss
			   1 AS 'FROMDebit',       -- need to discuss 					
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
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
		  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.CustomerId = MJD.ReferenceId
		   LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.CustomerId = CST.CustomerId
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 
		   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CSF.CreditTermsId      
		   LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.CustomerTypeId = CT.CustomerTypeId      
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
		   WHERE MJD.ReferenceId= ISNULL(@customerid,MJD.ReferenceId)  
			AND MJH.[ManualJournalStatusId] = @PostStatusId
			AND MJD.[ReferenceTypeId] = 1  
			AND (CASE WHEN @exludedebit = 2 THEN (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) END > 0 OR CASE WHEN @exludedebit = 1 THEN (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) END IS NOT NULL)
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@ToDate AS DATE) AND MJH.MasterCompanyId = @mastercompanyid      
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

		GROUP BY MJD.ReferenceId,CST.[Name],CST.CustomerCode,CT.CustomerTypeName,CR.Code,MJH.JournalNumber, 
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

		UNION ALL

		-- Stand Alone Credit Memo --

		SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode', 
					CM.Amount AS 'BalanceAmount',    
					CM.Amount AS 'CurrentlAmount',     
					CM.Amount AS 'PaymentAmount',  
					UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',
					CM.InvoiceDate AS InvoiceDate,  
					ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
							 WHEN ctm.Code='CIA' THEN -1
							 WHEN ctm.Code='CreditCard' THEN -1
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN CM.Amount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN CM.Amount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN CM.Amount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN CM.Amount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN CM.Amount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN CM.Amount ELSE 0 END) AS Amountpaidbymorethan120days,      
				UPPER(CM.UpdatedBy) AS UpdatedBy, 
				(CM.ManagementStructureId) AS ManagementStructureId,     
				UPPER('Stand Alone Credit Memo') AS 'DocType',    
				'' AS 'CustomerRef',      
				'' AS 'Salesperson',   				
				UPPER(CTM.[Name]) AS 'Terms',    
				'0.000000' AS 'FixRateAmount',      
				CM.Amount AS 'InvoiceAmount', 
				CM.Amount AS 'CMAmount', 
				CM.Amount AS CreditMemoAmount,
				0 AS CreditMemoUsed,
			    1 AS 'FROMDebit',   
				NULL AS 'DueDate', 
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
				CM.MasterCompanyId,
				1 AS IsCreditMemo,
				CM.StatusId,
				0 AS 'InvoicePaidAmount'
		   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
		  WHERE CM.CustomerId = ISNULL(@customerid,CM.CustomerId) 
		    AND CM.IsStandAloneCM = 1           
		    AND CM.StatusId = @CMPostedStatusId
		    AND CM.MasterCompanyId = @mastercompanyid      
		    AND (CASE WHEN @exludedebit = 2 THEN CM.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CM.Amount END < 0)
		    AND CAST(CM.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) 
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
			
	  UNION ALL

		-- Exchange SO --
			
	  SELECT DISTINCT (CUST.CustomerId) AS 'CustomerId',
			     UPPER(ISNULL(CUST.[Name],'')) 'CustName',  
				 UPPER(ISNULL(CUST.CustomerCode,'')) 'CustomerCode',      
                 UPPER(CT.[CustomerTypeName]) 'CustomertType',   
				 UPPER(CR.[Code]) AS  'currencyCode', 
				 (ESOBI.[GrandTotal]) AS 'BalanceAmount',
			     (ESOBI.[GrandTotal] - ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)) AS 'CurrentlAmount',
				 (ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)) AS 'PaymentAmount', 				 
				 (ESOBI.[InvoiceNo]) AS 'InvoiceNo',
				 (ESOBI.[InvoiceDate]) AS 'InvoiceDate',
				 ISNULL(CTM.[NetDays],0) AS NetDays,   
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1
					   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) <= 0 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS AmountpaidbylessTHEN0days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
					   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 30 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby30days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
					   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 60 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby60days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 	   WHEN CTM.[Code]='CIA' THEN -1
				 	   WHEN CTM.[Code]='CreditCard' THEN -1
				 	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 90 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby90days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 	   WHEN CTM.[Code]='CIA' THEN -1
				 	   WHEN CTM.[Code]='CreditCard' THEN -1
				 	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby120days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 	   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidbymorethan120days,
				  UPPER(ESO.UpdatedBy) AS UpdatedBy, 
				  ESO.[ManagementStructureId] AS ManagementStructureId, 
				  UPPER('Exchange Invoice') AS 'DocType',
				  UPPER(ESO.[CustomerReference]) AS 'CustomerRef',   
				  UPPER(ISNULL(ESO.[SalesPersonName],'Unassigned')) AS 'Salesperson',    
				  UPPER(CTM.[Name]) AS 'Terms', 
				  '0.000000' AS 'FixRateAmount',
				  ESOBI.[GrandTotal] AS 'InvoiceAmount', 
				  0 AS 'CMAmount', 
				  0 AS 'CreditMemoAmount',
				  0 AS 'CreditMemoUsed',
				  1 AS 'FROMDebit',   
				  DATEADD(DAY, CTM.[NetDays],ESOBI.[InvoiceDate]) AS 'DueDate', 
				  UPPER(MSD.[Level1Name]) AS 'level1',        
				  UPPER(MSD.[Level2Name]) AS 'level2',       
				  UPPER(MSD.[Level3Name]) AS 'level3',       
				  UPPER(MSD.[Level4Name]) AS 'level4',       
				  UPPER(MSD.[Level5Name]) AS 'level5',       
				  UPPER(MSD.[Level6Name]) AS 'level6',       
				  UPPER(MSD.[Level7Name]) AS 'level7',       
				  UPPER(MSD.[Level8Name]) AS 'level8',       
				  UPPER(MSD.[Level9Name]) AS 'level9',       
				  UPPER(MSD.[Level10Name]) AS 'level10',
				  ESO.[MasterCompanyId],
				  0 AS 'IsCreditMemo',
				  0 AS 'StatusId',
				  A.[InvoicePaidAmount]
			FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)    
			INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
			INNER JOIN [dbo].[Customer] CUST WITH (NOLOCK) ON CUST.CustomerId = ESO.CustomerId 
			 LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
			INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CUST.CustomerTypeId = CT.CustomerTypeId
			INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK) ON ESOP.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId      
			INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] ESOBII WITH (NOLOCK) ON ESOBII.SOBillingInvoicingId = ESOBI.SOBillingInvoicingId AND ESOBII.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId      
			INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = ESOBI.CurrencyId      
			INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId      
			 LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			OUTER APPLY      
				  (      
					 SELECT SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount'							
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
					 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.[ReceiptId] = IPS.[ReceiptId]      
					 WHERE ESOBII.[SOBillingInvoicingId] = IPS.[SOBillingInvoicingId] AND CP.[StatusId] = 2 AND IPS.[InvoiceType] = 6 
					 GROUP BY IPS.[SOBillingInvoicingId]      
				  ) A
			WHERE ESO.[CustomerId] = ISNULL(@customerid,ESO.[CustomerId])
			AND ESOBI.[RemainingAmount] > 0 
			AND ESOBI.[InvoiceStatus] = 'Invoiced' 
			AND CAST(ESOBI.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) 
			AND ESO.[MasterCompanyId] = @mastercompanyid   
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
	)    
      
  , Result AS(      
    SELECT DISTINCT       
        (CTE.CustomerId) AS CustomerId ,      
        UPPER(((ISNULL(CTE.CustName,'')))) 'CustName' ,      
        UPPER(((ISNULL(CTE.CustomerCode,'')))) 'CustomerCode' ,      
        --(CTE.CustomertType) 'CustomertType' ,      
        --(CTE.currencyCode) AS  'currencyCode',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.InvoiceAmount - ISNULL(CTE.InvoicePaidAmount,0)),0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus  THEN 0 ELSE ISNULL(CTE.CreditMemoAmount,0) END END AS 'BalanceAmount',
	    --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.Amountpaidbylessthen0days + ISNULL(CTE.CreditMemoAmount,0)),0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CTE.CreditMemoAmount,0) END END AS 'CurrentlAmount',   
	    --ISNULL(CTE.PaymentAmount,0) AS 'PaymentAmount',      
        --(CTE.InvoiceNo) AS 'InvoiceNo',      
        --CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CTE.InvoiceDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END 'InvoiceDate',  
  --      CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END END AS 'Amountpaidbylessthen0days',   							
		--CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby30days) END,0)  END END AS 'Amountpaidby30days',                            					  
		--CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby60days) END,0) END END AS 'Amountpaidby60days',
		--CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby90days) END,0) END END AS 'Amountpaidby90days',
		--CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby120days) END,0) END END AS 'Amountpaidby120days',
		--CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbymorethan120days) END,0) END END AS 'Amountpaidbymorethan120days',  

		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END END AS 'Amountpaidbylessthen0days',   							
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE 0 END AS 'Amountpaidby30days',                            					  
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE 0 END AS 'Amountpaidby60days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE 0 END AS 'Amountpaidby90days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE 0 END AS 'Amountpaidby120days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE 0 END AS 'Amountpaidbymorethan120days',  
	   
	   --(C.CreatedDate) AS CreatedDate,      
        --(C.UpdatedDate) AS UpdatedDate,      
        --(C.CreatedBy) AS CreatedBy,      
        --(C.UpdatedBy) AS UpdatedBy,      
        --(CTE.ManagementStructureId) AS ManagementStructureId,      
        --CTE.DocType AS DocType,      
        --CTE.CustomerRef AS 'CustomerRef',      
        --CTE.SalespersON AS 'Salesperson',      
        --CTE.Terms AS 'Terms',      
        --CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 107) END 'DueDate',       
        --ISNULL(CTE.FixRateAmount,0) AS 'FixRateAmount',      
        ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount',      
        --ISNULL(CTE.CMAmount,0) 'CMAmount',  
		--ISNULL(CTE.CreditMemoUsed,0) 'CMAmountUsed',  
        --ISNULL(CTE.FROMDebit,0) AS 'FROMDebit',  
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
      INNER JOIN Customer AS c WITH (NOLOCK) ON c.CustomerId = CTE.CustomerId       
      WHERE C.MasterCompanyId = @MasterCompanyId 
	  --and CTE.FROMDebit =@exludedebit      
      
   ) , ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)      
   ,WithTotal (MastercompanyId, 
               TotalInvoiceAmount, --TotalCMAmount, TotalCMAmountUsed, 
               TotalBalanceAmount, 
			   --TotalCurrentlAmount, 
			   TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, 
			   TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days) 
			  AS (SELECT MastercompanyId, 
				SUM(InvoiceAmount) TotalInvoiceAmount,
				--FORMAT(SUM(CMAmount), 'N', 'en-us') TotalCMAmount,
				--FORMAT(SUM(CMAmountUsed), 'N', 'en-us') TotalCMAmountUsed,
				SUM(BalanceAmount) TotalBalanceAmount,
				--FORMAT(SUM(CurrentlAmount), 'N', 'en-us') TotalCurrentlAmount,
				SUM(Amountpaidbylessthen0days) TotalAmountpaidbylessthen0days,
				SUM(Amountpaidby30days) TotalAmountpaidby30days,
				SUM(Amountpaidby60days) TotalAmountpaidby60days,
				SUM(Amountpaidby90days) TotalAmountpaidby90days,
				SUM(Amountpaidby120days) TotalAmountpaidby120days,
				SUM(Amountpaidbymorethan120days) TotalAmountpaidbymorethan120days
		   FROM Result GROUP BY MastercompanyId)

   SELECT	CustomerId, 
            CustName, 
		    CustomerCode, 
            --CustomertType, 
			--currencyCode, 
			--PaymentAmount, 
			--InvoiceNo, 
			--InvoiceDate,
			SUM(InvoiceAmount) AS InvoiceAmount, 
			--CMAmount, 
			--CMAmountUsed, 
			SUM(BalanceAmount) AS BalanceAmount, 
			--CurrentlAmount, 
			SUM(Amountpaidbylessthen0days) AS Amountpaidbylessthen0days, 
			SUM(Amountpaidby30days) AS Amountpaidby30days, 
			SUM(Amountpaidby60days) AS Amountpaidby60days, 
			SUM(Amountpaidby90days) AS Amountpaidby90days, 
			SUM(Amountpaidby120days) AS Amountpaidby120days, 
			SUM(Amountpaidbymorethan120days) AS Amountpaidbymorethan120days,
			--CreatedDate, 
			--UpdatedDate, 
			--CreatedBy, 
			--UpdatedBy,
			--ManagementStructureId, 
			--DocType, CustomerRef, Salesperson, Terms, 
			--DueDate
			--FixRateAmount,
			--FROMDebit, 
			level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,			
			TotalInvoiceAmount, 
			--TotalCMAmount, TotalCMAmountUsed, 			 
			TotalBalanceAmount,
			--TotalCurrentlAmount, 
			TotalAmountpaidbylessthen0days,
			TotalAmountpaidby30days, 
			TotalAmountpaidby60days,
			TotalAmountpaidby90days, 
			TotalAmountpaidby120days, 
			TotalAmountpaidbymorethan120days
			
   INTO #TempResult1 FROM  Result FC
   INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
   GROUP BY CustomerId,CustName,CustomerCode,level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
            ,TotalInvoiceAmount,TotalBalanceAmount,TotalAmountpaidbylessthen0days,TotalAmountpaidby30days, TotalAmountpaidby60days,
			TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days
      
    SELECT @Count = COUNT(CustomerId) FROM #TempResult1      
      
    SELECT @Count AS TotalRecordsCount,
	CustomerId, 
	CustName, 
	CustomerCode, 
	--CustomertType, 
	--currencyCode, 
	--PaymentAmount, 
	--InvoiceNo, 
	--InvoiceDate,
	FORMAT(ISNULL(InvoiceAmount,0), 'N', 'en-us') AS 'InvoiceAmount',
	FORMAT(ISNULL(BalanceAmount,0), 'N', 'en-us') AS 'BalanceAmount',
	--FORMAT(ISNULL(CMAmount,0), 'N', 'en-us') AS 'CMAmount',
	--FORMAT(ISNULL(CMAmountUsed,0), 'N', 'en-us') AS 'CMAmountUsed',
	--FORMAT(ISNULL(CurrentlAmount,0), 'N', 'en-us') AS 'CurrentlAmount',
	FORMAT(ISNULL(Amountpaidbylessthen0days,0), 'N', 'en-us') AS 'Amountpaidbylessthen0days',
	FORMAT(ISNULL(Amountpaidby30days,0), 'N', 'en-us') AS 'Amountpaidby30days',
	FORMAT(ISNULL(Amountpaidby60days,0), 'N', 'en-us') AS 'Amountpaidby60days',
	FORMAT(ISNULL(Amountpaidby90days,0), 'N', 'en-us') AS 'Amountpaidby90days',
	FORMAT(ISNULL(Amountpaidby120days,0), 'N', 'en-us') AS 'Amountpaidby120days',
	FORMAT(ISNULL(Amountpaidbymorethan120days,0), 'N', 'en-us') AS 'Amountpaidbymorethan120days',
	--CreatedDate, 
	--UpdatedDate, 
	--CreatedBy, 
	--UpdatedBy, 
	--ManagementStructureId,
	--DocType, CustomerRef, Salesperson, Terms, DueDate, FixRateAmount,
	--FROMDebit, 
	level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
	TotalInvoiceAmount, --TotalCMAmount, TotalCMAmountUsed, 
	TotalBalanceAmount, 
	--TotalCurrentlAmount, 
	TotalAmountpaidbylessthen0days, 
	TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days
	FROM #TempResult1      

    ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN 1 ELSE 1       
        
    END      
        
	OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
  
	END
	ELSE
	BEGIN
	print @exludedebit
	;WITH CTE AS ( 
	        
			-- Work Order Order Invoicing --

             SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
                    UPPER(CR.Code) AS  'currencyCode',      
                    wobi.GrandTotal AS 'BalanceAmount',      
                    (wobi.GrandTotal - wobi.RemainingAmount  + ISNULL(wobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
                    wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)  AS 'PaymentAmount',      
                    UPPER(wobi.InvoiceNo) AS 'InvoiceNo',      
                    wobi.InvoiceDate AS InvoiceDate,      
                    ISNULL(ctm.NetDays,0) AS NetDays,      
						
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN wobi.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
					UPPER(C.UpdatedBy) AS UpdatedBy,      
					(wop.ManagementStructureId) AS ManagementStructureId,      
					UPPER('AR-Inv') AS 'DocType',      
					UPPER(wop.CustomerReference) AS 'CustomerRef',      
					UPPER(isnull(emp.FirstName,'Unassigned')) AS 'Salesperson',      
					UPPER(ctm.Name) AS 'Terms',      
					'0.000000' AS 'FixRateAmount',      
					wobi.GrandTotal AS 'InvoiceAmount',      
					--B.CMAmount AS 'CMAmount', 
					0 AS 'CMAmount',
					B.CMAmount AS CreditMemoAmount,
					ISNULL(wobi.CreditMemoUsed,0) AS CreditMemoUsed,
					(CASE WHEN ISNULL((wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)+ Isnull(B.CMAmount,0)),0) > 0 THEN (CASE WHEN isnull(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					DATEADD(DAY, ctm.NetDays,wobi.InvoiceDate) AS 'DueDate',      
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
					wobi.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId,
					A.InvoicePaidAmount
         FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK)       
         INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId      
         INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId      
         LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId      
         LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
         INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
         INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId      
         INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID      
         INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId      
         INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID      
          LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID      
		 OUTER APPLY      
		 (      
			SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
			       MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
				   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
				   SUM(IPS.FxRate)  AS 'FxRate',
				   SUM( IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
			       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
				   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
				   MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount      
			 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
			 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
			 WHERE wobi.BillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId = 2 AND IPS.InvoiceType = 2 
			 GROUP BY IPS.SOBillingInvoicingId       
	     ) A      
		 OUTER APPLY      
		 (      
			 SELECT SUM(CMD.Amount) AS 'CMAmount'      
			 FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
			 INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId      
			 WHERE wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId AND CM.StatusId = @CMPostedStatusId
			 GROUP BY CMD.BillingInvoicingItemId       
		  ) B      
		  WHERE WO.CustomerId = ISNULL(@customerid,WO.CustomerId)   
		  AND wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' 
		  AND CAST(wobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
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

	-- Sales Order Invoicing --
  
	SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode',      
					sobi.GrandTotal AS 'BalanceAmount',      
					(sobi.GrandTotal - sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
					sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) AS 'PaymentAmount',      
					UPPER(sobi.InvoiceNo) AS 'InvoiceNo',      
					sobi.InvoiceDate AS InvoiceDate,      
					ISNULL(ctm.NetDays,0) AS NetDays,      						
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
                    UPPER(C.UpdatedBy) AS UpdatedBy,      
					(SO.ManagementStructureId) AS ManagementStructureId,      
					UPPER('AR-Inv') AS 'DocType',      
					UPPER(sop.CustomerReference) AS 'CustomerRef',      
					UPPER(ISNULL(SO.SalesPersonName,'Unassigned')) AS 'Salesperson',      
					UPPER(ctm.[Name]) AS 'Terms',      
					'0.000000' AS 'FixRateAmount',      
					sobi.GrandTotal AS 'InvoiceAmount',      
					0 AS 'CMAmount',   
					B.CMAmount AS CreditMemoAmount,
					sobi.CreditMemoUsed,
					(CASE WHEN ISNULL((sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) + Isnull(B.CMAmount,0)),0) > 0 THEN (CASE WHEN isnull(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					DATEADD(DAY, ctm.NetDays,sobi.InvoiceDate) AS 'DueDate',      
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
					sobi.MasterCompanyId,
					0 AS IsCreditMemo,
					0 AS StatusId,
					A.InvoicePaidAmount
				FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK)       
				  INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId      
				  INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId      
				   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId      
				  INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
				  INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId      
				  INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId      
				  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId      
				  INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
				   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID      
				  OUTER APPLY      
				  (      
					 SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
					        MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
							SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
							SUM(IPS.FxRate)  AS 'FxRate',
							SUM(IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
					        MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
							MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
							MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount      
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
					 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
					 WHERE sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType=1 
					 GROUP BY IPS.SOBillingInvoicingId       
				  ) A      
				  OUTER APPLY      
				  (      
					 SELECT SUM(CMD.Amount)  AS 'CMAmount'      
					 FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
					 INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId  AND CM.StatusId = @CMPostedStatusId 
					 WHERE sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId 
					 GROUP BY CMD.BillingInvoicingItemId       
				  ) B      
				  WHERE SO.CustomerId = ISNULL(@customerid,SO.CustomerId)   
				  AND sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' 
				  AND CAST(sobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) 
				  AND SO.mastercompanyid = @mastercompanyid      
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
				  
		UNION ALL  

			--WO Credit Memo --

		     SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
                    UPPER(CR.Code) AS  'currencyCode',      
                    wobi.GrandTotal AS 'BalanceAmount',      
                    (wobi.GrandTotal - wobi.RemainingAmount  + ISNULL(wobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
                    wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)  AS 'PaymentAmount',      
                    UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',      
                    wobi.InvoiceDate AS InvoiceDate,      
                    ISNULL(ctm.NetDays,0) AS NetDays,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN wobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
					UPPER(C.UpdatedBy) AS UpdatedBy,      
					(CM.ManagementStructureId) AS ManagementStructureId,      					
					UPPER('Credit-Memo') AS 'DocType',    
					UPPER(wop.CustomerReference) AS 'CustomerRef',      
					UPPER(isnull(emp.FirstName,'Unassigned')) AS 'Salesperson',      
					--ctm.Name AS 'Terms',  
					'-' AS 'Terms',  
					'0.000000' AS 'FixRateAmount',      
					--wobi.GrandTotal AS 'InvoiceAmount',  
					CMD.Amount AS 'InvoiceAmount', 
					CMD.Amount AS 'CMAmount', 
					CMD.Amount AS CreditMemoAmount,
					ISNULL(wobi.CreditMemoUsed,0) AS CreditMemoUsed,
					(CASE WHEN ISNULL((wobi.RemainingAmount + ISNULL(wobi.CreditMemoUsed,0)+ Isnull(CMD.Amount,0)),0) > 0 THEN (CASE WHEN ISNULL(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					--DATEADD(DAY, ctm.NetDays,CM.CreatedDate) AS 'DueDate',  
					NULL AS 'DueDate', 
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
				    wobi.MasterCompanyId,
					1 AS IsCreditMemo,
					CM.StatusId,
					0 AS 'InvoicePaidAmount'
		 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
		 INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
         INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK) ON CM.InvoiceId = wobi.BillingInvoicingId       
         INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId      
         INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId      
         LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId      
         LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId      
         INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
         INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId      
         INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON wop.ID = wobii.WorkOrderPartId AND wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID      
         INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId      
		 INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
          LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID      
		 OUTER APPLY      
		 (      
			SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
			       MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
				   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
				   SUM(IPS.FxRate)  AS 'FxRate',
				   SUM( IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
			       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
				   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
				   MAX(Isnull(IPS.BankFeeAmount,0)) AS BankFeeAmount      
			 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
			 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
			 WHERE wobi.BillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType = 2 
			 GROUP BY IPS.SOBillingInvoicingId       
	     ) A      
		 --OUTER APPLY      
		 --(      
			-- SELECT SUM(CMD.Amount)  AS 'CMAmount'      
			-- FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
			-- INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId      
			-- WHERE wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId AND CM.StatusId = 3
			-- GROUP BY CMD.BillingInvoicingItemId       
		 -- ) B      
		  WHERE WO.CustomerId = ISNULL(@customerid,WO.CustomerId) AND CMD.IsWorkOrder = 1
		  AND CM.StatusId = @CMPostedStatusId
		  AND (CASE WHEN @exludedebit = 2 THEN CMD.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CMD.Amount END < 0)
		  AND CAST(wobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid      
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

		--SO Credit Memo --

	SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode',      
					sobi.GrandTotal AS 'BalanceAmount',      
					(sobi.GrandTotal - sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0)) AS 'CurrentlAmount',      
					sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) AS 'PaymentAmount',      
					UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',      
					sobi.InvoiceDate AS InvoiceDate,      
					ISNULL(ctm.NetDays,0) AS NetDays,      
						
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,					
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidbymorethan120days,      
                    UPPER(C.UpdatedBy) AS UpdatedBy,      
					(CM.ManagementStructureId) AS ManagementStructureId,      					 
					UPPER('Credit-Memo') AS 'DocType',    
					UPPER(sop.CustomerReference) AS 'CustomerRef',      
					UPPER(ISNULL(SO.SalesPersonName,'Unassigned')) AS 'Salesperson',      
					--ctm.[Name] AS 'Terms',  
					'-' AS 'Terms',  
					'0.000000' AS 'FixRateAmount',      
					--sobi.GrandTotal AS 'InvoiceAmount',  
					CMD.Amount AS 'InvoiceAmount', 
					CMD.Amount AS 'CMAmount', 
					CMD.Amount AS CreditMemoAmount,
					sobi.CreditMemoUsed,
					(CASE WHEN ISNULL((sobi.RemainingAmount + ISNULL(sobi.CreditMemoUsed,0) + Isnull(CMD.Amount,0)),0) > 0 THEN (CASE WHEN isnull(@exludedebit,2) =1 THEN  1 ELSE 2 END) ELSE 2 END) AS 'FROMDebit',      
					--DATEADD(DAY, ctm.NetDays,sobi.InvoiceDate) AS 'DueDate',  
					NULL AS 'DueDate', 
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
					sobi.MasterCompanyId,
					1 AS IsCreditMemo,
					CM.StatusId,
					0 AS 'InvoicePaidAmount'
			  FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
		          INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				  INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) ON CMD.InvoiceId = sobi.SOBillingInvoicingId       
				  INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId      
				  INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId      
				   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId      
				  INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId      
				  INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId      
				  INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId      
				  INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId      
				  --INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
				  INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
				  LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID      
				  OUTER APPLY      
				  (      
					 SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
					        MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
							SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
							SUM(IPS.FxRate)  AS 'FxRate',
							SUM(IPS.DiscAmount + IPS.OtherAdjustAmt + IPS.BankFeeAmount) AS AdjustMentAmount,      
					        MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
							MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
							MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount      
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
					 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId      
					 WHERE sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType=1 
					 GROUP BY IPS.SOBillingInvoicingId       
				  ) A      
				  --OUTER APPLY      
				  --(      
					 --SELECT SUM(CMD.Amount)  AS 'CMAmount'      
					 --FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)      
					 --INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId  AND CM.StatusId = 3 
					 --WHERE sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId 
					 --GROUP BY CMD.BillingInvoicingItemId       
				  --) B      
				  WHERE SO.CustomerId = ISNULL(@customerid,SO.CustomerId) AND CMD.IsWorkOrder = 0           
				  AND CM.StatusId = @CMPostedStatusId
				  AND (CASE WHEN @exludedebit = 2 THEN CMD.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CMD.Amount END < 0)
				  AND CAST(sobi.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid      
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
				  				  
			UNION ALL 

			-- Manual Journal --

			SELECT DISTINCT (MJD.ReferenceId) AS CustomerId,
			   UPPER(ISNULL(CST.[Name],'')) 'CustName' ,      
			   UPPER(ISNULL(CST.CustomerCode,'')) 'CustomerCode' ,      
			   UPPER(CT.CustomerTypeName) 'CustomertType' ,      
			   UPPER(CR.Code) AS  'currencyCode',
			   0 AS 'BalanceAmount',       -- need to discuss
			   0 AS 'CurrentlAmount',      -- need to discuss
			   0 AS 'PaymentAmount',      
			   UPPER(MJH.JournalNumber) AS 'InvoiceNo',      
			   MJH.[PostedDate] AS InvoiceDate,      
			   ISNULL(CTM.NetDays,0) AS NetDays, 
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
					 WHEN ctm.Code='CIA' THEN -1      
					 WHEN ctm.Code='CreditCard' THEN -1      
					 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN  ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN  ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby30days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN  ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby60days,      
			   (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN  ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby90days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN  ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby120days,      
			   (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   				 WHEN ctm.Code='CIA' THEN -1      
	   				 WHEN ctm.Code='CreditCard' THEN -1      
	   				 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
			   UPPER(MJD.UpdatedBy) AS UpdatedBy,      
			   MJD.ManagementStructureId, 
			   UPPER('Manual Journal') AS 'DocType',      
			   '' AS 'CustomerRef',      
			   ''AS 'Salesperson',	   
			   '-' AS 'Terms',  
			   '0.000000' AS 'FixRateAmount',      			   
			  -- (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) AS 'InvoiceAmount', 
			   ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0)  AS 'InvoiceAmount', 
			   0  AS 'CMAmount',    
			   0 AS CreditMemoAmount,
			   0 AS CreditMemoUsed,   -- need to discuss
			   1 AS 'FROMDebit',       -- need to discuss 					
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
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
		  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.CustomerId = MJD.ReferenceId 
		   LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.CustomerId = CST.CustomerId
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]    
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 
		   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CSF.CreditTermsId      
		   LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.CustomerTypeId = CT.CustomerTypeId      
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

		   WHERE MJD.ReferenceId= ISNULL(@customerid,MJD.ReferenceId) -- AND CMD.IsWorkOrder = 0    
			AND MJH.[ManualJournalStatusId] = @PostStatusId
			AND MJD.ReferenceTypeId = 1 
			AND (CASE WHEN @exludedebit = 2 THEN (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) END > 0 OR CASE WHEN @exludedebit = 1 THEN (ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) END IS NOT NULL)
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

			GROUP BY MJD.ReferenceId,CST.[Name],CST.CustomerCode,CT.CustomerTypeName,CR.Code,MJH.JournalNumber, 
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

		UNION ALL

		-- Stand Alone Credit Memo --

		SELECT DISTINCT (C.CustomerId) AS CustomerId,      
                    UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode', 
					CM.Amount AS 'BalanceAmount',    
					CM.Amount AS 'CurrentlAmount',     
					CM.Amount AS 'PaymentAmount',  
					UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',
					CM.InvoiceDate AS InvoiceDate,  
					ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
							 WHEN ctm.Code='CIA' THEN -1
							 WHEN ctm.Code='CreditCard' THEN -1
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN CM.Amount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN CM.Amount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN CM.Amount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN CM.Amount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN CM.Amount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN CM.Amount ELSE 0 END) AS Amountpaidbymorethan120days,      
				UPPER(CM.UpdatedBy) AS UpdatedBy, 
				(CM.ManagementStructureId) AS ManagementStructureId,     
				UPPER('Stand Alone Credit Memo') AS 'DocType',    
				'' AS 'CustomerRef',      
				'' AS 'Salesperson',   
				'-' AS 'Terms',  
				'0.000000' AS 'FixRateAmount',      
				CM.Amount AS 'InvoiceAmount', 
				CM.Amount AS 'CMAmount', 
				CM.Amount AS CreditMemoAmount,
				0 AS CreditMemoUsed,
			    1 AS 'FROMDebit',   
				NULL AS 'DueDate', 
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
				CM.MasterCompanyId,
				1 AS IsCreditMemo,
				CM.StatusId,
				0 AS 'InvoicePaidAmount'
		   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
		  WHERE CM.CustomerId = ISNULL(@customerid,CM.CustomerId) 
		    AND CM.IsStandAloneCM = 1           
		    AND CM.StatusId = @CMPostedStatusId
		    AND CM.MasterCompanyId = @mastercompanyid      
		    AND (CASE WHEN @exludedebit = 2 THEN CM.Amount END > 0 OR CASE WHEN @exludedebit = 1 THEN CM.Amount END < 0)
		    AND CAST(CM.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE) 
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

		UNION ALL

		-- Exchange SO --
			
	  SELECT DISTINCT (CUST.CustomerId) AS 'CustomerId',
			     UPPER(ISNULL(CUST.[Name],'')) 'CustName',  
				 UPPER(ISNULL(CUST.CustomerCode,'')) 'CustomerCode',      
                 UPPER(CT.[CustomerTypeName]) 'CustomertType',   
				 UPPER(CR.[Code]) AS  'currencyCode', 
				 (ESOBI.[GrandTotal]) AS 'BalanceAmount',
			     (ESOBI.[GrandTotal] - ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)) AS 'CurrentlAmount',
				 (ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)) AS 'PaymentAmount', 				 
				 (ESOBI.[InvoiceNo]) AS 'InvoiceNo',
				 (ESOBI.[InvoiceDate]) AS 'InvoiceDate',
				 ISNULL(CTM.[NetDays],0) AS NetDays,   
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1
					   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) <= 0 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS AmountpaidbylessTHEN0days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
					   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 30 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby30days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
					   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 60 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby60days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 	   WHEN CTM.[Code]='CIA' THEN -1
				 	   WHEN CTM.[Code]='CreditCard' THEN -1
				 	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 90 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby90days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 	   WHEN CTM.[Code]='CIA' THEN -1
				 	   WHEN CTM.[Code]='CreditCard' THEN -1
				 	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)  AS DATE), GETUTCDATE()) <= 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby120days,
				 (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 	   WHEN CTM.[Code]='CIA' THEN -1
					   WHEN CTM.[Code]='CreditCard' THEN -1
					   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(CTM.[NetDays],0) END) AS DATE), GETUTCDATE()) > 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidbymorethan120days,
				  UPPER(ESO.UpdatedBy) AS UpdatedBy, 
				  ESO.[ManagementStructureId] AS ManagementStructureId, 
				  UPPER('Exchange Invoice') AS 'DocType',
				  UPPER(ESO.[CustomerReference]) AS 'CustomerRef',   
				  UPPER(ISNULL(ESO.[SalesPersonName],'Unassigned')) AS 'Salesperson',    
				  UPPER(CTM.[Name]) AS 'Terms', 
				  '0.000000' AS 'FixRateAmount',
				  ESOBI.[GrandTotal] AS 'InvoiceAmount', 
				  0 AS 'CMAmount', 
				  0 AS 'CreditMemoAmount',
				  0 AS 'CreditMemoUsed',
				  1 AS 'FROMDebit',   
				  DATEADD(DAY, CTM.[NetDays],ESOBI.[InvoiceDate]) AS 'DueDate', 
				  UPPER(MSD.[Level1Name]) AS 'level1',        
				  UPPER(MSD.[Level2Name]) AS 'level2',       
				  UPPER(MSD.[Level3Name]) AS 'level3',       
				  UPPER(MSD.[Level4Name]) AS 'level4',       
				  UPPER(MSD.[Level5Name]) AS 'level5',       
				  UPPER(MSD.[Level6Name]) AS 'level6',       
				  UPPER(MSD.[Level7Name]) AS 'level7',       
				  UPPER(MSD.[Level8Name]) AS 'level8',       
				  UPPER(MSD.[Level9Name]) AS 'level9',       
				  UPPER(MSD.[Level10Name]) AS 'level10',
				  ESO.[MasterCompanyId],
				  0 AS 'IsCreditMemo',
				  0 AS 'StatusId',
				  A.[InvoicePaidAmount]
			FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)    
			INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
			INNER JOIN [dbo].[Customer] CUST WITH (NOLOCK) ON CUST.CustomerId = ESO.CustomerId 
			 LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
			INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CUST.CustomerTypeId = CT.CustomerTypeId
			INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK) ON ESOP.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId      
			INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] ESOBII WITH (NOLOCK) ON ESOBII.SOBillingInvoicingId = ESOBI.SOBillingInvoicingId AND ESOBII.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId      
			INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = ESOBI.CurrencyId      
			INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId      
			 LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			OUTER APPLY      
				  (      
					 SELECT SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount'							
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)      
					 LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.[ReceiptId] = IPS.[ReceiptId]      
					 WHERE ESOBII.[SOBillingInvoicingId] = IPS.[SOBillingInvoicingId] AND CP.[StatusId] = 2 AND IPS.[InvoiceType] = 6 
					 GROUP BY IPS.[SOBillingInvoicingId]      
				  ) A
			WHERE ESO.[CustomerId] = ISNULL(@customerid,ESO.[CustomerId])
			AND ESOBI.[RemainingAmount] > 0 
			AND ESOBI.[InvoiceStatus] = 'Invoiced' 
			AND CAST(ESOBI.[InvoiceDate] AS DATE) <= CAST(@ToDate AS DATE) 
			AND ESO.[MasterCompanyId] = @mastercompanyid   
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
   )          
  , Result AS(      
    SELECT DISTINCT       
        (CTE.CustomerId) AS CustomerId ,      
        UPPER(((ISNULL(CTE.CustName,'')))) 'CustName' ,      
        UPPER(((ISNULL(CTE.CustomerCode,'')))) 'CustomerCode' ,      
        UPPER(CTE.CustomertType) 'CustomertType' ,      
        UPPER(CTE.currencyCode) AS  'currencyCode',      
        --FORMAT(ISNULL((CTE.PaymentAmount + Isnull(CTE.CMAmount,0)),0) , 'N', 'en-us') AS 'BalanceAmount',      
		--ISNULL(CTE.PaymentAmount,0) AS 'BalanceAmount',  
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.InvoiceAmount - ISNULL(CTE.InvoicePaidAmount,0)),0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus  THEN 0 ELSE ISNULL(CTE.CreditMemoAmount,0) END END AS 'BalanceAmount',
					  
        --(ISNULL((CTE.Amountpaidbylessthen0days + ISNULL(CTE.CMAmount,0) +ISNULL(CTE.CreditMemoUsed,0)),0)) AS 'CurrentlAmount',   
		--CASE WHEN CTE.IsCreditMemo = 0 THEN (ISNULL((CTE.Amountpaidbylessthen0days + ISNULL(CTE.CreditMemoAmount,0) +ISNULL(CTE.CreditMemoUsed,0)),0)) ELSE ISNULL(CTE.CreditMemoAmount,0) END AS 'CurrentlAmount',   	
        CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.Amountpaidbylessthen0days + ISNULL(CTE.CreditMemoAmount,0)),0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CTE.CreditMemoAmount,0) END END AS 'CurrentlAmount',   
	    ISNULL(CTE.PaymentAmount,0) AS 'PaymentAmount',      
        UPPER(CTE.InvoiceNo) AS 'InvoiceNo',      
        CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CTE.InvoiceDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END 'InvoiceDate',       
        
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END END AS 'Amountpaidbylessthen0days',   							
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) ELSE 0 END AS 'Amountpaidby30days',                            					  
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) ELSE 0 END AS 'Amountpaidby60days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0) ELSE 0 END AS 'Amountpaidby90days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN CTE.Amountpaidby120days ELSE (CTE.Amountpaidby120days) END,0) ELSE 0 END AS 'Amountpaidby120days',
		CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE 0 END AS 'Amountpaidbymorethan120days',  
			
	    (C.CreatedDate) AS CreatedDate,      
        (C.UpdatedDate) AS UpdatedDate,      
        UPPER(C.CreatedBy) AS CreatedBy,      
        UPPER(C.UpdatedBy) AS UpdatedBy,      
        (CTE.ManagementStructureId) AS ManagementStructureId,      
        UPPER(CTE.DocType) AS DocType,      
        UPPER(CTE.CustomerRef) AS 'CustomerRef',      
        UPPER(CTE.SalespersON) AS 'Salesperson',      
        UPPER(CTE.Terms) AS 'Terms',      
        CASE WHEN CTE.IsCreditMemo = 0 THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 107) END ELSE NULL END 'DueDate',       
        ISNULL(CTE.FixRateAmount,0) AS 'FixRateAmount',      
        ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount',      
        ISNULL(CTE.CMAmount,0) 'CMAmount',  
		ISNULL(CTE.CreditMemoUsed,0) 'CMAmountUsed',  
        ISNULL(CTE.FROMDebit,0) AS 'FROMDebit',  
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
      INNER JOIN Customer AS c WITH (NOLOCK) ON c.CustomerId = CTE.CustomerId       
      WHERE C.MasterCompanyId = @MasterCompanyId 
	  --and CTE.FROMDebit =@exludedebit      
      
   ) , ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)      
   ,WithTotal (MastercompanyId, TotalInvoiceAmount, TotalCMAmount, TotalCMAmountUsed, TotalBalanceAmount, TotalCurrentlAmount, TotalAmountpaidbylessthen0days, TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days) 
			  AS (SELECT MastercompanyId, 
				FORMAT(SUM(InvoiceAmount), 'N', 'en-us') TotalInvoiceAmount,
				FORMAT(SUM(CMAmount), 'N', 'en-us') TotalCMAmount,
				FORMAT(SUM(CMAmountUsed), 'N', 'en-us') TotalCMAmountUsed,
				FORMAT(SUM(BalanceAmount), 'N', 'en-us') TotalBalanceAmount,
				FORMAT(SUM(CurrentlAmount), 'N', 'en-us') TotalCurrentlAmount,
				FORMAT(SUM(Amountpaidbylessthen0days), 'N', 'en-us') TotalAmountpaidbylessthen0days,
				FORMAT(SUM(Amountpaidby30days), 'N', 'en-us') TotalAmountpaidby30days,
				FORMAT(SUM(Amountpaidby60days), 'N', 'en-us') TotalAmountpaidby60days,
				FORMAT(SUM(Amountpaidby90days), 'N', 'en-us') TotalAmountpaidby90days,
				FORMAT(SUM(Amountpaidby120days), 'N', 'en-us') TotalAmountpaidby120days,
				FORMAT(SUM(Amountpaidbymorethan120days), 'N', 'en-us') TotalAmountpaidbymorethan120days
				FROM Result
				GROUP BY MastercompanyId)

   SELECT	CustomerId, CustName, CustomerCode, CustomertType, currencyCode, PaymentAmount, InvoiceNo, InvoiceDate,
			InvoiceAmount, CMAmount, CMAmountUsed, BalanceAmount, CurrentlAmount, 
			Amountpaidbylessthen0days, Amountpaidby30days, Amountpaidby60days, Amountpaidby90days, Amountpaidby120days, Amountpaidbymorethan120days,
			CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, ManagementStructureId, DocType, CustomerRef, Salesperson, Terms, DueDate, FixRateAmount,
			FROMDebit, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
			TotalInvoiceAmount, TotalCMAmount, TotalCMAmountUsed, TotalBalanceAmount, TotalCurrentlAmount, TotalAmountpaidbylessthen0days, 
			TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days
   INTO #TempResult2 FROM  Result FC
   INNER JOIN WithTotal WC ON FC.MastercompanyId = WC.MastercompanyId
      
    SELECT @Count = COUNT(CustomerId) FROM #TempResult2    
      
    SELECT @Count AS TotalRecordsCount,
	CustomerId, CustName, CustomerCode, CustomertType, currencyCode, PaymentAmount, InvoiceNo, InvoiceDate,
	FORMAT(ISNULL(InvoiceAmount,0), 'N', 'en-us') AS 'InvoiceAmount',
	FORMAT(ISNULL(BalanceAmount,0), 'N', 'en-us') AS 'BalanceAmount',
	FORMAT(ISNULL(CMAmount,0), 'N', 'en-us') AS 'CMAmount',
	FORMAT(ISNULL(CMAmountUsed,0), 'N', 'en-us') AS 'CMAmountUsed',
	FORMAT(ISNULL(CurrentlAmount,0), 'N', 'en-us') AS 'CurrentlAmount',
	FORMAT(ISNULL(Amountpaidbylessthen0days,0), 'N', 'en-us') AS 'Amountpaidbylessthen0days',
	FORMAT(ISNULL(Amountpaidby30days,0), 'N', 'en-us') AS 'Amountpaidby30days',
	FORMAT(ISNULL(Amountpaidby60days,0), 'N', 'en-us') AS 'Amountpaidby60days',
	FORMAT(ISNULL(Amountpaidby90days,0), 'N', 'en-us') AS 'Amountpaidby90days',
	FORMAT(ISNULL(Amountpaidby120days,0), 'N', 'en-us') AS 'Amountpaidby120days',
	FORMAT(ISNULL(Amountpaidbymorethan120days,0), 'N', 'en-us') AS 'Amountpaidbymorethan120days',
	CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, ManagementStructureId, DocType, CustomerRef, Salesperson, Terms, DueDate, FixRateAmount,
	FROMDebit, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
	TotalInvoiceAmount, TotalCMAmount, TotalCMAmountUsed, TotalBalanceAmount, TotalCurrentlAmount, TotalAmountpaidbylessthen0days, 
	TotalAmountpaidby30days, TotalAmountpaidby60days, TotalAmountpaidby90days, TotalAmountpaidby120days, TotalAmountpaidbymorethan120days
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