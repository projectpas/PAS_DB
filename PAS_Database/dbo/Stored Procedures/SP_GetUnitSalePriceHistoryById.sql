-- =============================================
-- Author:		Ekta Chandegra
-- Create date: 09-01-2024
-- Description:	This stored procedure is used to retrieve history of unit sales price.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    09-01-2024   Ekta Chandegra		Created

	EXEC [GetUnitSalePriceHistoryById] 163178

**************************************************************/

CREATE   PROC [dbo].[SP_GetUnitSalePriceHistoryById]
@StocklineId bigint


AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		
		SELECT StockLineNumber,UnitSalesPrice,SalesPriceExpiryDate,CreatedDate,
		UpdatedDate,UpdatedBy
		FROM [dbo].[UnitSalePriceHistoryAudit] 
		WHERE StocklineId = @StocklineId
		
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[SP_GetUnitSalePriceHistoryById]' 
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