/*************************************************************           
 ** File:   [GetWOPackagingLabelData]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to retrieve wo packing slip data
 ** Purpose:         
 ** Date:   05/02/2025

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    05/02/2025   Vishal Suthar		Created

**************************************************************/
CREATE   PROCEDURE [DBO].[GetWOPackagingLabelData]
    @WorkOrderId INT,
    @workOrderPartNoId INT,
    @CustShipvia NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY  
		SELECT 
			wopkt.PickTicketId AS WOPickTicketId,
			ISNULL(spb.PackagingSlipNo, '') AS PackagingSlipNo,
			ISNULL(spb.PackagingSlipNo, '') AS PackagingLabelBarcode, -- barcode should be generated in app
			wo.WorkOrderId,
			wo.WorkOrderNum AS WorkOrderNumber,
			ISNULL(sobi.InvoiceNo, '') AS InvoiceNo,
			sobi.InvoiceDate,
			ISNULL(sos.NoOfContainer, 0) AS NoOfContainer,
			sos.ShipDate,
			ISNULL(sos.Notes, '') AS Notes,
			ISNULL(sos.AirwayBill, '') AS AWB,
			ISNULL(sos.WOShippingNum, '') AS ShippingOrderNo,
			ISNULL(saemp.FirstName + ' ' + saemp.LastName, '') AS SalesPersonName,
			ISNULL(po.PurchaseOrderNumber, '') + CASE WHEN ro.RepairOrderNumber IS NOT NULL THEN '/' + ro.RepairOrderNumber ELSE '' END AS PORONum,
			wo.CustomerId,
			wo.CreditTerms,
			ISNULL(cust.Name, '') AS CustomerName,
			ISNULL(cust.CustomerCode, '') AS CustomerCode,
			ISNULL(cuad.Line1, '') AS CustToAddress1,
			ISNULL(cuad.Line2, '') AS CustToAddress2,
			ISNULL(cuad.City, '') AS CustToCity,
			ISNULL(cuad.StateOrProvince, '') AS CustToState,
			ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
			ISNULL(ccnty.countries_name, '') AS CustToCountry,
			ISNULL(cont.FirstName + ' ' + cont.LastName, '') AS CustomerContactName,
			sos.ShipToSiteName,
			sos.ShipToAddress1,
			sos.ShipToAddress2,
			sos.ShipToCity,
			sos.ShipToState,
			sos.ShipToZip AS ShipToPostalCode,
			sos.ShipToCountryName AS ShipToCountry,
			sos.ShipToName AS ShipToContactName,
			ISNULL(
				CASE 
					WHEN ISNULL(sos.IsCustomerShipping, 0) = 0 THEN sv1.Name
					WHEN sos.CustomerDomensticShippingShipViaId > 0 THEN sv2.Name
					ELSE @CustShipvia
				END, @CustShipvia
			) AS ShipViaName,
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
			sos.SoldToName AS BillToContactName
		FROM DBO.WOPickTicket wopkt WITH (NOLOCK)
		INNER JOIN DBO.WorkOrder wo WITH (NOLOCK) ON wopkt.WorkOrderId = wo.WorkOrderId
		INNER JOIN DBO.WorkOrderPartNumber part WITH (NOLOCK) ON wo.WorkOrderId = part.WorkOrderId
		LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON wo.CustomerId = cust.CustomerId
		LEFT JOIN DBO.[Address] cuad WITH (NOLOCK) ON cust.AddressId = cuad.AddressId
		LEFT JOIN DBO.Countries ccnty WITH (NOLOCK) ON cuad.CountryId = ccnty.countries_id
		INNER JOIN DBO.CustomerContact custCont WITH (NOLOCK) ON wo.CustomerContactId = custCont.CustomerContactId
		LEFT JOIN DBO.Contact cont WITH (NOLOCK) ON custCont.ContactId = cont.ContactId
		LEFT JOIN DBO.WorkOrderPackaginSlipItems spi WITH (NOLOCK) ON wopkt.PickTicketId = spi.WOPickTicketId
		LEFT JOIN DBO.WorkOrderPackaginSlipHeader spb WITH (NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId
		LEFT JOIN DBO.WorkOrderShippingItem sosi WITH (NOLOCK) ON wopkt.PickTicketId = sosi.WOPickTicketId
		LEFT JOIN DBO.WorkOrderShipping sos WITH (NOLOCK) ON sosi.WorkOrderShippingId = sos.WorkOrderShippingId
		LEFT JOIN DBO.WorkOrderBillingInvoicing sobi WITH (NOLOCK) ON sos.WorkOrderShippingId = sobi.WorkOrderShippingId AND ISNULL(sobi.IsVersionIncrease, 0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) != 1
		LEFT JOIN DBO.Employee saemp WITH (NOLOCK) ON wo.SalesPersonId = saemp.EmployeeId
		LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON part.StockLineId = qs.StockLineId
		LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
		LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
		LEFT JOIN DBO.CustomerDomensticShippingShipVia custship WITH (NOLOCK) ON sos.CustomerDomensticShippingShipViaId = custship.CustomerDomensticShippingShipViaId
		LEFT JOIN DBO.ShippingTerms term WITH (NOLOCK) ON custship.ShippingTermsId = term.ShippingTermsId
		LEFT JOIN DBO.ShippingVia sv1 WITH (NOLOCK) ON sv1.ShippingViaId = sos.ShipviaId
		LEFT JOIN DBO.CustomerDomensticShippingShipVia cdsv WITH (NOLOCK) ON cdsv.CustomerDomensticShippingShipViaId = sos.CustomerDomensticShippingShipViaId
		LEFT JOIN DBO.ShippingVia sv2 WITH (NOLOCK) ON cdsv.ShipViaId = sv2.ShippingViaId
		WHERE wopkt.WorkOrderId = @WorkOrderId AND wopkt.WorkFlowWorkOrderId = @workOrderPartNoId;

	END TRY
	BEGIN CATCH        
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWOPackagingLabelData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH
END