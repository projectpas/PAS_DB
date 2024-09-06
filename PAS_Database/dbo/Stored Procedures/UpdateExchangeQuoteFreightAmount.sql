/*************************************************************           
 ** File:   [UpdateExchangeQuoteFreightAmount]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to update Exchange Sales Order Freight Billing Amount
 ** Purpose:         
 ** Date:   09-04-2024
 ** PARAMETERS: @ExchangeQuoteId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09-04-2024  Abhishek Jirawla     Created
-- EXEC [UpdateExchangeQuoteFreightAmount] 13
************************************************************************/
CREATE   PROCEDURE [dbo].[UpdateExchangeQuoteFreightAmount]
@ExchangeQuoteId bigint,
@BillingAmount bigint,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	IF(@Opr=1)
	BEGIN
		UPDATE dbo.ExchangeQuote SET [FreightFlatRate] -= @BillingAmount where [ExchangeQuoteId] = @ExchangeQuoteId;
	END
	ELSE
	BEGIN
	    UPDATE dbo.ExchangeQuote SET [FreightFlatRate] += @BillingAmount where [ExchangeQuoteId] = @ExchangeQuoteId;
	END
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeQuoteFreightAmount' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ExchangeQuoteId, '') AS varchar(100))													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END