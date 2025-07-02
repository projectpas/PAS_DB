/*************************************************************           
 ** File:		 [USP_DeleteLegalEntityInternationalShipping]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Delete Legal Entity International Shipping.
 ** Purpose:         
 ** Date:   01-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    01-July-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_DeleteLegalEntityInternationalShipping] @ShippingAddressId=41, @UpdatedBy=N'DANE PERK', @IsDeleted=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_DeleteLegalEntityInternationalShipping]
@ShippingAddressId BIGINT,
@UpdatedBy VARCHAR(256),
@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalShipping] WITH(NOLOCK) WHERE [LegalEntityInternationalShippingId] = @ShippingAddressId)
		BEGIN
			UPDATE [DBO].[LegalEntityInternationalShipping] 
			SET	[IsDeleted] = ISNULL(@IsDeleted, 0), [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [LegalEntityInternationalShippingId] = @ShippingAddressId;
		END	

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteLegalEntityInternationalShipping'
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