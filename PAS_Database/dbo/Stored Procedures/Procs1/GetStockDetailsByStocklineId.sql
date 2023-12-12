
-- EXEC [dbo].[GetStockDetailsByStocklineId] 189
CREATE PROC [dbo].[GetStockDetailsByStocklineId]
	@StocklineId  bigint
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT sl.StockLineId, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.ConditionId, cond.Description as Condition,
		sl.CreatedDate, sl.QuantityIssued, sl.QuantityReserved, sl.QuantityToReceive
		FROM StockLine sl WITH (NOLOCK)
		INNER JOIN ItemMaster im WITH (NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
		INNER JOIN Condition cond WITH (NOLOCK) on sl.ConditionId = cond.ConditionId
		WHERE StockLineId = @StocklineId
		ORDER BY sl.CreatedDate
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetStockDetailsByStocklineId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StocklineId, '') + ''
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