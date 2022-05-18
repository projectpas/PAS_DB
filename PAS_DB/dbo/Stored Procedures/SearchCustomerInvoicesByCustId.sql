

-- EXEC [dbo].[SearchCustomerInvoicesByCustId] 7
CREATE PROCEDURE [dbo].[SearchCustomerInvoicesByCustId]
	@customerId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	    DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12; -- Sales Order Management Structure Module ID

		SELECT SOBI.SalesOrderId AS 'Id',
		SOBI.SOBillingInvoicingId AS 'SOBillingInvoicingId', 
	    'Invoice' AS 'DocumentType',
		SOBI.InvoiceNo AS 'DocNum', 
		SOBI.InvoiceDate, 
		SOBI.GrandTotal AS 'OriginalAmount', 
		SOBI.RemainingAmount AS 'RemainingAmount',
		0 AS 'PaymentAmount',
		0 AS 'DiscAmount', 
		Curr.Code AS 'CurrencyCode', 
		0 AS 'FxRate', 
		S.SalesOrderNumber AS 'WOSONum',
		0 AS 'NewRemainingBal',
		'Open' AS 'Status',
		DATEDIFF(DAY, SOBI.InvoiceDate, GETDATE()) AS 'DSI',		
		(CT.NetDays - DATEDIFF(DAY, CASt(SOBI.InvoiceDate as date), GETDATE())) AS 'DSO',
		CASE WHEN (CT.NetDays - DATEDIFF(DAY, CASt(SOBI.InvoiceDate as date), GETDATE())) < 0 THEN SOBI.RemainingAmount ELSE 0.00 END AS 'AmountPastDue',		
		--S.BalanceDue AS 'ARBalance',
		SOBI.RemainingAmount AS 'ARBalance', 
		C.CustomerId,
		C.Name AS 'CustName',
		C.CustomerCode, 
		S.CustomerReference, 		
		GETDATE() AS 'InvDueDate',		
		ISNULL(CF.CreditLimit, 0) AS 'CreditLimit', 
		S.CreditTermName,
		(Select COUNT(SOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems', 		
		MSD.LastMSLevel,
		MSD.AllMSlevels,
		1 AS InvoiceType
		FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
		LEFT JOIN Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
		LEFT JOIN CustomerFinancial CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId
		LEFT JOIN CreditTerms CT WITH (NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId		
		LEFT JOIN Currency Curr WITH (NOLOCK) ON SOBI.CurrencyId = Curr.CurrencyId
		LEFT JOIN SalesOrder S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		Where SOBI.InvoiceStatus = 'Invoiced'
		AND SOBI.CustomerId = @customerId AND SOBI.RemainingAmount > 0
		Group By SOBI.SalesOrderId,SOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceDate, S.SalesOrderNumber,
		S.CustomerReference, Curr.Code, SOBI.GrandTotal,SOBI.RemainingAmount, SOBI.InvoiceDate, S.BalanceDue, CF.CreditLimit, S.CreditTermName,		
		MSD.LastMSLevel,MSD.AllMSlevels,CT.NetDays

		UNION

		SELECT WOBI.WorkOrderId AS 'Id',
			   WOBI.BillingInvoicingId AS 'SOBillingInvoicingId',
			  'Invoice' AS 'DocumentType',
			   WOBI.InvoiceNo AS 'DocNum',
			   WOBI.InvoiceDate,
			   WOBI.GrandTotal AS 'OriginalAmount',
			   WOBI.RemainingAmount AS 'RemainingAmount',
			   0 AS 'PaymentAmount', 
			   0 AS 'DiscAmount',
			   Curr.Code AS 'CurrencyCode', 
			   0 AS 'FxRate',
			   WO.WorkOrderNum AS 'WOSONum',
			   0 AS 'NewRemainingBal',
			   'Open' AS 'Status',
			   DATEDIFF(DAY, WOBI.InvoiceDate, GETDATE()) AS 'DSI',		      			   
			   (CT.NetDays - DATEDIFF(DAY, CASt(WOBI.InvoiceDate as date), GETDATE())) AS 'DSO',
			    CASE WHEN (CT.NetDays - DATEDIFF(DAY, CASt(WOBI.InvoiceDate as date), GETDATE())) < 0 THEN WOBI.RemainingAmount ELSE 0.00 END AS 'AmountPastDue',			    
				WOBI.RemainingAmount AS 'ARBalance',  
				C.CustomerId,
				C.Name AS 'CustName',
				C.CustomerCode, 
				wop.CustomerReference,
				GETDATE() AS 'InvDueDate', 
				ISNULL(CF.CreditLimit, 0) AS 'CreditLimit',
				WO.CreditTerms AS 'CreditTermName',
				(Select COUNT(WOBI.InvoiceNo) AS NumberOfItems) 'NumberOfItems', 
				MSD.LastMSLevel,
				MSD.AllMSlevels,		 
				2 AS InvoiceType		 
		FROM WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
		INNER JOIN WorkOrder WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.WorkOrderId  and WOBI.IsVersionIncrease = 0
		LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on WOBI.BillingInvoicingId = wobii.BillingInvoicingId
		LEFT JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId		
		LEFT JOIN Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
		LEFT JOIN CustomerFinancial CF WITH (NOLOCK) ON WOBI.CustomerId = CF.CustomerId
		LEFT JOIN CreditTerms CT WITH (NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId
		LEFT JOIN Currency Curr WITH (NOLOCK) ON WOBI.CurrencyId = Curr.CurrencyId
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId
		Where WOBI.InvoiceStatus = 'Invoiced' AND WOBI.CustomerId = @customerId AND WOBI.RemainingAmount > 0
		Group By  WOBI.WorkOrderId,WOBI.InvoiceNo,C.CustomerId, C.Name, C.CustomerCode, WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceDate, WO.WorkOrderNum,
		wop.CustomerReference,Curr.Code, WOBI.GrandTotal,WOBI.RemainingAmount, WOBI.InvoiceDate, 
		--S.BalanceDue, --  need to confirm
		CF.CreditLimit, WO.CreditTerms,MSD.LastMSLevel,MSD.AllMSlevels,CT.NetDays

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
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END