/***************************************************************  
 ** File:   [usp_GetWorkOrderAndQuoteCostDetails]             
 ** Author:   Hemnat Saliya
 ** Description: Get WorkOrder Analysis Summary for Actual Vs Quote
 ** Date:  18-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    18-04-2025		Hemnat Saliya			Created
	2    23-04-2025		Moin Bloch			    Fix For Analysis Revenue Amount
	3    03-07-2025     Moin Bloch              Changed Old To New Billing Table
	4    09-01-2026		Hemnat Saliya			FIxed for Act Vs Quote Summary Labor Flat Amount wa not get

		
	exec dbo.usp_GetWorkOrderAndQuoteCostDetails 8374,8688
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetWorkOrderAndQuoteCostDetails]
@WorkOrderWorkflowId BIGINT,
@WorkOrderId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
		DECLARE @WOModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		DECLARE 
        @LabourCost DECIMAL(18,2) = 0,
        @PartsCost DECIMAL(18,2) = 0,
        @MICCharges DECIMAL(18,2) = 0,
        @FreightCost DECIMAL(18,2) = 0,
        @WORevenue DECIMAL(18,2) = 0,
        @IsRevenueFromWO BIT = 0,
        @QuoteId BIGINT,
        @QuoteDetailsId BIGINT,
        @QuoteMethod BIT,
        @LaborFlatBillingAmount DECIMAL(18,2),
        @LaborCost DECIMAL(18,2),
        @MaterialFlatBillingAmount DECIMAL(18,2),
        @MaterialCost DECIMAL(18,2),
        @ChargesFlatBillingAmount DECIMAL(18,2),
        @ChargesCost DECIMAL(18,2),
        @FreightFlatBillingAmount DECIMAL(18,2),
        @CommonFlatRate DECIMAL(18,2),
		@TotalPrice DECIMAL(18,2),
		@TotalCost DECIMAL(18,2),
        @LaborBuildMethod INT,
        @MaterialBuildMethod INT,
        @ChargesBuildMethod INT,
		@FreightBuildMethod INT,
        @LabourAmountPrice DECIMAL(18,2),
        @MarkupFixedPrice VARCHAR(10),
        @QuoteLabourHeaderId BIGINT,
        @WOPartNoId BIGINT;
		
		-- Calculate parts cost (Materials)
		SELECT @PartsCost = ISNULL(SUM(ISNULL(WOMS.UnitCost,0) * ISNULL(WOMS.QtyIssued,0)), 0)
		FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)
		JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND ISNULL(WOM.IsDeleted, 0) = 0 AND ISNULL(WOM.IsActive, 0) = 1;

		-- Add Kit materials
		SELECT @PartsCost = ISNULL(@PartsCost, 0) + ISNULL(SUM(ISNULL(WOMS.UnitCost,0) * ISNULL(WOMS.QtyIssued,0)), 0)
		FROM [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK)
		JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
		WHERE WOM.[WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND ISNULL(WOM.[IsDeleted], 0) = 0 AND ISNULL(WOM.[IsActive], 0) = 1;

		-- Charges
		SELECT @MicCharges = ISNULL(SUM(ISNULL(ExtendedCost, 0)), 0)
		FROM [dbo].[WorkOrderCharges] WITH(NOLOCK)
		WHERE [WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

		-- Freight
		SELECT @FreightCost = ISNULL(SUM(ISNULL(Amount, 0)), 0)
		FROM [dbo].[WorkOrderFreight] WITH(NOLOCK)
		WHERE [WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

		-- Labour Cost
		SELECT TOP 1 @LabourCost = ISNULL(SUM(l.[TotalCost]), 0)
		FROM [dbo].[WorkOrderLaborHeader] lh WITH(NOLOCK)
		JOIN [dbo].[WorkOrderLabor] l WITH(NOLOCK) ON lh.WorkOrderLaborHeaderId = l.WorkOrderLaborHeaderId
		WHERE lh.[WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND ISNULL(l.[BillableId], 0) = 1 AND ISNULL(l.[IsActive], 0) = 1 AND ISNULL(l.[IsDeleted], 0) = 0;

		-- Step 1: Get QuoteId
		SELECT TOP 1 @QuoteId = WorkOrderQuoteId 
		FROM [dbo].[WorkOrderQuote] WITH(NOLOCK)
		WHERE [WorkOrderId] = @WorkOrderId AND [IsVersionIncrease] = 0;
		
		IF(EXISTS (SELECT 1 FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND [WorkOrderQuoteId] = @QuoteId AND ISNULL(IsVersionIncrease, 0) = 0))  
		BEGIN
			-- Step 2: Get Quote Details			
			SELECT TOP 1 
				@QuoteDetailsId = [WorkOrderQuoteDetailsId],				
				@QuoteMethod = ISNULL([QuoteMethod], 0),
				@LaborFlatBillingAmount = CASE WHEN [LaborBuildMethod] = 3 THEN ISNULL([LaborFlatBillingAmount], 0) ELSE ISNULL([LaborBilling], 0) END,
				@LaborCost = ISNULL([LaborCost], 0),
				@MaterialFlatBillingAmount = CASE WHEN [MaterialBuildMethod] = 3 THEN ISNULL([MaterialFlatBillingAmount], 0) ELSE ISNULL([MaterialBilling], 0) END,
				@MaterialCost = ISNULL([MaterialCost], 0),
				@ChargesFlatBillingAmount = CASE WHEN [ChargesBuildMethod] = 3 THEN ISNULL([ChargesFlatBillingAmount], 0) ELSE ISNULL([ChargesBilling], 0) END,
				@ChargesCost = ISNULL(ChargesCost, 0),
				@FreightFlatBillingAmount = CASE WHEN [FreightBuildMethod] = 3 THEN ISNULL([FreightFlatBillingAmount], 0) ELSE ISNULL([FreightBilling], 0) END,
				@CommonFlatRate = ISNULL([CommonFlatRate], 0),
				@LaborBuildMethod = [LaborBuildMethod],
				@MaterialBuildMethod = [MaterialBuildMethod],
				@ChargesBuildMethod = [ChargesBuildMethod],
				@FreightBuildMethod = [FreightBuildMethod]
			FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK)
			WHERE [WorkOrderQuoteId] = @QuoteId AND [WorkflowWorkOrderId] = @WorkOrderWorkflowId AND ISNULL([IsVersionIncrease], 0) = 0;

			-- Step 3: Get Labor Header
			SELECT TOP 1 
				@QuoteLabourHeaderId = WorkOrderQuoteLaborHeaderId,
				@MarkupFixedPrice = ISNULL(MarkupFixedPrice, 0)
			FROM [dbo].WorkOrderQuoteLaborHeader  WITH(NOLOCK)
			WHERE WorkOrderQuoteDetailsId = @QuoteDetailsId AND IsDeleted = 0;

			-- costDetails.QuoteLabourCost logic
			DECLARE @QuoteLabourCost DECIMAL(18,2) = NULL;

			IF (ISNULL(@QuoteLabourHeaderId, 0) > 0)
			BEGIN
				-- if ((QuoteMethod == true) OR (LaborBuildMethod == 3))
				IF (@QuoteMethod = 1) OR (@LaborBuildMethod = 3)
				BEGIN
					SET @QuoteLabourCost = 0;

					-- if (QuoteMethod != true && LaborBuildMethod == FlatRate)
					IF (ISNULL(@QuoteMethod, 0) <> 1) AND (@LaborBuildMethod = 3)
					BEGIN
						SET @QuoteLabourCost = ISNULL(@LaborFlatBillingAmount, 0);
					END
				END
				ELSE
				BEGIN
					-- In your C# you load WorkOrderQuoteLabor.ToList() here but don't use it.
					-- Keeping the effective assignment:
					SET @QuoteLabourCost = ISNULL(@LaborCost, 0);
				END
			END

			-- Step 4: Calculate LabourAmountPrice
			SET @LabourAmountPrice = @LaborFlatBillingAmount;
			IF @MarkupFixedPrice IS NOT NULL AND @MarkupFixedPrice != '3'
			BEGIN
				SELECT @LabourAmountPrice = ISNULL(SUM(BillingAmount), 0)
				FROM [dbo].[WorkOrderQuoteLabor] WITH(NOLOCK)
				WHERE [WorkOrderQuoteLaborHeaderId] = @QuoteLabourHeaderId AND ISNULL([BillableId], 0) = 1 AND ISNULL([IsActive], 0) = 1 AND ISNULL([IsDeleted], 0) = 0;
			END
		END

		-- Step 5: Revenue Source Check
	  --IF(EXISTS (SELECT 1 FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND ISNULL(IsVersionIncrease, 0) = 0 AND ISNULL(IsPerformaInvoice,0) = 0))  
		IF(EXISTS (SELECT 1 FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [ReferenceId] = @WorkOrderId AND [ModuleId] =@WOModuleId AND ISNULL([IsVersionIncrease], 0) = 0 AND ISNULL([IsPerformaInvoice],0) = 0))  
		BEGIN
			SELECT TOP 1 @WOPartNoId = WorkOrderPartNoId
			FROM [dbo].WorkOrderWorkFlow WITH(NOLOCK)
			WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WorkOrderId = @WorkOrderId;

			SELECT TOP 1 @WORevenue = Revenue
			FROM [dbo].WorkOrderMPNCostDetails WITH(NOLOCK)
			WHERE WOPartNoId = @WOPartNoId;

			SET @IsRevenueFromWO = 1;
		END

		SET @TotalPrice = ISNULL(@PartsCost, 0) + ISNULL(@LabourCost, 0) + ISNULL(@MicCharges, 0);
		SET @TotalCost =  ISNULL(@PartsCost, 0) + ISNULL(@LabourCost, 0) + ISNULL(@MicCharges, 0);

		-- OUTPUT (temporary table for example)
		
		SELECT 
			QuoteMethod = @QuoteMethod,
			QuoteLabourCost = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @QuoteLabourCost END,

			QuoteMaterialCost = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE  @MaterialCost END,
			QuoteMiscCharges = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @ChargesCost END,
			QuotefreightCost =  CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @FreightCost END, 

			QuoteLabourPrice = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @LabourAmountPrice END,
			QuoteMaterialPrice = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @MaterialFlatBillingAmount END,
			QuoteMiscChargesPrice = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @ChargesFlatBillingAmount END,
			QuotefreightPrice = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @FreightFlatBillingAmount END,

			QuoteTotalCost = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @MaterialCost + @LaborCost + @ChargesCost END,
			QuoteTotalPrice = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount END,
			MarginQuoteMaterialCost = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @MaterialFlatBillingAmount - @MaterialCost END,
			MarginQuoteLabourCost = @LabourAmountPrice - @LaborCost,
			MarginQuoteMiscCharges = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @ChargesFlatBillingAmount - @ChargesCost END,
			MarginQuotefreightCost = @FreightFlatBillingAmount - @FreightCost,
			MarginQuoteTotalCost = (@MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount) - (@MaterialCost + @LaborCost + @ChargesCost),
			WOQRevenue = CASE WHEN @QuoteMethod = 1 THEN @CommonFlatRate ELSE @MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount END,
			WORevenue = CASE WHEN @IsRevenueFromWO = 1 THEN ISNULL(@WORevenue, 0) ELSE (CASE WHEN @QuoteMethod = 1 THEN @CommonFlatRate ELSE @MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount END) END,
			IsRevenueFromQuote = CASE WHEN @IsRevenueFromWO = 0 THEN 1 ELSE 0 END,
			
			-- Actual Costs and Margins
			MaterialPrice = @PartsCost,
			LabourPrice = @LabourCost,
			MiscChargesPrice = @MicCharges,
			FreightPrice = @FreightCost,
			TotalPrice = @PartsCost + @LabourCost + @MicCharges,
			MaterialCost = @PartsCost,
			LabourCost = @LabourCost,
			MiscCharges = @MicCharges,
			FreightCost = @FreightCost,
			TotalCost = @PartsCost + @LabourCost + @MicCharges,
			MarginMaterialCost = @PartsCost - @PartsCost,
			MarginLabourCost = @LabourCost - @LabourCost,
			MarginMiscCharges = @MicCharges - @MicCharges,
			MarginFreightCost = @FreightCost - @FreightCost,
			MarginTotalCost = (@PartsCost + @LabourCost + @MicCharges) - (@PartsCost + @LabourCost + @MicCharges),
			Marginworkper = CASE WHEN @TotalPrice > 0 THEN ((@TotalPrice - @TotalCost)/ @TotalPrice) * 100 ELSE 0 END,
			MarginQuoteper = CASE WHEN @QuoteMethod = 1 AND (@MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount) > 0 THEN (((@MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount) - (@MaterialCost + @LaborCost + @ChargesCost))/ (@MaterialFlatBillingAmount + @LaborFlatBillingAmount + @ChargesFlatBillingAmount)) * 100 ELSE 0 END;

		END TRY      
	  BEGIN CATCH        
	   IF @@trancount > 0  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				  , @AdhocComments     VARCHAR(150)    = 'usp_GetWorkOrderAndQuoteCostDetails'   				 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
				  , @ApplicationName VARCHAR(100) = 'PAS'  
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
				  exec spLogException   
						   @DatabaseName   = @DatabaseName  
						 , @AdhocComments   = @AdhocComments  
						 , @ProcedureParameters  = @ProcedureParameters  
						 , @ApplicationName         = @ApplicationName  
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;  
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
				  RETURN(1);  
	  END CATCH  
END