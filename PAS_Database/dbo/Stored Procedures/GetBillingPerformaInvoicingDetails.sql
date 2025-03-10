/*************************************************************             
 ** File:   [GetReceiverStockPO]            
 ** Author:   AMIT GHEDIYA  
 ** Description: This stored procedure is used to get data for Performa Invoicing Billing Details.
 ** Purpose:           
 ** Date:   03/05/2025          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    03/05/2025   AMIT GHEDIYA	    Created
  
exec dbo.GetBillingPerformaInvoicingDetails @WorkOrderId=8400,@workOrderPartNoId=8050
**************************************************************/
CREATE    PROCEDURE [dbo].[GetBillingPerformaInvoicingDetails]
	@WorkOrderId BIGINT,
	@workOrderPartNoId  BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		
		DECLARE @WOPartCount INT = 0;

		SELECT @WOPartCount = COUNT(DISTINCT wosi.WorkOrderPartNumId) 
			FROM [dbo].[WorkOrderShipping] wos WITH(NOLOCK)
			LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK)
				ON wos.WorkOrderShippingId = wosi.WorkOrderShippingId
		WHERE wos.WorkOrderId = @WorkOrderId 
		AND wosi.WorkOrderPartNumId = @workOrderPartNoId;

		IF(@WOPartCount > 0)
		BEGIN
			SELECT TOP 1
				wosh.workOrderId,
				wosh.workOrderPartNoId,
				cust.ContractReference,
				CASE WHEN cust.CustomerAffiliationId = 1 THEN 1 ELSE 0 END AS CustomerType,
				GETUTCDATE() AS InvoiceDate,
				GETUTCDATE() AS PrintDate,
				wosh.ShipDate,
				wo.EmployeeId,
				ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS EmployeeName,
				ISNULL(wos.Code + '-' + wos.Stage, '') AS gateStatus,
				wo.WorkOrderTypeId,
				CASE 
					WHEN wo.WorkOrderTypeId = 1 THEN 'Customer' 
					WHEN wo.WorkOrderTypeId = 2 THEN 'Internal' 
					WHEN wo.WorkOrderTypeId = 3 THEN 'Tear Down' 
					ELSE 'Shop Services' 
				END AS WorkOrderType,
				wop.WorkScope,
				wop.WorkOrderScopeId,
				wop.Quantity,
				wopsettlement.ConditionId,
				wo.OpenDate,
				wo.SalesPersonId,
				ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
				wosh.ShippingAccountInfo,
				CASE 
					WHEN wosh.IsCustomerShipping = 1 THEN wosh.CustomerDomensticShippingShipViaId 
					ELSE wosh.ShipviaId 
				END AS CustomerDomensticShippingShipViaId,
				ISNULL(cf.CreditLimit, 0) AS CreditLimit,
				ISNULL(cf.CreditTermsId, 0) AS CreditTermsId,
				wo.CreditTerms AS CreditTerm,
				ISNULL(wo.FunctionalCurrencyId, 0) AS CurrencyId,
				ISNULL(fcu.Code, '') AS Currency,
				wo.CustomerId AS SoldToCustomerId,
				wosh.SoldToName AS SoldToCustomer,
				wosh.SoldToSiteId,
				wosh.ShipToCustomerId,
				wosh.ShipToName AS ShipToCustomer,
				wosh.ShipToSiteId,
				wop.ManagementStructureId,
				'Flat Rate' AS CostPlusType,
				1 AS TotalWorkOrder,
				wosh.ShipviaId,
				wosh.TrackingNum AS Tracking,
				ISNULL(csr.FirstName + ' ' + csr.LastName, '') AS CSR,
				wop.CustomerReference,
				cust.Name AS CustomerName,
				wo.CustomerId,
				cust.Email,
				cust.CustomerPhone,
				wosh.AirwayBill AS wayBillRef,
				@WOPartCount AS NoofPieces, 
				wosh.IsCustomerShipping
			FROM [dbo].[WorkOrderShipping] wosh WITH(NOLOCK)
			JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wosh.WorkOrderId = wo.WorkOrderId
			JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wosh.WorkOrderId = wop.WorkOrderId
			LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK) ON wop.ID = wosi.WorkOrderPartNumId
			JOIN [dbo].[Customer] cust WITH(NOLOCK) ON wosh.CustomerId = cust.CustomerId
			JOIN [dbo].[WorkOrderStage] wos WITH(NOLOCK) ON wop.WorkOrderStageId = wos.WorkOrderStageId
			LEFT JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
			LEFT JOIN [dbo].[Currency] cr WITH(NOLOCK) ON cf.CurrencyId = cr.CurrencyId
			LEFT JOIN [dbo].[WorkOrderSettlementDetails] wopsettlement WITH(NOLOCK)
				ON wop.WorkOrderId = wopsettlement.WorkOrderId 
				AND wop.ID = wopsettlement.workOrderPartNoId 
				AND wopsettlement.WorkOrderSettlementId = 9
			LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON wo.EmployeeId = emp.EmployeeId
			LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON wo.SalesPersonId = sp.EmployeeId
			LEFT JOIN [dbo].[Employee] csr WITH(NOLOCK) ON wo.CSRId = csr.EmployeeId
			LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId
			LEFT JOIN [dbo].[Currency] fcu WITH(NOLOCK) ON wo.FunctionalCurrencyId = fcu.CurrencyId 
				AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
			WHERE wosh.WorkOrderId = @WorkOrderId 
			AND wosi.WorkOrderPartNumId = @workOrderPartNoId;
		END
		ELSE
		BEGIN
			SELECT TOP 1
				wo.workOrderId,
				wop.ID AS workOrderPartNoId,
				cust.contractReference,
				cust.customerCode,
				CASE WHEN cust.CustomerAffiliationId = 1 THEN 1 ELSE 0 END AS customerType,
				GETUTCDATE() AS invoiceDate,
				GETUTCDATE() AS printDate,
				'' AS shipDate,
				wo.employeeId,
				ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS employeeName,
				ISNULL(wos.Code + '-' + wos.Stage, '') AS gateStatus,
				wo.workOrderTypeId,
				CASE 
					WHEN wo.WorkOrderTypeId = 1 THEN 'Customer' 
					WHEN wo.WorkOrderTypeId = 2 THEN 'Internal' 
					WHEN wo.WorkOrderTypeId = 3 THEN 'Tear Down' 
					ELSE 'Shop Services' 
				END AS workOrderType,
				wop.workScope,
				wop.workOrderScopeId,
				wop.quantity,
				ISNULL(wopsettlement.ConditionId, wop.ConditionId) AS conditionId,
				wo.openDate,
				wo.salesPersonId,
				ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS salesPerson,
				ISNULL(cust_shipVia.ShippingAccountinfo, '') AS shipAccountInfo,
				ISNULL(cust_shipVia.ShipViaId, 0) AS customerDomensticShippingShipViaId,
				ISNULL(cf.CreditLimit, 0) AS creditLimit,
				ISNULL(cf.CreditTermsId, 0) AS creditTermsId,
				wo.CreditTerms AS creditTerm,
				ISNULL(wo.FunctionalCurrencyId, 0) AS currencyId,
				ISNULL(fcu.Code, '') AS currency,
				wo.CustomerId AS soldToCustomerId,
				cust.Name AS soldToCustomer,
				cust_bill.CustomerBillingAddressId AS soldToSiteId,
				wo.CustomerId AS shipToCustomerId,
				cust.Name AS shipToCustomer,
				cust_ship.CustomerDomensticShippingId AS shipToSiteId,
				wop.managementStructureId,
				'Flat Rate' AS costPlusType,
				1 AS totalWorkOrder,
				ISNULL(cust_shipVia.ShipViaId, 0) AS shipViaId,
				'' AS tracking,
				ISNULL(csr.FirstName + ' ' + csr.LastName, '') AS csr,
				wop.customerReference,
				cust.Name AS customerName,
				wo.customerId,
				cust.email,
				cust.customerPhone,
				'' AS wayBillRef,
				@WOPartCount AS noofPieces, 
				0 AS isCustomerShipping
			FROM WorkOrder wo WITH(NOLOCK)
			JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
			LEFT JOIN [dbo].[WOPickTicket] wopick WITH(NOLOCK) ON wop.ID = wopick.OrderPartId
			JOIN [dbo].[Customer] cust WITH(NOLOCK) ON wo.CustomerId = cust.CustomerId
			JOIN [dbo].[WorkOrderStage] wos WITH(NOLOCK) ON wop.WorkOrderStageId = wos.WorkOrderStageId
			LEFT JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
			LEFT JOIN [dbo].[Currency] cr WITH(NOLOCK) ON cf.CurrencyId = cr.CurrencyId
			LEFT JOIN [dbo].[CustomerDomensticShipping] cust_ship WITH(NOLOCK) ON wo.CustomerId = cust_ship.CustomerId
			LEFT JOIN [dbo].[CustomerBillingAddress] cust_bill WITH(NOLOCK) ON wo.CustomerId = cust_bill.CustomerId
			LEFT JOIN [dbo].[WorkOrderSettlementDetails] wopsettlement WITH(NOLOCK)
				ON wop.WorkOrderId = wopsettlement.WorkOrderId 
				AND wop.ID = wopsettlement.workOrderPartNoId 
				AND wopsettlement.WorkOrderSettlementId = 9
			LEFT JOIN [dbo].[Address] ship_addr WITH(NOLOCK) ON cust_ship.AddressId = ship_addr.AddressId
			LEFT JOIN [dbo].[CustomerDomensticShippingShipVia] cust_shipVia WITH(NOLOCK)
				ON wo.CustomerId = cust_shipVia.CustomerId 
				AND cust_shipVia.IsPrimary = 1
			LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON wo.EmployeeId = emp.EmployeeId
			LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON wo.SalesPersonId = sp.EmployeeId
			LEFT JOIN [dbo].[Employee] csr WITH(NOLOCK) ON wo.CSRId = csr.EmployeeId
			LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId
			LEFT JOIN [dbo].[Currency] fcu WITH(NOLOCK) ON wo.FunctionalCurrencyId = fcu.CurrencyId 
				AND fcu.IsActive = 1 
				AND fcu.IsDeleted = 0
			WHERE wo.WorkOrderId = @WorkOrderId
			AND wop.ID = @workOrderPartNoId
		END
		END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetBillingPerformaInvoicingDetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@workOrderPartNoId,'') + ''
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