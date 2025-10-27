/***************************************************************  
 ** File:  [usp_CreateCustomerForRFQ]            
 ** Author:   Devendra Shekh
 ** Description: Create the Customer For the RFQ
 ** Date:  27-Oct-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    27-Oct-2025		Devendra Shekh			Created
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_CreateCustomerForRFQ]
    @tbl_RfqCustomerType dbo.RfqCustomerType READONLY,
    @MasterCompanyId INT = NULL,
    @EmployeeId BIGINT = NULL,
	@CreatedBy VARCHAR(100) = NULL,
	@CustomerId BIGINT OUTPUT
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		
		DECLARE @AddressId BIGINT;
		DECLARE @CustomerClassificationId BIGINT, @CustomerTypeId BIGINT, @ExternalAffiliationId INT = 2, @CustomerModuleId BIGINT, @USACountryId BIGINT;

		SELECT @CustomerTypeId = [CustomerTypeId] FROM [dbo].[CustomerType] WITH(NOLOCK) WHERE [CustomerTypeName] = 'CUSTOMER' AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @CustomerModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Customer';
		SELECT TOP 1 @CustomerClassificationId = [CustomerClassificationId] FROM [dbo].[CustomerClassification] WITH(NOLOCK) WHERE (TRIM([Description]) = 'NA' OR TRIM([Description]) = 'N/A') AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @USACountryId = [countries_id] FROM [dbo].[Countries] WITH(NOLOCK) WHERE [countries_iso_code] = 'US' AND [MasterCompanyId] = @MasterCompanyId;

		-- Save Address Details
		INSERT INTO [dbo].[Address] ([POBox], [Line1], [Line2], [Line3], [City], [StateOrProvince], [PostalCode], [CountryId], [Latitude], [Longitude], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
		SELECT NULL, ISNULL([Address], '-'), NULL, NULL, ISNULL([City], '-'), ISNULL([State], '-'), ISNULL([Zip], '-'), ISNULL(CU.countries_id, @USACountryId), NULL, NULL, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
		FROM @tbl_RfqCustomerType TMP
		LEFT JOIN [dbo].[Countries] CU WITH(NOLOCK) ON TRIM(TMP.Country) = TRIM(CU.countries_name) AND CU.MasterCompanyId = @MasterCompanyId

		SET @AddressId = SCOPE_IDENTITY();

		-- Save Customer Details
		INSERT INTO	[dbo].[Customer]([CustomerAffiliationId], [CustomerTypeId], [Name], [CustomerCode], [DoingBuinessAsName], [IsParent], [ParentId], [CustomerPhone], [CustomerPhoneExt], [Email], [AddressId], 
				[IsAddressForBilling], [IsAddressForShipping], [IsCustomerAlsoVendor], [ContractReference], [IsPBHCustomer], [PBHCustomerMemo], [CustomerURL], [RestrictPMA], [RestrictDER], [ManagementStructureId], [MasterCompanyId], 
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsCRMCustomer], [BillingAddressId], [ShippingAddressId], [IsTradeRestricted], [TradeRestrictedMemo], [IsTrackScoreCard], [CommunicationPreference],
				[Ismiscellaneous], [IsStageChange], [IsCommunicationPreference], [IsCustomerShipping], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate], [Memo], [SyncToken]
		)
		SELECT	@ExternalAffiliationId, @CustomerTypeId, [CompanyName], '', '', 0, NULL, [Phone], '', [Email], @AddressId, 
				1, 1, 0, '', 0, '', '', 1, 1, NULL, @MasterCompanyId, 
				@CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 0, NULL, NULL, 0, '', 0, 0,
				0, 0, 0, 0, NULL, 1, NULL, '', NULL
		FROM @tbl_RfqCustomerType;

		SET @CustomerId = SCOPE_IDENTITY();

		EXEC [dbo].[USP_UpdateCustomerDetails] @CustomerId,@CustomerModuleId,@CustomerClassificationId,NULL,@MasterCompanyId,@EmployeeId,1,1;

	END TRY
	BEGIN CATCH    
		DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'usp_CreateCustomerForRFQ'    
			,@ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))   
			,@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
		EXEC spLogException @DatabaseName = @DatabaseName,    
			@AdhocComments = @AdhocComments,    
			@ProcedureParameters = @ProcedureParameters,    
			@ApplicationName = @ApplicationName,    
			@ErrorLogID = @ErrorLogID OUTPUT;    
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH    
END