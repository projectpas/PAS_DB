/*************************************************************               
 ** File:   [CheckLegalEntityDuplicateContacts]               
 ** Author:  Ayushi Patel    
 ** Description:  This Store Procedure use to check legal entity contact emial & phone duplicate.   
 ** Purpose:             
 ** Date:   08/08/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check legal entity emial & phone duplicate.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    08/08/2024  	AYUSHI PATEL	Created      
 
 EXEC [CheckLegalEntityDuplicateContacts] '9924523720','iupatel0803@gmail.com',61
********************************************************************/ 

CREATE   PROCEDURE [dbo].[CheckLegalEntityDuplicateContacts]
	@LegalEntityPhone VARCHAR(100) = NULL,
	@email VARCHAR(100) = NULL,
	@LegalEntityId BIGINT,
	@contactId BIGINT = 0
AS
BEGIN
		BEGIN TRY
			DECLARE @ReturnStatus INT = 0,
					@IsExistingLegalEntity INT = 0,
					@ExistingLegalEntityPhone VARCHAR(100),
					@ExistingEmail VARCHAR(100),
					@ExistinrContactId BIGINT,
					@ReturnMsg VARCHAR(150),
					@ContactIds VARCHAR(250),
					@MasterLoopID INT,
					@BreakLoop INT = 0,
					@ContactReturnMsg VARCHAR(150) = 'The work phone you are trying to use already exists.<br/>Are you sure you want to use it again?',
					@EmailReturnMsg VARCHAR(150) = 'The email address you are trying to use already exists. <br/>Are you sure you want to use it again?',
					@BothReturnMsg VARCHAR(150) = 'The work phone/email address you are trying to use already exists. <br/>Are you sure you want to use it again?';
			
			IF(@contactId > 0)
			BEGIN 
				 SET @ContactIds = (SELECT  STRING_AGG(ContactId, ',')
						FROM [dbo].[LegalEntityContact] WITH(NOLOCK)
						WHERE LegalEntityId = @LegalEntityId AND [IsActive] = 1 AND [IsDeleted] = 0 AND [ContactId] != @contactId)
			END
			
			--Checking for current customer email & phone.
			IF(@contactId > 0)
			BEGIN 
				IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email AND [ContactId] IN(SELECT Item FROM [dbo].[SplitString](@ContactIds,',')))
				BEGIN
					IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @LegalEntityPhone AND [ContactId] IN(SELECT Item FROM [dbo].[SplitString](@ContactIds,',')))
				    BEGIN
						 SET @ReturnStatus = -3;
						 SET @ReturnMsg = @BothReturnMsg;
						 SET @BreakLoop = 1;
					END
					ELSE
					BEGIN
						 SET @ReturnStatus = -1;
						 SET @ReturnMsg = @EmailReturnMsg;
						 SET @BreakLoop = 1;
					END
				END
				ELSE IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @LegalEntityPhone AND [ContactId] IN(SELECT Item FROM [dbo].[SplitString](@ContactIds,',')))
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email AND [ContactId] IN(SELECT Item FROM [dbo].[SplitString](@ContactIds,',')))
					 BEGIN
						  SET @ReturnStatus = -3;
						  SET @ReturnMsg = @BothReturnMsg;
						  SET @BreakLoop = 1;
					 END
					 ELSE
					 BEGIN
						  SET @ReturnStatus = -2;
						  SET @ReturnMsg = @ContactReturnMsg;
						  SET @BreakLoop = 1;
					 END
				END
				ELSE
				BEGIN
					 SET @ReturnStatus = 1;
					 SET @ReturnMsg = '';
				END	
			END
			ELSE
			BEGIN 
				IF(ISNULL(@ContactIds,0) = 0)
				BEGIN 
					IF EXISTS(SELECT 1 FROM [dbo].[Contact] C WITH(NOLOCK) 
								JOIN [dbo].[LegalEntityContact] CC WITH(NOLOCK) ON CC.ContactId = C.ContactId
							 WHERE C.[Email] = @email AND CC.[LegalEntityId] = @LegalEntityId AND CC.[IsActive] = 1 AND CC.[IsDeleted] = 0)
					BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Contact] C WITH(NOLOCK) 
									JOIN [dbo].[LegalEntityContact] CC WITH(NOLOCK) ON CC.ContactId = C.ContactId
								  WHERE [WorkPhone] = @LegalEntityPhone AND CC.[LegalEntityId] = @LegalEntityId AND CC.[IsActive] = 1 AND CC.[IsDeleted] = 0)
						 BEGIN
							  SET @ReturnStatus = -3;
							  SET @ReturnMsg = @BothReturnMsg;
						 END
						 ELSE
						 BEGIN
							  SET @ReturnStatus = -1;
							  SET @ReturnMsg = @EmailReturnMsg;
						 END
					END
					ELSE IF EXISTS(SELECT 1 FROM [dbo].[Contact] C WITH(NOLOCK) 
										JOIN [dbo].[LegalEntityContact] CC WITH(NOLOCK) ON CC.ContactId = C.ContactId
								  WHERE C.[WorkPhone] = @LegalEntityPhone AND CC.[LegalEntityId] = @LegalEntityId AND CC.[IsActive] = 1 AND CC.[IsDeleted] = 0)
					BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Contact] C WITH(NOLOCK) 
										JOIN [dbo].[LegalEntityContact] CC WITH(NOLOCK) ON CC.ContactId = C.ContactId
									WHERE C.[Email] = @email AND CC.[LegalEntityId] = @LegalEntityId AND CC.[IsActive] = 1 AND CC.[IsDeleted] = 0)
						 BEGIN
							  SET @ReturnStatus = -3;
							  SET @ReturnMsg = @BothReturnMsg;
						 END
						 ELSE
						 BEGIN 
							  SET @ReturnStatus = -2;
							  SET @ReturnMsg = @ContactReturnMsg;
						 END
					END
					ELSE
					BEGIN
						 SET @ReturnStatus = 1;
						 SET @ReturnMsg = '';
					END
				END
				ELSE
				BEGIN
					IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email AND [ContactId] NOT IN(SELECT Item FROM [dbo].[SplitString](ISNULL(@ContactIds,0),',')))
					BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @LegalEntityPhone AND [ContactId] NOT IN(SELECT Item FROM [dbo].[SplitString](ISNULL(@ContactIds,0),',')))
						 BEGIN
							  SET @ReturnStatus = -3;
							  SET @ReturnMsg = @BothReturnMsg;
						 END
						 ELSE
						 BEGIN
							  SET @ReturnStatus = -1;
							  SET @ReturnMsg = @EmailReturnMsg;
						 END
					END
					ELSE IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @LegalEntityPhone AND [ContactId] NOT IN(SELECT Item FROM [dbo].[SplitString](ISNULL(@ContactIds,0),',')))
					BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email AND [ContactId] NOT IN(SELECT Item FROM [dbo].[SplitString](ISNULL(@ContactIds,0),',')))
						 BEGIN
							  SET @ReturnStatus = -3;
							  SET @ReturnMsg = @BothReturnMsg;
						 END
						 ELSE
						 BEGIN
							  SET @ReturnStatus = -2;
							  SET @ReturnMsg = @ContactReturnMsg;
						 END
					END
					ELSE
					BEGIN
						 SET @ReturnStatus = 1;
						 SET @ReturnMsg = '';
					END
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
              , @AdhocComments     VARCHAR(150)    = 'CheckLegalEntityDuplicateContacts' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityPhone, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END