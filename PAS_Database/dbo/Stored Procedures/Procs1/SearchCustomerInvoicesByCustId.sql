/*************************************************************             
 ** File:   [SearchCustomerInvoicesByCustId]             
 ** Author:   Satish Gohil  
 ** Description: This stored procedure is used to display Expire Stockline List
 ** Purpose:           
 ** Date:   19/05/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			-------------------------------            
    1    19/05/2023   Satish Gohil		Show only legal entity releted invoice
	2    25/07/2023   Moin Bloch		Removed Credit Memo Used Amount from Remaining Amount
	3    18/09/2023   Hemant Saliya		Corrected Legal Entity Join
	4    03/10/2023   Moin Bloch		Added Stand Alone CreditMemo and Manual Journal Entry Details
	5    16/10/2023   Moin Bloch		Modify(Added Posted Status Insted of Fulfilling Credit Memo Status)
	6    10/11/2023   Amit Ghediya		Modify(Added Exchange Invoice)
	7    27/11/2023   Amit Ghediya		Modify(Exchange Invoice Disc Amount/Date)
	8    06/12/2023   Amit Ghediya		Modify(Exchange Invoice Disc Amount/Date)
	9    14/12/2023   Amit Ghediya		Modify(NetDays to Days for calculation)
	10   05/01/2024   Moin Bloch		Renamed CreditTerms.Percentage To PercentId
	11   02/1/2024	  AMIT GHEDIYA		Added isperforma Flage for SO
	12   08/02/2024	  Devendra Shekh	Added IsInvoicePosted flage for WO
	13   14/02/2024	  AMIT GHEDIYA		Added IsBilling flage for SO when standard invocie post proforma not available in Receipt information.
    14   14/02/2024	  Devendra Shekh	Duplicate wo for multiple MPN issue resolved
	15   20/02/2024	  AMIT GHEDIYA		Update Doc type name for performa for both SO & WO
	16   22/02/2024	  Devendra Shekh	Added isperforma to select
	17   08/03/2024   Moin Bloch		Modify(makes DSO 0 when it goes negaitive)
	18   13/03/2024   Moin Bloch		Modify(makes Exchange Invoice to Invoice)
	19   15/03/2024   Moin Bloch		Modify(Changed DSO Logic)
	20   19/03/2024   Bhargav Saliya	Get Days And NetDays From WO,SO and ESO Table instead of CreditTerms Table
	21   13/03/2024   Moin Bloch		Modify(makes Performa Invoice to Invoice)
	22   19/04/2024   Moin Bloch		Modify(CM Status Issue)
	23   21/06/2024   Hemant Saliya		Added Un Applied Cash to utilize in Cash Receipt.
	24	 11-Oct-2024  Bhargav Saliya	Get Module status 
	25   11/05/2024	  AMIT GHEDIYA		Update condition.
	26   19-Mar-2025  Divyesh Kathiriya	Update InvoiceDate based on Employee time zone
	27   27/06/2025   Moin Bloch		Modify(Changed To New Table)
	28   07/07/2025   Rajesh Gami		FIXED: If Standard invoice posted then no need to display proformainvoice 
	29 	 01-Apr-2026  Rajesh Gami		UOM Conversion Changes [PN-15866]
EXEC  [dbo].[SearchCustomerInvoicesByCustId] 90,1,226 
**************************************************************/ 

CREATE     PROCEDURE [dbo].[SearchCustomerInvoicesByCustId]      
@customerId BIGINT = NULL,
@legalEntityId BIGINT = 0,
@EmployeeId BIGINT
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
	 DECLARE @CustomerCreditPaymentOpenStatus INT = 1; -- For Un Applied Cash
	 DECLARE @SuspenseModuleID BIGINT;
	 
	 DECLARE @CMPostedStatusId INT
	 SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

	 SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	 SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
	 SELECT @SuspenseModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='SUSPENSEANDUNAPPLIEDPAYMENT';
    
	 DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
			
		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	SELECT *
