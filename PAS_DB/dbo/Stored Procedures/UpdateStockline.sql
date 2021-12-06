
CREATE PROC [dbo].[UpdateStockline]
	@StocklineId  bigint,
	@QtyToReserve int,
	@QuantityOnOrder int,
	@UpdatedBy varchar(50)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			
				 Update dbo.StockLine 
					SET QuantityAvailable = QuantityAvailable - @QtyToReserve,
					QuantityReserved = QuantityReserved + @QtyToReserve,
					QuantityOnOrder = @QuantityOnOrder,
					UpdatedBy = @UpdatedBy
					Where StockLineId = @StocklineId
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateStockline' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StocklineId, '') + ''',
														@Parameter2 = ' + ISNULL(@QtyToReserve,'') + ', 
														@Parameter3 = ' + ISNULL(@QuantityOnOrder,'') + ', 
			                                            @Parameter4 = ' + ISNULL(@UpdatedBy,'') +''
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