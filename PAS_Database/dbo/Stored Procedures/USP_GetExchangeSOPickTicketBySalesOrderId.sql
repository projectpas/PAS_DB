/*************************************************************           
 ** File:   [USP_GetExchangeSOPickTicketBySalesOrderId]           
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeSOPickTicketBySalesOrderId
 ** Purpose:         
 ** Date:    05/30/2025  

 ** PARAMETERS: @ExchangeId BIGINT,@SOPickTicketId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    05/30/2025  EKTA CHANDEGRA    Created
	     
-- EXEC USP_GetExchangeSOPickTicketBySalesOrderId @ExchangeId = 160 , @SOPickTicketId = 103
************************************************************************/   
CREATE   PROCEDURE [dbo].[USP_GetExchangeSOPickTicketBySalesOrderId]
    @ExchangeId BIGINT,
    @SOPickTicketId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @IsVendor BIT;
		DECLARE @ExchangeModuleId BIGINT;

		-- Determine if the customer is a vendor
		SELECT @IsVendor = 
			CASE 
				WHEN IsVendor IS NOT NULL THEN CAST(IsVendor AS BIT) 
				ELSE 0 
			END
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeId;

		SELECT @ExchangeModuleId =  [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		
		-- Vendor block
		IF @IsVendor = 1
		BEGIN
			SELECT TOP 1
				sopkt.SOPickTicketId,
				sopkt.SOPickTicketNumber,
				soq.ExchangeSalesOrderId,
				soq.ExchangeQuoteId,
				soq.ExchangeSalesOrderNumber,
				soq.ShippedDate,
				soq.NumberOfItems,
				soq.CustomerId,
				ISNULL(v.VendorName, '') AS CustomerName,
				ISNULL(v.VendorCode, '') AS CustomerCode,
				ISNULL(ca.Line1, '') AS CustToAddress1,
				ISNULL(ca.Line2, '') AS CustToAddress2,
				ISNULL(ca.City, '') AS CustToCity,
				ISNULL(ca.StateOrProvince, '') AS CustToState,
				ISNULL(ca.PostalCode, '') AS CustToPostalCode,
				ISNULL(cn.countries_name, '') AS CustToCountry,
				ISNULL(CONCAT(c.FirstName, ' ', c.LastName), '') AS CustomerContactName,
				ISNULL(shipadd.SiteName, '') AS ShipToSiteName,
				ISNULL(shipadd.Line1, '') AS ShipToAddress1,
				ISNULL(shipadd.Line2, '') AS ShipToAddress2,
				ISNULL(shipadd.City, '') AS ShipToCity,
				ISNULL(shipadd.StateOrProvince, '') AS ShipToState,
				ISNULL(shipadd.PostalCode, '') AS ShipToPostalCode,
				ISNULL(shipadd.Country, '') AS ShipToCountry,
				ISNULL(shipadd.ContactName, '') AS ShipToContactName,
				ISNULL(shipvia.ShipVia, '') AS ShipViaName,
				soq.CreatedBy,
				soq.CreatedDate,
				soq.UpdatedBy,
				soq.UpdatedDate,
				soq.ManagementStructureId,
				soq.QtyRequested,
				soq.QtyToBeQuoted,
				ISNULL(CONCAT(pickemp.FirstName, ' ', pickemp.LastName), '') AS PickedByName,
				sopkt.CreatedDate AS PickedDate,
				ISNULL(CONCAT(confirmemp.FirstName, ' ', confirmemp.LastName), '') AS ConfirmedByName,
				sopkt.ConfirmedDate,
				sopkt.CreatedDate AS PTCreatedDate,
				soq.Notes
			FROM [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK)
			LEFT JOIN [dbo].[ExchangeSOPickTicket] sopkt WITH(NOLOCK) ON soq.ExchangeSalesOrderId = sopkt.ExchangeSalesOrderId AND sopkt.SOPickTicketId = @SOPickTicketId
			LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON soq.CustomerId = v.VendorId
			LEFT JOIN [dbo].[Address] ca WITH(NOLOCK) ON v.AddressId = ca.AddressId
			LEFT JOIN [dbo].[Countries] cn WITH(NOLOCK) ON ca.CountryId = cn.countries_id
			LEFT JOIN [dbo].[VendorContact] vc WITH(NOLOCK) ON soq.CustomerContactId = vc.VendorContactId
			LEFT JOIN [dbo].[Contact] c WITH(NOLOCK) ON vc.ContactId = c.ContactId
			LEFT JOIN [dbo].[AllAddress] shipadd WITH(NOLOCK) ON soq.ExchangeSalesOrderId = shipadd.ReffranceId AND shipadd.IsShippingAdd = 1 AND shipadd.ModuleId = @ExchangeModuleId 
			LEFT JOIN [dbo].[AllShipVia] shipvia WITH(NOLOCK) ON soq.ExchangeSalesOrderId = shipvia.ReferenceId AND shipvia.ModuleId = @ExchangeModuleId
			LEFT JOIN [dbo].[Employee] pickemp WITH(NOLOCK) ON sopkt.PickedById = pickemp.EmployeeId
			LEFT JOIN [dbo].[Employee] confirmemp WITH(NOLOCK) ON sopkt.ConfirmedById = confirmemp.EmployeeId
			WHERE sopkt.ExchangeSalesOrderId = @ExchangeId;
		END
		ELSE
		BEGIN
			-- Customer block
			SELECT TOP 1
				sopkt.SOPickTicketId,
				sopkt.SOPickTicketNumber,
				soq.ExchangeSalesOrderId,
				soq.ExchangeQuoteId,
				soq.ExchangeSalesOrderNumber,
				soq.ShippedDate,
				soq.NumberOfItems,
				soq.CustomerId,
				ISNULL(cust.Name, '') AS CustomerName,
				ISNULL(cust.CustomerCode, '') AS CustomerCode,
				ISNULL(ca.Line1, '') AS CustToAddress1,
				ISNULL(ca.Line2, '') AS CustToAddress2,
				ISNULL(ca.City, '') AS CustToCity,
				ISNULL(ca.StateOrProvince, '') AS CustToState,
				ISNULL(ca.PostalCode, '') AS CustToPostalCode,
				ISNULL(cn.countries_name, '') AS CustToCountry,
				ISNULL(CONCAT(c.FirstName, ' ', c.LastName), '') AS CustomerContactName,
				ISNULL(shipadd.SiteName, '') AS ShipToSiteName,
				ISNULL(shipadd.Line1, '') AS ShipToAddress1,
				ISNULL(shipadd.Line2, '') AS ShipToAddress2,
				ISNULL(shipadd.City, '') AS ShipToCity,
				ISNULL(shipadd.StateOrProvince, '') AS ShipToState,
				ISNULL(shipadd.PostalCode, '') AS ShipToPostalCode,
				ISNULL(shipadd.Country, '') AS ShipToCountry,
				ISNULL(shipadd.ContactName, '') AS ShipToContactName,
				ISNULL(shipvia.ShipVia, '') AS ShipViaName,
				soq.CreatedBy,
				soq.CreatedDate,
				soq.UpdatedBy,
				soq.UpdatedDate,
				soq.ManagementStructureId,
				soq.QtyRequested,
				soq.QtyToBeQuoted,
				ISNULL(CONCAT(pickemp.FirstName, ' ', pickemp.LastName), '') AS PickedByName,
				sopkt.CreatedDate AS PickedDate,
				ISNULL(CONCAT(confirmemp.FirstName, ' ', confirmemp.LastName), '') AS ConfirmedByName,
				sopkt.ConfirmedDate,
				sopkt.CreatedDate AS PTCreatedDate,
				soq.Notes
			FROM [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK)
			LEFT JOIN [dbo].[ExchangeSOPickTicket] sopkt WITH(NOLOCK) ON soq.ExchangeSalesOrderId = sopkt.ExchangeSalesOrderId AND sopkt.SOPickTicketId = @SOPickTicketId
			LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
			LEFT JOIN [dbo].[Address] ca WITH(NOLOCK) ON cust.AddressId = ca.AddressId
			LEFT JOIN [dbo].[Countries] cn WITH(NOLOCK) ON ca.CountryId = cn.countries_id
			INNER JOIN [dbo].[CustomerContact] cc WITH(NOLOCK) ON soq.CustomerContactId = cc.CustomerContactId
			LEFT JOIN [dbo].[Contact] c WITH(NOLOCK) ON cc.ContactId = c.ContactId
			LEFT JOIN [dbo].[AllAddress] shipadd WITH(NOLOCK) ON soq.ExchangeSalesOrderId = shipadd.ReffranceId AND shipadd.IsShippingAdd = 1 AND shipadd.ModuleId = @ExchangeModuleId
			LEFT JOIN [dbo].[AllShipVia] shipvia WITH(NOLOCK) ON soq.ExchangeSalesOrderId = shipvia.ReferenceId AND shipvia.ModuleId = @ExchangeModuleId
			LEFT JOIN [dbo].[Employee] pickemp WITH(NOLOCK) ON sopkt.PickedById = pickemp.EmployeeId
			LEFT JOIN [dbo].[Employee] confirmemp WITH(NOLOCK) ON sopkt.ConfirmedById = confirmemp.EmployeeId
			WHERE sopkt.ExchangeSalesOrderId = @ExchangeId;
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSOPickTicketBySalesOrderId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeId = ''' + CAST(ISNULL(@ExchangeId, '') AS VARCHAR(100)) + ''',
												    @SOPickTicketId = ''' + CAST(ISNULL(@SOPickTicketId, '') AS VARCHAR(100))  
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