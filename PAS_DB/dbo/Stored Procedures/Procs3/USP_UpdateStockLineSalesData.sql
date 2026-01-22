/*************************************************************           
 ** File:   [USP_UpdateStockLineSalesData]           
 ** Author:   Devendra Shekh
 ** Description: Update Stockline Sales Data 
 ** Purpose:         
 ** Date:   20th November 2023
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    20-11-2023     Devendra Shekh			Created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateStockLineSalesData]
@tbl_StockLineSalesDataType StockLineSalesDataType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN

					IF((SELECT COUNT([StockLineId]) FROM @tbl_StockLineSalesDataType) > 0 )
					BEGIN
						MERGE dbo.Stockline AS TARGET
						USING @tbl_StockLineSalesDataType AS SOURCE ON (TARGET.[StockLineId] = SOURCE.[StockLineId]) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 							
								 TARGET.[UnitSalesPrice] = SOURCE.[UnitSalesPrice]
								,TARGET.[SalesPriceExpiryDate] = SOURCE.[SalesPriceExpiryDate]
								,TARGET.[UpdatedBy] = SOURCE.[UpdatedBy]
								,TARGET.[UpdatedDate] = GETUTCDATE();
					 END

					IF((SELECT COUNT([StockLineId]) FROM @tbl_StockLineSalesDataType) > 0 )
					BEGIN
						MERGE dbo.Stockline AS TARGET
						USING @tbl_StockLineSalesDataType AS SOURCE ON (TARGET.ParentId = SOURCE.[StockLineId]) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 							
								 TARGET.[UnitSalesPrice] = SOURCE.[UnitSalesPrice]
								,TARGET.[SalesPriceExpiryDate] = SOURCE.[SalesPriceExpiryDate]
								,TARGET.[UpdatedBy] = SOURCE.[UpdatedBy]
								,TARGET.[UpdatedDate] = GETUTCDATE();
					 END

				COMMIT  TRANSACTION
			END

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateStockLineSalesData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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