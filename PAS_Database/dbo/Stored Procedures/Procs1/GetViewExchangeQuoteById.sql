/*************************************************************           
 ** File:   [GetViewExchangeQuoteById]           
 ** Author:   
 ** Description: This stored procedure is used to get ExchangeQuote View Data    
 ** Purpose:         
 ** Date:       
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    2    07/25/2024  Bhargav Saliya Get ShippingTerms

--EXEC [dbo].[GetViewExchangeQuoteById] 138
**************************************************************/ 
CREATE     PROCEDURE [dbo].[GetViewExchangeQuoteById]
	@ExchangeQuoteId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				SELECT leg.CompanyName AS CompanyName, [add].Line1 AS ComAddress1, [add].Line2 AS ComAddress2, [add].City AS ComCity, [add].StateOrProvince AS ComState,
				[add].PostalCode AS ComPostalCode, ccon.countries_name AS ComCountry, leg.PhoneNumber AS ComPhoneNo, soq.ExchangeQuoteId, soq.ExchangeQuoteNumber, soq.OpenDate,
				soq.QuoteExpireDate, soq.TypeName, soq.CustomerId, soq.CustomerName, soq.CustomerCode, soq.CustomerContactId, (cont.FirstName + ' ' + cont.LastName) AS CustomerContactName,
				soq.CustomerContactEmail, soq.CustomerReference, soq.SalesPersonName, soq.CustomerServiceRepName, cust.CustomerPhone, soq.CreditLimit, soq.CreditLimitName, soq.CreditTermName, 
				soq.CreditTermId, soq.ApprovedDate, soq.Notes, sAddress.SiteId AS ShipToSiteId, sAddress.SiteName AS ShipToSiteName, sAddress.Line1 AS ShipToAddress1, sAddress.Line2 AS ShipToAddress2, 
				sAddress.Line3 AS ShipToAddress3, sAddress.City AS ShipToCity, sAddress.StateOrProvince AS ShipToState, sAddress.PostalCode AS ShipToPostalCode, sAddress.CountryId AS ShipToCountryId,
				sAddress.Country AS ShipToCountry, sAddress.ContactName AS ShipToContactName, sa.Attention, allShipVia.ShipVia AS ShipViaName, allShipVia.ShippingAccountNo AS ShipViaShippingAccountInfo,
				sAddress.Memo AS ShipViaMemo, bAddress.SiteName AS BillToSiteName, bAddress.Line1 AS BillToAddress1, bAddress.Line2 AS BillToAddress2, bAddress.City AS BillToCity, bAddress.StateOrProvince AS BillToState,
				bAddress.PostalCode AS BillToPostalCode, bAddress.CountryId AS BillToCountryId, bAddress.Country AS BillToCountry, bAddress.ContactName AS BillToContactName, bAddress.Memo AS BillToMemo, soq.CreatedBy, soq.CreatedDate,
				soq.UpdatedBy, soq.UpdatedDate, soq.IsDeleted, soq.IsActive, soq.StatusName AS Status, soq.StatusChangeDate, soq.ManagementStructureId, soq.MasterCompanyId, sAddress.UserTypeName AS ShipToUserType, sAddress.UserName AS ShipToUser,
				bAddress.UserTypeName AS BillToUserType, bAddress.UserName AS BillToUser, soq.Version, soq.VersionNumber, aty.CustomerTypeName AS AccountTypeName, soq.EmployeeName, pr.Description AS PriorityName, soq.Memo,
				soq.RestrictPMA, soq.RestrictDER, soq.BalanceDue, soq.IsNewVersionCreated, soq.ManagementStructureName1, soq.ManagementStructureName2, soq.ManagementStructureName3, soq.ManagementStructureName4, 
				(SELECT TOP 1 ISNULL(BillingAmount, 0) FROM DBO.ExchangeQuoteFreight FR WHERE FR.ExchangeQuoteId = @ExchangeQuoteId AND FR.IsActive = 1 AND FR.IsDeleted = 0) AS Freight,
				(SELECT TOP 1 ISNULL(BillingAmount, 0) FROM DBO.ExchangeQuoteCharges MISC WHERE MISC.ExchangeQuoteId = @ExchangeQuoteId AND MISC.IsActive = 1 AND MISC.IsDeleted = 0) AS Misc,
				custfc.CurrencyId, cur.Code AS CurrencyName, msd.EntityMSID AS EntityStructureId, msd.LastMSLevel, msd.AllMSlevels, soq.IsEnforceApproval AS IsEnforceApproval, soq.EnforceEffectiveDate AS EnforceEffectiveDate,
				soq.EmployeeId, exchso.ExchangeSalesOrderNumber, exchso.ExchangeSalesOrderId, custAddress.Line1 AS CustomerAddress1, custAddress.Line2 AS CustomerAddress2, custAddress.City AS CustomerCity, custAddress.StateOrProvince AS CustomerState,
				custAddress.PostalCode AS CustomerPostalCode, cconc.countries_name AS CustomerCountry,soq.CustomerServiceRepName AS CustomerSeviceRepName,soq.CreditTermName AS CreditTerms,ISNULL(AllShipVia.ShippingTerms, '') AS ShippingTerms
				FROM 
				DBO.ExchangeQuote soq WITH (NOLOCK)
				INNER JOIN DBO.ExchangeManagementStructureDetails msd WITH (NOLOCK) ON soq.ExchangeQuoteId = msd.ReferenceID AND msd.ModuleID = 58
				INNER JOIN DBO.ManagementStructureLevel msl WITH (NOLOCK) on msd.Level1Id = msl.ID
				LEFT JOIN DBO.LegalEntity leg WITH (NOLOCK) on msl.LegalEntityId = leg.LegalEntityId
				LEFT JOIN DBO.[Address] [add] WITH (NOLOCK) on leg.AddressId = [add].AddressId
				LEFT JOIN DBO.Countries ccon WITH (NOLOCK) on [add].CountryId = ccon.countries_id
				LEFT JOIN DBO.AllAddress sAddress WITH (NOLOCK) on soq.ExchangeQuoteId = sAddress.ReffranceId AND sAddress.ModuleId = 17 AND sAddress.IsShippingAdd = 1
				LEFT JOIN DBO.AllAddress bAddress WITH (NOLOCK) on soq.ExchangeQuoteId = bAddress.ReffranceId AND bAddress.ModuleId = 17 AND bAddress.IsShippingAdd = 0
				LEFT JOIN DBO.AllShipVia allShipVia WITH (NOLOCK) on soq.ExchangeQuoteId = allShipVia.ReferenceId AND allShipVia.ModuleId = 17 
				LEFT JOIN DBO.Priority pr WITH (NOLOCK) on soq.PriorityId = pr.PriorityId
				LEFT JOIN DBO.CustomerType aty WITH (NOLOCK) on soq.AccountTypeId = aty.CustomerTypeId
				LEFT JOIN DBO.CustomerDomensticShipping sa WITH (NOLOCK) on sAddress.UserId = sa.CustomerId AND sa.IsPrimary = 1
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) on soq.CustomerId = cust.CustomerId
				INNER JOIN DBO.Address custAddress WITH (NOLOCK) on cust.AddressId = custAddress.AddressId
				LEFT JOIN DBO.Countries cconc WITH (NOLOCK) on custAddress.CountryId = cconc.countries_id
				LEFT JOIN DBO.CustomerFinancial custfc WITH (NOLOCK) on cust.CustomerId = custfc.CustomerId
				LEFT JOIN DBO.Currency cur WITH (NOLOCK) on custfc.CurrencyId = cur.CurrencyId
				LEFT JOIN DBO.CustomerContact cust_cont WITH (NOLOCK) on soq.CustomerContactId = cust_cont.CustomerContactId
				LEFT JOIN DBO.Contact cont WITH (NOLOCK) on cust_cont.ContactId = cont.ContactId
				LEFT JOIN DBO.ExchangeSalesOrder exchso WITH (NOLOCK) on soq.ExchangeQuoteId = exchso.ExchangeQuoteId
				where soq.ExchangeQuoteId = @ExchangeQuoteId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetViewExchangeQuoteById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeQuoteId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END