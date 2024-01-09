-- =============================================
-- Author:		Ekta Chandegra
-- Create date: 26-12-2023
-- Description:	This stored procedure is used to count Stockline Inventory mismatch.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    26-12-2023   Ekta Chandegra		Created
	2    02-01-2024   Ekta Chandegra		Add quantity related fields

	EXEC [GetUnitSalePriceHistoryById] 163178

**************************************************************/

CREATE   PROC [dbo].[SP_GetUnitSalePriceHistoryById]
@StocklineId bigint


AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		
		SELECT StockLineNumber,UnitSalesPrice,SalesPriceExpiryDate,CreatedDate,
		UpdatedDate,UpdatedBy
		FROM [dbo].[UnitSalePriceHistoryAudit] WITH (NOLOCK)
		WHERE StocklineId = @StocklineId
		
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetUnitSalePriceHistoryById' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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