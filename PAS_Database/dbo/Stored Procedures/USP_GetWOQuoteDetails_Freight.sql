/*************************************************************           
 ** File:   [USP_GetWOQuoteDetails_Freight]           
 ** Author:   Devendra Shekh
 ** Description: This is used to get Work Order Quote Details after computing Amount for Freight
 ** Date:   27-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    27-May-2025   Devendra Shekh		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOQuoteDetails_Freight]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE	@WorkOrderQuoteDetailsId BIGINT, @FreightFlatBillingAmount  DECIMAL(18, 2), @QuoteOverHeadCost DECIMAL(18, 2),  @totalRevenue DECIMAL(18, 2), @totalMargin DECIMAL(18, 2),
				@MaterialMargin DECIMAL(18, 2), @LaborMargin DECIMAL(18, 2), @ChargesMargin DECIMAL(18, 2),
				@MaterialRevenue DECIMAL(18, 2), @LaborRevenue DECIMAL(18, 2), @ChargesRevenue DECIMAL(18, 2),
				@InitialRowId INT = 1, @FreightBuildMethod INT;
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

		SELECT	@FreightBuildMethod = [FreightBuildMethod], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId], @FreightFlatBillingAmount = [FreightFlatBillingAmount]
		FROM #tmpWorkOrderQuoteDetailsResult WHERE [RowId] = @InitialRowId;

		IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
		BEGIN
			DECLARE @FreightBilling DECIMAL(18, 2), @FreightCost DECIMAL(18, 2);

			SELECT @FreightBilling = SUM(ISNULL(FreightBilling, 0)), @FreightCost = SUM(ISNULL(FreightCost, 0)) FROM @tbl_WorkOrderQuoteTaskType GROUP BY WOPartNoId;

			IF(@FreightBilling IS NOT NULL)
			BEGIN
				UPDATE TMP
				SET	TMP.FreightBilling = ISNULL(@FreightBilling, 0),
					TMP.FreightRevenue = ISNULL(@FreightBilling, 0),
					TMP.FreightCost = ISNULL(@FreightCost, 0),
					TMP.FreightMargin = ISNULL(@FreightBilling, 0) - ISNULL(@FreightCost, 0),
					TMP.FreightFlatBillingAmount = CASE WHEN ISNULL(@FreightBuildMethod, 0) = @FlateRateBillMethod THEN @FreightFlatBillingAmount ELSE ISNULL(@FreightBilling, 0) END
				FROM #tmpWorkOrderQuoteDetailsResult TMP
			END
		END

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId)
		BEGIN
			UPDATE TMP
			SET
				TMP.MaterialBilling = WOQD.MaterialBilling,
				TMP.MaterialCost = WOQD.MaterialCost,
				TMP.MaterialRevenue = WOQD.MaterialRevenue,
				TMP.MaterialMargin = WOQD.MaterialMargin,
				TMP.MaterialMarginPer = WOQD.MaterialMarginPer,
				TMP.MaterialRevenuePercentage = WOQD.MaterialRevenuePercentage,
				TMP.MaterialFlatBillingAmount = WOQD.MaterialFlatBillingAmount,
				TMP.MaterialBuildMethod = WOQD.MaterialBuildMethod,

				TMP.LaborBilling = WOQD.LaborBilling,
				TMP.LaborCost = WOQD.LaborCost,
				TMP.LaborRevenue = WOQD.LaborRevenue,
				TMP.LaborMargin = WOQD.LaborMargin,
				TMP.LaborMarginPer = WOQD.LaborMarginPer,
				TMP.LaborRevenuePercentage = WOQD.LaborRevenuePercentage,
				TMP.OverHeadCost = WOQD.OverHeadCost,
				TMP.LaborFlatBillingAmount = WOQD.LaborFlatBillingAmount,
				TMP.LaborBuildMethod = WOQD.LaborBuildMethod,

				TMP.ExclusionsBilling = WOQD.ExclusionsBilling,
				TMP.ExclusionsCost = WOQD.ExclusionsCost,
				TMP.ExclusionsRevenue = WOQD.ExclusionsRevenue,
				TMP.ExclusionsMargin = WOQD.ExclusionsMargin,
				TMP.ExclusionsMarginPer = WOQD.ExclusionsMarginPer,
				TMP.ExclusionsRevenuePercentage = WOQD.ExclusionsRevenuePercentage,
				TMP.ExclusionsBuildMethod = WOQD.ExclusionsBuildMethod,

				TMP.ChargesBilling = WOQD.ChargesBilling,
				TMP.ChargesCost = WOQD.ChargesCost,
				TMP.ChargesRevenue = WOQD.ChargesRevenue,
				TMP.ChargesMargin = WOQD.ChargesMargin,
				TMP.ChargesMarginPer = WOQD.ChargesMarginPer,
				TMP.ChargesRevenuePercentage = WOQD.ChargesRevenuePercentage,
				TMP.ChargesFlatBillingAmount = WOQD.ChargesFlatBillingAmount,
				TMP.ChargesBuildMethod = WOQD.ChargesBuildMethod,

				TMP.QuoteMethod = WOQD.QuoteMethod,
				TMP.CommonFlatRate = WOQD.CommonFlatRate
			FROM #tmpWorkOrderQuoteDetailsResult TMP
			INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH (NOLOCK) ON TMP.WorkOrderQuoteDetailsId = WOQD.WorkOrderQuoteDetailsId
		END

		SELECT	@FreightCost = [FreightCost], @QuoteOverHeadCost = [OverHeadCost], @MaterialMargin = [MaterialMargin], @LaborMargin = [LaborMargin], @ChargesMargin = [ChargesMargin], @FreightFlatBillingAmount = [FreightFlatBillingAmount],
				@MaterialRevenue = [MaterialRevenue], @LaborRevenue = [LaborRevenue], @ChargesRevenue = [ChargesRevenue], @FreightBilling = [FreightBilling]
		FROM #tmpWorkOrderQuoteDetailsResult WHERE [RowId] = @InitialRowId;

		SET @totalRevenue = ISNULL(@MaterialRevenue, 0) + ISNULL(@LaborRevenue, 0) + ISNULL(@ChargesRevenue, 0);
		SET @totalMargin = ISNULL(@MaterialMargin, 0) + ISNULL(@LaborMargin, 0) + ISNULL(@ChargesMargin, 0);

		UPDATE TMP
		SET	TMP.ExclusionsMarginPer = dbo.fn_GetMarginPercentage(@totalMargin, @totalRevenue),
			TMP.ExclusionsRevenuePercentage = dbo.fn_GetRevenuePercentage(@FreightCost, @totalRevenue),
			TMP.OverHeadCostRevenuePercentage = dbo.fn_GetRevenuePercentage(@QuoteOverHeadCost, @totalRevenue),
			TMP.FreightFlatBillingAmount = CASE WHEN ISNULL(@FreightBuildMethod, 0) = @FlateRateBillMethod THEN @FreightFlatBillingAmount ELSE ISNULL(@FreightBilling, 0) END
		FROM #tmpWorkOrderQuoteDetailsResult TMP

		SELECT * FROM #tmpWorkOrderQuoteDetailsResult;

	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOQuoteDetails_Freight' 
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