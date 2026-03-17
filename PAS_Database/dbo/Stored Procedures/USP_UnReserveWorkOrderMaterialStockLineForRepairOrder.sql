/*************************************************************           
 ** File:  [USP_UpdateWorkOrderMaterialStockLine]     
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Update Work Order Material Stockline
 ** Purpose:         
 ** Date:   12/03/2026
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------              
	1    12/03/2026   Moin Bloch       Created PN-15605
	
--  EXEC PROC [USP_UnReserveWorkOrderMaterialStockLineForRepairOrder]  24273,32556,26581,200491,1,0,1,'Admin User'

**************************************************************/
CREATE PROCEDURE [dbo].[USP_UnReserveWorkOrderMaterialStockLineForRepairOrder]
@WorkOrderId BIGINT = NULL,
@WOMStockLineId BIGINT = NULL,
@WorkOrderMaterialsId BIGINT = NULL,
@StockLineId BIGINT = NULL,
@Quantity INT = NULL,
@IsKitType BIT = NULL,
@MasterCompanyId INT = NULL,
@UpdatedBy VARCHAR(256)= NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
    -- Declare variables
      DECLARE @WorkOrderModuleID INT,@StocklineHistoryUNReserveActionEnum BIGINT,@UpdatedDate DATETIME2(7) = GETUTCDATE()
	  DECLARE @MaterialRefNo VARCHAR(100) = 'UnReserve', @WONumber VARCHAR(100);
	  DECLARE @historySubModuleId BIGINT,@TemplateBody NVARCHAR(MAX)
	  DECLARE @REPAIRProvisionId INT,@ProvisionId INT,@QtyReserved INT=0,@QtyIssued INT=0
	  DECLARE @QuantityAvailable INT=0,@QuantityReserved INT=0,@WorkFlowWorkOrderId BIGINT,@WorkOrderPartNoId BIGINT
	  DECLARE @historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@historyPartNumber VARCHAR(50)
	-- Modules
	  SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';	
	  SELECT @historySubModuleId = [ModuleId] FROM [dbo].[Module] WHERE [ModuleName] = 'WorkOrderMPN';
	  SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = 'UnReservedParts';

	  SELECT @REPAIRProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE UPPER([StatusCode]) = 'REPAIR';

	-- STOCKLINE UN-RESERVE ENUM			
	   SELECT @StocklineHistoryUNReserveActionEnum = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type]='UnReserve';
		
	   SELECT @WONumber = [WorkOrderNum] FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId

	   SELECT @ProvisionId = [ProvisionId], @QtyReserved = ISNULL([QtyReserved],0), @QtyIssued = ISNULL([QtyIssued],0) FROM [dbo].[WorkOrderMaterialStockLine] WITH(NOLOCK) WHERE [WOMStockLineId] = @WOMStockLineId AND [MasterCompanyId] = @MasterCompanyId

	   IF(@ProvisionId <> @REPAIRProvisionId AND @QtyIssued = 0)
	   BEGIN
			IF(@IsKitType = 0 )
			BEGIN
				UPDATE WOMS
				   SET [ProvisionId] = @REPAIRProvisionId 				   
				  FROM [dbo].[WorkOrderMaterialStockLine] WOMS 
				 WHERE WOMS.[WOMStockLineId] = @WOMStockLineId		
			END			
	    END

		IF(@IsKitType = 0 AND @QtyIssued = 0)
		BEGIN
			SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId;
			SELECT @WorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;
			SELECT @historyPartNumber = [IncomingPartNumber] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNoId;

			IF(@QtyReserved > 0)
			BEGIN						
				UPDATE WOM 
				   SET [QuantityReserved] = ISNULL(WOM.[QuantityReserved],0) - ISNULL(@Quantity,0),								
					   [TotalReserved] = ISNULL(WOM.[TotalReserved],0) - ISNULL(@Quantity,0),
					   [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = @UpdatedDate								
				  FROM [dbo].[WorkOrderMaterials] WOM 
				 WHERE WOM.[WorkOrderMaterialsId] = @WorkOrderMaterialsId

				UPDATE WOMS
				   SET [QtyReserved] = ISNULL([QtyReserved], 0) - ISNULL(@Quantity, 0),				   
					   [UpdatedDate] = @UpdatedDate,												
					   [UpdatedBy] = @UpdatedBy, 
					   [ReferenceNumber] = @MaterialRefNo + ' - '+ @WONumber
				  FROM [dbo].[WorkOrderMaterialStockLine] WOMS 
				 WHERE WOMS.[WOMStockLineId] = @WOMStockLineId

				 SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
				 SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@Quantity,''));
						
				 EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,@historySubModuleId,@WorkOrderPartNoId,@Quantity,@Quantity,@TemplateBody,'UnReservedParts',@MasterCompanyId,@UpdatedBy,NULL,@UpdatedBy,NULL;
									
				SELECT @QuantityAvailable = ISNULL([QuantityAvailable],0),
					   @QuantityReserved = ISNULL([QuantityReserved],0)				  
				  FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

				UPDATE [dbo].[StockLine]
				   SET [QuantityReserved] = @QuantityReserved - @Quantity,		      
					   [QuantityAvailable] = @QuantityAvailable + @Quantity,
					   [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = @UpdatedDate		
				 WHERE [StockLineId] = @StockLineId;	

				 -- STOCKLINE Un-Reserve HISTORY
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@WorkOrderModuleID,@WorkOrderId,NULL,NULL,@StocklineHistoryUNReserveActionEnum,@Quantity,@UpdatedBy;

			END	
		END
		ELSE
		BEGIN
			SELECT @ProvisionId = [ProvisionId], @QtyReserved = ISNULL([QtyReserved],0), @QtyIssued = ISNULL([QtyIssued],0) FROM [dbo].[WorkOrderMaterialStockLineKit] WITH(NOLOCK) WHERE [WorkOrderMaterialStockLineKitId] = @WOMStockLineId AND [MasterCompanyId] = @MasterCompanyId

			IF(@ProvisionId <> @REPAIRProvisionId AND @QtyIssued = 0)
		    BEGIN			
				UPDATE WOMS
				   SET [ProvisionId] = @REPAIRProvisionId 				   
				  FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS 
				 WHERE WOMS.[WorkOrderMaterialStockLineKitId] = @WOMStockLineId	
			END

			IF(@IsKitType = 1 AND @QtyIssued = 0)
			BEGIN
				SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE [WorkOrderMaterialsKitId] = @WorkOrderMaterialsId;
				SELECT @WorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;
				SELECT @historyPartNumber = [IncomingPartNumber] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNoId;

				IF(@QtyReserved > 0)
				BEGIN
					UPDATE WOM 
					   SET [QuantityReserved] = ISNULL(WOM.[QuantityReserved],0) - ISNULL(@Quantity,0),	
						   [TotalReserved] = ISNULL(WOM.[TotalReserved],0) - ISNULL(@Quantity,0),
						   [UpdatedBy] = @UpdatedBy,
						   [UpdatedDate] = @UpdatedDate								
					  FROM [dbo].[WorkOrderMaterialsKit] WOM 
					 WHERE WOM.[WorkOrderMaterialsKitId] = @WorkOrderMaterialsId

					 UPDATE WOMS
					   SET [QtyReserved] = ISNULL([QtyReserved], 0) - ISNULL(@Quantity, 0),				   
						   [UpdatedDate] = @UpdatedDate,												
						   [UpdatedBy] = @UpdatedBy, 
						   [ReferenceNumber] = @MaterialRefNo + ' - '+ @WONumber
					  FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS 
					 WHERE WOMS.[WorkOrderMaterialStockLineKitId] = @WOMStockLineId

					 SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
					 SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@Quantity,''));
						
					 EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,@historySubModuleId,@WorkOrderPartNoId,@Quantity,@Quantity,@TemplateBody,'UnReservedParts',@MasterCompanyId,@UpdatedBy,NULL,@UpdatedBy,NULL;
									
					SELECT @QuantityAvailable = ISNULL([QuantityAvailable],0),
						   @QuantityReserved = ISNULL([QuantityReserved],0)				  
					  FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

					UPDATE [dbo].[StockLine]
					   SET [QuantityReserved] = @QuantityReserved - @Quantity,		      
						   [QuantityAvailable] = @QuantityAvailable + @Quantity,
						   [UpdatedBy] = @UpdatedBy,
						   [UpdatedDate] = @UpdatedDate		
					 WHERE [StockLineId] = @StockLineId;	

					 -- STOCKLINE Un-Reserve HISTORY
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@WorkOrderModuleID,@WorkOrderId,NULL,NULL,@StocklineHistoryUNReserveActionEnum,@Quantity,@UpdatedBy;

				END
			END

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
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderMaterialStockLine' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) +
													 '@Parameter3 = ''' + CAST(ISNULL(@WorkOrderMaterialsId, '') AS VARCHAR(100))
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