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
    1    12/28/2020   Deep Patel	Changes related to AllAddress Common table.
	2    06/29/2023   Amit Ghediya	Changes related to get Vendor Address of VendorRMA Bill/Ship Address.
	3	 03/04/2024   Bhargav Saliya Resolved Ship-To address issue in Shipping (Single Part) 
	4	 07/23/2024	  Bhargav Saliya Added ShippingTerms
     
exec dbo.USP_GetAddressById @Id=111,@AddressType=N'VendorRMA',@ModuleID=0
**************************************************************/ 
    
CREATE       PROCEDURE [dbo].[USP_GetAddressById]
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
		
		DECLARE @vendorID BIGINT;

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
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(POSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].PurchaseOrder PO WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress POA WITH (NOLOCK) ON PO.PurchaseOrderId = POA.ReffranceId AND POA.IsShippingAdd = 1 and POA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress POAS WITH (NOLOCK) ON PO.PurchaseOrderId = POAS.ReffranceId AND POAS.IsShippingAdd = 0 and POAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia POSV WITH (NOLOCK) ON POSV.ReferenceId = PO.PurchaseOrderId and POSV.ModuleId = @ModuleID
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
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].SalesOrderQuote SOQ WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress SOQAS WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = SOQ.SalesOrderQuoteId and SOQSV.ModuleId = @ModuleID
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
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].SalesOrder SO WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress SOQA WITH (NOLOCK) ON SO.SalesOrderId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress SOQAS WITH (NOLOCK) ON SO.SalesOrderId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = SO.SalesOrderId and SOQSV.ModuleId = @ModuleID
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
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].RepairOrder RO WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress ROQA WITH (NOLOCK) ON RO.RepairOrderId = ROQA.ReffranceId AND ROQA.IsShippingAdd = 1 and ROQA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress SOQAS WITH (NOLOCK) ON RO.RepairOrderId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = RO.RepairOrderId and SOQSV.ModuleId = @ModuleID
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
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].ExchangeQuote EQ WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress SOQA WITH (NOLOCK) ON EQ.ExchangeQuoteId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress SOQAS WITH (NOLOCK) ON EQ.ExchangeQuoteId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = EQ.ExchangeQuoteId and SOQSV.ModuleId = @ModuleID
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
				ISNULL(SOQAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(SOQSV.ShippingTerms, '') AS ShippingTerms
			
			FROM [DBO].ExchangeSalesOrder ExchSO WITH (NOLOCK)
				LEFT JOIN [DBO].AllAddress SOQA WITH (NOLOCK) ON ExchSO.ExchangeSalesOrderId = SOQA.ReffranceId AND SOQA.IsShippingAdd = 1 and SOQA.ModuleId = @ModuleID
				LEFT JOIN [DBO].AllAddress SOQAS WITH (NOLOCK) ON ExchSO.ExchangeSalesOrderId = SOQAS.ReffranceId AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
				LEFT JOIN [DBO].AllShipVia SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = ExchSO.ExchangeSalesOrderId and SOQSV.ModuleId = @ModuleID
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
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(POSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].VendorRFQPurchaseOrder PO WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress POA WITH (NOLOCK) ON PO.VendorRFQPurchaseOrderId = POA.ReffranceId AND POA.IsShippingAdd = 1 and POA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress POAS WITH (NOLOCK) ON PO.VendorRFQPurchaseOrderId = POAS.ReffranceId AND POAS.IsShippingAdd = 0 and POAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia POSV WITH (NOLOCK) ON POSV.ReferenceId = PO.VendorRFQPurchaseOrderId and POSV.ModuleId = @ModuleID
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
				ISNULL(POAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(POSV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].VendorRFQRepairOrder PO WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress POA WITH (NOLOCK) ON PO.VendorRFQRepairOrderId = POA.ReffranceId AND POA.IsShippingAdd = 1 and POA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress POAS WITH (NOLOCK) ON PO.VendorRFQRepairOrderId = POAS.ReffranceId AND POAS.IsShippingAdd = 0 and POAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia POSV WITH (NOLOCK) ON POSV.ReferenceId = PO.VendorRFQRepairOrderId and POSV.ModuleId = @ModuleID
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
				ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(RMASV.ShippingTerms, '') AS ShippingTerms
			
		FROM [DBO].CustomerRMAHeader CRMA  WITH (NOLOCK)
			LEFT JOIN [DBO].AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllAddress RMAAS WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAAS.ReffranceId AND RMAAS.IsShippingAdd = 0 and RMAAS.ModuleId = @ModuleID
			LEFT JOIN [DBO].AllShipVia RMASV WITH (NOLOCK) ON RMASV.ReferenceId = CRMA.RMAHeaderId and RMASV.ModuleId = @ModuleID
		WHERE CRMA.RMAHeaderId = @Id
		END

		ELSE IF(@AddressType = 'VendorRMA')
		BEGIN
			DECLARE @RMADetailCount INT = 0;
			--Get Vendor id get from vendorrma table.
			SELECT @vendorID = VendorId FROM [DBO].VendorRMA WITH (NOLOCK) WHERE VendorRMAId = @Id;
			SELECT @RMADetailCount = COUNT(VendorRMADetailId) FROM [DBO].VendorRMADetail CVRMA WITH (NOLOCK) 
				   JOIN [DBO].VendorRMA VRMA WITH (NOLOCK) ON VRMA.VendorRMAId = CVRMA.VendorRMAId
			WHERE VRMA.VendorRMAId = @Id;

			SELECT DISTINCT V.VendorId,V.VendorName,V.VendorCode,V.MasterCompanyId,V.IsActive,V.IsDeleted,V.CreatedDate,V.UpdatedDate,V.CreatedBy,V.UpdatedBy,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN ARD.VendorShippingAddressId ELSE VSA.AddressId END AS ShipAddressId,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIPVSA.SiteName ELSE VSA.SiteName END AS ShipSiteName,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIP.Line1 ELSE SAD.Line1 END AS ShipLine1,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIP.Line2 ELSE SAD.Line2 END AS ShipLine2,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIP.Line3 ELSE SAD.Line3 END AS ShipLine3,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIP.City ELSE SAD.City END AS ShipCity,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIP.StateOrProvince ELSE SAD.StateOrProvince END AS ShipStateOrProvince,
				   CASE WHEN ISNULL(ARD.VendorShippingAddressId ,0) > 0 AND @RMADetailCount = 1 THEN SHIP.PostalCode ELSE SAD.PostalCode END AS ShipPostalCode,

				   --VSA.AddressId AS ShipAddressId,
				   --VSA.SiteName AS ShipSiteName,
				   --SAD.Line1 AS ShipLine1,
				   --SAD.Line2 AS ShipLine2,
				   --SAD.Line3 AS ShipLine3,
				   --SAD.City AS ShipCity,
				   --SAD.StateOrProvince AS ShipStateOrProvince,
				   --SAD.PostalCode AS ShipPostalCode,

				   SCO.countries_name AS Shipcountries_name,SCO.nice_name AS Shipnice_name,SCO.countries_isd_code AS Shipcountries_isd_code,SCO.countries_iso3 AS Shipcountries_iso3,	  
				   VBA.AddressId AS BillAddressId,
				   VBA.SiteName AS BillSiteName,
				   BAD.Line1 AS BillLine1,BAD.Line2 AS BillLine2,BAD.Line3 AS BillLine3,BAD.City AS BillCity,BAD.StateOrProvince AS BillStateOrProvince,BAD.PostalCode AS BillPostalCode,
				   BCO.countries_id AS countries_id,BCO.countries_name AS Billcountries_name,BCO.nice_name AS Billnice_name,BCO.countries_isd_code AS Billcountries_isd_code,BCO.countries_iso3 AS Billcountries_iso3,
				   SV.ShippingViaId, SV.Name,VS.ShippingAccountinfo,Vs.ShippingId,VS.IsPrimary
		FROM [DBO].Vendor V WITH (NOLOCK)
				LEFT JOIN [DBO].VendorShipping VS WITH (NOLOCK) ON V.VendorId = VS.VendorId AND VS.IsActive = 1
				LEFT JOIN [DBO].VendorRMA VR with (nolock) on VR.VendorId = V.VendorId
				LEFT JOIN [DBO].VendorRMADetail ARD WITH (NOLOCK) ON ARD.VendorRMAId = VR.VendorRMAId
				LEFT JOIN [DBO].ShippingVia SV WITH (NOLOCK) ON  VS.ShipViaId = SV.ShippingViaId
				LEFT JOIN [DBO].VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 AND VSA.IsPrimary = 1
				LEFT JOIN [DBO].VendorBillingAddress VBA WITH (NOLOCK) ON V.VendorId = VBA.VendorId AND VBA.IsActive = 1 AND VBA.IsPrimary = 1
				LEFT JOIN [DBO].Address SHIP WITH (NOLOCK) ON SHIP.AddressId = ARD.VendorShippingAddressId AND SHIP.IsActive = 1
				LEFT JOIN [DBO].VendorShippingAddress SHIPVSA WITH (NOLOCK) ON V.VendorId = SHIPVSA.VendorId AND VSA.IsActive = 1 AND VSA.AddressId = ARD.VendorShippingAddressId
				LEFT JOIN [DBO].Address SAD WITH (NOLOCK) ON SAD.AddressId = VSA.AddressId AND SAD.IsActive = 1
				LEFT JOIN [DBO].Address BAD WITH (NOLOCK) ON BAD.AddressId = VBA.AddressId AND BAD.IsActive = 1
				LEFT JOIN [DBO].Countries SCO WITH (NOLOCK) ON SAD.CountryId = SCO.countries_id AND SCO.IsActive = 1
				LEFT JOIN [DBO].Countries BCO WITH (NOLOCK) ON BAD.CountryId = BCO.countries_id AND BCO.IsActive = 1
			WHERE V.VendorId = @vendorID AND VR.VendorRMAId = @Id; 
			---WHERE V.VendorId = @vendorID;
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