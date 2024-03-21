/*************************************************************             
 ** File:   [GetCustomerLegalEntityWiseInvoiceDataDateWise]  
 ** Author: unknown  
 ** Description: This stored procedure is used Get Customer LegalEntity Wise Invoice Data  
 ** Purpose:           
 ** Date:              
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date          Author  Change Description              
 ** --   --------      -------  --------------------------------            
 1                 unknown          Created  
 2    13/09/2023   Moin Bloch       Modify(Added order by Invoice Date and Format the SP)  
 3    25-SEP-2023  Moin Bloch       Modified (Added Manual JE Amount)  
 4    26-SEP-2023  BHARGAV SALIYA   Convert Reference  FIELD into uppercase
 5    27-SEP-2023  Moin Bloch       Modify(Added Manual Journal Description)  
 6    16-OCT-2023  Moin Bloch       Modify(Added Posted Status Insted of Fulfilling Credit Memo Status)
 7    17-OCT-2023  Moin Bloch       Modify(Added Stand Alone Credit Memo)
 8    31-JAN-2024  Devendra Shekh	added isperforma Flage for WO
 9	  01/02/2024   AMIT GHEDIYA	    added isperforma Flage for SO
 10	  19/02/2024   Devendra Shekh	removed isperforma and added isinvoiceposted flage for wo
 11	  27/02/2024   Devendra Shekh	changes for profoma calculation
 12	  28/02/2024   Devendra Shekh  changes for amount calculation based on isproforma for wo and so
 13	  04/02/2024   Devendra Shekh  changes for amount calculation based on isproforma for wo and so
 14	  06/02/2024   Devendra Shekh  extra deposit amount issue resolved
 15   19/03/2024   Bhargav Saliya  Get Days And NetDays From WO,SO and ESO Table instead of CreditTerms Table

-- EXEC [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise] 77,23,'2022-05-12','2022-05-12',1,1,79,2  
  
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise]  
@CustomerId BIGINT = NULL,  
@ManagementStructureId BIGINT = NULL,  
@StartDate DATETIME = NULL,  
@EndDate DATETIME = NULL,  
@OpenTransactionsOnly BIT = 0,  
@IncludeCredits BIT = 0,  
@SiteId BIGINT = NULL,  
@MasterCompanyId INT = NULL  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  DECLARE @SOMSModuleID INT = 17;  
  DECLARE @WOMSModuleID INT = 12;    
  DECLARE @CreditMemoMSModuleID INT = 61  
  DECLARE @MSModuleId INT = 0   
  DECLARE @PostStatusId INT;  
  SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';  
  SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';  

  DECLARE @CMPostedStatusId INT
  SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
  
  IF(@OpenTransactionsOnly = 1 and @IncludeCredits =0)  
  BEGIN  
   SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId,   
           ct.CustomerId,  
           CAST(sobi.InvoiceDate AS DATE) AS InvoiceDate,     
           sobi.InvoiceNo AS InvoiceNo,  
           sobi.InvoiceStatus as InvoiceStatus,  
           STUFF(UPPER((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)  
			 INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId  
			 WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
			 FOR XML PATH(''))), 1, 1, '')  
           AS 'Reference',  
		   so.[CreditTermName] as CreditTerm,     
		   DateAdd(Day,ISNULL(so.NetDays,0),  
		   ISNULL(sobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
		   cr.Code AS Currency,  
		   ISNULL(SUM(CM.Amount),0) AS CM,  
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
			 CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
						CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END AS RemainingAmount,
		   ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)) AS PaidAmount  
     FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)  
		  INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId  
		  INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId  
		  --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId  
		  LEFT JOIN  [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
		  LEFT JOIN  [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
		  INNER JOIN [dbo].[SalesOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID  
		  INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
		  INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId  
		   LEFT JOIN [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
		  INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'      
          ON CM.InvoiceId = sobi.SOBillingInvoicingId   
		  OUTER APPLY (SELECT nwop.SalesOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].SalesOrderPart nwop WITH (NOLOCK)  
						INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.SalesOrderPartId = nwobii.SalesOrderPartId AND ISNULL(nwobii.IsProforma, 0) = 1
						INNER JOIN [dbo].[SalesOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.SOBillingInvoicingId = nwobi.SOBillingInvoicingId AND ISNULL(nwobi.IsProforma, 0) = 1
						and nwobii.SalesOrderPartId = nwop.SalesOrderPartId WHERE so.SalesOrderId = nwop.SalesOrderId GROUP BY nwop.SalesOrderId) AS DepositData
  
   WHERE sobi.InvoiceStatus = 'Invoiced' AND ISNULL(sobi.IsBilling,0) = 0  AND--sobi.RemainingAmount > 0 
   le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId  
   AND CAST(sobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) and CAST(@EndDate AS DATE) AND sobi.BillToSiteId=@SiteId  
   AND ((ISNULL(sobi.IsProforma, 0) = 0 AND (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) = (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) AND sobi.RemainingAmount > 0) 
   OR (ISNULL(sobi.IsProforma, 0) = 1 AND (ISNULL(sobi.GrandTotal, 0) - ISNULL(sobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
   GROUP BY  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,  
   so.[CreditTermName],so.NetDays,sobi.PostedDate,cr.Code,sobi.GrandTotal,sobi.RemainingAmount,sobi.IsProforma,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt     
     
   UNION ALL  
     
   SELECT DISTINCT wobi.BillingInvoicingId AS InvoiceId,  
    ct.CustomerId,  
    CAST(wobi.InvoiceDate AS DATE) AS InvoiceDate,  
    wobi.InvoiceNo AS InvoiceNo,  
    wobi.InvoiceStatus AS InvoiceStatus,  
    STUFF(UPPER((SELECT ', ' + WP.CustomerReference  
       FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)  
       INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId  
       WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId  
       FOR XML PATH(''))), 1, 1, '')   
       AS 'Reference',  
    WO.[CreditTerms] as CreditTerm,     
    DateAdd(Day,ISNULL(WO.NetDays,0),ISNULL(wobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
    cr.Code AS Currency,  
    ISNULL(SUM(CM.Amount),0) AS CM,  
	CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
    CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
		 CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END AS RemainingAmount,
    ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)) AS PaidAmount  
    FROM [dbo].[WorkOrder] WO WITH (NOLOCK)  
     INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId  
     INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsInvoicePosted, 0) = 0
     INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID AND ISNULL(wobi.IsInvoicePosted, 0) = 0
     INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId  
     --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms AND ctm.MasterCompanyId = @MasterCompanyId
	 --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId AND ctm.MasterCompanyId = @MasterCompanyId
     LEFT JOIN  [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
     LEFT JOIN  [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
     INNER JOIN [dbo].[WorkOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID  
     INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
     INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId  
      LEFT JOIN [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
     INNER JOIN [dbo].CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId  AND CA.StatusName='Approved'     
    ON CM.InvoiceId = wobi.BillingInvoicingId  
	 OUTER APPLY (SELECT nwop.WorkOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].WorkOrderPartNumber nwop WITH (NOLOCK)  
				--INNER JOIN [dbo].[WorkOrderPartNumber] nwop WITH (NOLOCK) ON NWO.WorkOrderId = nwop.WorkOrderId  
				INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.ID = nwobii.WorkOrderPartId AND ISNULL(nwobii.isPerformaInvoice, 0) = 1
				INNER JOIN [dbo].[WorkOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.BillingInvoicingId = nwobi.BillingInvoicingId AND ISNULL(nwobi.isPerformaInvoice, 0) = 1
				and nwobii.WorkOrderPartId = nwop.ID WHERE WO.WorkOrderId = nwop.WorkOrderId GROUP BY nwop.WorkOrderId) AS DepositData
        
    WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0   --wobi.RemainingAmount > 0 AND
     AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId  
     AND CAST(wobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId  
	 AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) AND wobi.RemainingAmount > 0) 
	 OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
     
    GROUP BY wobi.BillingInvoicingId,ct.CustomerId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,WO.[CreditTerms],     
    WO.NetDays,wobi.PostedDate,cr.Code,wobi.GrandTotal,wobi.RemainingAmount,wobi.IsPerformaInvoice,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt
    ORDER BY InvoiceDate   
  END  
  ELSE if(@IncludeCredits = 1 AND @OpenTransactionsOnly = 1)  
  BEGIN  
   SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId,   
          ct.CustomerId,  
          CAST(sobi.InvoiceDate as date) AS InvoiceDate,  
          sobi.InvoiceNo as InvoiceNo,  
          sobi.InvoiceStatus as InvoiceStatus,  
          STUFF(UPPER((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)  
		   INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId  
		   WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
		   FOR XML PATH(''))), 1, 1, '')  
          AS 'Reference',  
          so.[CreditTermName] as CreditTerm,     
          DateAdd(Day,ISNULL(so.NetDays,0),ISNULL(sobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
          cr.Code AS Currency,  
          ISNULL(SUM(CM.Amount),0) AS CM,  
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
				 CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END AS RemainingAmount,
          ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)) AS PaidAmount  
     FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)  
        INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId  
        INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId  
        --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId  
        LEFT JOIN  [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
        LEFT JOIN  [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
        INNER JOIN [dbo].[SalesOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID  
        INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
        INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId     
        LEFT JOIN  [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
        INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'      
           ON CM.InvoiceId = sobi.SOBillingInvoicingId  
		OUTER APPLY (SELECT nwop.SalesOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].SalesOrderPart nwop WITH (NOLOCK)  
					INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.SalesOrderPartId = nwobii.SalesOrderPartId AND ISNULL(nwobii.IsProforma, 0) = 1
					INNER JOIN [dbo].[SalesOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.SOBillingInvoicingId = nwobi.SOBillingInvoicingId AND ISNULL(nwobi.IsProforma, 0) = 1
					and nwobii.SalesOrderPartId = nwop.SalesOrderPartId WHERE so.SalesOrderId = nwop.SalesOrderId GROUP BY nwop.SalesOrderId) AS DepositData
				
            
     WHERE sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId AND ISNULL(sobi.IsBilling,0) = 0
       AND CAST(sobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)  
           AND sobi.BillToSiteId=@SiteId  
			AND ((ISNULL(sobi.IsProforma, 0) = 0 AND (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) = (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0))) 
			OR (ISNULL(sobi.IsProforma, 0) = 1 AND (ISNULL(sobi.GrandTotal, 0) - ISNULL(sobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
          GROUP BY  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,  
          so.[CreditTermName],so.NetDays,sobi.PostedDate,cr.Code,sobi.GrandTotal,sobi.RemainingAmount,sobi.IsProforma,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt       
     
   UNION ALL  
     
   SELECT DISTINCT wobi.BillingInvoicingId AS InvoiceId,  
          ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,  
          wobi.InvoiceNo AS InvoiceNo,  
          wobi.InvoiceStatus AS InvoiceStatus,  
          STUFF(UPPER((SELECT ', ' + WP.CustomerReference  
       FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)  
       INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId  
       WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId  
       FOR XML PATH(''))), 1, 1, '')   
       AS 'Reference',  
    WO.[CreditTerms] as CreditTerm,     
    DateAdd(Day,ISNULL(WO.NetDays,0),ISNULL(wobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
    cr.Code AS Currency,  
    ISNULL(SUM(CM.Amount),0) AS CM,  
	CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
    CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
		 CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END AS RemainingAmount,
    ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)) AS PaidAmount  
    FROM [dbo].[WorkOrder] WO WITH (NOLOCK)  
     INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId  
     INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsInvoicePosted, 0) = 0
     INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID AND ISNULL(wobi.IsInvoicePosted, 0) = 0 
     INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId  
     --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms AND ctm.MasterCompanyId = @MasterCompanyId  
	 --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId AND ctm.MasterCompanyId = @MasterCompanyId
     LEFT JOIN  [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
     LEFT JOIN  [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
     INNER JOIN [dbo].[WorkOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID  
     INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
     INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId     
     LEFT JOIN  [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
     INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'     
    ON CM.InvoiceId = wobi.BillingInvoicingId 
	OUTER APPLY (SELECT nwop.WorkOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].[WorkOrderPartNumber] nwop WITH (NOLOCK)  
				--INNER JOIN [dbo].[WorkOrderPartNumber] nwop WITH (NOLOCK) ON NWO.WorkOrderId = nwop.WorkOrderId  
				INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.ID = nwobii.WorkOrderPartId AND ISNULL(nwobii.isPerformaInvoice, 0) = 1
				INNER JOIN [dbo].[WorkOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.BillingInvoicingId = nwobi.BillingInvoicingId AND ISNULL(nwobi.isPerformaInvoice, 0) = 1
				and nwobii.WorkOrderPartId = nwop.ID WHERE WO.WorkOrderId = nwop.WorkOrderId GROUP BY nwop.WorkOrderId) AS DepositData
     
    WHERE wobi.InvoiceStatus = 'Invoiced' AND   
    wobi.IsVersionIncrease=0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId  
     AND CAST(wobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) and CAST(@EndDate AS DATE) AND wobi.SoldToSiteId = @SiteId  
	 AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) 
	 OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
     
    GROUP BY wobi.BillingInvoicingId,ct.CustomerId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,WO.[CreditTerms],     
    WO.NetDays,wobi.PostedDate,cr.Code,wobi.GrandTotal,wobi.RemainingAmount,wobi.IsPerformaInvoice,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt
  
   UNION ALL  
     
   SELECT DISTINCT CM.CreditMemoHeaderId AS InvoiceId,  
          CGL.CustomerId,CASt(CGL.CreatedDate AS date) AS InvoiceDate,  
          CM.CreditMemoNumber AS InvoiceNo,  
       'Payment' AS InvoiceStatus,  
       'CreditMemo' AS Reference,  
       ctm.[Name] AS CreditTerm,     
       DateAdd(Day,ISNULL(ctm.NetDays,0),  
       ISNULL(CGL.CreatedDate, '01/01/1900 23:59:59.999')) AS 'DueDate',  
       cr.Code AS Currency,  
       0 AS CM,  
       (ISNULL(CGL.CreditAmount,0) * -1) AS InvoiceAmount,  
       (ISNULL(CGL.CreditAmount,0) * -1) AS RemainingAmount,  
       0 AS PaidAmount  
       FROM [dbo].[CustomerGeneralLedger] CGL  WITH (NOLOCK)  
        INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CGL.ReferenceId AND CM.StatusId = @CMPostedStatusId  
        INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = CGL.CustomerId  
        LEFT JOIN  [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
        LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId AND ctm.MasterCompanyId = @MasterCompanyId  
        LEFT JOIN  [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
       WHERE CM.StatusId = @CMPostedStatusId AND   
       CGL.ModuleId = @CreditMemoMSModuleID AND CGL.CustomerId=@CustomerId   
     AND CAST(CGL.CreatedDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)   
  
   UNION ALL  
  
     SELECT DISTINCT MJH.ManualJournalHeaderId AS InvoiceId,  
      MJD.ReferenceId AS CustomerId,  
      CAST(MJH.[PostedDate] AS DATE) AS InvoiceDate,      
      UPPER(MJH.JournalNumber) AS 'InvoiceNo',     
      'Posted' AS InvoiceStatus,       
	  CASE WHEN LEN(UPPER(MJD.[Description])) <= 55 THEN UPPER(MJD.[Description])		
	        WHEN LEN(UPPER(MJD.[Description])) > 55  THEN LEFT(UPPER(MJD.[Description]), 55)  + ' ...'
			ELSE '' 
	  END AS Reference,
      CTM.[Name] AS CreditTerm,            
      DATEADD(DAY,ISNULL(CTM.NetDays,0),ISNULL(MJH.[PostedDate], '01/01/1900 23:59:59.999')) AS 'DueDate',  
      cr.Code AS Currency,  
      0 AS CM,       
	  ISNULL(SUM(MJD.Debit),0) -  ISNULL(SUM(MJD.Credit),0) AS InvoiceAmount, 
	  ISNULL(SUM(MJD.Debit),0) -  ISNULL(SUM(MJD.Credit),0) AS RemainingAmount,
      0 AS PaidAmount  
       FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)     
      INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
      INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.CustomerId = MJD.ReferenceId 
       LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.CustomerId = CST.CustomerId  
      INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]      
       LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID   
       LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CSF.CreditTermsId        
       LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.CustomerTypeId = CT.CustomerTypeId        
       LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId        
    WHERE MJD.[ReferenceId] = @CustomerId AND MJD.[ReferenceTypeId] = 1  
    AND MJH.[ManualJournalStatusId] = @PostStatusId  
    AND CAST(MJH.[PostedDate] AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)   
	GROUP BY MJH.ManualJournalHeaderId,MJD.ReferenceId,MJH.[PostedDate],MJH.JournalNumber,
	MJD.[Description],CTM.[Name],CTM.NetDays,cr.Code

              
	UNION ALL  
		
		 SELECT DISTINCT CM.CreditMemoHeaderId AS InvoiceId,
		        CM.CustomerId AS CustomerId,  
				CM.InvoiceDate,
				UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',
				'Posted' AS InvoiceStatus, 
				'Stand Alone Credit Memo' AS Reference, 
				CTM.[Name] AS CreditTerm,  
				DATEADD(DAY,ISNULL(CTM.NetDays,0),ISNULL(CM.InvoiceDate, '01/01/1900 23:59:59.999')) AS 'DueDate',  
		        CR.Code AS Currency,  
				0 AS CM,
				(ISNULL(CM.Amount,0)) AS InvoiceAmount,  
                (ISNULL(CM.Amount,0)) AS RemainingAmount, 
				 0 AS PaidAmount  
		   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		   WHERE CM.CustomerId=@CustomerId 
			 AND CM.StatusId = @CMPostedStatusId
			 AND CM.IsStandAloneCM = 1    
			 AND CAST(CM.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)   		   
		ORDER BY InvoiceDate      
		
  END  
  ELSE if(@IncludeCredits = 1 AND @OpenTransactionsOnly = 0)  
  BEGIN  
   SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId, 
          ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,  
          sobi.InvoiceNo as InvoiceNo,  
          sobi.InvoiceStatus as InvoiceStatus,  
          STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)  
		   INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId  
		   WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
		   FOR XML PATH('')), 1, 1, '')  
          AS 'Reference',  
	      so.[CreditTermName] as CreditTerm,     
	      DateAdd(Day,ISNULL(so.NetDays,0),ISNULL(sobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
	      cr.Code AS Currency,  
	      ISNULL(SUM(CM.Amount),0) AS CM,  
	      CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
		  CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
			   CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END AS RemainingAmount,
	      ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)) AS PaidAmount  
   FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)  
    INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId  
    INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId  
     --LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId  
     LEFT JOIN [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
     LEFT JOIN [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
    INNER JOIN [dbo].[SalesOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID  
    INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
    INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId     
     LEFT JOIN [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
    INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'      
    ON CM.InvoiceId = sobi.SOBillingInvoicingId  
	OUTER APPLY (SELECT nwop.SalesOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].SalesOrderPart nwop WITH (NOLOCK)  
			INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.SalesOrderPartId = nwobii.SalesOrderPartId AND ISNULL(nwobii.IsProforma, 0) = 1
			INNER JOIN [dbo].[SalesOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.SOBillingInvoicingId = nwobi.SOBillingInvoicingId AND ISNULL(nwobi.IsProforma, 0) = 1
			and nwobii.SalesOrderPartId = nwop.SalesOrderPartId WHERE so.SalesOrderId = nwop.SalesOrderId GROUP BY nwop.SalesOrderId) AS DepositData
     
   WHERE sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId   
    AND CAST(sobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) and CAST(@EndDate AS DATE)  
    AND sobi.BillToSiteId=@SiteId AND ISNULL(sobi.IsBilling,0) = 0   
	AND ((ISNULL(sobi.IsProforma, 0) = 0 AND (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) = (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0))) 
	OR (ISNULL(sobi.IsProforma, 0) = 1 AND (ISNULL(sobi.GrandTotal, 0) - ISNULL(sobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
   GROUP BY  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,  
   so.[CreditTermName],so.NetDays,sobi.PostedDate,cr.Code,sobi.GrandTotal,sobi.RemainingAmount,sobi.IsProforma,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt
     
   UNION ALL  
     
   SELECT DISTINCT wobi.BillingInvoicingId AS InvoiceId,  
          ct.CustomerId,  
		  CAST(wobi.InvoiceDate AS DATE) AS InvoiceDate,  
		  wobi.InvoiceNo AS InvoiceNo,  
		  wobi.InvoiceStatus AS InvoiceStatus,  
		  STUFF((SELECT ', ' + WP.CustomerReference  
          FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)  
          INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId  
          WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId  
          FOR XML PATH('')), 1, 1, '')   
          AS 'Reference',  
		  WO.[CreditTerms] as CreditTerm,     
		  DateAdd(Day,ISNULL(WO.NetDays,0),ISNULL(wobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
		  cr.Code AS Currency,  
		  ISNULL(SUM(CM.Amount),0) AS CM,  
		  CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
		  CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
			   CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END AS RemainingAmount,
		  ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)) AS PaidAmount  
    FROM [dbo].[WorkOrder] WO WITH (NOLOCK)  
     INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId  
     INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsInvoicePosted, 0) = 0
     INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID AND ISNULL(wobi.IsInvoicePosted, 0) = 0
     INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId  
      --LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms AND ctm.MasterCompanyId = @MasterCompanyId  
	  --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId AND ctm.MasterCompanyId = @MasterCompanyId
      LEFT JOIN [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
      LEFT JOIN [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
     INNER JOIN [dbo].[WorkOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID  
     INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
     INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId     
      LEFT JOIN [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
     INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'     
    ON CM.InvoiceId = wobi.BillingInvoicingId  
	OUTER APPLY (SELECT nwop.WorkOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].[WorkOrderPartNumber] nwop WITH (NOLOCK)  
				--INNER JOIN [dbo].[WorkOrderPartNumber] nwop WITH (NOLOCK) ON NWO.WorkOrderId = nwop.WorkOrderId  
				INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.ID = nwobii.WorkOrderPartId AND ISNULL(nwobii.isPerformaInvoice, 0) = 1
				INNER JOIN [dbo].[WorkOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.BillingInvoicingId = nwobi.BillingInvoicingId AND ISNULL(nwobi.isPerformaInvoice, 0) = 1
				and nwobii.WorkOrderPartId = nwop.ID WHERE WO.WorkOrderId = nwop.WorkOrderId GROUP BY nwop.WorkOrderId) AS DepositData
     
    WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId  
     AND CAST(wobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) AND wobi.SoldToSiteId = @SiteId
	 AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) 
	 OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
     GROUP BY wobi.BillingInvoicingId,ct.CustomerId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,WO.[CreditTerms],     
    WO.NetDays,wobi.PostedDate,cr.Code,wobi.GrandTotal,wobi.RemainingAmount,wobi.IsPerformaInvoice,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt
  
   UNION ALL  
     
   SELECT DISTINCT CM.CreditMemoHeaderId AS InvoiceId,  
		CGL.CustomerId,  
		CAST(CGL.CreatedDate AS DATE) AS InvoiceDate,  
		CM.CreditMemoNumber as InvoiceNo,  
		'Payment' as InvoiceStatus,  
		'CreditMemo' as Reference,  
		ctm.[Name] as CreditTerm,     
		DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(CGL.CreatedDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
		cr.Code AS Currency,  
		0 AS CM,  
		(Isnull(CGL.CreditAmount,0) * -1) as InvoiceAmount,  
		(Isnull(CGL.CreditAmount,0) * -1) AS RemainingAmount,  
		0 AS PaidAmount  
   FROM [dbo].[CustomerGeneralLedger] CGL  WITH (NOLOCK)  
    INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CGL.ReferenceId  and CM.StatusId = @CreditMemoMSModuleID  
    INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = CGL.CustomerId  
    LEFT JOIN  [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
    LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId AND ctm.MasterCompanyId = @MasterCompanyId  
    LEFT JOIN  [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
   WHERE CM.StatusId = @CreditMemoMSModuleID AND CGL.ModuleId=@CreditMemoMSModuleID and CGL.CustomerId=@CustomerId   
   AND CAST(CGL.CreatedDate AS DATE) BETWEEN CAST(@StartDate AS DATE) and CAST(@EndDate AS DATE)   
  
   UNION ALL  
  
     SELECT DISTINCT MJH.ManualJournalHeaderId AS InvoiceId,  
            MJD.ReferenceId AS CustomerId,  
		    CAST(MJH.[PostedDate] as date) AS InvoiceDate,      
		    UPPER(MJH.JournalNumber) AS InvoiceNo,     
		    'Posted' AS InvoiceStatus,  
		     CASE WHEN LEN(UPPER(MJD.[Description])) <= 55 THEN UPPER(MJD.[Description])		
				WHEN LEN(UPPER(MJD.[Description])) > 55  THEN LEFT(UPPER(MJD.[Description]), 55)  + ' ...'
			 ELSE '' 
		     END AS Reference,
		     CTM.[Name] AS CreditTerm,            
		     DATEADD(DAY,ISNULL(CTM.NetDays,0),ISNULL(MJH.[PostedDate], '01/01/1900 23:59:59.999')) AS 'DueDate',  
		     cr.Code AS Currency,  
		     0 AS CM,  		        
			 ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0)    AS InvoiceAmount,
             ISNULL(SUM(MJD.Debit),0) -  ISNULL(SUM(MJD.Credit),0)    AS RemainingAmount,
		     0 AS PaidAmount  
       FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)     
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId  
		  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.CustomerId = MJD.ReferenceId AND MJD.ReferenceTypeId = 1   
		   LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.CustomerId = CST.CustomerId  
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]      
		   LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = MSD.EntityMSID   
		   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CSF.CreditTermsId        
		   LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.CustomerTypeId = CT.CustomerTypeId        
		   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = MJH.FunctionalCurrencyId        
    WHERE MJD.[ReferenceId] = @CustomerId AND MJD.[ReferenceTypeId] = 1  
		AND MJH.[ManualJournalStatusId] = @PostStatusId  
		AND CAST(MJH.[PostedDate] AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
		GROUP BY MJH.ManualJournalHeaderId,MJD.ReferenceId,MJH.[PostedDate],MJH.JournalNumber,MJD.[Description],
		CTM.[Name],CTM.NetDays,cr.Code
	
  UNION ALL   
	
	   SELECT DISTINCT CM.CreditMemoHeaderId AS InvoiceId,
		        CM.CustomerId AS CustomerId,  
				CM.InvoiceDate,
				UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',
				'Posted' AS InvoiceStatus, 
				'Stand Alone Credit Memo' AS Reference, 
				CTM.[Name] AS CreditTerm,  
				DATEADD(DAY,ISNULL(CTM.NetDays,0),ISNULL(CM.InvoiceDate, '01/01/1900 23:59:59.999')) AS 'DueDate',  
		        CR.Code AS Currency,  
				0 AS CM,
				(ISNULL(CM.Amount,0)) AS InvoiceAmount,  
                (ISNULL(CM.Amount,0)) AS RemainingAmount, 
				 0 AS PaidAmount  
		   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		   WHERE CM.CustomerId=@CustomerId 
			 AND CM.StatusId = @CMPostedStatusId
			 AND CM.IsStandAloneCM = 1    
			 AND CAST(CM.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)   	
		ORDER BY InvoiceDate   

  END  
  ELSE  
  BEGIN  
   SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId,   
   ct.CustomerId,  
   CAST(sobi.InvoiceDate as date) AS InvoiceDate,  
   sobi.InvoiceNo as InvoiceNo,  
   sobi.InvoiceStatus as InvoiceStatus,  
   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)  
       INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId  
       WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId   
       FOR XML PATH('')), 1, 1, '')  
       AS 'Reference',  
   so.[CreditTermName] as CreditTerm,     
   DateAdd(Day,ISNULL(so.NetDays,0),ISNULL(sobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
   cr.Code AS Currency,  
   ISNULL(SUM(CM.Amount),0) AS CM,  
	CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
	CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
		 CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END AS RemainingAmount,
   ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)) AS PaidAmount  
   FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)  
    INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId  
    INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId  
     --LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId  
     LEFT JOIN [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
     LEFT JOIN [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
    INNER JOIN [dbo].[SalesOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID  
    INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
    INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId     
     LEFT JOIN [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
    INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'      
    ON CM.InvoiceId = sobi.SOBillingInvoicingId   
	OUTER APPLY (SELECT nwop.SalesOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].SalesOrderPart nwop WITH (NOLOCK)  
				INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.SalesOrderPartId = nwobii.SalesOrderPartId AND ISNULL(nwobii.IsProforma, 0) = 1
				INNER JOIN [dbo].[SalesOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.SOBillingInvoicingId = nwobi.SOBillingInvoicingId AND ISNULL(nwobi.IsProforma, 0) = 1
				and nwobii.SalesOrderPartId = nwop.SalesOrderPartId WHERE so.SalesOrderId = nwop.SalesOrderId GROUP BY nwop.SalesOrderId) AS DepositData
     
   WHERE sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId AND ISNULL(sobi.IsBilling,0) = 0
   AND CAST(sobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)  
   AND sobi.BillToSiteId=@SiteId  
   AND ((ISNULL(sobi.IsProforma, 0) = 0 AND (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) = (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0))) 
   OR (ISNULL(sobi.IsProforma, 0) = 1 AND (ISNULL(sobi.GrandTotal, 0) - ISNULL(sobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
   GROUP BY  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,  
   so.[CreditTermName],so.NetDays,sobi.PostedDate,cr.Code,sobi.GrandTotal,sobi.RemainingAmount,sobi.IsProforma,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt   
     
   UNION ALL  
     
   select DISTINCT wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,  
   wobi.InvoiceNo as InvoiceNo,  
   wobi.InvoiceStatus as InvoiceStatus,  
   STUFF((SELECT ', ' + WP.CustomerReference  
       FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)  
       INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId  
       WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId  
       FOR XML PATH('')), 1, 1, '')   
       AS 'Reference',  
   WO.[CreditTerms] as CreditTerm,     
   DateAdd(Day,ISNULL(WO.NetDays,0),ISNULL(wobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',  
   cr.Code AS Currency,  
   ISNULL(SUM(CM.Amount),0) AS CM,     
	CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.GrandTotal) ELSE 0 END AS InvoiceAmount,  
	CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
		 CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END AS RemainingAmount,
   ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)) AS PaidAmount  
   FROM [dbo].[WorkOrder] WO WITH (NOLOCK)  
    INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId  
    INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsInvoicePosted, 0) = 0
    INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID AND ISNULL(wobi.IsInvoicePosted, 0) = 0
    INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId  
     --LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms AND ctm.MasterCompanyId = @MasterCompanyId  
	 --LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId AND ctm.MasterCompanyId = @MasterCompanyId
     LEFT JOIN [dbo].[CustomerFinancial] CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId  
     LEFT JOIN [dbo].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId  
    INNER JOIN [dbo].[WorkOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID  
    INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id  
    INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId     
     LEFT JOIN [dbo].[CreditMemoDetails] CM WITH(NOLOCK)   
    INNER JOIN [dbo].[CreditMemoApproval] CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'     
   ON CM.InvoiceId = wobi.BillingInvoicingId  
   OUTER APPLY (SELECT nwop.WorkOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].[WorkOrderPartNumber] nwop WITH (NOLOCK)  
				INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.ID = nwobii.WorkOrderPartId AND ISNULL(nwobii.isPerformaInvoice, 0) = 1
				INNER JOIN [dbo].[WorkOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.BillingInvoicingId = nwobi.BillingInvoicingId AND ISNULL(nwobi.isPerformaInvoice, 0) = 1
				and nwobii.WorkOrderPartId = nwop.ID WHERE WO.WorkOrderId = nwop.WorkOrderId GROUP BY nwop.WorkOrderId) AS DepositData
     
   WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease = 0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId  
   AND CAST(wobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) AND wobi.SoldToSiteId=@SiteId  
   AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) 
   OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
     
   GROUP BY wobi.BillingInvoicingId,ct.CustomerId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,WO.[CreditTerms],     
   WO.NetDays,wobi.PostedDate,cr.Code,wobi.GrandTotal,wobi.RemainingAmount,wobi.IsPerformaInvoice,DepositData.OriginalDepositAmt,DepositData.UsedDepositAmt
   ORDER BY InvoiceDate   
    
  END  
     
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'GetCustomerWiseLegalEntityData'   
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@customerId AS VARCHAR(10)), '') + ''  
        , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        exec spLogException   
                @DatabaseName           = @DatabaseName  
                , @AdhocComments          = @AdhocComments  
                , @ProcedureParameters = @ProcedureParameters  
                , @ApplicationName        =  @ApplicationName  
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
        RETURN(1);  
 END CATCH  
END