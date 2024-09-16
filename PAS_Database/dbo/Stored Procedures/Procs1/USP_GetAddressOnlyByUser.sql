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
    1    09/23/2020   Happy Chandigara Created
	2    13-09-2024   Shrey Chandegara  Add referenceid and moduleid.
     
 EXECUTE [USP_GetAddressOnlyByUser] 2, 97, 'Ship',20199
 EXECUTE [USP_GetAddressDetailsByUser] 9, 13, 'Ship'
 EXECUTE [USP_GetAddressDetailsByUser] 9, 98, 'Bill'
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetAddressOnlyByUser]    
(    
@UserTypeId BIGINT,   
@UserId BIGINT,
@AddressType VARCHAR(20),
@ModuleId BIGINT,
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
						0 as IsPoOnly	
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
						1 as IsPoOnly
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.ReferenceID = @PurchaseOrderID  AND lsa.ModuleId = @ModuleId
					  AND UserType = @UserTypeId
					  AND IsShipping = 1
					  AND UserId = @UserId
				ORDER BY SiteName desc
			END

			IF(@AddressType = 'Bill')
			BEGIN			
			
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
						0 as IsPoOnly	
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
						1 as IsPoOnly
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.ReferenceId = @PurchaseOrderID AND lsa.ModuleId = @ModuleId
					  AND UserType = @UserTypeId
					  AND IsShipping = 0
					  AND UserId = @UserId
				ORDER BY SiteName desc
			END
		END

		IF(@UserType = 'Customer')
		BEGIN
			
			IF(@AddressType = 'Ship')
			BEGIN			

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
						0 as IsPoOnly	
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
						1 as IsPoOnly
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.ReferenceId = @PurchaseOrderID AND lsa.ModuleId = @ModuleId
					  AND UserType = @UserTypeId
					  AND IsShipping = 1
					  AND UserId = @UserId
				ORDER BY SiteName desc
			END

			IF(@AddressType = 'Bill')
			BEGIN		
			
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
						0 as IsPoOnly	
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
						1 as IsPoOnly
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.ReferenceId = @PurchaseOrderID AND lsa.ModuleId = @ModuleId
					  AND UserType = @UserTypeId
					  AND IsShipping = 0
					  AND UserId = @UserId
				ORDER BY SiteName desc
			END
		END

		IF(@UserType = 'Vendor')
		BEGIN
			IF(@AddressType = 'Ship')
			BEGIN		

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
						0 as IsPoOnly	
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
						1 as IsPoOnly
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.ReferenceId = @PurchaseOrderID AND lsa.ModuleId = @ModuleId
					  AND UserType = @UserTypeId
					  AND IsShipping = 1
					  AND UserId = @UserId
				ORDER BY SiteName desc
			END

			IF(@AddressType = 'Bill')
			BEGIN			
		
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
						0 as IsPoOnly	
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
						1 as IsPoOnly
				FROM dbo.[POOnlyAddress] lsa WITH (NOLOCK)  
				JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
				LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
				WHERE lsa.ReferenceId = @PurchaseOrderID AND lsa.ModuleId = @ModuleId
					  AND UserType = @UserTypeId
					  AND IsShipping = 0
					  AND UserId = @UserId
				ORDER BY SiteName desc
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
            , @AdhocComments     VARCHAR(150)    = 'USP_GetAddressOnlyByUser' 
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