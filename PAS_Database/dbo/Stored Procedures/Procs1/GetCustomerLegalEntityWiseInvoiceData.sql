-- EXEC [dbo].[GetCustomerLegalEntityWiseInvoiceData] 66,29
CREATE PROCEDURE [dbo].[GetCustomerLegalEntityWiseInvoiceData]
	@CustomerId bigint = null,
	@ManagementStructureId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12;
	select  sobi.SOBillingInvoicingId AS InvoiceId, ct.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			--DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) AS dayDiff,
			--ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays,
			sobi.InvoiceNo as InvoiceNo,
			sobi.InvoiceStatus as InvoiceStatus,
			so.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			GETDATE() AS DueDate,
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
			--where sobi.InvoiceStatus != 'Invoiced' AND so.ManagementStructureId = @ManagementStructureId AND so.CustomerId = @CustomerId
			where sobi.InvoiceStatus = 'Invoiced' AND le.LegalEntityId = @ManagementStructureId AND so.CustomerId = @CustomerId
			group by ct.CustomerId,sobi.SOBillingInvoicingId,sobi.InvoiceDate,sobi.InvoiceNo,sobi.InvoiceStatus,so.CustomerReference,ctm.[Name],cr.Code,sobi.GrandTotal,sobi.RemainingAmount
			UNION ALL
			
			select wobi.BillingInvoicingId AS InvoiceId,ct.CustomerId,CASt(wobi.InvoiceDate as date) AS InvoiceDate,
			wobi.InvoiceNo as InvoiceNo,
			wobi.InvoiceStatus as InvoiceStatus,
			wop.CustomerReference as Reference,
			ctm.[Name] as CreditTerm,
			GETDATE() AS DueDate,
			cr.Code AS Currency,
			'' AS CM,
			wobi.GrandTotal as InvoiceAmount,
			wobi.RemainingAmount as RemainingAmount
			from dbo.[WorkOrder] WO
			INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID and wobi.IsVersionIncrease=0
			INNER JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			INNER JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=ct.CustomerId
			LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = CF.CurrencyId
			INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.ReferenceID = wop.ID AND soms.ModuleID = @WOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			--where wobi.InvoiceStatus != 'Invoiced' and wobi.IsVersionIncrease=0 AND wop.ManagementStructureId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND le.LegalEntityId = @ManagementStructureId AND WO.CustomerId = @CustomerId
			group by ct.CustomerId,wobi.BillingInvoicingId,wobi.InvoiceDate,wobi.InvoiceNo,wobi.InvoiceStatus,wop.CustomerReference,ctm.[Name],cr.Code,wobi.GrandTotal,wobi.RemainingAmount
			--group by WO.CustomerId
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