/*************************************************************               
 ** File:   [CheckCustomerDuplicateEmailContac]               
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
 
 EXEC [CheckCustomerDuplicateEmailContact] '123456789','AMIT@GDGD.COM'
********************************************************************/ 

CREATE      PROCEDURE [dbo].[CheckCustomerDuplicateEmailContact]
	@customerPhone VARCHAR(100),
	@email VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
			
			DECLARE @ReturnStatus INT = 0,
					@ReturnMsg VARCHAR(150);
				
			IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email)
			BEGIN
				 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone)
				 BEGIN
					  SET @ReturnStatus = -3;
					  SET @ReturnMsg = 'The contact number/email address you are trying to use already exists. <br/>Are you sure you want to use it again?';
				 END
				 ELSE
				 BEGIN
					 SET @ReturnStatus = -1;
					 SET @ReturnMsg = 'The email address you are trying to use already exists. <br/>Are you sure you want to use it again?';
				 END
			END
			ELSE IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerPhone] = @customerPhone)
			BEGIN
				 IF EXISTS(SELECT 1 FROM [dbo].[Customer] WITH(NOLOCK) WHERE [Email] = @email)
				 BEGIN
					  SET @ReturnStatus = -3;
					  SET @ReturnMsg = 'The contact number/email address you are trying to use already exists.<br/>Are you sure you want to use it again?';
				 END
				 ELSE
				 BEGIN
					  SET @ReturnStatus = -2;
					  SET @ReturnMsg = 'The contact number you are trying to use already exists.<br/>Are you sure you want to use it again?';
				 END
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