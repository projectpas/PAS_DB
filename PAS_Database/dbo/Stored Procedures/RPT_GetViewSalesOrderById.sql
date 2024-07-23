/*************************************************************  
** Author:  <AMIT GHEDIYA>  
** Create date: <01/09/2024>  
** Description: 
 
EXEC [RPT_GetViewSalesOrderById]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    01/09/2024  AMIT GHEDIYA    Created
   2	07/23/2024  Bhargav Saiya	Addes ShippingTerms

EXEC RPT_GetViewSalesOrderById 782

**************************************************************/
CREATE     PROCEDURE [dbo].[RPT_GetViewSalesOrderById]              
	@salesOrderId BIGINT            
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;              
             
  BEGIN TRY              
   BEGIN            
		DECLARE @moduleId BIGINT;

		SET @moduleId = (SELECT ModuleId FROM dbo.module WHERE CodePrefix = 'SO');

		SELECT TOP 1
			soq.SalesOrderId,
			soq.SalesOrderQuoteId,
			soq.SalesOrderNumber,
			soq.ATAPDFPath,
			soq.StatusId,
			UPPER(ISNULL(soqt.SalesOrderQuoteNumber, '')) AS SalesOrderQuoteNumber,
			ISNULL(qty.Name, '') AS TypeName,
			soq.OpenDate,
			soq.ShippedDate,
			soq.NumberOfItems,
			ISNULL(cty.CustomerTypeName, '') AS AccountTypeName,
			soq.CustomerId,
			UPPER(ISNULL(cust.Name, '')) AS CustomerName,
			UPPER(ISNULL(cust.CustomerCode, '')) AS CustomerCode,
			UPPER(ISNULL(cuad.Line1, '')) AS CustToAddress1,
			UPPER(ISNULL(cuad.Line2, '')) AS CustToAddress2,
			UPPER(ISNULL(cuad.City, '')) AS CustToCity,
			comboAdCity = UPPER(ISNULL(cuad.Line1, '') + ' ' + UPPER(ISNULL(cuad.Line2, '')) + ' ' + UPPER(ISNULL(cuad.City, ''))),
			UPPER(ISNULL(cuad.StateOrProvince, '')) AS CustToState,
			UPPER(ISNULL(cuad.PostalCode, '')) AS CustToPostalCode,
			UPPER(ISNULL(ccnty.countries_name, '')) AS CustToCountry,
			UPPER(ISNULL(cont.FirstName + ' ' + cont.LastName, '')) AS CustomerContactName,
			soq.CustomerReference,
			soq.CustomerContactId,
			ISNULL(saemp.FirstName + ' ' + saemp.LastName, '') AS SalesPersonName,
			ISNULL(saremp.FirstName + ' ' + saremp.LastName, '') AS CustomerSeviceRepName,
			soq.CreditLimit,
			soq.CreditLimitName,
			soq.CreditTermName,
			soq.TotalSalesAmount,
			soq.CustomerHold,
			soq.DepositAmount,
			ISNULL((SELECT TOP 1 ARBalance FROM dbo.CustomerCreditTermsHistory WITH(NOLOCK) WHERE CustomerId = soq.CustomerId ORDER BY CustomerCreditTermsHistoryId DESC), 0) AS BalanceDue,
			ISNULL(cur.Code, '') AS CurrencyName,
			soq.ApprovedDate,
			ISNULL(qst.Name, '') AS Status,
			soq.StatusChangeDate,
			ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS EmployeeName,
			soq.RestrictPMA,
			soq.RestrictDER,
			soq.Memo,
			soq.Notes,
			ISNULL(cuwa.WarningMessage, '') AS CustomerWarningMessage,
			ISNULL(posadd.SiteId, 0) AS ShipToSiteId,
			UPPER(ISNULL(posadd.SiteName, '')) AS ShipToSiteName,
			UPPER(posadd.Line1) AS ShipToAddress1,
			UPPER(posadd.Line2) AS ShipToAddress2,
			UPPER(posadd.Line3) AS ShipToAddress3,
			UPPER(posadd.City) AS ShipToCity,
			comboShipAdCity = UPPER(ISNULL(posadd.Line1,'') + ' ' + ISNULL(posadd.Line2,'') + ' ' + ISNULL(posadd.Line3,'') + ' ' + ISNULL(posadd.City,'')),
			UPPER(posadd.StateOrProvince) AS ShipToState,
			UPPER(posadd.PostalCode) AS ShipToPostalCode,
			UPPER(ISNULL(posadd.Country, '')) AS ShipToCountry,
			UPPER(ISNULL(posadd.ContactName, '')) AS ShipToContactName,
			'' AS ShipToContactPhone,
			'' AS ShipToContactEmail,
			posadd.Memo AS ShipToMemo,
			ISNULL(posv.ShipVia, '') AS ShipViaName,
			ISNULL(posv.ShippingAccountNo, '') AS ShipViaShippingAccountInfo,
			posv.ShippingCost,
			posv.HandlingCost,
			ISNULL(pobadd.SiteName, '') AS BillToSiteName,
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
			UPPER(posadd.UserName) AS ShipToUser,
			pobadd.UserTypeName AS BillToUserType,
			pobadd.UserName AS BillToUser,
			soq.Version,
			--PASCommon.GenerateNumber(
			--	CONVERT(INT, soq.Version),
			--	(SELECT TOP 1 CodePrefix FROM CodePrefixes WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = CAST(CodePrefixEnum.Version AS BIGINT)),
			--	(SELECT TOP 1 CodeSufix FROM CodePrefixes WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = CAST(CodePrefixEnum.Version AS BIGINT))
			--) AS VersionNumber,
			soq.QtyRequested,
			soq.QtyToBeQuoted,
			ISNULL(cont.Email, '') AS CustomerContactEmail,
			CONVERT(DECIMAL(18, 2), (
				SELECT SUM(ta.TaxRate)
				FROM dbo.CustomerTaxTypeRateMapping cta WITH(NOLOCK)
				JOIN dbo.TaxRate ta WITH(NOLOCK) ON cta.TaxRateId = ta.TaxRateId
				WHERE cta.CustomerId = soq.CustomerId
				--GROUP BY ta.TaxRate
			)) AS TaxRate,
			--PASCommon.BarCodeGenerator(
			--	CONCAT(soq.SalesOrderNumber, '|', PASCommon.GenerateNumber(
			--		CONVERT(INT, soq.Version),
			--		(SELECT TOP 1 CodePrefix FROM CodePrefixes WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = CAST(CodePrefixEnum.Version AS BIGINT)),
			--		(SELECT TOP 1 CodeSufix FROM CodePrefixes WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = CAST(CodePrefixEnum.Version AS BIGINT))
			--	))
			--) AS BarCodePath,
			soq.ContractReference,
			soq.TotalFreight,
			soq.TotalCharges,
			soq.FreightBilingMethodId AS HeaderMarkupIdFreight,
			soq.ChargesBilingMethodId AS HeaderMarkupIdCharge,
			soq.MasterCompanyId,
			saemp.EmployeeId,
			msd.EntityMSID AS EntityStructureId,
			ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
			ISNULL(msd.AllMSlevels, '') AS AllMSlevelsr,
			ShippingTerms = posv.ShippingTerms
		FROM dbo.SalesOrder soq WITH(NOLOCK)
		LEFT JOIN dbo.SalesOrderQuote soqt WITH(NOLOCK) ON soq.SalesOrderQuoteId = soqt.SalesOrderQuoteId
		LEFT JOIN dbo.MasterSalesOrderQuoteTypes qty WITH(NOLOCK) ON soq.TypeId = qty.Id
		LEFT JOIN dbo.CustomerType cty WITH(NOLOCK) ON soq.AccountTypeId = cty.CustomerTypeId
		LEFT JOIN dbo.Customer cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
		LEFT JOIN dbo.CustomerFinancial custfc WITH(NOLOCK) ON cust.CustomerId = custfc.CustomerId
		LEFT JOIN dbo.Address cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
		LEFT JOIN dbo.Countries ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
		LEFT JOIN dbo.AllAddress posadd WITH(NOLOCK) ON soq.SalesOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @moduleId
		LEFT JOIN dbo.AllAddress pobadd WITH(NOLOCK) ON soq.SalesOrderId = pobadd.ReffranceId AND pobadd.IsShippingAdd = 0 AND pobadd.ModuleId = @moduleId
		LEFT JOIN dbo.AllShipVia posv WITH(NOLOCK) ON soq.SalesOrderId = posv.ReferenceId AND posv.ModuleId = @moduleId
		LEFT JOIN dbo.CustomerContact cust_cont WITH(NOLOCK) ON soq.CustomerContactId = cust_cont.CustomerContactId
		LEFT JOIN dbo.Contact cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
		LEFT JOIN dbo.Employee saemp WITH(NOLOCK) ON soq.SalesPersonId = saemp.EmployeeId
		LEFT JOIN dbo.Employee saremp WITH(NOLOCK) ON soq.CustomerSeviceRepId = saremp.EmployeeId
		LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON soq.EmployeeId = emp.EmployeeId
		LEFT JOIN dbo.Currency cur WITH(NOLOCK) ON custfc.CurrencyId = cur.CurrencyId
		LEFT JOIN dbo.MasterSalesOrderQuoteStatus qst WITH(NOLOCK) ON soq.StatusId = qst.Id
		LEFT JOIN dbo.CustomerWarning cuwa WITH(NOLOCK) ON soq.CustomerWarningId = cuwa.CustomerWarningId
		LEFT JOIN dbo.SalesOrderManagementStructureDetails msd WITH(NOLOCK) ON soq.SalesOrderId = msd.ReferenceID
		WHERE soq.SalesOrderId = @salesOrderId;
   END              
             
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetViewSalesOrderById'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@salesOrderId, '')              
              , @ApplicationName VARCHAR(100) = 'PAS'              
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
             
              exec spLogException              
                       @DatabaseName           = @DatabaseName              
                     , @AdhocComments          = @AdhocComments              
                     , @ProcedureParameters    = @ProcedureParameters              
                     , @ApplicationName        = @ApplicationName              
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;              
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)              
              RETURN(1);              
  END CATCH              
END