/*************************************************************             
 ** File:   [USP_DeleteWorkOrderMaterialStockline]             
 ** Author:  Amit Ghediya  
 ** Description: This stored procedure is used to delete SubWorkOrder Materials Stockline.  
 ** Purpose:           
 ** Date:    28/04/2025     
            
 ** PARAMETERS: @subWorkOrderMaterialId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------			--------------------------------            
    1    28/04/2025  Amit Ghediya			Created  
       
-- EXEC USP_DeleteWorkOrderMaterialStockline 129,194091,'AMIT GHEDIYA'  
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_DeleteWorkOrderMaterialStockline]  
	@WorkOrderMaterialsId BIGINT,
	@StocklineId BIGINT,
    @UpdatedBy VARCHAR(100)
AS  
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
	 BEGIN TRANSACTION;
	 BEGIN TRY  
	  
			DECLARE @WorkFlowWorkOrderId BIGINT;
			
			--Delete WorkOrderReservedStock
			IF EXISTS(SELECT TOP 1 WOReservedStockId FROM [DBO].[WorkOrderReservedStock] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId AND [StockLIneId] = @StocklineId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderReservedStock] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId AND [StockLIneId] = @StocklineId;
			END

			--Delete WorkOrderStockLineReserve
			IF EXISTS(SELECT TOP 1 WOSReserveId FROM [DBO].[WorkOrderStockLineReserve] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId AND [StockLIneId] = @StocklineId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderReservedStock] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId AND [StockLIneId] = @StocklineId;
			END

			--Delete WorkOrderStockLineReserve
			IF EXISTS(SELECT TOP 1 WOMStockLineId FROM [DBO].[WorkOrderMaterialStockLine] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId AND [StockLIneId] = @StocklineId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderMaterialStockLine] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId AND [StockLIneId] = @StocklineId;
			END

			--GET WorkFlowWorkOrderId
			SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [DBO].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;

			--Call for UpadteMaterialsCost
			EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId,@WorkFlowWorkOrderId;
			
		 COMMIT TRANSACTION;
	 END TRY      
     BEGIN CATCH        
     IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRANSACTION; 
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
--		--------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		         , @AdhocComments     VARCHAR(150)    = 'USP_DeleteWorkOrderMaterialStockline'   
		         , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderMaterialsId, '') + ''  
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