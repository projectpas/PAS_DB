
/*************************************************************           
 ** File:   [USP_GetSalesOrderShippingAddressById]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used retrieve Shipping Address Deatais For Billing and Invoicing  
 ** Purpose:         
 ** Date:   07/02/2024        
          
 ** PARAMETERS:  @SalesOrderShippingId,@SalesOrderId
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/02/2024   Moin Bloch      Created

   EXECUTE [USP_GetSalesOrderShippingAddressById] 10358,10812
**************************************************************/ 
    
CREATE   PROCEDURE [dbo].[USP_GetSalesOrderShippingAddressById]
@SalesOrderShippingId  BIGINT,
@SalesOrderId BIGINT
AS    
BEGIN    

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	DECLARE @ModuleID INT,@CustomerModuleID INT,@VendorModuleID INT,@CompanyModuleID INT;

	SELECT @ModuleID = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @CustomerModuleID = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Customer';
	SELECT @VendorModuleID = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Vendor';
	SELECT @CompanyModuleID = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Company';
				
	BEGIN TRY	
	
	     SELECT SOS.SalesOrderId,  
				SOS.MasterCompanyId,
				SOS.IsActive,
				SOS.IsDeleted,
				SOS.CreatedDate,
				SOS.UpdatedDate,
				SOS.CreatedBy,
				SOS.UpdatedBy,
				ISNULL(SOQA.AllAddressId, 0) AS ShipToPOAddressId,
				ISNULL(SOQA.UserType, 0) AS ShipToUserType,
				ISNULL(SOS.ShipToCustomerId, 0) AS ShipToUserId,				
				ISNULL(SOS.ShipToName, '') AS ShipToUserName,
				ISNULL(SOS.ShipToSiteId, 0) AS ShipToSiteId,
				ISNULL(SOS.ShipToSiteName, '') AS ShipToSiteName,				
				SOQA.IsModuleOnly AS ShipAddIsPoOnly,
				ISNULL(SOQA.ContactId, 0) AS ShipToContactId,
				ISNULL(SOQA.ContactName, '') AS ShipToContact,
				ISNULL(SOQA.Memo, '') AS ShipToMemo,
				ISNULL(SOQA.AddressId, 0) AS ShipToAddressId,
				ISNULL(SOS.ShipToAddress1, '') AS ShipToAddress1,
				ISNULL(SOS.ShipToAddress2, '') AS ShipToAddress2,
				ISNULL(SOS.ShipToCity, '') AS ShipToCity,
				ISNULL(SOS.ShipToCountryId, 0) AS ShipToCountryId,
				ISNULL(SOS.ShipToCountryName, '') AS ShipToCountryName,
				ISNULL(SOS.ShipToState, '') AS ShipToState,
				ISNULL(SOS.ShipToZip, '') AS ShipToPostalCode,
				ISNULL(SOS.ShipViaId, 0) AS POShipViaId,
				ISNULL(SOQSV.ShippingViaId, 0) AS ShippingViaId,
				ISNULL(SOSV.[Name], '') AS ShipVia,
				ISNULL(SOS.ShipViaId, 0) AS ShipViaId,
				ISNULL(SOS.ShippingAccountNo, '') AS ShippingAccountNo,

				ISNULL(SOQAS.AllAddressId, 0) AS BillToPOAddressId,
				ISNULL(SOQAS.UserType, 0) AS BillToUserType,
				CASE WHEN SOQAS.UserType = @CustomerModuleID
				     THEN (SELECT CustomerId FROM dbo.Customer WHERE UPPER([NAME]) = UPPER(SOS.SoldToName))
					 WHEN SOQAS.UserType = @VendorModuleID
					 THEN (SELECT VendorId FROM dbo.Vendor WHERE UPPER([VendorName]) = UPPER(SOS.SoldToName))
					 WHEN SOQAS.UserType = @CompanyModuleID
					 THEN (SELECT LegalEntityId FROM dbo.LegalEntity WHERE UPPER([NAME]) = UPPER(SOS.SoldToName))
				END AS BillToUserId,	
				ISNULL(SOS.SoldToName,'')BillToUserName,				
				ISNULL(SOS.SoldToSiteId, 0) AS BillToSiteId,
				ISNULL(SOS.SoldToSiteName, '') AS BillToSiteName,
				SOQAS.IsModuleOnly AS BillAddIsPoOnly,
				ISNULL(SOQAS.ContactId, 0) AS BillToContactId,
				ISNULL(SOQAS.ContactName, '') AS BillToContactName,			
				ISNULL(SOQAS.Memo, '') AS BillToMemo,
				ISNULL(SOQAS.AddressId, 0) AS BillToAddressId,
				ISNULL(SOS.SoldToZip, '') AS BillToPostalCode,
				ISNULL(SOS.SoldToAddress1, '') AS BillToAddress1,
				ISNULL(SOS.SoldToAddress2, '') AS BillToAddress2,
				ISNULL(SOS.SoldToCity, '') AS BillToCity,
				ISNULL(SOS.SoldToCountryId, 0) AS BillToCountryId,
				ISNULL(SOS.SoldToCountryName, '') AS BillToCountryName,
				ISNULL(SOS.SoldToState, '') AS BillToState

		   FROM [dbo].[SalesOrderShipping] SOS WITH (NOLOCK)
			LEFT JOIN [dbo].[AllAddress] SOQA WITH (NOLOCK) ON SOQA.ReffranceId = SOS.SalesOrderId AND SOQA.IsShippingAdd = 1 AND SOQA.ModuleId = @ModuleID			
			LEFT JOIN [dbo].[AllAddress] SOQAS WITH (NOLOCK)ON SOQAS.ReffranceId = SOS.SalesOrderId  AND SOQAS.IsShippingAdd = 0 and SOQAS.ModuleId = @ModuleID
			LEFT JOIN [dbo].[AllShipVia] SOQSV WITH (NOLOCK) ON SOQSV.ReferenceId = SOS.SalesOrderId AND SOQSV.ModuleId = @ModuleID
			LEFT JOIN [dbo].[ShippingVia] SOSV WITH (NOLOCK) ON SOS.ShipViaId = SOSV.ShippingViaId 
		    WHERE SOS.[SalesOrderShippingId] = @SalesOrderShippingId 
		      AND SOS.[SalesOrderId] = @SalesOrderId

	END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSalesOrderShippingAddressById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter2 = ' + ISNULL(CAST(@SalesOrderId AS varchar(10)) ,'') +''
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