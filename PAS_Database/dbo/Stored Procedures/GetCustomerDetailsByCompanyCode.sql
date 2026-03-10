/*************************************************************             
 ** File:   [GetCustomerDetailsByCompanyCode]            
 ** Author:  RAJESH GAMI
 ** Description: This stored procedure is used to get customer details by company code (General Info, Contact Details, Billing and Shipping Details)
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

 EXEC GetCustomerDetailsByCompanyCode 'SA'
************************************************************************/  
CREATE     PROCEDURE [dbo].[GetCustomerDetailsByCompanyCode]
 @companyCode VARCHAR(30),
 @customerId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		DECLARE @MasterCompanyId BIGINT = (SELECT TOP 1  MasterCompanyId FROM Dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyCode = @companyCode)
		SELECT 
			cust.CustomerId,
			aff.Description AS [Account Type],
			custType.CustomerTypeName AS [Customer Type],
			cust.Name AS [Customer Name],
			cust.CustomerCode AS [Customer Code],
			cust.CustomerPhone AS [Customer Phone],
			cust.Email,

			addrMain.Line1 +
				(CASE WHEN ISNULL(addrMain.Line2,'') = '' THEN '' ELSE ',' + addrMain.Line2 END) +
				(CASE WHEN ISNULL(addrMain.Line3,'') = '' THEN '' ELSE ',' + addrMain.Line3 END)
				AS [Customer Address],

			addrMain.City,
			addrMain.StateOrProvince AS [State or Province],
			addrMain.PostalCode AS [Postal Code],
			countryMain.countries_name AS [Country],
			cust.Memo AS [Customer Memo],

			cont.FirstName + ' ' + cont.LastName AS [Contact Person Name],
			cont.Email AS [Contact Person Email],

			CASE 
				WHEN cont.WorkPhone IS NOT NULL 
					 AND cont.WorkPhoneExtn IS NOT NULL 
					 AND LTRIM(RTRIM(cont.WorkPhoneExtn)) <> ''
				THEN cont.WorkPhone + '-' + cont.WorkPhoneExtn 
				ELSE cont.WorkPhone 
			END AS [Contact Person PhoneNo],

			billAddr.Line1 +
				(CASE WHEN ISNULL(billAddr.Line2,'') = '' THEN '' ELSE ',' + billAddr.Line2 END) +
				(CASE WHEN ISNULL(billAddr.Line3,'') = '' THEN '' ELSE ',' + billAddr.Line3 END)
				AS [Billing Address],

			billAddr.City AS [Billing City],
			billAddr.StateOrProvince AS [Billing State or Province],
			billAddr.PostalCode AS [Billing Postal Code],
			countryBill.countries_name AS [Billing Country],
			bill.Email AS [Billing Email],
			bill.SiteName [Billing Site Name],

			shipAddr.Line1 +
				(CASE WHEN ISNULL(shipAddr.Line2,'') = '' THEN '' ELSE ',' + shipAddr.Line2 END) +
				(CASE WHEN ISNULL(shipAddr.Line3,'') = '' THEN '' ELSE ',' + shipAddr.Line3 END)
				AS [Shipping Address],

			shipAddr.City AS [Shipping City],
			shipAddr.StateOrProvince AS [Shipping State or Province],
			shipAddr.PostalCode AS [Shipping Postal Code],
			countryShip.countries_name AS [Shipping Country],
			ship.SiteName AS [Shipping Site Name]

		FROM dbo.Customer cust WITH (NOLOCK)

		LEFT JOIN dbo.Address addrMain WITH (NOLOCK) ON cust.AddressId = addrMain.AddressId
		LEFT JOIN dbo.CustomerType custType WITH (NOLOCK) ON cust.CustomerTypeId = custType.CustomerTypeId
		LEFT JOIN dbo.Countries countryMain WITH (NOLOCK) ON addrMain.CountryId = countryMain.countries_id
		LEFT JOIN dbo.CustomerAffiliation aff WITH (NOLOCK)	ON cust.CustomerAffiliationId = aff.CustomerAffiliationId
		LEFT JOIN dbo.CustomerContact custContact WITH (NOLOCK)	ON cust.CustomerId = custContact.CustomerId	AND custContact.IsDefaultContact = 1
		LEFT JOIN dbo.Contact cont WITH (NOLOCK) ON custContact.ContactId = cont.ContactId
		
		LEFT JOIN dbo.CustomerDomensticShipping ship WITH (NOLOCK) ON cust.CustomerId = ship.CustomerId	AND ship.IsPrimary = 1
		LEFT JOIN dbo.Address shipAddr WITH (NOLOCK) ON ship.AddressId = shipAddr.AddressId
		LEFT JOIN dbo.Countries countryShip WITH (NOLOCK) ON shipAddr.CountryId = countryShip.countries_id
		
		LEFT JOIN dbo.CustomerBillingAddress bill WITH (NOLOCK)	ON cust.CustomerId = bill.CustomerId
		LEFT JOIN dbo.Address billAddr WITH (NOLOCK) ON bill.AddressId = billAddr.AddressId
		LEFT JOIN dbo.Countries countryBill WITH (NOLOCK) ON billAddr.CountryId = countryBill.countries_id
		WHERE
			cust.MasterCompanyId = @MasterCompanyId
			AND ISNULL(cust.IsActive,0) = 1
			AND ISNULL(cust.IsDeleted,0) = 0
			AND (@customerId IS NULL OR cust.CustomerId = @customerId)

		ORDER BY cust.CustomerId;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetCustomerDetailsByCompanyCode'     
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