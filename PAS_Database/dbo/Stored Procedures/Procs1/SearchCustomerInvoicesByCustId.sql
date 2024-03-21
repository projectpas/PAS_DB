/*************************************************************             
 ** File:   [SearchCustomerInvoicesByCustId]             
 ** Author:   Satish Gohil  
 ** Description: This stored procedure is used to display Expire Stockline List
 ** Purpose:           
 ** Date:   19/05/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    19/05/2023   Satish Gohil     Show only legal entity releted invoice
	2    25/07/2023   Moin Bloch       Removed Credit Memo Used Amount from Remaining Amount
	3    18/09/2023   Hemant Saliya    Corrected Legal Entity Join
	4    03/10/2023   Moin Bloch       Added Stand Alone CreditMemo and Manual Journal Entry Details
	5    16/10/2023   Moin Bloch       Modify(Added Posted Status Insted of Fulfilling Credit Memo Status)
	6    10/11/2023   Amit Ghediya     Modify(Added Exchange Invoice)
	7    27/11/2023   Amit Ghediya     Modify(Exchange Invoice Disc Amount/Date)
	8    06/12/2023   Amit Ghediya     Modify(Exchange Invoice Disc Amount/Date)
	9    14/12/2023   Amit Ghediya     Modify(NetDays to Days for calculation)
	10   05/01/2024   Moin Bloch       Renamed CreditTerms.Percentage To PercentId
	11   02/1/2024	  AMIT GHEDIYA	   added isperforma Flage for SO
	12   08/02/2024	  Devendra Shekh   added IsInvoicePosted flage for WO
	13   14/02/2024	  AMIT GHEDIYA     added IsBilling flage for SO when standard invocie post proforma not available in Receipt information.
    14   14/02/2024	  Devendra Shekh    duplicate wo for multiple MPN issue resolved
	15   20/02/2024	  AMIT GHEDIYA      update Doc type name for performa for both SO & WO
	16   22/02/2024	  Devendra Shekh    added isperforma to select
	17   08/03/2024   Moin Bloch       Modify(makes DSO 0 when it goes negaitive)
	18   13/03/2024   Moin Bloch       Modify(makes Exchange Invoice to Invoice)
	19   15/03/2024   Moin Bloch       Modify(Changed DSO Logic)
	20   19/03/2024   Bhargav Saliya   Get Days And NetDays From WO,SO and ESO Table instead of CreditTerms Table
	21   13/03/2024   Moin Bloch       Modify(makes Performa Invoice to Invoice)
	EXEC  [dbo].[SearchCustomerInvoicesByCustId] 1122,1 
**************************************************************/ 

