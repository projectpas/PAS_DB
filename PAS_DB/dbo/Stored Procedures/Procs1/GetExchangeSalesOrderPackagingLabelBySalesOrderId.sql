/*************************************************************           
 ** File:   [GetExchangeSalesOrderPackagingLabelBySalesOrderId]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeSalesOrderPackagingLabelBySalesOrderId
 ** Purpose:         
 ** Date:   05/27/2025      
          
 ** PARAMETERS: @ExchangeId bigint, @SalesOrderPartId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1     05/27/2025   Ekta Chandegra     Created
    2     09/July/2026   RAJESH GAMI     [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
    3     24/July/2026   RAJESH GAMI     [PN-17350] - Removed 2 leftover IsNonStock=0 exclusion filter(s) added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filters no longer needed).
     
-- EXEC GetExchangeSalesOrderPackagingLabelBySalesOrderId @ExchangeId=157 , @SalesOrderPartId=147
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderPackagingLabelBySalesOrderId]
    @ExchangeId BIGINT,
    @SalesOrderPartId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @IsVendor BIT;

		-- Get IsVendor flag
		SELECT @IsVendor = CAST(ISNULL(IsVendor, 0) AS BIT)
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeId;

		IF @IsVendor = 1
		BEGIN
			SELECT TOP 1
				sopkt.SOPickTicketId,
				ISNULL(spb.PackagingSlipNo, '') AS PackagingSlipNo,
				soq.ExchangeSalesOrderId,
				soq.ExchangeSalesOrderNumber,
				ISNULL(eb.InvoiceNo, '') AS InvoiceNo,
				eb.InvoiceDate,
				ISNULL(sos.NoOfContainer, 0) AS NoOfContainer,
				sos.ShipDate,
				ISNULL(sos.AirwayBill, '') AS AWB,
				ISNULL(sos.SOShippingNum, '') AS ShippingOrderNo,
				ISNULL(saemp.FirstName + ' ' + saemp.LastName, '') AS SalesPersonName,
				ISNULL(po.PurchaseOrderNumber, '') + CASE WHEN ro.RepairOrderNumber IS NULL THEN '' ELSE '/' + ro.RepairOrderNumber END AS PORONum,
				soq.CustomerId,
				soq.CreditTermName AS CreditTerm,
				ISNULL(cust.VendorName, '') AS CustomerName,
				ISNULL(cust.VendorCode, '') AS CustomerCode,
				ISNULL(cuad.Line1, '') AS CustToAddress1,
				ISNULL(cuad.Line2, '') AS CustToAddress2,
				ISNULL(cuad.City, '') AS CustToCity,
				ISNULL(cuad.StateOrProvince, '') AS CustToState,
				ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
				ISNULL(ccnty.countries_name, '') AS CustToCountry,
				ISNULL(cont.FirstName + ' ' + cont.LastName, '') AS CustomerContactName,
				posadd.SiteName AS ShipToSiteName,
				posadd.Line1 AS ShipToAddress1,
				posadd.Line2 AS ShipToAddress2,
				posadd.City AS ShipToCity,
				posadd.StateOrProvince AS ShipToState,
				posadd.PostalCode AS ShipToPostalCode,
				posadd.Country AS ShipToCountry,
				posadd.ContactName AS ShipToContactName,
				sh.Name AS ShipViaName,
				soq.CreatedBy,
				soq.CreatedDate,
				soq.UpdatedBy,
				soq.UpdatedDate,
				soq.ManagementStructureId,
				soq.CustomerReference,
				ISNULL(sos.PackagingSlipNotes,'') AS PackagingSlipNotes,
				ISNULL(allShipVia.ShippingTerms, '-') AS ShippingTerms
			FROM [dbo].[ExchangeSOPickTicket] sopkt WITH(NOLOCK)
			INNER JOIN [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK) ON sopkt.ExchangeSalesOrderId = soq.ExchangeSalesOrderId
			INNER JOIN [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK) ON soq.ExchangeSalesOrderId = part.ExchangeSalesOrderId
			LEFT JOIN [dbo].[Vendor] cust WITH(NOLOCK) ON soq.CustomerId = cust.VendorId
			LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
			LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
			INNER JOIN [dbo].[VendorContact] cust_cont WITH(NOLOCK) ON soq.CustomerContactId = cust_cont.VendorContactId
			LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
			LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON soq.ExchangeSalesOrderId = posadd.ReffranceId 
				AND posadd.IsShippingAdd = 1 
				AND posadd.ModuleId = CAST((SELECT CAST(ModuleId AS INT) FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder') AS BIGINT) 
			LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON soq.ExchangeSalesOrderId = posv.ReferenceId AND posv.ModuleId = CAST((SELECT CAST(ModuleId AS INT) FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder') AS BIGINT)
			LEFT JOIN [dbo].[ExchangeSalesOrderPackaginSlipItems] spi WITH(NOLOCK) ON sopkt.SOPickTicketId = spi.SOPickTicketId
			LEFT JOIN [dbo].[ExchangeSalesOrderPackaginSlipHeader] spb WITH(NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId
			LEFT JOIN [dbo].[ExchangeSalesOrderShippingItem] sosi WITH(NOLOCK) ON sopkt.SOPickTicketId = sosi.SOPickTicketId
			LEFT JOIN [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK) ON sosi.ExchangeSalesOrderShippingId = sos.ExchangeSalesOrderShippingId
			LEFT JOIN [dbo].[Employee] saemp WITH(NOLOCK) ON soq.SalesPersonId = saemp.EmployeeId
			LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
			LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
			LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] ebi WITH(NOLOCK) ON sos.ExchangeSalesOrderShippingId = ebi.ExchangeSalesOrderShippingId AND ebi.IsDeleted = 0
			LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] eb WITH(NOLOCK) ON ebi.SOBillingInvoicingId = eb.SOBillingInvoicingId
			LEFT JOIN [dbo].[ShippingVia] sh WITH(NOLOCK) ON sos.ShipviaId = sh.ShippingViaId
			LEFT JOIN [dbo].[AllShipVia] allShipVia WITH(NOLOCK) ON soq.ExchangeSalesOrderId = allShipVia.ReferenceId AND allShipVia.ModuleId = CAST((SELECT CAST(ModuleId AS INT) FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder') AS BIGINT)
			WHERE sopkt.ExchangeSalesOrderId = @ExchangeId
			  AND sopkt.ExchangeSalesOrderPartId = @SalesOrderPartId
			  AND ISNULL(ebi.IsDeleted,0) = 0;
		END
		ELSE
		BEGIN
			SELECT TOP 1
				sopkt.SOPickTicketId,
				ISNULL(spb.PackagingSlipNo, '') AS PackagingSlipNo,
				soq.ExchangeSalesOrderId,
				soq.ExchangeSalesOrderNumber,
				ISNULL(eb.InvoiceNo, '') AS InvoiceNo,
				eb.InvoiceDate,
				ISNULL(sos.NoOfContainer, 0) AS NoOfContainer,
				sos.ShipDate,
				ISNULL(sos.AirwayBill, '') AS AWB,
				ISNULL(sos.SOShippingNum, '') AS ShippingOrderNo,
				ISNULL(saemp.FirstName + ' ' + saemp.LastName, '') AS SalesPersonName,
				ISNULL(po.PurchaseOrderNumber, '') + CASE WHEN ro.RepairOrderNumber IS NULL THEN '' ELSE '/' + ro.RepairOrderNumber END AS PORONum,
				soq.CustomerId,
				soq.CreditTermName AS CreditTerm,
				ISNULL(cust.Name, '') AS CustomerName,
				ISNULL(cust.CustomerCode, '') AS CustomerCode,
				ISNULL(cuad.Line1, '') AS CustToAddress1,
				ISNULL(cuad.Line2, '') AS CustToAddress2,
				ISNULL(cuad.City, '') AS CustToCity,
				ISNULL(cuad.StateOrProvince, '') AS CustToState,
				ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
				ISNULL(ccnty.countries_name, '') AS CustToCountry,
				ISNULL(cont.FirstName + ' ' + cont.LastName, '') AS CustomerContactName,
				posadd.SiteName AS ShipToSiteName,
				posadd.Line1 AS ShipToAddress1,
				posadd.Line2 AS ShipToAddress2,
				posadd.City AS ShipToCity,
				posadd.StateOrProvince AS ShipToState,
				posadd.PostalCode AS ShipToPostalCode,
				posadd.Country AS ShipToCountry,
				posadd.ContactName AS ShipToContactName,
				sh.Name AS ShipViaName,
				soq.CreatedBy,
				soq.CreatedDate,
				soq.UpdatedBy,
				soq.UpdatedDate,
				soq.ManagementStructureId,
				soq.CustomerReference,
				ISNULL(sos.PackagingSlipNotes,'') AS PackagingSlipNotes,
				ISNULL(allShipVia.ShippingTerms, '-') AS ShippingTerms
			FROM [dbo].[ExchangeSOPickTicket] sopkt WITH(NOLOCK)
			INNER JOIN [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK) ON sopkt.ExchangeSalesOrderId = soq.ExchangeSalesOrderId
			INNER JOIN [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK) ON soq.ExchangeSalesOrderId = part.ExchangeSalesOrderId
			LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
			LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
			LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
			INNER JOIN [dbo].[CustomerContact] cust_cont WITH(NOLOCK)  ON soq.CustomerContactId = cust_cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
			LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON soq.ExchangeSalesOrderId = posadd.ReffranceId 
				AND posadd.IsShippingAdd = 1 
				AND posadd.ModuleId = CAST((SELECT CAST(ModuleId AS INT) FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder') AS BIGINT)
			LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON soq.ExchangeSalesOrderId = posv.ReferenceId AND posv.ModuleId = CAST((SELECT CAST(ModuleId AS INT) FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder') AS BIGINT)
			LEFT JOIN [dbo].[ExchangeSalesOrderPackaginSlipItems] spi WITH(NOLOCK) ON sopkt.SOPickTicketId = spi.SOPickTicketId
			LEFT JOIN [dbo].[ExchangeSalesOrderPackaginSlipHeader] spb WITH(NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId
			LEFT JOIN [dbo].[ExchangeSalesOrderShippingItem] sosi WITH(NOLOCK) ON sopkt.SOPickTicketId = sosi.SOPickTicketId
			LEFT JOIN [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK) ON sosi.ExchangeSalesOrderShippingId = sos.ExchangeSalesOrderShippingId
			LEFT JOIN [dbo].[Employee] saemp WITH(NOLOCK) ON soq.SalesPersonId = saemp.EmployeeId
			LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
			LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
			LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] ebi WITH(NOLOCK) ON sos.ExchangeSalesOrderShippingId = ebi.ExchangeSalesOrderShippingId AND ebi.IsDeleted = 0
			LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] eb WITH(NOLOCK) ON ebi.SOBillingInvoicingId = eb.SOBillingInvoicingId
			LEFT JOIN [dbo].[ShippingVia] sh WITH(NOLOCK) ON sos.ShipviaId = sh.ShippingViaId
			LEFT JOIN [dbo].[AllShipVia] allShipVia WITH(NOLOCK) ON soq.ExchangeSalesOrderId = allShipVia.ReferenceId AND allShipVia.ModuleId = CAST((SELECT CAST(ModuleId AS INT) FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder') AS BIGINT)
			WHERE sopkt.ExchangeSalesOrderId = @ExchangeId
			  AND sopkt.ExchangeSalesOrderPartId = @SalesOrderPartId
			  AND ISNULL(ebi.IsDeleted,0) = 0;
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderPackagingLabelBySalesOrderId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeId = ''' + CAST(ISNULL(@ExchangeId, '') AS VARCHAR(100))+'''+,
													@SalesOrderPartId = ''' + CAST(ISNULL(@SalesOrderPartId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END