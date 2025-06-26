/*************************************************************           
 ** File:		 [USP_DeleteLegalEntityShipVia]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Delete Legal Entity Ship Via.
 ** Purpose:         
 ** Date:   25-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    25-June-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_DeleteLegalEntityShipVia] @ShippingAddressId=84, @UpdatedBy=N'DANE PERK', @IsDeleted=1
**************************************************************/
CREATE   PROCEDURE [DBO].USP_DeleteLegalEntityShipVia
@ShippingAddressId BIGINT,
@UpdatedBy VARCHAR(256),
@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShipping] WITH(NOLOCK) WHERE [LegalEntityShippingId] = @ShippingAddressId)
		BEGIN
			UPDATE [DBO].[LegalEntityShipping] 
			SET	[IsDeleted] = ISNULL(@IsDeleted, 0), [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [LegalEntityShippingId] = @ShippingAddressId
		END	
		
		SELECT @ShippingAddressId AS ShippingAddressId;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteLegalEntityShipVia'
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