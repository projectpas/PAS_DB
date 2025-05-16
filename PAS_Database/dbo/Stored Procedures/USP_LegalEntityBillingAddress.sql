/*************************************************************           
 ** File:		 [USP_LegalEntityBillingAddress]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create LegalEntity Billing Address.
 ** Purpose:         
 ** Date:   12-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    12-May-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityBillingAddress] 45, 0, 'COMPANY NAME', 'ADDRESS LINE 1', 'ADDRESS LINE 2', 'PRIMARY STATE/PROVINCE','CITY','ZIP CODE', 2, 1, 0, 1, 'DANE PARK', 'DANE PARK', 1;
**************************************************************/
Create   PROCEDURE [DBO].[USP_LegalEntityBillingAddress]
@LegalEntityId BIGINT,
@LegalEntityBillingAddressId BIGINT = 0,
@CompanyName VARCHAR(256),
@Address1 VARCHAR(50),
@Address2 VARCHAR(50) = Null,
@StateOrProvince VARCHAR(50),
@City VARCHAR(50),
@PostalCode VARCHAR(20),
@CountryId INT,
@IsPrimary BIT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Declare variables
		DECLARE @AddressId BIGINT;
		DECLARE @BillingAddressId BIGINT;
		DECLARE @AddressType INT = 1;
		DECLARE @LegalEntityModuleId INT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity');

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

			SET @BillingAddressId = SCOPE_IDENTITY();	

			UPDATE [DBO].[LegalEntity] 
			SET	[BillingAddressId] = @AddressId
			WHERE LegalEntityId = @LegalEntityId AND [MasterCompanyId] = @MasterCompanyId

			EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@BillingAddressId,@AddressType,@UpdatedBy;

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