

/*************************************************************           
 ** File:   [USP_GetAddressDetailsByUser]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Billing & Shiping Address for Purchage Order    
 ** Purpose:         
 ** Date:   09/23/2020        
          
 ** PARAMETERS:           
 @AddressType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/23/2020   Hemant Saliya Created
    2    07/01/2021   Vishal Suthar Added Attention field
     
 EXECUTE [USP_GetAddressDetailsByUser] 9, 97, 'Ship',20199
 EXECUTE [USP_GetAddressDetailsByUser] 9, 13, 'Ship'
 EXECUTE [USP_GetAddressDetailsByUser] 9, 98, 'Bill'
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetAddressDetailsByUser]    
(    
@UserTypeId BIGINT,   
@UserId BIGINT,
@AddressType VARCHAR(20),
@PurchaseOrderID  bigint = 0
)    
AS    
BEGIN    

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION   
	
		DECLARE @UserType NVARCHAR(50);

		SELECT @UserType = ModuleName FROM dbo.Module WITH (NOLOCK)  WHERE ModuleId = @UserTypeId;

		IF(@UserType = 'Company')
		BEGIN

			IF(@AddressType = 'Ship')
			BEGIN
				SELECT	LegalEntityShippingAddressId as SiteId, 
						SiteName, 
						IsPrimary, 
						AddressId,
						0 as IsPoOnly			
				FROM LegalEntityShippingAddress WITH (NOLOCK) 
				WHERE LegalEntityId = @UserId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				UNION 
				SELECT POOnlyAddressId as SiteId,
					   SiteName,
					   IsPrimary,
					   AddressId,
					   1 as IsPoOnly
				FROM dbo.[POOnlyAddress] WITH (NOLOCK)  
				WHERE PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND UserId = @UserId
					  AND IsShipping = 1
				ORDER BY SiteName desc


				SELECT	adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.LegalEntityShippingAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						0 as IsPoOnly,
						lsa.Attention
				FROM LegalEntityShippingAddress lsa WITH (NOLOCK) 
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.LegalEntityId = @UserId 
				AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
				UNION 
				SELECT  adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.POOnlyAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						1 as IsPoOnly,
						'' AS Attention
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND IsShipping = 1
					  AND UserId = @UserId
				ORDER BY SiteName desc

				SELECT	lec.ContactId as ContactId,  -- lec.LegalEntityContactId as ContactId,
						co.FirstName + ' ' + co.LastName AS [Name], lec.IsDefaultContact
				FROM dbo.LegalEntityContact lec WITH (NOLOCK) 
					JOIN dbo.Contact co WITH (NOLOCK)  ON co.ContactId = lec.ContactId
				WHERE LegalEntityId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1

				SELECT	lec.LegalEntityShippingId AS ShippingViaId,
						sv.Name,
						lec.ShippingAccountinfo AS ShippingAccountInfo,
						lec.Memo,
						lec.IsPrimary,
						sv.ShippingViaId AS ShipViaId,
						lec.LegalEntityShippingAddressId as ShippingId
				FROM dbo.LegalEntityShipping lec WITH (NOLOCK) 
					JOIN dbo.ShippingVia sv WITH (NOLOCK)  ON sv.ShippingViaId = lec.ShipViaId
				WHERE LegalEntityId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1
			END

			IF(@AddressType = 'Bill')
			BEGIN
			
				SELECT	LegalEntityBillingAddressId as SiteId, 
						SiteName, 
						IsPrimary, 
						AddressId,
						0 as IsPoOnly				
				FROM LegalEntityBillingAddress WITH (NOLOCK) 
				WHERE LegalEntityId = @UserId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				UNION 
				SELECT POOnlyAddressId as SiteId,
					   SiteName,
					   IsPrimary,
					   AddressId,
					   1 as IsPoOnly
				FROM dbo.[POOnlyAddress] WITH (NOLOCK)  
				WHERE PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND UserId = @UserId
					  AND IsShipping = 0
				ORDER BY SiteName desc
		
				SELECT	adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.LegalEntityBillingAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						0 as IsPoOnly,
						lsa.Attention
				FROM LegalEntityBillingAddress lsa WITH (NOLOCK) 
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.LegalEntityId = @UserId 
				AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
				UNION 
				SELECT  adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.POOnlyAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						1 as IsPoOnly,
						'' AS Attention
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND IsShipping = 0
					  AND UserId = @UserId
				ORDER BY SiteName desc

				SELECT	lec.ContactId as ContactId,  -- lec.LegalEntityContactId as ContactId,
						co.FirstName + ' ' + co.LastName AS [Name], lec.IsDefaultContact
				FROM dbo.LegalEntityContact lec WITH (NOLOCK) 
					JOIN dbo.Contact co WITH (NOLOCK)  ON co.ContactId = lec.ContactId
				WHERE LegalEntityId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1
			END
		END

		IF(@UserType = 'Customer')
		BEGIN
			
			IF(@AddressType = 'Ship')
			BEGIN
				SELECT	CustomerDomensticShippingId as SiteId, 
						SiteName, 
						IsPrimary, 
						AddressId,
						0 as IsPoOnly				
				FROM CustomerDomensticShipping WITH (NOLOCK) 
				WHERE CustomerId = @UserId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				UNION 
				SELECT POOnlyAddressId as SiteId,
					   SiteName,
					   IsPrimary,
					   AddressId,
					   1 as IsPoOnly
				FROM dbo.[POOnlyAddress] WITH (NOLOCK)  
				WHERE PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND UserId = @UserId
					  AND IsShipping = 1
				ORDER BY SiteName desc

				SELECT	adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.CustomerDomensticShippingId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						0 as IsPoOnly,
						lsa.Attention
				FROM CustomerDomensticShipping lsa WITH (NOLOCK) 
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.CustomerId = @UserId 
				AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
				UNION 
				SELECT  adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.POOnlyAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						1 as IsPoOnly,
						'' AS Attention
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND IsShipping = 1
					  AND UserId = @UserId
				ORDER BY SiteName desc

				SELECT	lec.ContactId as ContactId,  -- lec.CustomerContactId as ContactId,
						co.FirstName + ' ' + co.LastName AS [Name], lec.IsDefaultContact
				FROM dbo.CustomerContact lec WITH (NOLOCK) 
					JOIN dbo.Contact co WITH (NOLOCK)  ON co.ContactId = lec.ContactId
				WHERE CustomerId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1

				SELECT	lec.CustomerDomensticShippingShipViaId AS ShippingViaId,
						sv.Name,
						lec.ShippingAccountinfo AS ShippingAccountInfo,
						lec.Memo,
						lec.IsPrimary,
						sv.ShippingViaId AS ShipViaId,
						lec.CustomerDomensticShippingId as ShippingId
				FROM dbo.CustomerDomensticShippingShipVia lec WITH (NOLOCK) 
					JOIN dbo.ShippingVia sv WITH (NOLOCK)  ON sv.ShippingViaId = lec.ShipViaId
				WHERE CustomerId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1
			END

			IF(@AddressType = 'Bill')
			BEGIN
			
				SELECT	CustomerBillingAddressId as SiteId, 
						SiteName, 
						IsPrimary, 
						AddressId,
						0 as IsPoOnly				
				FROM CustomerBillingAddress WITH (NOLOCK) 
				WHERE CustomerId = @UserId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				UNION 
				SELECT POOnlyAddressId as SiteId,
					   SiteName,
					   IsPrimary,
					   AddressId,
					   1 as IsPoOnly
				FROM dbo.[POOnlyAddress] WITH (NOLOCK)  
				WHERE PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND UserId = @UserId
					  AND IsShipping = 0
				ORDER BY SiteName desc

				SELECT	adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.CustomerBillingAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						0 as IsPoOnly,
						lsa.Attention
				FROM CustomerBillingAddress lsa WITH (NOLOCK) 
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.CustomerId = @UserId 
				AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
				UNION 
				SELECT  adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.POOnlyAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						1 as IsPoOnly,
						'' AS Attention
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND IsShipping = 0
					  AND UserId = @UserId
				ORDER BY SiteName desc

				SELECT	lec.ContactId as ContactId,   -- lec.CustomerContactId as ContactId,
						co.FirstName + ' ' + co.LastName AS [Name], lec.IsDefaultContact
				FROM dbo.CustomerContact lec WITH (NOLOCK) 
					JOIN dbo.Contact co WITH (NOLOCK)  ON co.ContactId = lec.ContactId
				WHERE CustomerId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1
			END
		END

		IF(@UserType = 'Vendor')
		BEGIN
			IF(@AddressType = 'Ship')
			BEGIN
				SELECT	VendorShippingAddressId as SiteId, 
						SiteName, 
						IsPrimary, 
						AddressId,
						0 as IsPoOnly				
				FROM VendorShippingAddress WITH (NOLOCK) 
				WHERE VendorId = @UserId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				UNION 
				SELECT POOnlyAddressId as SiteId,
					   SiteName,
					   IsPrimary,
					   AddressId,
					   1 as IsPoOnly
				FROM dbo.[POOnlyAddress] WITH (NOLOCK)  
				WHERE PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND UserId = @UserId
					  AND IsShipping = 1
				ORDER BY SiteName desc

				SELECT	adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.VendorShippingAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						0 as IsPoOnly,
						lsa.Attention
				FROM VendorShippingAddress lsa WITH (NOLOCK) 
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.VendorId = @UserId 
				AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
				UNION 
				SELECT  adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.POOnlyAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						1 as IsPoOnly,
						'' AS Attention
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND IsShipping = 1
					  AND UserId = @UserId
				ORDER BY SiteName desc

				SELECT	lec.ContactId as ContactId,  -- lec.VendorContactId as ContactId,
						co.FirstName + ' ' + co.LastName AS [Name], lec.IsDefaultContact
				FROM dbo.VendorContact lec WITH (NOLOCK) 
					JOIN dbo.Contact co WITH (NOLOCK)  ON co.ContactId = lec.ContactId
				WHERE VendorId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1

				SELECT	lec.VendorShippingId AS ShippingViaId,
						sv.Name,
						lec.ShippingAccountinfo AS ShippingAccountInfo,
						lec.Memo,
						lec.IsPrimary,
						sv.ShippingViaId AS ShipViaId,
						lec.VendorShippingAddressId as ShippingId
				FROM dbo.VendorShipping lec WITH (NOLOCK) 
					JOIN dbo.ShippingVia sv WITH (NOLOCK)  ON sv.ShippingViaId = lec.ShipViaId
				WHERE VendorId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1
			END

			IF(@AddressType = 'Bill')
			BEGIN
			
				SELECT	VendorBillingAddressId as SiteId, 
						SiteName, 
						IsPrimary, 
						AddressId,
						0 as IsPoOnly				
				FROM VendorBillingAddress WITH (NOLOCK) 
				WHERE VendorId = @UserId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				UNION 
				SELECT POOnlyAddressId as SiteId,
					   SiteName,
					   IsPrimary,
					   AddressId,
					   1 as IsPoOnly
				FROM dbo.[POOnlyAddress] WITH (NOLOCK)  
				WHERE PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND UserId = @UserId
					  AND IsShipping = 0
				ORDER BY SiteName desc

				SELECT	adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.VendorBillingAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						0 as IsPoOnly,
						lsa.Attention
				FROM VendorBillingAddress lsa WITH (NOLOCK) 
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.VendorId = @UserId 
				AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
				UNION 
				SELECT  adr.AddressId,
						adr.Line1 AS Address1,
						adr.Line2 AS Address2,
						adr.Line3 AS Address3,
						adr.City,
						adr.StateOrProvince,
						adr.PostalCode,
						adr.CountryId,
						c.countries_name,
						lsa.POOnlyAddressId as SiteID,
						lsa.SiteName as SiteName,
						lsa.IsPrimary,
						1 as IsPoOnly,
						'' AS Attention
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.PurchaseOrderid = @PurchaseOrderID 
					  AND UserType = @UserTypeId
					  AND IsShipping = 0
					  AND UserId = @UserId
				ORDER BY SiteName desc

				SELECT	lec.ContactId as ContactId, -- lec.VendorContactId as ContactId,
						co.FirstName + ' ' + co.LastName AS [Name], lec.IsDefaultContact
				FROM dbo.VendorContact lec WITH (NOLOCK) 
					JOIN dbo.Contact co WITH (NOLOCK)  ON co.ContactId = lec.ContactId
				WHERE VendorId = @UserId AND ISNULL(lec.IsDeleted,0) = 0 AND ISNULL(lec.IsActive,1) = 1
			END
		END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetAddressDetailsByUser' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@UserTypeId, '') + ''',													   
													@Parameter2 = ' + ISNULL(CAST(@UserId AS varchar(10)) ,'') +''
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