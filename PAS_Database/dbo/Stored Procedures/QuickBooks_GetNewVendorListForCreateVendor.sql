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
    1    27-AUG-2024	Hemant Saliya	Created
    2    18-NOV-2024	Devendra Shekh	Modified(Added fields to select)
	3    10-Jan-2025	Devendra Shekh	Modified(Added MasterCompanyId To Param)
	4    21-Feb-2025    Devendra Shekh	Modified(Added new field TermQuickBooksReferenceId)
	5    27-May-2026    Bhargav Saliya	Get Vendor Data For Xero Integration 
	6    12-Jun-2026	Bhargav Saliya  Modified(Get VendorName Instead of ContactName )
     
 EXECUTE [QuickBooks_GetNewVendorListForCreateVendor] 2,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewVendorListForCreateVendor]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @QBIntegrationTypeId INT,@NSIntegrationTypeId INT,@XeroIntegrationTypeId INT,@ModuleId INT;;
		
		SELECT @QBIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'QuickBooks';
		SELECT @NSIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'NetSuite';
		SELECT @XeroIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'Xero';

		SELECT @ModuleId = AccountingModuleId FROM [dbo].AccountingModule WITH(NOLOCK) WHERE AccountingModuleName = 'Vendor';

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId) 
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
					UPPER(AD.Line1) AS AddressLine1,
					UPPER(AD.Line2) AS AddressLine2,
					UPPER(AD.City) AS City,
					UPPER(AD.StateOrProvince) StateOrProvince,
					AD.PostalCode,
					AD.CountryId,
					UPPER(CT.countries_name) Country,
					V.UpdatedBy,
					ISNULL(V.VendorURL, '') AS VendorURL,
					CDT.QuickBooksReferenceId as TermQuickBooksReferenceId
			FROM dbo.Vendor V WITH(NOLOCK) 
				JOIN dbo.VendorContact CO WITH(NOLOCK) ON V.VendorId = CO.VendorId AND CO.IsDefaultContact = 1
				JOIN dbo.Contact CON WITH(NOLOCK) ON CO.ContactId = CON.ContactId
				JOIN dbo.[Address] AD WITH (NOLOCK) ON V.AddressId = AD.AddressId
				LEFT JOIN dbo.[Countries] CT WITH (NOLOCK) ON CT.countries_id = AD.CountryId
				LEFT JOIN dbo.[CreditTerms] CDT WITH (NOLOCK) ON CDT.CreditTermsId = V.CreditTermsId
			WHERE ISNULL(V.QuickBooksReferenceId, '') = '' AND ISNULL(V.IsUpdated, 0) = 1 AND V.MasterCompanyId = @MasterCompanyId
		END
		IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId) 
		BEGIN
			SELECT [VendorName] As CompanyName, V.VendorId, V.VendorCode, V.MasterCompanyId,
						V.VendorName AS FullName,
						V.VendorName AS FirstName,
						'' AS LastName,
						'' AS MiddleName,
						CON.Prefix,
						CON.Suffix,
						CON.Email,
						V.VendorPhone AS VendorPhone,
						V.VendorEmail AS Email,
						CON.ContactTitle,
						CON.Fax, 
						CON.Notes,
						CON.Tag,
						UPPER(AD.AddressId) AS AddressId,
						UPPER(AD.Line1) AS AddressLine1,
						UPPER(AD.Line2) AS AddressLine2,
						UPPER(AD.City) AS City,
						UPPER(AD.StateOrProvince) StateOrProvince,
						AD.PostalCode,
						AD.CountryId,
						UPPER(CT.countries_name) Country,
						V.UpdatedBy,
						ISNULL(V.VendorURL, '') AS VendorURL,
						V.QuickBooksReferenceId as TermQuickBooksReferenceId
				FROM dbo.Vendor V WITH(NOLOCK) 
					JOIN dbo.VendorContact CO WITH(NOLOCK) ON V.VendorId = CO.VendorId AND CO.IsDefaultContact = 1
					JOIN dbo.Contact CON WITH(NOLOCK) ON CO.ContactId = CON.ContactId
					JOIN dbo.[Address] AD WITH (NOLOCK) ON V.AddressId = AD.AddressId
					LEFT JOIN dbo.[Countries] CT WITH (NOLOCK) ON CT.countries_id = AD.CountryId
				WHERE ISNULL(V.QuickBooksReferenceId, '') = '' AND ISNULL(V.IsUpdated, 0) = 1 AND V.MasterCompanyId = @MasterCompanyId
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