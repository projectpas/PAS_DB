/*************************************************************           
 ** File:   [USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to Get SubWorkOrder CostAnalysis Details.
 ** Purpose:         
 ** Date:   11/30/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    11/30/2023    Amit Ghediya		Created	
	2    12/18/2023    Amit Ghediya		Updated (Get Multiple Sub WO Data based on Main WO)
	3    12/19/2023    Amit Ghediya		Updated (SubWOPartNoId added as param)	
	4    12/22/2023    Amit Ghediya		Updated (get data from SWOkit also)	
	5    12/27/2024   Hemnat Saliya		Update for Modify Work Order cost analysis Summary
	6    01/27/2025   Hemant Saliya		Update OH Cost analysis Summary
	7    04/28/2025   Hemant Saliya		Handle OutSide Service Cost Calculation
	8    30/Mar/2026  Rajesh Gami		UOM Changes [PN-15741]
EXEC [dbo].[USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails] 4324, 641, false, 627     
exec USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails @WorkOrderWorkflowId=4324,@WorkOrderId=4776,@IsSubWOFromWo=1,@SubWOPartNoId=0
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails]
(
	@WorkOrderWorkflowId BIGINT,
	@WorkOrderId BIGINT,
	@IsSubWOFromWo BIT = 0,
	@SubWOPartNoId BIGINT
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @RowMaterialTotalCost DECIMAL(18, 6) = 0.0,@MainSubWorkOrderId BIGINT, @SubRowMaterialTotalCost DECIMAL(18, 6) = 0.0, @SubWoTotalCounts INT,@SubWoCount INT, @TotalCounts INT, @count INT, @partsCost DECIMAL(18, 6) = 0.0,
				@SubpartsCost DECIMAL(18, 6) = 0.0, @ReservedCost DECIMAL(18, 6) = 0.0, @SubReservedCost DECIMAL(18, 6) = 0.0, @BkOrderCost DECIMAL(18, 6) = 0.0, @SubBkOrderCost DECIMAL(18, 6) = 0.0,
				@QtyIssued DECIMAL(18, 6),@SubQtyIssued DECIMAL(18, 6),@QtyOnBkOrder DECIMAL(18, 6),@SubQtyOnBkOrder DECIMAL(18, 6),@QtyReserved DECIMAL(18, 6),@SubQtyReserved DECIMAL(18, 6) ,@POQuantity DECIMAL(18, 6)=0,@poid BIGINT,@UnitCost DECIMAL(18, 6),
				@bkUnitCost DECIMAL(18, 6),@SubUnitCost DECIMAL(18, 6),@QtyToTurnIn DECIMAL(18, 6),@SubQtyToTurnIn DECIMAL(18, 6),@QtyToTurnCost DECIMAL(18, 6) = 0.0,@SubQtyToTurnCost DECIMAL(18, 6) = 0.0,
				@WorkOrderLaborHeaderIds BIGINT,@WorkOrderLaborHeaderId BIGINT,@SubWorkOrderLaborHeaderId BIGINT,@DirectLaborOHCost DECIMAL(18, 6) = 0.0, @BurdenRateAmount DECIMAL(18, 6) = 0.0,@DirectLaborCost DECIMAL(18, 6) = 0.0,
				@SubDirectLaborCost DECIMAL(18, 6) = 0.0,@TotalWorkHours DECIMAL(18, 6) = 0.0,@OverheadCost DECIMAL(18, 6) = 0.0,@SubOverheadCost DECIMAL(18, 6) = 0.0,@OutSideServiceCost DECIMAL(18, 6),
				@SubOutSideServiceCost DECIMAL(18, 6),@FreightCost DECIMAL(18, 6) = 0,@ChargesCost DECIMAL(18, 6)=0,@woNumber VARCHAR(256),@subItemMasterId BIGINT,@subItemMasterIds VARCHAR(MAX),@subPartNumber VARCHAR(MAX),@subPartNumberDesc VARCHAR(MAX),@IsSubWO BIT = 0,
				@ReserveOutSideServiceMaterialsCost DECIMAL(18, 6),@IssueOutSideServiceMaterialsCost DECIMAL(18, 6),@ReserveOutSideServiceKitCost DECIMAL(18, 6),@IssueOutSideServiceKitCost DECIMAL(18, 6),
				@ReserveOutSideServiceCost DECIMAL(18, 6) = 0.00,@IssueOutSideServiceCost DECIMAL(18, 6) = 0.00, @OutSideServiceMaterialsCost DECIMAL(18, 6),@OutSideServiceKitCost DECIMAL(18, 6);
				
		DECLARE @exchangeProvisionId int = (SELECT TOP 1 ProvisionId FROM Provision Where Description = 'EXCHANGE')

		DECLARE @POStatusIds VARCHAR(100);
		DECLARE @ROStatusIds VARCHAR(100);

		SELECT @POStatusIds = STRING_AGG(POStatusId, ',')  FROM [DBO].[POStatus]  WITH(NOLOCK) WHERE Status IN ('CLOSING','CLOSED','CANCELED');  
		SELECT @ROStatusIds = STRING_AGG(ROStatusId, ',')  FROM [DBO].[ROStatus]  WITH(NOLOCK) WHERE Status IN ('CLOSED','CANCELED');  
		
		SET @SubWoCount = 1;
		IF OBJECT_ID(N'tempdb..#tmpSubWorkOrder') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSubWorkOrder
		END

		CREATE TABLE #tmpSubWorkOrder
		(
			ID BIGINT NOT NULL IDENTITY, 
			SubWorkOrderId BIGINT NULL
		);

		IF(@IsSubWOFromWo = 1) -- Check is subWO for WO
		BEGIN 
			INSERT INTO #tmpSubWorkOrder (SubWorkOrderId)
				SELECT SubWorkOrderId FROM [DBO].[SubWorkOrder] SWO WITH(NOLOCK) INNER JOIN [DBO].[WorkOrderWorkFlow] WF ON SWO.WorkOrderId = WF.WorkOrderId 
																				AND WF.WorkOrderPartNoId = SWO.WorkOrderPartNumberId
				WHERE SWO.WorkOrderId = @WorkOrderId AND WF.WorkFlowWorkOrderId = @WorkOrderWorkflowId;

			SET @woNumber = (SELECT STRING_AGG([SubWorkOrderNo], ', ') FROM [DBO].[SubWorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId);
			SET @subItemMasterIds = (SELECT STRING_AGG([ItemMasterId], ', ') FROM [DBO].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId);
			SELECT @subPartNumber = STRING_AGG([partnumber], ', '), @subPartNumberDesc = STRING_AGG([PartDescription], ', ') FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] IN(SELECT Item FROM dbo.SplitString(@subItemMasterIds, ','));
		END
		ELSE
		BEGIN 
			SET @woNumber = (SELECT [SubWorkOrderNo] FROM [DBO].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId);
			IF(ISNULL(@SubWOPartNoId,0) = 0)
			BEGIN 
				SET @subItemMasterIds = (SELECT STRING_AGG([ItemMasterId], ', ') FROM [DBO].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId);
				SELECT @subPartNumber = STRING_AGG([partnumber], ', '), @subPartNumberDesc = STRING_AGG([PartDescription], ', ') FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] IN(SELECT Item FROM dbo.SplitString(@subItemMasterIds, ','));
			END
			ELSE
			BEGIN
				SET @subItemMasterId = (SELECT [ItemMasterId] FROM [DBO].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId);
				SELECT @subPartNumber = [partnumber], @subPartNumberDesc = [PartDescription] FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @subItemMasterId;
			END
			
		END
		
		--Sub-WorkOrder Start

		-- Temp for SubWOMaterial data
		SET @count = 1;
		IF OBJECT_ID(N'tempdb..#tmpSubWorkOrderMaterials') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSubWorkOrderMaterials
		END
					  	  
		CREATE TABLE #tmpSubWorkOrderMaterials
		(
			ID BIGINT NOT NULL IDENTITY, 
			SubWorkOrderMaterialsId BIGINT NULL,
			UnitCost DECIMAL(18, 6) NULL,
			ExtendedCost DECIMAL(18, 6) NULL,
			QtyIssued DECIMAL(18, 6) NULL,
			QtyReserved DECIMAL(18, 6) NULL,
			QtyOnBkOrder DECIMAL(18, 6) NULL,
			MUnitCost DECIMAL(18, 6) NULL,
			POId BIGINT NULL,
			QtyToTurnIn DECIMAL(18, 6) NULL,
		);

		-- Temp for SWOMaterialKit data
		IF OBJECT_ID(N'tempdb..#tmpSWorkOrderMaterialsKit') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSWorkOrderMaterialsKit
		END
					  	  
		CREATE TABLE #tmpSWorkOrderMaterialsKit
		(
			ID BIGINT NOT NULL IDENTITY, 
			WorkOrderMaterialsId BIGINT NULL,
			WorkFlowWorkOrderId BIGINT NULL,
			UnitCost DECIMAL(18, 6) NULL,
			ExtendedCost DECIMAL(18, 6) NULL,
			QtyIssued DECIMAL(18, 6) NULL,
			QtyReserved DECIMAL(18, 6) NULL,
			QtyOnBkOrder DECIMAL(18, 6) NULL,
			MUnitCost DECIMAL(18, 6) NULL,
			POId BIGINT NULL,
			QtyToTurnIn DECIMAL(18, 6) NULL,
		)

		-- Temp for WorkOrderLabor data
		IF OBJECT_ID(N'tempdb..#tmpWorkOrderLabor') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWorkOrderLabor
		END
					  	  
		CREATE TABLE #tmpWorkOrderLabor
		(
			ID BIGINT NOT NULL IDENTITY, 
			DirectLaborOHCost DECIMAL(18, 6) NULL,
			BurdenRateAmount DECIMAL(18, 6) NULL,
			AdjustedHours DECIMAL(18, 6) NULL,
		);

		IF(@IsSubWOFromWo = 1) -- Check is subWO for WO
		BEGIN 
			SELECT @SubWoTotalCounts = COUNT(ID) FROM #tmpSubWorkOrder; --Get All SubWo From Wo
			WHILE @SubWoCount <= @SubWoTotalCounts
			BEGIN
				SELECT	@MainSubWorkOrderId = SubWorkOrderId 
				FROM #tmpSubWorkOrder tmpSWO WHERE tmpSWO.ID = @SubWoCount;
				
				--Insert SWOM data
				INSERT INTO #tmpSubWorkOrderMaterials (SubWorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
					SELECT SWOMS.SubWorkOrderMaterialsId,
						CASE WHEN ISNULL(SWOMS.RepairOrderId, 0) > 0 THEN ISNULL(SWOMS.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(SWOMS.UnitCost, 0) END AS UnitCost,
						ISNULL(SWOMS.ExtendedCost, 0),
						ISNULL(SWOMS.QtyIssued, 0),
						ISNULL(SWOMS.QtyReserved, 0),
						CASE WHEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
							 THEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) 
							 ELSE ISNULL(POPartReferece.Qty, 0) END,
						CASE WHEN ISNULL(SWOM.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOM.UnitCost, 0) END,
						SWOM.POId,
						CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOM.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
					FROM [DBO].[SubWorkOrderMaterials] SWOM WITH(NOLOCK) 
						LEFT JOIN [DBO].[SubWorkOrderMaterialStockLine] SWOMS WITH(NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId
						LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON SWOM.SubWorkOrderId = ROP.SubWorkOrderId AND SWOMS.StockLineId = ROP.StockLineId
						LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON SWOMS.StockLineId = SL.StockLineId
						LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOM.POId AND POP.ItemMasterId = SWOM.ItemMasterId AND (POP.ConditionId = SWOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = SWOM.SubWorkOrderMaterialsId AND SWOM.ProvisionId = @exchangeProvisionId))
						LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
						LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOM.SubWorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
					WHERE SWOM.SubWorkOrderId = @MainSubWorkOrderId AND SWOM.IsDeleted = 0;

				--Insert SWOMK data
				INSERT INTO #tmpSWorkOrderMaterialsKit (WorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
				SELECT DISTINCT 
					SWOMSK.SubWorkOrderMaterialsKitId,
					CASE WHEN ISNULL(SWOMSK.RepairOrderId, 0) > 0 THEN ISNULL(SWOMSK.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(SWOMSK.UnitCost, 0) END AS UnitCost,
					ISNULL(SWOMSK.ExtendedCost, 0),
					ISNULL(SWOMSK.QtyIssued, 0),
					ISNULL(SWOMSK.QtyReserved, 0),
					CASE WHEN (ISNULL(SWOMK.Quantity, 0) - (ISNULL(SWOMK.QuantityReserved, 0) + ISNULL(SWOMK.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
						THEN (ISNULL(SWOMK.Quantity, 0) - (ISNULL(SWOMK.QuantityReserved, 0) + ISNULL(SWOMK.QuantityIssued, 0))) 
						ELSE ISNULL(POPartReferece.Qty, 0) END,
					CASE WHEN ISNULL(SWOMK.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOMK.UnitCost, 0) END,
					SWOMK.POId,
					CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOMK.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
				FROM [DBO].[SubWorkOrderMaterialsKit] SWOMK WITH(NOLOCK)
					LEFT JOIN [DBO].[SubWorkOrderMaterialStockLineKit] SWOMSK  WITH(NOLOCK) ON SWOMK.SubWorkOrderMaterialsKitId = SWOMSK.SubWorkOrderMaterialsKitId
					LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON SWOMSK.StockLineId = SL.StockLineId 
					LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOMK.POId AND POP.ItemMasterId = SWOMK.ItemMasterId AND POP.ConditionId = SWOMK.ConditionCodeId
					LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
					LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOMK.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
				WHERE SWOMK.SubWorkOrderId = @MainSubWorkOrderId AND SWOMK.IsDeleted = 0;	
				
				--SubOutside Cost
				--SELECT @SubOutSideServiceCost = ISNULL(@SubOutSideServiceCost, 0) + ISNULL(SUM(ISNULL(ROP.ExtendedCost,0)),0)
				--	FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
				--	JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId --AND RO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@ROStatusIds,',')) 
				--WHERE ROP.SubWorkOrderId = @MainSubWorkOrderId;

				--Sub Outside Cost
				SELECT @OutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))) , 
					   @ReserveOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
					   @IssueOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
				FROM [DBO].[Stockline] SL WITH(NOLOCK)
					JOIN [DBO].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId --AND SL.RepairOrderId = WOMS.RepairOrderId
					JOIN [DBO].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId			
				WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.SubWorkOrderId  = @MainSubWorkOrderId;

				SELECT @OutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))), 
					   @ReserveOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
					   @IssueOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
				FROM [DBO].[Stockline] SL WITH(NOLOCK)
					JOIN [DBO].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId --AND SL.RepairOrderId = WOMS.RepairOrderId
					JOIN [DBO].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsKitId = WOMS.SubWorkOrderMaterialsKitId			
				WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.SubWorkOrderId  = @MainSubWorkOrderId;

				SET @SubOutSideServiceCost = ISNULL(@OutSideServiceMaterialsCost, 0) + ISNULL(@OutSideServiceKitCost, 0);
				SET @ReserveOutSideServiceCost = ISNULL(@ReserveOutSideServiceMaterialsCost, 0) + ISNULL(@ReserveOutSideServiceKitCost, 0);
				SET @IssueOutSideServiceCost = ISNULL(@IssueOutSideServiceMaterialsCost, 0) + ISNULL(@IssueOutSideServiceKitCost, 0);

				--Labor Cost
				SELECT @WorkOrderLaborHeaderIds = STRING_AGG(WOLH.SubWorkOrderLaborHeaderId, ', ')
					FROM [DBO].[SubWorkOrderLaborHeader] WOLH WITH(NOLOCK) 
				WHERE WOLH.SubWorkOrderId = @MainSubWorkOrderId;
		
				INSERT INTO #tmpWorkOrderLabor (DirectLaborOHCost,BurdenRateAmount,AdjustedHours) 
					SELECT WOL.DirectLaborOHCost,
						   WOL.BurdenRateAmount,
						   WOL.AdjustedHours
				FROM [DBO].[SubWorkOrderLabor] WOL WITH(NOLOCK)
				WHERE WOL.SubWorkOrderLaborHeaderId IN(SELECT Item FROM dbo.SplitString(@WorkOrderLaborHeaderIds, ','));

				--Freight Cost
				SELECT @FreightCost = ISNULL(@FreightCost,0) + ISNULL(SUM(ISNULL(WOC.Amount,0)),0)
					FROM [DBO].[SubWorkOrderFreight] WOC WITH(NOLOCK) 
				WHERE WOC.SubWorkOrderId = @MainSubWorkOrderId AND WOC.IsDeleted = 0;
				
				--Charges Cost
				SELECT @ChargesCost = ISNULL(@ChargesCost,0) + ISNULL(SUM(ISNULL(WOC.ExtendedCost,0)),0) 
					FROM [DBO].[SubWorkOrderCharges] WOC WITH(NOLOCK) 
				WHERE WOC.SubWorkOrderId = @MainSubWorkOrderId AND WOC.IsDeleted = 0;

				SET @MainSubWorkOrderId = 0;
				SET @SubWoCount = @SubWoCount + 1;
			END
		END
		ELSE
		BEGIN 
			IF(ISNULL(@SubWOPartNoId,0) = 0)
			BEGIN
				--Insert SWOM data
				INSERT INTO #tmpSubWorkOrderMaterials (SubWorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
				SELECT SWOMS.SubWorkOrderMaterialsId,					
					CASE WHEN ISNULL(SWOMS.RepairOrderId, 0) > 0 THEN ISNULL(SWOMS.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(SWOMS.UnitCost, 0) END AS UnitCost,
					ISNULL(SWOMS.ExtendedCost, 0),
					ISNULL(SWOMS.QtyIssued, 0),
					ISNULL(SWOMS.QtyReserved, 0),
					CASE WHEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
							THEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) 
							ELSE ISNULL(POPartReferece.Qty, 0) END,
					CASE WHEN ISNULL(SWOM.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOM.UnitCost, 0) END,
					SWOM.POId,					
					CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOM.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
				FROM [DBO].[SubWorkOrderMaterials] SWOM WITH(NOLOCK) 
					LEFT JOIN [DBO].[SubWorkOrderMaterialStockLine] SWOMS WITH(NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId					
					LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON SWOMS.StockLineId = SL.StockLineId
					LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOM.POId AND POP.ItemMasterId = SWOM.ItemMasterId AND (POP.ConditionId = SWOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = SWOM.SubWorkOrderMaterialsId AND SWOM.ProvisionId = @exchangeProvisionId))
					LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
					LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOM.SubWorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
				WHERE SWOM.SubWorkOrderId = @WorkOrderId AND SWOM.IsDeleted = 0;

				--Insert SWOMK data
				INSERT INTO #tmpSWorkOrderMaterialsKit (WorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
				SELECT DISTINCT 
					SWOMSK.SubWorkOrderMaterialsKitId,
					--SWOMSK.UnitCost,
					CASE WHEN ISNULL(SWOMSK.RepairOrderId, 0) > 0 THEN ISNULL(SWOMSK.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(SWOMSK.UnitCost, 0) END AS UnitCost,
					ISNULL(SWOMSK.ExtendedCost, 0),
					ISNULL(SWOMSK.QtyIssued, 0),
					ISNULL(SWOMSK.QtyReserved, 0),
					CASE WHEN (ISNULL(SWOMK.Quantity, 0) - (ISNULL(SWOMK.QuantityReserved, 0) + ISNULL(SWOMK.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
						THEN (ISNULL(SWOMK.Quantity, 0) - (ISNULL(SWOMK.QuantityReserved, 0) + ISNULL(SWOMK.QuantityIssued, 0))) 
						ELSE ISNULL(POPartReferece.Qty, 0) END,
					CASE WHEN ISNULL(SWOMK.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOMK.UnitCost, 0) END,
					SWOMK.POId,					
					CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOMK.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
				FROM [DBO].[SubWorkOrderMaterialsKit] SWOMK WITH(NOLOCK)
					LEFT JOIN [DBO].[SubWorkOrderMaterialStockLineKit] SWOMSK  WITH(NOLOCK) ON SWOMK.SubWorkOrderMaterialsKitId = SWOMSK.SubWorkOrderMaterialsKitId					
					LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON SWOMSK.StockLineId = SL.StockLineId
					LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOMK.POId AND POP.ItemMasterId = SWOMK.ItemMasterId AND POP.ConditionId = SWOMK.ConditionCodeId
					LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
					LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOMK.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
				WHERE SWOMK.SubWorkOrderId = @WorkOrderId AND SWOMK.IsDeleted = 0;	

				--SubOutside Cost
				--SELECT @SubOutSideServiceCost = ISNULL(@SubOutSideServiceCost, 0) + ISNULL(SUM(ISNULL(ROP.ExtendedCost,0)),0) 
				--	FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
				--	JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId --AND RO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@ROStatusIds,',')) 
				--WHERE ROP.SubWorkOrderId = @WorkOrderId;

				--Sub Outside Cost
				SELECT @OutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))) , 
					   @ReserveOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
					   @IssueOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
				FROM [DBO].[Stockline] SL WITH(NOLOCK)
					JOIN [DBO].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId --AND SL.RepairOrderId = WOMS.RepairOrderId
					JOIN [DBO].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId			
				WHERE WOM.SubWorkOrderId  = @WorkOrderId;

				SELECT @OutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))), 
					   @ReserveOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
					   @IssueOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
				FROM [DBO].[Stockline] SL WITH(NOLOCK)
					JOIN [DBO].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId --AND SL.RepairOrderId = WOMS.RepairOrderId
					JOIN [DBO].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsKitId = WOMS.SubWorkOrderMaterialsKitId			
				WHERE WOM.SubWorkOrderId  = @WorkOrderId;

				SET @SubOutSideServiceCost = ISNULL(@OutSideServiceMaterialsCost, 0) + ISNULL(@OutSideServiceKitCost, 0);
				SET @ReserveOutSideServiceCost = ISNULL(@ReserveOutSideServiceMaterialsCost, 0) + ISNULL(@ReserveOutSideServiceKitCost, 0);
				SET @IssueOutSideServiceCost = ISNULL(@IssueOutSideServiceMaterialsCost, 0) + ISNULL(@IssueOutSideServiceKitCost, 0);

				--Labor Cost
				SELECT @WorkOrderLaborHeaderId = WOLH.SubWorkOrderLaborHeaderId , @TotalWorkHours = TotalWorkHours
					FROM [DBO].[SubWorkOrderLaborHeader] WOLH WITH(NOLOCK) 
				WHERE WOLH.SubWorkOrderId = @WorkOrderId;
		
				INSERT INTO #tmpWorkOrderLabor (DirectLaborOHCost,BurdenRateAmount,AdjustedHours) 
					SELECT WOL.DirectLaborOHCost,
						   WOL.BurdenRateAmount,
						   WOL.AdjustedHours
				FROM [DBO].[SubWorkOrderLabor] WOL WITH(NOLOCK)
				WHERE WOL.SubWorkOrderLaborHeaderId = @WorkOrderLaborHeaderId;

				--Freight Cost
				SELECT @FreightCost = ISNULL(SUM(ISNULL(WOC.Amount,0)),0)
					FROM [DBO].[SubWorkOrderFreight] WOC WITH(NOLOCK) 
				WHERE WOC.SubWorkOrderId = @WorkOrderId AND WOC.IsDeleted = 0;

				--Charges Cost
				SELECT @ChargesCost = ISNULL(SUM(ISNULL(WOC.ExtendedCost,0)),0) 
					FROM [DBO].[SubWorkOrderCharges] WOC WITH(NOLOCK) 
				WHERE WOC.SubWorkOrderId = @WorkOrderId AND WOC.IsDeleted = 0;
			END
			ELSE
			BEGIN
				--Insert SWOM data
				INSERT INTO #tmpSubWorkOrderMaterials (SubWorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
				SELECT SWOMS.SubWorkOrderMaterialsId,
					CASE WHEN ISNULL(SWOMS.RepairOrderId, 0) > 0 THEN ISNULL(SWOMS.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(SWOMS.UnitCost, 0) END AS UnitCost,
					ISNULL(SWOMS.ExtendedCost, 0),
					ISNULL(SWOMS.QtyIssued, 0),
					ISNULL(SWOMS.QtyReserved, 0),
					CASE WHEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
							THEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) 
							ELSE ISNULL(POPartReferece.Qty, 0) END,
					CASE WHEN ISNULL(SWOM.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOM.UnitCost, 0) END,
					SWOM.POId,
					CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOM.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
				FROM [DBO].[SubWorkOrderMaterials] SWOM WITH(NOLOCK) 
					LEFT JOIN [DBO].[SubWorkOrderMaterialStockLine] SWOMS WITH(NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId					
					LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON SWOMS.StockLineId = SL.StockLineId
					LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOM.POId AND POP.ItemMasterId = SWOM.ItemMasterId AND (POP.ConditionId = SWOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = SWOM.SubWorkOrderMaterialsId AND SWOM.ProvisionId = @exchangeProvisionId))
					LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
					LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOM.SubWorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
				WHERE SWOM.SubWorkOrderId = @WorkOrderId AND SWOM.IsDeleted = 0 AND SWOM.SubWOPartNoId = @SubWOPartNoId;

				--Insert SWOMK data
				INSERT INTO #tmpSWorkOrderMaterialsKit (WorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
				SELECT DISTINCT 
					SWOMSK.SubWorkOrderMaterialsKitId,
					CASE WHEN ISNULL(SWOMSK.RepairOrderId, 0) > 0 THEN ISNULL(SWOMSK.UnitCost, 0) - ISNULL(SL.RepairOrderUnitCost, 0) ELSE ISNULL(SWOMSK.UnitCost, 0) END AS UnitCost,
					ISNULL(SWOMSK.ExtendedCost, 0),
					ISNULL(SWOMSK.QtyIssued, 0),
					ISNULL(SWOMSK.QtyReserved, 0),
					CASE WHEN (ISNULL(SWOMK.Quantity, 0) - (ISNULL(SWOMK.QuantityReserved, 0) + ISNULL(SWOMK.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
						THEN (ISNULL(SWOMK.Quantity, 0) - (ISNULL(SWOMK.QuantityReserved, 0) + ISNULL(SWOMK.QuantityIssued, 0))) 
						ELSE ISNULL(POPartReferece.Qty, 0) END,
					CASE WHEN ISNULL(SWOMK.UnitCost,0) = 0 THEN ISNULL(POP.UnitCost, 0) ELSE ISNULL(SWOMK.UnitCost, 0) END,
					SWOMK.POId,
					CASE WHEN ISNULL(PO.PurchaseOrderId, 0) > 0 THEN SWOMK.QtyToTurnIn ELSE 0 END AS QtyToTurnIn
				FROM [DBO].[SubWorkOrderMaterialsKit] SWOMK WITH(NOLOCK)
					LEFT JOIN [DBO].[SubWorkOrderMaterialStockLineKit] SWOMSK WITH(NOLOCK) ON SWOMK.SubWorkOrderMaterialsKitId = SWOMSK.SubWorkOrderMaterialsKitId
					LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON SWOMK.SubWorkOrderId = ROP.SubWorkOrderId 
					LEFT JOIN [DBO].[Stockline] SL WITH(NOLOCK) ON SWOMSK.StockLineId = SL.StockLineId
					LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOMK.POId AND POP.ItemMasterId = SWOMK.ItemMasterId AND POP.ConditionId = SWOMK.ConditionCodeId
					LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@POStatusIds,',')) 
					LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOMK.WorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
				WHERE SWOMK.SubWorkOrderId = @WorkOrderId AND SWOMK.IsDeleted = 0 AND SWOMK.SubWOPartNoId = @SubWOPartNoId;	

				--SubOutside Cost
				--SELECT @SubOutSideServiceCost = ISNULL(@SubOutSideServiceCost, 0) + ISNULL(SUM(ISNULL(ROP.ExtendedCost,0)),0) 
				--	FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
				--	JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId --AND RO.StatusId NOT IN (SELECT Item FROM DBO.SPLITSTRING(@ROStatusIds,',')) 
				--WHERE ROP.SubWorkOrderId = @WorkOrderId;

				--SubOutside Cost
				SELECT @OutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))) , 
					   @ReserveOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
					   @IssueOutSideServiceMaterialsCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
				FROM [DBO].[Stockline] SL WITH(NOLOCK)
					JOIN [DBO].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId --AND SL.RepairOrderId = WOMS.RepairOrderId
					JOIN [DBO].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId			
				WHERE WOM.SubWorkOrderId  = @WorkOrderId;

				SELECT @OutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))), 
					   @ReserveOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyReserved, 0))),
					   @IssueOutSideServiceKitCost = SUM(ISNULL(SL.RepairOrderUnitCost,0) * (ISNULL(WOMS.QtyIssued, 0)))
				FROM [DBO].[Stockline] SL WITH(NOLOCK)
					JOIN [DBO].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOMS.StockLineId = SL.StockLineId --AND SL.RepairOrderId = WOMS.RepairOrderId
					JOIN [DBO].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsKitId = WOMS.SubWorkOrderMaterialsKitId			
				WHERE WOM.SubWorkOrderId  = @WorkOrderId;

				SET @SubOutSideServiceCost = ISNULL(@OutSideServiceMaterialsCost, 0) + ISNULL(@OutSideServiceKitCost, 0);
				SET @ReserveOutSideServiceCost = ISNULL(@ReserveOutSideServiceMaterialsCost, 0) + ISNULL(@ReserveOutSideServiceKitCost, 0);
				SET @IssueOutSideServiceCost = ISNULL(@IssueOutSideServiceMaterialsCost, 0) + ISNULL(@IssueOutSideServiceKitCost, 0);

				--Labor Cost
				SELECT @WorkOrderLaborHeaderId = WOLH.SubWorkOrderLaborHeaderId , @TotalWorkHours = TotalWorkHours
					FROM [DBO].[SubWorkOrderLaborHeader] WOLH WITH(NOLOCK) 
				WHERE WOLH.SubWorkOrderId = @WorkOrderId AND WOLH.SubWOPartNoId = @SubWOPartNoId;
		
				INSERT INTO #tmpWorkOrderLabor (DirectLaborOHCost,BurdenRateAmount,AdjustedHours) 
					SELECT WOL.DirectLaborOHCost,
						   WOL.BurdenRateAmount,
						   WOL.AdjustedHours
				FROM [DBO].[SubWorkOrderLabor] WOL WITH(NOLOCK)
				WHERE WOL.SubWorkOrderLaborHeaderId = @WorkOrderLaborHeaderId;

				--Freight Cost
				SELECT @FreightCost = ISNULL(SUM(ISNULL(WOC.Amount,0)),0)
					FROM [DBO].[SubWorkOrderFreight] WOC WITH(NOLOCK) 
				WHERE WOC.SubWorkOrderId = @WorkOrderId AND WOC.IsDeleted = 0 AND WOC.SubWOPartNoId = @SubWOPartNoId;

				--Charges Cost
				SELECT @ChargesCost = ISNULL(SUM(ISNULL(WOC.ExtendedCost,0)),0) 
					FROM [DBO].[SubWorkOrderCharges] WOC WITH(NOLOCK) 
				WHERE WOC.SubWorkOrderId = @WorkOrderId AND WOC.IsDeleted = 0 AND WOC.SubWOPartNoId = @SubWOPartNoId;
			END
				
		END
		
		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		--Get from SubWOMaterial table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpSubWorkOrderMaterials;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @SubQtyIssued = ISNULL(QtyIssued, 0) ,
				   @SubQtyToTurnIn = ISNULL(QtyToTurnIn, 0) , 
				   @SubUnitCost = ISNULL(UnitCost, 0) ,
				   @bkUnitCost = ISNULL(MUnitCost, 0),
				   @poid = POId,
				   @QtyOnBkOrder = ISNULL(QtyOnBkOrder, 0), 
				   @SubQtyReserved = ISNULL(QtyReserved, 0)
			FROM #tmpSubWorkOrderMaterials tmpSubWOM WHERE tmpSubWOM.ID = @count; 

			IF(@SubQtyReserved > 0)
			BEGIN
				SET @SubReservedCost = ISNULL(@SubReservedCost, 0) + ISNULL((@SubQtyReserved * @SubUnitCost), 0);
			END

			IF(@QtyOnBkOrder > 0)
			BEGIN
				SET @BkOrderCost = ISNULL(@BkOrderCost, 0) + (ISNULL(@QtyOnBkOrder, 0) * ISNULL(@bkUnitCost, 0));
			END
			
			IF(@SubQtyIssued > 0)
			BEGIN
				SET @SubpartsCost = ISNULL(@SubpartsCost, 0) + ISNULL((@SubQtyIssued * @SubUnitCost), 0);
			END

			IF(@SubQtyToTurnIn > 0)
			BEGIN
				SET @SubQtyToTurnCost = ISNULL(@SubQtyToTurnCost, 0) + ISNULL((@SubQtyToTurnIn * @SubUnitCost), 0);
			END

			SET @SubQtyIssued = 0;
			SET @SubQtyToTurnIn = 0;
			SET @SubUnitCost = 0;
			SET @bkUnitCost = 0;
			SET @poid = 0;
			SET @POQuantity = 0;
			SET @count = @count + 1;
		END

		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		--Get from SWOMaterialKit table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpSWorkOrderMaterialsKit;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @SubQtyIssued = ISNULL(QtyIssued, 0) ,
				   @SubQtyToTurnIn = ISNULL(QtyToTurnIn, 0) , 
				   @SubUnitCost = ISNULL(UnitCost, 0) ,
				   @bkUnitCost = ISNULL(MUnitCost, 0),
				   @poid = POId,
				   @QtyOnBkOrder = CASE WHEN (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) > ISNULL(QtyOnBkOrder, 0) THEN 0 ELSE ISNULL(QtyOnBkOrder, 0) - (ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0)) END, 
				   @SubQtyReserved = ISNULL(QtyReserved, 0)
			FROM #tmpSWorkOrderMaterialsKit tmpWOM WHERE tmpWOM.ID = @count; 
			
			IF(@SubQtyReserved > 0)
			BEGIN
				SET @SubReservedCost = ISNULL(@SubReservedCost, 0) + ISNULL((@SubQtyReserved * @SubUnitCost), 0);
			END

			IF(@QtyOnBkOrder > 0)
			BEGIN
				SET @BkOrderCost = ISNULL(@BkOrderCost, 0) + (ISNULL(@QtyOnBkOrder, 0) * ISNULL(@bkUnitCost, 0));
			END
			
			IF(@SubQtyIssued > 0)
			BEGIN
				SET @SubpartsCost = ISNULL(@SubpartsCost, 0) + ISNULL((@SubQtyIssued * @SubUnitCost), 0);
			END

			IF(@SubQtyToTurnIn > 0)
			BEGIN
				SET @SubQtyToTurnCost = ISNULL(@SubQtyToTurnCost, 0) + ISNULL((@SubQtyToTurnIn * @SubUnitCost), 0);
			END

			SET @SubQtyIssued = 0;
			SET @SubQtyToTurnIn = 0;
			SET @SubUnitCost = 0;
			SET @bkUnitCost = 0;
			SET @poid = 0;
			SET @POQuantity = 0;
			SET @count = @count + 1;
		END

		DECLARE @tmpBurdenRateAmount DECIMAL(18, 6)= 0.0,
				@tmpDirectLaborOHCost DECIMAL(18, 6)= 0.0,
				@tmpAdjustedHours DECIMAL(18, 6)= 0.0,
				@tmpBurdonLaborCost DECIMAL(18, 6) = 0.0,
				@tmpDirectLaborCost DECIMAL(18, 6) = 0.0,
				@tmpAdjustedHoursdata BIGINT,
				@minutesdata BIGINT,
				@tmpAdjustedHoursdata1 DECIMAL(18, 6) = 0.0;

		--Get from WOMaterialKit table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpWorkOrderLabor;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @tmpBurdenRateAmount = tmpWOL.BurdenRateAmount,
				   @tmpDirectLaborOHCost = tmpWOL.DirectLaborOHCost,@tmpAdjustedHours = tmpWOL.AdjustedHours,
				   @tmpAdjustedHoursdata = PARSENAME(tmpWOL.AdjustedHours,1)
			FROM #tmpWorkOrderLabor tmpWOL WHERE tmpWOL.ID = @count; 

			SET @tmpBurdonLaborCost = ISNULL(@tmpBurdonLaborCost, 0) + (@tmpBurdenRateAmount * PARSENAME(@tmpAdjustedHours,2));
			SET @tmpDirectLaborCost = ISNULL(@tmpDirectLaborCost, 0) + (@tmpDirectLaborOHCost * PARSENAME(@tmpAdjustedHours,2));

			SET @tmpAdjustedHoursdata1 = CAST((CAST(@tmpAdjustedHoursdata AS DECIMAL(18, 6))/ 100 )AS DECIMAL(18, 6));

			IF(@tmpAdjustedHoursdata > 0)
			BEGIN
				SET @tmpBurdonLaborCost = ISNULL(@tmpBurdonLaborCost, 0) + ((@tmpAdjustedHoursdata1 * 100 /60) * @tmpBurdenRateAmount);
				SET @tmpDirectLaborCost = ISNULL(@tmpDirectLaborCost, 0) + ((@tmpAdjustedHoursdata1 * 100 /60) * @tmpDirectLaborOHCost);
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

		--Total SubRowMaterial cost
		SET @SubRowMaterialTotalCost = (ISNULL(@SubReservedCost, 0) + ISNULL(@SubpartsCost, 0) + ISNULL(@SubQtyToTurnCost, 0) + ISNULL(@BkOrderCost, 0));

	-------------------------------------------------------------------------------------------------------------------------------
	
	SELECT  @ReservedCost AS 'ReservedCost',
			@partsCost AS 'IssuedCost',
			@QtyToTurnCost AS 'TenderCost',
			@BkOrderCost AS 'BackorderCost',
			@RowMaterialTotalCost AS 'RowMaterialTotalCost',
			@OutSideServiceCost AS 'OutsideCost',			
			@OverheadCost AS 'OverheadCost',
			@DirectLaborCost AS 'LaborCost',
			@FreightCost AS 'FreightCost',
			@ChargesCost AS 'ChargesCost',
			@SubReservedCost AS 'SubReservedCost',
			@SubpartsCost AS 'SubIssuedCost',
			@SubQtyToTurnCost AS 'SubTenderCost',
			@BkOrderCost AS 'SubBackorderCost',
			@SubRowMaterialTotalCost AS 'SubRowMaterialTotalCost',
			@SubOutSideServiceCost AS 'SubOutsideCost',
			@ReserveOutSideServiceCost AS 'SubReserveOutsideCost',
			@IssueOutSideServiceCost AS 'SubIssueOutsideCost',
			ISNULL(@SubReservedCost, 0) + ISNULL(@ReserveOutSideServiceCost, 0) AS 'SubReserveTotalCost',
			ISNULL(@SubpartsCost, 0) + ISNULL(@IssueOutSideServiceCost, 0) AS 'SubIssueTotalCost',
			@OverheadCost AS 'SubLaborCost',
			@DirectLaborCost AS 'SubOverheadCost',
			@FreightCost AS 'SubFreightCost',
			@ChargesCost AS 'SubChargesCost',
			@subPartNumber AS 'PartNumber',
			@subPartNumberDesc AS 'PartNumberDesc',
			@woNumber As 'WoNumber',
			@IsSubWO As 'IsSubWO';
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails' 
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