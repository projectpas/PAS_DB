/*************************************************************               
 ** File:   [GetPackagingLabel]               
 ** Author:   
 ** Description:         
 ** Purpose:             
 ** Date:   13/11/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author				Change	Description                
 ** --   --------     -------   --------------------------------              
    2    13/11/2024    SHREY CHANDEGARA      UPDATED for @SalesOrderModuleId
	3    17/06/2025    Amit Ghediya			 UPDATED for add @PackagingSlipId
	4    07-07-2025    Moin Bloch            Changed Old To New Billing Table
         
-- EXEC [dbo].[GetPackagingLabel] 1300, 1507
**************************************************************/  
CREATE     PROCEDURE [dbo].[GetPackagingLabel]
    @SalesOrderId BIGINT,
    @SalesOrderPartId BIGINT,
	@PackagingSlipId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @SalesOrderModuleId BIGINT;
	SET @SalesOrderModuleId = (SELECT ModuleId FROM dbo.[Module] WHERE ModuleName = 'SalesOrder')
    SELECT TOP 1
        sopkt.SOPickTicketId soPickTicketId,
        ISNULL(spb.PackagingSlipNo, '') AS packagingSlipNo,
        ISNULL(spb.PackagingSlipNo, '') AS packagingLabelBarcode, -- Add your barcode generation logic in app layer
        soq.SalesOrderId salesOrderId,
        soq.SalesOrderNumber salesOrderNumber,
        ISNULL(sobi.InvoiceNo, '') AS invoiceNo,
        sobi.InvoiceDate invoiceDate,
        sos.Notes notes,
        ISNULL(sos.NoOfContainer, 0) AS noOfContainer,
        sos.ShipDate shipDate,
        ISNULL(sos.AirwayBill, '') AS awb,
        ISNULL(sos.SOShippingNum, '') AS shippingOrderNo,
        ISNULL(CONCAT(saemp.FirstName, ' ', saemp.LastName), '') AS salesPersonName,
        ISNULL(CONCAT(po.PurchaseOrderNumber, ISNULL(CONCAT('/', ro.RepairOrderNumber), '')), '') AS poroNum,
        soq.CustomerId customerId,
        soq.CreditTermName AS creditTerm,
        ISNULL(cust.Name, '') AS customerName,
        ISNULL(cust.CustomerCode, '') AS customerCode,
        ISNULL(cuad.Line1, '') AS custToAddress1,
        ISNULL(cuad.Line2, '') AS custToAddress2,
        ISNULL(cuad.City, '') AS custToCity,
        ISNULL(cuad.StateOrProvince, '') AS custToState,
        ISNULL(cuad.PostalCode, '') AS custToPostalCode,
        ISNULL(ccnty.countries_name, '') AS custToCountry,
        ISNULL(CONCAT(cont.FirstName, ' ', cont.LastName), '') AS customerContactName,
        ISNULL(posadd.SiteName, '') AS shipToSiteName,
        ISNULL(posadd.Line1, '') AS shipToAddress1,
        ISNULL(posadd.Line2, '') AS shipToAddress2,
        ISNULL(posadd.City, '') AS shipToCity,
        ISNULL(posadd.StateOrProvince, '') AS shipToState,
        ISNULL(posadd.PostalCode, '') AS shipToPostalCode,
        ISNULL(posadd.Country, '') AS shipToCountry,
        ISNULL(posadd.ContactName, '') AS shipToContactName,
        ISNULL(sh.Name, '') AS shipViaName,
        soq.CreatedBy createdBy,
        soq.CreatedDate createdDate,
        soq.UpdatedBy updatedBy,
        soq.UpdatedDate updatedDate,
        soq.ManagementStructureId managementStructureId,
        soq.CustomerReference customerReference
    FROM [dbo].[SOPickTicket] sopkt WITH(NOLOCK)
    JOIN [dbo].SalesOrder soq WITH(NOLOCK) ON sopkt.SalesOrderId = soq.SalesOrderId
    LEFT JOIN [dbo].[SalesOrderPartV1] part WITH(NOLOCK) ON soq.SalesOrderId = part.SalesOrderId
    LEFT JOIN [dbo].[SalesOrderStockLineV1] stk WITH(NOLOCK) ON part.SalesOrderPartId = stk.SalesOrderPartId
    LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
    LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
    LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
    LEFT JOIN [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON soq.CustomerContactId = cust_cont.CustomerContactId
    LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
    LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON soq.SalesOrderId = posadd.ReffranceId 
        AND posadd.IsShippingAdd = 1 
        AND posadd.ModuleId = @SalesOrderModuleId -- assuming SalesOrder module
    LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON soq.SalesOrderId = posv.ReferenceId 
        AND posv.ModuleId = 1 -- assuming SalesOrder module
    LEFT JOIN [dbo].[SalesOrderPackaginSlipItems] spi WITH(NOLOCK) ON sopkt.SOPickTicketId = spi.SOPickTicketId
    LEFT JOIN [dbo].[SalesOrderPackaginSlipHeader] spb WITH(NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId 
    LEFT JOIN [dbo].[SalesOrderShippingItem] sosi WITH(NOLOCK) ON sopkt.SOPickTicketId = sosi.SOPickTicketId
    LEFT JOIN [dbo].[SalesOrderShipping] sos WITH(NOLOCK) ON sosi.SalesOrderShippingId = sos.SalesOrderShippingId
    LEFT JOIN [dbo].[BillingInvoicing] sobi WITH(NOLOCK) ON sos.SalesOrderId = sobi.ReferenceId AND sobi.[ModuleId] = @SalesOrderModuleId
    LEFT JOIN [dbo].[Employee] saemp WITH(NOLOCK) ON soq.SalesPersonId = saemp.EmployeeId
    LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON stk.StockLineId = qs.StockLineId
    LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN [dbo].[ShippingVia] sh WITH(NOLOCK) ON sos.ShipviaId = sh.ShippingViaId
    WHERE sopkt.SalesOrderId = @SalesOrderId AND spb.PackagingSlipId = @PackagingSlipId --AND sopkt.SalesOrderPartId = @SalesOrderPartId;
END;