/*************************************************************           
 ** File:   [USP_CreateWorkOrderQuoteMaterial]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Create work Order Quote Materials
 ** Date:   20-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    20-May-2025   Devendra Shekh		Created
	 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderQuoteMaterial]
@tbl_WorkOrderQuoteDetailsType [WorkOrderQuoteDetailsType] READONLY,
@tbl_WorkOrderQuoteMaterialType [WorkOrderQuoteMaterialType] READONLY,
@tbl_WorkOrderQuoteTaskType [WorkOrderQuoteTaskType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION  

		DECLARE @WorkflowWorkOrderId BIGINT, @woPartNoId BIGINT, @ItemMasterId BIGINT, @WorkOrderQuoteDetailsId BIGINT, @InitialRowId INT = 1, @WorkOrderQuoteId BIGINT, @UpdatedBy VARCHAR(256), @workorderId BIGINT;
		DECLARE @MasterCompanyId INT, @IsVersionIncrease BIT;
		DECLARE @WOQMaterialKitMappingType [WOQMaterialKitMappingType];

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteDetails') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteDetails;

		IF OBJECT_ID('tempdb..#workOrderQuoteMaterialKitMappingList') IS NOT NULL
			DROP TABLE #workOrderQuoteMaterialKitMappingList;

		IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteMaterial') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteMaterial;

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

		-- Material List Data
		SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteMaterialId], [WorkOrderQuoteDetailsId], [ItemMasterId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDefered],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MarkupPercentageId], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate],
				[HeaderMarkupId], [ProvisionId], [MaterialMandatoriesId], [BillingMethodId], [TaskName], [PartNumber], [PartDescription], [Provision], [UomName], [Conditiontype], [Stocktype], [BillingName],
				[MarkUp], [ManufacturerName], [UOM], [MandatoryOrSupplemental], [ItemClassification], [Figure], [Item], [WOQMaterialKitMappingId], [KitId], [Partqty]
		INTO #tmpWorkOrderQuoteMaterial
		FROM @tbl_WorkOrderQuoteMaterialType WHERE ISNULL(KitId, 0) = 0;

		-- Kit Material List Data
		SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteMaterialId], [WorkOrderQuoteDetailsId], [ItemMasterId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDefered],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MarkupPercentageId], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate],
				[HeaderMarkupId], [ProvisionId], [MaterialMandatoriesId], [BillingMethodId], [TaskName], [PartNumber], [PartDescription], [Provision], [UomName], [Conditiontype], [Stocktype], [BillingName],
				[MarkUp], [ManufacturerName], [UOM], [MandatoryOrSupplemental], [ItemClassification], [Figure], [Item], [WOQMaterialKitMappingId], [KitId], [Partqty]
		INTO #workOrderQuoteMaterialKitMappingList
		FROM @tbl_WorkOrderQuoteMaterialType WHERE ISNULL(KitId, 0) > 0;

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

			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteTaskType
			
			DELETE FROM [dbo].[WorkOrderQuoteMaterial] WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;

			UPDATE TMPM
			SET TMPM.MarkupPercentageId = CASE WHEN ISNULL(TMPM.MarkupPercentageId, 0) = 0 THEN NULL ELSE TMPM.MarkupPercentageId END
			FROM  #tmpWorkOrderQuoteMaterial TMPM

			INSERT INTO [dbo].[WorkOrderQuoteMaterial]([WorkOrderQuoteDetailsId], [ItemMasterId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDefered],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MarkupPercentageId], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate], [HeaderMarkupId],
					[ProvisionId], [MaterialMandatoriesId], [BillingMethodId], [TaskName], [PartNumber], [PartDescription], [Provision], [UomName], [Conditiontype], [Stocktype], [BillingName], [MarkUp])
			SELECT	@WorkOrderQuoteDetailsId, [ItemMasterId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost], [ExtendedCost], [Memo], [IsDefered],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0, [MarkupPercentageId], [TaskId], [MarkupFixedPrice], [BillingAmount], [BillingRate], [HeaderMarkupId],
					[ProvisionId], [MaterialMandatoriesId], [BillingMethodId], [TaskName], [PartNumber], [PartDescription], [Provision], [UomName], [Conditiontype], [Stocktype], [BillingName], [MarkUp]
			FROM #tmpWorkOrderQuoteMaterial WHERE ISNULL(IsDeleted, 0) = 0
			
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
					WQT.MaterialBilling = T.MaterialBilling,
					WQT.MaterialCost = T.MaterialCost,
					WQT.MaterialMargin = T.MaterialBilling - T.MaterialCost,
					WQT.MaterialRevenue = T.MaterialBilling,
					WQT.MaterialRevenuePercentage = dbo.fn_GetRevenuePercentage(T.MaterialCost, T.MaterialBilling),
					WQT.MaterialMarginPer = dbo.fn_GetMarginPercentage((T.MaterialBilling - T.MaterialCost), T.MaterialBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;
				
				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevenue], [LaborRevnuePercentage], [LaborMargin], [MaterialCost], [MaterialBilling],
						[MaterialRevnuePercentage], [ChargesCost], [ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling],
						[FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId],
						[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage], [LaborRevenuePercentage], 
						[OverHeadCostRevenuePercentage]
						,[MaterialMargin]
						,[MaterialRevenue]
						,[MaterialRevenuePercentage]
						,[MaterialMarginPer]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevenue], [LaborRevnuePercentage], [LaborMargin], [MaterialCost], [MaterialBilling],
						[MaterialRevnuePercentage], [ChargesCost], [ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling],
						[FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId],
						[CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage], [LaborRevenuePercentage], 
						[OverHeadCostRevenuePercentage]
						,[MaterialBilling] - [MaterialCost]
						,[MaterialBilling]
						,dbo.fn_GetRevenuePercentage([MaterialCost], MaterialBilling)
						,dbo.fn_GetMarginPercentage(([MaterialBilling] - [MaterialCost]), [MaterialBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0 AND ISNULL(IsKitPart, 0) = 0
			END
		END
		ELSE
		BEGIN

			TRUNCATE TABLE #tmpWorkOrderQuoteDetails;
			
			INSERT INTO #tmpWorkOrderQuoteDetails EXEC [DBO].[USP_GetWOQuoteDetails] @tbl_WorkOrderQuoteDetailsType, @tbl_WorkOrderQuoteTaskType;

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

			-- Inserting Quote Material
			UPDATE TMPM
			SET TMPM.MarkupPercentageId = CASE WHEN ISNULL(TMPM.MarkupPercentageId, 0) = 0 THEN NULL ELSE TMPM.MarkupPercentageId END,
				TMPM.IsActive = 1,
				TMPM.IsDeleted = 0,
				TMPM.CreatedDate = GETUTCDATE(),
				TMPM.UpdatedDate = GETUTCDATE()
			FROM  #tmpWorkOrderQuoteMaterial TMPM

			INSERT INTO [dbo].[WorkOrderQuoteMaterial]([WorkOrderQuoteDetailsId], [ItemMasterId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost],
				   [ExtendedCost], [Memo], [IsDefered], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MarkupPercentageId], [TaskId],
				   [MarkupFixedPrice], [BillingAmount], [BillingRate], [HeaderMarkupId], [ProvisionId], [MaterialMandatoriesId], [BillingMethodId], [TaskName], [PartNumber], [PartDescription],
				   [Provision], [UomName], [Conditiontype], [Stocktype], [BillingName], [MarkUp])
			SELECT @WorkOrderQuoteDetailsId, [ItemMasterId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId], [UnitCost],
				   [ExtendedCost], [Memo], [IsDefered], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0, [MarkupPercentageId], [TaskId],
				   [MarkupFixedPrice], [BillingAmount], [BillingRate], [HeaderMarkupId], [ProvisionId], [MaterialMandatoriesId], [BillingMethodId], [TaskName], [PartNumber], [PartDescription],
				   [Provision], [UomName], [Conditiontype], [Stocktype], [BillingName], [MarkUp]
			FROM #tmpWorkOrderQuoteMaterial WHERE ISNULL(IsDeleted, 0) = 0

			IF EXISTS(SELECT 1 FROM @tbl_WorkOrderQuoteTaskType)
			BEGIN
				-- Updating WorkOrderQuoteTask Details
				UPDATE WQT
				SET 
					WQT.UpdatedDate = GETUTCDATE(),
					WQT.MaterialBilling = T.MaterialBilling,
					WQT.MaterialCost = T.MaterialCost,
					WQT.MaterialMargin = T.MaterialBilling - T.MaterialCost,
					WQT.MaterialRevenue = T.MaterialBilling,
					WQT.MaterialRevenuePercentage = dbo.fn_GetRevenuePercentage(T.MaterialCost, T.MaterialBilling),
					WQT.MaterialMarginPer = dbo.fn_GetMarginPercentage((T.MaterialBilling - T.MaterialCost), T.MaterialBilling),
					WQT.UpdatedBy = @UpdatedBy
				FROM [dbo].[WorkOrderQuoteTask] WQT WITH(NOLOCK)
				JOIN @tbl_WorkOrderQuoteTaskType T ON WQT.WorkOrderQuoteTaskId = T.WorkOrderQuoteTaskId
				WHERE ISNULL(T.IsDeleted, 0) = 0 AND ISNULL(T.WorkOrderQuoteTaskId, 0) > 0;

				-- Inserting New Quote Task
				INSERT INTO [dbo].[WorkOrderQuoteTask] ([WOPartNoId], [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevenue], [LaborRevnuePercentage], [LaborMargin], [MaterialCost], [MaterialBilling],
						[MaterialRevnuePercentage], [ChargesCost], [ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling],
						[FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId],
						[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage], [LaborRevenuePercentage], 
						[OverHeadCostRevenuePercentage]
						,[MaterialMargin]
						,[MaterialRevenue]
						,[MaterialRevenuePercentage]
						,[MaterialMarginPer]
				)
				SELECT	@woPartNoId, [TaskId], [LaborHours], [LaborCost], [LaborBilling], [LaborRevenue], [LaborRevnuePercentage], [LaborMargin], [MaterialCost], [MaterialBilling],
						[MaterialRevnuePercentage], [ChargesCost], [ChargesBilling], [ChargesRevenue], [ChargesRevnuePercentage], [ChargesMargin], [FreightCost], [FreightBilling],
						[FreightRevenue], [FreightRevnuePercentage], [FreightMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenue], [ExclusionsRevnuePercentage], [ExclusionsMargin], [MasterCompanyId],
						[CreatedBy], [UpdatedBy], GETUTCDATE(),  GETUTCDATE(), 1, 0, [LaborMarginPer], [ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer],
						[OverHeadCost], [AdjustmentHours], [AdjustedHours], [WorkOrderLaborHeaderId], [ChargesRevenuePercentage], [ExclusionsRevenuePercentage], [FreightRevenuePercentage], [LaborRevenuePercentage], 
						[OverHeadCostRevenuePercentage]
						,[MaterialBilling] - [MaterialCost]
						,[MaterialBilling]
						,dbo.fn_GetRevenuePercentage([MaterialCost], MaterialBilling)
						,dbo.fn_GetMarginPercentage(([MaterialBilling] - [MaterialCost]), [MaterialBilling])
				FROM @tbl_WorkOrderQuoteTaskType
				WHERE ISNULL(IsDeleted, 0) = 0 AND ISNULL(WorkOrderQuoteTaskId, 0) = 0;
			END
		END
		
		IF EXISTS(SELECT 1 FROM #workOrderQuoteMaterialKitMappingList)
		BEGIN
			INSERT INTO @WOQMaterialKitMappingType([WOQMaterialKitMappingId], [WorkOrderQuoteId], [WorkflowWorkOrderId], [KitId], [KitNumber], [ItemMasterId], [Quantity], [UnitCost], [ExtendedCost],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Memo], [MarkupPercentageId], [MarkupFixedPrice], [BillingAmount], 
					[BillingRate], [HeaderMarkupId], [BillingMethodId], [TaskId], [IsUpdateQuoteDetail])
			SELECT	[WOQMaterialKitMappingId], @WorkOrderQuoteId AS WorkOrderQuoteId, @WorkflowWorkOrderId AS [WorkflowWorkOrderId], [KitId], PartNumber AS [KitNumber], [ItemMasterId], [Quantity], [UnitCost], [ExtendedCost],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Memo], [MarkupPercentageId], [MarkupFixedPrice], [BillingAmount], 
					[BillingRate], [HeaderMarkupId], [BillingMethodId], [TaskId], 0
			FROM #workOrderQuoteMaterialKitMappingList;

			EXEC [dbo].[usp_SavePostKitforWOQ] @WOQMaterialKitMappingType;
		END

		EXEC [dbo].[USP_ChangeWOQStatusAfterApproval] @WorkOrderQuoteId, @UpdatedBy, @woPartNoId;

		EXEC [dbo].[USP_UpdateWOTotalCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateWOCostDetails] @WorkOrderId, @WorkflowWorkOrderId, @UpdatedBy, @MasterCompanyId

		EXEC [dbo].[UpdateWorkOrderQuoteVersionNo] @WorkOrderQuoteId, @IsVersionIncrease;

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteMaterial] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId)
		BEGIN
			DECLARE @TotalRows INT, @CurrentRowId INT, @TMPWorkOrderQuoteMaterialId BIGINT, @TableName VARCHAR(50) = 'WorkOrderQuoteMaterial';

			IF OBJECT_ID('tempdb..#tmpWOQMaterial') IS NOT NULL
				DROP TABLE #tmpWOQMaterial;

			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [WorkOrderQuoteMaterialId] INTO #tmpWOQMaterial
			FROM [dbo].[WorkOrderQuoteMaterial] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;

			SELECT @TotalRows = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWOQMaterial;

			IF(ISNULL(@TotalRows, 0) > 0)
			BEGIN
				WHILE(@TotalRows >= @CurrentRowId)
				BEGIN
					SELECT @TMPWorkOrderQuoteMaterialId = [WorkOrderQuoteMaterialId] FROM #tmpWOQMaterial WHERE [RowId] = @CurrentRowId;

					EXEC [dbo].[UpdateWorkOrderQuoteTable] @TableName, @TMPWorkOrderQuoteMaterialId;

					SET @CurrentRowId += 1;
				END
			END
		END

		SELECT * FROM [DBO].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteMaterial] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;
		SELECT * FROM [DBO].[WorkOrderQuoteTask] WITH(NOLOCK) WHERE [WOPartNoId] = @woPartNoId;

	COMMIT TRANSACTION  
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderQuoteMaterial' 
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