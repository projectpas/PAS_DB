-- EXEC [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise] 77,23,'2022-05-12','2022-05-12',1,1,79,2
-- EXEC [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise] 76,3,'2022-05-24','2022-05-24',1,1,76,1
CREATE PROCEDURE [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise]
	@CustomerId bigint = null,
	@ManagementStructureId bigint = null,
	@StartDate DateTime=null,
	@EndDate DateTime=null,
	@OpenTransactionsOnly bit=0,
	@IncludeCredits bit=0,
	@SiteId bigint=null,
	@MasterCompanyId int=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12;		
		--DECLARE @SOSTDT datetime2(7)=null;
		--DECLARE @WOSTDT datetime2(7)=null;		
		--SELECT TOP 1 @SOSTDT = sb.InvoiceDate FROM SalesOrderBillingInvoicing sb WITH(NOLOCK)WHERE sb.RemainingAmount > 0 AND sb.InvoiceStatus = 'Invoiced' AND sb.CustomerId = @CustomerId;		
		--SELECT TOP 1 @WOSTDT = wb.InvoiceDate FROM WorkOrderBillingInvoicing wb WITH(NOLOCK) WHERE wb.RemainingAmount > 0 AND wb.InvoiceStatus = 'Invoiced' AND wb.CustomerId = @CustomerId;		
		--print @SOSTDT
		--print @WOSTDT
		--IF(@SOSTDT is null or @SOSTDT = '')
		--BEGIN
		--	SET @StartDate = @WOSTDT; 
		--END
		--ELSE
		--BEGIN
		--	IF(@WOSTDT is null or @WOSTDT = '')
		--	BEGIN					
		--		SET @StartDate = @SOSTDT;
		--	END
		--	ELSE
		--	BEGIN
		--		IF(@SOSTDT < @WOSTDT)
		--		BEGIN
		--			SET @StartDate = @SOSTDT;
		--		END
		--		ELSE
		--		BEGIN
		--			SET @StartDate = @WOSTDT; 
		--		END
		--	END
		--END
		IF(@OpenTransactionsOnly = 1)
		BEGIN
			--print @StartDate
			--print @EndDate

			SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId, ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			--DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			--ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays,
			sobi.InvoiceNo as InvoiceNo,
			sobi.InvoiceStatus as InvoiceStatus,
			--so.CustomerReference as Reference,
			STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference',
			ctm.[Name] as CreditTerm,			
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(sobi.PostedDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			ISNULL(SUM(CM.Amount),0) AS CM,
			sobi.GrandTotal as InvoiceAmount,
			--sobi.RemainingAmount as RemainingAmount
			(sobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0) +(ISNULL(SUM(CM.Amount),0))) AS PaidAmount
			from SalesOrderBillingInvoicing sobi
			INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			 LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			 
			 ON CM.InvoiceId = sobi.SOBillingInvoicingId  			

			WHERE sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId
			AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND sobi.BillToSiteId=@SiteId
			--AND CAST(sobi.InvoiceDate AS date) >= CAST(@StartDate as date) and CAST(sobi.InvoiceDate AS date) <= CAST(@EndDate as date)
			GROUP BY  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,
			ctm.[Name],ctm.NetDays,sobi.PostedDate,cr.Code,sobi.GrandTotal,sobi.RemainingAmount			
			
			UNION ALL
			
			select DISTINCT wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.InvoiceNo as InvoiceNo,
			wobi.InvoiceStatus as InvoiceStatus,
			--wop.CustomerReference as Reference,
			STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference',
			ctm.[Name] as CreditTerm,			
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(wobi.PostedDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			ISNULL(SUM(CM.Amount),0) AS CM,
			wobi.GrandTotal as InvoiceAmount,
            --wobi.RemainingAmount as RemainingAmount
			(wobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0) +(ISNULL(SUM(CM.Amount),0))) AS PaidAmount
			from dbo.[WorkOrder] WO
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms AND ctm.MasterCompanyId = @MasterCompanyId
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId  AND CA.StatusName='Approved'			
			ON CM.InvoiceId = wobi.BillingInvoicingId
						
			WHERE wobi.RemainingAmount > 0 AND wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 
			AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId
			
			GROUP BY wobi.BillingInvoicingId,ct.CustomerId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,ctm.[Name],			
			ctm.NetDays,wobi.PostedDate,cr.Code,wobi.GrandTotal,wobi.RemainingAmount

		END
		ELSE
		BEGIN
			SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId, ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			--DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			--ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays,
			sobi.InvoiceNo as InvoiceNo,
			sobi.InvoiceStatus as InvoiceStatus,
			--so.CustomerReference as Reference,
			STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference',
			ctm.[Name] as CreditTerm,			
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(sobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			ISNULL(SUM(CM.Amount),0) AS CM,
			sobi.GrandTotal as InvoiceAmount,
			--sobi.RemainingAmount as RemainingAmount
			(sobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0) +(ISNULL(SUM(CM.Amount),0))) AS PaidAmount
			from SalesOrderBillingInvoicing sobi
			INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId			
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			 
			 ON CM.InvoiceId = sobi.SOBillingInvoicingId 
			
			WHERE sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			 AND sobi.BillToSiteId=@SiteId
			GROUP BY  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,
			ctm.[Name],ctm.NetDays,sobi.PostedDate,cr.Code,sobi.GrandTotal,sobi.RemainingAmount	
			
			UNION ALL
			
			select DISTINCT wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.InvoiceNo as InvoiceNo,
			wobi.InvoiceStatus as InvoiceStatus,
			--wop.CustomerReference as Reference,
			STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference',
			ctm.[Name] as CreditTerm,			
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(wobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			ISNULL(SUM(CM.Amount),0) AS CM,
			wobi.GrandTotal as InvoiceAmount,
			--wobi.RemainingAmount as RemainingAmount
			(wobi.RemainingAmount +(ISNULL(SUM(CM.Amount),0))) AS RemainingAmount,
			ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0) +(ISNULL(SUM(CM.Amount),0))) AS PaidAmount
			from dbo.[WorkOrder] WO
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms AND ctm.MasterCompanyId = @MasterCompanyId
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId			
			LEFT JOIN dbo.CreditMemoDetails CM WITH(NOLOCK) 
				INNER JOIN dbo.CreditMemoApproval CA WITH(NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId AND CA.StatusName='Approved'			
			ON CM.InvoiceId = wobi.BillingInvoicingId
			
			WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId
			
			GROUP BY wobi.BillingInvoicingId,ct.CustomerId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,ctm.[Name],			
			ctm.NetDays,wobi.PostedDate,cr.Code,wobi.GrandTotal,wobi.RemainingAmount
		
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