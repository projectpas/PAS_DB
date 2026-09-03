/*************************************************************             
 ** File:   [USP_Lot_UpdateCOGSByStocklineId]             
 ** Author:   
 ** Description: This stored procedure is used to update  Stockline Adjustment,Freight Adjustment,Tax Adjustment
 ** Date:   02/09/2026
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    02/09/2026   Moin Bloch    Created 
	       
EXEC [dbo].[USP_Lot_UpdateCOGSByStocklineId] 217

************************************************************************/
CREATE PROCEDURE [dbo].[USP_Lot_UpdateCOGSByStocklineId]
@StocklineId BIGINT,
@FreightAdjustment DECIMAL(18,2) = 0,
@MiscAdjustment DECIMAL(18,2) = 0,
@TaxAdjustment  DECIMAL(18,2) = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
			Print @StocklineId
			
				
	END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_Lot_UpdateCOGSByStocklineId' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))  
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