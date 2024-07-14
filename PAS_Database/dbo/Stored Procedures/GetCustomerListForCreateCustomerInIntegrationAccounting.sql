/*************************************************************           
 ** File:   [GetCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Get Customer List to Create Customer in QuickBooks    
 ** Purpose:         
 ** Date:   04-July-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-July-2024   Hemant Saliya	Created
     
 EXECUTE [GetCustomerList] 1, 10, null, -1, 1, '', 'uday', 'CUS-00','','HYD'
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetCustomerListForCreateCustomerInIntegrationAccounting]
	@IntegrationTypeId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			SELECT [Name] As CompanyName, C.CustomerId, C.CustomerCode,
					CON.FirstName + ' ' + CON.LastName AS FullName,
					CON.FirstName,
					CON.LastName,
					CON.MiddleName,
					CON.Prefix,
					CON.Suffix,
					CON.Email,
					CON.WorkPhone AS CustomerPhone,
					C.Email,
					CON.ContactTitle,
					CON.Fax, 
					CON.Notes,
					CON.Tag,
					UPPER(AD.AddressId) AS AddressId,
					UPPER(AD.Line1) + ' ' + UPPER(AD.Line2) + ' ' + UPPER(AD.Line3) AS AddressLine1,
					UPPER(AD.City) AS City,
					UPPER(AD.StateOrProvince) StateOrProvince,
					AD.PostalCode,
					AD.CountryId,
					UPPER(CT.countries_name) Country				
			FROM dbo.Customer C WITH(NOLOCK) 
				JOIN dbo.CustomerContact CO WITH(NOLOCK) ON C.CustomerId = CO.CustomerId AND CO.IsDefaultContact = 1
				JOIN dbo.Contact CON WITH(NOLOCK) ON CO.ContactId = CON.ContactId
				JOIN dbo.[Address] AD WITH (NOLOCK) ON C.AddressId = AD.AddressId
				LEFT JOIN dbo.Countries CT WITH (NOLOCK) ON CT.countries_id = AD.CountryId
			WHERE ISNULL(C.QuickBooksCustomerId, 0) = 0 AND ISNULL(C.IsUpdated, 0) = 1 
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetCustomerList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END