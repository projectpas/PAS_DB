/*************************************************************               
 ** File:   [CheckCustomerDuplicateContacts]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to check customer contact emial & phone duplicate.   
 ** Purpose:             
 ** Date:   08/08/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone duplicate.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    08/08/2024  	AMIT GHEDIYA	Created     
 
 EXEC [CheckCustomerDuplicateContacts] '886645789','amitfirst2@gmail.com',0
********************************************************************/ 

CREATE    PROCEDURE [dbo].[CheckCustomerDuplicateContacts]
	@customerPhone VARCHAR(100),
	@email VARCHAR(100),
	@customerId BIGINT,
	@contactId BIGINT = 0
AS
BEGIN
		BEGIN TRY
			DECLARE @ReturnStatus INT = 0,
					@IsExistingCustomer INT = 0,
					@ExistingCustomerPhone VARCHAR(100),
					@ExistingEmail VARCHAR(100),
					@ExistinrContactId BIGINT,
					@ReturnMsg VARCHAR(150),
					@ContactIds VARCHAR(250),
					@MasterLoopID INT,
					@BreakLoop INT = 0,
					@ContactReturnMsg VARCHAR(150) = 'The work phone you are trying to use already exists.<br/>Are you sure you want to use it again?',
					@EmailReturnMsg VARCHAR(150) = 'The email address you are trying to use already exists. <br/>Are you sure you want to use it again?',
					@BothReturnMsg VARCHAR(150) = 'The work phone/email address you are trying to use already exists. <br/>Are you sure you want to use it again?';
			
			IF(@customerId > 0)
			BEGIN
				 SET @ContactIds = (SELECT  STUFF((SELECT ',' + CAST(ContactId AS VARCHAR(10)) [text()]
						FROM [dbo].[CustomerContact] WITH(NOLOCK)
						WHERE CustomerId = @customerId AND [IsDeleted] = 0
				 FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'),1,2,' ') CustomersId)
			END

			--Checking for current customer email & phone.
			IF(@contactId > 0)
			BEGIN 
				IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email AND [ContactId] != @contactId)
				BEGIN
					IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @customerPhone AND [ContactId] != @contactId)
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
				ELSE IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @customerPhone AND [ContactId] != @contactId)
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email AND [ContactId] != @contactId)
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
				IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email)
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @customerPhone)
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
				ELSE IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [WorkPhone] = @customerPhone)
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[Contact] WITH(NOLOCK) WHERE [Email] = @email)
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

			SELECT @ReturnStatus AS Status, @ReturnMsg AS Msg;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckCustomerDuplicateEmailContact' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@customerPhone, '') + ''
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