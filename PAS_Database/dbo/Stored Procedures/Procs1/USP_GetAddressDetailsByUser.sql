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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/23/2020   Hemant Saliya		Created
    2    07/01/2021   Vishal Suthar		Added Attention field
	3    06/29/2023   Amit Ghediya		Added Vendor RMA both ship/bill address.
     
 EXECUTE [USP_GetAddressDetailsByUser] 9, 97, 'Ship',20199
 EXECUTE [USP_GetAddressDetailsByUser] 9, 13, 'Ship'
 EXECUTE [USP_GetAddressDetailsByUser] 9, 98, 'Bill'
  EXECUTE [USP_GetAddressDetailsByUser] 45, 2492, 'Ship' --VendorRMA
  EXECUTE [USP_GetAddressDetailsByUser] 45, 34, 'Bill',53 --VendorRMA
**************************************************************/ 
    
CREATE    PROCEDURE [dbo].[USP_GetAddressDetailsByUser]    
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

		IF(@UserType = 'VendorRMA')
		BEGIN
			IF(@AddressType = 'Ship')
			BEGIN

				SELECT DISTINCT 
						VSA.AddressId AS AddressId,VSA.AddressId AS SiteId,VSA.SiteName AS SiteName,VSA.IsPrimary,0 AS IsPoOnly
					FROM Vendor V WITH (NOLOCK)
						LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 --AND VSA.IsPrimary = 1
						LEFT JOIN Address SAD WITH (NOLOCK) ON SAD.AddressId = VSA.AddressId AND SAD.IsActive = 1
						LEFT JOIN Countries SCO WITH (NOLOCK) ON SAD.CountryId = SCO.countries_id AND SCO.IsActive = 1
						WHERE V.VendorId = @UserId;

				SELECT DISTINCT V.VendorId,V.VendorName,V.VendorCode,V.MasterCompanyId,V.IsActive,V.IsDeleted,V.CreatedDate,V.UpdatedDate,V.CreatedBy,V.UpdatedBy,
						VSA.AddressId AS AddressId,VSA.AddressId AS SiteId,VSA.SiteName AS SiteName,VSA.IsPrimary,0 AS IsPoOnly,'' AS Attention,
						SAD.Line1 AS Address1,SAD.Line2 AS Address2,SAD.Line3 AS Address3,SAD.City AS City,SAD.StateOrProvince AS StateOrProvince,SAD.PostalCode AS PostalCode,
						SCO.countries_id AS CountryId,SCO.countries_name AS countries_name,SCO.nice_name AS Billnice_name,SCO.countries_isd_code AS Billcountries_isd_code,SCO.countries_iso3 AS Billcountries_iso3

					FROM Vendor V WITH (NOLOCK)
						LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 --AND VSA.IsPrimary = 1
						LEFT JOIN Address SAD WITH (NOLOCK) ON SAD.AddressId = VSA.AddressId AND SAD.IsActive = 1
						LEFT JOIN Countries SCO WITH (NOLOCK) ON SAD.CountryId = SCO.countries_id AND SCO.IsActive = 1
						WHERE V.VendorId = @UserId

				SELECT 0 AS ContactId, '' AS Name, VSA.IsPrimary AS IsDefaultContact
				FROM Vendor V WITH (NOLOCK)
						LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 --AND VSA.IsPrimary = 1
						LEFT JOIN Address SAD WITH (NOLOCK) ON SAD.AddressId = VSA.AddressId AND SAD.IsActive = 1
						LEFT JOIN Countries SCO WITH (NOLOCK) ON SAD.CountryId = SCO.countries_id AND SCO.IsActive = 1
						WHERE V.VendorId = @UserId;

				select SV.ShippingViaId, SV.ShippingViaId AS ShipViaId, SV.Name,VS.ShippingAccountinfo,0 AS ShippingId,VS.IsPrimary,VS.Memo
					FROM Vendor V WITH (NOLOCK)
						--LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 --AND VSA.IsPrimary = 1
						LEFT JOIN VendorShipping VS WITH (NOLOCK) ON V.VendorId = VS.VendorId AND VS.IsActive = 1
						LEFT JOIN ShippingVia SV WITH (NOLOCK) ON  VS.ShipViaId = SV.ShippingViaId
						LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON VS.VendorShippingAddressId = vsa.VendorShippingAddressId
						WHERE V.VendorId = @UserId;

				--SELECT 0 AS ShippingViaId,0 AS ShipViaId,'' AS Name,'' AS ShippingAccountInfo,'' AS Memo,VSA.IsPrimary AS IsPrimary,0 AS ShippingId
				--FROM Vendor V WITH (NOLOCK)
				--		LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 --AND VSA.IsPrimary = 1
				--		--LEFT JOIN Address SAD WITH (NOLOCK) ON SAD.AddressId = VSA.AddressId AND SAD.IsActive = 1
				--		--LEFT JOIN Countries SCO WITH (NOLOCK) ON SAD.CountryId = SCO.countries_id AND SCO.IsActive = 1
				--		WHERE V.VendorId = @UserId;

				--SELECT DISTINCT V.VendorId,V.VendorName,V.VendorCode,V.MasterCompanyId,V.IsActive,V.IsDeleted,V.CreatedDate,V.UpdatedDate,V.CreatedBy,V.UpdatedBy,
				--		VSA.AddressId AS ShipAddressId,VSA.SiteName AS ShipSiteName,VSA.IsPrimary,
				--		SAD.Line1 AS ShipLine1,SAD.Line2 AS ShipLine2,SAD.Line3 AS ShipLine3,SAD.City AS ShipCity,SAD.StateOrProvince AS ShipStateOrProvince,SAD.PostalCode AS ShipPostalCode,
				--		SCO.countries_name AS Shipcountries_name,SCO.nice_name AS Shipnice_name,SCO.countries_isd_code AS Shipcountries_isd_code,SCO.countries_iso3 AS Shipcountries_iso3  

				--FROM Vendor V WITH (NOLOCK)
				--		LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 AND VSA.IsPrimary = 1
				--		--LEFT JOIN VendorBillingAddress VBA WITH (NOLOCK) ON V.VendorId = VBA.VendorId AND VBA.IsActive = 1 AND VBA.IsPrimary = 1
				--		LEFT JOIN Address SAD WITH (NOLOCK) ON SAD.AddressId = VSA.AddressId AND SAD.IsActive = 1
				--		--LEFT JOIN Address BAD WITH (NOLOCK) ON BAD.AddressId = VBA.AddressId AND BAD.IsActive = 1
				--		LEFT JOIN Countries SCO WITH (NOLOCK) ON SAD.CountryId = SCO.countries_id AND SCO.IsActive = 1
				--		--LEFT JOIN Countries BCO WITH (NOLOCK) ON BAD.CountryId = BCO.countries_id AND BCO.IsActive = 1
				--	WHERE V.VendorId = @UserId;
			END
			IF(@AddressType = 'Bill')
			BEGIN
				SELECT DISTINCT 
						VBA.AddressId AS AddressId,VBA.AddressId AS SiteId,VBA.SiteName AS SiteName,VBA.IsPrimary,0 AS IsPoOnly
					FROM Vendor V WITH (NOLOCK)
								LEFT JOIN VendorBillingAddress VBA WITH (NOLOCK) ON V.VendorId = VBA.VendorId AND VBA.IsActive = 1 --AND VBA.IsPrimary = 1
								LEFT JOIN Address BAD WITH (NOLOCK) ON BAD.AddressId = VBA.AddressId AND BAD.IsActive = 1
								LEFT JOIN Countries BCO WITH (NOLOCK) ON BAD.CountryId = BCO.countries_id AND BCO.IsActive = 1
						WHERE V.VendorId = @UserId;

				SELECT DISTINCT V.VendorId,V.VendorName,V.VendorCode,V.MasterCompanyId,V.IsActive,V.IsDeleted,V.CreatedDate,V.UpdatedDate,V.CreatedBy,V.UpdatedBy,
						VBA.AddressId AS AddressId,VBA.AddressId AS SiteId,VBA.SiteName AS SiteName,VBA.IsPrimary,0 AS IsPoOnly,'' AS Attention,
						BAD.Line1 AS Address1,BAD.Line2 AS Address2,BAD.Line3 AS Address3,BAD.City AS City,BAD.StateOrProvince AS StateOrProvince,BAD.PostalCode AS PostalCode,
						BCO.countries_id AS CountryId,BCO.countries_name AS countries_name,BCO.nice_name AS Billnice_name,BCO.countries_isd_code AS Billcountries_isd_code,BCO.countries_iso3 AS Billcountries_iso3

					FROM Vendor V WITH (NOLOCK)
								LEFT JOIN VendorBillingAddress VBA WITH (NOLOCK) ON V.VendorId = VBA.VendorId AND VBA.IsActive = 1 --AND VBA.IsPrimary = 1
								LEFT JOIN Address BAD WITH (NOLOCK) ON BAD.AddressId = VBA.AddressId AND BAD.IsActive = 1
								LEFT JOIN Countries BCO WITH (NOLOCK) ON BAD.CountryId = BCO.countries_id AND BCO.IsActive = 1
						WHERE V.VendorId = @UserId

				SELECT 0 AS ContactId, '' AS Name, VBA.IsPrimary AS IsDefaultContact
				FROM Vendor V WITH (NOLOCK)
								LEFT JOIN VendorBillingAddress VBA WITH (NOLOCK) ON V.VendorId = VBA.VendorId AND VBA.IsActive = 1 --AND VBA.IsPrimary = 1
								LEFT JOIN Address BAD WITH (NOLOCK) ON BAD.AddressId = VBA.AddressId AND BAD.IsActive = 1
								LEFT JOIN Countries BCO WITH (NOLOCK) ON BAD.CountryId = BCO.countries_id AND BCO.IsActive = 1
						WHERE V.VendorId = @UserId;

				select SV.ShippingViaId,SV.ShippingViaId AS ShipViaId, SV.Name,VS.ShippingAccountinfo,0 AS ShippingId,VS.IsPrimary,VS.Memo
					FROM Vendor V WITH (NOLOCK)
						--LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON V.VendorId = VSA.VendorId AND VSA.IsActive = 1 --AND VSA.IsPrimary = 1
						LEFT JOIN VendorShipping VS WITH (NOLOCK) ON V.VendorId = VS.VendorId AND VS.IsActive = 1
						LEFT JOIN ShippingVia SV WITH (NOLOCK) ON  VS.ShipViaId = SV.ShippingViaId
						LEFT JOIN VendorShippingAddress VSA WITH (NOLOCK) ON VS.VendorShippingAddressId = vsa.VendorShippingAddressId
						WHERE V.VendorId = @UserId;

				--SELECT 0 AS ShippingViaId,0 AS ShipViaId,'' AS Name,'' AS ShippingAccountInfo,'' AS Memo,VBA.IsPrimary AS IsPrimary,0 AS ShippingId
				--FROM Vendor V WITH (NOLOCK)
				--				LEFT JOIN VendorBillingAddress VBA WITH (NOLOCK) ON V.VendorId = VBA.VendorId AND VBA.IsActive = 1 --AND VBA.IsPrimary = 1
				--				LEFT JOIN Address BAD WITH (NOLOCK) ON BAD.AddressId = VBA.AddressId AND BAD.IsActive = 1
				--				LEFT JOIN Countries BCO WITH (NOLOCK) ON BAD.CountryId = BCO.countries_id AND BCO.IsActive = 1
				--		WHERE V.VendorId = @UserId;
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