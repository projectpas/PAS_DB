/*************************************************************             
 ** File:   [GetSalesOrderDetailsById]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderDetailsById
 ** Purpose:           
 ** Date:  05/12/2024        
            
 ** PARAMETERS: @SalesOrderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    05/12/2024		EKTA CHANDEGRA	 Created  
	2	 04/25/2025     Bhargav Saliya   Customer Name Get from the SO table instead of the Customer table
    3    07/May/2026	Rajesh Gami	     ARBalance Getting From New Table CustomerAging Instead Of CustomerCreditTermsHistory [PN-16092]
	4    19/JUN/2026    AMIT GHEDIYA	 Get [MarketplaceRef] data [PN-16922]
 EXEC GetSalesOrderDetailsById 1484 
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetSalesOrderDetailsById]
    @SalesOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;    
	BEGIN TRY 
		DECLARE @SalesOrderModuleId BIGINT = 10;
		DECLARE @SalesOrderManagementStructureModuleId BIGINT = 17;
				
		BEGIN
			SELECT
        soq.SalesOrderId,
        soq.SalesOrderQuoteId,
        soq.SalesOrderNumber,
        soq.ATAPDFPath,
        soq.COCManufacturingPDFPath,
        soq.StatusId,
        ISNULL(soqt.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
        ISNULL(qty.Name, '') AS TypeName,
        soq.OpenDate,
        ISNULL(soq.ShippedDate,'') AS ShippedDate , 
        soq.NumberOfItems,
        soq.AccountTypeName,
        soq.CustomerId,
        ISNULL(soq.CustomerName, '') AS CustomerName,
        ISNULL(cust.CustomerCode, '') AS CustomerCode,
        ISNULL(cuad.Line1, '') AS CustToAddress1,
        ISNULL(cuad.Line2, '') AS CustToAddress2,
        ISNULL(cuad.City, '') AS CustToCity,
        ISNULL(cuad.StateOrProvince, '') AS CustToState,
        ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
        ISNULL(ccnty.countries_name, '') AS CustToCountry,
        ISNULL(CONCAT(cont.FirstName, ' ', cont.LastName), '') AS CustomerContactName,
        soq.CustomerReference,
        soq.CustomerContactId,
        ISNULL(CONCAT(saemp.FirstName, ' ', saemp.LastName), '') AS SalesPersonName,
        ISNULL(CONCAT(saremp.FirstName, ' ', saremp.LastName), '') AS CustomerSeviceRepName,
        soq.CreditLimit,
        soq.CreditLimitName,
        soq.CreditTermName AS CreditTerms,
        soq.TotalSalesAmount,
        soq.CustomerHold,
        soq.DepositAmount,
        ISNULL((SELECT TOP 1 TotalOutstanding
                FROM [dbo].CustomerAging WITH(NOLOCK) 
                WHERE CustomerId = soq.CustomerId
                ORDER BY CustomerAgingId DESC), 0) AS BalanceDue,
        custfc.CurrencyId,
        ISNULL(cur.Code, '') AS CurrencyName,
        soq.ApprovedDate,
        ISNULL(qst.Name, '') AS Status,
        soq.StatusChangeDate,
        ISNULL(CONCAT(emp.FirstName, ' ', emp.LastName), '') AS EmployeeName,
        soq.RestrictPMA,
        soq.RestrictDER,
        soq.Memo,
        soq.Notes,
        ISNULL(cuwa.WarningMessage, '') AS CustomerWarningMessage,
        posadd.SiteId AS ShipToSiteId,
        posadd.SiteName AS ShipToSiteName,
        posadd.Line1 AS ShipToAddress1,
        posadd.Line2 AS ShipToAddress2,
        posadd.Line3 AS ShipToAddress3,
        posadd.City AS ShipToCity,
        posadd.StateOrProvince AS ShipToState,
        posadd.PostalCode AS ShipToPostalCode,
        ISNULL(posadd.Country, '') AS ShipToCountry,
        ISNULL(posadd.ContactName, '') AS ShipToContactName,
        posadd.Memo AS ShipToMemo,
        posv.ShipVia AS ShipViaName,
        posv.ShippingAccountNo AS ShipViaShippingAccountInfo,
        posv.ShippingCost,
        posv.HandlingCost,
        pobadd.SiteName AS BillToSiteName,
        pobadd.Line1 AS BillToAddress1,
        pobadd.Line2 AS BillToAddress2,
        pobadd.Line3 AS BillToAddress3,
        pobadd.City AS BillToCity,
        pobadd.StateOrProvince AS BillToState,
        pobadd.PostalCode AS BillToPostalCode,
        ISNULL(pobadd.Country, '') AS BillToCountry,
        ISNULL(pobadd.ContactName, '') AS BillToContactName,
        pobadd.Memo AS BillToMemo,
        soq.CreatedBy,
        soq.CreatedDate,
        soq.UpdatedBy,
        soq.UpdatedDate,
        soq.IsDeleted,
        soq.ManagementStructureId,
        posadd.UserTypeName AS ShipToUserType,
        posadd.UserName AS ShipToUser,
        pobadd.UserTypeName AS BillToUserType,
        pobadd.UserName AS BillToUser,
        soq.Version,
        soq.VersionNumber,
        soq.QtyRequested,
        soq.QtyToBeQuoted,
        ISNULL(cont.Email, '') AS CustomerContactEmail,
        (SELECT SUM(ta.TaxRate)
         FROM [dbo].[CustomerTaxTypeRateMapping] cta WITH(NOLOCK)
         LEFT JOIN [dbo].[TaxRate] ta WITH(NOLOCK) ON cta.TaxRateId = ta.TaxRateId
         WHERE cta.CustomerId = soq.CustomerId) AS TaxRate,
        CONCAT(soq.SalesOrderNumber, '|', CAST(soq.Version AS VARCHAR(10))) AS BarCodePath,
        soq.ContractReference,
        soq.TotalFreight AS Freight,
        soq.TotalCharges AS MiscCharges,
        soq.FreightBilingMethodId AS HeaderMarkupIdFreight,
        soq.ChargesBilingMethodId AS HeaderMarkupIdCharge,
        soq.MasterCompanyId,
        emp.EmployeeId,
        ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
        ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
        ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
        posv.ShippingTerms,
        ISNULL(fcu.Code, '') AS FunctionalCurrency,
        ISNULL(rcu.Code, '') AS ReportCurrency,
        CASE 
            WHEN soq.ForeignExchangeRate > 0 THEN soq.ForeignExchangeRate 
            ELSE 0 
        END AS ForeignExchangeRate,
		soq.MarketplaceRef
			FROM [dbo].[SalesOrder] soq WITH(NOLOCK)
			LEFT JOIN [dbo].[SalesOrderQuote] soqt WITH(NOLOCK) ON soq.SalesOrderQuoteId = soqt.SalesOrderQuoteId
			LEFT JOIN [dbo].[MasterSalesOrderQuoteTypes] qty WITH(NOLOCK) ON soq.TypeId = qty.Id
			LEFT JOIN [dbo].[CustomerType] cty WITH(NOLOCK) ON soq.AccountTypeId = cty.CustomerTypeId
			LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
			LEFT JOIN [dbo].[CustomerFinancial] custfc WITH(NOLOCK) ON cust.CustomerId = custfc.CustomerId
			LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
			LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
			LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON soq.SalesOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @SalesOrderModuleId
			LEFT JOIN [dbo].[AllAddress] pobadd WITH(NOLOCK) ON soq.SalesOrderId = pobadd.ReffranceId AND pobadd.IsShippingAdd = 0 AND pobadd.ModuleId = @SalesOrderModuleId
			LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON soq.SalesOrderId = posv.ReferenceId AND posv.ModuleId = @SalesOrderModuleId
			LEFT JOIN [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON soq.CustomerContactId = cust_cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
			LEFT JOIN [dbo].[Employee] saemp WITH(NOLOCK) ON soq.SalesPersonId = saemp.EmployeeId
			LEFT JOIN [dbo].[Employee] saremp WITH(NOLOCK) ON soq.CustomerSeviceRepId = saremp.EmployeeId
			LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON soq.EmployeeId = emp.EmployeeId
			LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON custfc.CurrencyId = cur.CurrencyId
			LEFT JOIN [dbo].[MasterSalesOrderQuoteStatus] qst WITH(NOLOCK) ON soq.StatusId = qst.Id
			LEFT JOIN [dbo].[CustomerWarning] cuwa WITH(NOLOCK) ON soq.CustomerWarningId = cuwa.CustomerWarningId
			LEFT JOIN [dbo].[SalesOrderManagementStructureDetails] msd WITH(NOLOCK) ON soq.SalesOrderId = msd.ReferenceID AND msd.ModuleID = @SalesOrderManagementStructureModuleId
			LEFT JOIN [dbo].[Currency] fcu WITH(NOLOCK) ON soq.FunctionalCurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
			LEFT JOIN [dbo].[Currency] rcu WITH(NOLOCK) ON soq.ReportCurrencyId = rcu.CurrencyId AND rcu.IsActive = 1 AND rcu.IsDeleted = 0
			WHERE soq.SalesOrderId = @SalesOrderId
		END
    END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderDetailsById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''    
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END