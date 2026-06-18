/*************************************************************           
 ** File:   [GetSalesOrderQuoteById]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get sales order quote details for view    
 ** Purpose:         
 ** Date:   09/20/2024
          
 ** PARAMETERS:
 
 ** RETURN VALUE:

 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    09/20/2024		Vishal Suthar	Created
    2    12/13/2024		Vishal Suthar	Fixed an alias for Credit Terms
    3    15-07-2025		Rajesh Gami		Fixed: showing proper status
    4    09-DEC-2025	Vishal Suthar	Fixed: added IsDeleted = 0 in join for AllAddress table
    5    17-DEC-2025	Devendra Shekh	added cont.ContactId, ContactEmail
	6    08-JUN-2026    Ayushi Patel    [PN-16030]Added logic to return ContactEmail and CustomerContactEmail in lowercase for A2Z Master Company.
	7    17-JUN-2026    Amit Ghediya    Get MarketplaceRef for view [PN-16886].

 -- EXEC DBO.GetSalesOrderQuoteById 771
**************************************************************/ 
CREATE    PROCEDURE [dbo].[GetSalesOrderQuoteById]
    @SalesOrderQuoteId INT
AS
BEGIN
    SET NOCOUNT ON;
	
	BEGIN TRY
		DECLARE @SalesQuoteModuleId BIGINT = 7;
		DECLARE @SalesQuoteManagementStructureModuleId BIGINT = 18;

		DECLARE @A2ZMasterCompanyCode VARCHAR(50);
		DECLARE @MasterCompanyCodeAll VARCHAR(50);
		DECLARE @CompanyId BIGINT;
		SELECT @CompanyId = ModuleId FROM Module WHERE ModuleName = 'Company';
		SELECT @MasterCompanyCodeAll = mc.MasterCompanyCode FROM DBO.SalesOrderQuote soq WITH(NOLOCK) INNER JOIN DBO.MasterCompany mc WITH(NOLOCK) ON soq.MasterCompanyId = mc.MasterCompanyId WHERE soq.SalesOrderQuoteId = @SalesOrderQuoteId;
		SELECT @A2ZMasterCompanyCode = MasterCompanyCode FROM DBO.MasterCompany WITH(NOLOCK) WHERE UPPER(MasterCompanyCode) = 'A2Z';


		SELECT 
			ISNULL(leg.Name, '') AS CompanyName,
			ISNULL(addr.Line1, '') AS ComAddress1,
			ISNULL(addr.Line2, '') AS ComAddress2,
			ISNULL(addr.City, '') AS ComCity,
			ISNULL(addr.StateOrProvince, '') AS ComState,
			ISNULL(addr.PostalCode, '') AS ComPostalCode,
			ISNULL(ccon.countries_name, '') AS ComCountry,
			ISNULL(leg.PhoneNumber, '') AS ComPhoneNo,
			soq.SalesOrderQuoteId,
			soq.SalesOrderQuoteNumber,
			soq.QuoteTypeName,
			soq.OpenDate,
			soq.ValidForDays,
			soq.QuoteExpireDate,
			soq.AccountTypeName,
			soq.CustomerId,
			soq.CustomerName,
			soq.CustomerCode,
			soq.CustomerContactId,
			cust.CustomerPhone,
			CONCAT(ISNULL(cont.FirstName, ''), ' ', ISNULL(cont.LastName, ''), ' ', ISNULL(cont.WorkPhone, '')) AS CustomerContactName,
			CASE 
				WHEN @MasterCompanyCodeAll = @A2ZMasterCompanyCode 
					THEN LOWER(ISNULL(soq.CustomerContactEmail, ''))
				ELSE ISNULL(soq.CustomerContactEmail, '')
			END AS CustomerContactEmail,
			CASE WHEN LOWER(soq.StatusName) = 'closed' THEN so.CustomerReference ELSE soq.CustomerReference END AS CustomerReference,
			soq.ContractReference,
			soq.SalesPersonName,
			soq.AgentName,
			soq.CustomerServiceRepName,
			soq.ProbabilityName,
			soq.LeadSourceName AS LeadSource,
			soq.CreditLimit,
			soq.CreditLimitName,
			soq.CreditTermName,
			soq.CreditTermName CreditTerms,
			soq.EmployeeName,
			soq.RestrictPMA,
			soq.RestrictDER,
			soq.ApprovedDate,
			custfc.CurrencyId,
			ISNULL(cur.Code, '') AS CurrencyName,
			soq.CustomerWarningName AS CustomerWarningMessage,
			soq.Memo,
			soq.Notes,
			ISNULL(sAddress.SiteId, 0) AS ShipToSiteId,
			sAddress.SiteName AS ShipToSiteName,
			sAddress.Line1 AS ShipToAddress1,
			sAddress.Line2 AS ShipToAddress2,
			sAddress.Line3 AS ShipToAddress3,
			sAddress.City AS ShipToCity,
			sAddress.StateOrProvince AS ShipToState,
			sAddress.PostalCode AS ShipToPostalCode,
			sAddress.CountryId AS ShipToCountryId,
			sAddress.Country AS ShipToCountry,
			sAddress.ContactPhoneNo AS ShipToContactPhone,
			sa.Attention,
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
			soq.IsDeleted,
			soq.IsActive,
			MST.Name AS Status,
			soq.StatusChangeDate,
			soq.ManagementStructureId,
			sAddress.UserTypeName AS ShipToUserType,
			CASE 
				WHEN sAddress.UserType = @CompanyId 
				AND UPPER(@MasterCompanyCodeAll) = UPPER(@A2ZMasterCompanyCode)
				THEN ISNULL(sAddress.UserName, '')
				ELSE UPPER(ISNULL(sAddress.UserName, ''))
			END AS ShipToUser,
			bAddress.UserTypeName AS BillToUserType,
			bAddress.UserName AS BillToUser,
			soq.Version,
			soq.VersionNumber,
			soq.QtyRequested,
			soq.QtyToBeQuoted,
			soq.QuoteSentDate,
			(SELECT ISNULL(SUM(CONVERT(DECIMAL, cta.TaxRate)), 0) FROM CustomerTaxTypeRateMapping cta WHERE cta.CustomerId = soq.CustomerId) AS TaxRate,
			soq.IsNewVersionCreated,
			soq.ManagementStructureName1,
			soq.ManagementStructureName2,
			soq.ManagementStructureName3,
			soq.ManagementStructureName4,
			soq.MasterCompanyId,
			soq.TotalFreight AS Freight,
			soq.TotalCharges AS MiscCharges,
			soq.EmployeeId,
			custAddress.Line1 AS CustomerAddress1,
			custAddress.Line2 AS CustomerAddress2,
			custAddress.City AS CustomerCity,
			custAddress.StateOrProvince AS CustomerState,
			custAddress.PostalCode AS CustomerPostalCode,
			ISNULL(cconc.countries_name, '') AS CustomerCountry,
			ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
			ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
			ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
			soq.ChargesBilingMethodId AS HeaderMarkupIdCharge,
			soq.FreightBilingMethodId AS HeaderMarkupIdFreight,
			so.SalesOrderNumber,
			allShipVia.ShippingTerms,
			ISNULL(sAddress.IsShippingAdd, 0) AS IsShippingAdd,
			ISNULL(fcu.Code, '') AS FunctionalCurrency,
			ISNULL(rcu.Code, '') AS ReportCurrency,
			CASE WHEN soq.ForeignExchangeRate > 0 THEN soq.ForeignExchangeRate ELSE 0 END AS ForeignExchangeRate,
			cont.ContactId,
			CASE 
				WHEN @MasterCompanyCodeAll = @A2ZMasterCompanyCode 
					THEN LOWER(ISNULL(cont.Email, ''))
				ELSE ISNULL(cont.Email, '')
			END AS ContactEmail,
			ISNULL(SOQ.MarketplaceRef,'') MarketplaceRef
		FROM DBO.SalesOrderQuote soq WITH (NOLOCK)
		INNER JOIN DBO.MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId = MST.Id
		LEFT JOIN DBO.ManagementStructure mn WITH (NOLOCK) ON soq.ManagementStructureId = mn.ManagementStructureId
		LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON soq.SalesOrderQuoteId = so.SalesOrderQuoteId
		LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON soq.CustomerId = cust.CustomerId
		LEFT JOIN DBO.[Address] custAddress WITH (NOLOCK) ON cust.AddressId = custAddress.AddressId
		LEFT JOIN DBO.Countries cconc WITH (NOLOCK) ON custAddress.CountryId = cconc.countries_id
		LEFT JOIN DBO.CustomerFinancial custfc WITH (NOLOCK) ON cust.CustomerId = custfc.CustomerId
		LEFT JOIN DBO.Currency cur WITH (NOLOCK) ON custfc.CurrencyId = cur.CurrencyId
		LEFT JOIN DBO.LegalEntity leg WITH (NOLOCK) ON mn.LegalEntityId = leg.LegalEntityId
		LEFT JOIN DBO.[Address] addr WITH (NOLOCK) ON leg.AddressId = addr.AddressId
		LEFT JOIN DBO.Countries ccon WITH (NOLOCK) ON addr.CountryId = ccon.countries_id
		LEFT JOIN DBO.AllAddress sAddress WITH (NOLOCK) ON soq.SalesOrderQuoteId = sAddress.ReffranceId 
			AND sAddress.ModuleId = @SalesQuoteModuleId 
			AND sAddress.IsShippingAdd = 1 AND sAddress.IsDeleted = 0
		LEFT JOIN DBO.AllAddress bAddress WITH (NOLOCK) ON soq.SalesOrderQuoteId = bAddress.ReffranceId 
			AND bAddress.ModuleId = @SalesQuoteModuleId
			AND bAddress.IsShippingAdd = 0 AND bAddress.IsDeleted = 0
		LEFT JOIN DBO.AllShipVia allShipVia WITH (NOLOCK) ON soq.SalesOrderQuoteId = allShipVia.ReferenceId 
			AND allShipVia.ModuleId = @SalesQuoteModuleId
		LEFT JOIN DBO.CustomerContact cust_cont WITH (NOLOCK) ON soq.CustomerContactId = cust_cont.CustomerContactId
		LEFT JOIN DBO.Contact cont WITH (NOLOCK) ON cust_cont.ContactId = cont.ContactId
		LEFT JOIN DBO.CustomerDomensticShipping sa WITH (NOLOCK) ON sAddress.UserId = sa.CustomerId AND sa.IsPrimary = 1
		LEFT JOIN DBO.SalesOrderManagementStructureDetails msd ON soq.SalesOrderQuoteId = msd.ReferenceID 
			AND msd.ModuleID = @SalesQuoteManagementStructureModuleId
		LEFT JOIN DBO.Currency fcu WITH (NOLOCK) ON soq.FunctionalCurrencyId = fcu.CurrencyId 
			AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
		LEFT JOIN DBO.Currency rcu WITH (NOLOCK) ON soq.ReportCurrencyId = rcu.CurrencyId 
			AND rcu.IsActive = 1 AND rcu.IsDeleted = 0
		WHERE soq.SalesOrderQuoteId = @SalesOrderQuoteId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments varchar(150) = 'GetSalesOrderQuoteById',
        @ProcedureParameters varchar(3000) = '@SalesOrderQuoteId = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName,
						@AdhocComments = @AdhocComments,
						@ProcedureParameters = @ProcedureParameters,
						@ApplicationName = @ApplicationName,
						@ErrorLogID = @ErrorLogID OUTPUT;
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1);
	END CATCH
END;