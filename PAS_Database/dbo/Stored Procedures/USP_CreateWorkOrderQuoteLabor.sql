/*************************************************************           
 ** File:   [USP_CreateWorkOrderQuoteLabor]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Create work Order Quote Labor
 ** Date:   27-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    27-May-2025   Devendra Shekh		Created
	 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderQuoteLabor]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteLaborHeaderType [WorkOrderQuoteLaborHeaderType] READONLY,
@tbl_WorkOrderQuoteLaborType [WorkOrderQuoteLaborType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY
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

		UPDATE #tmpWorkOrderQuoteDetails SET [UpdatedDate] = GETUTCDATE();

		SELECT	@WorkflowWorkOrderId = [WorkflowWorkOrderId], @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId], @WorkOrderQuoteId = [WorkOrderQuoteId], @UpdatedBy = [UpdatedBy], @MasterCompanyId = [MasterCompanyId],
				@IsVersionIncrease = ISNULL([IsVersionIncrease], 0)
		FROM #tmpWorkOrderQuoteDetails WHERE [RowId] = @InitialRowId;

		SET @woPartNoId = (SELECT TOP 1 [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId);
		SET @ItemMasterId = (SELECT TOP 1 [ItemMasterId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId);
		SET @WorkOrderQuoteDetailsId = (SELECT TOP 1 [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId);
		SET @workorderId = (SELECT TOP 1 [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId);

		IF(ISNULL(@WorkOrderQuoteDetailsId, 0) > 0)
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;

			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails_Labor] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteLaborType;

			--DELETE FROM [dbo].[WorkOrderQuoteLabor] WHERE WorkOrderQuoteLaborHeaderId IN (SELECT WorkOrderQuoteLaborHeaderId FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId)
			--DELETE FROM [dbo].[WorkOrderQuoteLaborHeader] WHERE WorkOrderQuoteLaborHeaderId IN (SELECT WorkOrderQuoteLaborHeaderId FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId)

			UPDATE WQLH
			SET
				WQLH.DataEnteredBy = CASE WHEN ISNULL(TMPLH.[DataEnteredBy], 0) = 0 THEN NULL ELSE TMPLH.[DataEnteredBy] END,
				WQLH.MasterCompanyId = TMPLH.MasterCompanyId,
				WQLH.UpdatedBy = TMPLH.UpdatedBy,
				WQLH.UpdatedDate = GETUTCDATE(),
				WQLH.IsActive = TMPLH.IsActive,
				WQLH.IsDeleted = TMPLH.IsDeleted,
				WQLH.MarkupFixedPrice = TMPLH.MarkupFixedPrice,
				WQLH.HeaderMarkupId = TMPLH.HeaderMarkupId
			FROM [dbo].[WorkOrderQuoteLaborHeader] WQLH WITH(NOLOCK)
			JOIN @tbl_WorkOrderQuoteLaborHeaderType TMPLH ON WQLH.WorkOrderQuoteLaborHeaderId = TMPLH.WorkOrderQuoteLaborHeaderId
			WHERE TMPLH.WorkOrderQuoteLaborHeaderId > 0;

			UPDATE WQL
			SET
				WQL.ExpertiseId = TMPL.ExpertiseId,
				WQL.Hours = TMPL.Hours,
				WQL.BillableId = TMPL.BillableId,
				WQL.UpdatedBy = TMPL.UpdatedBy,
				WQL.UpdatedDate =  GETUTCDATE(),
				WQL.IsActive = TMPL.IsActive,
				WQL.IsDeleted = TMPL.IsDeleted,
				WQL.TaskId = TMPL.TaskId,
				WQL.DirectLaborOHCost = TMPL.DirectLaborOHCost,
				WQL.MarkupPercentageId = CASE WHEN ISNULL(TMPL.[MarkupPercentageId], 0) = 0 THEN NULL ELSE TMPL.[MarkupPercentageId] END,
				WQL.BurdenRateAmount = TMPL.BurdenRateAmount,
				WQL.TotalCostPerHour = TMPL.TotalCostPerHour,
				WQL.TotalCost = TMPL.TotalCost,
				WQL.BillingRate = TMPL.BillingRate,
				WQL.BillingAmount = TMPL.BillingAmount,
				WQL.BurdaenRatePercentageId = CASE WHEN ISNULL(TMPL.[BurdaenRatePercentageId], 0) = 0 THEN NULL ELSE TMPL.[BurdaenRatePercentageId] END,
				WQL.BillingMethodId = TMPL.BillingMethodId,
				WQL.MasterCompanyId = TMPL.MasterCompanyId,
				WQL.TaskName = TMPL.TaskName,
				WQL.Expertise = TMPL.Expertise,
				WQL.Billabletype = TMPL.Billabletype,
				WQL.BurdaenRatePercentage = TMPL.BurdaenRatePercentage,
				WQL.BillingName = TMPL.BillingName,
				WQL.MarkUp = TMPL.MarkUp,
				WQL.EmployeeId = TMPL.EmployeeId
			FROM [dbo].[WorkOrderQuoteLabor] WQL WITH(NOLOCK)
			JOIN @tbl_WorkOrderQuoteLaborType TMPL ON WQL.WorkOrderQuoteLaborId = TMPL.WorkOrderQuoteLaborId
			WHERE TMPL.WorkOrderQuoteLaborId > 0;

			UPDATE WQL
			SET	WQL.IsDeleted = 1
			FROM [dbo].[WorkOrderQuoteLabor] WQL WITH(NOLOCK)
			JOIN @tbl_WorkOrderQuoteLaborHeaderType WOH ON WQL.WorkOrderQuoteLaborHeaderId = WOH.WorkOrderQuoteLaborHeaderId
			WHERE WQL.WorkOrderQuoteLaborId NOT IN (SELECT TMP.WorkOrderQuoteLaborId FROM @tbl_WorkOrderQuoteLaborType TMP WHERE WOH.WorkOrderQuoteLaborHeaderId = TMP.WorkOrderQuoteLaborHeaderId)
			
			INSERT INTO [dbo].[WorkOrderQuoteLaborHeader] ([WorkOrderQuoteDetailsId], [DataEnteredBy], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MarkupFixedPrice], [HeaderMarkupId])
			SELECT	[WorkOrderQuoteDetailsId], CASE WHEN ISNULL([DataEnteredBy], 0) = 0 THEN NULL ELSE [DataEnteredBy] END, [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0, [MarkupFixedPrice], [HeaderMarkupId]
			FROM @tbl_WorkOrderQuoteLaborHeaderType WHERE ISNULL(WorkOrderQuoteLaborHeaderId, 0) = 0;

			SET @WorkOrderQuoteLaborHeaderId = SCOPE_IDENTITY();

			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteLaborType WHERE ISNULL(IsDeleted, 0) = 0)
			BEGIN
				
				IF(ISNULL(@WorkOrderQuoteLaborHeaderId, 0) = 0)
				BEGIN
					SET @WorkOrderQuoteLaborHeaderId = (SELECT TOP 1 WorkOrderQuoteLaborHeaderId FROM @tbl_WorkOrderQuoteLaborHeaderType WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId)
				END

				INSERT INTO [dbo].[WorkOrderQuoteLabor] ([WorkOrderQuoteLaborHeaderId], [ExpertiseId], [Hours], [BillableId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [DirectLaborOHCost],
							[MarkupPercentageId], [BurdenRateAmount], [TotalCostPerHour], [TotalCost], [BillingRate], [BillingAmount], [BurdaenRatePercentageId], [BillingMethodId], [MasterCompanyId], [TaskName], [Expertise], [Billabletype],
							[BurdaenRatePercentage], [BillingName], [MarkUp], [EmployeeId])
				SELECT	@WorkOrderQuoteLaborHeaderId, [ExpertiseId], [Hours], [BillableId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0, [TaskId], [DirectLaborOHCost], CASE WHEN ISNULL([MarkupPercentageId], 0) = 0 THEN NULL ELSE [MarkupPercentageId] END, [BurdenRateAmount],
						[TotalCostPerHour], [TotalCost], [BillingRate], [BillingAmount], CASE WHEN ISNULL([BurdaenRatePercentageId], 0) = 0 THEN NULL ELSE [BurdaenRatePercentageId] END, [BillingMethodId], [MasterCompanyId], [TaskName], [Expertise], [Billabletype], [BurdaenRatePercentage],  [BillingName], [MarkUp], [EmployeeId]
				FROM @tbl_WorkOrderQuoteLaborType WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteLaborId, 0) = 0;
			END			

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
					WQT.OverHeadCost = T.OverHeadCost,
					WQT.LaborCost = T.LaborCost,
					WQT.LaborBilling = T.LaborBilling,
					WQT.LaborRevenue = T.LaborBilling,
					WQT.LaborRevenuePercentage = dbo.fn_GetRevenuePercentage(T.LaborCost, T.LaborBilling),
					WQT.LaborMargin = T.LaborBilling - T.LaborCost,
					WQT.LaborMarginPer = dbo.fn_GetMarginPercentage((T.LaborBilling - T.LaborCost), T.LaborBilling),
					WQT.OverHeadCostRevenuePercentage = dbo.fn_GetRevenuePercentage(T.OverHeadCost, T.LaborBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;
				
				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling], 
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ChargesMarginPer], [ExclusionsMarginPer],
						[FreightMarginPer], [OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer]
						,[LaborMargin]
						,[LaborRevenue]
						,[LaborRevenuePercentage]
						,[LaborMarginPer]
						,[OverHeadCostRevenuePercentage]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [ChargesMarginPer], [ExclusionsMarginPer],
						[FreightMarginPer], [OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer]
						,[LaborBilling] - [LaborCost]
						,[LaborBilling]
						,dbo.fn_GetRevenuePercentage([LaborCost], [LaborBilling])
						,dbo.fn_GetMarginPercentage(([LaborBilling] - [LaborCost]), [LaborBilling])
						,dbo.fn_GetRevenuePercentage([OverHeadCost], [LaborBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0
			END
		END
		ELSE
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;
			
			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails_Labor] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteLaborType;

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

			INSERT INTO [dbo].[WorkOrderQuoteLaborHeader] ([WorkOrderQuoteDetailsId], [DataEnteredBy], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MarkupFixedPrice], [HeaderMarkupId])
			SELECT	@WorkOrderQuoteDetailsId, CASE WHEN ISNULL([DataEnteredBy], 0) = 0 THEN NULL ELSE [DataEnteredBy] END, [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0, [MarkupFixedPrice], [HeaderMarkupId]
			FROM @tbl_WorkOrderQuoteLaborHeaderType;

			SET @WorkOrderQuoteLaborHeaderId = SCOPE_IDENTITY();

			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteLaborType WHERE ISNULL(IsDeleted, 0) = 0)
			BEGIN
				INSERT INTO [dbo].[WorkOrderQuoteLabor] ([WorkOrderQuoteLaborHeaderId], [ExpertiseId], [Hours], [BillableId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TaskId], [DirectLaborOHCost],
							[MarkupPercentageId], [BurdenRateAmount], [TotalCostPerHour], [TotalCost], [BillingRate], [BillingAmount], [BurdaenRatePercentageId], [BillingMethodId], [MasterCompanyId], [TaskName], [Expertise], [Billabletype],
							[BurdaenRatePercentage], [BillingName], [MarkUp], [EmployeeId])
				SELECT	@WorkOrderQuoteLaborHeaderId, [ExpertiseId], [Hours], [BillableId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0, [TaskId], [DirectLaborOHCost], CASE WHEN ISNULL([MarkupPercentageId], 0) = 0 THEN NULL ELSE [MarkupPercentageId] END, [BurdenRateAmount],
						[TotalCostPerHour], [TotalCost], [BillingRate], [BillingAmount], CASE WHEN ISNULL([BurdaenRatePercentageId], 0) = 0 THEN NULL ELSE [BurdaenRatePercentageId] END, [BillingMethodId], [MasterCompanyId], [TaskName], [Expertise], [Billabletype], [BurdaenRatePercentage],  [BillingName], [MarkUp], [EmployeeId]
				FROM @tbl_WorkOrderQuoteLaborType WHERE ISNULL(IsDeleted, 0) = 0;
			END

			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
			BEGIN
				-- Updating WorkOrderQuoteTask Details
				UPDATE WQT
				SET 
					WQT.UpdatedDate = GETUTCDATE(),
					WQT.OverHeadCost = T.OverHeadCost,
					WQT.LaborCost = T.LaborCost,
					WQT.LaborBilling = T.LaborBilling,
					WQT.LaborRevenue = T.LaborBilling,
					WQT.LaborRevenuePercentage = dbo.fn_GetRevenuePercentage(T.LaborCost, T.LaborBilling),
					WQT.LaborMargin = T.LaborBilling - T.LaborCost,
					WQT.LaborMarginPer = dbo.fn_GetMarginPercentage((T.LaborBilling - T.LaborCost), T.LaborBilling),
					WQT.OverHeadCostRevenuePercentage = dbo.fn_GetRevenuePercentage(T.OverHeadCost, T.LaborBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;

				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling], 
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ChargesMarginPer], [ExclusionsMarginPer],
						[FreightMarginPer], [OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer]
						,[LaborMargin]
						,[LaborRevenue]
						,[LaborRevenuePercentage]
						,[LaborMarginPer]
						,[OverHeadCostRevenuePercentage]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevnuePercentage], [MaterialCost], [MaterialBilling], [MaterialRevnuePercentage], [ChargesCost],
						[ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling], [FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling],
						[ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [ChargesMarginPer], [ExclusionsMarginPer],
						[FreightMarginPer], [OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage],
						[MaterialMargin], [MaterialRevenue], [MaterialRevenuePercentage], [MaterialMarginPer]
						,[LaborBilling] - [LaborCost]
						,[LaborBilling]
						,dbo.fn_GetRevenuePercentage([LaborCost], [LaborBilling])
						,dbo.fn_GetMarginPercentage(([LaborBilling] - [LaborCost]), [LaborBilling])
						,dbo.fn_GetRevenuePercentage([OverHeadCost], [LaborBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0
			END
		END
		
		EXEC [dbo].[USP_ChangeWOQStatusAfterApproval] @WorkOrderQuoteId, @UpdatedBy, @woPartNoId;

		EXEC [dbo].[USP_UpdateWOTotalCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateWOCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId

		EXEC [dbo].[UpdateWorkOrderQuoteVersionNo] @WorkOrderQuoteId, @IsVersionIncrease;

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteLabor] WOL WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderQuoteLaborHeader] WOQLH WITH(NOLOCK) ON WOL.WorkOrderQuoteLaborHeaderId = WOQLH.WorkOrderQuoteLaborHeaderId WHERE WOQLH.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId)
		BEGIN
			DECLARE @TotalRows INT, @CurrentRowId INT, @TMPWorkOrderQuoteLaborId BIGINT, @TableName VARCHAR(50) = 'workorderquotelabor';

			IF OBJECT_ID('tempdb..#tmpWOQLabor') IS NOT NULL
				DROP TABLE #tmpWOQLabor;

			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteLaborId] INTO #tmpWOQLabor
			FROM [dbo].[WorkOrderQuoteLabor] WOL WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrderQuoteLaborHeader] WOQLH WITH(NOLOCK) ON WOL.WorkOrderQuoteLaborHeaderId = WOQLH.WorkOrderQuoteLaborHeaderId
			WHERE WOQLH.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId

			SELECT @TotalRows = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWOQLabor;

			IF(ISNULL(@TotalRows, 0) > 0)
			BEGIN
				WHILE(@TotalRows >= @CurrentRowId)
				BEGIN
					SELECT @TMPWorkOrderQuoteLaborId = [WorkOrderQuoteLaborId] FROM #tmpWOQLabor WHERE [RowId] = @CurrentRowId;

					EXEC [dbo].[UpdateWorkOrderQuoteTable] @TableName, @TMPWorkOrderQuoteLaborId;

					SET @CurrentRowId += 1;
				END
			END
		END

		SELECT * FROM [DBO].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [dbo].[WorkOrderQuoteLabor] WOL WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderQuoteLaborHeader] WOQLH WITH(NOLOCK) ON WOL.WorkOrderQuoteLaborHeaderId = WOQLH.WorkOrderQuoteLaborHeaderId WHERE WOQLH.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId
		SELECT * FROM [DBO].[WorkOrderQuoteTask] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId;

	COMMIT TRANSACTION  
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderQuoteLabor' 
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