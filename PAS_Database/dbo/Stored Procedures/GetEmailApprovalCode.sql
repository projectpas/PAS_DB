/*************************************************************           
 ** File: [GetEmailApprovalCode]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to check approvalcode is match with email send time generate
 ** Purpose:         
 ** Date:   27/08/2025    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    27/08/2025   Amit Ghediya     Created
     
-- EXEC [GetEmailApprovalCode] 
************************************************************************/

CREATE   PROCEDURE [dbo].[GetEmailApprovalCode]
	@RefrenceId BIGINT,
	@ApprovalCode VARCHAR(200) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @return BIT = 0;
		IF(@RefrenceId > 0)
		BEGIN
			 IF EXISTS (SELECT SalesOrderQuoteId FROM [DBO].[SalesorderQuote] WHERE [SalesOrderQuoteId]  = @RefrenceId AND [ApprovalCode] = @ApprovalCode)
			 BEGIN
				  SET @return = 1;
			 END
		END

		SELECT @return AS CodeExists

	END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetEmailApprovalCode' 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = ''
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END