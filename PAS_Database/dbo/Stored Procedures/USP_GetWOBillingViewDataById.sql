/*************************************************************                   
 ** File:   [USP_GetWOBillingViewDataById]                   
 ** Author:   Shrey Chandegara      
 ** Description:       
 ** Purpose:                 
 ** Date:   30-01-2024               
                  
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** PR   Date         Author   Change Description                    
 ** --   --------     -------   --------------------------------                  
    1    30-01-2024   Shrey Chandegara  Created
             
 EXECUTE USP_GetWOBillingViewDataById 410,4000,3488   
**************************************************************/         
Create      PROCEDURE [dbo].[USP_GetWOBillingViewDataById]      
     
@WorkOrderBillingId BIGINT,      
@WorkOrderId BIGINT,      
@WorkOrderPartId BIGINT    
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
         
  BEGIN TRY      
  BEGIN TRANSACTION      
   BEGIN       
          SELECT 
		    bi.WorkOrderId AS WorkOrderId,
		    wo.CustomerId AS CustomerId,
		    cust.Name AS ClientName,
		    ISNULL(cont.countries_name, '') AS CustCountry,
		    ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
		    custAddress.Line1 AS AddressLine1,
		    custAddress.Line2 AS AddressLine2,
		    custAddress.City AS City,
		    custAddress.StateOrProvince AS State,
		    custAddress.PostalCode AS PostalCode,
		    cust.CustomerPhone AS PhoneFax,
			shippingInfo.ShipToName AS ShipToCustomer,
		    shipToSite.SiteName AS ShipToSiteName,
		    shipToAddress.Line1 AS ShipToAddressLine1,
		    shipToAddress.Line2 AS ShipToAddressLine2,
		    shipToAddress.City AS ShipToCity,
		    shipToAddress.StateOrProvince AS ShipToState,
		    shipToAddress.PostalCode AS ShipToPostalCode,
		    shipToCountry.countries_name AS ShipToCountry,
		    shipToSite.Attention AS ShipToAttention,
		    billToSite.SiteName AS BillToSiteName,
			billToSite.Attention AS BillToAttention,
		    billToAddress.Line1 AS BillToAddressLine1,
		    billToAddress.Line2 AS BillToAddressLine2,
		    billToAddress.City AS BillToCity,
		    billToAddress.StateOrProvince AS BillToState,
		    billToAddress.PostalCode AS BillToPostalCode,
		    billToCountry.countries_name AS BillToCountry,
		    billToCustomer.Name AS BillToNameOfCustomer,
		    bi.InvoiceNo AS InvoiceNumber,
		    CONVERT(VARCHAR, bi.InvoiceDate, 101) + ' ' + CONVERT(VARCHAR, bi.InvoiceDate, 108) AS DateAndTime,
		    ISNULL(shippingInfo.NoOfContainer, 0) AS NoOfContainers,
		    CONCAT(contact.FirstName, ' ', contact.LastName) AS BuyersName,
		    bi.CreatedBy AS PreparedBy,
		    CONVERT(VARCHAR, bi.PrintDate, 101) + ' ' + CONVERT(VARCHAR, bi.PrintDate, 108) AS DatePrinted,
		    ISNULL(shippingInfo.Weight, 0) AS Weight,
		    ct.Name AS CreditTerms,
		    ISNULL(cur.Code, '') AS Currency,
		    wo.WorkOrderNum AS WONum,
		    CONVERT(VARCHAR, wo.OpenDate, 101) AS OrderDate,
		    CONVERT(VARCHAR, shippingInfo.ShipDate, 101) AS ShipDate,
		    --ISNULL(shipInfoVia.Name, '') AS ShipVia,
		    bi.ShippingAccountInfo AS ShipAccNumber,
		    shippingInfo.WOShippingNum AS ShippingOrderNumber,
		    ISNULL(shippingInfo.AirwayBill, '') AS Awb,
		    bi.InvoiceStatus AS InvoiceStatus,
		    bi.ManagementStructureId AS ManagementStructureId,
		    --PASCommon.BarCodeGenerator(bi.InvoiceNo) AS Barcode,
		    wo.UpdatedDate AS UpdatedDate,
		    shippingInfo.Shipment AS Shipment,
		    cust.CustomerCode AS CustomerCode,
		   -- ISNULL(custref.CustomerReference, '') AS CustomerReference,
		    cust.CustomerPhone AS CustToPhone,
		    CASE WHEN bi.PostedDate IS NOT NULL THEN DATEADD(DAY, ct.NetDays, bi.InvoiceDate) ELSE '' END AS DueDate,
		    bi.InvoiceDate AS NewDateAndTime,
		    shippingInfo.ShipDate AS NewShipDate,
		    DATEADD(DAY, ct.NetDays, bi.InvoiceDate) AS NewDueDate,
			IT.Description AS 'InvoiceType',
			bi.RevType,
			bi.InvoiceNo,
			WOT.Description AS 'WOType',
			WOP.CustomerReference,
			WOP.WorkScope,
			bi.InvoiceDate,
			WO.OpenDate,
			bi.InvoiceTime,
			ISNULL(CF.CurrencyId,0) AS 'CurrencyId',
			CR.Code,
			GETUTCDATE() AS 'PrintDate',
			wo.SalesPersonId,
			sp.FirstName + ' '+ sp.LastName as 'SalesPerson',
			shippingInfo.ShippingAccountInfo AS ShipAccount,
			bi.CostPlusType,
			WOS.Code +'-'+WOS.Stage AS Stage,
			emp.FirstName+' '+emp.LastName AS Employee,
			bi.GrandTotal,
			bi.AvailableCredit,
			bi.Notes,
			bi.TotalWorkOrder,
			bi.Material,
			bi.LaborOverHead,
			bi.MiscCharges,
			bi.Freight,
			CASE WHEN ISNULL(bi.TotalWorkOrderValue,0) > 0 THEN (SELECT P.PercentValue FROM DBO.[Percent] P WHERE P.PercentId = bi.TotalWorkOrderValue) ELSE 0 END AS TotalWorkOrderPercent,
			bi.TotalWorkOrderCost,
			bi.TotalWorkOrderCostPlus,
			CASE WHEN ISNULL(bi.MaterialValue,0) > 0 THEN (SELECT P.PercentValue FROM DBO.[Percent] P WHERE P.PercentId = bi.MaterialValue) ELSE 0 END AS MaterialPercent,
			bi.MaterialCost,
			bi.MaterialCostPlus,
			CASE WHEN ISNULL(bi.LaborOverHeadValue,0) > 0 THEN (SELECT P.PercentValue FROM DBO.[Percent] P WHERE P.PercentId = bi.LaborOverHeadValue) ELSE 0 END AS LaborPercent,
			bi.LaborOverHeadCost,
			bi.LaborOverHeadCostPlus,
			CASE WHEN ISNULL(bi.MiscChargesValue,0) > 0 THEN (SELECT P.PercentValue FROM DBO.[Percent] P WHERE P.PercentId = bi.MiscChargesValue) ELSE 0 END AS MiscPercent,
			bi.MiscChargesCost,
			bi.MiscChargesCostPlus,
			CASE WHEN ISNULL(bi.FreightValue,0) > 0 THEN (SELECT P.PercentValue FROM DBO.[Percent] P WHERE P.PercentId = bi.FreightValue) ELSE 0 END AS FreightPercent,
			bi.FreightCost,
			bi.FreightCostPlus,
			ISNULL(SIP.Name,'') AS ShipVia,
			bi.InvoiceTime
		FROM 
		    DBO.WorkOrderBillingInvoicing bi
		    JOIN DBO.WorkOrder wo WITH(NOLOCK) ON bi.WorkOrderId = wo.WorkOrderId
		    JOIN DBO.Customer cust WITH(NOLOCK) ON bi.CustomerId = cust.CustomerId
		    JOIN DBO.Address custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
		    JOIN DBO.CustomerContact custCont WITH(NOLOCK) ON wo.CustomerContactId = custCont.CustomerContactId
		    LEFT JOIN DBO.Contact contact WITH(NOLOCK) ON custCont.ContactId = contact.ContactId
		    LEFT JOIN DBO.CustomerFinancial cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
		    LEFT JOIN DBO.InvoiceType it WITH(NOLOCK) ON bi.InvoiceTypeId = it.InvoiceTypeId
		    LEFT JOIN DBO.Employee emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
		    JOIN DBO.Customer billToCustomer WITH(NOLOCK) ON bi.SoldToCustomerId = billToCustomer.CustomerId
		    JOIN DBO.CustomerBillingAddress billToSite WITH(NOLOCK) ON bi.SoldToSiteId = billToSite.CustomerBillingAddressId
		    JOIN DBO.Address billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
		    LEFT JOIN DBO.Countries billToCountry WITH(NOLOCK) ON billToAddress.CountryId = billToCountry.countries_id
		    JOIN DBO.CustomerDomensticShipping shipToSite WITH(NOLOCK) ON bi.ShipToSiteId = shipToSite.CustomerDomensticShippingId
		    JOIN DBO.Address shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
		    LEFT JOIN DBO.Employee sp WITH(NOLOCK) ON wo.SalesPersonId = sp.EmployeeId
		    LEFT JOIN DBO.Countries cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
		    LEFT JOIN DBO.Currency cur WITH(NOLOCK) ON bi.CurrencyId = cur.CurrencyId
		    JOIN DBO.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
		    LEFT JOIN DBO.WorkOrderShipping shippingInfo WITH(NOLOCK) ON bi.WorkOrderShippingId = shippingInfo.WorkOrderShippingId
		    LEFT JOIN DBO.ShippingVia sipVia WITH(NOLOCK) ON bi.ShipViaId = sipVia.ShippingViaId
		    LEFT JOIN DBO.Countries shipToCountry WITH(NOLOCK) ON shippingInfo.ShipToCountryId = shipToCountry.countries_id
			LEFT JOIN DBO.WorkOrderType WOT WITH(NOLOCK) on WOT.Id = WO.WorkOrderTypeId
			LEFT JOIN DBO.WorkOrderPartNumber WOP WITH(NOLOCK) on WOP.Id = @WorkOrderPartId
			LEFT JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = CF.CurrencyId
			LEFT JOIN DBO.WorkOrderStage WOS WITH(NOLOCK) on WOP.WorkOrderStageId = WOS.WorkOrderStageId
			LEFT JOIN DBO.ShippingVia SIP WITH(NOLOCK) on SIP.ShippingViaId = bi.ShipViaId
		WHERE 
		    bi.BillingInvoicingId = @WorkOrderBillingId
		    AND bi.IsActive = 1
		    AND bi.IsDeleted = 0

	END   
  COMMIT  TRANSACTION      
      
  END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
 --PRINT 'ROLLBACK'      
    ROLLBACK TRAN;      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
      
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOBillingViewDataById'       
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderBillingId, '') + ''      
              , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
      
              exec spLogException       
                       @DatabaseName   = @DatabaseName      
                     , @AdhocComments   = @AdhocComments      
                     , @ProcedureParameters  = @ProcedureParameters      
                     , @ApplicationName         = @ApplicationName      
                     , @ErrorLogID = @ErrorLogID OUTPUT ;      
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
              RETURN(1);      
  END CATCH      
END