/*************************************************************           
 ** File:     [USP_UpdateMPNTenderStocklineDetail]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used update Tendor Stockline 
 ** Purpose:         
 ** Date:   08/04/2024	          
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		08/04/2024		Moin Bloch			CREATED
	2		09/04/2024		Moin Bloch			Added Stockline History
	3		15/04/2024		Moin Bloch			Added Scrap Entry Operatin

	EXEC [USP_UpdateMPNTenderStocklineDetail] 1,1,'dsdsd'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateMPNTenderStocklineDetail]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
@UpdatedBy VARCHAR(50),
@Opr INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN	
				
				DECLARE @StockLineId BIGINT = 0;
				DECLARE @QuantityReserved INT = 0;
				DECLARE @QuantityOnHand INT = 0;
				DECLARE @QuantityAvailable INT = 0;
				DECLARE @QuantityIssued INT = 0;
				DECLARE @UnReserveActionId INT = 0;
				DECLARE @IssueActionId INT = 0;
				DECLARE @SubModuleId BIGINT;  
				DECLARE @SubReferenceId BIGINT;  
				DECLARE @HistoryModuleId INT = 0;

				SELECT @UnReserveActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type] = 'UnReserve'
				SELECT @IssueActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type] = 'Issue'
								
			    SELECT @HistoryModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
												
				SELECT @StockLineId = [StockLineId] FROM  [dbo].[WorkOrderPartNumber] WITH(NOLOCK)  WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNumberId;

				SELECT @QuantityReserved = ISNULL([QuantityReserved],0),
				       @QuantityOnHand = ISNULL([QuantityOnHand],0), 
				       @QuantityAvailable = ISNULL([QuantityAvailable],0),
					   @QuantityIssued = ISNULL([QuantityIssued],0)
				FROM  [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId;

				IF(@Opr = 1)   -- If Remaining Amount > 0
				BEGIN
					UPDATE [dbo].[Stockline] 
					   SET [QuantityReserved] = @QuantityReserved - 1,  
						 --[QuantityOnHand] = @QuantityOnHand - 1,					   
						 --[QuantityIssued] = @QuantityIssued + 1    
						   [QuantityAvailable] = @QuantityAvailable + 1,  
						   [UnitCost] = 0
					 WHERE [StockLineId] = @StocklineId;	

					 -- Quantity Un-Reserve History
					 EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @UnReserveActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;
				END
				IF(@Opr = 2)  -- If Remaining Amount = 0
				BEGIN
					UPDATE [dbo].[Stockline] 
					   SET [QuantityReserved] = @QuantityReserved - 1,   
						   [QuantityAvailable] = @QuantityAvailable + 1  
					 WHERE [StockLineId] = @StocklineId;	
					
					-- Quantity Un-Reserve History
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @UnReserveActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;
				END
				IF(@Opr = 3)  -- If Remaining Amount = 0
				BEGIN
					UPDATE [dbo].[Stockline] 
					   SET [QuantityReserved] = @QuantityReserved - 1,  						
						   [QuantityOnHand] = @QuantityAvailable - 1,  
						   [UnitCost] = 0
					 WHERE [StockLineId] = @StocklineId;
					
					-- Quantity Un-Reserve History
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @UnReserveActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;
				END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateTenderStocklineDetail' 
               ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END