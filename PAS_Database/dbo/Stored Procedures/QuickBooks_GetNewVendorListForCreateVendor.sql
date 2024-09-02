/*************************************************************           
 ** File:   [QuickBooks_GetNewVendorListForCreateVendor]           
 ** Author:   Hemant Saliya
 ** Description: Get Vendor List to Create Vendor in QuickBooks    
 ** Purpose:         
 ** Date:   27-AUG-2024       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    27-AUG-2024   Hemant Saliya	Created
     
 EXECUTE [QuickBooks_GetNewVendorListForCreateVendor] 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewVendorListForCreateVendor]
	@IntegrationTypeId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			SELECT [VendorName] As CompanyName, V.VendorId, V.VendorCode, V.MasterCompanyId,
					CON.FirstName + ' ' + CON.LastName AS FullName,
					CON.FirstName,
					CON.LastName,
					CON.MiddleName,
					CON.Prefix,
					CON.Suffix,
					CON.Email,
					CON.WorkPhone AS VendorPhone,
					V.VendorEmail AS Email,
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
					UPPER(CT.countries_name) Country,
					V.UpdatedBy
			FROM dbo.Vendor V WITH(NOLOCK) 
				JOIN dbo.VendorContact CO WITH(NOLOCK) ON V.VendorId = CO.VendorId AND CO.IsDefaultContact = 1
				JOIN dbo.Contact CON WITH(NOLOCK) ON CO.ContactId = CON.ContactId
				JOIN dbo.[Address] AD WITH (NOLOCK) ON V.AddressId = AD.AddressId
				LEFT JOIN dbo.Countries CT WITH (NOLOCK) ON CT.countries_id = AD.CountryId
			WHERE ISNULL(V.QuickBooksReferenceId, 0) = 0 AND ISNULL(V.IsUpdated, 0) = 1 
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetNewVendorListForCreateVendor'
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