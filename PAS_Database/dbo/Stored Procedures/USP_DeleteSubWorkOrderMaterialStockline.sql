/*************************************************************             
 ** File:   [USP_DeleteSubWorkOrderMaterialStockline]             
 ** Author:  Amit Ghediya  
 ** Description: This stored procedure is used to delete SubWorkOrder Materials Stockline.  
 ** Purpose:           
 ** Date:    14/04/2025     
            
 ** PARAMETERS: @subWorkOrderMaterialId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------			--------------------------------            
    1    14/04/2025  Amit Ghediya			Created  
       
-- EXEC USP_DeleteSubWorkOrderMaterialStockline 129,194091,'AMIT GHEDIYA'  
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_DeleteSubWorkOrderMaterialStockline]  
	@SubWorkOrderMaterialsId BIGINT,
	@StocklineId BIGINT,
    @UpdatedBy VARCHAR(100)
AS  
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
	 BEGIN TRANSACTION;
	 BEGIN TRY  
	  
		    -- Delete SubWorkOrderStockLineReserve if exists
			IF EXISTS(SELECT TOP 1 SWOSReserveId FROM [DBO].[SubWorkOrderStockLineReserve] WITH(NOLOCK) WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId AND [StockLineId] = @StocklineId)
			BEGIN
				 DELETE FROM [DBO].[SubWorkOrderStockLineReserve] WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId AND [StockLineId] = @StocklineId;
			END

			-- Delete SubWorkOrderMaterialStockLine if exists
			IF EXISTS(SELECT TOP 1 SWOMStockLineId FROM [DBO].[SubWorkOrderMaterialStockLine] WITH(NOLOCK) WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId AND [StockLineId] = @StocklineId)
			BEGIN
				 DELETE FROM [DBO].[SubWorkOrderMaterialStockLine] WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId AND [StockLineId] = @StocklineId;
			END

			-- UpdateSubWOMaterialsCost
			EXEC [DBO].[USP_UpdateSubWOMaterialsCost] @SubWorkOrderMaterialsId;
			
		 COMMIT TRANSACTION;
	 END TRY      
     BEGIN CATCH        
     IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRANSACTION; 
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
--		--------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		         , @AdhocComments     VARCHAR(150)    = 'USP_DeleteSubWorkOrderMaterialStockline'   
		         , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderMaterialsId, '') + ''  
		         , @ApplicationName VARCHAR(100) = 'PAS'  
--		--------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
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