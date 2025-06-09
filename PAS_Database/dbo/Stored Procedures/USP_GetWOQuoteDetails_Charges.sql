/*************************************************************           
 ** File:   [USP_GetWOQuoteDetails_Charges]           
 ** Author:   Devendra Shekh
 ** Description: This is used to get Work Order Quote Details after computing Amount for Charges
 ** Date:   09-June-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    09-June-2025   Devendra Shekh		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOQuoteDetails_Charges]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE	@WorkOrderQuoteDetailsId BIGINT, @ChargesFlatBillingAmount  DECIMAL(18, 2), @QuoteOverHeadCost DECIMAL(18, 2),  @totalRevenue DECIMAL(18, 2), @totalMargin DECIMAL(18, 2),
				@MaterialMargin DECIMAL(18, 2), @LaborMargin DECIMAL(18, 2), @ChargesMargin DECIMAL(18, 2),
				@MaterialFlatBillingAmount DECIMAL(18, 2), @LaborFlatBillingAmount DECIMAL(18, 2),
				@InitialRowId INT = 1, @ChargesBuildMethod INT;
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

		SELECT	@ChargesBuildMethod = [ChargesBuildMethod], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId], @ChargesFlatBillingAmount = [ChargesFlatBillingAmount]
		FROM #tmpWorkOrderQuoteDetailsResult WHERE [RowId] = @InitialRowId;

		IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
		BEGIN
			DECLARE @ChargesBilling DECIMAL(18, 2), @ChargesCost DECIMAL(18, 2);

			SELECT @ChargesBilling = SUM(ISNULL(ChargesBilling, 0)), @ChargesCost = SUM(ISNULL(ChargesCost, 0)) FROM @tbl_WorkOrderQuoteTaskType GROUP BY WOPartNoId;

			IF(@ChargesBilling IS NOT NULL)
			BEGIN
				UPDATE TMP
				SET	TMP.ChargesBilling = ISNULL(@ChargesBilling, 0),
					TMP.ChargesRevenue = ISNULL(@ChargesBilling, 0),
					TMP.ChargesCost = ISNULL(@ChargesCost, 0),
					TMP.ChargesMargin = ISNULL(@ChargesBilling, 0) - ISNULL(@ChargesCost, 0),
					TMP.ChargesFlatBillingAmount = CASE WHEN ISNULL(@ChargesBuildMethod, 0) = @FlateRateBillMethod THEN @ChargesFlatBillingAmount ELSE ISNULL(@ChargesBilling, 0) END
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
			INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH (NOLOCK) ON TMP.WorkOrderQuoteDetailsId = WOQD.WorkOrderQuoteDetailsId
		END

		SELECT	@ChargesCost = [ChargesCost], @QuoteOverHeadCost = [OverHeadCost], @MaterialMargin = [MaterialMargin], @LaborMargin = [LaborMargin], @ChargesMargin = [ChargesMargin], @ChargesFlatBillingAmount = [ChargesFlatBillingAmount],
				@MaterialFlatBillingAmount = [MaterialFlatBillingAmount], @LaborFlatBillingAmount = [LaborFlatBillingAmount], @ChargesFlatBillingAmount = [ChargesFlatBillingAmount], @ChargesBilling = [ChargesBilling]
		FROM #tmpWorkOrderQuoteDetailsResult WHERE [RowId] = @InitialRowId;

		SET @totalRevenue = ISNULL(@MaterialFlatBillingAmount, 0) + ISNULL(@LaborFlatBillingAmount, 0) + ISNULL(@ChargesFlatBillingAmount, 0);
		SET @totalMargin = ISNULL(@MaterialMargin, 0) + ISNULL(@LaborMargin, 0) + ISNULL(@ChargesMargin, 0);

		UPDATE TMP
		SET	TMP.ChargesMarginPer = dbo.fn_GetMarginPercentage(@totalMargin, @totalRevenue),
			TMP.ChargesRevenuePercentage = dbo.fn_GetRevenuePercentage(@ChargesCost, @totalRevenue),
			TMP.OverHeadCostRevenuePercentage = dbo.fn_GetRevenuePercentage(@QuoteOverHeadCost, @totalRevenue)
		FROM #tmpWorkOrderQuoteDetailsResult TMP

		SELECT * FROM #tmpWorkOrderQuoteDetailsResult;

	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOQuoteDetails_Charges' 
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