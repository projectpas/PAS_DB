
--USP_GetViewExchangeQuoteById 55,58,1



CREATE   PROCEDURE USP_GetViewExchangeQuoteById
(
	@Id BIGINT,
	@ManagementModuleId INT,
	@ModuleListId INT
)
AS
BEGIN 
	BEGIN TRY
		SELECT 
		leg.Name 'CompanyName',[add].Line1 'ComAddress1',[add].Line2 'ComAddress2',[add].City 'ComCity',[add].StateOrProvince 'ComState',[add].PostalCode 'ComPostalCode'
		,ccon.countries_name 'ComCountry',leg.PhoneNumber 'ComPhoneNo',soq.ExchangeQuoteId,soq.ExchangeQuoteNumber,soq.OpenDate,soq.QuoteExpireDate,
        soq.TypeName,soq.CustomerId,soq.CustomerName,soq.CustomerCode,soq.CustomerContactId,cont.FirstName + ' ' + cont.LastName 'CustomerContactName',
		soq.CustomerContactEmail,soq.CustomerReference,soq.SalesPersonName,soq.CustomerServiceRepName,cust.CustomerPhone,
		soq.CreditLimit,soq.CreditLimitName,soq.CreditTermName,soq.CreditTermId,soq.ApprovedDate,soq.Notes,ISNULL(sAddress.SiteId,0) SiteId,
		sAddress.SiteName 'ShipToSiteName',sAddress.Line1 'ShipToAddress1',sAddress.Line2 'ShipToAddress2',sAddress.Line3 'ShipToAddress3',sAddress.City 'ShipToCity',
		sAddress.StateOrProvince 'ShipToState',sAddress.PostalCode 'ShipToPostalCode',sAddress.CountryId 'ShipToCountryId',
		sAddress.Country 'ShipToCountry',sAddress.ContactName 'ShipToContactName',sa.Attention 'Attention',allShipVia.ShipVia ,allShipVia.ShippingAccountNo,
		sAddress.Memo 'ShipViaMemo',bAddress.SiteName 'BillToSiteName',bAddress.Line1 'BillToAddress1',bAddress.Line2 'BillToAddress2',bAddress.City 'BillToCity',
		bAddress.StateOrProvince 'BillToState',bAddress.PostalCode 'BillToPostalCode',bAddress.CountryId 'BillToCountryId',bAddress.Country 'BillToCountry',
		bAddress.ContactName 'BillToContactName',bAddress.Memo 'BillToMemo',soq.CreatedBy,soq.CreatedDate,soq.UpdatedBy,
		soq.UpdatedDate,soq.IsDeleted,soq.IsActive,soq.StatusName,soq.StatusChangeDate,soq.ManagementStructureId,soq.MasterCompanyId,
		sAddress.UserTypeName 'ShipToUserType',sAddress.UserName 'ShipToUser',bAddress.UserTypeName 'BillToUserType',bAddress.UserName 'BillToUser',
		soq.Version,soq.VersionNumber,aty.CustomerTypeName,soq.EmployeeName,pr.Description,soq.Memo,soq.RestrictPMA,soq.RestrictDER,soq.BalanceDue,soq.IsNewVersionCreated,
		soq.ManagementStructureName1,soq.ManagementStructureName2,soq.ManagementStructureName3,soq.ManagementStructureName4,ISNULL(p.BillingAmount,0) Freight,ISNULL(q.BillingAmount,0) Misc,
		custfc.CurrencyId,cur.Code 'CurrencyName',msd.EntityMSID,msd.LastMSLevel,msd.AllMSlevels,soq.IsEnforceApproval,soq.EnforceEffectiveDate,soq.EmployeeId,
		exchso.ExchangeSalesOrderNumber,exchso.ExchangeSalesOrderId,custAddress.Line1 'CustomerAddress1',custAddress.Line2 'CustomerAddress2',custAddress.City 'CustomerCity',
		custAddress.StateOrProvince 'CustomerState',custAddress.PostalCode 'CustomerPostalCode',cconc.countries_name 'CustomerCountry'
		FROM ExchangeQuote Soq
		INNER JOIN ExchangeManagementStructureDetails msd WITH(NOLOCK) ON soq.ExchangeQuoteId = msd.ReferenceID AND msd.ModuleID = @ManagementModuleId
		INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) on msd.Level1Id = msl.ID
		LEFT JOIN LegalEntity leg WITH(NOLOCK) on msl.LegalEntityId = leg.LegalEntityId
		LEFT JOIN Address [add] WITH(NOLOCK) on leg.AddressId = [add].AddressId
		LEFT JOIN Countries ccon WITH(NOLOCK) on [add].CountryId = ccon.countries_id
		LEFT JOIN AllAddress sAddress WITH(NOLOCK) on sAddress.ModuleId = ISNULL(@ModuleListId,0) AND sAddress.IsShippingAdd = 1 AND soq.ExchangeQuoteId = sAddress.ReffranceId 
		LEFT JOIN AllAddress bAddress WITH(NOLOCK) on bAddress.ModuleId = ISNULL(@ModuleListId,0) AND bAddress.IsShippingAdd = 0 AND soq.ExchangeQuoteId = bAddress.ReffranceId 
		LEFT JOIN AllShipVia allShipVia WITH(NOLOCK) on allShipVia.ModuleId = ISNULL(@ModuleListId,0) AND soq.ExchangeQuoteId = allShipVia.ReferenceId
		LEFT JOIN Priority pr WITH(NOLOCK) on soq.PriorityId = pr.PriorityId
		LEFT JOIN CustomerType aty WITH(NOLOCK) on soq.AccountTypeId = aty.CustomerTypeId
		LEFT JOIN CustomerDomensticShipping sa WITH(NOLOCK) on sa.IsPrimary = 1 AND sAddress.UserId = sa.CustomerId
		LEFT JOIN Customer cust WITH(NOLOCK) on soq.CustomerId = cust.CustomerId
		LEFT JOIN Address custAddress WITH(NOLOCK) on cust.AddressId = custAddress.AddressId
		LEFT JOIN Countries cconc WITH(NOLOCK) on custAddress.CountryId = cconc.countries_id 
        LEFT JOIN CustomerFinancial custfc WITH(NOLOCK) on cust.CustomerId = custfc.CustomerId 
        LEFT JOIN Currency cur WITH(NOLOCK) on custfc.CurrencyId = cur.CurrencyId 
        LEFT JOIN CustomerContact cust_cont WITH(NOLOCK) on soq.CustomerContactId = cust_cont.CustomerContactId 
        LEFT JOIN Contact cont WITH(NOLOCK) on cust_cont.ContactId = cont.ContactId 
        LEFT JOIN ExchangeSalesOrder exchso WITH(NOLOCK) on soq.ExchangeQuoteId = exchso.ExchangeQuoteId
		LEFT JOIN ExchangeQuoteFreight p WITH(NOLOCK) on soq.ExchangeQuoteId = p.ExchangeQuoteId AND p.IsActive = 1 AND p.IsDeleted = 0
		LEFT JOIN ExchangeQuoteCharges q WITH(NOLOCK) on soq.ExchangeQuoteId = q.ExchangeQuoteId AND q.IsActive = 1 AND q.IsDeleted = 0
		WHERE soq.ExchangeQuoteId = @Id

	END TRY
	BEGIN CATCH 
		DECLARE @ErrorLogID INT      
	   ,@DatabaseName VARCHAR(100) = db_name()      
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
	   ,@AdhocComments VARCHAR(150) = 'USP_GetViewExchangeQuoteById'      
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Id, '') as varchar(100))      
		  + '@Parameter2 = ''' + CAST(ISNULL(@ManagementModuleId, '') as varchar(100))       
		  + '@Parameter3 = ''' + CAST(ISNULL(@ModuleListId, '') as varchar(100))        
	   ,@ApplicationName VARCHAR(100) = 'PAS'      
      
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
	  EXEC spLogException @DatabaseName = @DatabaseName      
	   ,@AdhocComments = @AdhocComments      
	   ,@ProcedureParameters = @ProcedureParameters      
	   ,@ApplicationName = @ApplicationName      
	   ,@ErrorLogID = @ErrorLogID OUTPUT;      
      
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)      
      
	  RETURN (1);  
	END CATCH
END