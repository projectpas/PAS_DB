--exec GetCustomerAccountListDataByCustomerId 68,'2022-04-26','2022-04-27',1,1
--exec GetCustomerAccountListDataByCustomerId 76,'2022-05-24','2022-05-24',1,1,76,3
--exec GetCustomerAccountListDataByCustomerId 14,'2021-11-25','2022-05-25',1,1,20,1
CREATE PROCEDURE [dbo].[GetCustomerAccountListDataByCustomerId]
@CustomerId bigint = null,
@StartDate DateTime=null,
@EndDate DateTime=null,
@OpenTransactionsOnly bit=false,
@IncludeCredits bit=false,
@SiteId bigint=null,
@LegalEntityId bigint=null
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY
		DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12;
		
		IF(@OpenTransactionsOnly = 1)
		BEGIN

		 ;WITH CTEData AS(
			select ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			sobi.GrandTotal,
			--sobi.RemainingAmount,
			(sobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			DATEDIFF(DAY, CASt(sobi.PostedDate as date), GETDATE()) AS dayDiff,
			ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays
			--(ISNULL(ctm.NetDays,0) - DATEDIFF(DAY, CASt(sobi.PostedDate as date), GETDATE())) AS CreditRemainingDays
			--DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) AS CreditRemainingDays
			DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) AS CreditRemainingDays
			,CASt(sobi.PostedDate as date) AS PostedDate
			from SalesOrderBillingInvoicing sobi
			INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			 
			 ON CM.InvoiceId = sobi.SOBillingInvoicingId
			--where ct.CustomerId=58 AND sobi.InvoiceStatus='Reviewed'
			where sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced'
			AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND sobi.BillToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId
			group by sobi.InvoiceDate,ct.CustomerId,sobi.GrandTotal,sobi.RemainingAmount,ctm.NetDays,sobi.PostedDate,ctm.Code
			
			UNION ALL
			
			select ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.GrandTotal,
			--wobi.RemainingAmount,
			(wobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			DATEDIFF(DAY, CASt(wobi.PostedDate as date), GETDATE()) AS dayDiff,
			ctm.NetDays,
			--(DATEDIFF(DAY, CASt(wobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays
			--(ISNULL(ctm.NetDays,0) - DATEDIFF(DAY, CASt(wobi.PostedDate as date), GETDATE())) AS CreditRemainingDays
			--DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) AS CreditRemainingDays
			DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) AS CreditRemainingDays
			,CASt(wobi.PostedDate as date) AS PostedDate
			from WorkOrderBillingInvoicing wobi
			INNER JOIN WorkOrder wo WITH(NOLOCK) ON wo.WorkOrderId = wobi.WorkOrderId
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			--LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId  AND CA.StatusName='Approved'			
			ON CM.InvoiceId = wobi.BillingInvoicingId
			--where ct.CustomerId=58 AND wobi.InvoiceStatus='Reviewed'
			where wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0
			AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId
			group by wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,wobi.PostedDate,ctm.Code
			
			), CTECalculation AS(
			select
				CustomerId,
				SUM (CASE
			    WHEN CreditRemainingDays < 0 THEN RemainingAmount
			    ELSE 0
			  END) AS paidbylessthen0days,
			   SUM (CASE
			    WHEN CreditRemainingDays > 0 AND CreditRemainingDays <= 30 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby30days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 30 AND CreditRemainingDays <= 60 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby60days,
			   SUM (CASE
			    WHEN CreditRemainingDays > 60 AND CreditRemainingDays <= 90 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby90days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 90 AND CreditRemainingDays <= 120 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby120days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 120 THEN RemainingAmount
			    ELSE 0
			  END) AS paidbymorethan120days
			    from CTEData c group by CustomerId
			),CTE AS(
						SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(wobi.GrandTotal) as 'BalanceAmount',
					   SUM(wobi.GrandTotal - wobi.RemainingAmount)as 'CurrentlAmount',             
					   SUM(wobi.RemainingAmount)as 'PaymentAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(wop.ManagementStructureId) as ManagementStructureId,
					   STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference',
						ISNULL(SUM(CM.Amount),0) AS CM
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   --INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			   --INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID
			   INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkOrderId = WO.WorkOrderId
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   --LEFT JOIN InvoicePayments ipy WITH(NOLOCK) ON ipy.SOBillingInvoicingId = wobi.BillingInvoicingId AND ipy.InvoiceType=2
			   --INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   INNER JOIN WorkOrderManagementStructureDetails MSD WITH(NOLOCK) ON MSD.ReferenceID = wop.ID AND MSD.ModuleID = @WOMSModuleID
			   INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
			  INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			  LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId  AND CA.StatusName='Approved'			
			ON CM.InvoiceId = wobi.BillingInvoicingId
			  WHERE wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' AND c.CustomerId=@CustomerId AND wobi.SoldToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)	GROUP BY C.CustomerId,wop.CustomerReference,wobi.BillingInvoicingId
UNION ALL
SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					  Max(CR.Code) as  'currencyCode',
					   SUM(sobi.GrandTotal) as 'BalanceAmount',
					   SUM(sobi.GrandTotal - sobi.RemainingAmount)as 'CurrentlAmount',   
					   SUM(sobi.RemainingAmount)as 'PaymentAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(SO.ManagementStructureId) as ManagementStructureId,
					   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference',
						ISNULL(SUM(CM.Amount),0) AS CM
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   --INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId
			   --INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   --LEFT JOIN InvoicePayments ipy WITH(NOLOCK) ON ipy.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND ipy.InvoiceType=1
			   		--INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
				INNER JOIN SalesOrderManagementStructureDetails MSD WITH(NOLOCK) ON MSD.ReferenceID = so.SalesOrderId AND MSD.ModuleID = @SOMSModuleID
				INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
				INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
				LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			 
			 ON CM.InvoiceId = sobi.SOBillingInvoicingId
		 	  WHERE sobi.InvoiceStatus='Invoiced' AND sobi.RemainingAmount > 0 AND c.CustomerId=@CustomerId AND sobi.BillToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)	GROUP BY C.CustomerId,SO.CustomerReference,sobi.SOBillingInvoicingId
						), Result AS(
				SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CTE.currencyCode) as  'currencyCode',
					   --SUM(CTE.BalanceAmount) as 'BalanceAmount',
					   --ISNULL(SUM(CTE.PaymentAmount),0) as 'BalanceAmount',
					   ISNULL(SUM(CTE.PaymentAmount),0)+(ISNULL(SUM(CTE.CM),0)) as 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.PaymentAmount),0)as 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.PaymentAmount),0) as 'PaymentAmount',
					   MAX(CTECalculation.paidbylessthen0days) as 'Amountpaidbylessthen0days',      
					   MAX(CTECalculation.paidby30days) as 'Amountpaidby30days',      
                       MAX(CTECalculation.paidby60days) as 'Amountpaidby60days',
					   MAX(CTECalculation.paidby90days) as 'Amountpaidby90days',
					   MAX(CTECalculation.paidby120days) as 'Amountpaidby120days',
					   MAX(CTECalculation.paidbymorethan120days) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(CTE.ManagementStructureId) as ManagementStructureId
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
			   INNER JOIN CTECalculation as CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId 
			   WHERE c.CustomerId=@CustomerId 
			   --AND CAST(CTECalculation.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) 
			   GROUP BY C.CustomerId


			), ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)

			SELECT * INTO #TempResult FROM  Result
			select * from #TempResult;

         END
		 ELSE
		 BEGIN
			;WITH CTEData AS(
			select ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			sobi.GrandTotal,
			--sobi.RemainingAmount,
			(sobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays
			--(ISNULL(ctm.NetDays,0) - DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE())) AS CreditRemainingDays
			--DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) AS CreditRemainingDays
			DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) AS CreditRemainingDays
			from SalesOrderBillingInvoicing sobi
			INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			 
			 ON CM.InvoiceId = sobi.SOBillingInvoicingId
			--where ct.CustomerId=58 AND sobi.InvoiceStatus='Reviewed'
			where sobi.InvoiceStatus = 'Invoiced'
			AND CAST(sobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)AND sobi.BillToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId
			group by sobi.InvoiceDate,ct.CustomerId,sobi.GrandTotal,sobi.RemainingAmount,ctm.NetDays,sobi.PostedDate,ctm.Code
			
			UNION ALL
			
			select ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.GrandTotal,
			--wobi.RemainingAmount,
			(wobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			DATEDIFF(DAY, CASt(wobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			ctm.NetDays,
			--(DATEDIFF(DAY, CASt(wobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays
			--(ISNULL(ctm.NetDays,0) - DATEDIFF(DAY, CASt(wobi.InvoiceDate as date), GETDATE())) AS CreditRemainingDays
			--DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) AS CreditRemainingDays
			DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) AS CreditRemainingDays
			from WorkOrderBillingInvoicing wobi
			INNER JOIN WorkOrder wo WITH(NOLOCK) ON wo.WorkOrderId = wobi.WorkOrderId
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId  AND CA.StatusName='Approved'			
			ON CM.InvoiceId = wobi.BillingInvoicingId
			--where ct.CustomerId=58 AND wobi.InvoiceStatus='Reviewed'
			where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0
			AND CAST(wobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId
			group by wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,wobi.PostedDate,ctm.Code
			
			), CTECalculation AS(
			select
				CustomerId,
				SUM (CASE
			    WHEN CreditRemainingDays < 0 THEN RemainingAmount
			    ELSE 0
			  END) AS paidbylessthen0days,
			   SUM (CASE
			    WHEN CreditRemainingDays > 0 AND CreditRemainingDays <= 30 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby30days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 30 AND CreditRemainingDays <= 60 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby60days,
			   SUM (CASE
			    WHEN CreditRemainingDays > 60 AND CreditRemainingDays <= 90 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby90days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 90 AND CreditRemainingDays <= 120 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby120days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 120 THEN RemainingAmount
			    ELSE 0
			  END) AS paidbymorethan120days
			    from CTEData c group by CustomerId
			),CTE AS(
						SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(wobi.GrandTotal) as 'BalanceAmount',
					   SUM(wobi.GrandTotal - wobi.RemainingAmount)as 'CurrentlAmount',             
					   SUM(wobi.RemainingAmount)as 'PaymentAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(wop.ManagementStructureId) as ManagementStructureId,
					   STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference',
						ISNULL(SUM(CM.Amount),0) AS CM
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   --INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			   --INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID
			   INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkOrderId = WO.WorkOrderId
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   --LEFT JOIN InvoicePayments ipy WITH(NOLOCK) ON ipy.SOBillingInvoicingId = wobi.BillingInvoicingId AND ipy.InvoiceType=2
			   --INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   INNER JOIN WorkOrderManagementStructureDetails MSD WITH(NOLOCK) ON MSD.ReferenceID = wop.ID AND MSD.ModuleID = @WOMSModuleID
			   INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
			  INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			  LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId  AND CA.StatusName='Approved'			
			ON CM.InvoiceId = wobi.BillingInvoicingId
			  --WHERE c.CustomerId=@CustomerId AND CAST(wobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)	GROUP BY C.CustomerId,wop.CustomerReference,wobi.BillingInvoicingId
			  WHERE wobi.InvoiceStatus = 'Invoiced' AND c.CustomerId=@CustomerId AND wobi.SoldToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)	GROUP BY C.CustomerId,wop.CustomerReference,wobi.BillingInvoicingId
UNION ALL
SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					  Max(CR.Code) as  'currencyCode',
					   SUM(sobi.GrandTotal) as 'BalanceAmount',
					   SUM(sobi.GrandTotal - sobi.RemainingAmount)as 'CurrentlAmount',   
					   SUM(sobi.RemainingAmount)as 'PaymentAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(SO.ManagementStructureId) as ManagementStructureId,
					   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference',
						ISNULL(SUM(CM.Amount),0) AS CM
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   --INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId
			   --INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   --LEFT JOIN InvoicePayments ipy WITH(NOLOCK) ON ipy.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND ipy.InvoiceType=1
			   --INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
			   INNER JOIN SalesOrderManagementStructureDetails MSD WITH(NOLOCK) ON MSD.ReferenceID = so.SalesOrderId AND MSD.ModuleID = @SOMSModuleID
			   INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = MSD.Level1Id
			   INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			   LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			 
			 ON CM.InvoiceId = sobi.SOBillingInvoicingId
		 	  --WHERE c.CustomerId=@CustomerId AND CAST(sobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)	GROUP BY C.CustomerId,SO.CustomerReference,sobi.SOBillingInvoicingId
			  WHERE sobi.InvoiceStatus='Invoiced' AND c.CustomerId=@CustomerId AND sobi.BillToSiteId=@SiteId AND le.LegalEntityId = @LegalEntityId AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)	GROUP BY C.CustomerId,SO.CustomerReference,sobi.SOBillingInvoicingId
						), Result AS(
				SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CTE.currencyCode) as  'currencyCode',
					   --SUM(CTE.BalanceAmount) as 'BalanceAmount',
					   --ISNULL(SUM(CTE.PaymentAmount),0) as 'BalanceAmount',
					   ISNULL(SUM(CTE.PaymentAmount),0)+(ISNULL(SUM(CTE.CM),0)) as 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.PaymentAmount),0)as 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.PaymentAmount),0) as 'PaymentAmount',
					   MAX(CTECalculation.paidbylessthen0days) as 'Amountpaidbylessthen0days',      
					   MAX(CTECalculation.paidby30days) as 'Amountpaidby30days',      
                       MAX(CTECalculation.paidby60days) as 'Amountpaidby60days',
					   MAX(CTECalculation.paidby90days) as 'Amountpaidby90days',
					   MAX(CTECalculation.paidby120days) as 'Amountpaidby120days',
					   MAX(CTECalculation.paidbymorethan120days) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(CTE.ManagementStructureId) as ManagementStructureId
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
			   INNER JOIN CTECalculation as CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId 
			   WHERE c.CustomerId=@CustomerId
			   --AND CAST(CTECalculation.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			   GROUP BY C.CustomerId


			), ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)
			SELECT * INTO #TempResult2 FROM  Result
			select * from #TempResult2;

		 END

			--COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			--PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;
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