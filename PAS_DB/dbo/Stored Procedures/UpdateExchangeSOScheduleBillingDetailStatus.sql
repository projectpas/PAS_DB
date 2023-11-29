CREATE Procedure [dbo].[UpdateExchangeSOScheduleBillingDetailStatus]
	@ExchangeSalesOrderScheduleBillingId  bigint=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRAN
	BEGIN TRY
	BEGIN
		
			--UPDATE ExchangeSalesOrderBillingInvoicingItem SET IsDeleted=1 WHERE ExchangeSalesOrderScheduleBillingId = @ExchangeSalesOrderScheduleBillingId
		
			UPDATE ExchangeSalesOrderScheduleBilling SET StatusId=1 WHERE ExchangeSalesOrderScheduleBillingId = @ExchangeSalesOrderScheduleBillingId
		
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeSOScheduleBillingDetailStatus' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderScheduleBillingId, '') + ''
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