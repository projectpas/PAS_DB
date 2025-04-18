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
		FROM [dbo].WorkOrderMaterials WOM WITH(NOLOCK)
		JOIN [dbo].WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOM.IsDeleted = 0;

		-- Add Kit materials
		SELECT @PartsCost = @PartsCost + ISNULL(SUM(ISNULL(WOMS.UnitCost,0) * ISNULL(WOMS.QtyIssued,0)), 0)
		FROM [dbo].WorkOrderMaterialsKit WOM WITH(NOLOCK)
		JOIN [dbo].WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOM.IsDeleted = 0;

		-- Charges
		SELECT @MicCharges = ISNULL(SUM(ISNULL(ExtendedCost, 0)), 0)
		FROM [dbo].WorkOrderCharges WITH(NOLOCK)
		WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId AND IsActive = 1 AND IsDeleted = 0;

		-- Freight
		SELECT @FreightCost = ISNULL(SUM(ISNULL(Amount, 0)), 0)
		FROM [dbo].WorkOrderFreight WITH(NOLOCK)
		WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId AND IsActive = 1 AND IsDeleted = 0;

		-- Labour Cost
		SELECT TOP 1 @LabourCost = ISNULL(SUM(l.TotalCost), 0)
		FROM [dbo].WorkOrderLaborHeader lh WITH(NOLOCK)
		JOIN [dbo].WorkOrderLabor l WITH(NOLOCK) ON lh.WorkOrderLaborHeaderId = l.WorkOrderLaborHeaderId
		WHERE lh.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND l.BillableId = 1 AND l.IsActive = 1 AND l.IsDeleted = 0;

		-- Step 1: Get QuoteId
		SELECT TOP 1 @QuoteId = WorkOrderQuoteId 
		FROM [dbo].WorkOrderQuote WITH(NOLOCK)
		WHERE WorkOrderId = @WorkOrderId AND IsVersionIncrease = 0;
		
		IF(EXISTS (SELECT 1 FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND WorkOrderQuoteId = @QuoteId AND ISNULL(IsVersionIncrease, 0) = 0))  
		BEGIN
			-- Step 2: Get Quote Details
			SELECT TOP 1 
				@QuoteDetailsId = WorkOrderQuoteDetailsId,
				@QuoteMethod = ISNULL(QuoteMethod, 0),
				@LaborFlatBillingAmount = ISNULL(LaborFlatBillingAmount, 0),
				@LaborCost = ISNULL(LaborCost, 0),
				@MaterialFlatBillingAmount = ISNULL(MaterialFlatBillingAmount, 0),
				@MaterialCost = ISNULL(MaterialCost, 0),
				@ChargesFlatBillingAmount = ISNULL(ChargesFlatBillingAmount, 0),
				@ChargesCost = ISNULL(ChargesCost, 0),
				@FreightFlatBillingAmount = ISNULL(FreightFlatBillingAmount, 0),
				@CommonFlatRate = ISNULL(CommonFlatRate, 0),
				@LaborBuildMethod = LaborBuildMethod,
				@MaterialBuildMethod = MaterialBuildMethod,
				@ChargesBuildMethod = ChargesBuildMethod,
				@FreightBuildMethod = FreightBuildMethod
			FROM [dbo].WorkOrderQuoteDetails WITH(NOLOCK)
			WHERE WorkOrderQuoteId = @QuoteId AND WorkflowWorkOrderId = @WorkOrderWorkflowId AND IsVersionIncrease = 0;

			-- Step 3: Get Labor Header
			SELECT TOP 1 
				@QuoteLabourHeaderId = WorkOrderQuoteLaborHeaderId,
				@MarkupFixedPrice = MarkupFixedPrice
			FROM [dbo].WorkOrderQuoteLaborHeader  WITH(NOLOCK)
			WHERE WorkOrderQuoteDetailsId = @QuoteDetailsId AND IsDeleted = 0;

			-- Step 4: Calculate LabourAmountPrice
			SET @LabourAmountPrice = @LaborFlatBillingAmount;
			IF @MarkupFixedPrice IS NOT NULL AND @MarkupFixedPrice != '3'
			BEGIN
				SELECT @LabourAmountPrice = ISNULL(SUM(BillingAmount), 0)
				FROM [dbo].WorkOrderQuoteLabor WITH(NOLOCK)
				WHERE WorkOrderQuoteLaborHeaderId = @QuoteLabourHeaderId AND BillableId = 1 AND IsActive = 1 AND IsDeleted = 0;
			END
		END

		-- Step 5: Revenue Source Check
		IF(EXISTS (SELECT 1 FROM [dbo].WorkOrderBillingInvoicing WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND ISNULL(IsVersionIncrease, 0) = 0 AND ISNULL(IsPerformaInvoice,0) = 0))  
		BEGIN
			SELECT TOP 1 @WOPartNoId = WorkOrderPartNoId
			FROM [dbo].WorkOrderWorkFlow WITH(NOLOCK)
			WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WorkOrderId = @WorkOrderId;

			SELECT TOP 1 @WORevenue = Revenue
			FROM [dbo].WorkOrderMPNCostDetails WITH(NOLOCK)
			WHERE WOPartNoId = @WOPartNoId;

			SET @IsRevenueFromWO = 1;
		END

		SET @TotalPrice = @PartsCost + @LabourCost + @MicCharges;
		SET @TotalCost = @PartsCost + @LabourCost + @MicCharges;

		-- OUTPUT (temporary table for example)
		SELECT 
			QuoteMethod = @QuoteMethod,
			QuoteLabourCost = CASE WHEN @QuoteMethod = 1 THEN 0 ELSE @LaborCost END,

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
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingCostDetails'   
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workorderid, '') + ''  
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