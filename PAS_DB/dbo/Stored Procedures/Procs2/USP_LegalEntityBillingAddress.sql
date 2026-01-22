/*************************************************************           
 ** File:		 [USP_LegalEntityBillingAddress]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity Billing Address.
 ** Purpose:         
 ** Date:   12-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    12-May-2025		Divyesh Kathiriya	Created
    2	 15-May-2025		Divyesh Kathiriya	Add Update LegalEntity Billing Address.

 -- EXEC [USP_LegalEntityBillingAddress] 45, 0, 'COMPANY NAME', 'ADDRESS LINE 1', 'ADDRESS LINE 2', 'PRIMARY STATE/PROVINCE','CITY','ZIP CODE', 2, 1, 0, 1, 'DANE PARK', 'DANE PARK', 1, NULL;
**************************************************************/
Create   PROCEDURE [DBO].[USP_LegalEntityBillingAddress]
@LegalEntityId BIGINT,
@LegalEntityBillingAddressId BIGINT = 0,
@CompanyName VARCHAR(256),
@Address1 VARCHAR(50),
@Address2 VARCHAR(50) = NULL,
@StateOrProvince VARCHAR(50),
@City VARCHAR(50),
@PostalCode VARCHAR(20),
@CountryId INT,
@IsPrimary BIT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@MasterCompanyId INT,
@BillingAddressId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Declare variables
		DECLARE @AddressId BIGINT;		
		DECLARE @AddressType INT = 1;
		DECLARE @CurrentPrimaryId BIGINT;
		DECLARE @LegalEntityModuleId INT;
		DECLARE @IsHistory INT = 0;

		SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';

		IF(ISNULL(@LegalEntityBillingAddressId, 0) = 0)
		BEGIN			
			
			INSERT INTO [DBO].[Address]( 
										[Line1],
										[Line2],
										[City],
										[StateOrProvince],
										[PostalCode],
										[CountryId],
										[MasterCompanyId], 
										[CreatedBy], 
										[UpdatedBy], 
										[CreatedDate], 
										[UpdatedDate], 
										[IsActive], 
										[IsDeleted])
								VALUES(
										@Address1,
										@Address2,
										@City,
										@StateOrProvince,						
										@PostalCode,
										@CountryId,
										@MasterCompanyId, 
										@CreatedBy, 
										@UpdatedBy, 
										GETUTCDATE(), 
										GETUTCDATE(), 
										1, 
										0)
 					
			SET @AddressId = SCOPE_IDENTITY();

			INSERT INTO [DBO].[LegalEntityBillingAddress]( 
										[LegalEntityId],
										[AddressId],
										[IsPrimary],
										[SiteName],																				
										[MasterCompanyId],										
										[CreatedBy], 
										[UpdatedBy], 
										[CreatedDate], 
										[UpdatedDate], 
										[IsActive], 
										[IsDeleted])
								VALUES(
										@LegalEntityId,
										@AddressId,
										@IsPrimary,
										@CompanyName,										
										@MasterCompanyId,										
										@CreatedBy, 
										@UpdatedBy, 
										GETUTCDATE(), 
										GETUTCDATE(), 
										1, 
										0) 

			SET @LegalEntityBillingAddressId = SCOPE_IDENTITY();	

			UPDATE [DBO].[LegalEntity] 
			SET	[BillingAddressId] = @AddressId
			WHERE [LegalEntityId] = @LegalEntityId AND [MasterCompanyId] = @MasterCompanyId

			EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@LegalEntityBillingAddressId,@AddressType,@UpdatedBy;

		END		
		ELSE
		BEGIN
			-- GET CURRENT PRIMARY BILLING ADDRESS
			SELECT @CurrentPrimaryId = [LegalEntityBillingAddressId] FROM [DBO].[LegalEntityBillingAddress] WITH(NOLOCK) WHERE LegalEntityId = @LegalEntityId AND IsPrimary = 1;
			
			-- IF CURRENT PRIMARY ADDRESS IS DIFFERENT FROM THE PROVIDED BILLINGADDRESSID
			IF (@CurrentPrimaryId IS NOT NULL AND EXISTS (SELECT 1 FROM [DBO].[LegalEntityBillingAddress] WITH(NOLOCK) WHERE [AddressId] = @BillingAddressId AND [LegalEntityId] = @LegalEntityId AND [LegalEntityBillingAddressId] != @CurrentPrimaryId))
			BEGIN
				-- UPDATE OLD PRIMARY
				UPDATE [DBO].[LegalEntityBillingAddress]
				SET [IsPrimary] = 0,
					[UpdatedDate] = GETUTCDATE(),
					[UpdatedBy] = @UpdatedBy
				WHERE [LegalEntityBillingAddressId] = @CurrentPrimaryId;
				
				EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@CurrentPrimaryId,@AddressType,@UpdatedBy;
			END
			
			IF NOT EXISTS (SELECT 1 FROM [DBO].[Address] WITH(NOLOCK) WHERE [AddressId] = @BillingAddressId AND [Line1] = @Address1 AND [Line2] = @Address2 AND [City] = @City AND [StateOrProvince] = @StateOrProvince AND [CountryId] = @CountryId AND [PostalCode] = @PostalCode)
			BEGIN
				UPDATE [DBO].[Address]
				SET [Line1] = @Address1,
					[Line2] = @Address2,
					[City] = @City,
					[StateOrProvince] = @StateOrProvince,				
					[PostalCode] = @PostalCode,
					[CountryId] = @CountryId,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()				
				WHERE [AddressId] = @BillingAddressId;
				
				SET @IsHistory = 1;
			END
			
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityBillingAddress] WITH(NOLOCK) WHERE [AddressId] = @BillingAddressId AND [SiteName] = @CompanyName AND [IsPrimary] = @IsPrimary)
			BEGIN
				UPDATE [DBO].[LegalEntityBillingAddress] 
				SET [SiteName] = @CompanyName,
					[IsPrimary] = @IsPrimary,									
					[UpdatedBy] = @UpdatedBy, 
					[UpdatedDate] = GETUTCDATE(),
					[IsActive] = 1, 
					[IsDeleted] = 0
				WHERE [LegalEntityBillingAddressId] = @LegalEntityBillingAddressId;
				
				SET @IsHistory = 1;
			END

			IF (@IsHistory = 1)
			BEGIN
				EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@LegalEntityBillingAddressId,@AddressType,@UpdatedBy;
			END
			
		END
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityBillingAddress'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END