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
	

EXEC [dbo].[USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails] 3123, 3652     
**************************************************************/
CREATE       PROCEDURE [dbo].[USP_SubWorkOrder_GetSubWorkOrderandCostAnalysisDetails]
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
				@SubOutSideServiceCost DECIMAL(18,2),@FreightCost DECIMAL(18,2),@ChargesCost DECIMAL(18,2),@woNumber VARCHAR(256),@subItemMasterId BIGINT,@subPartNumber VARCHAR(256),@subPartNumberDesc VARCHAR(MAX);
		DECLARE @exchangeProvisionId int = (SELECT TOP 1 ProvisionId FROM Provision Where Description = 'EXCHANGE')
		
		SET @count = 1;

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

		SET @woNumber = (SELECT [SubWorkOrderNo] FROM [DBO].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId);
		SET @subItemMasterId = (SELECT [ItemMasterId] FROM [DBO].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWorkOrderId] = @WorkOrderId);
		SELECT @subPartNumber = [partnumber], @subPartNumberDesc = [PartDescription] FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @subItemMasterId;

		INSERT INTO #tmpSubWorkOrderMaterials (SubWorkOrderMaterialsId,UnitCost,ExtendedCost, QtyIssued, QtyReserved, QtyOnBkOrder, MUnitCost, POId, QtyToTurnIn) 
			SELECT SWOMS.SubWorkOrderMaterialsId,
				SWOMS.UnitCost,
				SWOMS.ExtendedCost,
				SWOMS.QtyIssued,
				SWOMS.QtyReserved,
				--SWOM.QtyOnBkOrder,
				CASE WHEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) < ISNULL(POPartReferece.Qty, 0) 
					 THEN (ISNULL(SWOM.Quantity, 0) - (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0))) 
					 ELSE ISNULL(POPartReferece.Qty, 0) END,
				CASE WHEN ISNULL(SWOM.UnitCost,0) = 0 THEN POP.UnitCost ELSE SWOM.UnitCost END,
				SWOM.POId,
				SWOM.QtyToTurnIn
		FROM [DBO].[SubWorkOrderMaterials] SWOM WITH(NOLOCK) 
			LEFT JOIN [DBO].[SubWorkOrderMaterialStockLine] SWOMS WITH(NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = SWOM.POId AND POP.ItemMasterId = SWOM.ItemMasterId AND (POP.ConditionId = SWOM.ConditionCodeId OR (pop.WorkOrderMaterialsId = SWOM.SubWorkOrderMaterialsId AND SWOM.ProvisionId = @exchangeProvisionId))
			LEFT JOIN dbo.PurchaseOrderPartReference POPartReferece WITH(NOLOCK) ON POPartReferece.ReferenceId = SWOM.SubWorkOrderId AND POPartReferece.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId
		WHERE SWOM.SubWorkOrderId = @WorkOrderId AND SWOM.IsDeleted = 0;

		--Reset counts.
		SET @TotalCounts  = 0;
		SET @count = 1;

		--Get from SubWOMaterial table
		SELECT @TotalCounts = COUNT(ID) FROM #tmpSubWorkOrderMaterials;
		WHILE @count <= @TotalCounts
		BEGIN
			SELECT @SubQtyIssued = QtyIssued ,
				   @SubQtyToTurnIn = QtyToTurnIn , 
				   @SubUnitCost = UnitCost ,
				   @bkUnitCost = ISNULL(MUnitCost, 0),
				   @poid = POId,
				   --@SubQtyOnBkOrder = QtyOnBkOrder,
				   @QtyOnBkOrder = ISNULL(QtyOnBkOrder, 0), 
				   @SubQtyReserved = QtyReserved
			FROM #tmpSubWorkOrderMaterials tmpSubWOM WHERE tmpSubWOM.ID = @count; 

			IF(@SubQtyReserved > 0)
			BEGIN
				SET @SubReservedCost = @SubReservedCost + (@SubQtyReserved * @SubUnitCost);
			END

			IF(@QtyOnBkOrder > 0)
			BEGIN
				SET @BkOrderCost = ISNULL(@BkOrderCost, 0) + (ISNULL(@QtyOnBkOrder, 0) * ISNULL(@bkUnitCost, 0));
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
			SET @bkUnitCost = 0;
			SET @poid = 0;
			SET @POQuantity = 0;
			SET @count = @count + 1;
		END

		

		--SubOutside Cost
		SELECT @SubOutSideServiceCost = SUM(ISNULL(ROP.ExtendedCost,0)) 
			FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
		WHERE ROP.SubWorkOrderId = @WorkOrderId;

		--Labor Cost
		SELECT @WorkOrderLaborHeaderId = WOLH.SubWorkOrderLaborHeaderId , @TotalWorkHours = TotalWorkHours
			FROM [DBO].[SubWorkOrderLaborHeader] WOLH WITH(NOLOCK) 
		WHERE WOLH.SubWorkOrderId = @WorkOrderId;

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
		FROM [DBO].[SubWorkOrderLabor] WOL WITH(NOLOCK)
		WHERE WOL.SubWorkOrderLaborHeaderId = @WorkOrderLaborHeaderId;

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
			FROM [DBO].[SubWorkOrderFreight] WOC WITH(NOLOCK) 
		WHERE WOC.SubWorkOrderId = @WorkOrderId AND WOC.IsDeleted = 0;

		--Charges Cost
		SELECT @ChargesCost = SUM(ISNULL(WOC.ExtendedCost,0)) 
			FROM [DBO].[SubWorkOrderCharges] WOC WITH(NOLOCK) 
		WHERE WOC.SubWorkOrderId = @WorkOrderId AND WOC.IsDeleted = 0;;

		--Total SubRowMaterial cost
		SET @SubRowMaterialTotalCost = (@SubReservedCost + @SubpartsCost + @SubQtyToTurnCost + @BkOrderCost);

	-------------------------------------------------------------------------------------------------------------------------------
	
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
			@BkOrderCost AS 'SubBackorderCost',
			@SubRowMaterialTotalCost AS 'SubRowMaterialTotalCost',
			@SubOutSideServiceCost AS 'SubOutsideCost',
			@OverheadCost AS 'SubLaborCost',
			@DirectLaborCost AS 'SubOverheadCost',
			@FreightCost AS 'SubFreightCost',
			@ChargesCost AS 'SubChargesCost',
			@subPartNumber AS 'PartNumber',
			@subPartNumberDesc AS 'PartNumberDesc',
			@woNumber As 'WoNumber';
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