CREATE   PROCEDURE [dbo].[SearchCustomerInvoicesByCustId]      
@customerId BIGINT = NULL,
@legalEntityId BIGINT = 0
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
     DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12; -- Sales Order Management Structure Module ID      
     DECLARE @CreditMemoModuleId INT = 61;   
	 DECLARE @Level1SequenceNo INT = 1;
	 DECLARE @PostStatusId INT;
	 DECLARE @MSModuleId INT = 0;
	 DECLARE @ExSOMSModuleID INT = 19;
	 
	 DECLARE @CMPostedStatusId INT
	 SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

	 SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	 SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';
    
		SELECT SOBI.SalesOrderId AS 'Id',      
	         SOBI.SOBillingInvoicingId AS 'SOBillingInvoicingId',       
		      CASE WHEN SOBI.IsProforma = 1 THEN 'Invoice' ELSE 'Invoice' END  AS 'DocumentType',      
			  SOBI.InvoiceNo AS 'DocNum',       
			  SOBI.InvoiceDate,       
			  SOBI.GrandTotal AS 'OriginalAmount',       
			  SOBI.RemainingAmount, --+ ISNULL(SOBI.CreditMemoUsed,0) AS 'RemainingAmount',      
			  0 AS 'PaymentAmount',      
			  0 AS 'DiscAmount',       
			  Curr.Code AS 'CurrencyCode',       
			  0 AS 'FxRate',       
			  S.SalesOrderNumber AS 'WOSONum',      
			  0 AS 'NewRemainingBal',      
			  'Open' AS 'Status',      
			  CASE WHEN SOBI.IsProforma = 1 THEN 0 ELSE DATEDIFF(DAY, SOBI.InvoiceDate, GETUTCDATE()) END AS 'DSI',        
			  --CASE WHEN SOBI.IsProforma = 1 THEN 0 ELSE CASE WHEN (ISNULL(CT.NetDays,0) - DATEDIFF(DAY, CAST(SOBI.InvoiceDate AS DATE), GETUTCDATE())) > 0 THEN (CT.NetDays - DATEDIFF(DAY, CAST(SOBI.InvoiceDate AS DATE), GETUTCDATE())) ELSE 0 END END AS 'DSO', 			  
			  CASE WHEN SOBI.IsProforma = 1 THEN 0 ELSE CASE WHEN (DATEDIFF(DAY, SOBI.InvoiceDate, GETUTCDATE()) - ISNULL(S.NetDays,0)) > 0 
			        THEN (DATEDIFF(DAY, SOBI.InvoiceDate, GETUTCDATE()) - ISNULL(S.NetDays,0))
					ELSE 0
			 		END END AS 'DSO', 	
			  CASE WHEN SOBI.IsProforma = 1 THEN NULL ELSE CASE WHEN ISNULL(SOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(S.[Days],0), (CAST(SOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(S.[Days],0), (CAST(SOBI.InvoiceDate AS DATETIME))) END END AS DiscountDate,      			 			 
			  CASE WHEN (S.NetDays - DATEDIFF(DAY, CASt(SOBI.InvoiceDate AS DATE), GETUTCDATE())) < 0 THEN SOBI.RemainingAmount ELSE 0.00 END AS 'AmountPastDue',        
			  CASE WHEN DATEDIFF(DAY, (CAST(SOBI.PostedDate AS DATETIME) + ISNULL(S.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(SOBI.PostedDate AS DATETIME) + ISNULL(S.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,      
			  CASE WHEN ISNULL(SOBI.IsProforma,0 ) = 0 THEN
					CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(SOBI.PostedDate AS DATETIME) + ISNULL(S.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((SOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END
					ELSE 0 END AS DiscountAvailable,      
			  C.CustomerId,      
			  C.[Name] AS 'CustName',      
			  C.CustomerCode,       
			  S.CustomerReference,         
			  GETUTCDATE() AS 'InvDueDate',        
			  ISNULL(CF.CreditLimit, 0) AS 'CreditLimit',       
			  S.CreditTermName,      
			  (Select COUNT(SOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems',         
			  MSD.LastMSLevel,      
			  MSD.AllMSlevels,      
			  1 AS InvoiceType,      
			  ISNULL(H.ARBalance,0) AS ARBalance,      
			  C.Ismiscellaneous,
			  0 AS 'ExchangeSalesOrderScheduleBillingId',
			  0 AS 'BillingId',
			  ISNULL(SOBI.IsProforma,0 ) AS 'isPerformaInvoice'
		FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)      
			  JOIN [dbo].[SalesOrder] S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId      
			  LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId      
			  LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId      
			  --LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON S.CreditTermId = CT.CreditTermsId AND CT.PercentId > 0        
			  LEFT JOIN [dbo].[Currency] Curr WITH (NOLOCK) ON SOBI.CurrencyId = Curr.CurrencyId      
			  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(S.PercentId AS INT) = p.PercentId 
	          INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId-- AND MSD.Level1Id = @legalEntityId 
			  INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID AND ML.LegalEntityId = @LegalEntityId
			  INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = S.MasterCompanyId
	          OUTER APPLY       
			  (       
				 SELECT TOP 1 ARBalance FROM [dbo].[CustomerCreditTermsHistory] cch WITH(NOLOCK)      
				 WHERE c.CustomerId = @customerId ORDER BY CustomerCreditTermsHistoryId DESC      
			  ) H      
		WHERE SOBI.InvoiceStatus = 'Invoiced'      
			  AND SOBI.CustomerId = @customerId 
			  AND SOBI.IsBilling = 0 AND SOBI.RemainingAmount > 0 
		GROUP BY SOBI.SalesOrderId,SOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceDate, S.Days, SOBI.PostedDate, S.SalesOrderNumber,      
			  S.CustomerReference, Curr.Code, SOBI.GrandTotal,SOBI.RemainingAmount, SOBI.InvoiceDate, S.BalanceDue, CF.CreditLimit, S.CreditTermName, p.[PercentValue],       
			  MSD.LastMSLevel,MSD.AllMSlevels,S.NetDays,ARBalance,C.Ismiscellaneous,SOBI.IsProforma--,SOBI.CreditMemoUsed      
      
		UNION ALL    
      
		SELECT WOBI.WorkOrderId AS 'Id',      
			 WOBI.BillingInvoicingId AS 'SOBillingInvoicingId',   
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 'Invoice' ELSE 'Invoice' END AS 'DocumentType',
			 WOBI.InvoiceNo AS 'DocNum',      
			 WOBI.InvoiceDate,      
			 WOBI.GrandTotal AS 'OriginalAmount',      
			 WOBI.RemainingAmount, -- + ISNULL(WOBI.CreditMemoUsed,0) AS 'RemainingAmount',      
			 0 AS 'PaymentAmount',       
			 0 AS 'DiscAmount',      
			 Curr.Code AS 'CurrencyCode',       
			 0 AS 'FxRate',      
			 WO.WorkOrderNum AS 'WOSONum',      
			 0 AS 'NewRemainingBal',      
			 'Open' AS 'Status',      
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 0 ELSE DATEDIFF(DAY, WOBI.InvoiceDate, GETUTCDATE()) END AS  'DSI',                    
			 --CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 0 ELSE CASE WHEN (CT.NetDays - DATEDIFF(DAY, CAST(WOBI.InvoiceDate AS DATE), GETUTCDATE())) > 0 THEN (CT.NetDays - DATEDIFF(DAY, CAST(WOBI.InvoiceDate AS DATE), GETUTCDATE())) ELSE 0 END END AS 'DSO',      
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 0 ELSE CASE WHEN (DATEDIFF(DAY, WOBI.InvoiceDate, GETUTCDATE()) - ISNULL(WO.NetDays,0)) > 0 
			      THEN (DATEDIFF(DAY, WOBI.InvoiceDate, GETUTCDATE()) - ISNULL(WO.NetDays,0))
				  ELSE 0
			  END END AS 'DSO', 	
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN NULL ELSE CASE WHEN ISNULL(WOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(WO.[Days],0), (CAST(WOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(WO.[Days],0), (CAST(WOBI.InvoiceDate AS DATETIME))) END END AS DiscountDate,      			 
			 CASE WHEN (WO.NetDays - DATEDIFF(DAY, CASt(WOBI.InvoiceDate AS DATE), GETUTCDATE())) < 0 THEN WOBI.RemainingAmount ELSE 0.00 END AS 'AmountPastDue',           
			 CASE WHEN DATEDIFF(DAY, (CAST(WOBI.PostedDate AS DATETIME) + ISNULL(WO.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(WOBI.PostedDate AS DATETIME) + ISNULL(WO.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,      
			 CASE WHEN ISNULL(WOBI.isPerformaInvoice,0 ) = 0 THEN
				  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(WOBI.PostedDate AS DATETIME) + ISNULL(WO.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((WOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END
				  ELSE 0 END AS DiscountAvailable,         
			 C.CustomerId,      
			 C.Name AS 'CustName',      
			 C.CustomerCode,       
			 '' as CustomerReference,      
			 GETUTCDATE() AS 'InvDueDate',       
			 ISNULL(CF.CreditLimit, 0) AS 'CreditLimit',      
			 WO.CreditTerms AS 'CreditTermName',      
			 (Select COUNT(WOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems',       
			 MSD.LastMSLevel,      
			 MSD.AllMSlevels,         
			 2 AS InvoiceType,      
			 ISNULL(H.ARBalance,0) AS ARBalance,      
			 C.Ismiscellaneous,
			 0 AS 'ExchangeSalesOrderScheduleBillingId',
			 0 AS 'BillingId',
			 ISNULL(WOBI.isPerformaInvoice,0 ) AS 'isPerformaInvoice'
			 FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK)      
			 INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.WorkOrderId  and WOBI.IsVersionIncrease = 0      
			 LEFT JOIN  [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on WOBI.BillingInvoicingId = wobii.BillingInvoicingId AND ISNULL(wobii.[IsInvoicePosted], 0) != 1
			 LEFT JOIN  [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId        
			 LEFT JOIN  [dbo].[Customer] C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId      
			 LEFT JOIN  [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON WOBI.CustomerId = CF.CustomerId      
			 --LEFT JOIN  [dbo].[CreditTerms] CT WITH (NOLOCK) ON WO.CreditTermId = CT.CreditTermsId AND CT.PercentId > 0      
			 LEFT JOIN  [dbo].[Currency] Curr WITH (NOLOCK) ON WOBI.CurrencyId = Curr.CurrencyId      
			 LEFT JOIN  [dbo].[Percent] p WITH(NOLOCK) ON CAST(WO.PercentId AS INT) = p.PercentId      
			 INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId  --AND MSD.Level1Id = @legalEntityId  
			 INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID AND ML.LegalEntityId = @LegalEntityId
			 INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = WO.MasterCompanyId
			 OUTER APPLY       
			 (       
					 SELECT TOP 1 ARBalance FROM [dbo].[CustomerCreditTermsHistory] cch WITH(NOLOCK)      
					 WHERE c.CustomerId = @customerId ORDER BY CustomerCreditTermsHistoryId DESC      
			 ) H      
		WHERE WOBI.InvoiceStatus = 'Invoiced' AND WOBI.CustomerId = @customerId AND WOBI.RemainingAmount > 0 
		AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1
		GROUP BY  WOBI.WorkOrderId,WOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceDate, WO.Days, WOBI.PostedDate, WO.WorkOrderNum,      
			 Curr.Code, WOBI.GrandTotal,WOBI.RemainingAmount, WOBI.InvoiceDate, p.[PercentValue],      --wop.CustomerReference,
			 CF.CreditLimit, WO.CreditTerms,MSD.LastMSLevel,MSD.AllMSlevels,WO.NetDays,ARBalance,C.Ismiscellaneous,WOBI.IsPerformaInvoice--,WOBI.CreditMemoUsed      
      
		UNION ALL    
    
		SELECT CM.CreditMemoHeaderId AS 'Id',    
		    CM.CreditMemoHeaderId AS 'SOBillingInvoicingId',    
		    CASE WHEN COUNT(SACMD.CreditMemoHeaderId) > 0 THEN 'Stand Alone Credit Memo' ELSE 'Credit Memo' END AS 'DocumentType',      
		    CM.CreditMemoNumber  AS 'DocNum',       
		    CM.InvoiceDate,       
		    CM.Amount AS 'OriginalAmount',    
		    0 AS'RemainingAmount',    
		    0 AS 'PaymentAmount',      
		    0 AS 'DiscAmount',      
		    CASE WHEN CM.IsWorkOrder = 1 THEN WCurr.Code ELSE SCurr.Code END AS 'CurrencyCode',       
		    0 AS 'FxRate',      
		    CM.InvoiceNumber AS 'WOSONum',      
		    0 AS 'NewRemainingBal',      
		    'Fulfilling' AS 'Status',    
		    0 AS 'DSI',                    
		    0 AS 'DSO',      
		    NULL AS DiscountDate,      
		    0.00 AS 'AmountPastDue',           
		    0 AS DaysPastDue,      
		    0 AS DiscountAvailable,      
		    C.CustomerId,      
		    C.Name AS 'CustName',      
		    C.CustomerCode,       
		    '' AS CustomerReference,    
		    GETUTCDATE() AS 'InvDueDate',     
		    0 AS 'CreditLimit',    
		    '' AS 'CreditTermName',    
		    (SELECT COUNT(CM.CreditMemoHeaderId) AS NumberOfItems) 'NumberOfItems',      
		    MSD.LastMSLevel,      
		    MSD.AllMSlevels,    
		    CASE WHEN COUNT(SACMD.CreditMemoHeaderId) > 0 THEN 4 ELSE 3 END AS InvoiceType,      
		    0 AS ARBalance,      
		    C.Ismiscellaneous,
			0 AS 'ExchangeSalesOrderScheduleBillingId',
			0 AS 'BillingId',
			0 AS 'isPerformaInvoice'
		FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CustomerRMAHeader] RM WITH (NOLOCK) ON CM.RMAHeaderId = RM.RMAHeaderId    
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId      
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId      
			LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON CMD.InvoiceId =  SOBI.SOBillingInvoicingId AND CMD.IsWorkOrder = 0  AND ISNULL(SOBI.IsProforma,0) = 0 
			LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON CMD.InvoiceId =  WOBI.BillingInvoicingId AND CMD.IsWorkOrder = 1    
			LEFT JOIN [dbo].[Currency] WCurr WITH (NOLOCK) ON WOBI.CurrencyId = WCurr.CurrencyId      
			LEFT JOIN [dbo].[Currency] SCurr WITH (NOLOCK) ON SOBI.CurrencyId = SCurr.CurrencyId      
		   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CreditMemoModuleId AND MSD.ReferenceID = CM.CreditMemoHeaderId  --AND MSD.Level1Id = @legalEntityId   
		   INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID AND ML.LegalEntityId = @LegalEntityId
		   INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = CM.MasterCompanyId
		WHERE CM.[CustomerId] = @customerId 
		AND CM.[StatusId] = @CMPostedStatusId
		AND ISNULL(CM.IsClosed,0) = 0
		GROUP BY CM.CreditMemoHeaderId,CM.InvoiceId,CM.InvoiceNumber,CM.InvoiceDate,CM.CreditMemoNumber,C.CustomerId,C.[Name],C.CustomerCode,CM.CreditMemoNumber,      
			MSD.LastMSLevel,MSD.AllMSlevels,C.Ismiscellaneous,CM.IsWorkOrder,WCurr.Code,SCurr.Code,CM.Amount   

	   UNION ALL  
		
		SELECT MJH.ManualJournalHeaderId AS 'Id',   
			   MJH.ManualJournalHeaderId AS 'SOBillingInvoicingId',      
			   'MANUAL JOURNAL' AS 'DocumentType',
			   UPPER(MJH.JournalNumber) AS 'DocNum', 
			   MJH.[PostedDate] AS InvoiceDate,  
			   SUM(ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)) AS 'OriginalAmount', 
			   0 AS 'RemainingAmount',    
		       0 AS 'PaymentAmount',      
		       0 AS 'DiscAmount',    
			   (CR.Code) AS  'CurrencyCode',
			   0 AS 'FxRate',      
		       UPPER(MJH.JournalNumber) AS 'WOSONum', 
			   0 AS 'NewRemainingBal', 
			   UPPER(MJS.Name) AS 'Status',   
			   0 AS 'DSI',                    
		       0 AS 'DSO',      
		       NULL AS DiscountDate,      
		       0.00 AS 'AmountPastDue',           
		       0 AS DaysPastDue,      
		       0 AS DiscountAvailable,      
		       CST.CustomerId,      
		       (CST.[Name]) AS 'CustName',      
		       (CST.[CustomerCode]) AS 'CustomerCode',       
		       '' AS CustomerReference,    
		       GETUTCDATE() AS 'InvDueDate',     
		       0 AS 'CreditLimit',    
		       '' AS 'CreditTermName',  
			   (SELECT COUNT(MJD.ManualJournalHeaderId) AS NumberOfItems) 'NumberOfItems',   
			   (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(MJD.ManagementStructureId)) AS LastMSLevel,      
			   (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(MJD.ManagementStructureId)) AS AllMSlevels,   
			   5 AS InvoiceType,      
		       0 AS ARBalance,      
		       CST.Ismiscellaneous,
			   0 AS 'ExchangeSalesOrderScheduleBillingId',
			   0 AS 'BillingId',
			   0 AS 'isPerformaInvoice'
	    FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.[ManualJournalHeaderId] = MJD.[ManualJournalHeaderId]		  
		  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.CustomerId = MJD.ReferenceId AND MJD.ReferenceTypeId = 1 
		   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.[CurrencyId] = MJH.[FunctionalCurrencyId]
		   LEFT JOIN [dbo].[ManualJournalStatus] MJS  ON MJS.[ManualJournalStatusId] = MJH.[ManualJournalStatusId]
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 
		  INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID AND ML.LegalEntityId = @LegalEntityId
		  INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = MJH.MasterCompanyId
		 WHERE MJD.ReferenceId = @customerId AND MJH.[ManualJournalStatusId] = @PostStatusId AND
		       ISNULL(MJD.IsClosed,0) = 0
		GROUP BY MJH.[ManualJournalHeaderId],MJH.[JournalNumber],MJH.[PostedDate],MJD.[Debit],MJD.[Credit],MJS.[Name],
		         MJD.[ManagementStructureId],CST.[CustomerId],CST.[Name],CST.[CustomerCode],CST.[Ismiscellaneous],CR.[Code]  

		UNION ALL

		SELECT ESOBI.ExchangeSalesOrderId AS 'Id',      
	          ESOBI.SOBillingInvoicingId AS 'SOBillingInvoicingId',       
		      'Invoice' AS 'DocumentType',      
			  ESOBI.InvoiceNo AS 'DocNum',       
			  ESOBI.InvoiceDate,       
			  ESOBI.GrandTotal AS 'OriginalAmount',       
			  ESOBI.RemainingAmount,    
			  0 AS 'PaymentAmount',      
			  0 AS 'DiscAmount',       
			  Curr.Code AS 'CurrencyCode',       
			  0 AS 'FxRate',       
			  ES.ExchangeSalesOrderNumber AS 'WOSONum',      
			  0 AS 'NewRemainingBal',      
			  'Open' AS 'Status',      
			  DATEDIFF(DAY, ESOBI.InvoiceDate, GETUTCDATE()) AS 'DSI',        
			 -- CASE WHEN (CT.NetDays - DATEDIFF(DAY, CASt(ESOBI.InvoiceDate AS DATE), GETUTCDATE())) > 0 THEN (CT.NetDays - DATEDIFF(DAY, CASt(ESOBI.InvoiceDate AS DATE), GETUTCDATE())) ELSE 0 END AS 'DSO', 
			  CASE WHEN (DATEDIFF(DAY, ESOBI.InvoiceDate, GETUTCDATE()) - ISNULL(ES.NetDays,0)) > 0 
			      THEN (DATEDIFF(DAY, ESOBI.InvoiceDate, GETUTCDATE()) - ISNULL(ES.NetDays,0))
				  ELSE 0
			  END AS 'DSO',
			  CASE WHEN ISNULL(ESOBI.PostedDate, '') != '' THEN CASE WHEN ISNULL(ES.[Days],0) > 0 THEN DATEADD(DAY, ISNULL(ES.[Days],0), (CAST(ESOBI.PostedDate AS DATETIME))) ELSE NULL END ELSE DATEADD(DAY, ISNULL(ES.[Days],0), (CAST(ESOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,   
			  CASE WHEN (ES.NetDays - DATEDIFF(DAY, CASt(ESOBI.InvoiceDate AS DATE), GETUTCDATE())) < 0 THEN ISNULL(ESOBI.RemainingAmount,0) ELSE 0.00 END AS 'AmountPastDue',        
			  CASE WHEN DATEDIFF(DAY, (CAST(ESOBI.PostedDate AS DATETIME) + ISNULL(ES.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(ESOBI.PostedDate AS DATETIME) + ISNULL(ES.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,      
			  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(ESOBI.PostedDate AS DATETIME) + ISNULL(ES.Days,0)), GETUTCDATE()), 0) <= 0 THEN CASE WHEN ISNULL(ES.NetDays,0) > 0 THEN CAST((ESOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END ELSE 0 END AS DiscountAvailable,
			  C.CustomerId,      
			  C.[Name] AS 'CustName',      
			  C.CustomerCode,       
			  ES.CustomerReference,         
			  GETUTCDATE() AS 'InvDueDate',        
			  ISNULL(CF.CreditLimit, 0) AS 'CreditLimit',       
			  ES.CreditTermName,      
			  (Select COUNT(ESOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems',         
			  MSD.LastMSLevel,      
			  MSD.AllMSlevels,      
			  6 AS InvoiceType,      
			  ISNULL(H.ARBalance,0) AS ARBalance,      
			  C.Ismiscellaneous,
			  ESOBI.ExchangeSalesOrderScheduleBillingId,
			  ESOBI.BillingId,
			  0 AS 'isPerformaInvoice'
		FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)      
			 INNER JOIN [dbo].[ExchangeSalesOrder] ES WITH (NOLOCK) ON ESOBI.ExchangeSalesOrderId = ES.ExchangeSalesOrderId      
			  LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON ESOBI.CustomerId = C.CustomerId      
			  LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON ESOBI.CustomerId = CF.CustomerId      
			  --LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON ES.CreditTermId = CT.CreditTermsId AND CT.PercentId > 0 
			  LEFT JOIN [dbo].[Currency] Curr WITH (NOLOCK) ON ESOBI.CurrencyId = Curr.CurrencyId      
			  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ES.[PercentId] AS INT) = p.PercentId 
	         INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ExSOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId
			 INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID AND ML.LegalEntityId = @LegalEntityId
			 INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = ES.MasterCompanyId
	          OUTER APPLY       
			  (       
				 SELECT TOP 1 ARBalance FROM [dbo].[CustomerCreditTermsHistory] cch WITH(NOLOCK)      
				 WHERE c.CustomerId = @customerId ORDER BY CustomerCreditTermsHistoryId DESC      
			  ) H      
		WHERE ESOBI.InvoiceStatus = 'Invoiced'     
			  AND ES.IsVendor = 0
			  AND ESOBI.CustomerId = @customerId AND ESOBI.RemainingAmount > 0     
		GROUP BY ESOBI.ExchangeSalesOrderId,ESOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, ESOBI.SOBillingInvoicingId, ESOBI.InvoiceNo, ESOBI.InvoiceDate, ES.Days, ESOBI.PostedDate, ES.ExchangeSalesOrderNumber,      
			  ES.CustomerReference, Curr.Code, ESOBI.GrandTotal,ESOBI.RemainingAmount, ESOBI.InvoiceDate, ES.BalanceDue, CF.CreditLimit, ES.CreditTermName, p.[PercentValue],       
			  MSD.LastMSLevel,MSD.AllMSlevels,ES.NetDays,ARBalance,C.Ismiscellaneous,ExchangeSalesOrderScheduleBillingId,BillingId   
    
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'SearchCustomerInvoicesByCustId'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@customerId AS VARCHAR(10)), '') + ''      
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName           = @DatabaseName      
                , @AdhocComments          = @AdhocComments                  , @ProcedureParameters = @ProcedureParameters      
                , @ApplicationName        =  @ApplicationName      
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
 END CATCH      
END