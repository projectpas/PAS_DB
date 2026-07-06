/*************************************************************           
 ** File:   [GetExchangeBillingDetailsById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeBillingDetailsById
 ** Purpose:         
 ** Date:   06/06/2025      
          
 ** PARAMETERS: @ExchangeSalesOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/06/2025   Ekta Chandegra     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
-- EXEC GetExchangeBillingDetailsById @ExchangeSalesOrderId=150
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeBillingDetailsById]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ExchangeSalesOrderModuleId BIGINT;
		SELECT @ExchangeSalesOrderModuleId = ModuleId FROM [dbo].[Module] WHERE ModuleName = 'ExchangeSalesOrder';
		SELECT TOP 1
			soq.ExchangeSalesOrderId,
			soq.ExchangeQuoteId,
			soq.ExchangeSalesOrderNumber,
			soq.CustomerId,
			ISNULL(cust.Name, '') AS CustomerName,
			ISNULL(cust.CustomerCode, '') AS CustomerCode,
			ISNULL(cuad.Line1, '') AS CustToAddress1,
			ISNULL(cuad.Line2, '') AS CustToAddress2,
			ISNULL(cuad.City, '') AS CustToCity,
			ISNULL(cuad.StateOrProvince, '') AS CustToState,
			ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
			ISNULL(ccnty.countries_name, '') AS CustToCountry,
			ISNULL(cont.FirstName, '') + ' ' + ISNULL(cont.LastName, '') AS CustomerContactName,
			ISNULL(cust.Email, '') AS CustEmail,
			ISNULL(cust.CustomerPhone, '') AS CustomerPhone,
			ISNULL(posadd.SiteId, 0) AS ShipToSiteId,
			posadd.SiteName AS ShipToSiteName,
			posadd.Line1 AS ShipToAddress1,
			posadd.Line2 AS ShipToAddress2,
			posadd.City AS ShipToCity,
			posadd.StateOrProvince AS ShipToState,
			posadd.PostalCode AS ShipToPostalCode,
			posadd.Country AS ShipToCountry,
			saos.ShippingAccountNo AS ShipAccNumber,
			posadd.ContactName AS ShipToContactName,
			posv.ShipVia AS ShipViaName,
			soq.CreatedBy,
			soq.CreatedDate,
			soq.UpdatedBy,
			soq.UpdatedDate,
			soq.ManagementStructureId,
			im.PartNumber,
			im.PartDescription,
			sl.SerialNumber,
			mf.Name AS Manufacurer,
			cn.Description AS ConditionName,
			ISNULL(sp.FirstName, '') + ' ' + ISNULL(sp.LastName, '') AS SalesPerson,
			ISNULL(cont.FirstName, '') + ' ' + ISNULL(cont.LastName, '') AS BuyersName,
			soq.CreditTermName AS CreditTerms,
			soq.Notes AS SONotes,
			soq.CustomerReference AS PORONum,
			FORMAT(saos.ShipDate, 'MM/dd/yyyy') AS ShipDate,
			shipInfoVia.Name AS ShipVia,
			saos.SOShippingNum AS ShippingOrderNumber,
			saos.AirwayBill AS Awb,
			ISNULL(frt.MarkupFixedPrice, 0) AS Freight,
			ISNULL(chg.MarkupFixedPrice, 0) AS MiscCharges,
			ISNULL(allShipVia.ShippingTerms, '') AS ShippingTerms
		FROM [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK)
		LEFT JOIN  [dbo].[ExchangeSalesOrderPart] exp WITH(NOLOCK) ON soq.ExchangeSalesOrderId = exp.ExchangeSalesOrderId
		LEFT JOIN  [dbo].[ItemMaster] im WITH(NOLOCK) ON exp.ItemMasterId = im.ItemMasterId
		 AND ISNULL(im.IsNonStock,0) = 0
		 LEFT JOIN  [dbo].[StockLine] sl WITH(NOLOCK) ON exp.StockLineId = sl.StockLineId
		LEFT JOIN  [dbo].[Manufacturer] mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
		LEFT JOIN  [dbo].[Condition] cn WITH(NOLOCK) ON exp.ConditionId = cn.ConditionId
		LEFT JOIN  [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
		LEFT JOIN  [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
		LEFT JOIN  [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
		LEFT JOIN  [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON soq.CustomerContactId = cust_cont.CustomerContactId
		LEFT JOIN  [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
		LEFT JOIN  [dbo].[AllAddress] posadd WITH(NOLOCK) ON soq.ExchangeSalesOrderId = posadd.ReffranceId 
			AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @ExchangeSalesOrderModuleId 
		LEFT JOIN  [dbo].[AllShipVia] posv WITH(NOLOCK) ON soq.ExchangeSalesOrderId = posv.ReferenceId 
			AND posv.ModuleId = @ExchangeSalesOrderModuleId
		LEFT JOIN  [dbo].[Employee] sp WITH(NOLOCK) ON soq.SalesPersonId = sp.EmployeeId
		LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
		LEFT JOIN  [dbo].[ExchangeSalesOrderShipping] saos WITH(NOLOCK) ON soq.ExchangeSalesOrderId = saos.ExchangeSalesOrderId
		LEFT JOIN  [dbo].[ShippingVia] shipInfoVia WITH(NOLOCK) ON saos.ShipviaId = shipInfoVia.ShippingViaId
		LEFT JOIN  [dbo].[Countries] shipToCountry WITH(NOLOCK) ON saos.ShipToCountryId = shipToCountry.countries_id
		LEFT JOIN  [dbo].[AllShipVia] allShipVia WITH(NOLOCK) ON soq.ExchangeSalesOrderId = allShipVia.ReferenceId 
			AND allShipVia.ModuleId = @ExchangeSalesOrderModuleId
		LEFT JOIN (
			SELECT ExchangeSalesOrderId, MarkupFixedPrice
			FROM  [dbo].[ExchangeSalesOrderFreight] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
		) frt  ON soq.ExchangeSalesOrderId = frt.ExchangeSalesOrderId
		LEFT JOIN (
			SELECT ExchangeSalesOrderId, MarkupFixedPrice
			FROM  [dbo].[ExchangeSalesOrderCharges] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
		) chg ON soq.ExchangeSalesOrderId = chg.ExchangeSalesOrderId
		WHERE soq.ExchangeSalesOrderId = @ExchangeSalesOrderId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeBillingDetailsById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100))
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