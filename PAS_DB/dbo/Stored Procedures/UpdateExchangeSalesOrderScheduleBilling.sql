-- =============================================
-- Author:		Deep Patel
-- Create date: 16-September-2021
-- Description:	Update columns into corrosponding reference Id values from respective table.....
-- =============================================
--  EXEC [dbo].[UpdateExchangeSalesOrderScheduleBilling] 5
CREATE PROCEDURE [dbo].[UpdateExchangeSalesOrderScheduleBilling]
	@ExchangeSalesOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update EQ
		SET 
		ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId
		FROM [dbo].[ExchangeSalesOrderScheduleBilling] EQ WITH (NOLOCK)
		INNER JOIN DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) ON ESOP.ExchangeSalesOrderPartId = EQ.ExchangeSalesOrderPartId
		INNER JOIN DBO.ExchangeSalesOrder SP WITH (NOLOCK) ON ESOP.ExchangeSalesOrderId = SP.ExchangeSalesOrderId
		Where ESOP.ExchangeSalesOrderId = @ExchangeSalesOrderId

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeSalesOrderScheduleBilling' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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