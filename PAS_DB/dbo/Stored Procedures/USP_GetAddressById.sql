/*************************************************************           
 ** File:   [USP_GetAddressById]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Address Deatais By Purchase Order Id    
 ** Purpose:         
 ** Date:   09/24/2020        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/24/2020   Hemant Saliya Created

**************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/28/2020   Deep Patel	Changes relaed to AllAddress Common table.
     
 EXECUTE [USP_GetAddressById] 175
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetAddressById]
(    
@Id BIGINT,--Id is primaryKey value from respective module 
@AddressType NVARCHAR(10),
@ModuleID bigint
)    
AS    
BEGIN    

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION  
		IF(@AddressType = 'PO')
		BEGIN
		SELECT PO.PurchaseOrderId,
				PO.MasterCompanyId,
				PO.IsActive,
				PO.IsDeleted,
				PO.CreatedDate,
				PO.UpdatedDate,
				PO.CreatedBy,
				PO.UpdatedBy,
				ISNULL(POA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(POA.UserType, 0) AS ShipToUserType,
				ISNULL(POA.UserId, 0) AS ShipToUserId,
				ISNULL(POA.SiteId, 0) AS ShipToSiteId,
				ISNULL(POA.SiteName, '') AS ShipToSiteName,
				POA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(POA.ContactId, 0) AS ShipToContactId,
				ISNULL(POA.ContactName, '') AS ShipToContact,
				ISNULL(POA.Memo, '') AS ShipToMemo,
				ISNULL(POA.AddressId, 0) AS ShipToAddressId,
				ISNULL(POA.Line1, '') AS ShipToAddress1,
				ISNULL(POA.Line2, '') AS ShipToAddress2,
				ISNULL(POA.City, '') AS ShipToCity,
				ISNULL(POA.CountryId, 0) AS ShipToCountryId,
				ISNULL(POA.Country, '') AS ShipToCountryName,
				ISNULL(POA.StateOrProvince, '') AS ShipToState,
				ISNULL(POA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(POSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(POSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(POSV.ShipVia, '') AS ShipVia,
				ISNULL(POSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(POSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(POSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(POSV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(POAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(POAS.UserType, 0) AS BillToUserType,
				ISNULL(POAS.UserId, 0) AS BillToUserId,
				ISNULL(POAS.SiteId, 0) AS BillToSiteId,
				ISNULL(POAS.SiteName, '') AS BillToSiteName,
				POAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(POAS.ContactId, 0) AS BillToContactId,
				ISNULL(POAS.ContactName, '') AS BillToContactName,			
				ISNULL(POAS.Memo, '') AS BillToMemo,
				ISNULL(POAS.AddressId, 0) AS BillToAddressId,
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(POAS.Line1, '') AS BillToAddress1,
				ISNULL(POAS.Line2, '') AS BillToAddress2,
				ISNULL(POAS.City, '') AS BillToCity,
				ISNULL(POAS.CountryId, 0) AS BillToCountryId,
				ISNULL(POAS.Country, '') AS BillToCountryName,
				ISNULL(POAS.StateOrProvince, '') AS BillToState,
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode
			
		FROM PurchaseOrder PO WITH (NOLOCK)
			LEFT JOIN AllAddress POA WITH (NOLOCK) ON PO.PurchaseOrderId = POA.ReffranceId AND POA.IsShippingAdd = 1 and POA.ModuleId = @ModuleID
			LEFT JOIN AllAddress POAS WITH (NOLOCK) ON PO.PurchaseOrderId = POAS.ReffranceId AND POAS.IsShippingAdd = 0 and POAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia POSV WITH (NOLOCK) ON POSV.ReferenceId = PO.PurchaseOrderId and POSV.ModuleId = @ModuleID
		WHERE PO.PurchaseOrderId = @Id
		END

		ELSE IF(@AddressType = 'SOQ')
		BEGIN
		SELECT SOQ.SalesOrderQuoteId,
				SOQ.MasterCompanyId,
				SOQ.IsActive,
				SOQ.IsDeleted,
				SOQ.CreatedDate,
				SOQ.UpdatedDate,
				SOQ.CreatedBy,
				SOQ.UpdatedBy,
				ISNULL(SOQA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(SOQA.UserType, 0) AS ShipToUserType,
				ISNULL(SOQA.UserId, 0) AS ShipToUserId,
				ISNULL(SOQA.SiteId, 0) AS ShipToSiteId,
				ISNULL(SOQA.SiteName, '') AS ShipToSiteName,
				SOQA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(SOQA.ContactId, 0) AS ShipToContactId,
				ISNULL(SOQA.ContactName, '') AS ShipToContact,
				ISNULL(SOQA.Memo, '') AS ShipToMemo,
				ISNULL(SOQA.AddressId, 0) AS ShipToAddressId,
				ISNULL(SOQA.Line1, '') AS ShipToAddress1,
				ISNULL(SOQA.Line2, '') AS ShipToAddress2,
				ISNULL(SOQA.City, '') AS ShipToCity,
				ISNULL(SOQA.CountryId, 0) AS ShipToCountryId,
				ISNULL(SOQA.Country, '') AS ShipToCountryName,
				ISNULL(SOQA.StateOrProvince, '') AS ShipToState,
				ISNULL(SOQA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(SOQSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(SOQSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(SOQSV.ShipVia, '') AS ShipVia,
				ISNULL(SOQSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(SOQSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(SOQSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(SOQSV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(SOQAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(SOQAS.UserType, 0) AS BillToUserType,
				ISNULL(SOQAS.UserId, 0) AS BillToUserId,
				ISNULL(SOQAS.SiteId, 0) AS BillToSiteId,
				ISNULL(SOQAS.SiteName, '') AS BillToSiteName,
				SOQAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(SOQAS.ContactId, 0) AS BillToContactId,
				ISNULL(SOQAS.ContactName, '') AS BillToContactName,			
				ISNULL(SOQAS.Memo, '') AS BillToMemo,
				ISNULL(SOQAS.AddressId, 0) AS BillToAddressId,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQAS.Line1, '') AS BillToAddress1,
				ISNULL(SOQAS.Line2, '') AS BillToAddress2,
				ISNULL(SOQAS.City, '') AS BillToCity,
				ISNULL(SOQAS.CountryId, 0) AS BillToCountryId,
				ISNULL(SOQAS.Country, '') AS BillToCountryName,
				ISNULL(SOQAS.StateOrProvince, '') AS BillToState,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode
			
		FROM SalesOrderQuote SOQ WITH (NOLOCK)
			LEFT JOIN AllAddress SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
			LEFT JOIN AllAddress SOQAS WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = SOQ.SalesOrderQuoteId and SOQSV.ModuleId = @ModuleID
		WHERE SOQ.SalesOrderQuoteId = @Id
		END

		ELSE IF(@AddressType = 'SO')
		BEGIN
		SELECT SO.SalesOrderId,
				SO.MasterCompanyId,
				SO.IsActive,
				SO.IsDeleted,
				SO.CreatedDate,
				SO.UpdatedDate,
				SO.CreatedBy,
				SO.UpdatedBy,
				ISNULL(SOQA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(SOQA.UserType, 0) AS ShipToUserType,
				ISNULL(SOQA.UserId, 0) AS ShipToUserId,
				ISNULL(SOQA.SiteId, 0) AS ShipToSiteId,
				ISNULL(SOQA.SiteName, '') AS ShipToSiteName,
				SOQA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(SOQA.ContactId, 0) AS ShipToContactId,
				ISNULL(SOQA.ContactName, '') AS ShipToContact,
				ISNULL(SOQA.Memo, '') AS ShipToMemo,
				ISNULL(SOQA.AddressId, 0) AS ShipToAddressId,
				ISNULL(SOQA.Line1, '') AS ShipToAddress1,
				ISNULL(SOQA.Line2, '') AS ShipToAddress2,
				ISNULL(SOQA.City, '') AS ShipToCity,
				ISNULL(SOQA.CountryId, 0) AS ShipToCountryId,
				ISNULL(SOQA.Country, '') AS ShipToCountryName,
				ISNULL(SOQA.StateOrProvince, '') AS ShipToState,
				ISNULL(SOQA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(SOQSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(SOQSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(SOQSV.ShipVia, '') AS ShipVia,
				ISNULL(SOQSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(SOQSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(SOQSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(SOQSV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(SOQAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(SOQAS.UserType, 0) AS BillToUserType,
				ISNULL(SOQAS.UserId, 0) AS BillToUserId,
				ISNULL(SOQAS.SiteId, 0) AS BillToSiteId,
				ISNULL(SOQAS.SiteName, '') AS BillToSiteName,
				SOQAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(SOQAS.ContactId, 0) AS BillToContactId,
				ISNULL(SOQAS.ContactName, '') AS BillToContactName,			
				ISNULL(SOQAS.Memo, '') AS BillToMemo,
				ISNULL(SOQAS.AddressId, 0) AS BillToAddressId,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQAS.Line1, '') AS BillToAddress1,
				ISNULL(SOQAS.Line2, '') AS BillToAddress2,
				ISNULL(SOQAS.City, '') AS BillToCity,
				ISNULL(SOQAS.CountryId, 0) AS BillToCountryId,
				ISNULL(SOQAS.Country, '') AS BillToCountryName,
				ISNULL(SOQAS.StateOrProvince, '') AS BillToState,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode
			
		FROM SalesOrder SO WITH (NOLOCK)
			LEFT JOIN AllAddress SOQA WITH (NOLOCK) ON SO.SalesOrderId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
			LEFT JOIN AllAddress SOQAS WITH (NOLOCK) ON SO.SalesOrderId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = SO.SalesOrderId and SOQSV.ModuleId = @ModuleID
		WHERE SO.SalesOrderId = @Id
		END
	
		ELSE IF(@AddressType = 'RO')
		BEGIN
		SELECT RO.RepairOrderId,
				RO.MasterCompanyId,
				RO.IsActive,
				RO.IsDeleted,
				RO.CreatedDate,
				RO.UpdatedDate,
				RO.CreatedBy,
				RO.UpdatedBy,
				ISNULL(ROQA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(ROQA.UserType, 0) AS ShipToUserType,
				ISNULL(ROQA.UserId, 0) AS ShipToUserId,
				ISNULL(ROQA.SiteId, 0) AS ShipToSiteId,
				ISNULL(ROQA.SiteName, '') AS ShipToSiteName,
				ROQA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(ROQA.ContactId, 0) AS ShipToContactId,
				ISNULL(ROQA.ContactName, '') AS ShipToContact,
				ISNULL(ROQA.Memo, '') AS ShipToMemo,
				ISNULL(ROQA.AddressId, 0) AS ShipToAddressId,
				ISNULL(ROQA.Line1, '') AS ShipToAddress1,
				ISNULL(ROQA.Line2, '') AS ShipToAddress2,
				ISNULL(ROQA.City, '') AS ShipToCity,
				ISNULL(ROQA.CountryId, 0) AS ShipToCountryId,
				ISNULL(ROQA.Country, '') AS ShipToCountryName,
				ISNULL(ROQA.StateOrProvince, '') AS ShipToState,
				ISNULL(ROQA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(SOQSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(SOQSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(SOQSV.ShipVia, '') AS ShipVia,
				ISNULL(SOQSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(SOQSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(SOQSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(SOQSV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(SOQAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(SOQAS.UserType, 0) AS BillToUserType,
				ISNULL(SOQAS.UserId, 0) AS BillToUserId,
				ISNULL(SOQAS.SiteId, 0) AS BillToSiteId,
				ISNULL(SOQAS.SiteName, '') AS BillToSiteName,
				SOQAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(SOQAS.ContactId, 0) AS BillToContactId,
				ISNULL(SOQAS.ContactName, '') AS BillToContactName,			
				ISNULL(SOQAS.Memo, '') AS BillToMemo,
				ISNULL(SOQAS.AddressId, 0) AS BillToAddressId,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQAS.Line1, '') AS BillToAddress1,
				ISNULL(SOQAS.Line2, '') AS BillToAddress2,
				ISNULL(SOQAS.City, '') AS BillToCity,
				ISNULL(SOQAS.CountryId, 0) AS BillToCountryId,
				ISNULL(SOQAS.Country, '') AS BillToCountryName,
				ISNULL(SOQAS.StateOrProvince, '') AS BillToState,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode
			
		FROM RepairOrder RO WITH (NOLOCK)
			LEFT JOIN AllAddress ROQA WITH (NOLOCK) ON RO.RepairOrderId = ROQA.ReffranceId AND ROQA.IsShippingAdd = 1 and ROQA.ModuleId = @ModuleID
			LEFT JOIN AllAddress SOQAS WITH (NOLOCK) ON RO.RepairOrderId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = RO.RepairOrderId and SOQSV.ModuleId = @ModuleID
		WHERE RO.RepairOrderId = @Id
		END

		ELSE IF(@AddressType = 'EQ')
		BEGIN
		SELECT EQ.ExchangeQuoteId,
				EQ.MasterCompanyId,
				EQ.IsActive,
				EQ.IsDeleted,
				EQ.CreatedDate,
				EQ.UpdatedDate,
				EQ.CreatedBy,
				EQ.UpdatedBy,
				ISNULL(SOQA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(SOQA.UserType, 0) AS ShipToUserType,
				ISNULL(SOQA.UserId, 0) AS ShipToUserId,
				ISNULL(SOQA.SiteId, 0) AS ShipToSiteId,
				ISNULL(SOQA.SiteName, '') AS ShipToSiteName,
				SOQA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(SOQA.ContactId, 0) AS ShipToContactId,
				ISNULL(SOQA.ContactName, '') AS ShipToContact,
				ISNULL(SOQA.Memo, '') AS ShipToMemo,
				ISNULL(SOQA.AddressId, 0) AS ShipToAddressId,
				ISNULL(SOQA.Line1, '') AS ShipToAddress1,
				ISNULL(SOQA.Line2, '') AS ShipToAddress2,
				ISNULL(SOQA.City, '') AS ShipToCity,
				ISNULL(SOQA.CountryId, 0) AS ShipToCountryId,
				ISNULL(SOQA.Country, '') AS ShipToCountryName,
				ISNULL(SOQA.StateOrProvince, '') AS ShipToState,
				ISNULL(SOQA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(SOQSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(SOQSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(SOQSV.ShipVia, '') AS ShipVia,
				ISNULL(SOQSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(SOQSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(SOQSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(SOQSV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(SOQAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(SOQAS.UserType, 0) AS BillToUserType,
				ISNULL(SOQAS.UserId, 0) AS BillToUserId,
				ISNULL(SOQAS.SiteId, 0) AS BillToSiteId,
				ISNULL(SOQAS.SiteName, '') AS BillToSiteName,
				SOQAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(SOQAS.ContactId, 0) AS BillToContactId,
				ISNULL(SOQAS.ContactName, '') AS BillToContactName,			
				ISNULL(SOQAS.Memo, '') AS BillToMemo,
				ISNULL(SOQAS.AddressId, 0) AS BillToAddressId,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQAS.Line1, '') AS BillToAddress1,
				ISNULL(SOQAS.Line2, '') AS BillToAddress2,
				ISNULL(SOQAS.City, '') AS BillToCity,
				ISNULL(SOQAS.CountryId, 0) AS BillToCountryId,
				ISNULL(SOQAS.Country, '') AS BillToCountryName,
				ISNULL(SOQAS.StateOrProvince, '') AS BillToState,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode
			
		FROM ExchangeQuote EQ WITH (NOLOCK)
			LEFT JOIN AllAddress SOQA WITH (NOLOCK) ON EQ.ExchangeQuoteId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
			LEFT JOIN AllAddress SOQAS WITH (NOLOCK) ON EQ.ExchangeQuoteId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = EQ.ExchangeQuoteId and SOQSV.ModuleId = @ModuleID
		WHERE EQ.ExchangeQuoteId = @Id
		END

		ELSE IF(@AddressType = 'ExchSO')
		BEGIN
		SELECT ExchSO.ExchangeSalesOrderId,
				ExchSO.MasterCompanyId,
				ExchSO.IsActive,
				ExchSO.IsDeleted,
				ExchSO.CreatedDate,
				ExchSO.UpdatedDate,
				ExchSO.CreatedBy,
				ExchSO.UpdatedBy,
				ISNULL(SOQA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(SOQA.UserType, 0) AS ShipToUserType,
				ISNULL(SOQA.UserId, 0) AS ShipToUserId,
				ISNULL(SOQA.SiteId, 0) AS ShipToSiteId,
				ISNULL(SOQA.SiteName, '') AS ShipToSiteName,
				SOQA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(SOQA.ContactId, 0) AS ShipToContactId,
				ISNULL(SOQA.ContactName, '') AS ShipToContact,
				ISNULL(SOQA.Memo, '') AS ShipToMemo,
				ISNULL(SOQA.AddressId, 0) AS ShipToAddressId,
				ISNULL(SOQA.Line1, '') AS ShipToAddress1,
				ISNULL(SOQA.Line2, '') AS ShipToAddress2,
				ISNULL(SOQA.City, '') AS ShipToCity,
				ISNULL(SOQA.CountryId, 0) AS ShipToCountryId,
				ISNULL(SOQA.Country, '') AS ShipToCountryName,
				ISNULL(SOQA.StateOrProvince, '') AS ShipToState,
				ISNULL(SOQA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(SOQSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(SOQSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(SOQSV.ShipVia, '') AS ShipVia,
				ISNULL(SOQSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(SOQSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(SOQSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(SOQSV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(SOQAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(SOQAS.UserType, 0) AS BillToUserType,
				ISNULL(SOQAS.UserId, 0) AS BillToUserId,
				ISNULL(SOQAS.SiteId, 0) AS BillToSiteId,
				ISNULL(SOQAS.SiteName, '') AS BillToSiteName,
				SOQAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(SOQAS.ContactId, 0) AS BillToContactId,
				ISNULL(SOQAS.ContactName, '') AS BillToContactName,			
				ISNULL(SOQAS.Memo, '') AS BillToMemo,
				ISNULL(SOQAS.AddressId, 0) AS BillToAddressId,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQAS.Line1, '') AS BillToAddress1,
				ISNULL(SOQAS.Line2, '') AS BillToAddress2,
				ISNULL(SOQAS.City, '') AS BillToCity,
				ISNULL(SOQAS.CountryId, 0) AS BillToCountryId,
				ISNULL(SOQAS.Country, '') AS BillToCountryName,
				ISNULL(SOQAS.StateOrProvince, '') AS BillToState,
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode
			
			FROM ExchangeSalesOrder ExchSO WITH (NOLOCK)
				LEFT JOIN AllAddress SOQA WITH (NOLOCK) ON ExchSO.ExchangeSalesOrderId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
				LEFT JOIN AllAddress SOQAS WITH (NOLOCK) ON ExchSO.ExchangeSalesOrderId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
				LEFT JOIN AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = ExchSO.ExchangeSalesOrderId and SOQSV.ModuleId = @ModuleID
			WHERE ExchSO.ExchangeSalesOrderId = @Id;
		END

		ELSE IF(@AddressType = 'VRFQPO')
		BEGIN
		 SELECT PO.VendorRFQPurchaseOrderId,
				PO.MasterCompanyId,
				PO.IsActive,
				PO.IsDeleted,
				PO.CreatedDate,
				PO.UpdatedDate,
				PO.CreatedBy,
				PO.UpdatedBy,
				ISNULL(POA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(POA.UserType, 0) AS ShipToUserType,
				ISNULL(POA.UserId, 0) AS ShipToUserId,
				ISNULL(POA.SiteId, 0) AS ShipToSiteId,
				ISNULL(POA.SiteName, '') AS ShipToSiteName,
				POA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(POA.ContactId, 0) AS ShipToContactId,
				ISNULL(POA.ContactName, '') AS ShipToContact,
				ISNULL(POA.Memo, '') AS ShipToMemo,
				ISNULL(POA.AddressId, 0) AS ShipToAddressId,
				ISNULL(POA.Line1, '') AS ShipToAddress1,
				ISNULL(POA.Line2, '') AS ShipToAddress2,
				ISNULL(POA.City, '') AS ShipToCity,
				ISNULL(POA.CountryId, 0) AS ShipToCountryId,
				ISNULL(POA.Country, '') AS ShipToCountryName,
				ISNULL(POA.StateOrProvince, '') AS ShipToState,
				ISNULL(POA.PostalCode, '') AS ShipToPostalCode,
				ISNULL(POSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(POSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(POSV.ShipVia, '') AS ShipVia,
				ISNULL(POSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(POSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(POSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(POSV.ShippingAccountNo, '') AS ShippingAccountNo,
				ISNULL(POAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(POAS.UserType, 0) AS BillToUserType,
				ISNULL(POAS.UserId, 0) AS BillToUserId,
				ISNULL(POAS.SiteId, 0) AS BillToSiteId,
				ISNULL(POAS.SiteName, '') AS BillToSiteName,
				POAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(POAS.ContactId, 0) AS BillToContactId,
				ISNULL(POAS.ContactName, '') AS BillToContactName,			
				ISNULL(POAS.Memo, '') AS BillToMemo,
				ISNULL(POAS.AddressId, 0) AS BillToAddressId,
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(POAS.Line1, '') AS BillToAddress1,
				ISNULL(POAS.Line2, '') AS BillToAddress2,
				ISNULL(POAS.City, '') AS BillToCity,
				ISNULL(POAS.CountryId, 0) AS BillToCountryId,
				ISNULL(POAS.Country, '') AS BillToCountryName,
				ISNULL(POAS.StateOrProvince, '') AS BillToState,
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode
			
		FROM VendorRFQPurchaseOrder PO WITH (NOLOCK)
			LEFT JOIN AllAddress POA WITH (NOLOCK) ON PO.VendorRFQPurchaseOrderId = POA.ReffranceId AND POA.IsShippingAdd = 1 and POA.ModuleId = @ModuleID
			LEFT JOIN AllAddress POAS WITH (NOLOCK) ON PO.VendorRFQPurchaseOrderId = POAS.ReffranceId AND POAS.IsShippingAdd = 0 and POAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia POSV WITH (NOLOCK) ON POSV.ReferenceId = PO.VendorRFQPurchaseOrderId and POSV.ModuleId = @ModuleID
		WHERE PO.VendorRFQPurchaseOrderId = @Id;
		END

		ELSE IF(@AddressType = 'VRFQRO')
		BEGIN
		 SELECT PO.VendorRFQRepairOrderId,
				PO.MasterCompanyId,
				PO.IsActive,
				PO.IsDeleted,
				PO.CreatedDate,
				PO.UpdatedDate,
				PO.CreatedBy,
				PO.UpdatedBy,
				ISNULL(POA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(POA.UserType, 0) AS ShipToUserType,
				ISNULL(POA.UserId, 0) AS ShipToUserId,
				ISNULL(POA.SiteId, 0) AS ShipToSiteId,
				ISNULL(POA.SiteName, '') AS ShipToSiteName,
				POA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(POA.ContactId, 0) AS ShipToContactId,
				ISNULL(POA.ContactName, '') AS ShipToContact,
				ISNULL(POA.Memo, '') AS ShipToMemo,
				ISNULL(POA.AddressId, 0) AS ShipToAddressId,
				ISNULL(POA.Line1, '') AS ShipToAddress1,
				ISNULL(POA.Line2, '') AS ShipToAddress2,
				ISNULL(POA.City, '') AS ShipToCity,
				ISNULL(POA.CountryId, 0) AS ShipToCountryId,
				ISNULL(POA.Country, '') AS ShipToCountryName,
				ISNULL(POA.StateOrProvince, '') AS ShipToState,
				ISNULL(POA.PostalCode, '') AS ShipToPostalCode,
				ISNULL(POSV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(POSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(POSV.ShipVia, '') AS ShipVia,
				ISNULL(POSV.ShipViaId, 0) AS ShipViaId,
				ISNULL(POSV.ShippingCost, 0) AS ShippingCost,
				ISNULL(POSV.HandlingCost, 0) AS HandlingCost,
				ISNULL(POSV.ShippingAccountNo, '') AS ShippingAccountNo,
				ISNULL(POAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(POAS.UserType, 0) AS BillToUserType,
				ISNULL(POAS.UserId, 0) AS BillToUserId,
				ISNULL(POAS.SiteId, 0) AS BillToSiteId,
				ISNULL(POAS.SiteName, '') AS BillToSiteName,
				POAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(POAS.ContactId, 0) AS BillToContactId,
				ISNULL(POAS.ContactName, '') AS BillToContactName,			
				ISNULL(POAS.Memo, '') AS BillToMemo,
				ISNULL(POAS.AddressId, 0) AS BillToAddressId,
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(POAS.Line1, '') AS BillToAddress1,
				ISNULL(POAS.Line2, '') AS BillToAddress2,
				ISNULL(POAS.City, '') AS BillToCity,
				ISNULL(POAS.CountryId, 0) AS BillToCountryId,
				ISNULL(POAS.Country, '') AS BillToCountryName,
				ISNULL(POAS.StateOrProvince, '') AS BillToState,
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode
			
		FROM VendorRFQRepairOrder PO WITH (NOLOCK)
			LEFT JOIN AllAddress POA WITH (NOLOCK) ON PO.VendorRFQRepairOrderId = POA.ReffranceId AND POA.IsShippingAdd = 1 and POA.ModuleId = @ModuleID
			LEFT JOIN AllAddress POAS WITH (NOLOCK) ON PO.VendorRFQRepairOrderId = POAS.ReffranceId AND POAS.IsShippingAdd = 0 and POAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia POSV WITH (NOLOCK) ON POSV.ReferenceId = PO.VendorRFQRepairOrderId and POSV.ModuleId = @ModuleID
		WHERE PO.VendorRFQRepairOrderId = @Id;
	    END
		ELSE IF(@AddressType = 'RMA')
		BEGIN
		SELECT  CRMA.RMAHeaderId,
				CRMA.MasterCompanyId,
				CRMA.IsActive,
				CRMA.IsDeleted,
				CRMA.CreatedDate,
				CRMA.UpdatedDate,
				CRMA.CreatedBy,
				CRMA.UpdatedBy,
				ISNULL(RMAA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(RMAA.UserType, 0) AS ShipToUserType,
				ISNULL(RMAA.UserId, 0) AS ShipToUserId,
				ISNULL(RMAA.SiteId, 0) AS ShipToSiteId,
				ISNULL(RMAA.SiteName, '') AS ShipToSiteName,
				RMAA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(RMAA.ContactId, 0) AS ShipToContactId,
				ISNULL(RMAA.ContactName, '') AS ShipToContact,
				ISNULL(RMAA.Memo, '') AS ShipToMemo,
				ISNULL(RMAA.AddressId, 0) AS ShipToAddressId,
				ISNULL(RMAA.Line1, '') AS ShipToAddress1,
				ISNULL(RMAA.Line2, '') AS ShipToAddress2,
				ISNULL(RMAA.City, '') AS ShipToCity,
				ISNULL(RMAA.CountryId, 0) AS ShipToCountryId,
				ISNULL(RMAA.Country, '') AS ShipToCountryName,
				ISNULL(RMAA.StateOrProvince, '') AS ShipToState,
				ISNULL(RMAA.PostalCode, '') AS ShipToPostalCode,

				ISNULL(RMASV.AllShipViaId, 0) AS POShipViaId,
				ISNULL(RMASV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(RMASV.ShipVia, '') AS ShipVia,
				ISNULL(RMASV.ShipViaId, 0) AS ShipViaId,
				ISNULL(RMASV.ShippingCost, 0) AS ShippingCost,
				ISNULL(RMASV.HandlingCost, 0) AS HandlingCost,
				ISNULL(RMASV.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(RMAAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(RMAAS.UserType, 0) AS BillToUserType,
				ISNULL(RMAAS.UserId, 0) AS BillToUserId,
				ISNULL(RMAAS.SiteId, 0) AS BillToSiteId,
				ISNULL(RMAAS.SiteName, '') AS BillToSiteName,
				RMAAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(RMAAS.ContactId, 0) AS BillToContactId,
				ISNULL(RMAAS.ContactName, '') AS BillToContactName,			
				ISNULL(RMAAS.Memo, '') AS BillToMemo,
				ISNULL(RMAAS.AddressId, 0) AS BillToAddressId,
				ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(RMAAS.Line1, '') AS BillToAddress1,
				ISNULL(RMAAS.Line2, '') AS BillToAddress2,
				ISNULL(RMAAS.City, '') AS BillToCity,
				ISNULL(RMAAS.CountryId, 0) AS BillToCountryId,
				ISNULL(RMAAS.Country, '') AS BillToCountryName,
				ISNULL(RMAAS.StateOrProvince, '') AS BillToState,
				ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode
			
		FROM CustomerRMAHeader CRMA  WITH (NOLOCK)
			LEFT JOIN AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleID
			LEFT JOIN AllAddress RMAAS WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAAS.ReffranceId AND RMAAS.IsShippingAdd = 0 and RMAAS.ModuleId = @ModuleID
			LEFT JOIN AllShipVia RMASV WITH (NOLOCK) ON RMASV.ReferenceId = CRMA.RMAHeaderId and RMASV.ModuleId = @ModuleID
		WHERE CRMA.RMAHeaderId = @Id
		END


	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAddressById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Id, '') + ''',													   
													   @Parameter2 = ' + ISNULL(CAST(@AddressType AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END