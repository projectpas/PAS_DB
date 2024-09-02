/*************************************************************           
 ** File:   [QuickBooks_GetVendorListForUpdateVendor]           
 ** Author:   Hemant Saliya
 ** Description: Get Vendor List to Update Vendor in QuickBooks    
 ** Purpose:         
 ** Date:   04-July-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-July-2024   Hemant Saliya	Created
     
 EXECUTE [QuickBooks_GetVendorListForUpdateVendor] 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetVendorListForUpdateVendor]
	@IntegrationTypeId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			SELECT [VendorName] As CompanyName, V.VendorId, V.VendorCode, V.QuickBooksReferenceId,
					CON.FirstName + ' ' + CON.LastName AS FullName,
					CON.FirstName,
					CON.LastName,
					CON.MiddleName,
					CON.Prefix,
					CON.Suffix,
					CON.Email,
					CON.WorkPhone AS CustomerPhone,
					V.VendorEmail As Email,
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
			FROM dbo.Vendor V WITH(NOLOCK) 
				JOIN dbo.VendorContact VO WITH(NOLOCK) ON V.VendorId = VO.VendorId AND VO.IsDefaultContact = 1
				JOIN dbo.Contact CON WITH(NOLOCK) ON VO.ContactId = CON.ContactId
				JOIN dbo.[Address] AD WITH (NOLOCK) ON V.AddressId = AD.AddressId
				LEFT JOIN dbo.Countries CT WITH (NOLOCK) ON CT.countries_id = AD.CountryId
			WHERE ISNULL(V.QuickBooksReferenceId, 0) != 0 AND ISNULL(V.IsUpdated, 0) = 1 
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetVendorListForUpdateVendor'
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