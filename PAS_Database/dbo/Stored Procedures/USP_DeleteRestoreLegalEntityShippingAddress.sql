/*************************************************************           
 ** File:		 [USP_DeleteRestoreLegalEntityShippingAddress]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Delete Or Restore Legal Entity Shipping Address.
 ** Purpose:         
 ** Date:   18-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    18-June-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_DeleteRestoreLegalEntityShippingAddress] @ShippingAddressId=41, @UpdatedBy=N'DANE PERK', @IsDeleted=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_DeleteRestoreLegalEntityShippingAddress]
@ShippingAddressId BIGINT,
@UpdatedBy VARCHAR(256),
@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	
		DECLARE @LegalEntityModuleId INT;
		DECLARE @LegalEntityId BIGINT;		
		DECLARE @AddressType INT = 2;
		
		SELECT @LegalEntityId = [LegalEntityId] FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityShippingAddressId] = @ShippingAddressId;
		SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';		

		IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityShippingAddressId] = @ShippingAddressId)
		BEGIN
			UPDATE [DBO].[LegalEntityShippingAddress] 
			SET	[IsDeleted] = ISNULL(@IsDeleted, 0), [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [LegalEntityShippingAddressId] = @ShippingAddressId				

			EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@ShippingAddressId,@AddressType,@UpdatedBy;
		END	
		
		SELECT @ShippingAddressId AS ShippingAddressId;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteRestoreLegalEntityShippingAddress'
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