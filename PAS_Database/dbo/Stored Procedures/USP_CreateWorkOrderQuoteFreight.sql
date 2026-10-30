/*************************************************************           
 ** File:   [USP_CreateWorkOrderQuoteFreight]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Create work Order Quote Freight
 ** Date:   27-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    27-May-2025   Devendra Shekh		Created
    2    28-Oct-2026   Divyesh Kathiriya    Added freight history for new entries and transfers from WO for each selected MPN [PN-18341].
	 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderQuoteFreight]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteFreightType [WorkOrderQuoteFreightType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY,
@tbl_FreightHistoryType [FreightHistoryType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION  

		DECLARE @WorkflowWorkOrderId BIGINT, @woPartNoId BIGINT, @ItemMasterId BIGINT, @WorkOrderQuoteDetailsId BIGINT, @InitialRowId INT = 1, @WorkOrderQuoteId BIGINT, @UpdatedBy VARCHAR(256), @workorderId BIGINT;
		DECLARE @WorkOrderQuoteLaborHeaderId BIGINT, @MasterCompanyId INT, @IsVersionIncrease BIT;

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteDetails') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteDetails;

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteFreight') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteFreight;

		SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteDetailsId], [WorkOrderQuoteId], [ItemMasterId], [BuildMethodId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
				[WorkflowWorkOrderId], [WOPartNoId], [MaterialCost], [MaterialBilling], [MaterialRevenuePercentage], [MaterialMargin], [LaborHours], [LaborCost], [LaborBilling], [LaborRevenuePercentage],
				[LaborMargin], [ChargesCost], [ChargesBilling], [ChargesRevenuePercentage], [ChargesMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenuePercentage], [ExclusionsMargin],
				[FreightCost], [FreightBilling], [FreightRevenuePercentage], [FreightMargin], [MaterialMarginPer], [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer],
				[OverHeadCost], [AdjustmentHours], [AdjustedHours], [LaborFlatBillingAmount], [MaterialFlatBillingAmount], [ChargesFlatBillingAmount], [FreightFlatBillingAmount], [MaterialBuildMethod],
				[LaborBuildMethod], [ChargesBuildMethod], [FreightBuildMethod], [ExclusionsBuildMethod], [MaterialMarkupId], [LaborMarkupId], [ChargesMarkupId], [FreightMarkupId], [ExclusionsMarkupId],
				[FreightRevenue], [LaborRevenue], [MaterialRevenue], [ExclusionsRevenue], [ChargesRevenue], [OverHeadCostRevenuePercentage], [QuoteParentId], [IsVersionIncrease], [QuoteMethod],
				[CommonFlatRate], [EvalFees]
		INTO #tmpWorkOrderQuoteDetails
		FROM @tbl_WorkOrderQuoteDetailsType;

		SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteFreightId], [WorkOrderQuoteDetailsId], [ShipViaId], [Weight], [Memo], [Amount], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
				[UpdatedDate], [IsActive], [IsDeleted], [MarkupPercentageId], [MarkupFixedPrice], [TaskId], [HeaderMarkupId], [BillingRate], [BillingAmount], [Length], [Width], [Height], [UOMId], [DimensionUOMId],
				[CurrencyId], [BillingMethodId], [TaskName], [Shipvia], [UomName], [DimensionUomName], [Currency], [BillingName], [MarkUp]
		INTO #tmpWorkOrderQuoteFreight
		FROM @tbl_WorkOrderQuoteFreightType;

		UPDATE #tmpWorkOrderQuoteDetails SET [UpdatedDate] = GETUTCDATE();

		UPDATE TMPF
		SET	TMPF.[CreatedDate] = CASE WHEN ISNULL(TMPF.[WorkOrderQuoteFreightId], 0) > 0 THEN TMPF.[CreatedDate] ELSE GETUTCDATE() END,
			TMPF.[UpdatedDate] = GETUTCDATE(),
			TMPF.[IsActive] = 1,
			TMPF.[IsDeleted] = CASE WHEN ISNULL(TMPF.[WorkOrderQuoteFreightId], 0) > 0 THEN TMPF.[IsDeleted] ELSE 0 END,
			TMPF.[MarkupPercentageId] = CASE WHEN ISNULL(TMPF.[MarkupPercentageId], 0) = 0 THEN NULL ELSE TMPF.[MarkupPercentageId] END,
			TMPF.[DimensionUOMId] = CASE WHEN ISNULL(TMPF.[DimensionUOMId], 0) = 0 THEN NULL ELSE TMPF.[DimensionUOMId] END,
			TMPF.[UOMId] = CASE WHEN ISNULL(TMPF.[UOMId], 0) = 0 THEN NULL ELSE TMPF.[UOMId] END,
			TMPF.[CurrencyId] = CASE WHEN ISNULL(TMPF.[CurrencyId], 0) = 0 THEN NULL ELSE TMPF.[CurrencyId] END
		FROM #tmpWorkOrderQuoteFreight TMPF

		SELECT	@WorkflowWorkOrderId = [WorkflowWorkOrderId], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId], @WorkOrderQuoteId = [WorkOrderQuoteId], @UpdatedBy = [UpdatedBy], @MasterCompanyId = [MasterCompanyId],
				@IsVersionIncrease = ISNULL([IsVersionIncrease], 0)
		FROM #tmpWorkOrderQuoteDetails WHERE [RowId] = @InitialRowId;

		SET @woPartNoId = (SELECT TOP 1 [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId);
		SET @ItemMasterId = (SELECT TOP 1 [ItemMasterId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId);
		SET @WorkOrderQuoteDetailsId = (SELECT TOP 1 [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId);
		SET @workorderId = (SELECT TOP 1 [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId);

		DECLARE @PreviousFreightHistory TABLE ([WorkOrderQuoteFreightId] BIGINT PRIMARY KEY, [TaskId] BIGINT, [Amount] DECIMAL(20,3));

		INSERT INTO @PreviousFreightHistory ([WorkOrderQuoteFreightId], [TaskId], [Amount])
		SELECT WOQF.[WorkOrderQuoteFreightId], WOQF.[TaskId], WOQF.[Amount]
		FROM [DBO].[WorkOrderQuoteFreight] WOQF WITH(NOLOCK)
		INNER JOIN @tbl_WorkOrderQuoteFreightType TMPF ON WOQF.[WorkOrderQuoteFreightId] = TMPF.[WorkOrderQuoteFreightId]
			AND WOQF.[MasterCompanyId] = TMPF.[MasterCompanyId]
		WHERE WOQF.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId AND WOQF.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(WOQF.[IsDeleted], 0) = 0;

		IF(ISNULL(@WorkOrderQuoteDetailsId, 0) > 0)
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;

			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails_Freight] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteTaskType;

			--DELETE FROM [dbo].[WorkOrderQuoteFreight] WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;		

			UPDATE WOQF
			SET
				WOQF.ShipViaId = TMPF.ShipViaId,
				WOQF.Weight = TMPF.Weight,
				WOQF.Memo = TMPF.Memo,
				WOQF.Amount = TMPF.Amount,
				WOQF.MasterCompanyId = TMPF.MasterCompanyId,
				WOQF.UpdatedBy = TMPF.UpdatedBy,
				WOQF.UpdatedDate = TMPF.UpdatedDate,
				WOQF.IsActive = TMPF.IsActive,
				WOQF.IsDeleted = TMPF.IsDeleted,
				WOQF.MarkupPercentageId = TMPF.MarkupPercentageId,
				WOQF.MarkupFixedPrice = TMPF.MarkupFixedPrice,
				WOQF.TaskId = TMPF.TaskId,
				WOQF.HeaderMarkupId = TMPF.HeaderMarkupId,
				WOQF.BillingRate = TMPF.BillingRate,
				WOQF.BillingAmount = TMPF.BillingAmount,
				WOQF.Length = TMPF.Length,
				WOQF.Width = TMPF.Width,
				WOQF.Height = TMPF.Height,
				WOQF.UOMId = TMPF.UOMId,
				WOQF.DimensionUOMId = TMPF.DimensionUOMId,
				WOQF.CurrencyId = TMPF.CurrencyId,
				WOQF.BillingMethodId = TMPF.BillingMethodId,
				WOQF.TaskName = TMPF.TaskName,
				WOQF.Shipvia = TMPF.Shipvia,
				WOQF.UomName = TMPF.UomName,
				WOQF.DimensionUomName = TMPF.DimensionUomName,
				WOQF.Currency = TMPF.Currency,
				WOQF.BillingName = TMPF.BillingName,
				WOQF.MarkUp = TMPF.MarkUp
			FROM [dbo].[WorkOrderQuoteFreight] WOQF WITH(NOLOCK)
			JOIN #tmpWorkOrderQuoteFreight TMPF ON WOQF.WorkOrderQuoteFreightId = TMPF.WorkOrderQuoteFreightId
			WHERE TMPF.WorkOrderQuoteFreightId > 0;

			INSERT INTO [dbo].[WorkOrderQuoteFreight]
			SELECT	[WorkOrderQuoteDetailsId], [ShipViaId], [Weight], [Memo], [Amount], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[MarkupPercentageId], [MarkupFixedPrice], [TaskId], [HeaderMarkupId], [BillingRate], [BillingAmount], [Length], [Width], [Height], [UOMId], [DimensionUOMId], [CurrencyId], [BillingMethodId], [TaskName],
					[Shipvia], [UomName], [DimensionUomName], [Currency], [BillingName], [MarkUp]
			FROM #tmpWorkOrderQuoteFreight WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteFreightId, 0) = 0

			UPDATE TMP
			SET	TMP.WOPartNoId = @woPartNoId, TMP.ItemMasterId = CASE WHEN ISNULL(TMP.ItemMasterId, 0) = 0 THEN @ItemMasterId ELSE TMP.ItemMasterId END, TMP.IsDeleted = 0
			FROM #tmpWorkOrderQuoteDetails TMP

			-- Updating Work Order Quote Details
			UPDATE woq
			SET 
				woq.WorkOrderQuoteId = tmp.WorkOrderQuoteId,
				woq.ItemMasterId = tmp.ItemMasterId,
				woq.BuildMethodId = tmp.BuildMethodId,
				woq.MasterCompanyId = tmp.MasterCompanyId,
				woq.UpdatedBy = tmp.UpdatedBy,
				woq.UpdatedDate = tmp.UpdatedDate,
				woq.IsActive = tmp.IsActive,
				woq.IsDeleted = tmp.IsDeleted,
				woq.WorkflowWorkOrderId = tmp.WorkflowWorkOrderId,
				woq.WOPartNoId = tmp.WOPartNoId,
				woq.MaterialCost = tmp.MaterialCost,
				woq.MaterialBilling = tmp.MaterialBilling,
				woq.MaterialRevenuePercentage = tmp.MaterialRevenuePercentage,
				woq.MaterialMargin = tmp.MaterialMargin,
				woq.LaborHours = tmp.LaborHours,
				woq.LaborCost = tmp.LaborCost,
				woq.LaborBilling = tmp.LaborBilling,
				woq.LaborRevenuePercentage = tmp.LaborRevenuePercentage,
				woq.LaborMargin = tmp.LaborMargin,
				woq.ChargesCost = tmp.ChargesCost,
				woq.ChargesBilling = tmp.ChargesBilling,
				woq.ChargesRevenuePercentage = tmp.ChargesRevenuePercentage,
				woq.ChargesMargin = tmp.ChargesMargin,
				woq.ExclusionsCost = tmp.ExclusionsCost,
				woq.ExclusionsBilling = tmp.ExclusionsBilling,
				woq.ExclusionsRevenuePercentage = tmp.ExclusionsRevenuePercentage,
				woq.ExclusionsMargin = tmp.ExclusionsMargin,
				woq.FreightCost = tmp.FreightCost,
				woq.FreightBilling = tmp.FreightBilling,
				woq.FreightRevenuePercentage = tmp.FreightRevenuePercentage,
				woq.FreightMargin = tmp.FreightMargin,
				woq.MaterialMarginPer = tmp.MaterialMarginPer,
				woq.LaborMarginPer = tmp.LaborMarginPer,
				woq.ChargesMarginPer = tmp.ChargesMarginPer,
				woq.ExclusionsMarginPer = tmp.ExclusionsMarginPer,
				woq.FreightMarginPer = tmp.FreightMarginPer,
				woq.OverHeadCost = tmp.OverHeadCost,
				woq.AdjustmentHours = tmp.AdjustmentHours,
				woq.AdjustedHours = tmp.AdjustedHours,
				woq.LaborFlatBillingAmount = tmp.LaborFlatBillingAmount,
				woq.MaterialFlatBillingAmount = tmp.MaterialFlatBillingAmount,
				woq.ChargesFlatBillingAmount = tmp.ChargesFlatBillingAmount,
				woq.FreightFlatBillingAmount = tmp.FreightFlatBillingAmount,
				woq.MaterialBuildMethod = tmp.MaterialBuildMethod,
				woq.LaborBuildMethod = tmp.LaborBuildMethod,
				woq.ChargesBuildMethod = tmp.ChargesBuildMethod,
				woq.FreightBuildMethod = tmp.FreightBuildMethod,
				woq.ExclusionsBuildMethod = tmp.ExclusionsBuildMethod,
				woq.MaterialMarkupId = tmp.MaterialMarkupId,
				woq.LaborMarkupId = tmp.LaborMarkupId,
				woq.ChargesMarkupId = tmp.ChargesMarkupId,
				woq.FreightMarkupId = tmp.FreightMarkupId,
				woq.ExclusionsMarkupId = tmp.ExclusionsMarkupId,
				woq.FreightRevenue = tmp.FreightRevenue,
				woq.LaborRevenue = tmp.LaborRevenue,
				woq.MaterialRevenue = tmp.MaterialRevenue,
				woq.ExclusionsRevenue = tmp.ExclusionsRevenue,
				woq.ChargesRevenue = tmp.ChargesRevenue,
				woq.OverHeadCostRevenuePercentage = tmp.OverHeadCostRevenuePercentage,
				woq.QuoteParentId = tmp.QuoteParentId,
				woq.IsVersionIncrease = 0,
				woq.QuoteMethod = tmp.QuoteMethod,
				woq.CommonFlatRate = tmp.CommonFlatRate,
				woq.EvalFees = tmp.EvalFees
			FROM [dbo].[WorkOrderQuoteDetails] woq WITH(NOLOCK)
			JOIN #tmpWorkOrderQuoteDetails tmp ON woq.WorkOrderQuoteDetailsId = tmp.WorkOrderQuoteDetailsId WHERE tmp.WorkOrderQuoteDetailsId > 0;
			
			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
			BEGIN
				-- Updating WorkOrderQuoteTask Details
				UPDATE WQT
				SET 
					WQT.UpdatedDate = GETUTCDATE(),
					WQT.FreightBilling = T.FreightBilling,
					WQT.FreightCost = T.FreightCost,
					WQT.FreightMargin = T.FreightBilling - T.FreightCost,
					WQT.FreightRevenue = T.FreightBilling,
					WQT.FreightRevenuePercentage = dbo.fn_GetRevenuePercentage(T.FreightCost, T.FreightBilling),
					WQT.FreightMarginPer = dbo.fn_GetMarginPercentage((T.FreightBilling - T.FreightCost), T.FreightBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;
				
				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ChargesMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[FreightMargin]
						,[FreightRevenue]
						,[FreightRevenuePercentage]
						,[FreightMarginPer]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [ChargesMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[FreightBilling] - [FreightCost]
						,[FreightBilling]
						,dbo.fn_GetRevenuePercentage([FreightCost], [FreightBilling])
						,dbo.fn_GetMarginPercentage(([FreightBilling] - [FreightCost]), [FreightBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0
			END
		END
		ELSE
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;
			
			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails_Freight] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteTaskType;

			UPDATE TMP
			SET	TMP.WOPartNoId = @woPartNoId, TMP.ItemMasterId = CASE WHEN ISNULL(TMP.ItemMasterId, 0) = 0 THEN @ItemMasterId ELSE TMP.ItemMasterId END,
				TMP.CreatedDate = GETUTCDATE(),
				TMP.UpdatedDate = GETUTCDATE(),
				TMP.IsActive = 1,
				TMP.IsDeleted = 0
			FROM #tmpWorkOrderQuoteDetails TMP

			INSERT INTO	[dbo].[WorkOrderQuoteDetails] ([WorkOrderQuoteId], [ItemMasterId], [BuildMethodId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
					[IsActive], [IsDeleted], [WorkflowWorkOrderId], [WOPartNoId], [MaterialCost], [MaterialBilling], [MaterialRevenuePercentage], [MaterialMargin], [LaborHours],
					[LaborCost], [LaborBilling], [LaborRevenuePercentage], [LaborMargin], [ChargesCost], [ChargesBilling], [ChargesRevenuePercentage], [ChargesMargin],
					[ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenuePercentage], [ExclusionsMargin], [FreightCost], [FreightBilling], [FreightRevenuePercentage],
					[FreightMargin], [MaterialMarginPer], [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer], [OverHeadCost], [AdjustmentHours],
					[AdjustedHours], [LaborFlatBillingAmount], [MaterialFlatBillingAmount], [ChargesFlatBillingAmount], [FreightFlatBillingAmount], [MaterialBuildMethod], 
					[LaborBuildMethod], [ChargesBuildMethod], [FreightBuildMethod], [ExclusionsBuildMethod], [MaterialMarkupId], [LaborMarkupId], [ChargesMarkupId], 
					[FreightMarkupId], [ExclusionsMarkupId], [FreightRevenue], [LaborRevenue], [MaterialRevenue], [ExclusionsRevenue], [ChargesRevenue], 
					[OverHeadCostRevenuePercentage], [QuoteParentId], [IsVersionIncrease], [QuoteMethod], [CommonFlatRate], [EvalFees]
			)
			SELECT	[WorkOrderQuoteId], [ItemMasterId], [BuildMethodId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
					[IsActive], [IsDeleted], [WorkflowWorkOrderId], [WOPartNoId], [MaterialCost], [MaterialBilling], [MaterialRevenuePercentage], [MaterialMargin], [LaborHours],
					[LaborCost], [LaborBilling], [LaborRevenuePercentage], [LaborMargin], [ChargesCost], [ChargesBilling], [ChargesRevenuePercentage], [ChargesMargin],
					[ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenuePercentage], [ExclusionsMargin], [FreightCost], [FreightBilling], [FreightRevenuePercentage],
					[FreightMargin], [MaterialMarginPer], [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer], [OverHeadCost], [AdjustmentHours],
					[AdjustedHours], [LaborFlatBillingAmount], [MaterialFlatBillingAmount], [ChargesFlatBillingAmount], [FreightFlatBillingAmount], [MaterialBuildMethod], 
					[LaborBuildMethod], [ChargesBuildMethod], [FreightBuildMethod], [ExclusionsBuildMethod], [MaterialMarkupId], [LaborMarkupId], [ChargesMarkupId], 
					[FreightMarkupId], [ExclusionsMarkupId], [FreightRevenue], [LaborRevenue], [MaterialRevenue], [ExclusionsRevenue], [ChargesRevenue], 
					[OverHeadCostRevenuePercentage], [QuoteParentId], 0, [QuoteMethod], [CommonFlatRate], [EvalFees]
			FROM #tmpWorkOrderQuoteDetails;

			SET @WorkOrderQuoteDetailsId = SCOPE_IDENTITY();

			INSERT INTO [dbo].[WorkOrderQuoteFreight]
			SELECT	@WorkOrderQuoteDetailsId AS WorkOrderQuoteDetailsId, [ShipViaId], [Weight], [Memo], [Amount], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[MarkupPercentageId], [MarkupFixedPrice], [TaskId], [HeaderMarkupId], [BillingRate], [BillingAmount], [Length], [Width], [Height], [UOMId], [DimensionUOMId], [CurrencyId], [BillingMethodId], [TaskName],
					[Shipvia], [UomName], [DimensionUomName], [Currency], [BillingName], [MarkUp]
			FROM #tmpWorkOrderQuoteFreight WHERE ISNULL(IsDeleted, 0) = 0

			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
			BEGIN
				-- Updating WorkOrderQuoteTask Details
				UPDATE WQT
				SET 
					WQT.UpdatedDate = GETUTCDATE(),
					WQT.FreightBilling = T.FreightBilling,
					WQT.FreightCost = T.FreightCost,
					WQT.FreightMargin = T.FreightBilling - T.FreightCost,
					WQT.FreightRevenue = T.FreightBilling,
					WQT.FreightRevenuePercentage = dbo.fn_GetRevenuePercentage(T.FreightCost, T.FreightBilling),
					WQT.FreightMarginPer = dbo.fn_GetMarginPercentage((T.FreightBilling - T.FreightCost), T.FreightBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;
				
				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ChargesMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[FreightMargin]
						,[FreightRevenue]
						,[FreightRevenuePercentage]
						,[FreightMarginPer]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [ChargesMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[FreightBilling] - [FreightCost]
						,[FreightBilling]
						,dbo.fn_GetRevenuePercentage([FreightCost], [FreightBilling])
						,dbo.fn_GetMarginPercentage(([FreightBilling] - [FreightCost]), [FreightBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0
			END
		END
		
		EXEC [dbo].[USP_ChangeWOQStatusAfterApproval] @WorkOrderQuoteId, @UpdatedBy, @woPartNoId;

		EXEC [dbo].[USP_UpdateWOTotalCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateWOCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId

		EXEC [dbo].[UpdateWorkOrderQuoteVersionNo] @WorkOrderQuoteId, @IsVersionIncrease;

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteFreight] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId)
		BEGIN
			DECLARE @TotalRows INT, @CurrentRowId INT, @TMPWorkOrderQuoteFreightId BIGINT, @TableName VARCHAR(50) = 'workorderquotefreight';

			IF OBJECT_ID('tempdb..#tmpWOQFreight') IS NOT NULL
				DROP TABLE #tmpWOQFreight;

			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteFreightId] INTO #tmpWOQFreight
			FROM [dbo].[WorkOrderQuoteFreight] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId

			SELECT @TotalRows = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWOQFreight;

			IF(ISNULL(@TotalRows, 0) > 0)
			BEGIN
				WHILE(@TotalRows >= @CurrentRowId)
				BEGIN
					SELECT @TMPWorkOrderQuoteFreightId = [WorkOrderQuoteFreightId] FROM #tmpWOQFreight WHERE [RowId] = @CurrentRowId;

					EXEC [dbo].[UpdateWorkOrderQuoteTable] @TableName, @TMPWorkOrderQuoteFreightId;

					SET @CurrentRowId += 1;
				END
			END
		END

		DECLARE @ChangedFreightHistory TABLE ([TaskId] BIGINT, [OldValue] VARCHAR(60), [NewValue] VARCHAR(60), [UpdatedBy] VARCHAR(256), [StatusCode] VARCHAR(256));

		INSERT INTO @ChangedFreightHistory ([TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode])
		SELECT CASE WHEN ISNULL(WOQF.[IsDeleted], 0) = 1 THEN P.[TaskId] ELSE WOQF.[TaskId] END,
			CASE WHEN ISNULL(WOQF.[IsDeleted], 0) = 1 THEN '' ELSE CONVERT(VARCHAR(60), P.[Amount]) END,
			CASE WHEN ISNULL(WOQF.[IsDeleted], 0) = 1 THEN '' ELSE CONVERT(VARCHAR(60), WOQF.[Amount]) END,
			COALESCE(NULLIF(WOQF.[UpdatedBy], ''), @UpdatedBy),
			CASE WHEN ISNULL(WOQF.[IsDeleted], 0) = 1 THEN 'WorkOrderQuoteFreightRemoved' ELSE 'WorkOrderQuoteFreightUpdated' END
		FROM @PreviousFreightHistory P
		INNER JOIN [DBO].[WorkOrderQuoteFreight] WOQF WITH(NOLOCK) ON P.[WorkOrderQuoteFreightId] = WOQF.[WorkOrderQuoteFreightId]
			AND WOQF.[MasterCompanyId] = @MasterCompanyId
		WHERE ISNULL(WOQF.[IsDeleted], 0) = 1 OR ISNULL(P.[Amount], 0) <> ISNULL(WOQF.[Amount], 0);

		IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteFreightType WHERE ISNULL([WorkOrderQuoteFreightId], 0) = 0 AND ISNULL([IsDeleted], 0) = 0)
			OR EXISTS(SELECT 1 FROM @ChangedFreightHistory)
		BEGIN
			DECLARE @FreightHistoryModuleId BIGINT, @FreightHistoryQuoteId BIGINT, @FreightHistoryPartId BIGINT, @FreightHistoryFormTypeId BIT;
			DECLARE @FreightHistoryRowId INT = 1, @FreightHistoryRowCount INT;
			DECLARE @FreightHistoryStatusCode VARCHAR(256), @FreightHistoryText VARCHAR(MAX), @FreightHistoryOldValue VARCHAR(60), @FreightHistoryNewValue VARCHAR(60), @FreightHistoryActor VARCHAR(256);
			DECLARE @AddedFreightHistory TABLE ([RowId] INT IDENTITY(1,1), [TaskId] BIGINT, [Amount] DECIMAL(20,3), [UpdatedBy] VARCHAR(256), [StatusCode] VARCHAR(256), [OldValue] VARCHAR(60), [NewValue] VARCHAR(60));

			SELECT @FreightHistoryModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WOQuote';
			SELECT @FreightHistoryQuoteId = Q.[WorkOrderQuoteId], @FreightHistoryPartId = D.[WOPartNoId], @FreightHistoryFormTypeId = WO.[WorkOrderFormTypeId]
			FROM [DBO].[WorkOrderQuoteDetails] D WITH(NOLOCK)
			INNER JOIN [DBO].[WorkOrderQuote] Q WITH(NOLOCK) ON D.[WorkOrderQuoteId] = Q.[WorkOrderQuoteId] AND D.[MasterCompanyId] = Q.[MasterCompanyId]
			INNER JOIN [DBO].[WorkOrder] WO WITH(NOLOCK) ON Q.[WorkOrderId] = WO.[WorkOrderId] AND Q.[MasterCompanyId] = WO.[MasterCompanyId]
			WHERE D.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId AND D.[MasterCompanyId] = @MasterCompanyId;

			IF NOT EXISTS (SELECT 1 FROM @tbl_FreightHistoryType)
			BEGIN
				INSERT INTO @AddedFreightHistory ([TaskId], [Amount], [UpdatedBy], [StatusCode])
				SELECT F.[TaskId], F.[Amount], COALESCE(NULLIF(F.[UpdatedBy], ''), @UpdatedBy), 'WorkOrderQuoteFreightAdded'
				FROM @tbl_WorkOrderQuoteFreightType F
				WHERE ISNULL(F.[WorkOrderQuoteFreightId], 0) = 0 AND ISNULL(F.[IsDeleted], 0) = 0 AND F.[MasterCompanyId] = @MasterCompanyId;
			END
			ELSE
			BEGIN
				INSERT INTO @AddedFreightHistory ([TaskId], [Amount], [UpdatedBy], [StatusCode])
				SELECT F.[TaskId], F.[Amount], COALESCE(NULLIF(F.[UpdatedBy], ''), @UpdatedBy),
					CASE WHEN ISNULL(F.[IsTransferredFromWO], 0) = 1 THEN 'WorkOrderQuoteFreightTransferredFromWO' ELSE 'WorkOrderQuoteFreightAdded' END
				FROM @tbl_FreightHistoryType F
				WHERE F.[MasterCompanyId] = @MasterCompanyId
					AND EXISTS (SELECT 1 FROM @tbl_WorkOrderQuoteFreightType T
						WHERE T.[TaskId] = F.[TaskId] AND T.[Amount] = F.[Amount] AND T.[MasterCompanyId] = F.[MasterCompanyId]
							AND ISNULL(T.[WorkOrderQuoteFreightId], 0) = 0 AND ISNULL(T.[IsDeleted], 0) = 0);
			END
			INSERT INTO @AddedFreightHistory ([TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode])
			SELECT [TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode] FROM @ChangedFreightHistory;

			SELECT @FreightHistoryRowCount = COUNT(*) FROM @AddedFreightHistory;

			WHILE @FreightHistoryRowId <= @FreightHistoryRowCount
			BEGIN
				SET @FreightHistoryText = NULL;
				SELECT @FreightHistoryText = REPLACE(HT.[TemplateBody], '##TASKNAME##',
					COALESCE(NULLIF(CASE WHEN ISNULL(@FreightHistoryFormTypeId, 0) = 1 THEN WOT.[TaskName] ELSE T.[Description] END, ''),
						NULLIF(T.[Description], ''), CONVERT(VARCHAR(60), H.[TaskId]))),
					@FreightHistoryOldValue = COALESCE(H.[OldValue], '0'), @FreightHistoryNewValue = COALESCE(H.[NewValue], CONVERT(VARCHAR(60), H.[Amount])),
					@FreightHistoryActor = H.[UpdatedBy], @FreightHistoryStatusCode = H.[StatusCode]
				FROM @AddedFreightHistory H
				INNER JOIN [DBO].[HistoryTemplate] HT WITH(NOLOCK) ON H.[StatusCode] = HT.[TemplateCode]
				LEFT JOIN [DBO].[WorkOrderTask] WOT WITH(NOLOCK) ON H.[TaskId] = WOT.[WorkOrderTaskId]
					AND WOT.[WorkOrderId] = @workorderId AND WOT.[WorkOrderPartNumberId] = @FreightHistoryPartId AND WOT.[MasterCompanyId] = @MasterCompanyId
				LEFT JOIN [DBO].[Task] T WITH(NOLOCK) ON H.[TaskId] = T.[TaskId] AND T.[MasterCompanyId] = @MasterCompanyId
				WHERE H.[RowId] = @FreightHistoryRowId;

				EXEC [DBO].[USP_History] @ModuleId = @FreightHistoryModuleId, @RefferenceId = @FreightHistoryQuoteId,
					@SubModuleId = 0, @SubRefferenceId = @FreightHistoryPartId, @OldValue = @FreightHistoryOldValue, @NewValue = @FreightHistoryNewValue,
					@HistoryText = @FreightHistoryText, @StatusCode = @FreightHistoryStatusCode, @MasterCompanyId = @MasterCompanyId,
					@CreatedBy = @FreightHistoryActor, @UpdatedBy = @FreightHistoryActor;
				SET @FreightHistoryRowId += 1;
			END
		END

		SELECT * FROM [DBO].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteFreight] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteTask] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId;

	COMMIT TRANSACTION  
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderQuoteFreight' 
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