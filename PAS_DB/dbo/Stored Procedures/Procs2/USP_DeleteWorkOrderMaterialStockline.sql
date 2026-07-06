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
	2    04/09/2025  Moin Bloch		    Updated Added History
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
       
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
			DECLARE @WorkOrderModuleID INT = 0
			DECLARE @DeleteWOMaterial VARCHAR(50)='DeleteWorkOrderMaterialStockline'
			DECLARE @TemplateBody VARCHAR(MAX)=''
			DECLARE @ItemMasterId BIGINT = 0
			DECLARE @PartNumber VARCHAR(50) = NULL
			DECLARE @StockLineNumber VARCHAR(50) = NULL
			DECLARE @CreatedDate DATETIME2(7) = GETUTCDATE()
			DECLARE @MasterCompanyId INT = 1
			DECLARE @WOPartNoId BIGINT=0
			DECLARE @WorkOrderId BIGINT

				--GET WorkFlowWorkOrderId
			SELECT @WorkOrderId = [WorkOrderId],@ItemMasterId = [ItemMasterId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [DBO].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			
			SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';	

			SELECT @WOPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
	
			SELECT @PartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;

			SELECT @StockLineNumber = [StockLineNumber], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId;
					
					
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

		
			--Call for UpadteMaterialsCost
			EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId,@WorkFlowWorkOrderId;
			
			-- History Template--							
			SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @DeleteWOMaterial;	

			SET @TemplateBody = REPLACE(@TemplateBody, '##StockLineNum##', @StockLineNumber)
			SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @PartNumber)
		
			EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WOPartNoId,'','',@TemplateBody,@DeleteWOMaterial,@MasterCompanyId,@UpdatedBy,@CreatedDate,@UpdatedBy,@CreatedDate
			
		 COMMIT TRANSACTION;
	 END TRY      
     BEGIN CATCH        
     IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRANSACTION; 
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
--		--------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		         , @AdhocComments     VARCHAR(150)    = 'USP_DeleteWorkOrderMaterialStockline'   
				 , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderMaterialsId, '') AS VARCHAR(100))  
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