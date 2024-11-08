-- EXEC [dbo].[GetPackagingLabel] 1103, 1
CREATE   PROCEDURE [dbo].[GetPackagingLabel]
    @SalesOrderId INT,
    @SalesOrderPartId INT
AS
BEGIN
    SET NOCOUNT ON;

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
    FROM SOPickTicket sopkt
    JOIN SalesOrder soq ON sopkt.SalesOrderId = soq.SalesOrderId
    LEFT JOIN SalesOrderPartV1 part ON soq.SalesOrderId = part.SalesOrderId
    LEFT JOIN SalesOrderStockLineV1 stk ON part.SalesOrderPartId = stk.SalesOrderPartId
    LEFT JOIN Customer cust ON soq.CustomerId = cust.CustomerId
    LEFT JOIN Address cuad ON cust.AddressId = cuad.AddressId
    LEFT JOIN Countries ccnty ON cuad.CountryId = ccnty.countries_id
    LEFT JOIN CustomerContact cust_cont ON soq.CustomerContactId = cust_cont.CustomerContactId
    LEFT JOIN Contact cont ON cust_cont.ContactId = cont.ContactId
    LEFT JOIN AllAddress posadd ON soq.SalesOrderId = posadd.ReffranceId 
        AND posadd.IsShippingAdd = 1 
        AND posadd.ModuleId = 1 -- assuming SalesOrder module
    LEFT JOIN AllShipVia posv ON soq.SalesOrderId = posv.ReferenceId 
        AND posv.ModuleId = 1 -- assuming SalesOrder module
    LEFT JOIN SalesOrderPackaginSlipItems spi ON sopkt.SOPickTicketId = spi.SOPickTicketId
    LEFT JOIN SalesOrderPackaginSlipHeader spb ON spi.PackagingSlipId = spb.PackagingSlipId
    LEFT JOIN SalesOrderShippingItem sosi ON sopkt.SOPickTicketId = sosi.SOPickTicketId
    LEFT JOIN SalesOrderShipping sos ON sosi.SalesOrderShippingId = sos.SalesOrderShippingId
    LEFT JOIN SalesOrderBillingInvoicing sobi ON sos.SalesOrderId = sobi.SalesOrderId
    LEFT JOIN Employee saemp ON soq.SalesPersonId = saemp.EmployeeId
    LEFT JOIN StockLine qs ON stk.StockLineId = qs.StockLineId
    LEFT JOIN PurchaseOrder po ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN RepairOrder ro ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN ShippingVia sh ON sos.ShipviaId = sh.ShippingViaId
    WHERE sopkt.SalesOrderId = @SalesOrderId AND sopkt.SalesOrderPartId = @SalesOrderPartId;
END;