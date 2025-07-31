-- =============================================
-- Author:		Amit Ghediya
/*************************************************************           
 ** File:  [UpdateCustomerRfqQuoteReferenceId]           
 ** Author:   Amit Ghediya
 ** Description: Update name columns into CustomerRfq referenceId & moduleId values from respective master table               
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    31/07/2025   Amit Ghediya		 Created         

	EXEC [dbo].[UpdateCustomerRfqQuoteReferenceId] 31
**************************************************************/ 
CREATE   PROCEDURE [dbo].[UpdateCustomerRfqQuoteReferenceId]
	@CustomerRfqId BIGINT,
	@QuoteReferenceId BIGINT,
	@ModuleId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			DECLARE @SpeedQuoteModuleId BIGINT = 0,
					@SalesQuoteModuleId BIGINT = 0;

			SELECT @SpeedQuoteModuleId  = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SpeedQuote';
			SELECT @SalesQuoteModuleId  = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) where [ModuleName] = 'SalesQuote';

			--Update for SOQ
			IF(ISNULL(@ModuleId,0) = @SalesQuoteModuleId)
			BEGIN
				 UPDATE CustomerRfq SET [ModuleId] = @SalesQuoteModuleId , [ReferenceId] = @QuoteReferenceId WHERE CustomerRfqId = @CustomerRfqId;
			END

			--Update for SQ
			IF(ISNULL(@ModuleId,0) = @SpeedQuoteModuleId)
			BEGIN
				 UPDATE CustomerRfq SET [ModuleId] = @SpeedQuoteModuleId , [ReferenceId] = @QuoteReferenceId WHERE CustomerRfqId = @CustomerRfqId;
			END
			
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateCustomerRfqQuoteReferenceId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@QuoteReferenceId AS VARCHAR), '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END