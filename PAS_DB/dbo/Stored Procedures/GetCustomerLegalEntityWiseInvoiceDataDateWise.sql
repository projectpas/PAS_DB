-- EXEC [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise] 68,15,'2022-04-26','2022-04-27',1,1,68
CREATE PROCEDURE [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise]
	@CustomerId bigint = null,
	@ManagementStructureId bigint = null,
	@StartDate DateTime=null,
	@EndDate DateTime=null,
	@OpenTransactionsOnly bit=0,
	@IncludeCredits bit=0,
	@SiteId bigint=null
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
			so.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			--GETDATE() AS DueDate,
			--dateadd(dd,(ctm.NetDays - DATEDIFF(DAY, CAST(sobi.InvoiceDate as date), GETDATE())),sobi.InvoiceDate) as 'DueDate',
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(sobi.PostedDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			'' AS CM,
			sobi.GrandTotal as InvoiceAmount,
			sobi.RemainingAmount as RemainingAmount
			from SalesOrderBillingInvoicing sobi
			INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			INNER JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			--WHERE sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' AND so.ManagementStructureId = @ManagementStructureId AND so.CustomerId = @CustomerId
			WHERE sobi.RemainingAmount > 0 AND sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId
			AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND sobi.BillToSiteId=@SiteId
			--AND CAST(sobi.InvoiceDate AS date) >= CAST(@StartDate as date) and CAST(sobi.InvoiceDate AS date) <= CAST(@EndDate as date)
			--group by  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,ctm.[Name],cr.Code,sobi.GrandTotal,sobi.RemainingAmount,so.CustomerReference
			UNION ALL
			
			select DISTINCT wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.InvoiceNo as InvoiceNo,
			wobi.InvoiceStatus as InvoiceStatus,
			wop.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			--GETDATE() AS DueDate,
			--dateadd(dd,(ctm.NetDays - DATEDIFF(DAY, CAST(wobi.InvoiceDate as date), GETDATE())),wobi.InvoiceDate) as 'DueDate',
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(wobi.PostedDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			'' AS CM,
			wobi.GrandTotal as InvoiceAmount,
			wobi.RemainingAmount as RemainingAmount
			from dbo.[WorkOrder] WO
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			INNER JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			--WHERE wobi.RemainingAmount > 0 AND  wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND wop.ManagementStructureId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			WHERE wobi.RemainingAmount > 0 AND  wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId
		END
		ELSE
		BEGIN
			SELECT DISTINCT sobi.SOBillingInvoicingId AS InvoiceId, ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			--DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			--ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays,
			sobi.InvoiceNo as InvoiceNo,
			sobi.InvoiceStatus as InvoiceStatus,
			so.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			--GETDATE() AS DueDate,
			--dateadd(dd,(ctm.NetDays - DATEDIFF(DAY, CAST(sobi.InvoiceDate as date), GETDATE())),sobi.InvoiceDate) as 'DueDate',
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(sobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			'' AS CM,
			sobi.GrandTotal as InvoiceAmount,
			sobi.RemainingAmount as RemainingAmount
			from SalesOrderBillingInvoicing sobi
			INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			INNER JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = so.SalesOrderId AND soms.ModuleID = @SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			--where sobi.InvoiceStatus = 'Invoiced' AND so.ManagementStructureId = @ManagementStructureId AND so.CustomerId = @CustomerId AND CAST(sobi.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			where sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			 AND sobi.BillToSiteId=@SiteId
			--group by  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,ctm.[Name],cr.Code,sobi.GrandTotal,sobi.RemainingAmount,so.CustomerReference
			UNION ALL
			
			select DISTINCT wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.InvoiceNo as InvoiceNo,
			wobi.InvoiceStatus as InvoiceStatus,
			wop.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			--GETDATE() AS DueDate,
			--dateadd(dd,(ctm.NetDays - DATEDIFF(DAY, CAST(wobi.InvoiceDate as date), GETDATE())),wobi.InvoiceDate) as 'DueDate',
			DateAdd(Day,ISNULL(ctm.NetDays,0),ISNULL(wobi.InvoiceDate, '01/01/1900 23:59:59.999')) as 'DueDate',
			cr.Code AS Currency,
			'' AS CM,
			wobi.GrandTotal as InvoiceAmount,
			wobi.RemainingAmount as RemainingAmount
			from dbo.[WorkOrder] WO
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			INNER JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			--where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND wop.ManagementStructureId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND wobi.SoldToSiteId=@SiteId
		END
			--group by  wobi.BillingInvoicingId,ct.CustomerId
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