/*************************************************************               
 ** File:   [CheckStocklineForDelete]               
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to check stockline in RO,SO,WO
 ** Purpose:             
 ** Date:   18/12/2024        
 ** PARAMETERS:               
 ** RETURN VALUE:             
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author       Change Description                
 ** --   --------     -------  --------------------------------               
	1    18-12-2024   Moin Bloch   Created
	2    31-12-2024   Moin Bloch   Added Freight And Charges For WO/SO
	3    02-01-2025   Moin Bloch   Added Labor Completed Condition
    
-- EXEC [dbo].[CheckStocklineForDelete] 4724,15,'Jim Roberts'  
**************************************************************/ 
CREATE     PROCEDURE [dbo].[CheckStocklineForDelete]
@ReferenceId BIGINT,
@ModuleId INT,
@UpdatedBy VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY

	DECLARE @RoModuleId INT = 0,@SOModuleId INT = 0,@QtyReserved INT = 0,@WOModuleId INT = 0;	
	SELECT @RoModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]= 'RepairOrder';	 	
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]= 'SalesOrder';
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]= 'WorkOrder';
	DECLARE @FreightBilingMethodId INT = 3,@ChargesBilingMethodId INT = 3	
	
	IF(@ModuleId = @RoModuleId)
	BEGIN
		SELECT TOP 1 [RepairOrderId] AS ReferenceId FROM [dbo].[RepairOrderPart] WITH(NOLOCK) WHERE [RepairOrderId] = @ReferenceId;
	END
	IF(@ModuleId = @SOModuleId)
	BEGIN
		DECLARE @TotalSOFreight DECIMAL(18,2) = 0;
		DECLARE @TotalSOFlatFreight DECIMAL(18,2) = 0;
		DECLARE @TotalSOCharges DECIMAL(18,2) = 0;
		DECLARE @TotalSOFlatCharges DECIMAL(18,2) = 0;

		SELECT @QtyReserved = SUM([QtyReserved]) FROM [dbo].[SalesOrderPartV1] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId;
		IF(@QtyReserved > 0)
		BEGIN
			SELECT @ReferenceId AS ReferenceId
		END
		ELSE
		BEGIN			
			SET @TotalSOFreight = (SELECT ISNULL(SUM([BillingAmount]), 0) FROM [dbo].[SalesOrderFreight] sof WITH (NOLOCK) WHERE sof.[SalesOrderId] = @ReferenceId	AND sof.[IsActive] = 1 AND sof.[IsDeleted] = 0)

            SET @TotalSOFlatFreight = (SELECT ISNULL(SO.[TotalFreight],0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) WHERE [SO].[SalesOrderId] = @ReferenceId AND SO.[FreightBilingMethodId] = @FreightBilingMethodId)
			
            SET @TotalSOCharges = (SELECT ISNULL(SUM([BillingAmount]), 0) FROM [dbo].[SalesOrderCharges] socg WITH (NOLOCK) WHERE socg.[SalesOrderId] = @ReferenceId AND socg.[IsActive] = 1 AND socg.[IsDeleted] = 0) 
						
            SET @TotalSOFlatCharges = (SELECT ISNULL(SO.[TotalCharges],0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) WHERE [SO].[SalesOrderId] = @ReferenceId AND SO.[ChargesBilingMethodId] = @ChargesBilingMethodId)
			
			IF(@TotalSOFreight > 0 OR @TotalSOFlatFreight > 0)
			BEGIN
				SELECT -1 AS ReferenceId
			END
			ELSE IF(@TotalSOCharges > 0 OR @TotalSOFlatCharges > 0)
			BEGIN
				SELECT -2 AS ReferenceId
			END
			ELSE
			BEGIN
				SELECT 0 AS ReferenceId
			END
		END
	END
	IF(@ModuleId = @WOModuleId)
	BEGIN		
		IF OBJECT_ID(N'tempdb..#WOPartNumberDetailForDelete') IS NOT NULL
		BEGIN
			DROP TABLE #WOPartNumberDetailForDelete
		END

		CREATE TABLE #WOPartNumberDetailForDelete
		(
			[ID] BIGINT NOT NULL IDENTITY,
			[StockLineId] BIGINT
		)	

		DECLARE @MasterCompanyId INT = 0;

		SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @ReferenceId AND [IsDeleted] = 0;
		
		SELECT @QtyReserved = ISNULL(SUM(WOMS.QtyReserved),0)
		  FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsId] = WOMS.[WorkOrderMaterialsId]
		WHERE WOM.[WorkOrderId] = @ReferenceId AND WOMS.[IsDeleted] = 0;
		
		IF(@QtyReserved = 0)
		BEGIN
			SELECT @QtyReserved = ISNULL(SUM(WOMS.QtyReserved),0)
			  FROM [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsKitId] = WOMS.[WorkOrderMaterialsKitId]
			WHERE WOM.[WorkOrderId] = @ReferenceId AND WOMS.[IsDeleted] = 0;
			
			IF(@QtyReserved = 0)
			BEGIN			
				SELECT @QtyReserved = COUNT(SWOP.[WorkOrderId])
				FROM [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK)
				WHERE SWOP.[WorkOrderId] = @ReferenceId AND [IsClosed] = 0 AND SWOP.[IsDeleted] = 0;	
							   				 				
				IF(@QtyReserved = 0)
				BEGIN						
					DECLARE @TotalLaborCost DECIMAL(18,2) = 0;
					DECLARE @TotalWOFreight DECIMAL(18,2) = 0;
					DECLARE @TotalWOCharges DECIMAL(18,2) = 0;
					DECLARE @TaskStatusId BIGINT = 0;
							
				    SET  @TaskStatusId = (SELECT [TaskStatusId] FROM [dbo].[TaskStatus] WITH(NOLOCK) WHERE [Description] = 'COMPLETED' AND [MasterCompanyId] = @MasterCompanyId);
					
					SET @TotalLaborCost = (SELECT ISNULL(SUM(WOL.[TotalCost]),0)  
					FROM [dbo].[WorkOrderLaborHeader] WOLH WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderLabor] WOL WITH(NOLOCK) ON WOLH.[WorkOrderLaborHeaderId] = WOL.[WorkOrderLaborHeaderId] AND WOL.[TaskStatusId] = @TaskStatusId
					WHERE WOLH.[WorkOrderId] = @ReferenceId AND WOLH.[IsDeleted] = 0)

					SET @TotalWOFreight = (SELECT ISNULL(SUM([FreightCost]),0) FROM [dbo].[WorkOrderCostDetails] WITH(NOLOCK) WHERE [WorkOrderId] = @ReferenceId AND [IsDeleted] = 0);
					
					SET @TotalWOCharges = (SELECT ISNULL(SUM([ChargesCost]),0) FROM [dbo].[WorkOrderCostDetails] WITH(NOLOCK) WHERE [WorkOrderId] = @ReferenceId AND [IsDeleted] = 0);
					
					IF(@TotalLaborCost > 0)
					BEGIN
						SELECT -1 AS ReferenceId
					END
					ELSE IF(@TotalWOFreight > 0)
					BEGIN
						SELECT -2 AS ReferenceId
					END
					ELSE IF(@TotalWOCharges > 0)
					BEGIN
						SELECT -3 AS ReferenceId
					END
					ELSE
					BEGIN									   					 
						INSERT INTO #WOPartNumberDetailForDelete ([StockLineId])
						SELECT [StockLineId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId]=@ReferenceId
									   
						DECLARE @TotCount AS INT;
						DECLARE @LoopID AS INT;

						SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #WOPartNumberDetailForDelete;
					
						WHILE (@LoopID <= @TotCount)
						BEGIN
							DECLARE @StockLineId BIGINT=0;
							DECLARE @QuantityAvailable INT=0;
							DECLARE @QuantityReserved INT=0;
							DECLARE	@ActionId INT=0;

							SET @ActionId = (SELECT [ActionId] FROM DBO.[StklineHistory_Action] ITH  WITH(NOLOCK) WHERE [Type] = 'UnReserve');
						
							SELECT @StockLineId = [StockLineId] FROM #WOPartNumberDetailForDelete WHERE ID = @LoopID;
						
							IF(@StockLineId > 0)
							BEGIN
								SELECT @QuantityAvailable = ISNULL([QuantityAvailable],0),
									   @QuantityReserved = ISNULL([QuantityReserved],0)
								  FROM [dbo].[Stockline] WITH(NOLOCK) 
								 WHERE [StockLineId] = @StockLineId;

								 UPDATE [dbo].[Stockline] 
									SET [QuantityAvailable] = @QuantityAvailable + 1,
										[QuantityReserved] = @QuantityReserved - 1,
										[UpdatedBy] = @UpdatedBy,
										[UpdatedDate] = GETUTCDATE()									
								  WHERE [StockLineId] = @StockLineId;

								  EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@WOModuleId,@ReferenceId,NULL,NULL,@ActionId,1,@UpdatedBy;
							END						
							SET @LoopID = @LoopID + 1;
						END
					
					    SELECT 0 AS ReferenceId
					END
				END
				ELSE 
				BEGIN
					SELECT @ReferenceId AS ReferenceId
				END
			END
			ELSE 
			BEGIN
				SELECT @ReferenceId AS ReferenceId
			END				
		END
		ELSE 
		BEGIN	
			SELECT @ReferenceId AS ReferenceId
		END			
	END
	
	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'CheckStocklineForDelete' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100)) 
	  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  exec spLogException 
			   @DatabaseName           = @DatabaseName
			 , @AdhocComments          = @AdhocComments
			 , @ProcedureParameters    = @ProcedureParameters
			 , @ApplicationName        =  @ApplicationName
			 , @ErrorLogID             = @ErrorLogID OUTPUT ;
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
	  RETURN(1);
	END CATCH
END