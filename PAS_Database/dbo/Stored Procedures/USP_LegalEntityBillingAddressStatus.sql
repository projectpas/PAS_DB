/*************************************************************           
 ** File:		 [USP_LegalEntityBillingAddressStatus]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update Legal Entity Billing Status.
 ** Purpose:         
 ** Date:   12-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    12-June-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityBillingAddressStatus] @BillingAddressId=35, @Status=N'Active', @UpdatedBy=N'DANE PERK'
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_LegalEntityBillingAddressStatus]
@BillingAddressId BIGINT = 0,
@Status VARCHAR(20),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsActive BIT;
	DECLARE @LegalEntityModuleId INT;
	DECLARE @LegalEntityId BIGINT;
	DECLARE @AddressType INT = 1;

	SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';
	SELECT @LegalEntityId = [LegalEntityId] FROM [DBO].[LegalEntityBillingAddress] WITH(NOLOCK) WHERE [LegalEntityBillingAddressId] = @BillingAddressId;

    IF (LOWER(@Status) = LOWER('Active'))
	BEGIN
        SET @IsActive = 1;
	END
    ELSE
	BEGIN
        SET @IsActive = 0;
	END

	IF(ISNULL(@BillingAddressId, 0) > 0)		
	BEGIN

		UPDATE [DBO].[LegalEntityBillingAddress] 
		SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [LegalEntityBillingAddressId] = @BillingAddressId;
		
		EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@BillingAddressId,@AddressType,@UpdatedBy;
	END

	SELECT @BillingAddressId AS BillingAddressId;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityBillingAddressStatus'
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