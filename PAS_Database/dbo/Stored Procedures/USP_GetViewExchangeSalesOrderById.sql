/*************************************************************           
 ** File:   [USP_GetViewExchangeSalesOrderById]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetViewExchangeSalesOrderById
 ** Purpose:         
 ** Date:    06/02/2025  

 ** PARAMETERS: @ExchangeSalesOrderId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    06/02/2025  EKTA CHANDEGRA    Created
	     
 EXEC USP_GetViewExchangeSalesOrderById @ExchangeSalesOrderId = 150 
************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetViewExchangeSalesOrderById]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ExchangeModuleId BIGINT, @ExchangeManagementStructureModuleId INT;
		SELECT @ExchangeModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';  		
		SELECT @ExchangeManagementStructureModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSOHeader';  		
		SELECT
			ISNULL(leg.Name, '') AS CompanyName,
			ISNULL(add1.Line1, '') AS ComAddress1,
			ISNULL(add1.Line2, '') AS ComAddress2,
			ISNULL(add1.City, '') AS ComCity,
			ISNULL(add1.StateOrProvince, '') AS ComState,
			ISNULL(add1.PostalCode, '') AS ComPostalCode,
			ISNULL(ccon.countries_name, '') AS ComCountry,
			ISNULL(leg.PhoneNumber, '') AS ComPhoneNo,

			soq.ExchangeSalesOrderId,
			ISNULL(soq.ExchangeQuoteId,0) AS ExchangeQuoteId,
			ISNULL(exq.ExchangeQuoteNumber,'') AS ExchangeQuoteNumber,
			ISNULL(soq.ExchangeSalesOrderNumber,'') AS ExchangeSalesOrderNumber,
			soq.OpenDate,
			soq.TypeName,
			soq.CustomerId,
			soq.CustomerName,
			soq.CustomerCode,

			ISNULL(cuad.Line1, '') AS CustToAddress1,
			ISNULL(cuad.Line2, '') AS CustToAddress2,
			ISNULL(cuad.City, '') AS CustToCity,
			ISNULL(cuad.StateOrProvince, '') AS CustToState,
			ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
			ISNULL(cts.countries_name, '') AS CustToCountry,

			soq.CustomerContactId,
			CASE WHEN soq.IsVendor = 1 THEN CONCAT(vcont.FirstName, ' ', vcont.LastName) ELSE CONCAT(cont.FirstName, ' ', cont.LastName) END AS CustomerContactName,
			CASE WHEN soq.IsVendor = 1 THEN vcont.Email ELSE cont.Email END AS CustomerContactEmail,

			cust.CustomerPhone,
			soq.CustomerReference,

			ISNULL(CONCAT(saemp.FirstName, ' ', saemp.LastName), '') AS SalesPersonName,
			ISNULL(CONCAT(saremp.FirstName, ' ', saremp.LastName), '') AS CustomerSeviceRepName,
			soq.CreditLimit,
			ISNULL(soq.CreditLimitName,'') AS CreditLimitName,
			soq.CreditTermName,
			ISNULL(CONCAT(emp.FirstName, ' ', emp.LastName), '') AS EmployeeName,
			soq.RestrictPMA,
			soq.RestrictDER,
			soq.BalanceDue,

			CASE WHEN soq.IsVendor = 1 THEN vaty.VendorTypeName ELSE aty.CustomerTypeName END AS AccountTypeName,

			soq.Memo,
			soq.Notes,

			ISNULL(sAddress.SiteId, 0) AS ShipToSiteId,
			sAddress.SiteName,
			sAddress.Line1 AS ShipToAddress1,
			sAddress.Line2 AS ShipToAddress2,
			sAddress.Line3 AS ShipToAddress3,
			sAddress.City AS ShipToCity,
			sAddress.StateOrProvince AS ShipToState,
			sAddress.PostalCode AS ShipToPostalCode,
			sAddress.CountryId AS ShipToCountryId,
			sAddress.Country AS ShipToCountry,
			sAddress.ContactName AS ShipToContactName,

			allShipVia.ShipVia AS ShipViaName,
			allShipVia.ShippingAccountNo AS ShipViaShippingAccountInfo,
			sAddress.Memo AS ShipViaMemo,

			bAddress.SiteName AS BillToSiteName,
			bAddress.Line1 AS BillToAddress1,
			bAddress.Line2 AS BillToAddress2,
			bAddress.City AS BillToCity,
			bAddress.StateOrProvince AS BillToState,
			bAddress.PostalCode AS BillToPostalCode,
			bAddress.CountryId AS BillToCountryId,
			bAddress.Country AS BillToCountry,
			bAddress.ContactName AS BillToContactName,
			bAddress.Memo AS BillToMemo,

			soq.CreatedBy,
			soq.CreatedDate,
			soq.UpdatedBy,
			soq.UpdatedDate,
			ISNULl(soq.IsDeleted,0) AS IsDeleted,
			ISNULL(soq.IsActive,0) AS IsActive,
			es.Name AS Status,
			soq.StatusChangeDate,
			soq.ManagementStructureId,

			sAddress.UserTypeName AS ShipToUserType,
			sAddress.UserName AS ShipToUser,
			bAddress.UserTypeName AS BillToUserType,
			bAddress.UserName AS BillToUser,

			soq.Version,
			soq.VersionNumber,

			custfc.CurrencyId,
			ISNULL(curc.Code, '') AS CurrencyName,


			ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
			ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
			ISNULL(msd.AllMSlevels, '') AS AllMSlevels,

			ISNULL(allShipVia.ShippingTerms, '') AS ShippingTerms,
			ISNULL(fcu.Code, '') AS FunctionalCurrency,
			ISNULL(rcu.Code, '') AS ReportCurrency,
			CASE WHEN soq.ForeignExchangeRate > 0 THEN soq.ForeignExchangeRate ELSE 0 END AS ForeignExchangeRate

		FROM [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK)
		LEFT JOIN [dbo].[ExchangeManagementStructureDetails] msd WITH(NOLOCK)
			ON soq.ExchangeSalesOrderId = msd.ReferenceID AND msd.ModuleID = @ExchangeManagementStructureModuleId -- ExchangeSOHeader
		LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msd.Level1Id = msl.ID
		LEFT JOIN [dbo].[LegalEntity] leg WITH(NOLOCK) ON msl.LegalEntityId = leg.LegalEntityId
		LEFT JOIN [dbo].[Address] add1 WITH(NOLOCK) ON leg.AddressId = add1.AddressId
		LEFT JOIN [dbo].[Countries] ccon WITH(NOLOCK) ON add1.CountryId = ccon.countries_id

		LEFT JOIN [dbo].[AllAddress] sAddress WITH(NOLOCK)
			ON soq.ExchangeSalesOrderId = sAddress.ReffranceId 
		   AND sAddress.ModuleId = @ExchangeModuleId AND sAddress.IsShippingAdd = 1

		LEFT JOIN [dbo].[AllAddress] bAddress WITH(NOLOCK)
			ON soq.ExchangeSalesOrderId = bAddress.ReffranceId 
		   AND bAddress.ModuleId = @ExchangeModuleId AND bAddress.IsShippingAdd = 0

		LEFT JOIN [dbo].[AllShipVia] allShipVia WITH(NOLOCK)
			ON soq.ExchangeSalesOrderId = allShipVia.ReferenceId AND allShipVia.ModuleId = @ExchangeModuleId

		LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
		LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
		LEFT JOIN [dbo].[Countries] cts WITH(NOLOCK) ON cuad.CountryId = cts.countries_id

		LEFT JOIN [dbo].[CustomerContact] custc WITH(NOLOCK) ON soq.CustomerContactId = custc.CustomerContactId
		LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON custc.ContactId = cont.ContactId
		LEFT JOIN [dbo].[ExchangeStatus] es WITH(NOLOCK) ON soq.StatusId = es.ExchangeStatusId

		LEFT JOIN [dbo].[Employee] saemp WITH(NOLOCK) ON soq.SalesPersonId = saemp.EmployeeId
		LEFT JOIN [dbo].[Employee] saremp WITH(NOLOCK) ON soq.CustomerSeviceRepId = saremp.EmployeeId
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON soq.EmployeeId = emp.EmployeeId

		LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON soq.CurrencyId = cur.CurrencyId
		LEFT JOIN [dbo].[CustomerType] aty WITH(NOLOCK) ON soq.AccountTypeId = aty.CustomerTypeId
		LEFT JOIN [dbo].[ExchangeQuote] exq WITH(NOLOCK) ON soq.ExchangeQuoteId = exq.ExchangeQuoteId

		LEFT JOIN [dbo].[CustomerFinancial] custfc WITH(NOLOCK) ON cust.CustomerId = custfc.CustomerId
		LEFT JOIN [dbo].[Currency] curc WITH(NOLOCK) ON custfc.CurrencyId = curc.CurrencyId

		LEFT JOIN [dbo].[VendorContact] vendc WITH(NOLOCK) ON soq.CustomerContactId = vendc.VendorContactId
		LEFT JOIN [dbo].[Contact] vcont WITH(NOLOCK) ON vendc.ContactId = vcont.ContactId
		LEFT JOIN [dbo].[VendorType] vaty WITH(NOLOCK) ON soq.AccountTypeId = vaty.VendorTypeId

		LEFT JOIN [dbo].[Currency] fcu WITH(NOLOCK) ON soq.FunctionalCurrencyId = fcu.CurrencyId AND ISNULL(fcu.IsActive,0) = 1 AND ISNULL(fcu.IsDeleted,0) = 0
		LEFT JOIN [dbo].[Currency] rcu WITH(NOLOCK) ON soq.ReportCurrencyId = rcu.CurrencyId AND ISNULL(rcu.IsActive,0) = 1 AND ISNULL(rcu.IsDeleted,0) = 0

		WHERE soq.ExchangeSalesOrderId = @ExchangeSalesOrderId
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetViewExchangeSalesOrderById'     
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