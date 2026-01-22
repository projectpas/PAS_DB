/*************************************************************               
 ** File:   [CheckLegalEntityrDuplicatePhoneContact]            
 ** Author:  Ayushi Patel   
 ** Description:  This Stored Procedure checks for duplicate legalEntity phone numbers.   
 ** Purpose:             
 ** Date:   06/01/2025         
              
 ** RETURN VALUE:               
 **********************************************************               
 ** Checks for duplicate phone numbers in the legalEntity table.             
 **********************************************************               
 ** PR   Date		Author		Change Description                
 ** --   --------		-------		--------------------------------              
    1    06/01/2025  	Ayushi Patel	Created      
 
 EXEC [CheckLegalEntityrDuplicatePhoneContact] '360-551-0556', 0
********************************************************************/ 

CREATE   PROCEDURE [dbo].[CheckLegalEntityrDuplicatePhoneContact]
	@LegalEntityPhone VARCHAR(100) = NULL,
	@LegalEntityId BIGINT = 0
AS
BEGIN
	BEGIN TRY
		DECLARE @ReturnStatus INT = 0,
				@ExistingLegalEntityPhone VARCHAR(100),
				@ReturnMsg VARCHAR(150),
				@ContactReturnMsg VARCHAR(150) = 'The phone number you are trying to use already exists.<br/>Are you sure you want to use it again?';

		-- Checking for current customer phone.
		IF (@LegalEntityId > 0)
		BEGIN 
			SELECT @ExistingLegalEntityPhone = PhoneNumber
			FROM [dbo].[LegalEntity] WITH(NOLOCK)
			WHERE [LegalEntityId] = @LegalEntityId AND [IsActive] = 1 AND [IsDeleted] = 0;

			IF (@ExistingLegalEntityPhone = @LegalEntityPhone)
			BEGIN 
				SET @ReturnStatus = 1;
				SET @ReturnMsg = '';
			END
			ELSE
			BEGIN
				IF EXISTS (
					SELECT 1 
					FROM [dbo].[LegalEntity] WITH(NOLOCK)
					WHERE [PhoneNumber] = @LegalEntityPhone AND [LegalEntityId] != @LegalEntityId AND [IsActive] = 1 AND [IsDeleted] = 0
				)
				BEGIN
					SET @ReturnStatus = -2;
					SET @ReturnMsg = @ContactReturnMsg;
				END
				ELSE
				BEGIN
					SET @ReturnStatus = 1;
					SET @ReturnMsg = '';
				END
			END
		END
		ELSE
		BEGIN
			IF EXISTS (
				SELECT 1 
				FROM [dbo].[LegalEntity] WITH(NOLOCK)
				WHERE [PhoneNumber] = @LegalEntityPhone AND [IsActive] = 1 AND [IsDeleted] = 0
			)
			BEGIN
				SET @ReturnStatus = -2;
				SET @ReturnMsg = @ContactReturnMsg;
			END
			ELSE
			BEGIN
				SET @ReturnStatus = 1;
				SET @ReturnMsg = '';
			END
		END

		SELECT @ReturnStatus AS Status, @ReturnMsg AS Msg;

	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckLegalEntityrDuplicatePhoneContact' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityPhone, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

		exec spLogException 
				 @DatabaseName = @DatabaseName
				,@AdhocComments = @AdhocComments
				,@ProcedureParameters = @ProcedureParameters
				,@ApplicationName = @ApplicationName
				,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN(1);
	END CATCH
END