-- EXEC [UpdateStockLineQty]
CREATE PROCEDURE [dbo].[UpdateStockLineQty]
@StockLineId BIGINT,
@WOSReserveId BIGINT,
@QtyReserved INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		 DECLARE @QuantityAvailable INT
		 DECLARE @QuantityReserved INT

		 SELECT @QuantityAvailable = QuantityAvailable, @QuantityReserved = QuantityReserved
		 FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId

		 SET @QuantityAvailable = @QuantityAvailable + @QtyReserved
		 SET @QuantityReserved = @QuantityReserved - @QtyReserved

		 UPDATE Stockline SET QuantityAvailable = @QuantityAvailable, QuantityReserved = @QuantityReserved, UpdatedBy = 'PAS Service', UpdatedDate = GETDATE()
		 WHERE StockLineId = @StockLineId
		 
		 UPDATE WorkOrderStockLineReserve SET IsReserved = 0,UpdatedBy = 'PAS Service', UpdatedDate = GETDATE() 
		 WHERE WOSReserveId = @WOSReserveId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateStockLineQty' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StockLineId, '') + ''
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