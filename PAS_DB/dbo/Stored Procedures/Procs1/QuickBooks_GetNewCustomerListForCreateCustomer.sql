/*************************************************************           
 ** File:   [QuickBooks_GetNewCustomerListForCreateCustomer]           
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
	2    18-NOV-2024    Devendra Shekh	Modified(Added fields to select)
	3    10-Jan-2025    Devendra Shekh	Modified(Added MasterCompanyId To Param)
	4    21-Feb-2025    Devendra Shekh	Modified(Added new fields Fax, TermQuickBooksReferenceId)
	5    12-March-2025  Devendra Shekh	Modified(Changes for Billing/Shipping Address Details)
     
 EXECUTE [QuickBooks_GetNewCustomerListForCreateCustomer] 1,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewCustomerListForCreateCustomer]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		IF OBJECT_ID('tempdb..#CustomerResults') IS NOT NULL
			DROP TABLE #CustomerResults

		CREATE TABLE #CustomerResults (
			[CompanyName] VARCHAR(100) NULL,
			[CustomerId] BIGINT NULL,
			[CustomerCode] VARCHAR(100) NULL,
			[MasterCompanyId] INT NULL,
			[FullName] VARCHAR(200) NULL,
			[FirstName] VARCHAR(100) NULL,
			[LastName] VARCHAR(50) NULL,
			[MiddleName] VARCHAR(50) NULL,
			[Prefix] VARCHAR(20) NULL,
			[Suffix] VARCHAR(20) NULL,
			[Email] VARCHAR(200) NULL,
			[CustomerPhone] VARCHAR(20) NULL,
			[WorkEmail] VARCHAR(200) NULL,
			[ContactTitle] VARCHAR(30) NULL,
			[Fax] VARCHAR(20) NULL,
			[Notes] NVARCHAR(MAX) NULL,
			[Tag] VARCHAR(255) NULL,
			[AddressId] BIGINT NULL,
			[BillCountry] VARCHAR(100) NULL,
			[BillState] VARCHAR(50) NULL,
			[BillCity] VARCHAR(50) NULL,
			[BillPostalCode] VARCHAR(20) NULL,
			[BillAddressLine1] VARCHAR(250) NULL,
			[BillAddressLine2] VARCHAR(250) NULL,
			[BillAddressLine3] VARCHAR(250) NULL,
			[CountryId] INT NULL,
			[UpdatedBy] VARCHAR(256) NULL,
			[CustomerURL] NVARCHAR(MAX) NULL,
			[TermQuickBooksReferenceId] VARCHAR(200) NULL,
			[ShipCountry] VARCHAR(100) NULL,
			[ShipState] VARCHAR(50) NULL,
			[ShipCity] VARCHAR(50) NULL,
			[ShipPostalCode] VARCHAR(20) NULL,
			[ShipAddressLine1] VARCHAR(250) NULL,
			[ShipAddressLine2] VARCHAR(250) NULL,
			[ShipAddressLine3] VARCHAR(250) NULL,
		);

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			
			INSERT INTO #CustomerResults ([CompanyName], [CustomerId], [CustomerCode], [FullName], [FirstName], [LastName], [MiddleName], [Prefix], [Suffix], [Email], [CustomerPhone], 
						[ContactTitle], [Fax], [Notes], [Tag], [UpdatedBy], [MasterCompanyId], [CustomerURL], [TermQuickBooksReferenceId])
			SELECT C.[Name] As CompanyName, C.CustomerId, C.CustomerCode,
					CON.FirstName + ' ' + CON.LastName AS FullName,
					CON.FirstName,
					CON.LastName,
					CON.MiddleName,
					CON.Prefix,
					CON.Suffix,
					CON.Email,
					CON.WorkPhone AS CustomerPhone,
					CON.ContactTitle,
					CON.Fax, 
					CON.Notes,
					CON.Tag,
					--UPPER(AD.AddressId) AS AddressId,
					--UPPER(CT.countries_name) BillCountry,
					--UPPER(AD.StateOrProvince) BillState,
					--UPPER(AD.City) AS BillCity,
					--AD.PostalCode as BillPostalCode,
					--UPPER(AD.Line1) AS BillAddressLine1,
					--UPPER(AD.Line2) AS BillAddressLine2,
					--UPPER(AD.Line3) AS BillAddressLine3,
					--AD.CountryId,
					C.UpdatedBy,
					C.MasterCompanyId,
					ISNULL(C.CustomerURL, '') AS CustomerURL,
					CDT.QuickBooksReferenceId as TermQuickBooksReferenceId
			FROM dbo.Customer C WITH(NOLOCK) 
				JOIN dbo.CustomerContact CO WITH(NOLOCK) ON C.CustomerId = CO.CustomerId AND CO.IsDefaultContact = 1
				JOIN dbo.Contact CON WITH(NOLOCK) ON CO.ContactId = CON.ContactId
				--JOIN dbo.[Address] AD WITH (NOLOCK) ON C.AddressId = AD.AddressId
				--LEFT JOIN dbo.Countries CT WITH (NOLOCK) ON CT.countries_id = AD.CountryId
				LEFT JOIN dbo.[CustomerFinancial] CF WITH (NOLOCK) ON CF.CustomerId = C.CustomerId
				LEFT JOIN dbo.[CreditTerms] CDT WITH (NOLOCK) ON CDT.CreditTermsId = CF.CreditTermsId
			WHERE ISNULL(C.QuickBooksReferenceId, 0) = 0 AND ISNULL(C.IsUpdated, 0) = 1 AND C.MasterCompanyId = @MasterCompanyId 

			--Updating Customer Primary Billing Address Details
			UPDATE CUST
			SET	--CUST.AddressId = AD.AddressId,
				--CUST.CountryId = AD.CountryId,
				CUST.BillCountry = UPPER(CT.countries_name),
				CUST.BillState = UPPER(AD.StateOrProvince),
				CUST.BillCity = UPPER(AD.City),
				CUST.BillPostalCode = (AD.PostalCode),
				CUST.BillAddressLine1 = UPPER(AD.Line1),
				CUST.BillAddressLine2 = UPPER(AD.Line2),
				CUST.BillAddressLine3 = UPPER(AD.Line3)
			FROM #CustomerResults CUST
			LEFT JOIN [dbo].[CustomerBillingAddress] CBA WITH(NOLOCK) ON CUST.CustomerId = CBA.CustomerId AND CBA.IsPrimary = 1
			LEFT JOIN [dbo].[Address] AD WITH(NOLOCK) ON CBA.AddressId = AD.AddressId
			LEFT JOIN [dbo].[Countries] CT WITH(NOLOCK) ON AD.CountryId = CT.countries_id

			--Updating Customer Primary Shipping Address Details
			UPDATE CUST
			SET	--CUST.AddressId = AD.AddressId,
				--CUST.CountryId = AD.CountryId,
				CUST.ShipCountry = UPPER(CT.countries_name),
				CUST.ShipState = UPPER(AD.StateOrProvince),
				CUST.ShipCity = UPPER(AD.City),
				CUST.ShipPostalCode = (AD.PostalCode),
				CUST.ShipAddressLine1 = UPPER(AD.Line1),
				CUST.ShipAddressLine2 = UPPER(AD.Line2),
				CUST.ShipAddressLine3 = UPPER(AD.Line3)
			FROM #CustomerResults CUST
			LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CUST.CustomerId = CDS.CustomerId AND CDS.IsPrimary = 1
			LEFT JOIN [dbo].[Address] AD WITH(NOLOCK) ON CDS.AddressId = AD.AddressId
			LEFT JOIN [dbo].[Countries] CT WITH(NOLOCK) ON AD.CountryId = CT.countries_id

			SELECT * FROM #CustomerResults
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