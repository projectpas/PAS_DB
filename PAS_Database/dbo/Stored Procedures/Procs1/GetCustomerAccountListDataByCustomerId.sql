﻿/*************************************************************                   
 ** File:   [GetCustomerAccountListDataByCustomerId]                   
 ** Author:  unknown   
 ** Description: Get Data For Customer Account List
 ** Purpose:                 
 ** Date:     
 ** PARAMETERS:         
 ** RETURN VALUE:       
 *************************************************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------   
	1                      unknown         Created            
	2    20-SEP-2023       Moin Bloch      Modified (changed  InvoiceDate insted of PostedDate and Formated The SP)
	3    25-SEP-2023       Moin Bloch      Modified (Added Manual JE Amount)
	4    16-OCT-2023       Moin Bloch      Modify(Added Posted Status Insted of Fulfilling Credit Memo Status)
	5    17-OCT-2023       Moin Bloch      Modify(Added Stand Alone Credit Memo)
	6	 01/31/2024		   Devendra Shekh  added isperforma Flage for WO
	7	 01/02/2024	       AMIT GHEDIYA	   added isperforma Flage for SO
	8	 19/02/2024		   Devendra Shekh  removed isperforma Flage and added isinvoiceposted for WO
	9	 27/02/2024		   AMIT GHEDIYA    removed isperforma Flage and added IsBilling for SO
	10	 27/02/2024		   Devendra Shekh  changes for proforma invoice calculation
	11	 28/02/2024	       Devendra Shekh  changes for amount calculation based on isproforma for wo and so

***************************************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetCustomerAccountListDataByCustomerId]
@CustomerId BIGINT = NULL,
@StartDate DATETIME = NULL,
@EndDate DATETIME = NULL,
@OpenTransactionsOnly BIT = false,
@IncludeCredits BIT = false,
@SiteId BIGINT = NULL,
@LegalEntityId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY
		DECLARE @SOMSModuleID INT = 17;
		DECLARE @WOMSModuleID INT = 12;
	    DECLARE @CreditMemoMSModuleID INT = 61
		DECLARE @PostStatusId INT;
	    SELECT @PostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';
		DECLARE @CMPostedStatusId INT
        SELECT @CMPostedStatusId = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
		
		IF(@OpenTransactionsOnly = 1)
		BEGIN 
		 ;WITH CTEData AS(
			SELECT ct.CustomerId,
			       CAST(sobi.InvoiceDate AS DATE) AS InvoiceDate,
				   CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN sobi.GrandTotal ELSE 0 END AS GrandTotal,  
				   CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN sobi.RemainingAmount ELSE (0 - (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0))) END AS RemainingAmount,
				   DATEDIFF(DAY, CAST(sobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
				   ctm.NetDays,
				   DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) AS CreditRemainingDays,
				   CAST(sobi.PostedDate AS DATE) AS PostedDate,
				   ISNULL(sobi.IsProforma, 0) as IsProformaInvoice
			FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)
				INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
				INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
				 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
				INNER JOIN [dbo].[SalesOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
				INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			WHERE sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' AND ISNULL(sobi.IsBilling, 0) = 0 AND
				 CAST(sobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) 
				AND sobi.BillToSiteId = @SiteId AND le.LegalEntityId = @LegalEntityId
			GROUP BY sobi.InvoiceDate,ct.CustomerId,sobi.GrandTotal,sobi.RemainingAmount,ctm.NetDays,sobi.PostedDate,ctm.Code,sobi.IsProforma
			
			UNION ALL
			
			SELECT ct.CustomerId,
			       CAST(wobi.InvoiceDate AS DATE) AS InvoiceDate,
				   CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN wobi.GrandTotal ELSE 0 END AS GrandTotal,  
				   CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN wobi.RemainingAmount ELSE (0 - (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) END AS RemainingAmount,
				DATEDIFF(DAY, CAST(wobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
				ctm.NetDays,
				DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) AS CreditRemainingDays,
				CAST(wobi.PostedDate AS DATE) AS PostedDate,
				ISNULL(wobi.IsPerformaInvoice, 0) AS IsProformaInvoice
			FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wobi.WorkOrderId
				INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
				INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
				INNER JOIN [dbo].[WorkOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
				INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			WHERE wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' AND 
			    wobi.IsVersionIncrease = 0 AND ISNULL(wobi.IsInvoicePosted, 0) = 0
				AND CAST(wobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) 
				AND wobi.SoldToSiteId = @SiteId AND le.LegalEntityId = @LegalEntityId
				AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) 
				OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 ))
			GROUP BY wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,wobi.PostedDate,ctm.Code,wobi.IsPerformaInvoice
			
			), CTECalculation AS(
			SELECT
				CustomerId,
					SUM (CASE WHEN IsProformaInvoice = 1 THEN RemainingAmount
								ELSE (CASE WHEN CreditRemainingDays < 0 THEN RemainingAmount ELSE 0 END) END)AS paidbylessthen0days,
					SUM (CASE WHEN IsProformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 0 AND CreditRemainingDays <= 30 THEN RemainingAmount ELSE 0 END) END) AS paidby30days,
					SUM (CASE WHEN IsProformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 30 AND CreditRemainingDays <= 60 THEN RemainingAmount ELSE 0 END) END) AS paidby60days,
					SUM (CASE WHEN IsProformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 60 AND CreditRemainingDays <= 90 THEN RemainingAmount ELSE 0 END) END) AS paidby90days,
					SUM (CASE WHEN IsProformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 90 AND CreditRemainingDays <= 120 THEN RemainingAmount ELSE 0 END) END) AS paidby120days,
					SUM (CASE WHEN IsProformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 120 THEN RemainingAmount ELSE 0 END) END) AS paidbymorethan120days
			    FROM CTEData c GROUP BY CustomerId
			),CTE AS(
					SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(wobi.GrandTotal) AS 'BalanceAmount',
					   SUM(wobi.GrandTotal - wobi.RemainingAmount) AS 'CurrentlAmount',             
					   SUM(CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE (0 - ((wobi.GrandTotal - wobi.RemainingAmount))) END) AS 'PaymentAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   Max('') AS 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(wop.ManagementStructureId) AS ManagementStructureId,
					   STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference',
						0 AS CM
			   FROM [dbo].Customer C WITH (NOLOCK) 
				   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
				   INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
				   INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkOrderId = WO.WorkOrderId AND ISNULL(wobi.IsInvoicePosted, 0) = 0
		 		   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
				   INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ReferenceID = wop.ID AND MSD.ModuleID = @WOMSModuleID
				   INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
				   INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			  WHERE wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' AND 
			  c.CustomerId = @CustomerId 
			  AND wobi.SoldToSiteId = @SiteId AND le.LegalEntityId = @LegalEntityId 
			  AND CAST(wobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)	
			  GROUP BY C.CustomerId,wop.CustomerReference,wobi.BillingInvoicingId,wobi.IsPerformaInvoice
		
			UNION ALL

				SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(sobi.GrandTotal) AS 'BalanceAmount',
					   SUM(sobi.GrandTotal - sobi.RemainingAmount) AS 'CurrentlAmount',   
					   SUM(CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE (0 - ((sobi.GrandTotal - sobi.RemainingAmount))) END) AS 'PaymentAmount',
					   --SUM(sobi.RemainingAmount) AS 'PaymentAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   Max('') AS 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(SO.ManagementStructureId) AS ManagementStructureId,
					   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference',
						    0 AS CM
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
				   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId AND ISNULL(sobi.IsBilling, 0) = 0
				   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
				   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ReferenceID = so.SalesOrderId AND MSD.ModuleID = @SOMSModuleID
				   INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
				   INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
		 	  WHERE sobi.InvoiceStatus='Invoiced' AND sobi.RemainingAmount > 0 AND 
			  c.CustomerId=@CustomerId
			  AND sobi.BillToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId 
			  AND CAST(sobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) and CAST(@EndDate AS DATE)	
			  GROUP BY C.CustomerId,SO.CustomerReference,sobi.SOBillingInvoicingId
			)

		   ,Creditmemo AS(
				SELECT CGL.CustomerId AS CustomerId, 
				(ISNULL(SUM(CGL.CreditAmount),0)) AS 'CreditMemoAmount'
				FROM dbo.CustomerGeneralLedger CGL  WITH (NOLOCK) 
					INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CGL.ReferenceId 
			   WHERE CGL.ModuleId = @CreditMemoMSModuleID 
			     AND CAST(CGL.CreatedDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
			     AND CGL.CustomerId = @CustomerId
				 AND CM.StatusId = @CMPostedStatusId
			   GROUP BY CGL.CustomerId			
			)

			,StandaloneCreditMemo  AS (
				SELECT CM.CustomerId AS CustomerId, 
				(ISNULL(SUM(CM.Amount),0)) AS 'CreditMemoAmount'
				FROM [dbo].[StandAloneCreditMemoDetails] CGL  WITH (NOLOCK) 
					INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CGL.CreditMemoHeaderId 
			   WHERE CAST(CM.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
			     AND CM.CustomerId = @CustomerId
				 AND CM.StatusId = @CMPostedStatusId
				 AND CM.IsStandAloneCM = 1  				 
			   GROUP BY CM.CustomerId			
			)
			
			,ManualJE AS (			 
			  SELECT MJD.ReferenceId AS CustomerId,
				     ISNULL(SUM(ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)),0) AS 'ManualJEAmount' 	
		     FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
				  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
				   WHERE MJD.[ReferenceId] = @CustomerId AND MJD.[ReferenceTypeId] = 1
				AND MJH.[ManualJournalStatusId] = @PostStatusId
			    AND CAST(MJH.[PostedDate] AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) 
				GROUP BY MJD.ReferenceId

			), Result AS(
				SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CTE.currencyCode) AS  'currencyCode',
					   (ISNULL(MAX(Creditmemo.CreditMemoAmount),0)) + (ISNULL(MAX(SCM.CreditMemoAmount),0))  AS 'CreditMemoAmount',
					   --(ISNULL(MAX(Creditmemo.CreditMemoAmount * -1),0)) AS 'CreditMemoAmount',
					   (ISNULL(MAX(ManualJE.ManualJEAmount),0)) AS 'ManualJEAmount',
					   (ISNULL(SUM(CTE.PaymentAmount),0) - (ISNULL(MAX(Creditmemo.CreditMemoAmount),0)) + (ISNULL(MAX(SCM.CreditMemoAmount),0)) + (ISNULL(MAX(ManualJE.ManualJEAmount),0))) AS 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.PaymentAmount),0) AS 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.PaymentAmount),0) AS 'PaymentAmount',
					   MAX(CTECalculation.paidbylessthen0days) AS 'Amountpaidbylessthen0days',      
					   MAX(CTECalculation.paidby30days) AS 'Amountpaidby30days',      
                       MAX(CTECalculation.paidby60days) AS 'Amountpaidby60days',
					   MAX(CTECalculation.paidby90days) AS 'Amountpaidby90days',
					   MAX(CTECalculation.paidby120days) AS 'Amountpaidby120days',
					   MAX(CTECalculation.paidbymorethan120days) AS 'Amountpaidbymorethan120days',  
					   Max('') AS 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(CTE.ManagementStructureId) AS ManagementStructureId
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
				   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				   INNER JOIN CTE AS CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
				   INNER JOIN CTECalculation AS CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId
				    LEFT JOIN Creditmemo AS Creditmemo WITH (NOLOCK) ON Creditmemo.CustomerId = C.CustomerId 
					LEFT JOIN StandaloneCreditMemo AS SCM WITH (NOLOCK) ON SCM.CustomerId = C.CustomerId 					
					LEFT JOIN ManualJE AS ManualJE WITH (NOLOCK) ON ManualJE.CustomerId = C.CustomerId 
					
			   WHERE c.CustomerId = @CustomerId 
			   GROUP BY C.CustomerId
			), ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)

			SELECT * INTO #TempResult FROM Result

			SELECT * FROM #TempResult;

         END
		 ELSE
		 BEGIN 
			;WITH CTEData AS(
				SELECT ct.CustomerId,
						CAST(sobi.InvoiceDate AS DATE) AS InvoiceDate,
						sobi.GrandTotal,
						(sobi.RemainingAmount) AS RemainingAmount,
						DATEDIFF(DAY, CAST(sobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
						ctm.NetDays,
						DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																			WHEN ctm.Code='CIA' THEN -1
																			WHEN ctm.Code='CreditCard' THEN -1
																			WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) AS CreditRemainingDays,
						 ISNULL(sobi.IsProforma, 0) AS IsProformaInvoice
				FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)
					INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
					INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
					 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
					INNER JOIN [dbo].[SalesOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
					INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
					INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
				WHERE sobi.InvoiceStatus = 'Invoiced' AND ISNULL(sobi.IsBilling, 0) = 0
					AND CAST(sobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)AND sobi.BillToSiteId = @SiteId AND le.LegalEntityId = @LegalEntityId
				GROUP BY sobi.InvoiceDate,ct.CustomerId,sobi.GrandTotal,sobi.RemainingAmount,ctm.NetDays,sobi.PostedDate,ctm.Code,sobi.IsProforma
			
			UNION ALL
			
				SELECT ct.CustomerId,
					CAST(wobi.InvoiceDate AS DATE) AS InvoiceDate,
					CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN wobi.GrandTotal ELSE 0 END AS GrandTotal,  
					CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN wobi.RemainingAmount ELSE (0 - (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) END AS RemainingAmount,
					DATEDIFF(DAY, CAST(wobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
					ctm.NetDays,
					DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																		WHEN ctm.Code='CIA' THEN -1
																		WHEN ctm.Code='CreditCard' THEN -1
																		WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETUTCDATE()) AS CreditRemainingDays,
					ISNULL(wobi.IsPerformaInvoice, 0) AS IsProformaInvoice
				FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wobi.WorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
					INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
					 --LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
					 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
					INNER JOIN [dbo].[WorkOrderManagementStructureDetails] soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
					INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
					INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
				WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND ISNULL(wobi.IsInvoicePosted, 0) = 0
					AND CAST(wobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId
					AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) 
					OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 ))
				GROUP BY wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,wobi.PostedDate,ctm.Code,wobi.IsPerformaInvoice
			
			), CTECalculation AS(
			SELECT CustomerId, SUM (CASE WHEN IsProformaInvoice = 1 THEN RemainingAmount
											ELSE (CASE WHEN CreditRemainingDays < 0 THEN RemainingAmount ELSE 0 END) END) AS paidbylessthen0days,
							   SUM (CASE WHEN IsProformaInvoice = 1 THEN 0
											ELSE (CASE WHEN CreditRemainingDays > 0 AND CreditRemainingDays <= 30 THEN RemainingAmount ELSE 0 END) END) AS paidby30days,
							   SUM (CASE WHEN IsProformaInvoice = 1 THEN 0
											ELSE (CASE WHEN CreditRemainingDays > 30 AND CreditRemainingDays <= 60 THEN RemainingAmount ELSE 0 END) END) AS paidby60days,
							   SUM (CASE WHEN IsProformaInvoice = 1 THEN 0
											ELSE (CASE WHEN CreditRemainingDays > 60 AND CreditRemainingDays <= 90 THEN RemainingAmount ELSE 0 END) END) AS paidby90days,
			                   SUM (CASE WHEN IsProformaInvoice = 1 THEN 0
											ELSE (CASE WHEN CreditRemainingDays > 90 AND CreditRemainingDays <= 120 THEN RemainingAmount ELSE 0 END) END) AS paidby120days,
							   SUM (CASE WHEN IsProformaInvoice = 1 THEN 0
											ELSE (CASE WHEN CreditRemainingDays > 120 THEN RemainingAmount ELSE 0 END) END) AS paidbymorethan120days
			FROM CTEData c GROUP BY CustomerId
			),CTE AS(
				SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(wobi.GrandTotal) AS 'BalanceAmount',
					   SUM(wobi.GrandTotal - wobi.RemainingAmount) AS 'CurrentlAmount',             
					   SUM(CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE (0 - ((wobi.GrandTotal - wobi.RemainingAmount))) END) AS 'PaymentAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   MAX('') AS 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(wop.ManagementStructureId) AS ManagementStructureId,
					   STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference',
						0 AS CM
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkOrderId = WO.WorkOrderId AND ISNULL(wobi.IsInvoicePosted, 0) = 0
		 	   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ReferenceID = wop.ID AND MSD.ModuleID = @WOMSModuleID
			   INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
			   INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			  WHERE wobi.InvoiceStatus = 'Invoiced' AND c.CustomerId=@CustomerId AND wobi.SoldToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId 
			  AND CAST(wobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) and CAST(@EndDate AS DATE)	
			  GROUP BY C.CustomerId,wop.CustomerReference,wobi.BillingInvoicingId,wobi.IsPerformaInvoice
		
		UNION ALL
		
			    SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(sobi.GrandTotal) AS 'BalanceAmount',
					   SUM(sobi.GrandTotal - sobi.RemainingAmount) AS 'CurrentlAmount',  
					   SUM(CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE (0 - ((sobi.GrandTotal - sobi.RemainingAmount))) END) AS 'PaymentAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   MAX('') AS 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(SO.ManagementStructureId) AS ManagementStructureId,
					   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference',
						0 AS CM
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId AND ISNULL(sobi.IsBilling, 0) = 0
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ReferenceID = so.SalesOrderId AND MSD.ModuleID = @SOMSModuleID
			   INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
			   INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			  WHERE sobi.InvoiceStatus='Invoiced' AND c.CustomerId=@CustomerId AND sobi.BillToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId 
			  AND CAST(sobi.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)	
			  GROUP BY C.CustomerId,SO.CustomerReference,sobi.SOBillingInvoicingId,sobi.IsProforma),

			 
			Creditmemo AS(
			 SELECT CGL.CustomerId AS CustomerId, 
			     (ISNULL(SUM(CGL.CreditAmount),0)) AS 'CreditMemoAmount',
				 'CM' 'Type'
			   FROM dbo.CustomerGeneralLedger CGL  WITH (NOLOCK) 
			   INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CGL.ReferenceId 
			   WHERE  CGL.ModuleId=@CreditMemoMSModuleID 
			     AND CAST(CGL.CreatedDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) 
				 AND CGL.CustomerId=@CustomerId  
				 AND CM.StatusId = @CMPostedStatusId
			   GROUP BY CGL.CustomerId			   			
			) 

			,StandaloneCreditMemo  AS (
				SELECT CM.CustomerId AS CustomerId, 
				(ISNULL(SUM(CM.Amount),0)) AS 'CreditMemoAmount'
				FROM [dbo].[StandAloneCreditMemoDetails] CGL  WITH (NOLOCK) 
					INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CGL.CreditMemoHeaderId 
			   WHERE CAST(CM.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
			     AND CM.CustomerId = @CustomerId
				 AND CM.StatusId = @CMPostedStatusId
				 AND CM.IsStandAloneCM = 1  				 
			   GROUP BY CM.CustomerId			
			)

		    ,ManualJE AS (			 
			  SELECT MJD.ReferenceId AS CustomerId,
				     ISNULL(SUM(ISNULL(MJD.Debit,0) - ISNULL(MJD.Credit,0)),0) AS 'ManualJEAmount' 				 
		     FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
				  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
				   WHERE MJD.[ReferenceId] = @CustomerId AND MJD.[ReferenceTypeId] = 1
				AND MJH.[ManualJournalStatusId] = @PostStatusId
			    AND CAST(MJH.[PostedDate] AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) 
				GROUP BY MJD.ReferenceId
			),
			
			Result AS(
				SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType',
					   MAX(CTE.currencyCode) AS  'currencyCode',
					   --(ISNULL(MAX(Creditmemo.CreditMemoAmount * -1),0)) AS 'CreditMemoAmount',				   
					   (ISNULL(MAX(Creditmemo.CreditMemoAmount),0)) + (ISNULL(MAX(SCM.CreditMemoAmount),0))  AS 'CreditMemoAmount', (ISNULL(SUM(ManualJE.ManualJEAmount),0)) AS 'ManualJEAmount',
					   --(ISNULL(SUM(CTE.PaymentAmount),0) - (ISNULL(SUM(Creditmemo.CreditMemoAmount),0)) + (ISNULL(SUM(ManualJE.ManualJEAmount),0))) AS 'BalanceAmount',
					   (ISNULL(SUM(CTE.PaymentAmount),0) - (ISNULL(MAX(Creditmemo.CreditMemoAmount),0)) + (ISNULL(MAX(SCM.CreditMemoAmount),0)) + (ISNULL(MAX(ManualJE.ManualJEAmount),0))) AS 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.PaymentAmount),0) AS 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.PaymentAmount),0) AS 'PaymentAmount',
					   MAX(CTECalculation.paidbylessthen0days) AS 'Amountpaidbylessthen0days',      
					   MAX(CTECalculation.paidby30days) AS 'Amountpaidby30days',      
                       MAX(CTECalculation.paidby60days) AS 'Amountpaidby60days',
					   MAX(CTECalculation.paidby90days) AS 'Amountpaidby90days',
					   MAX(CTECalculation.paidby120days) AS 'Amountpaidby120days',
					   MAX(CTECalculation.paidbymorethan120days) AS 'Amountpaidbymorethan120days',  
					   Max('') AS 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(CTE.ManagementStructureId) AS ManagementStructureId
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN CTE AS CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
			   INNER JOIN CTECalculation AS CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId
			    LEFT JOIN Creditmemo AS Creditmemo WITH (NOLOCK) ON Creditmemo.CustomerId = C.CustomerId
				LEFT JOIN StandaloneCreditMemo AS SCM WITH (NOLOCK) ON SCM.CustomerId = C.CustomerId 	
				LEFT JOIN ManualJE AS ManualJE WITH (NOLOCK) ON ManualJE.CustomerId = C.CustomerId 				
			   WHERE c.CustomerId = @CustomerId  GROUP BY C.CustomerId

			), ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)
			SELECT * INTO #TempResult2 FROM  Result
			select * from #TempResult2;

		 END

	END TRY    
	BEGIN CATCH      
            -- temp table drop
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProcLegalEntityList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@startDate, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@EndDate, '') AS varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END