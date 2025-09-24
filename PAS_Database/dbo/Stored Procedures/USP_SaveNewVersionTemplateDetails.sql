/***************************************************************  
 ** File:   [USP_SaveNewVersionTemplateDetails]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used TO generate Uppdated Workflow Version Number
 ** Date:   09-April-2025

 ** Change History
 **************************************************************
 ** PR   Date				Author  					Change Description
 ** --   --------			-------					--------------------------------
    1    09-April-2025	   Devendra Shekh				Created
	2    24-Sep-2025       Sahdev Saliya                Added New Field Verified, VerifiedBy And VerifiedDate

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveNewVersionTemplateDetails]
	@workFlowMainId BIGINT = 0,
	@VersionNum VARCHAR(10) = '',
	@WorkFlowNumber VARCHAR(256) = '',
	@CreatedBy VARCHAR(256) = '',
	@MasterCompanyId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @workFlowNewId BIGINT = 0;
		DECLARE @WorkflowDirection [WorkflowDirectionType];
		
		INSERT INTO [DBO].[Workflow] (
		[WorkflowDescription], [BERThresholdAmount], [Version], [WorkScopeId], [ItemMasterId], [PartNumber], [PartNumberDescription], [RevisedPartNumber], [ChangedPartNumberId], [ChangedPartNumberDescription], [CustomerId], [CurrencyId],
		[WorkflowCreateDate], [WorkflowExpirationDate], [IsCalculatedBERThreshold], [IsFixedAmount], [FixedAmount], [FlatRate], [IsPercentageOfNew], [CostOfNew], [PercentageOfNew], [IsPercentageOfReplacement],
		[CostOfReplacement], [PercentageOfReplacement], [OtherCost], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], [PercentageOfOthers], [PercentageOfTotal], [Memo], [ManagementStructureId], [WorkScope], [Currency],
		[ChangedPartNumber], [CustomerName], [CustomerCode], [WFParentId], [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy], [MasterCompanyId], [IsActive], [IsVersionIncrease], [WorkOrderNumber], [Verified], [VerifiedBy], [VerifiedDate]
		)
		SELECT	[WorkflowDescription], [BERThresholdAmount], @VersionNum, [WorkScopeId], [ItemMasterId], [PartNumber], [PartNumberDescription], [RevisedPartNumber], [ChangedPartNumberId], [ChangedPartNumberDescription], [CustomerId], [CurrencyId],
		GETUTCDATE(), [WorkflowExpirationDate], [IsCalculatedBERThreshold], [IsFixedAmount], [FixedAmount], [FlatRate], [IsPercentageOfNew], [CostOfNew], [PercentageOfNew], [IsPercentageOfReplacement],
		[CostOfReplacement], [PercentageOfReplacement], [OtherCost], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], [PercentageOfOthers], [PercentageOfTotal], [Memo], [ManagementStructureId], [WorkScope], [Currency],
		[ChangedPartNumber], [CustomerName], [CustomerCode], @workFlowMainId, GETUTCDATE(), GETUTCDATE(), [CreatedBy], [UpdatedBy], [MasterCompanyId], 1, 0, @WorkFlowNumber, [Verified], [VerifiedBy], [VerifiedDate]
		FROM [dbo].[Workflow] WITH(NOLOCK)
		WHERE [WorkflowId] = @workFlowMainId;

		SET @workFlowNewId = SCOPE_IDENTITY();
	
		-- Saving WorkflowChargesList Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkflowChargesList] (
					[WorkflowId], [WorkflowChargeTypeId], [Description], [Quantity], [UnitCost], [ExtendedCost], [UnitPrice], [ExtendedPrice], [VendorId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], 
					[CreatedDate], [UpdatedDate], [IsActive], [VendorName], [Order], [IsDeleted], [Memo], [WFParentId], [IsVersionIncrease]
			)
			SELECT  @workFlowNewId, [WorkflowChargeTypeId], [Description], [Quantity], [UnitCost], [ExtendedCost], [UnitPrice], [ExtendedPrice], [VendorId], [TaskId], @MasterCompanyId, @CreatedBy, @CreatedBy,
					GETUTCDATE(), GETUTCDATE(), 1, [VendorName], [Order], 0, [Memo], @workFlowMainId, 0
			FROM [DBO].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkFlowDirection Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkFlowDirection] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO @WorkflowDirection (
					[WorkflowId], [Action], [Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease],
					[TaskName], [ParentId], [IsParent], [IsTaskDetails], [WorkflowDirectionId]
			)
			SELECT	@workFlowNewId, [Action], [Description], [Sequence], [Memo], [TaskId], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, [Order], @workFlowMainId, 0, 
					[TaskName], [ParentId], [IsParent], [IsTaskDetails], [WorkflowDirectionId]
			FROM [DBO].[WorkFlowDirection] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;

			EXEC [dbo].[USP_CreateNewVersionWorkFlowTaskInstructionMaster] @WorkflowDirection;
		END

		-- Saving WorkflowEquipmentList Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkflowEquipmentList] (
					[WorkflowId], [AssetId], [AssetTypeId], [AssetDescription], [Quantity], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[PartNumber], [Order], [Memo], [WFParentId], [IsVersionIncrease], [AssetAttributeTypeId]
			)
			SELECT	@workFlowNewId, [AssetId], [AssetTypeId], [AssetDescription], [Quantity], [TaskId], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 
					[PartNumber], [Order], [Memo], @workFlowMainId, 0, [AssetAttributeTypeId]
			FROM [DBO].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkFlowExclusion Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkFlowExclusion] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkFlowExclusion] (
					[WorkflowId], [ItemMasterId], [UnitCost], [Quantity], [ExtendedCost], [EstimtPercentOccurrance], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
					[IsActive], [IsDeleted], [PartNumber], [PartDescription], [Order], [ConditionId], [ItemClassificationId], [WFParentId], [IsVersionIncrease]
			)
			SELECT	@workFlowNewId, [ItemMasterId], [UnitCost], [Quantity], [ExtendedCost], [EstimtPercentOccurrance], [Memo], [TaskId], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(),
					1, 0, [PartNumber], [PartDescription], [Order], [ConditionId], [ItemClassificationId], @workFlowMainId, 0
			FROM [DBO].[WorkFlowExclusion] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkflowExpertiseList Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkflowExpertiseList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkflowExpertiseList] (
					[WorkflowId], [ExpertiseTypeId], [EstimatedHours], [LaborDirectRate], [DirectLaborRate], [OverheadBurden], [OverheadCost], [StandardRate], [LaborOverheadCost], [TaskId], [MasterCompanyId], [CreatedBy],
					[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [Memo], [WFParentId], [IsVersionIncrease], [OverheadburdenPercentId]
			)
			SELECT	@workFlowNewId, [ExpertiseTypeId], [EstimatedHours], [LaborDirectRate], [DirectLaborRate], [OverheadBurden], [OverheadCost], [StandardRate], [LaborOverheadCost], [TaskId], @MasterCompanyId, @CreatedBy,
					@CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, [Order], [Memo], @workFlowMainId, 0, [OverheadburdenPercentId]
			FROM [DBO].[WorkflowExpertiseList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkflowMaterial Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkflowMaterial] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkflowMaterial] (
					[WorkflowId], [ItemMasterId], [TaskId], [Quantity], [UnitOfMeasureId], [ConditionCodeId], [UnitCost], [ExtendedCost], [Price], [ProvisionId], [IsDeferred], [WorkflowActionId], [Memo], [MasterCompanyId],
					[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MaterialMandatoriesName], [PartNumber], [PartDescription], [ItemClassificationId], [ExtendedPrice], [Order], [MaterialMandatoriesId],
					[WFParentId], [IsVersionIncrease], [Figure], [Item]
			)
			SELECT	@workFlowNewId, [ItemMasterId], [TaskId], [Quantity], [UnitOfMeasureId], [ConditionCodeId], [UnitCost], [ExtendedCost], [Price], [ProvisionId], [IsDeferred], [WorkflowActionId], [Memo], @MasterCompanyId,
					@CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, [MaterialMandatoriesName], [PartNumber], [PartDescription], [ItemClassificationId], [ExtendedPrice], [Order], [MaterialMandatoriesId],
					@workFlowMainId, 0, [Figure], [Item]
			FROM [DBO].[WorkflowMaterial] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkflowMeasurement Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkflowMeasurement] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkflowMeasurement] (
					[WorkflowId], [Sequence], [Stage], [Min], [Max], [Expected], [DiagramURL], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[ItemMasterId], [PartNumber], [Order], [PartDescription], [WFParentId], [IsVersionIncrease]
				)
			SELECT	@workFlowNewId, [Sequence], [Stage], [Min], [Max], [Expected], [DiagramURL], [Memo], [TaskId], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 
					[ItemMasterId], [PartNumber], [Order], [PartDescription], @workFlowMainId, 0
			FROM [DBO].[WorkflowMeasurement] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkflowPublications Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkflowPublications] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0)
		BEGIN
			INSERT INTO [DBO].[WorkflowPublications] (
					[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsDeleted], [PublicationId], [PublicationDescription], [PublicationType], [Sequence], [Source], [AircraftManufacturer], [Model], [Location],
					[Revision], [RevisionDate], [VerifiedBy], [VerifiedDate], [Status], [Image], [TaskId], [WorkflowId], [MasterCompanyId], [Order], [IsActive], [Memo], [WFParentId], [IsVersionIncrease]
			)
			SELECT	@CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 0, [PublicationId], [PublicationDescription], [PublicationType], [Sequence], [Source], [AircraftManufacturer], [Model], [Location],
					[Revision], [RevisionDate], [VerifiedBy], [VerifiedDate], [Status], [Image], [TaskId], @workFlowNewId, @MasterCompanyId, [Order], 1, [Memo], @workFlowMainId, 0
			FROM [DBO].[WorkflowPublications] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0;
		END

		-- Saving WorkFlowTask Details
		IF EXISTS(SELECT 1 FROM [DBO].[WorkFlowTask] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0 AND [MasterCompanyId] = @MasterCompanyId)
		BEGIN
			INSERT INTO [DBO].[WorkFlowTask] ([WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [WFParentId], [MasterCompanyId],
						[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate])
			SELECT	@workFlowNewId,  @WorkFlowNumber,  WFT.[TaskId],  WFT.[TaskDescription],  WFT.[SequenceNumber],  WFT.[Descrepancy], WFT.[Resolution], 0, @workFlowMainId,  @MasterCompanyId,
					@CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE()
			FROM [DBO].[WorkFlowTask] WFT WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL(IsDeleted, 0) = 0 AND [MasterCompanyId] = @MasterCompanyId;
		END
		
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
		@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments varchar(150) = 'USP_SaveNewVersionTemplateDetails',
		@ProcedureParameters varchar(3000) = '@VersionNum = ''' + ISNULL(@VersionNum, ''),
		@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		EXEC	spLogException @DatabaseName = @DatabaseName,
				@AdhocComments = @AdhocComments,
				@ProcedureParameters = @ProcedureParameters,
				@ApplicationName = @ApplicationName,
				@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END