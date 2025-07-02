/*************************************************************           
 ** File:		 [USP_LegalEntityInternationalShippingStatus]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update Legal Entity International Shipping Status.
 ** Purpose:         
 ** Date:   01-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    01-July-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityInternationalShippingStatus] @ShippingAddressId=8, @Status=N'Active', @UpdatedBy=N'DANE PERK'
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_LegalEntityInternationalShippingStatus]
@ShippingAddressId BIGINT = 0,
@Status VARCHAR(20),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsActive BIT;	

    IF (LOWER(@Status) = LOWER('Active'))
	BEGIN
        SET @IsActive = 1;
	END
    ELSE
	BEGIN
        SET @IsActive = 0;
	END

	IF(ISNULL(@ShippingAddressId, 0) > 0)		
	BEGIN

		UPDATE [DBO].[LegalEntityInternationalShipping] 
		SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [LegalEntityInternationalShippingId] = @ShippingAddressId;		
		
	END

	SELECT @ShippingAddressId AS ShippingAddressId;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityInternationalShippingStatus'
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