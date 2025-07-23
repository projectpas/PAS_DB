/*************************************************************           
 ** File:		 [USP_UpdateLegalEntitySettings]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update LegalEntity Settings.
 ** Purpose:         
 ** Date:   11-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    11-July-2025		Divyesh Kathiriya	Created    
 
**************************************************************/
Create   PROCEDURE [DBO].[USP_UpdateLegalEntitySettings]
@LegalEntityId BIGINT,
@CurrencyFormatId BIGINT = Null,
@DecimalPrecisionId BIGINT = Null,
@ShortDateTimeFormatId BIGINT = Null,
@LongDateTimeFormatId BIGINT = Null,
@TextTransformId BIGINT = Null,
@TimeZoneId BIGINT = Null,
@EnableLockScreen BIT = Null,
@TimeoutInMinutes INT = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		IF EXISTS (SELECT 1 FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId)
		BEGIN						
				UPDATE [DBO].[LegalEntity]
				SET	[CurrencyFormatId] = @CurrencyFormatId,
					[DecimalPrecisionId] = @DecimalPrecisionId,
					[ShortDateTimeFormatId] = @ShortDateTimeFormatId,
					[LongDateTimeFormatId] = @LongDateTimeFormatId,
					[TextTransformId] = @TextTransformId,
					[TimeZoneId] = @TimeZoneId,
					[EnableLockScreen] = @EnableLockScreen,
					[TimeoutInMinutes] = @TimeoutInMinutes
				WHERE [LegalEntityId] = @LegalEntityId;	
		END
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateLegalEntitySettings'
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