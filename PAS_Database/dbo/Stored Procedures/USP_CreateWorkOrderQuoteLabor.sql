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
    1    27-May-2025   Devendra Shekh		Created.
	2    28-Oct-2026   Divyesh Kathiriya    Record labor entries, hours updates and removals for each selected MPN [PN-18341].
	 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderQuoteLabor]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteLaborHeaderType [WorkOrderQuoteLaborHeaderType] READONLY,
@tbl_WorkOrderQuoteLaborType [WorkOrderQuoteLaborType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY,
@tbl_LaborHistoryType [LaborHistoryType] READONLY
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

		DECLARE @PreviousLaborHistory TABLE ([WorkOrderQuoteLaborId] BIGINT PRIMARY KEY, [TaskId] BIGINT, [Hours] DECIMAL(10,2), [UpdatedBy] VARCHAR(256));

		INSERT INTO @PreviousLaborHistory ([WorkOrderQuoteLaborId], [TaskId], [Hours], [UpdatedBy])
		SELECT WQL.[WorkOrderQuoteLaborId], WQL.[TaskId], WQL.[Hours], COALESCE(NULLIF(TMPLH.[UpdatedBy], ''), @UpdatedBy)
		FROM [DBO].[WorkOrderQuoteLabor] WQL WITH(NOLOCK)
		INNER JOIN [DBO].[WorkOrderQuoteLaborHeader] WQLH WITH(NOLOCK) ON WQL.[WorkOrderQuoteLaborHeaderId] = WQLH.[WorkOrderQuoteLaborHeaderId]
			AND WQL.[MasterCompanyId] = WQLH.[MasterCompanyId]
		INNER JOIN @tbl_WorkOrderQuoteLaborHeaderType TMPLH ON WQLH.[WorkOrderQuoteLaborHeaderId] = TMPLH.[WorkOrderQuoteLaborHeaderId]
			AND WQLH.[MasterCompanyId] = TMPLH.[MasterCompanyId]
		WHERE WQLH.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId AND WQLH.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(WQLH.[IsDeleted], 0) = 0 AND ISNULL(WQL.[IsDeleted], 0) = 0;

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

		DECLARE @ChangedLaborHistory TABLE ([TaskId] BIGINT, [OldValue] VARCHAR(60), [NewValue] VARCHAR(60), [UpdatedBy] VARCHAR(256), [StatusCode] VARCHAR(256));

		INSERT INTO @ChangedLaborHistory ([TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode])
		SELECT CASE WHEN ISNULL(WQL.[IsDeleted], 0) = 1 THEN P.[TaskId] ELSE WQL.[TaskId] END,
			CASE WHEN ISNULL(WQL.[IsDeleted], 0) = 1 THEN '' ELSE CONVERT(VARCHAR(60), P.[Hours]) END,
			CASE WHEN ISNULL(WQL.[IsDeleted], 0) = 1 THEN '' ELSE CONVERT(VARCHAR(60), WQL.[Hours]) END,
			CASE WHEN ISNULL(WQL.[IsDeleted], 0) = 1 THEN P.[UpdatedBy] ELSE COALESCE(NULLIF(WQL.[UpdatedBy], ''), @UpdatedBy) END,
			CASE WHEN ISNULL(WQL.[IsDeleted], 0) = 1 THEN 'WorkOrderQuoteLaborRemoved' ELSE 'WorkOrderQuoteLaborUpdated' END
		FROM @PreviousLaborHistory P
		INNER JOIN [DBO].[WorkOrderQuoteLabor] WQL WITH(NOLOCK) ON P.[WorkOrderQuoteLaborId] = WQL.[WorkOrderQuoteLaborId]
			AND WQL.[MasterCompanyId] = @MasterCompanyId
		WHERE ISNULL(WQL.[IsDeleted], 0) = 1 OR ISNULL(P.[Hours], 0) <> ISNULL(WQL.[Hours], 0);

		IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteLaborType WHERE ISNULL([WorkOrderQuoteLaborId], 0) = 0 AND ISNULL([IsDeleted], 0) = 0)
			OR EXISTS(SELECT 1 FROM @ChangedLaborHistory)
		BEGIN
			DECLARE @LaborHistoryModuleId BIGINT, @LaborHistoryQuoteId BIGINT, @LaborHistoryPartId BIGINT, @LaborHistoryFormTypeId BIT;
			DECLARE @LaborHistoryRowId INT = 1, @LaborHistoryRowCount INT;
			DECLARE @LaborHistoryStatusCode VARCHAR(256), @LaborHistoryText VARCHAR(MAX), @LaborHistoryOldValue VARCHAR(60), @LaborHistoryNewValue VARCHAR(60), @LaborHistoryActor VARCHAR(256);
			DECLARE @AddedLaborHistory TABLE ([RowId] INT IDENTITY(1,1), [TaskId] BIGINT, [Hours] DECIMAL(10,2), [UpdatedBy] VARCHAR(256), [StatusCode] VARCHAR(256), [OldValue] VARCHAR(60), [NewValue] VARCHAR(60));

			SELECT @LaborHistoryModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WOQuote';
			SELECT @LaborHistoryQuoteId = Q.[WorkOrderQuoteId], @LaborHistoryPartId = D.[WOPartNoId], @LaborHistoryFormTypeId = WO.[WorkOrderFormTypeId]
			FROM [DBO].[WorkOrderQuoteDetails] D WITH(NOLOCK)
			INNER JOIN [DBO].[WorkOrderQuote] Q WITH(NOLOCK) ON D.[WorkOrderQuoteId] = Q.[WorkOrderQuoteId] AND D.[MasterCompanyId] = Q.[MasterCompanyId]
			INNER JOIN [DBO].[WorkOrder] WO WITH(NOLOCK) ON Q.[WorkOrderId] = WO.[WorkOrderId] AND Q.[MasterCompanyId] = WO.[MasterCompanyId]
			WHERE D.[WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId AND D.[MasterCompanyId] = @MasterCompanyId;

			IF NOT EXISTS (SELECT 1 FROM @tbl_LaborHistoryType)
			BEGIN
				INSERT INTO @AddedLaborHistory ([TaskId], [Hours], [UpdatedBy], [StatusCode])
				SELECT L.[TaskId], L.[Hours], COALESCE(NULLIF(L.[UpdatedBy], ''), @UpdatedBy), 'WorkOrderQuoteLaborAdded'
				FROM @tbl_WorkOrderQuoteLaborType L
				WHERE ISNULL(L.[WorkOrderQuoteLaborId], 0) = 0 AND ISNULL(L.[IsDeleted], 0) = 0 AND L.[MasterCompanyId] = @MasterCompanyId;
			END
			ELSE
			BEGIN
				INSERT INTO @AddedLaborHistory ([TaskId], [Hours], [UpdatedBy], [StatusCode])
				SELECT L.[TaskId], L.[Hours], COALESCE(NULLIF(L.[UpdatedBy], ''), @UpdatedBy),
					CASE WHEN ISNULL(L.[IsTransferredFromWO], 0) = 1 THEN 'WorkOrderQuoteLaborTransferredFromWO' ELSE 'WorkOrderQuoteLaborAdded' END
				FROM @tbl_LaborHistoryType L
				WHERE L.[MasterCompanyId] = @MasterCompanyId
					AND EXISTS (SELECT 1 FROM @tbl_WorkOrderQuoteLaborType T
						WHERE T.[TaskId] = L.[TaskId] AND T.[Hours] = L.[Hours] AND T.[MasterCompanyId] = L.[MasterCompanyId]
							AND ISNULL(T.[WorkOrderQuoteLaborId], 0) = 0 AND ISNULL(T.[IsDeleted], 0) = 0);
			END
			INSERT INTO @AddedLaborHistory ([TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode])
			SELECT [TaskId], [OldValue], [NewValue], [UpdatedBy], [StatusCode] FROM @ChangedLaborHistory;

			SELECT @LaborHistoryRowCount = COUNT(*) FROM @AddedLaborHistory;

			WHILE @LaborHistoryRowId <= @LaborHistoryRowCount
			BEGIN
				SET @LaborHistoryText = NULL;
				SELECT @LaborHistoryText = REPLACE(HT.[TemplateBody], '##TASKNAME##',
					COALESCE(NULLIF(CASE WHEN ISNULL(@LaborHistoryFormTypeId, 0) = 1 THEN WOT.[TaskName] ELSE T.[Description] END, ''),
						NULLIF(T.[Description], ''), CONVERT(VARCHAR(60), H.[TaskId]))),
					@LaborHistoryOldValue = COALESCE(H.[OldValue], '0'), @LaborHistoryNewValue = COALESCE(H.[NewValue], CONVERT(VARCHAR(60), H.[Hours])),
					@LaborHistoryActor = H.[UpdatedBy], @LaborHistoryStatusCode = H.[StatusCode]
				FROM @AddedLaborHistory H
				INNER JOIN [DBO].[HistoryTemplate] HT WITH(NOLOCK) ON H.[StatusCode] = HT.[TemplateCode]
				LEFT JOIN [DBO].[WorkOrderTask] WOT WITH(NOLOCK) ON H.[TaskId] = WOT.[WorkOrderTaskId]
					AND WOT.[WorkOrderId] = @workorderId AND WOT.[WorkOrderPartNumberId] = @LaborHistoryPartId AND WOT.[MasterCompanyId] = @MasterCompanyId
				LEFT JOIN [DBO].[Task] T WITH(NOLOCK) ON H.[TaskId] = T.[TaskId] AND T.[MasterCompanyId] = @MasterCompanyId
				WHERE H.[RowId] = @LaborHistoryRowId;

				EXEC [DBO].[USP_History] @ModuleId = @LaborHistoryModuleId, @RefferenceId = @LaborHistoryQuoteId,
					@SubModuleId = 0, @SubRefferenceId = @LaborHistoryPartId, @OldValue = @LaborHistoryOldValue, @NewValue = @LaborHistoryNewValue,
					@HistoryText = @LaborHistoryText, @StatusCode = @LaborHistoryStatusCode, @MasterCompanyId = @MasterCompanyId,
					@CreatedBy = @LaborHistoryActor, @UpdatedBy = @LaborHistoryActor;
				SET @LaborHistoryRowId += 1;
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