FROM (
		SELECT SOBI.ReferenceId AS 'Id',      
	           SOBI.BillingInvoicingId AS 'SOBillingInvoicingId',       		     
			   CASE WHEN SOBI.IsPerformaInvoice = 1 THEN 'Proforma Invoice' ELSE 'Invoice' END  AS 'DocumentType',    
			   SOBI.InvoiceNo AS 'DocNum',       			  
			   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				   CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
			   SOBI.GrandTotal AS 'OriginalAmount',       
			   SOBI.RemainingAmount,     
			   0 AS 'PaymentAmount',      
			   0 AS 'DiscAmount',       
			   Curr.Code AS 'CurrencyCode',       
			   0 AS 'FxRate',       
			   S.SalesOrderNumber AS 'WOSONum',      
			   0 AS 'NewRemainingBal',      
			   msq.[Name] AS 'Status',      
			   CASE WHEN SOBI.IsPerformaInvoice = 1 THEN 0 ELSE DATEDIFF(DAY, SOBI.InvoiceDate, GETUTCDATE()) END AS 'DSI',        
			   CASE WHEN SOBI.IsPerformaInvoice = 1 THEN 0 ELSE CASE WHEN (DATEDIFF(DAY, SOBI.InvoiceDate, GETUTCDATE()) - ISNULL(S.NetDays,0)) > 0 
			        THEN (DATEDIFF(DAY, SOBI.InvoiceDate, GETUTCDATE()) - ISNULL(S.NetDays,0))
					ELSE 0
			 		END END AS 'DSO', 	
			   CASE WHEN SOBI.IsPerformaInvoice = 1 THEN NULL ELSE CASE WHEN ISNULL(SOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(S.[Days],0), (CAST(SOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(S.[Days],0), (CAST(SOBI.InvoiceDate AS DATETIME))) END END AS DiscountDate,      			 			 
			   CASE WHEN (S.NetDays - DATEDIFF(DAY, CASt(SOBI.InvoiceDate AS DATE), GETUTCDATE())) < 0 THEN SOBI.RemainingAmount ELSE 0.00 END AS 'AmountPastDue',        
			   CASE WHEN DATEDIFF(DAY, (CAST(SOBI.PostedDate AS DATETIME) + ISNULL(S.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(SOBI.PostedDate AS DATETIME) + ISNULL(S.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,      
			   CASE WHEN ISNULL(SOBI.IsPerformaInvoice,0 ) = 0 THEN
					CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(SOBI.PostedDate AS DATETIME) + ISNULL(S.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((SOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS [decimal](18,6)) ELSE 0 END
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
			   ISNULL(SOBI.IsPerformaInvoice,0 ) AS 'isPerformaInvoice'
		 FROM [dbo].[BillingInvoicing] SOBI WITH (NOLOCK)      
			  JOIN [dbo].[SalesOrder] S WITH (NOLOCK) ON SOBI.ReferenceId = S.SalesOrderId      
			  LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId      
			  LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId      
			  LEFT JOIN [dbo].[Currency] Curr WITH (NOLOCK) ON SOBI.CurrencyId = Curr.CurrencyId      
			  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(S.PercentId AS INT) = p.PercentId 
			  INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] msq WITH(NOLOCK) ON S.StatusId = msq.Id
	          INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.ReferenceId-- AND MSD.Level1Id = @legalEntityId 
			  INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID --AND ML.LegalEntityId = @LegalEntityId
			  INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = S.MasterCompanyId
	          OUTER APPLY       
			  (       
				 SELECT TOP 1 ARBalance FROM [dbo].[CustomerCreditTermsHistory] cch WITH(NOLOCK)      
				 WHERE c.CustomerId = @customerId ORDER BY CustomerCreditTermsHistoryId DESC      
			  ) H      
		WHERE SOBI.InvoiceStatus = 'Invoiced'      
			  AND SOBI.CustomerId = @customerId 
			  --AND ISNULL(SOBI.[IsBilling], 0) != 1  -- Need TO Discuss
			  AND SOBI.RemainingAmount > 0 
			  AND SOBI.ModuleId = @SOModuleId 
			  AND ISNULL(SOBI.IsStandardInvoicePosted,0)= 0
		GROUP BY SOBI.ReferenceId,SOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, SOBI.BillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceDate, S.Days, SOBI.PostedDate, S.SalesOrderNumber,      
			  S.CustomerReference, Curr.Code, SOBI.GrandTotal,SOBI.RemainingAmount, SOBI.InvoiceDate, S.BalanceDue, CF.CreditLimit, S.CreditTermName, p.[PercentValue],       
			  MSD.LastMSLevel,MSD.AllMSlevels,S.NetDays,ARBalance,C.Ismiscellaneous,SOBI.IsPerformaInvoice,msq.[Name]--,SOBI.CreditMemoUsed      
      
		UNION ALL    
      
		SELECT WOBI.ReferenceId AS 'Id',      
			 WOBI.BillingInvoicingId AS 'SOBillingInvoicingId',   			
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 'Proforma Invoice' ELSE 'Invoice' END AS 'DocumentType',
			 WOBI.InvoiceNo AS 'DocNum',      			
			 CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				  CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			 ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
			 WOBI.GrandTotal AS 'OriginalAmount',      
			 WOBI.RemainingAmount,   
			 0 AS 'PaymentAmount',       
			 0 AS 'DiscAmount',      
			 Curr.Code AS 'CurrencyCode',       
			 0 AS 'FxRate',      
			 WO.WorkOrderNum AS 'WOSONum',      
			 0 AS 'NewRemainingBal',      
			 WOS.[Description] AS 'Status',      
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 0 ELSE DATEDIFF(DAY, WOBI.InvoiceDate, GETUTCDATE()) END AS  'DSI',                    
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN 0 ELSE CASE WHEN (DATEDIFF(DAY, WOBI.InvoiceDate, GETUTCDATE()) - ISNULL(WO.NetDays,0)) > 0 
			      THEN (DATEDIFF(DAY, WOBI.InvoiceDate, GETUTCDATE()) - ISNULL(WO.NetDays,0))
				  ELSE 0
			  END END AS 'DSO', 	
			 CASE WHEN WOBI.IsPerformaInvoice = 1 THEN NULL ELSE CASE WHEN ISNULL(WOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(WO.[Days],0), (CAST(WOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(WO.[Days],0), (CAST(WOBI.InvoiceDate AS DATETIME))) END END AS DiscountDate,      			 
			 CASE WHEN (WO.NetDays - DATEDIFF(DAY, CASt(WOBI.InvoiceDate AS DATE), GETUTCDATE())) < 0 THEN WOBI.RemainingAmount ELSE 0.00 END AS 'AmountPastDue',           
			 CASE WHEN DATEDIFF(DAY, (CAST(WOBI.PostedDate AS DATETIME) + ISNULL(WO.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(WOBI.PostedDate AS DATETIME) + ISNULL(WO.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,      
			 CASE WHEN ISNULL(WOBI.isPerformaInvoice,0 ) = 0 THEN
				  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(WOBI.PostedDate AS DATETIME) + ISNULL(WO.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((WOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS [decimal](18,6)) ELSE 0 END
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
			 FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK)      
			 INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.ReferenceId AND ISNULL(WOBI.IsVersionIncrease,0) = 0 --AND ISNULL(wobi.[IsInvoicePosted], 0) != 1    
			 LEFT JOIN  [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) on WOBI.BillingInvoicingId = wobii.BillingInvoicingId --AND ISNULL(wobii.[IsInvoicePosted], 0) != 1
			 LEFT JOIN  [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) on wop.ID = wobii.SubReferenceId        
			 LEFT JOIN  [dbo].[Customer] C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId      
			 LEFT JOIN  [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON WOBI.CustomerId = CF.CustomerId      
			 LEFT JOIN  [dbo].[Currency] Curr WITH (NOLOCK) ON WOBI.CurrencyId = Curr.CurrencyId      
			 LEFT JOIN  [dbo].[Percent] p WITH(NOLOCK) ON CAST(WO.PercentId AS INT) = p.PercentId   
			 LEFT JOIN  [dbo].[WorkOrderStatus] WOS WITH(NOLOCK) ON WOS.Id = wop.WorkOrderStatusId
			 INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.SubReferenceId  --AND MSD.Level1Id = @legalEntityId  
			 INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID --AND ML.LegalEntityId = @LegalEntityId
			 INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = WO.MasterCompanyId
			 OUTER APPLY       
			 (       
					 SELECT TOP 1 ARBalance FROM [dbo].[CustomerCreditTermsHistory] cch WITH(NOLOCK)      
					 WHERE c.CustomerId = @customerId ORDER BY CustomerCreditTermsHistoryId DESC      
			 ) H      
		WHERE WOBI.InvoiceStatus = 'Invoiced' 
		AND WOBI.CustomerId = @customerId 
		AND WOBI.RemainingAmount > 0 
		--AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1  -- Need TO Discuss
		  AND ISNULL(WOBI.IsStandardInvoicePosted,0)= 0
		AND WOBI.ModuleId = @WOModuleId 
		GROUP BY  WOBI.ReferenceId,WOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceDate, WO.Days, WOBI.PostedDate, WO.WorkOrderNum,      
			 Curr.Code, WOBI.GrandTotal,WOBI.RemainingAmount, WOBI.InvoiceDate, p.[PercentValue],      --wop.CustomerReference,
			 CF.CreditLimit, WO.CreditTerms,MSD.LastMSLevel,MSD.AllMSlevels,WO.NetDays,ARBalance,C.Ismiscellaneous,WOBI.IsPerformaInvoice,WOS.[Description]--,WOBI.CreditMemoUsed      
      
		UNION ALL    
    
		SELECT CM.CreditMemoHeaderId AS 'Id',    
		    CM.CreditMemoHeaderId AS 'SOBillingInvoicingId',    
		    CASE WHEN COUNT(SACMD.CreditMemoHeaderId) > 0 THEN 'Stand Alone Credit Memo' ELSE 'Credit Memo' END AS 'DocumentType',      
		    CM.CreditMemoNumber  AS 'DocNum',       		   
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(CM.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CM.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(CM.InvoiceDate AS DATETIME)) END InvoiceDate,
		    CM.Amount AS 'OriginalAmount',    
		    0 AS'RemainingAmount',    
		    0 AS 'PaymentAmount',      
		    0 AS 'DiscAmount',      
		    CASE WHEN CM.IsWorkOrder = 1 THEN WCurr.Code ELSE SCurr.Code END AS 'CurrencyCode',       
		    0 AS 'FxRate',      
		    CM.InvoiceNumber AS 'WOSONum',      
		    0 AS 'NewRemainingBal',      
		    CMS.[Name] AS 'Status',    
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
			LEFT JOIN [dbo].[CreditMemoStatus] CMS WITH(NOLOCK) ON CM.[StatusId] = CMS.Id    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId      
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId      
			LEFT JOIN [dbo].[BillingInvoicing] SOBI WITH (NOLOCK) ON CMD.InvoiceId =  SOBI.BillingInvoicingId AND CMD.IsWorkOrder = 0  AND SOBI.ModuleId = @SOModuleId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 
			LEFT JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON CMD.InvoiceId =  WOBI.BillingInvoicingId AND CMD.IsWorkOrder = 1  AND WOBI.ModuleId = @WOModuleId    
			LEFT JOIN [dbo].[Currency] WCurr WITH (NOLOCK) ON WOBI.CurrencyId = WCurr.CurrencyId      
			LEFT JOIN [dbo].[Currency] SCurr WITH (NOLOCK) ON SOBI.CurrencyId = SCurr.CurrencyId      
		   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CreditMemoModuleId AND MSD.ReferenceID = CM.CreditMemoHeaderId  --AND MSD.Level1Id = @legalEntityId   
		   INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID --AND ML.LegalEntityId = @LegalEntityId
		   INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = CM.MasterCompanyId
		WHERE CM.[CustomerId] = @customerId 
		AND CM.[StatusId] = @CMPostedStatusId
		AND ISNULL(CM.IsClosed,0) = 0
		GROUP BY CM.CreditMemoHeaderId,CM.InvoiceId,CM.InvoiceNumber,CM.InvoiceDate,CM.CreditMemoNumber,C.CustomerId,C.[Name],C.CustomerCode,CM.CreditMemoNumber,      
			MSD.LastMSLevel,MSD.AllMSlevels,C.Ismiscellaneous,CM.IsWorkOrder,WCurr.Code,SCurr.Code,CM.Amount,CMS.[Name] 
			
		UNION ALL    
    
		SELECT CCP.CustomerCreditPaymentDetailId AS 'Id',   
		    CCP.CustomerCreditPaymentDetailId AS 'SOBillingInvoicingId',    
		    'Unapplied Cash' AS 'DocumentType',      
		    CCP.SuspenseUnappliedNumber  AS 'DocNum',       		    
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(CCP.ReceiveDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CCP.ReceiveDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(CCP.ReceiveDate AS DATETIME)) END InvoiceDate,
		    CCP.RemainingAmount AS 'OriginalAmount',    
		    0 AS'RemainingAmount',    
		    0 AS 'PaymentAmount',      
		    0 AS 'DiscAmount',      
		    Curr.Code AS 'CurrencyCode',       
		    0 AS 'FxRate',      
		    CCP.SuspenseUnappliedNumber AS 'WOSONum',      
		    0 AS 'NewRemainingBal',
			CASE WHEN ISNULL(CCP.StatusId, 0) = 1 THEN 'Open' WHEN ISNULL(CCP.StatusId, 0) = 2 THEN 'Closed' WHEN ISNULL(CCP.StatusId, 0) = 3 THEN 'Processed' END AS 'Status',    
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
		    (SELECT COUNT(CCP.CustomerCreditPaymentDetailId) AS NumberOfItems) 'NumberOfItems',      
		    MSD.LastMSLevel,      
		    MSD.AllMSlevels,    
		    7 AS InvoiceType,      
		    0 AS ARBalance,      
		    C.Ismiscellaneous,
			0 AS 'ExchangeSalesOrderScheduleBillingId',
			0 AS 'BillingId',
			0 AS 'isPerformaInvoice'
		FROM [dbo].[CustomerCreditPaymentDetail] CCP WITH (NOLOCK)   
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CCP.CustomerId = C.CustomerId      
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CCP.CustomerId = CF.CustomerId      
			LEFT JOIN [dbo].[Currency] Curr WITH (NOLOCK) ON CF.CurrencyId = Curr.CurrencyId     
			INNER JOIN [dbo].[SuspenseAndUnAppliedPaymentMSDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SuspenseModuleID AND MSD.ReferenceID = CCP.CustomerCreditPaymentDetailId
		    INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID --AND ML.LegalEntityId = @LegalEntityId
		    INNER JOIN [dbo].[ManagementStructureType] MST WITH(NOLOCK) ON MST.TypeID = ML.TypeID AND MST.SequenceNo = @Level1SequenceNo AND MST.MasterCompanyId = CCP.MasterCompanyId
		WHERE CCP.[CustomerId] = @customerId AND ISNULL(CCP.IsMiscellaneous, 0) = 0
			AND CCP.[StatusId] = @CustomerCreditPaymentOpenStatus	
			AND ISNULL(CCP.IsProcessed, 0) = 0 AND ISNULL(CCP.IsActive, 0) = 1 AND ISNULL(CCP.IsDeleted, 0) = 0
		GROUP BY CCP.CustomerCreditPaymentDetailId,CCP.SuspenseUnappliedNumber,CCP.ReceiveDate,C.CustomerId,C.[Name],C.CustomerCode,      
			MSD.LastMSLevel,MSD.AllMSlevels,C.Ismiscellaneous,Curr.Code,CCP.RemainingAmount, CCP.StatusId

	   UNION ALL  
		
		SELECT MJH.ManualJournalHeaderId AS 'Id',   
			   MJH.ManualJournalHeaderId AS 'SOBillingInvoicingId',      
			   'MANUAL JOURNAL' AS 'DocumentType',
			   UPPER(MJH.JournalNumber) AS 'DocNum', 			   
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(MJH.[PostedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(MJH.[PostedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(MJH.[PostedDate] AS DATETIME)) END InvoiceDate,
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
			LEFT JOIN [dbo].[ManualJournalStatus] MJS WITH (NOLOCK) ON MJS.[ManualJournalStatusId] = MJH.[ManualJournalStatusId]
			INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @MSModuleId AND MSD.ReferenceID = MJD.[ManualJournalDetailsId]
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID 
			INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID --AND ML.LegalEntityId = @LegalEntityId
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
			  CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				   CASE WHEN CAST(ESOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ESOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			  ELSE (CAST(ESOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
			  ESOBI.GrandTotal AS 'OriginalAmount',       
			  ESOBI.RemainingAmount,    
			  0 AS 'PaymentAmount',      
			  0 AS 'DiscAmount',       
			  Curr.Code AS 'CurrencyCode',       
			  0 AS 'FxRate',       
			  ES.ExchangeSalesOrderNumber AS 'WOSONum',      
			  0 AS 'NewRemainingBal',      
			  EST.[Name] AS 'Status',      
			  DATEDIFF(DAY, ESOBI.InvoiceDate, GETUTCDATE()) AS 'DSI',        
			  CASE WHEN (DATEDIFF(DAY, ESOBI.InvoiceDate, GETUTCDATE()) - ISNULL(ES.NetDays,0)) > 0 
			      THEN (DATEDIFF(DAY, ESOBI.InvoiceDate, GETUTCDATE()) - ISNULL(ES.NetDays,0))
				  ELSE 0
			  END AS 'DSO',
			  CASE WHEN ISNULL(ESOBI.PostedDate, '') != '' THEN CASE WHEN ISNULL(ES.[Days],0) > 0 THEN DATEADD(DAY, ISNULL(ES.[Days],0), (CAST(ESOBI.PostedDate AS DATETIME))) ELSE NULL END ELSE DATEADD(DAY, ISNULL(ES.[Days],0), (CAST(ESOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,   
			  CASE WHEN (ES.NetDays - DATEDIFF(DAY, CASt(ESOBI.InvoiceDate AS DATE), GETUTCDATE())) < 0 THEN ISNULL(ESOBI.RemainingAmount,0) ELSE 0.00 END AS 'AmountPastDue',        
			  CASE WHEN DATEDIFF(DAY, (CAST(ESOBI.PostedDate AS DATETIME) + ISNULL(ES.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(ESOBI.PostedDate AS DATETIME) + ISNULL(ES.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,      
			  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(ESOBI.PostedDate AS DATETIME) + ISNULL(ES.Days,0)), GETUTCDATE()), 0) <= 0 THEN CASE WHEN ISNULL(ES.NetDays,0) > 0 THEN CAST((ESOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS [decimal](18,6)) ELSE 0 END ELSE 0 END AS DiscountAvailable,
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
			LEFT JOIN [dbo].[Currency] Curr WITH (NOLOCK) ON ESOBI.CurrencyId = Curr.CurrencyId      
			LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ES.[PercentId] AS INT) = p.PercentId 
			INNER JOIN [dbo].[ExchangeStatus] EST WITH (NOLOCK) on ES.StatusId = EST.ExchangeStatusId
	        INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ExSOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId
			INNER JOIN [dbo].[ManagementStructureLevel] ML WITH(NOLOCK) ON MSD.Level1Id = ML.ID --AND ML.LegalEntityId = @LegalEntityId
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
			  MSD.LastMSLevel,MSD.AllMSlevels,ES.NetDays,ARBalance,C.Ismiscellaneous,ExchangeSalesOrderScheduleBillingId,BillingId,EST.[Name] 
			  ) AS FinalResult ORDER BY InvoiceDate DESC;
    
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