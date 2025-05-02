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
	  
			DECLARE @WorkOrderId BIGINT,
					@POId BIGINT;
			
			--Update StockLine
			IF EXISTS(SELECT TOP 1 StockLineId FROM [DBO].[StockLine] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 UPDATE [DBO].[Stockline] SET WorkOrderMaterialsId = NULL WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--Delete WorkOrderIssuedStock
			IF EXISTS(SELECT TOP 1 WOIssuedStockId FROM [DBO].[WorkOrderIssuedStock] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderIssuedStock] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--Delete WorkOrderUnIssuedStock
			IF EXISTS(SELECT TOP 1 WOUnIssuedStockId FROM [DBO].[WorkOrderUnIssuedStock] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderUnIssuedStock] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--Delete WorkOrderReservedStock
			IF EXISTS(SELECT TOP 1 WOReservedStockId FROM [DBO].[WorkOrderReservedStock] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderReservedStock] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--Delete  WorkOrderUnReservedStock
			IF EXISTS(SELECT TOP 1 WOUnReservedStockId FROM [DBO].[WorkOrderUnReservedStock] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderUnReservedStock] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--Delete WorkOrderStockLineReserve
			IF EXISTS(SELECT TOP 1 WOSReserveId FROM [DBO].[WorkOrderStockLineReserve] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderStockLineReserve] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--Delete WorkOrderMaterialStockLine
			IF EXISTS(SELECT TOP 1 WOMStockLineId FROM [DBO].[WorkOrderMaterialStockLine] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[WorkOrderMaterialStockLine] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END

			--If Exists SubWorkOrder
			IF EXISTS(SELECT TOP 1 SubWorkOrderId FROM [DBO].[SubWorkOrder] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId)
			BEGIN
				 SELECT @WorkOrderId = [WorkOrderId], @POId = [POId] FROM [DBO].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId

				 -- Call for UnMappedPOByWorkOrderMaterialsId.
				 EXEC [DBO].[USP_UnMappedPOByWorkOrderMaterialsId] 
					 @WorkOrderMaterialsId,
					 0,  -- false for kit
					 0,  -- false for subWO
					 @WorkOrderId, -- for ReferenceId
					 @POId,
					 @UpdatedBy;

				--Update WorkOrderMaterials
				UPDATE [DBO].[WorkOrderMaterials] SET [IsDeleted] = 1 WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END
			ELSE
			BEGIN
				 SELECT @WorkOrderId = [WorkOrderId], @POId = [POId] FROM [DBO].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId

				 -- Call for UnMappedPOByWorkOrderMaterialsId.
				 EXEC [DBO].[USP_UnMappedPOByWorkOrderMaterialsId] 
					 @WorkOrderMaterialsId,
					 0,  -- false for kit
					 0,  -- false for subWO
					 @WorkOrderId, -- for ReferenceId
					 @POId,
					 @UpdatedBy;

				 -- Delete WorkOrderMaterials
				 DELETE FROM [DBO].[WorkOrderMaterials] WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			END
			
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