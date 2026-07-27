-- ===== PROCEDURE: [dbo].[USP_WorkOrder_GetWorkOrderandCostAnalysisDetails]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs3/USP_WorkOrder_GetWorkOrderandCostAnalysisDetails.sql) =====
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
	6    12/31/2024   Hemant Saliya		Update for Modify Work Order cost analysis Summary
	7    01/27/2025   Hemant Saliya		Update OH Cost analysis Summary
	8    04/22/2025   Hemant Saliya		Repair Cost at Part wise from Srockline
	9    04/25/2025   Hemant Saliya		Handle OutSide Service Cost Calculation
	10   02/05/2026   Hemant Saliya		Handle -ve Adjustment cost issue
	11   09/July/2026   RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	12   23/July/2026   RAJESH GAMI		[PN-17350] - Removed leftover IsNonStock=0 exclusion filters.

EXEC [dbo].[USP_WorkOrder_GetWorkOrderandCostAnalysisDetails_Hem] 3679 ,4165    
EXEC [dbo].[USP_WorkOrder_GetWorkOrderandCostAnalysisDetails] 3679 ,4165  
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
				@SubDirectLaborCost DECIMAL(18,2) = 0.0,@TotalWorkHours DECIMAL(18,2) = 0.0,@OverheadCost DECIMAL(18,2) = 0.0,@SubOverheadCost DECIMAL(18,2) = 0.0,@OutSideServiceMaterialsCost DECIMAL(18,2),
				@OutSideServiceKitCost DECIMAL(18,2),@FreightCost DECIMAL(18,2),@ChargesCost DECIMAL(18,2),@IsSubWO BIT = 0,@OutSideServiceCost DECIMAL(18,2),@SubOutSideServiceCost DECIMAL(18,2),
				@ReserveOutSideServiceMaterialsCost DECIMAL(18,2),@IssueOutSideServiceMaterialsCost DECIMAL(18,2),@ReserveOutSideServiceKitCost DECIMAL(18,2),@IssueOutSideServiceKitCost DECIMAL(18,2),
				@ReserveOutSideServiceCost DECIMAL(18,2) = 0.00,@IssueOutSideServiceCost DECIMAL(18,2) = 0.00;
		DECLARE @exchangeProvisionId int = (SELECT TOP 1 ProvisionId FROM Provision Where Description = 'EXCHANGE')

		DECLARE @POStatusIds VARCHAR(100);
		DECLARE @ROStatusIds VARCHAR(100);

		SELECT @POStatusIds = STRING_AGG(POStatusId, ',')  FROM [DBO].[POStatus]  WITH(NOLOCK) WHERE Status IN ('CLOSING','CLOSED','CANCELED');  
		SELECT @ROStatusIds = STRING_AGG(ROStatusId, ',')  FROM [DBO].[ROStatus]  WITH(NOLOCK) WHERE Status IN ('CLOSED','CANCELED');  

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
				CASE WHEN ISNULL(WOMS.RepairOrderId, 0) > 0 THEN ISNULL(WOMS.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(WOMS.UnitCost, 0) END AS UnitCost,
				ISNULL(WOMS.ExtendedCost, 0),
				ISNULL(WOMS.QtyIssued, 0),
				ISNULL(WOMS.QtyReserved,0),
				CASE WHEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
					 THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) 
					 ELSE ISNULL(POPartReferece.Qty, 0) END,
				CASE WHEN ISNULL(WOM.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(WOM.UnitCost, 0) END,
				WOM.POId,
				--WOM.QtyToTurnIn
				CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN WOM.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
		FROM [DBO].[WorkOrderMaterials] WOM WITH(NOLOCK) 
			LEFT JOIN [DBO].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
			LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON WOMS.StockLineId = ROP.StockLineId AND ROP.RepairOrderId = WOMS.RepairOrderId
			LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = WOM.POId AND POP.ItemMasterId = WOM.ItemMasterId AND (POP.ConditionId = WOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOM.ProvisionId = @exchangeProvisionId))
			LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
			LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = WOM.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOM.IsDeleted = 0

		--Select * from #tmpWorkOrderMaterials

		INSERT INTO #tmpWorkOrderMaterialsKit (WorkFlowWorkOrderId, WorkOrderMaterialsId,StocklineId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
			SELECT DISTINCT @WorkOrderWorkflowId,
			WOMSK.WorkOrderMaterialsKitId,
			WOMSK.StocklineId,
			--WOMSK.UnitCost,
			CASE WHEN ISNULL(WOMSK.RepairOrderId, 0) > 0 THEN ISNULL(WOMSK.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE WOMSK.UnitCost END AS UnitCost,
			ISNULL(WOMSK.ExtendedCost, 0),
			ISNULL(WOMSK.QtyIssued, 0),
			ISNULL(WOMSK.QtyReserved, 0),
			CASE WHEN (ISNULL(WOMK.Quantity, 0) - (ISNULL(WOMK.QuantityReserved, 0) + ISNULL(WOMK.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
				THEN (ISNULL(WOMK.Quantity, 0) - (ISNULL(WOMK.QuantityReserved, 0) + ISNULL(WOMK.QuantityIssued, 0))) 
				ELSE ISNULL(POPartReferece.Qty, 0) END,
			CASE WHEN ISNULL(WOMK.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(WOMK.UnitCost, 0) END,
			WOMK.POId,
			--WOMK.QtyToTurnIn
			CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN ISNULL(WOMK.QtyToTurnIn,0) ELSE 0 END AS QtyToTurnIn
		FROM [DBO].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK)
			LEFT JOIN [DBO].[WorkOrderMaterialStockLineKit] WOMSK ON WOMK.WorkOrderMaterialsKitId = WOMSK.WorkOrderMaterialsKitId
			LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON WOMSK.StockLineId = ROP.StockLineId AND ROP.RepairOrderId = WOMSK.RepairOrderId
			LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON WOMSK.StockLineId = SL.StockLineId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = WOMK.POId AND POP.ItemMasterId = WOMK.ItemMasterId AND POP.ConditionId = WOMK.ConditionCodeId
			LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
			LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = WOMK.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
		WHERE WOMK.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOMK.IsDeleted = 0;

		--Handle for remove Duplicate Back Order Qty
		WITH CTE AS (
			SELECT 
				id,
				WorkOrderMaterialsId,
				ROW_NUMBER() OVER (PARTITION BY WorkOrderMaterialsId, WorkFlowWorkOrderId ORDER BY id) AS row_num
				FROM #tmpWorkOrderMaterials WHERE ISNULL(POId, 0) > 0
		)
		UPDATE #tmpWorkOrderMaterials
		SET QtyOnBkOrder = 0
		WHERE id IN (SELECT id FROM CTE	WHERE row_num > 1 AND CTE.WorkOrderMaterialsId = #tmpWorkOrderMaterials.WorkOrderMaterialsId);

		WITH CTE AS (
			SELECT 
				id,
				WorkOrderMaterialsId,
				ROW_NUMBER() OVER (PARTITION BY WorkOrderMaterialsId, WorkFlowWorkOrderId ORDER BY id) AS row_num
				FROM #tmpWorkOrderMaterialsKit WHERE ISNULL(POId, 0) > 0
		)
		UPDATE #tmpWorkOrderMaterialsKit
		SET QtyOnBkOrder = 0
		WHERE id IN (SELECT id FROM CTE	WHERE row_num > 1 AND CTE.WorkOrderMaterialsId = #tmpWorkOrderMaterialsKit.WorkOrderMaterialsId);

		--Select * from #tmpWorkOrderMaterials

		--Get from WOMaterial table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpWorkOrderMaterials;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT	@QtyIssued = ISNULL(QtyIssued, 0) , 
					@QtyToTurnIn = ISNULL(QtyToTurnIn, 0) , 
					@UnitCost = ISNULL(UnitCost, 0), 
					@bkUnitCost = ISNULL(MUnitCost, 0),
					@poid = POId,
					@QtyOnBkOrder = ISNULL(QtyOnBkOrder, 0), 
					@QtyReserved = ISNULL(QtyReserved, 0)
			FROM #tmpWorkOrderMaterials tmpWOM WHERE tmpWOM.ID = @count; 
			
			IF(ISNULL(@QtyReserved, 0) > 0)
			BEGIN
				SET @ReservedCost = ISNULL(@ReservedCost, 0) + (ISNULL(@QtyReserved, 0) * ISNULL(@UnitCost, 0));
			END

			IF(ISNULL(@QtyOnBkOrder, 0) > 0)
			BEGIN
				SET @BkOrderCost = ISNULL(@BkOrderCost, 0) + (ISNULL(@QtyOnBkOrder, 0) * ISNULL(@bkUnitCost, 0));
			END
			
			IF(ISNULL(@QtyIssued, 0) > 0)
			BEGIN
				SET @partsCost = ISNULL(@partsCost, 0) + ISNULL((@QtyIssued * @UnitCost), 0);
			END

			IF(@QtyToTurnIn > 0)
			BEGIN
				SET @QtyToTurnCost = ISNULL(@QtyToTurnCost, 0) + ISNULL((@QtyToTurnIn * @UnitCost), 0);
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
				   @QtyOnBkOrder = CASE WHEN (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) > ISNULL(QtyOnBkOrder, 0) THEN 0 ELSE ISNULL(QtyOnBkOrder, 0) - (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) END, 
				   @QtyReserved = QtyReserved
			FROM #tmpWorkOrderMaterialsKit tmpWOM WHERE tmpWOM.ID = @count; 
			
			IF(@QtyReserved > 0)
			BEGIN
				SET @ReservedCost = ISNULL(@ReservedCost, 0) + ISNULL((@QtyReserved * @UnitCost),0);
			END

			IF(@QtyOnBkOrder > 0)
			BEGIN
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
		SELECT @OutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))) , 
			   @ReserveOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
			   @IssueOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
		FROM [DBO].[Stockline] SL WITH(NOLOCK)
			JOIN [DBO].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId AND SL.RepairOrderId = WOMS.RepairOrderId
			JOIN [DBO].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId			
		WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId  = @WorkOrderWorkflowId;

		SELECT @OutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))), 
			   @ReserveOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
			   @IssueOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
		FROM [DBO].[Stockline] SL WITH(NOLOCK)
			JOIN [DBO].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId AND SL.RepairOrderId = WOMS.RepairOrderId
			JOIN [DBO].[WorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId			
		WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId  = @WorkOrderWorkflowId;

		SET @OutSideServiceCost = ISNULL(@OutSideServiceMaterialsCost, 0) + ISNULL(@OutSideServiceKitCost, 0);
		SET @ReserveOutSideServiceCost = ISNULL(@ReserveOutSideServiceMaterialsCost, 0) + ISNULL(@ReserveOutSideServiceKitCost, 0);
		SET @IssueOutSideServiceCost = ISNULL(@IssueOutSideServiceMaterialsCost, 0) + ISNULL(@IssueOutSideServiceKitCost, 0);

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

			--SET @tmpBurdonLaborCost = ISNULL(@tmpBurdonLaborCost, 0) + ISNULL((@tmpBurdenRateAmount * PARSENAME(@tmpAdjustedHours,2)), 0);
			--SET @tmpDirectLaborCost = ISNULL(@tmpDirectLaborCost, 0) + ISNULL((@tmpDirectLaborOHCost * PARSENAME(@tmpAdjustedHours,2)), 0);

			SET @tmpBurdonLaborCost = ISNULL(@tmpBurdonLaborCost, 0) +
			@tmpBurdenRateAmount *
			(
				(
					CASE WHEN @tmpAdjustedHours < 0 THEN -1 ELSE 1 END *
					(
						FLOOR(ABS(@tmpAdjustedHours)) * 60
						+ CONVERT(int, ROUND((ABS(@tmpAdjustedHours) - FLOOR(ABS(@tmpAdjustedHours))) * 100.0, 0))
					)
				) / 60.0
			)

			SET @tmpDirectLaborCost = ISNULL(@tmpDirectLaborCost, 0) +
			@tmpDirectLaborOHCost *
			(
				(
					CASE WHEN @tmpAdjustedHours < 0 THEN -1 ELSE 1 END *
					(
						FLOOR(ABS(@tmpAdjustedHours)) * 60
						+ CONVERT(int, ROUND((ABS(@tmpAdjustedHours) - FLOOR(ABS(@tmpAdjustedHours))) * 100.0, 0))
					)
				) / 60.0
			)

			--SET @tmpAdjustedHoursdata1 = CAST((CAST(@tmpAdjustedHoursdata AS DECIMAL(18,2))/ 100 )AS DECIMAL(18,2));

			--IF(@tmpAdjustedHoursdata > 0)
			--BEGIN
			--	SET @tmpBurdonLaborCost = ISNULL(@tmpBurdonLaborCost, 0) + ((@tmpAdjustedHoursdata1 * 100 /60) * @tmpBurdenRateAmount);
			--	SET @tmpDirectLaborCost = ISNULL(@tmpDirectLaborCost, 0) + ((@tmpAdjustedHoursdata1 * 100 /60) * @tmpDirectLaborOHCost);
			--END

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
		SET @RowMaterialTotalCost = (ISNULL(@ReservedCost, 0) + ISNULL(@partsCost, 0) + ISNULL(@QtyToTurnCost, 0) + ISNULL(@BkOrderCost, 0));

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
			MUnitCost DECIMAL(18,2) NULL,
			POId BIGINT NULL,
			QtyToTurnIn INT NULL,
		);

		INSERT INTO #tmpSubWorkOrderMaterials (SubWorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder,MUnitCost,POId, QtyToTurnIn) 
			SELECT SWOMS.SubWorkOrderMaterialsId,
				SWOMS.UnitCost,
				SWOMS.ExtendedCost,
				SWOMS.QtyIssued,
				SWOMS.QtyReserved,
				CASE WHEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
					 THEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) 
					 ELSE ISNULL(POPartReferece.Qty, 0) END,
				CASE WHEN ISNULL(SWOM.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOM.UnitCost, 0) END,
				SWOM.POId,
				CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOM.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
				--SWOM.QtyOnBkOrder,
				--SWOM.QtyToTurnIn
		FROM [DBO].[SubWorkOrderMaterials] SWOM WITH(NOLOCK) 
			LEFT JOIN [DBO].[SubWorkOrderMaterialStockLine] SWOMS WITH(NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOM.POId AND POP.ItemMasterId = SWOM.ItemMasterId AND ISNULL(POP.IsSubWO, 0) = 1 AND (POP.ConditionId = SWOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = SWOM.SubWorkOrderMaterialsId AND SWOM.ProvisionId = @exchangeProvisionId))
			LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
			LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOM.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
		WHERE SWOM.WorkOrderId = @WorkOrderId AND SWOM.IsDeleted = 0;

		--Handle for remove Duplicate Back Order Qty
		WITH CTE AS (
			SELECT 
				id,
				SubWorkOrderMaterialsId,
				ROW_NUMBER() OVER (PARTITION BY SubWorkOrderMaterialsId ORDER BY id) AS row_num
				FROM #tmpSubWorkOrderMaterials WHERE ISNULL(POId, 0) > 0
		)
		UPDATE #tmpSubWorkOrderMaterials
		SET QtyOnBkOrder = 0
		WHERE id IN (SELECT id FROM CTE	WHERE row_num > 1 AND CTE.SubWorkOrderMaterialsId = #tmpSubWorkOrderMaterials.SubWorkOrderMaterialsId);

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
				SET @SubReservedCost = ISNULL(@SubReservedCost, 0) + (@SubQtyReserved * @SubUnitCost);
			END

			IF(@SubQtyOnBkOrder > 0)
			BEGIN
				SET @SubBkOrderCost = ISNULL(@SubBkOrderCost, 0) + (@SubQtyOnBkOrder * @SubUnitCost);
			END
			
			IF(@SubQtyIssued > 0)
			BEGIN
				SET @SubpartsCost = ISNULL(@SubpartsCost, 0) + (@SubQtyIssued * @SubUnitCost);
			END

			IF(@SubQtyToTurnIn > 0)
			BEGIN
				SET @SubQtyToTurnCost = ISNULL(@SubQtyToTurnCost, 0) + (@SubQtyToTurnIn * @SubUnitCost);
			END

			SET @SubQtyIssued = 0;
			SET @SubQtyToTurnIn = 0;
			SET @SubUnitCost = 0;
			SET @SubQtyOnBkOrder = 0;
			SET @SubQtyReserved = 0;

			SET @count = @count + 1;
		END

		--Total SubRowMaterial cost
		SET @SubRowMaterialTotalCost = (ISNULL(@SubReservedCost, 0) + ISNULL(@SubpartsCost, 0) + ISNULL(@SubQtyToTurnCost, 0) + ISNULL(@SubBkOrderCost, 0));

		--SubOutside Cost
		SELECT @SubOutSideServiceCost = SUM(ISNULL(ROP.ExtendedCost,0)) 
			FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
			JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId --AND RO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@ROStatusIds,',')) 
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


		-------Checking is WO has SubWO or not

	   IF EXISTS(SELECT 1 FROM [DBO].[SubWorkOrder] SWO WITH(NOLOCK) INNER JOIN [DBO].[WorkOrderWorkFlow] WF ON SWO.WorkOrderId = WF.WorkOrderId 
																				AND WF.WorkOrderPartNoId = SWO.WorkOrderPartNumberId
				WHERE SWO.WorkOrderId = @WorkOrderId AND WF.WorkFlowWorkOrderId = @WorkOrderWorkflowId)
	   BEGIN
			SET @IsSubWO = 1;
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
			@ReserveOutSideServiceCost AS 'ReserveOutsideCost',
			@IssueOutSideServiceCost AS 'IssueOutsideCost',
			ISNULL(@ReservedCost, 0) + ISNULL(@ReserveOutSideServiceCost, 0) AS 'ReserveTotalCost',
			ISNULL(@partsCost, 0) + ISNULL(@IssueOutSideServiceCost, 0) AS 'IssueTotalCost',
			@OverheadCost AS 'OverheadCost',
			@DirectLaborCost AS 'LaborCost',
			@FreightCost AS 'FreightCost',
			@ChargesCost AS 'ChargesCost',
			@SubReservedCost AS 'SubReservedCost',
			@SubpartsCost AS 'SubIssuedCost',
			@SubQtyToTurnCost AS 'SubTenderCost',
			@SubBkOrderCost AS 'SubBackorderCost',
			@SubRowMaterialTotalCost AS 'SubRowMaterialTotalCost',
			@SubOutSideServiceCost AS 'SubOutsideCost',
			@SubDirectLaborCost AS 'SubLaborCost',
			@SubOverheadCost AS 'SubOverheadCost',
			@IsSubWO As 'IsSubWO';
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