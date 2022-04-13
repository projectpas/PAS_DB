-- EXEC [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise] 61,26,'2022-04-01','2022-04-11'
CREATE PROCEDURE [dbo].[GetCustomerLegalEntityWiseInvoiceDataDateWise]
	@CustomerId bigint = null,
	@ManagementStructureId bigint = null,
	@StartDate DateTime=null,
	@EndDate DateTime=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	select DISTINCT sobi.SOBillingInvoicingId AS InvoiceId, ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			--DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			--ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays,
			sobi.InvoiceNo as InvoiceNo,
			sobi.InvoiceStatus as InvoiceStatus,
			so.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			--GETDATE() AS DueDate,
			dateadd(dd,(ctm.NetDays - DATEDIFF(DAY, CAST(sobi.InvoiceDate as date), GETDATE())),sobi.InvoiceDate) as 'DueDate',
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
			where sobi.InvoiceStatus = 'Invoiced' AND so.ManagementStructureId = @ManagementStructureId AND so.CustomerId = @CustomerId
			AND sobi.InvoiceDate BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			--group by  sobi.SOBillingInvoicingId,ct.CustomerId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,ctm.[Name],cr.Code,sobi.GrandTotal,sobi.RemainingAmount,so.CustomerReference
			UNION ALL
			
			select DISTINCT wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.InvoiceNo as InvoiceNo,
			wobi.InvoiceStatus as InvoiceStatus,
			wop.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			--GETDATE() AS DueDate,
			dateadd(dd,(ctm.NetDays - DATEDIFF(DAY, CAST(wobi.InvoiceDate as date), GETDATE())),wobi.InvoiceDate) as 'DueDate',
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
			where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND wop.ManagementStructureId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			AND wobi.InvoiceDate BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
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