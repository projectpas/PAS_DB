/*************************************************************               
 ** File:   [GetROPackagingLabel]               
 ** Author:   
 ** Description:         
 ** Purpose:             
 ** Date:   05/15/2025            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change	Description                
 ** --   --------     -------			--------------------------------              
    1    05/15/2025   VISHAL SUTHAR     Created
	2    06/19/2026   Abhishek Jirawla	Adding IsPiecePart condition in RepairOrderPart table 
         
-- EXEC [dbo].[GetROPackagingLabel] 2614, 4769
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetROPackagingLabel]
    @RepairOrderId INT,
    @RepairOrderPartId INT
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @RepairOrderModuleId BIGINT;
	SET @RepairOrderModuleId = (SELECT ModuleId FROM dbo.[Module] WHERE ModuleName = 'RepairOrder')

    SELECT TOP 1
        ropkt.ROPickTicketId roPickTicketId,
        ISNULL(spb.PackagingSlipNo, '') AS packagingSlipNo,
        ISNULL(spb.PackagingSlipNo, '') AS packagingLabelBarcode, -- Add your barcode generation logic in app layer
        roq.RepairOrderId repairOrderId,
        roq.RepairOrderNumber repairOrderNumber,
        '' AS invoiceNo,
        NULL invoiceDate,
        sos.Notes notes,
        ISNULL(sos.NoOfContainer, 0) AS noOfContainer,
        sos.ShipDate shipDate,
        ISNULL(sos.AirwayBill, '') AS awb,
        ISNULL(sos.ROShippingNum, '') AS shippingOrderNo,
        ISNULL(CONCAT(po.PurchaseOrderNumber, ISNULL(CONCAT('/', ro.RepairOrderNumber), '')), '') AS poroNum,
        roq.VendorId vendorId,
        roq.Terms AS creditTerm,
        ISNULL(cust.VendorName, '') AS vendorName,
        ISNULL(cust.VendorCode, '') AS vendorCode,
        ISNULL(cuad.Line1, '') AS custToAddress1,
        ISNULL(cuad.Line2, '') AS custToAddress2,
        ISNULL(cuad.City, '') AS custToCity,
        ISNULL(cuad.StateOrProvince, '') AS custToState,
        ISNULL(cuad.PostalCode, '') AS custToPostalCode,
        ISNULL(ccnty.countries_name, '') AS custToCountry,
        ISNULL(CONCAT(cont.FirstName, ' ', cont.LastName), '') AS vendorContactName,
        ISNULL(posadd.SiteName, '') AS shipToSiteName,
        ISNULL(posadd.Line1, '') AS shipToAddress1,
        ISNULL(posadd.Line2, '') AS shipToAddress2,
        ISNULL(posadd.City, '') AS shipToCity,
        ISNULL(posadd.StateOrProvince, '') AS shipToState,
        ISNULL(posadd.PostalCode, '') AS shipToPostalCode,
        ISNULL(posadd.Country, '') AS shipToCountry,
        ISNULL(posadd.ContactName, '') AS shipToContactName,
        ISNULL(sh.Name, '') AS shipViaName,
        roq.CreatedBy createdBy,
        roq.CreatedDate createdDate,
        roq.UpdatedBy updatedBy,
        roq.UpdatedDate updatedDate,
        roq.ManagementStructureId managementStructureId,
        '' vendorReference
    FROM [dbo].[ROPickTicket] ropkt WITH(NOLOCK)
    JOIN [dbo].RepairOrder roq WITH(NOLOCK) ON ropkt.RepairOrderId = roq.RepairOrderId
    LEFT JOIN [dbo].[RepairOrderPart] part WITH(NOLOCK) ON roq.RepairOrderId = part.SalesOrderId AND ISNULL(part.[IsPiecePart], 0) = 0
    LEFT JOIN [dbo].[Vendor] cust WITH(NOLOCK) ON roq.VendorId = cust.VendorId
    LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
    LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
    LEFT JOIN [dbo].[VendorContact] cust_cont WITH(NOLOCK) ON roq.VendorContactId = cust_cont.VendorContactId
    LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
    LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON roq.RepairOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @RepairOrderModuleId -- assuming RepairOrder module
    LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON roq.RepairOrderId = posv.ReferenceId AND posv.ModuleId = 1 -- assuming SalesOrder module
    LEFT JOIN [dbo].[RepairOrderPackaginSlipItems] spi WITH(NOLOCK) ON ropkt.ROPickTicketId = spi.ROPickTicketId
    LEFT JOIN [dbo].[RepairOrderPackaginSlipHeader] spb WITH(NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId
    LEFT JOIN [dbo].[RepairOrderShippingItem] sosi WITH(NOLOCK) ON ropkt.ROPickTicketId = sosi.ROPickTicketId
    LEFT JOIN [dbo].[RepairOrderShipping] sos WITH(NOLOCK) ON sosi.RepairOrderShippingId = sos.RepairOrderShippingId
    --LEFT JOIN [dbo].[Employee] saemp WITH(NOLOCK) ON roq.RepairPersonId = saemp.EmployeeId
    LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
    LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN [dbo].[ShippingVia] sh WITH(NOLOCK) ON sos.ShipviaId = sh.ShippingViaId
    WHERE ropkt.RepairOrderId = @RepairOrderId AND ropkt.RepairOrderPartId = @RepairOrderPartId;
END;