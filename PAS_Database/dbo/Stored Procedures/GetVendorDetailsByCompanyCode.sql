/*************************************************************             
 ** File:   [GetVendorDetailsByCompanyCode]            
 ** Author:  RAJESH GAMI
 ** Description: This stored procedure is used to get vendor details by company code (General Info, Contact Details, Billing and Shipping Details)
 ** Purpose:           
 ** Date:  09 Mar 2026        
            
 ** PARAMETERS: @companyCode VARCHAR(30)  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    09 Mar 2026		RAJESH GAMI	 Created  

 EXEC GetVendorDetailsByCompanyCode 'SA'
************************************************************************/  
CREATE     PROCEDURE [dbo].[GetVendorDetailsByCompanyCode]
 @companyCode VARCHAR(30),
 @vendorId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		DECLARE @MasterCompanyId BIGINT = (SELECT TOP 1  MasterCompanyId FROM Dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyCode = @companyCode)
		
		SELECT 
            v.VendorId,
			vt.Description as [Vendor Type],
            v.VendorName as [Vendor Name],
            v.VendorCode as [Vendor Code],
            v.VendorEmail as [Vendor Email],
			v.VendorPhone as [Vendor Phone],
            v.LicenseNumber as [License Number],
		  	adMain.Line1 +
				(CASE WHEN ISNULL(adMain.Line2,'') = '' THEN '' ELSE ',' + adMain.Line2 END) +
				(CASE WHEN ISNULL(adMain.Line3,'') = '' THEN '' ELSE ',' + adMain.Line3 END)
				AS [Vendor Address],
            adMain.City as [City],
            adMain.StateOrProvince as [State Or Province],
            adMain.PostalCode as [PostalCode],
            cont.countries_name   as [Vendor Country],


			c.FirstName + ' ' + c.LastName AS [Contact Person Name],
			c.Email AS [Contact Person Email],
			CASE WHEN ISNULL(c.WorkPhoneExtn, '') = '' THEN c.WorkPhone ELSE c.WorkPhone + ' - ' + c.WorkPhoneExtn END AS [Contact Person PhoneNo],


			billAddr.Line1 +
				(CASE WHEN ISNULL(billAddr.Line2,'') = '' THEN '' ELSE ',' + billAddr.Line2 END) +
				(CASE WHEN ISNULL(billAddr.Line3,'') = '' THEN '' ELSE ',' + billAddr.Line3 END)
				AS [Billing Address],
            billAddr.City as [Billing City],
            billAddr.StateOrProvince as [Billing State Or Province],
            billAddr.PostalCode as [Billing  Postal Code],
            countryBill.countries_name   as [Billing Country],
			bill.SiteName as [Billing Site Name],

			shipAddr.City AS [Shipping City],
			shipAddr.StateOrProvince AS [Shipping State or Province],
			shipAddr.PostalCode AS [Shipping Postal Code],
			countryShip.countries_name AS [Shipping Country],
			ship.SiteName AS [Shipping Site Name]

        FROM DBO.Vendor v WITH (NOLOCK)
        LEFT JOIN DBO.Address adMain WITH (NOLOCK) ON v.AddressId = adMain.AddressId
        LEFT JOIN DBO.Countries cont WITH (NOLOCK) ON adMain.CountryId = cont.countries_id
        LEFT JOIN DBO.VendorType vt WITH (NOLOCK) ON v.VendorTypeId = vt.VendorTypeId
		LEFT  JOIN dbo.VendorContact vc WITH (NOLOCK) ON v.VendorId = vc.VendorId --c.ContactId = vc.ContactId
		LEFT  JOIN dbo.Contact c WITH (NOLOCK) ON vc.ContactId = c.ContactId 

		LEFT JOIN dbo.VendorBillingAddress bill WITH (NOLOCK) ON v.VendorId = bill.VendorId
		LEFT JOIN dbo.Address billAddr WITH (NOLOCK) ON bill.AddressId = billAddr.AddressId
		LEFT JOIN dbo.Countries countryBill WITH (NOLOCK) ON billAddr.CountryId = countryBill.countries_id

		LEFT JOIN [VendorShippingAddress] AS ship  WITH (NOLOCK) ON v.VendorId = ship.VendorId
		LEFT JOIN [Address] AS shipAddr  WITH (NOLOCK) ON ship.[AddressId] = shipAddr.[AddressId]
		LEFT JOIN [Countries] AS countryShip WITH (NOLOCK) ON shipAddr.[CountryId] = countryShip.[countries_id]

		WHERE v.MasterCompanyId = @MasterCompanyId AND ISNULL(v.IsActive,0) = 1	AND ISNULL(v.IsDeleted,0) = 0
			AND (@vendorId IS NULL OR v.VendorId = @vendorId)

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetVendorDetailsByCompanyCode'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@companyCode, '') 
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END