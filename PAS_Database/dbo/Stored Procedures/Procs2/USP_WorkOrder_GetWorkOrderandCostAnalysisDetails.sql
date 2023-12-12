
/*************************************************************           
 ** File:   [USP_WorkOrder_GetWorkOrderandCostAnalysisDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to Get WorkOrder/SubWorkOrder CostAnalysis Details.
 ** Purpose:         
 ** Date:   07/27/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/27/2023   Amit Ghediya		Created	
	2    07/31/2023   Amit Ghediya		Added SubWorkorder logic.	
	3    08/18/2023   Amit Ghediya		Update Calculation logic.
	4    08/18/2023   Hemnat Saliya		Corrected Balance issues
	5    10/19/2023   Vishal Suthar		Fixed Backorder qty calculation

EXEC [dbo].[USP_WorkOrder_GetWorkOrderandCostAnalysisDetails] 3123, 3652     
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_WorkOrder_GetWorkOrderandCostAnalysisDetails]
(
	@WorkOrderWorkflowId BIGINT,
	@WorkOrderId BIGINT
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @RowMaterialTotalCost DECIMAL(18,2) = 0.0, @SubRowMaterialTotalCost DECIMAL(18,2) = 0.0, @TotalCounts INT, @count INT, @partsCost DECIMAL(18,2) = 0.0,
				@SubpartsCost DECIMAL(18,2) = 0.0, @ReservedCost DECIMAL(18,2) = 0.0, @SubReservedCost DECIMAL(18,2) = 0.0, @BkOrderCost DECIMAL(18,2) = 0.0, @SubBkOrderCost DECIMAL(18,2) = 0.0,
				@QtyIssued INT,@SubQtyIssued INT,@QtyOnBkOrder INT,@SubQtyOnBkOrder INT,@QtyReserved INT,@SubQtyReserved INT ,@POQuantity BIGINT=0,@poid BIGINT,@UnitCost DECIMAL(18,2),
				@bkUnitCost DECIMAL(18,2),@SubUnitCost DECIMAL(18,2),@QtyToTurnIn INT,@SubQtyToTurnIn INT,@QtyToTurnCost DECIMAL(18,2) = 0.0,@SubQtyToTurnCost DECIMAL(18,2) = 0.0,
				@WorkOrderLaborHeaderId BIGINT,@SubWorkOrderLaborHeaderId BIGINT,@DirectLaborOHCost DECIMAL(18,2) = 0.0, @BurdenRateAmount DECIMAL(18,2) = 0.0,@DirectLaborCost DECIMAL(18,2) = 0.0,
				@SubDirectLaborCost DECIMAL(18,2) = 0.0,@TotalWorkHours DECIMAL(18,2) = 0.0,@OverheadCost DECIMAL(18,2) = 0.0,@SubOverheadCost DECIMAL(18,2) = 0.0,@OutSideServiceCost DECIMAL(18,2),
				@SubOutSideServiceCost DECIMAL(18,2),@FreightCost DECIMAL(18,2),@ChargesCost DECIMAL(18,2);
		DECLARE @exchangeProvisionId int = (SELECT TOP 1 ProvisionId FROM Provision Where Description = 'EXCHANGE')
		
		SET @count = 1;

		-- Temp for WOMaterial data
		IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterials') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWorkOrderMaterials
		END
					  	  
		CREATE TABLE #tmpWorkOrderMaterials
		(
			ID BIGINT NOT NULL IDENTITY, 
			WorkOrderMaterialsId BIGINT NULL,
			WorkFlowWorkOrderId BIGINT NULL,
			StocklineId BIGINT NULL,
			UnitCost DECIMAL(18,2) NULL,
			ExtendedCost DECIMAL(18,2) NULL,
			QtyIssued INT NULL,
			QtyReserved INT NULL,
			QtyOnBkOrder INT NULL,
			MUnitCost DECIMAL(18,2) NULL,
			POId BIGINT NULL,
			QtyToTurnIn INT NULL,
		) 

		-- Temp for WOMaterialKit data
		IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialsKit') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWorkOrderMaterialsKit
		END
					  	  
		CREATE TABLE #tmpWorkOrderMaterialsKit
		(
			ID BIGINT NOT NULL IDENTITY, 
			WorkOrderMaterialsId BIGINT NULL,
			WorkFlowWorkOrderId BIGINT NULL,
			StocklineId BIGINT NULL,
			UnitCost DECIMAL(18,2) NULL,
			ExtendedCost DECIMAL(18,2) NULL,
			QtyIssued INT NULL,
			QtyReserved INT NULL,
			QtyOnBkOrder INT NULL,
			MUnitCost DECIMAL(18,2) NULL,
			POId BIGINT NULL,
			QtyToTurnIn INT NULL,
		)

		INSERT INTO #tmpWorkOrderMaterials (WorkFlowWorkOrderId, WorkOrderMaterialsId,StocklineId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
		SELECT  DISTINCT @WorkOrderWorkflowId, 
				WOMS.WorkOrderMaterialsId,
				WOMS.StocklineId,
				WOMS.UnitCost,
				WOMS.ExtendedCost,
				WOMS.QtyIssued,
				WOMS.QtyReserved,
				--ISNULL(POP.QuantityBackOrdered, 0),
				CASE WHEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
					 THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) 
					 ELSE ISNULL(POPartReferece.Qty, 0) END,
				CASE WHEN ISNULL(WOM.UnitCost,0) = 0 THEN POP.UnitCost ELSE WOM.UnitCost END,
				WOM.POId,
				WOM.QtyToTurnIn
		FROM [DBO].[WorkOrderMaterials] WOM WITH(NOLOCK) 
			LEFT JOIN [DBO].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = WOM.POId AND POP.ItemMasterId = WOM.ItemMasterId AND (POP.ConditionId = WOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOM.ProvisionId = @exchangeProvisionId))
			LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = WOM.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOM.IsDeleted = 0

		INSERT INTO #tmpWorkOrderMaterialsKit (WorkFlowWorkOrderId, WorkOrderMaterialsId,StocklineId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
			SELECT DISTINCT @WorkOrderWorkflowId,
			WOMSK.WorkOrderMaterialsKitId,
			WOMSK.StocklineId,
			WOMSK.UnitCost,
			WOMSK.ExtendedCost,
			WOMSK.QtyIssued,
			WOMSK.QtyReserved,
			--WOMK.QtyOnBkOrder,
			--ISNULL(POP.QuantityBackOrdered, 0),
			CASE WHEN (ISNULL(WOMK.Quantity, 0) - (ISNULL(WOMK.QuantityReserved, 0) + ISNULL(WOMK.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
				THEN (ISNULL(WOMK.Quantity, 0) - (ISNULL(WOMK.QuantityReserved, 0) + ISNULL(WOMK.QuantityIssued, 0))) 
				ELSE ISNULL(POPartReferece.Qty, 0) END,
			CASE WHEN ISNULL(WOMK.UnitCost,0) = 0 THEN POP.UnitCost ELSE WOMK.UnitCost END,
			WOMK.POId,
			WOMK.QtyToTurnIn
		FROM [DBO].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK)
			LEFT JOIN [DBO].[WorkOrderMaterialStockLineKit] WOMSK ON WOMK.WorkOrderMaterialsKitId = WOMSK.WorkOrderMaterialsKitId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = WOMK.POId AND POP.ItemMasterId = WOMK.ItemMasterId AND POP.ConditionId = WOMK.ConditionCodeId
			LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = WOMK.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
		WHERE WOMK.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOMK.IsDeleted = 0;

		--Get from WOMaterial table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpWorkOrderMaterials;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT	@QtyIssued = ISNULL(QtyIssued, 0) , 
					@QtyToTurnIn = ISNULL(QtyToTurnIn, 0) , 
					@UnitCost = ISNULL(UnitCost, 0), 
					@bkUnitCost = ISNULL(MUnitCost, 0),
					@poid = POId,
					--@QtyOnBkOrder = CASE WHEN (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) > ISNULL(QtyOnBkOrder, 0) THEN 0 ELSE ISNULL(QtyOnBkOrder, 0) - (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) END, 
					@QtyOnBkOrder = ISNULL(QtyOnBkOrder, 0), 
					@QtyReserved = ISNULL(QtyReserved, 0)
			FROM #tmpWorkOrderMaterials tmpWOM WHERE tmpWOM.ID = @count; 
			
			--SELECT @POQuantity = ISNULL(SUM(Quantity),0) FROM [DBO].[StocklineDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @poid and StockLineId IS NOT NULL;
			--SELECT @POQuantity = ISNULL(SUM(QuantityBackOrdered),0) FROM [DBO].[PurchaseOrderPart] WITH(NOLOCK) WHERE PurchaseOrderId = @poid --and StockLineId IS NOT NULL;
			
			IF(ISNULL(@QtyReserved, 0) > 0)
			BEGIN
				SET @ReservedCost = ISNULL(@ReservedCost, 0) + (ISNULL(@QtyReserved, 0) * ISNULL(@UnitCost, 0));
			END

			IF(ISNULL(@QtyOnBkOrder, 0) > 0)
			BEGIN
				--IF(@POQuantity > 0)
				--BEGIN
				--	SET @QtyOnBkOrder = ISNULL(@QtyOnBkOrder, 0) - ISNULL(@POQuantity, 0);
				--END
				SET @BkOrderCost = ISNULL(@BkOrderCost, 0) + (ISNULL(@QtyOnBkOrder, 0) * ISNULL(@bkUnitCost, 0));
			END
			
			IF(ISNULL(@QtyIssued, 0) > 0)
			BEGIN
				SET @partsCost = @partsCost + (@QtyIssued * @UnitCost);
			END

			IF(@QtyToTurnIn > 0)
			BEGIN
				SET @QtyToTurnCost = @QtyToTurnCost + (@QtyToTurnIn * @UnitCost);
			END

			SET @QtyIssued = 0;
			SET @QtyToTurnIn = 0;
			SET @UnitCost = 0;
			SET @bkUnitCost = 0;
			SET @poid = 0;
			SET @POQuantity = 0;
			SET @count = @count + 1;
		END

		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		--Get from WOMaterialKit table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpWorkOrderMaterialsKit;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @QtyIssued = QtyIssued , @QtyToTurnIn = QtyToTurnIn , @UnitCost = UnitCost, @bkUnitCost = MUnitCost,@poid = POId,
				   --@QtyOnBkOrder = QtyOnBkOrder, 
				   @QtyOnBkOrder = CASE WHEN (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) > ISNULL(QtyOnBkOrder, 0) THEN 0 ELSE ISNULL(QtyOnBkOrder, 0) - (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) END, 
				   @QtyReserved = QtyReserved
			FROM #tmpWorkOrderMaterialsKit tmpWOM WHERE tmpWOM.ID = @count; 
			
			--SELECT @POQuantity = ISNULL(SUM(Quantity),0) FROM [DBO].[StocklineDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @poid and StockLineId IS NOT NULL;
			
			IF(@QtyReserved > 0)
			BEGIN
				SET @ReservedCost = @ReservedCost + (@QtyReserved * @UnitCost);
			END

			IF(@QtyOnBkOrder > 0)
			BEGIN
				--IF(@POQuantity > 0)
				--BEGIN
				--	SET @QtyOnBkOrder = @QtyOnBkOrder - @POQuantity;
				--END
				SET @BkOrderCost = ISNULL(@BkOrderCost, 0) + (ISNULL(@QtyOnBkOrder, 0) * ISNULL(@bkUnitCost, 0));
			END

			IF(@QtyIssued > 0)
			BEGIN
				SET @partsCost = ISNULL(@partsCost, 0) + (ISNULL(@QtyIssued, 0) * ISNULL(@UnitCost, 0));
			END

			IF(@QtyToTurnIn > 0)
			BEGIN
				SET @QtyToTurnCost = ISNULL(@QtyToTurnCost, 0) + (ISNULL(@QtyToTurnIn, 0) * ISNULL(@UnitCost, 0));
			END

			SET @QtyIssued = 0;
			SET @QtyToTurnIn = 0;
			SET @UnitCost = 0;
			SET @bkUnitCost = 0;
			SET @poid = 0;
			SET @POQuantity = 0;
			SET @count = @count + 1;
		END

		--Outside Cost
		SELECT @OutSideServiceCost = SUM(ISNULL(ROP.ExtendedCost,0)) 
			FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
		WHERE ROP.WorkOrderId = @WorkOrderId;

		--Labor Cost
		SELECT @WorkOrderLaborHeaderId = WOLH.WorkOrderLaborHeaderId , @TotalWorkHours = TotalWorkHours
			FROM [DBO].[WorkOrderLaborHeader] WOLH WITH(NOLOCK) 
		WHERE WOLH.WorkFlowWorkOrderId = @WorkOrderWorkflowId;

		-- Temp for WorkOrderLabor data
		IF OBJECT_ID(N'tempdb..#tmpWorkOrderLabor') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWorkOrderLabor
		END
					  	  
		CREATE TABLE #tmpWorkOrderLabor
		(
			ID BIGINT NOT NULL IDENTITY, 
			DirectLaborOHCost DECIMAL(18,2) NULL,
			BurdenRateAmount DECIMAL(18,2) NULL,
			AdjustedHours DECIMAL(18,2) NULL,
		);
		INSERT INTO #tmpWorkOrderLabor (DirectLaborOHCost,BurdenRateAmount,AdjustedHours) 
			SELECT WOL.DirectLaborOHCost,
				   WOL.BurdenRateAmount,
				   WOL.AdjustedHours
		FROM [DBO].[WorkOrderLabor] WOL WITH(NOLOCK)
		WHERE WOL.WorkOrderLaborHeaderId = @WorkOrderLaborHeaderId;

		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		DECLARE @tmpBurdenRateAmount DECIMAL(18,2)= 0.0,
				@tmpDirectLaborOHCost DECIMAL(18,2)= 0.0,
				@tmpAdjustedHours DECIMAL(18,2)= 0.0,
				@tmpBurdonLaborCost DECIMAL(18,2) = 0.0,
				@tmpDirectLaborCost DECIMAL(18,2) = 0.0,
				@tmpAdjustedHoursdata BIGINT,
				@minutesdata BIGINT,
				@tmpAdjustedHoursdata1 DECIMAL(18,2) = 0.0;

		--Get from WOMaterialKit table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpWorkOrderLabor;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @tmpBurdenRateAmount = tmpWOL.BurdenRateAmount,
				   @tmpDirectLaborOHCost = tmpWOL.DirectLaborOHCost,@tmpAdjustedHours = tmpWOL.AdjustedHours,
				   @tmpAdjustedHoursdata = PARSENAME(tmpWOL.AdjustedHours,1)
			FROM #tmpWorkOrderLabor tmpWOL WHERE tmpWOL.ID = @count; 

			SET @tmpBurdonLaborCost = @tmpBurdonLaborCost + (@tmpBurdenRateAmount * PARSENAME(@tmpAdjustedHours,2));
			SET @tmpDirectLaborCost = @tmpDirectLaborCost + (@tmpDirectLaborOHCost * PARSENAME(@tmpAdjustedHours,2));

			SET @tmpAdjustedHoursdata1 = cast((cast(@tmpAdjustedHoursdata as decimal(18,2))/ 100 )as decimal(18,2));

			IF(@tmpAdjustedHoursdata > 0)
			BEGIN
				SET @tmpBurdonLaborCost = @tmpBurdonLaborCost + ((@tmpAdjustedHoursdata1 * 100 /60) * @tmpBurdenRateAmount);
				SET @tmpDirectLaborCost = @tmpDirectLaborCost + ((@tmpAdjustedHoursdata1 * 100 /60) * @tmpDirectLaborOHCost);
			END

			SET @tmpBurdenRateAmount =0.0;
			SET @tmpDirectLaborOHCost =0.0;
			SET @tmpAdjustedHours =0.0;
			SET @tmpAdjustedHoursdata = 0;
			SET @tmpAdjustedHoursdata1 = 0.0;
			SET @count = @count + 1;
		END

		--Adjust with hours
		SET @OverheadCost = @tmpBurdonLaborCost;--(@TotalWorkHours * @OverheadCost);
		SET @DirectLaborCost = @tmpDirectLaborCost;--(@TotalWorkHours * @DirectLaborCost);

		--Freight Cost
		SELECT @FreightCost = SUM(ISNULL(WOC.Amount,0)) 
			FROM [DBO].[WorkOrderFreight] WOC WITH(NOLOCK) 
		WHERE WOC.WorkFlowWorkOrderId = @WorkOrderWorkflowId;

		--Charges Cost
		SELECT @ChargesCost = SUM(ISNULL(WOC.ExtendedCost,0)) 
			FROM [DBO].[WorkOrderCharges] WOC WITH(NOLOCK) 
		WHERE WOC.WorkFlowWorkOrderId = @WorkOrderWorkflowId;

		--Total RowMaterial cost
		SET @RowMaterialTotalCost = (@ReservedCost + @partsCost + @QtyToTurnCost + @BkOrderCost);

	-------------------------------------------------------------------------------------------------------------------------
		--Sub-WorkOrder Start

		-- Temp for SubWOMaterial data
		IF OBJECT_ID(N'tempdb..#tmpSubWorkOrderMaterials') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSubWorkOrderMaterials
		END
					  	  
		CREATE TABLE #tmpSubWorkOrderMaterials
		(
			ID BIGINT NOT NULL IDENTITY, 
			SubWorkOrderMaterialsId BIGINT NULL,
			UnitCost DECIMAL(18,2) NULL,
			ExtendedCost DECIMAL(18,2) NULL,
			QtyIssued INT NULL,
			QtyReserved INT NULL,
			QtyOnBkOrder INT NULL,
			QtyToTurnIn INT NULL,
		);

		INSERT INTO #tmpSubWorkOrderMaterials (SubWorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, QtyToTurnIn) 
			SELECT SWOMS.SubWorkOrderMaterialsId,
				SWOMS.UnitCost,
				SWOMS.ExtendedCost,
				SWOMS.QtyIssued,
				SWOMS.QtyReserved,
				SWOM.QtyOnBkOrder,
				SWOM.QtyToTurnIn
		FROM [DBO].[SubWorkOrderMaterials] SWOM WITH(NOLOCK) 
		LEFT JOIN [DBO].[SubWorkOrderMaterialStockLine] SWOMS WITH(NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId
		WHERE SWOM.WorkOrderId = @WorkOrderId AND SWOM.IsDeleted = 0;

		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		--Get from SubWOMaterial table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpSubWorkOrderMaterials;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @SubQtyIssued = QtyIssued , @SubQtyToTurnIn = QtyToTurnIn , @SubUnitCost = UnitCost ,
				   @SubQtyOnBkOrder = QtyOnBkOrder, @SubQtyReserved = QtyReserved
			FROM #tmpSubWorkOrderMaterials tmpSubWOM WHERE tmpSubWOM.ID = @count; 

			IF(@SubQtyReserved > 0)
			BEGIN
				SET @SubReservedCost = @SubReservedCost + (@SubQtyReserved * @SubUnitCost);
			END

			IF(@SubQtyOnBkOrder > 0)
			BEGIN
				SET @SubBkOrderCost = @SubBkOrderCost + (@SubQtyOnBkOrder * @SubUnitCost);
			END
			
			IF(@SubQtyIssued > 0)
			BEGIN
				SET @SubpartsCost = @SubpartsCost + (@SubQtyIssued * @SubUnitCost);
			END

			IF(@SubQtyToTurnIn > 0)
			BEGIN
				SET @SubQtyToTurnCost = @SubQtyToTurnCost + (@SubQtyToTurnIn * @SubUnitCost);
			END

			SET @SubQtyIssued = 0;
			SET @SubQtyToTurnIn = 0;
			SET @SubUnitCost = 0;
			SET @SubQtyOnBkOrder = 0;
			SET @SubQtyReserved = 0;

			SET @count = @count + 1;
		END

		--Total SubRowMaterial cost
		SET @SubRowMaterialTotalCost = (@SubReservedCost + @SubpartsCost + @SubQtyToTurnCost + @SubBkOrderCost);

		--SubOutside Cost
		SELECT @SubOutSideServiceCost = SUM(ISNULL(ROP.ExtendedCost,0)) 
			FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
		WHERE ROP.WorkOrderId = @WorkOrderId;

		--Sub Labor Cost
		DECLARE @subWorkOrderId BIGINT;

		-- Temp for SubWOMaterial data
		IF OBJECT_ID(N'tempdb..#tmpSubWorkOrder') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSubWorkOrder
		END
					  	  
		CREATE TABLE #tmpSubWorkOrder
		(
			ID BIGINT NOT NULL IDENTITY, 
			SubWorkOrderId BIGINT NULL
		);

		INSERT INTO #tmpSubWorkOrder (SubWorkOrderId) 
			SELECT SWOLH.SubWorkOrderId
		FROM SubWorkOrder SWOLH WITH(NOLOCK) where WorkOrderId = @WorkOrderId;

		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		--Get from SubWOMaterial table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpSubWorkOrder;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @subWorkOrderId = SubWorkOrderId
			FROM #tmpSubWorkOrder tmpSubWOM WHERE tmpSubWOM.ID = @count; 

			SELECT @SubWorkOrderLaborHeaderId = SWOLH.SubWorkOrderLaborHeaderId 
				FROM [DBO].[SubWorkOrderLaborHeader] SWOLH WITH(NOLOCK) 
			WHERE SWOLH.SubWorkOrderId = @subWorkOrderId;

			SELECT 
				@SubOverheadCost = SUM(ISNULL(SWOL.DirectLaborOHCost,0)),
				@SubDirectLaborCost = SUM(ISNULL(SWOL.BurdenRateAmount,0))
			FROM [DBO].[SubWorkOrderLabor] SWOL WITH(NOLOCK)
			WHERE SWOL.SubWorkOrderLaborHeaderId = @SubWorkOrderLaborHeaderId;

			SET @subWorkOrderId = 0;
			SET @SubWorkOrderLaborHeaderId = 0;

			SET @count = @count + 1;
		END
		
	-------------------------------------------------------------------------------------------------------------------------------
		SET @SubReservedCost = 0.0;
		SET @SubpartsCost = 0.0;
		SET @SubQtyToTurnCost = 0.0;
		SET @SubBkOrderCost = 0.0;
		SET @SubRowMaterialTotalCost = 0.0;
		SET @SubOutSideServiceCost = 0.0;
		SET @SubDirectLaborCost = 0.0;
		SET @SubOverheadCost = 0.0;

		SELECT @ReservedCost AS 'ReservedCost',
			@partsCost AS 'IssuedCost',
			@QtyToTurnCost AS 'TenderCost',
			@BkOrderCost AS 'BackorderCost',
			@RowMaterialTotalCost AS 'RowMaterialTotalCost',
			@OutSideServiceCost AS 'OutsideCost',
			@OverheadCost AS 'LaborCost',
			@DirectLaborCost AS 'OverheadCost',
			@FreightCost AS 'FreightCost',
			@ChargesCost AS 'ChargesCost',
			@SubReservedCost AS 'SubReservedCost',
			@SubpartsCost AS 'SubIssuedCost',
			@SubQtyToTurnCost AS 'SubTenderCost',
			@SubBkOrderCost AS 'SubBackorderCost',
			@SubRowMaterialTotalCost AS 'SubRowMaterialTotalCost',
			@SubOutSideServiceCost AS 'SubOutsideCost',
			@SubDirectLaborCost AS 'SubLaborCost',
			@SubOverheadCost AS 'SubOverheadCost';
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_WorkOrder_GetWorkOrderandCostAnalysisDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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