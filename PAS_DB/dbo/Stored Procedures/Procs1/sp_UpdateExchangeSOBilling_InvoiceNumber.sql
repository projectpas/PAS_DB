
--EXEC sp_UpdateExchangeSOBilling_InvoiceFix '70,69,68'
CREATE    Procedure [dbo].[sp_UpdateExchangeSOBilling_InvoiceNumber]
@SOBillingInvoicingIds  varchar(500)
as
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRAN
	BEGIN TRY
	BEGIN
		DECLARE @SOBillingInvoicingId BIGINT;

		SELECT @SOBillingInvoicingId = MIN(SOBillingInvoicingId) FROM dbo.ExchangeSalesOrderBillingInvoicing WITH(NOLOCK) WHERE SOBillingInvoicingId IN (SELECT Item FROM DBO.SPLITSTRING(@SOBillingInvoicingIds,','))

		UPDATE dbo.ExchangeSalesOrderBillingInvoicingItem SET SOBillingInvoicingId = @SOBillingInvoicingId WHERE SOBillingInvoicingId IN (SELECT Item FROM DBO.SPLITSTRING(@SOBillingInvoicingIds,','))

		UPDATE dbo.ExchangeSalesOrderBillingInvoicing SET InvoiceNo = (SELECT TOP 1 InvoiceNo FROM dbo.ExchangeSalesOrderBillingInvoicing WITH(NOLOCK) WHERE SOBillingInvoicingId = @SOBillingInvoicingId ) 
		       wHERE SOBillingInvoicingId IN (SELECT Item FROM DBO.SPLITSTRING(@SOBillingInvoicingIds,','))
	
		SELECT
		InvoiceNo as value
		FROM dbo.ExchangeSalesOrderBillingInvoicing SB WITH (NOLOCK) WHERE SOBillingInvoicingId = @SOBillingInvoicingId
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_UpdateExchangeSOBilling_InvoiceNumber' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SOBillingInvoicingId, '') + ''
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