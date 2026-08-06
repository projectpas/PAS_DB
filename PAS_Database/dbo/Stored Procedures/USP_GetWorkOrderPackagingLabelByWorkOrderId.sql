/************************************************************************************           
 ** File:   [USP_GetWorkOrderPackagingLabelByWorkOrderId]           
 ** Author: 
 ** Description: This stored procedure is used to get USP_GetWorkOrderPackagingLabelByWorkOrderId.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    4-30-2025			Amit Ghediya			Created
	 2    6-12-2025         MOIN BLOCH              Updated BillingInvoice Old To New Table
	 3    13/01/2025		Amit Ghediya			Get ShippingAccountInfo field
	 4    09/July/2026		RAJESH GAMI			[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    23/July/2026		RAJESH GAMI			[PN-17350] - Removed 1 leftover IsNonStock=0 exclusion filter.
	 EXEC [dbo].[USP_GetWorkOrderPackagingLabelByWorkOrderId] 8936,8731
****************************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWorkOrderPackagingLabelByWorkOrderId]
@WorkOrderId BIGINT,
@WorkOrderPartNoId BIGINT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
				DECLARE @WOModuleId INT

				SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

				SELECT TOP 1
					wopkt.PickTicketId AS WOPickTicketId,
					ISNULL(spb.PackagingSlipNo, '') AS PackagingSlipNo,
					wo.WorkOrderId,
					wo.WorkOrderNum AS WorkOrderNumber,
					ISNULL(sobi.InvoiceNo, '') AS InvoiceNo,
					sobi.InvoiceDate,
					ISNULL(sos.NoOfContainer, 0) AS NoOfContainer,
					sos.ShipDate,
					ISNULL(sos.Notes, '') AS Notes,
					ISNULL(sos.AirwayBill, '') AS AWB,
					ISNULL(sos.WOShippingNum, '') AS ShippingOrderNo,
					ISNULL(CONCAT(saemp.FirstName, ' ', saemp.LastName), '') AS SalesPersonName,
					ISNULL(po.PurchaseOrderNumber, '') + CASE WHEN ro.RepairOrderNumber IS NOT NULL THEN '/' + ro.RepairOrderNumber ELSE '' END AS PORONum,
					wo.CustomerId,
					wo.CreditTerms,
					ISNULL(cust.[Name], '') AS CustomerName,
					ISNULL(cust.CustomerCode, '') AS CustomerCode,
					ISNULL(cuad.Line1, '') AS CustToAddress1,
					ISNULL(cuad.Line2, '') AS CustToAddress2,
					ISNULL(cuad.City, '') AS CustToCity,
					ISNULL(cuad.StateOrProvince, '') AS CustToState,
					ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
					ISNULL(ccnty.countries_name, '') AS CustToCountry,
					ISNULL(CONCAT(cont.FirstName, ' ', cont.LastName), '') AS CustomerContactName,
					sos.ShipToSiteName,
					sos.ShipToAddress1,
					sos.ShipToAddress2,
					sos.ShipToCity,
					sos.ShipToState,
					sos.ShipToZip AS ShipToPostalCode,
					sos.ShipToCountryName,
					sos.ShipToName AS ShipToContactName,
					CASE 
						WHEN sos.IsCustomerShipping = 0 THEN
							(SELECT TOP 1 sv.[Name] 
							FROM [DBO].[ShippingVia] sv WITH(NOLOCK)
							WHERE sv.ShippingViaId = sos.ShipviaId)
						WHEN sos.CustomerDomensticShippingShipViaId > 0 THEN
							(SELECT TOP 1 sv.[Name] 
							FROM [DBO].[CustomerDomensticShippingShipVia] cdsv WITH(NOLOCK)
							JOIN [DBO].[ShippingVia] sv WITH(NOLOCK) ON cdsv.ShipViaId = sv.ShippingViaId
							WHERE cdsv.CustomerDomensticShippingShipViaId = sos.CustomerDomensticShippingShipViaId)
						ELSE
							(SELECT TOP 1 sv.[Name]
							 FROM [DBO].[WorkOrder] wo2 WITH(NOLOCK)
							 JOIN [DBO].[WorkOrderPartNumber] part2 WITH(NOLOCK) ON wo2.WorkOrderId = part2.WorkOrderId
							 JOIN [DBO].[CustomerDomensticShippingShipVia] cusv2 WITH(NOLOCK) ON wo2.CustomerId = cusv2.CustomerId
							 JOIN [DBO].[ShippingVia] sv WITH(NOLOCK) ON cusv2.ShipViaId = sv.ShippingViaId
							 WHERE wo2.WorkOrderId = @WorkOrderId AND part2.ID = @workOrderPartNoId AND cusv2.IsPrimary = 1)
					END AS ShipViaName,
					wo.CreatedBy,
					wo.CreatedDate,
					wo.UpdatedBy,
					wo.UpdatedDate,
					part.ManagementStructureId,
					part.CustomerReference AS Reference,
					ISNULL(term.Name, '-') AS ShippingTerms,
					sos.SoldToSiteName AS BillToSiteName,
					sos.SoldToAddress1 AS BillToAddress1,
					sos.SoldToAddress2 AS BillToAddress2,
					sos.SoldToCity AS BillToCity,
					sos.SoldToState AS BillToState,
					sos.SoldToZip AS BillToPostalCode,
					sos.SoldToCountryName AS BillToCountry,
					sos.SoldToName,
					sos.ShippingAccountInfo
				FROM [DBO].[WOPickTicket] wopkt WITH(NOLOCK)
				JOIN [DBO].[WorkOrder] wo WITH(NOLOCK) ON wopkt.WorkOrderId = wo.WorkOrderId
				JOIN [DBO].[WorkOrderPartNumber] part WITH(NOLOCK) ON wo.WorkOrderId = part.WorkOrderId
				LEFT JOIN [DBO].[Customer] cust WITH(NOLOCK) ON wo.CustomerId = cust.CustomerId
				LEFT JOIN [DBO].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
				LEFT JOIN [DBO].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
				JOIN [DBO].[CustomerContact] custCont WITH(NOLOCK) ON wo.CustomerContactId = custCont.CustomerContactId
				LEFT JOIN [DBO].[Contact] cont WITH(NOLOCK) ON custCont.ContactId = cont.ContactId
				LEFT JOIN [DBO].[WorkOrderPackaginSlipItems] spi WITH(NOLOCK) ON wopkt.PickTicketId = spi.WOPickTicketId
				LEFT JOIN [DBO].[WorkOrderPackaginSlipHeader] spb WITH(NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId
				LEFT JOIN [DBO].[WorkOrderShippingItem] sosi WITH(NOLOCK) ON wopkt.PickTicketId = sosi.WOPickTicketId
				LEFT JOIN [DBO].[WorkOrderShipping] sos WITH(NOLOCK) ON sosi.WorkOrderShippingId = sos.WorkOrderShippingId
				-- COMMENT OLD TABLE
				--LEFT JOIN [DBO].[WorkOrderBillingInvoicing] sobi WITH(NOLOCK) ON sos.WorkOrderShippingId = sobi.WorkOrderShippingId AND ISNULL(sobi.IsVersionIncrease,0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) = 0
				-- ADDED NEW TABLES 
				LEFT JOIN [DBO].[BillingInvoicingItems] sobii WITH(NOLOCK) ON sobii.[ReferenceId] = wo.[WorkOrderId] AND sobii.[SubReferenceId] = @workOrderPartNoId AND sobii.[ModuleId] = @WOModuleId AND ISNULL(sobii.[IsVersionIncrease],0) = 0 AND ISNULL(sobii.[IsPerformaInvoice],0) = 0
				LEFT JOIN [DBO].[BillingInvoicing] sobi WITH(NOLOCK) ON sobii.[BillingInvoicingId] = sobi.[BillingInvoicingId]							
				LEFT JOIN [DBO].[Employee] saemp WITH(NOLOCK) ON wo.SalesPersonId = saemp.EmployeeId
				LEFT JOIN [DBO].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
				LEFT JOIN [DBO].[PurchaseOrder] po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [DBO].[RepairOrder] ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [DBO].[CustomerDomensticShippingShipVia] custship WITH(NOLOCK) ON sos.CustomerDomensticShippingShipViaId = custship.CustomerDomensticShippingShipViaId
				LEFT JOIN [DBO].[ShippingTerms] term WITH(NOLOCK)ON custship.ShippingTermsId = term.ShippingTermsId
				WHERE wopkt.WorkOrderId = @WorkOrderId AND wopkt.WorkFlowWorkOrderId = @workOrderPartNoId;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderPackagingLabelByWorkOrderId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END