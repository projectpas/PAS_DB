/*************************************************************           
 ** File:   [USP_CreateWorkOrderQuoteCharges]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Create work Order Quote Charges
 ** Date:   09-June-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    09-June-2025   Devendra Shekh		Created
    2    28-Oct-2026   Divyesh Kathiriya    Added charges quantity history for new entries and transfers from WO for each selected MPN [PN-18341].
	 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderQuoteCharges]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteChargesType [WorkOrderQuoteChargesType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY,
@tbl_ChargesHistoryType [ChargesHistoryType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION  

		DECLARE @WorkflowWorkOrderId BIGINT, @woPartNoId BIGINT, @ItemMasterId BIGINT, @WorkOrderQuoteDetailsId BIGINT, @InitialRowId INT = 1, @WorkOrderQuoteId BIGINT, @UpdatedBy VARCHAR(256), @workorderId BIGINT;
		DECLARE @WorkOrderQuoteLaborHeaderId BIGINT, @MasterCompanyId INT, @IsVersionIncrease BIT;
		DECLARE @AsPerGLAllocation VARCHAR(100) = 'As Per GL Allocation';

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteDetails') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteDetails;

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteCharges') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteCharges;

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

		SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteChargesId], [WorkOrderQuoteDetailsId], [ChargesTypeId], [VendorId], [Quantity], [MarkupPercentageId], [Description], [UnitCost], [ExtendedCost],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate],
				[HeaderMarkupId], [RefNum], [BillingMethodId], [TaskName], [ChargeType], [GlAccountName], [VendorName], [BillingName], [MarkUp], [UOMId] 
		INTO #tmpWorkOrderQuoteCharges
		FROM @tbl_WorkOrderQuoteChargesType;

		UPDATE #tmpWorkOrderQuoteDetails SET [UpdatedDate] = GETUTCDATE();

		UPDATE TMPC
		SET	TMPC.[CreatedDate] = CASE WHEN ISNULL(TMPC.[WorkOrderQuoteChargesId], 0) > 0 THEN TMPC.[CreatedDate] ELSE GETUTCDATE() END,
			TMPC.[UpdatedDate] = GETUTCDATE(),
			TMPC.[IsActive] = 1,
			TMPC.[IsDeleted] = CASE WHEN ISNULL(TMPC.[WorkOrderQuoteChargesId], 0) > 0 THEN TMPC.[IsDeleted] ELSE 0 END,
			TMPC.[MarkupPercentageId] = CASE WHEN ISNULL(TMPC.[MarkupPercentageId], 0) = 0 THEN NULL ELSE TMPC.[MarkupPercentageId] END,
			TMPC.[VendorId] = CASE WHEN ISNULL(TMPC.[VendorId], 0) = 0 THEN NULL ELSE TMPC.[VendorId] END,
			TMPC.[GlAccountName] = @AsPerGLAllocation
		FROM #tmpWorkOrderQuoteCharges TMPC

		SELECT	@WorkflowWorkOrderId = [WorkflowWorkOrderId], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId], @WorkOrderQuoteId = [WorkOrderQuoteId], @UpdatedBy = [UpdatedBy], @MasterCompanyId = [MasterCompanyId],
				@IsVersionIncrease = ISNULL([IsVersionIncrease], 0)
		FROM #tmpWorkOrderQuoteDetails WHERE [RowId] = @InitialRowId;

		SET @woPartNoId = (SELECT TOP 1 [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId);
		SET @ItemMasterId = (SELECT TOP 1 [ItemMasterId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId);
		SET @WorkOrderQuoteDetailsId = (SELECT TOP 1 [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId);
		SET @workorderId = (SELECT TOP 1 [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId);

		DECLARE @PreviousChargesHistory TABLE ([WorkOrderQuoteChargesId] BIGINT PRIMARY KEY, [TaskId] BIGINT, [Quantity] DECIMAL(18,6));

		INSERT INTO @PreviousChargesHistory ([WorkOrderQuoteChargesId], [TaskId], [Quantity])
		SELECT WOQC.[WorkOrderQuoteChargesId], WOQC.[TaskId], WOQC.[Quantity]
		FROM [DBO].[WorkOrderQuoteCharges] WOQC WITH(NOLOCK)
		INNER JOIN @tbl_WorkOrderQuoteChargesType TMPC ON WOQC.[WorkOrderQuoteChargesId] = TMPC.[WorkOrderQuoteChargesId]
			AND WOQC.[MasterCompanyId] = TMPC.[MasterCompanyId]
		WHERE WOQC.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId AND WOQC.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(WOQC.[IsDeleted], 0) = 0;

		IF(ISNULL(@WorkOrderQuoteDetailsId, 0) > 0)
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;

			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails_Charges] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteTaskType;

			--DELETE FROM [dbo].[WorkOrderQuoteCharges] WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;		
			UPDATE WOQC
			SET
				WOQC.ChargesTypeId = TMPC.ChargesTypeId,
				WOQC.VendorId = TMPC.VendorId,
				WOQC.Quantity = TMPC.Quantity,
				WOQC.MarkupPercentageId = TMPC.MarkupPercentageId,
				WOQC.Description = TMPC.Description,
				WOQC.UnitCost = TMPC.UnitCost,
				WOQC.ExtendedCost = TMPC.ExtendedCost,
				WOQC.MasterCompanyId = TMPC.MasterCompanyId,
				WOQC.UpdatedBy = TMPC.UpdatedBy,
				WOQC.UpdatedDate = TMPC.UpdatedDate,
				WOQC.IsActive = TMPC.IsActive,
				WOQC.IsDeleted = TMPC.IsDeleted,
				WOQC.TaskId = TMPC.TaskId,
				WOQC.MarkupFixedPrice = TMPC.MarkupFixedPrice,
				WOQC.BillingAmount = TMPC.BillingAmount,
				WOQC.BillingRate = TMPC.BillingRate,
				WOQC.HeaderMarkupId = TMPC.HeaderMarkupId,
				WOQC.RefNum = TMPC.RefNum,
				WOQC.BillingMethodId = TMPC.BillingMethodId,
				WOQC.TaskName = TMPC.TaskName,
				WOQC.ChargeType = TMPC.ChargeType,
				WOQC.GlAccountName = TMPC.GlAccountName,
				WOQC.VendorName = TMPC.VendorName,
				WOQC.BillingName = TMPC.BillingName,
				WOQC.MarkUp = TMPC.MarkUp,
				WOQC.UOMId = TMPC.UOMId
			FROM [dbo].[WorkOrderQuoteCharges] WOQC WITH(NOLOCK)
			JOIN #tmpWorkOrderQuoteCharges TMPC ON WOQC.WorkOrderQuoteChargesId = TMPC.WorkOrderQuoteChargesId
			WHERE TMPC.WorkOrderQuoteChargesId > 0;

			INSERT INTO [dbo].[WorkOrderQuoteCharges]
			SELECT	@WorkOrderQuoteDetailsId AS WorkOrderQuoteDetailsId, [ChargesTypeId], [VendorId], [Quantity], [MarkupPercentageId], [Description], [UnitCost], [ExtendedCost],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate],
					[HeaderMarkupId], [RefNum], [BillingMethodId], [TaskName], [ChargeType], [GlAccountName], [VendorName], [BillingName], [MarkUp], [UOMId] 
			FROM #tmpWorkOrderQuoteCharges WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteChargesId, 0) = 0

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
					WQT.ChargesBilling = T.ChargesBilling,
					WQT.ChargesCost = T.ChargesCost,
					WQT.ChargesMargin = T.ChargesBilling - T.ChargesCost,
					WQT.ChargesRevenue = T.ChargesBilling,
					WQT.ChargesRevenuePercentage = dbo.fn_GetRevenuePercentage(T.ChargesCost, T.ChargesBilling),
					WQT.ChargesMarginPer = dbo.fn_GetMarginPercentage((T.ChargesBilling - T.ChargesCost), T.ChargesBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;
				
				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevnuePercentage], [FreightMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [FreightMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [FreightRevenuePercentage] , [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[ChargesMargin]
						,[ChargesRevenue]
						,[ChargesRevenuePercentage]
						,[ChargesMarginPer]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevnuePercentage], [FreightMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [FreightMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [FreightRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[ChargesBilling] - [ChargesCost]
						,[ChargesBilling]
						,dbo.fn_GetRevenuePercentage([ChargesCost], [ChargesBilling])
						,dbo.fn_GetMarginPercentage(([ChargesBilling] - [ChargesCost]), [ChargesBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0
			END
		END
		ELSE
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;
			
			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails_Charges] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteTaskType;

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

			INSERT INTO [dbo].[WorkOrderQuoteCharges]
			SELECT	@WorkOrderQuoteDetailsId AS WorkOrderQuoteDetailsId, [ChargesTypeId], [VendorId], [Quantity], [MarkupPercentageId], [Description], [UnitCost], [ExtendedCost],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate],
					[HeaderMarkupId], [RefNum], [BillingMethodId], [TaskName], [ChargeType], [GlAccountName], [VendorName], [BillingName], [MarkUp], [UOMId] 
			FROM #tmpWorkOrderQuoteCharges WHERE ISNULL(IsDeleted, 0) = 0

			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
			BEGIN
				-- Updating WorkOrderQuoteTask Details
				UPDATE WQT
				SET 
					WQT.UpdatedDate = GETUTCDATE(),
					WQT.ChargesBilling = T.ChargesBilling,
					WQT.ChargesCost = T.ChargesCost,
					WQT.ChargesMargin = T.ChargesBilling - T.ChargesCost,
					WQT.ChargesRevenue = T.ChargesBilling,
					WQT.ChargesRevenuePercentage = dbo.fn_GetRevenuePercentage(T.ChargesCost, T.ChargesBilling),
					WQT.ChargesMarginPer = dbo.fn_GetMarginPercentage((T.ChargesBilling - T.ChargesCost), T.ChargesBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;
				
				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevnuePercentage], [FreightMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [FreightMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [FreightRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[ChargesMargin]
						,[ChargesRevenue]
						,[ChargesRevenuePercentage]
						,[ChargesMarginPer]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevnuePercentage], [FreightMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [FreightMarginPer], [ExclusionsMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [FreightRevenuePercentage], [ExclusionsRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer], [LaborMargin], [LaborRevenue], [LaborRevenuePercentage], [LaborMarginPer], [OverHeadCostRevenuePercentage]
						,[ChargesBilling] - [ChargesCost]
						,[ChargesBilling]
						,dbo.fn_GetRevenuePercentage([ChargesCost], [ChargesBilling])
						,dbo.fn_GetMarginPercentage(([ChargesBilling] - [ChargesCost]), [ChargesBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0
			END
		END
		
		EXEC [dbo].[USP_ChangeWOQStatusAfterApproval] @WorkOrderQuoteId, @UpdatedBy, @woPartNoId;

		EXEC [dbo].[USP_UpdateWOTotalCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateWOCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId

		EXEC [dbo].[UpdateWorkOrderQuoteVersionNo] @WorkOrderQuoteId, @IsVersionIncrease;

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteCharges] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId)
		BEGIN
			DECLARE @TotalRows INT, @CurrentRowId INT, @TMPWorkOrderQuoteChargesId BIGINT, @TableName VARCHAR(50) = 'workorderquotecharges';

			IF OBJECT_ID('tempdb..#tmpWOQCharges') IS NOT NULL
				DROP TABLE #tmpWOQCharges;

			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteChargesId] INTO #tmpWOQCharges
			FROM [dbo].[WorkOrderQuoteCharges] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId

			SELECT @TotalRows = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWOQCharges;

			IF(ISNULL(@TotalRows, 0) > 0)
			BEGIN
				WHILE(@TotalRows >= @CurrentRowId)
				BEGIN
					SELECT @TMPWorkOrderQuoteChargesId = [WorkOrderQuoteChargesId] FROM #tmpWOQCharges WHERE [RowId] = @CurrentRowId;

					EXEC [dbo].[UpdateWorkOrderQuoteTable] @TableName, @TMPWorkOrderQuoteChargesId;

					SET @CurrentRowId += 1;
				END
			END
		END

		DECLARE @ChangedChargesHistory TABLE ([TaskId] BIGINT, [OldValue] VARCHAR(60), [NewValue] VARCHAR(60), [UpdatedBy] VARCHAR(256), [StatusCode] VARCHAR(256));

		INSERT INTO @ChangedChargesHistory ([TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode])
		SELECT CASE WHEN ISNULL(WOQC.[IsDeleted], 0) = 1 THEN P.[TaskId] ELSE WOQC.[TaskId] END,
			CASE WHEN ISNULL(WOQC.[IsDeleted], 0) = 1 THEN '' ELSE CONVERT(VARCHAR(60), P.[Quantity]) END,
			CASE WHEN ISNULL(WOQC.[IsDeleted], 0) = 1 THEN '' ELSE CONVERT(VARCHAR(60), WOQC.[Quantity]) END,
			COALESCE(NULLIF(WOQC.[UpdatedBy], ''), @UpdatedBy),
			CASE WHEN ISNULL(WOQC.[IsDeleted], 0) = 1 THEN 'WorkOrderQuoteChargesRemoved' ELSE 'WorkOrderQuoteChargesUpdated' END
		FROM @PreviousChargesHistory P
		INNER JOIN [DBO].[WorkOrderQuoteCharges] WOQC WITH(NOLOCK) ON P.[WorkOrderQuoteChargesId] = WOQC.[WorkOrderQuoteChargesId]
			AND WOQC.[MasterCompanyId] = @MasterCompanyId
		WHERE ISNULL(WOQC.[IsDeleted], 0) = 1 OR ISNULL(P.[Quantity], 0) <> ISNULL(WOQC.[Quantity], 0);

		IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteChargesType WHERE ISNULL([WorkOrderQuoteChargesId], 0) = 0 AND ISNULL([IsDeleted], 0) = 0)
			OR EXISTS(SELECT 1 FROM @ChangedChargesHistory)
		BEGIN
			DECLARE @ChargesHistoryModuleId BIGINT, @ChargesHistoryQuoteId BIGINT, @ChargesHistoryPartId BIGINT, @ChargesHistoryFormTypeId BIT;
			DECLARE @ChargesHistoryRowId INT = 1, @ChargesHistoryRowCount INT;
			DECLARE @ChargesHistoryStatusCode VARCHAR(256), @ChargesHistoryText VARCHAR(MAX), @ChargesHistoryOldValue VARCHAR(60), @ChargesHistoryNewValue VARCHAR(60), @ChargesHistoryActor VARCHAR(256);
			DECLARE @AddedChargesHistory TABLE ([RowId] INT IDENTITY(1,1), [TaskId] BIGINT, [Quantity] DECIMAL(18,6), [UpdatedBy] VARCHAR(256), [StatusCode] VARCHAR(256), [OldValue] VARCHAR(60), [NewValue] VARCHAR(60));

			SELECT @ChargesHistoryModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WOQuote';
			SELECT @ChargesHistoryQuoteId = Q.[WorkOrderQuoteId], @ChargesHistoryPartId = D.[WOPartNoId], @ChargesHistoryFormTypeId = WO.[WorkOrderFormTypeId]
			FROM [DBO].[WorkOrderQuoteDetails] D WITH(NOLOCK)
			INNER JOIN [DBO].[WorkOrderQuote] Q WITH(NOLOCK) ON D.[WorkOrderQuoteId] = Q.[WorkOrderQuoteId] AND D.[MasterCompanyId] = Q.[MasterCompanyId]
			INNER JOIN [DBO].[WorkOrder] WO WITH(NOLOCK) ON Q.[WorkOrderId] = WO.[WorkOrderId] AND Q.[MasterCompanyId] = WO.[MasterCompanyId]
			WHERE D.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId AND D.[MasterCompanyId] = @MasterCompanyId;

			IF NOT EXISTS (SELECT 1 FROM @tbl_ChargesHistoryType)
			BEGIN
				INSERT INTO @AddedChargesHistory ([TaskId], [Quantity], [UpdatedBy], [StatusCode])
				SELECT F.[TaskId], F.[Quantity], COALESCE(NULLIF(F.[UpdatedBy], ''), @UpdatedBy), 'WorkOrderQuoteChargesAdded'
				FROM @tbl_WorkOrderQuoteChargesType F
				WHERE ISNULL(F.[WorkOrderQuoteChargesId], 0) = 0 AND ISNULL(F.[IsDeleted], 0) = 0 AND F.[MasterCompanyId] = @MasterCompanyId;
			END
			ELSE
			BEGIN
				INSERT INTO @AddedChargesHistory ([TaskId], [Quantity], [UpdatedBy], [StatusCode])
				SELECT F.[TaskId], F.[Quantity], COALESCE(NULLIF(F.[UpdatedBy], ''), @UpdatedBy),
					CASE WHEN ISNULL(F.[IsTransferredFromWO], 0) = 1 THEN 'WorkOrderQuoteChargesTransferredFromWO' ELSE 'WorkOrderQuoteChargesAdded' END
				FROM @tbl_ChargesHistoryType F
				WHERE F.[MasterCompanyId] = @MasterCompanyId
					AND EXISTS (SELECT 1 FROM @tbl_WorkOrderQuoteChargesType T
						WHERE T.[TaskId] = F.[TaskId] AND T.[Quantity] = F.[Quantity] AND T.[MasterCompanyId] = F.[MasterCompanyId]
							AND ISNULL(T.[WorkOrderQuoteChargesId], 0) = 0 AND ISNULL(T.[IsDeleted], 0) = 0);
			END
			INSERT INTO @AddedChargesHistory ([TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode])
			SELECT [TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode] FROM @ChangedChargesHistory;

			SELECT @ChargesHistoryRowCount = COUNT(*) FROM @AddedChargesHistory;

			WHILE @ChargesHistoryRowId <= @ChargesHistoryRowCount
			BEGIN
				SET @ChargesHistoryText = NULL;
				SELECT @ChargesHistoryText = REPLACE(HT.[TemplateBody], '##TASKNAME##',
					COALESCE(NULLIF(CASE WHEN ISNULL(@ChargesHistoryFormTypeId, 0) = 1 THEN WOT.[TaskName] ELSE T.[Description] END, ''),
						NULLIF(T.[Description], ''), CONVERT(VARCHAR(60), H.[TaskId]))),
					@ChargesHistoryOldValue = COALESCE(H.[OldValue], '0'), @ChargesHistoryNewValue = COALESCE(H.[NewValue], CONVERT(VARCHAR(60), H.[Quantity])),
					@ChargesHistoryActor = H.[UpdatedBy], @ChargesHistoryStatusCode = H.[StatusCode]
				FROM @AddedChargesHistory H
				INNER JOIN [DBO].[HistoryTemplate] HT WITH(NOLOCK) ON H.[StatusCode] = HT.[TemplateCode]
				LEFT JOIN [DBO].[WorkOrderTask] WOT WITH(NOLOCK) ON H.[TaskId] = WOT.[WorkOrderTaskId]
					AND WOT.[WorkOrderId] = @workorderId AND WOT.[WorkOrderPartNumberId] = @ChargesHistoryPartId AND WOT.[MasterCompanyId] = @MasterCompanyId
				LEFT JOIN [DBO].[Task] T WITH(NOLOCK) ON H.[TaskId] = T.[TaskId] AND T.[MasterCompanyId] = @MasterCompanyId
				WHERE H.[RowId] = @ChargesHistoryRowId;

				EXEC [DBO].[USP_History] @ModuleId = @ChargesHistoryModuleId, @RefferenceId = @ChargesHistoryQuoteId,
					@SubModuleId = 0, @SubRefferenceId = @ChargesHistoryPartId, @OldValue = @ChargesHistoryOldValue, @NewValue = @ChargesHistoryNewValue,
					@HistoryText = @ChargesHistoryText, @StatusCode = @ChargesHistoryStatusCode, @MasterCompanyId = @MasterCompanyId,
					@CreatedBy = @ChargesHistoryActor, @UpdatedBy = @ChargesHistoryActor;
				SET @ChargesHistoryRowId += 1;
			END
		END

		SELECT * FROM [DBO].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteCharges] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteTask] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId;

	COMMIT TRANSACTION  
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderQuoteCharges' 
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