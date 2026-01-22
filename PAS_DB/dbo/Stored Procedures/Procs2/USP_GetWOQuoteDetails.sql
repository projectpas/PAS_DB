/*************************************************************           
 ** File:   [USP_GetWOQuoteDetails]           
 ** Author:   Devendra Shekh
 ** Description: This is used to get Work Order Quote Details after computing Amount
 ** Date:   20-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    20-May-2025   Devendra Shekh		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOQuoteDetails]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE	@WorkOrderQuoteDetailsId BIGINT, @MaterialFlatBillingAmount DECIMAL(18, 2), @LaborFlatBillingAmount DECIMAL(18, 2), @ChargesFlatBillingAmount DECIMAL(18, 2),
				@QuoteMaterialCost DECIMAL(18, 2), @QuoteOverHeadCost DECIMAL(18, 2),  @totalRevenue DECIMAL(18, 2), @totalMargin DECIMAL(18, 2),
				@MaterialMargin DECIMAL(18, 2), @LaborMargin DECIMAL(18, 2), @ChargesMargin DECIMAL(18, 2),
				@InitialRowId INT = 1, @MaterialBuildMethod INT;
		DECLARE @FlateRateBillMethod INT = 3;

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteDetailsResult') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteDetailsResult;

		SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteDetailsId], [WorkOrderQuoteId], [ItemMasterId], [BuildMethodId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
				[UpdatedDate], [IsActive], [IsDeleted], [WorkflowWorkOrderId], [WOPartNoId], [MaterialCost], [MaterialBilling], [MaterialRevenuePercentage], [MaterialMargin], [LaborHours], [LaborCost], [LaborBilling],
				[LaborRevenuePercentage], [LaborMargin], [ChargesCost], [ChargesBilling], [ChargesRevenuePercentage], [ChargesMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenuePercentage],
				[ExclusionsMargin], [FreightCost], [FreightBilling], [FreightRevenuePercentage], [FreightMargin], [MaterialMarginPer], [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer],
				[OverHeadCost], [AdjustmentHours], [AdjustedHours], [LaborFlatBillingAmount], [MaterialFlatBillingAmount], [ChargesFlatBillingAmount], [FreightFlatBillingAmount], [MaterialBuildMethod],
				[LaborBuildMethod], [ChargesBuildMethod], [FreightBuildMethod], [ExclusionsBuildMethod], [MaterialMarkupId], [LaborMarkupId], [ChargesMarkupId], [FreightMarkupId], [ExclusionsMarkupId],
				[FreightRevenue], [LaborRevenue], [MaterialRevenue], [ExclusionsRevenue], [ChargesRevenue], [OverHeadCostRevenuePercentage], [QuoteParentId], [IsVersionIncrease], [QuoteMethod],
				[CommonFlatRate], [EvalFees]
		INTO #tmpWorkOrderQuoteDetailsResult
		FROM @tbl_WorkOrderQuoteDetailsType;

		SELECT	@MaterialBuildMethod = [MaterialBuildMethod], @MaterialFlatBillingAmount = [MaterialFlatBillingAmount], @LaborFlatBillingAmount = [LaborFlatBillingAmount], @ChargesFlatBillingAmount = [ChargesFlatBillingAmount],
				@QuoteMaterialCost = [MaterialCost], @QuoteOverHeadCost = [OverHeadCost], @MaterialMargin = [MaterialMargin], @LaborMargin = [LaborMargin], @ChargesMargin = [ChargesMargin], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId]
		FROM #tmpWorkOrderQuoteDetailsResult WHERE [RowId] = @InitialRowId;

		IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
		BEGIN
			DECLARE @MaterialBilling DECIMAL(18, 2), @MaterialCost DECIMAL(18, 2);

			SELECT @MaterialBilling = SUM(ISNULL(MaterialBilling, 0)), @MaterialCost = SUM(ISNULL(MaterialCost, 0)) FROM @tbl_WorkOrderQuoteTaskType GROUP BY WOPartNoId;

			IF(@MaterialBilling IS NOT NULL)
			BEGIN
				UPDATE TMP
				SET	TMP.MaterialBilling = ISNULL(@MaterialBilling, 0),
					TMP.MaterialRevenue = ISNULL(@MaterialBilling, 0),
					TMP.MaterialCost = ISNULL(@MaterialCost, 0),
					TMP.MaterialMargin = ISNULL(@MaterialBilling, 0) - ISNULL(@MaterialCost, 0),
					TMP.MaterialFlatBillingAmount = CASE WHEN ISNULL(@MaterialBuildMethod, 0) = @FlateRateBillMethod THEN @MaterialFlatBillingAmount ELSE ISNULL(@MaterialBilling, 0) END
				FROM #tmpWorkOrderQuoteDetailsResult TMP
			END
		END

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId)
		BEGIN
			UPDATE TMP
			SET 
				TMP.LaborBilling = WOQD.LaborBilling,
				TMP.LaborCost = WOQD.LaborCost,
				TMP.LaborRevenue = WOQD.LaborRevenue,
				TMP.LaborMargin = WOQD.LaborMargin,
				TMP.LaborMarginPer = WOQD.LaborMarginPer,
				TMP.LaborRevenuePercentage = WOQD.LaborRevenuePercentage,
				TMP.OverHeadCost = WOQD.OverHeadCost,
				TMP.LaborFlatBillingAmount = WOQD.LaborFlatBillingAmount,
				TMP.LaborBuildMethod = WOQD.LaborBuildMethod,
				TMP.ChargesBilling = WOQD.ChargesBilling,
				TMP.ChargesCost = WOQD.ChargesCost,
				TMP.ChargesRevenue = WOQD.ChargesRevenue,
				TMP.ChargesMargin = WOQD.ChargesMargin,
				TMP.ChargesMarginPer = WOQD.ChargesMarginPer,
				TMP.ChargesRevenuePercentage = WOQD.ChargesRevenuePercentage,
				TMP.ChargesFlatBillingAmount = WOQD.ChargesFlatBillingAmount,
				TMP.ChargesBuildMethod = WOQD.ChargesBuildMethod,
				TMP.FreightBilling = WOQD.FreightBilling,
				TMP.FreightCost = WOQD.FreightCost,
				TMP.FreightRevenue = WOQD.FreightRevenue,
				TMP.FreightMargin = WOQD.FreightMargin,
				TMP.FreightMarginPer = WOQD.FreightMarginPer,
				TMP.FreightRevenuePercentage = WOQD.FreightRevenuePercentage,
				TMP.FreightFlatBillingAmount = WOQD.FreightFlatBillingAmount,
				TMP.FreightBuildMethod = WOQD.FreightBuildMethod,
				TMP.ExclusionsBilling = WOQD.ExclusionsBilling,
				TMP.ExclusionsCost = WOQD.ExclusionsCost,
				TMP.ExclusionsRevenue = WOQD.ExclusionsRevenue,
				TMP.ExclusionsMargin = WOQD.ExclusionsMargin,
				TMP.ExclusionsMarginPer = WOQD.ExclusionsMarginPer,
				TMP.ExclusionsRevenuePercentage = WOQD.ExclusionsRevenuePercentage,
				TMP.ExclusionsBuildMethod = WOQD.ExclusionsBuildMethod,
				TMP.QuoteMethod = WOQD.QuoteMethod,
				TMP.CommonFlatRate = WOQD.CommonFlatRate
			FROM #tmpWorkOrderQuoteDetailsResult TMP
			INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) ON TMP.WorkOrderQuoteDetailsId = WOQD.WorkOrderQuoteDetailsId
		END

		SELECT	@MaterialFlatBillingAmount = [MaterialFlatBillingAmount], @LaborFlatBillingAmount = [LaborFlatBillingAmount], @ChargesFlatBillingAmount = [ChargesFlatBillingAmount],
				@QuoteMaterialCost = [MaterialCost], @QuoteOverHeadCost = [OverHeadCost], @MaterialMargin = [MaterialMargin], @LaborMargin = [LaborMargin], @ChargesMargin = [ChargesMargin], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId]
		FROM #tmpWorkOrderQuoteDetailsResult WHERE [RowId] = @InitialRowId;

		SET @totalRevenue = ISNULL(@MaterialFlatBillingAmount, 0) + ISNULL(@LaborFlatBillingAmount, 0) + ISNULL(@ChargesFlatBillingAmount, 0);
		SET @totalMargin = ISNULL(@MaterialMargin, 0) + ISNULL(@LaborMargin, 0) + ISNULL(@ChargesMargin, 0);

		UPDATE TMP
		SET	TMP.MaterialMarginPer = dbo.fn_GetMarginPercentage(@totalMargin, @totalRevenue),
			TMP.MaterialRevenuePercentage = dbo.fn_GetRevenuePercentage(@QuoteMaterialCost, @totalRevenue),
			TMP.OverHeadCostRevenuePercentage = dbo.fn_GetRevenuePercentage(@QuoteOverHeadCost, @totalRevenue)
		FROM #tmpWorkOrderQuoteDetailsResult TMP

		SELECT * FROM #tmpWorkOrderQuoteDetailsResult;

	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOQuoteDetails' 
		, @ProcedureParameters VARCHAR(3000) = ''
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