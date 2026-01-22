/*************************************************************           
 ** File:   [UpdateExchangeSalesOrderChargesAmount]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to update ExchangeSalesOrder Charges Billing Amount
 ** Purpose:         
 ** Date:   09-04-2024
 ** PARAMETERS: @ExchangeSalesOrderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09-04-2024  Abhishek Jirawla     Created
-- EXEC [UpdateExchangeSalesOrderChargesAmount] 13
************************************************************************/
CREATE   PROCEDURE [dbo].[UpdateExchangeSalesOrderChargesAmount]
@ExchangeSalesOrderId bigint,
@BillingAmount bigint,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	IF(@Opr=1)
	BEGIN
		UPDATE dbo.[ExchangeSalesOrder] SET [ChargeFlatRate] -= @BillingAmount where ExchangeSalesOrderId = @ExchangeSalesOrderId;
	END
	ELSE
	BEGIN
	    UPDATE dbo.[ExchangeSalesOrder] SET [ChargeFlatRate] += @BillingAmount where ExchangeSalesOrderId = @ExchangeSalesOrderId;
	END
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeSalesOrderChargesAmount' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ExchangeSalesOrderId, '') AS varchar(100))													
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