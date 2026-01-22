/*************************************************************               
 ** File:   [CheckCustomerDuplicateEmailContact]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to check customer emial & phone duplicate.   
 ** Purpose:             
 ** Date:   07/08/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone duplicate.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    07/08/2024  	AMIT GHEDIYA	Created     
 
 EXEC [CheckCustomerDuplicateEmailContact] '123456789','AMIT@GDGD.COM',12
********************************************************************/ 

CREATE      PROCEDURE [dbo].[CheckCustomerDuplicateEmailContact]
	@customerPhone VARCHAR(100) = NULL,
	@email VARCHAR(100) = NULL,
	@customerId BIGINT = 0
AS
BEGIN
		BEGIN TRY
			
			DECLARE @ReturnStatus INT = 0,
					@IsExistingCustomer INT = 0,
					@ExistingCustomerPhone VARCHAR(100),
					@ExistingEmail VARCHAR(100),
					@ReturnMsg VARCHAR(150),
					@ContactReturnMsg VARCHAR(150) = 'The contact number you are trying to use already exists.<br/>Are you sure you want to use it again?',
					@EmailReturnMsg VARCHAR(150) = 'The email address you are trying to use already exists. <br/>Are you sure you want to use it again?',
					@BothReturnMsg VARCHAR(150) = 'The contact number/email address you are trying to use already exists. <br/>Are you sure you want to use it again?';

			--Checking for current customer email & phone.
			IF(@customerId > 0)
			BEGIN 
				SELECT @ExistingCustomerPhone = CustomerPhone ,@ExistingEmail = Email  FROM [dbo].[Customer] WITH(NOLOCK) WHERE [customerId] = @customerId AND [IsActive] = 1 AND [IsDeleted] = 0;
				IF(@ExistingCustomerPhone = @customerPhone)
				BEGIN 
					 IF(@ExistingEmail = @email)
					 BEGIN
						  SET @ReturnStatus = 1;
						  SET @ReturnMsg = '';
					 END
					 ELSE
					 BEGIN 
						 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email AND [customerId] != @customerId AND [IsActive] = 1 AND [IsDeleted] = 0)
						 BEGIN
							  SET @ReturnStatus = -1;
							  SET @ReturnMsg = @EmailReturnMsg;
						 END
						 ELSE
						 BEGIN
							  SET @ReturnStatus = 1;
							  SET @ReturnMsg = '';
						 END
					 END
				END
				ELSE IF(@ExistingEmail = @email)
				BEGIN
					 IF(@ExistingCustomerPhone = @customerPhone)
					 BEGIN
						 SET @ReturnStatus = 1;
						 SET @ReturnMsg = '';
					 END
					 ELSE
					 BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone AND [customerId] != @customerId AND [IsActive] = 1 AND [IsDeleted] = 0)
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
					IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email AND [customerId] != @customerId AND [IsActive] = 1 AND [IsDeleted] = 0)
					BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone AND [customerId] != @customerId AND [IsActive] = 1 AND [IsDeleted] = 0)
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
					ELSE IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone AND [customerId] != @customerId AND [IsActive] = 1 AND [IsDeleted] = 0)
					BEGIN
						 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email AND [customerId] != @customerId AND [IsActive] = 1 AND [IsDeleted] = 0)
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
			ELSE
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email AND [IsActive] = 1 AND [IsDeleted] = 0)
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone AND [IsActive] = 1 AND [IsDeleted] = 0)
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
				ELSE IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone AND [IsActive] = 1 AND [IsDeleted] = 0)
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email AND [IsActive] = 1 AND [IsDeleted] = 0)
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