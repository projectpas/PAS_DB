﻿/*************************************************************               
 ** File:   [CheckEmailContactExists]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to check customer emial & phone is exists.   
 ** Purpose:             
 ** Date:   12/08/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone exists.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    12/08/2024  	AMIT GHEDIYA	Created     
	2    21/08/2024  	Devendra Shekh	added @CustomerContactId param  
	3    22/08/2024  	AMIT GHEDIYA	added @ContactId param 
	4    18/09/2024     SAHDEV SALIYA   Contact info Restriction Message changes
 
 EXEC [CheckEmailContactExists] 12,0,0
********************************************************************/ 
CREATE   PROCEDURE [dbo].[CheckEmailContactExists]
	@customerId BIGINT = 0,
	@CustomerContactId BIGINT NULL = 0,
	@ContactId BIGINT NULL = 0
AS
BEGIN
		BEGIN TRY
			
			DECLARE @ReturnStatus INT = 0,
					@ExistingCustomerPhone VARCHAR(100),
					@ExistingContactPhone VARCHAR(100),
					@ExistingEmail VARCHAR(100),
					@ExistingContactEmail VARCHAR(100),
					@ContactIds BIGINT,
					@ReturnMsg VARCHAR(150) = 'Please update email address and/or phone number.';
			
			--Get Email & Phone from Customer Primary Comtact details.
			SELECT @ContactIds = [ContactId] FROM [dbo].[CustomerContact] WITH(NOLOCK) WHERE [CustomerId] = @customerId AND [IsDefaultContact] = 1;
			IF(ISNULL(@CustomerContactId, 0) > 0)
			BEGIN 
				IF(ISNULL(@ContactId,0) > 0)
				BEGIN
					 SELECT @CustomerContactId = [ContactId] FROM [dbo].[CustomerContact] WITH(NOLOCK) WHERE [CustomerContactId] = @CustomerContactId;
				END
				SELECT @ExistingContactPhone = [WorkPhone], @ExistingContactEmail = [Email] FROM [dbo].[contact] WITH(NOLOCK) WHERE [ContactId] = @CustomerContactId;
			END
			ELSE
			BEGIN 
				SELECT @ExistingContactPhone = [WorkPhone], @ExistingContactEmail = [Email] FROM [dbo].[contact] WITH(NOLOCK) WHERE [ContactId] = @ContactIds;
			END
			
			--Get Email & Phone from Customer details.
			SELECT @ExistingCustomerPhone = [CustomerPhone], @ExistingEmail = [Email] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @customerId AND [IsActive] = 1 AND [IsDeleted] = 0;
			IF(ISNULL(@ExistingCustomerPhone,'') = '' OR ISNULL(@ExistingContactPhone,'') = '')
			BEGIN
				 SET @ReturnStatus = -1;
				 SET @ReturnMsg = @ReturnMsg;
			END
			ELSE IF(ISNULL(@ExistingEmail,'') = '' OR ISNULL(@ExistingContactEmail,'') = '')
			BEGIN
				 SET @ReturnStatus = -1;
				 SET @ReturnMsg = @ReturnMsg;
			END
			ELSE
			BEGIN
				 SET @ReturnStatus = 1;
				 SET @ReturnMsg = '';
			END

			SELECT @ReturnStatus AS Status, @ReturnMsg AS Msg;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckEmailContactExists' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@customerId, '') + ''
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