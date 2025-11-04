/***************************************************************  
 ** File:   [USP_AddUpdateTemplateDetails]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used add or update Template Details
 ** Date:   09-April-2025

 ** Change History
 **************************************************************
 ** PR   Date				Author  					Change Description
 ** --   --------			-------					--------------------------------
    1    09-April-2025	   Devendra Shekh				Created
	2    02-Sep-2025       Sahdev Saliya                Added New Field Verified, VerifiedBy And VerifiedDate
	3    04-Nov-2025       Moin Bloch                   Changed Logic For Version Increase

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddUpdateTemplateDetails]
	@tbl_WorkFlowType WorkFlowType READONLY,
	@tbl_WorkflowChargesListType WorkflowChargesListType READONLY,
	@tbl_WorkflowDirectionType WorkflowDirectionType READONLY,
	@tbl_WorkflowEquipmentListType WorkflowEquipmentListType READONLY,
	@tbl_WorkFlowExclusionListType WorkFlowExclusionListType READONLY,
	@tbl_WorkflowExpertiseListType WorkflowExpertiseListType READONLY,
	@tbl_WorkflowMaterialType WorkflowMaterialType READONLY,
	@tbl_WorkflowMeasurementListType WorkflowMeasurementListType READONLY,
	@tbl_WorkflowPublicationsListType WorkflowPublicationsListType READONLY,
	@tbl_WorkFlowTaskType WorkFlowTaskType READONLY,
	@tbl_WorkflowPublicationDashNumber WorkflowPublicationDashNumberType READONLY,
	@WorkFlowTaskIds VARCHAR(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @workFlowMainId BIGINT = 0;
		DECLARE @NewWorkFlowMainId BIGINT = 0;		
		DECLARE @versionNo VARCHAR(10) = '';
		DECLARE @IsVersionIncrease BIT = 0;
		DECLARE @WorkFlowNumber VARCHAR(256) = '';
		DECLARE @MasterCompanyId INT = 0;
		DECLARE @Version VARCHAR(10) = '';
		DECLARE @CreatedBy VARCHAR(256) = '';
		DECLARE @UpdatedBy VARCHAR(256) = '';
		DECLARE @CreatedDate DATETIME2;
		DECLARE @UpdatedDate DATETIME2;
		DECLARE @CurrencyId BIGINT = 0;
		DECLARE @WorkScopeId BIGINT = 0;
		DECLARE @CustomerId BIGINT = 0;
		DECLARE @CurrencyCode VARCHAR(10) = '';
		DECLARE @WorkScopeCode VARCHAR(30) = '';
		DECLARE @CustomerName VARCHAR(100) = '';

		DECLARE @WorkFlowTask WorkFlowTaskType;

		SELECT	@workFlowMainId = WorkflowId, @IsVersionIncrease = ISNULL(IsVersionIncrease, 0), @Version = ISNULL([Version], ''), @MasterCompanyId = [MasterCompanyId], @CurrencyId = CurrencyId, @WorkScopeId = WorkScopeId, @CustomerId = CustomerId,
				@CreatedBy = CreatedBy, @UpdatedBy = UpdatedBy, @CreatedDate = CreatedDate, @UpdatedDate = UpdatedDate
		FROM @tbl_WorkFlowType;
		SELECT @WorkFlowNumber = WorkOrderNumber FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId;

		SELECT @CurrencyCode = [Code] FROM [dbo].[Currency] WITH(NOLOCK) WHERE [CurrencyId] = @CurrencyId;
		SELECT @WorkScopeCode = [WorkScopeCode] FROM [dbo].[WorkScope] WITH(NOLOCK) WHERE [WorkScopeId] = @WorkScopeId;
		SELECT @CustomerName = [Name] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		IF(ISNULL(@IsVersionIncrease, 0) = 1)
		BEGIN
			-- Getting Update Template New Version
			EXEC [dbo].[USP_UpdateWorkFlowVersionNum] @MasterCompanyId, @Version, @versionNo OUTPUT
			SET @Version = @versionNo;
		END

		-- Save [workFlow] Details
		IF((SELECT COUNT(*) FROM @tbl_WorkFlowType) > 0 )
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) = 0)
			BEGIN
				/*************** Prefixes ***************/		  
				DECLARE @IdCodeTypeId BIGINT;
				DECLARE @CurrentNumber AS BIGINT;

				SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Workflow Id';

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixes
				END
	
				CREATE TABLE #tmpCodePrefixes
				(
					ID BIGINT NOT NULL IDENTITY, 
					CodePrefixId BIGINT NULL,
					CodeTypeId BIGINT NULL,
					CurrentNumber BIGINT NULL,
					CodePrefix VARCHAR(50) NULL,
					CodeSufix VARCHAR(50) NULL,
					StartsFrom BIGINT NULL,
				)

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId = @IdCodeTypeId
				AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
				BEGIN
					SELECT @CurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					
					SET @WorkFlowNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
									@CurrentNumber,
									(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
									(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
				END
				/*****************End Prefixes*******************/	
			END

			MERGE INTO [DBO].[workFlow] AS [Target]
			USING @tbl_WorkFlowType AS [Source]
			ON [Target].[WorkflowId] = [Source].[WorkflowId] AND ISNULL([Target].[IsVersionIncrease],0) = @IsVersionIncrease

			WHEN MATCHED THEN
				UPDATE SET
					[Target].[WorkflowDescription] = [Source].[WorkflowDescription],
					--[Target].[Version] = @Version,
					[Target].[WorkScopeId] = [Source].[WorkScopeId],
					[Target].[ItemMasterId] = [Source].[ItemMasterId],
					[Target].[PartNumberDescription] = [Source].[PartNumberDescription],
					[Target].[CustomerId] = [Source].[CustomerId],
					[Target].[CurrencyId] = [Source].[CurrencyId],
					[Target].[WorkflowExpirationDate] = [Source].[WorkflowExpirationDate],
					[Target].[IsCalculatedBERThreshold] = [Source].[IsCalculatedBERThreshold],
					[Target].[IsFixedAmount] = [Source].[IsFixedAmount],
					[Target].[FixedAmount] = [Source].[FixedAmount],
					[Target].[IsPercentageOfNew] = [Source].[IsPercentageOfNew],
					[Target].[CostOfNew] = [Source].[CostOfNew],
					[Target].[PercentageOfNew] = [Source].[PercentageOfNew],
					[Target].[IsPercentageOfReplacement] = [Source].[IsPercentageOfReplacement],
					[Target].[CostOfReplacement] = [Source].[CostOfReplacement],
					[Target].[PercentageOfReplacement] = [Source].[PercentageOfReplacement],
					[Target].[Memo] = [Source].[Memo],
					[Target].[MasterCompanyId] = @MasterCompanyId,
					[Target].[UpdatedBy] = @UpdatedBy,
					[Target].[UpdatedDate] = GETUTCDATE(),
					[Target].[PartNumber] = [Source].[PartNumber],
					[Target].[CustomerName] = @CustomerName,
					[Target].[FlatRate] = [Source].[FlatRate],
					[Target].[BERThresholdAmount] = [Source].[BERThresholdAmount],
					[Target].[WorkOrderNumber] = @WorkFlowNumber,
					[Target].[CustomerCode] = [Source].[CustomerCode],
					[Target].[OtherCost] = [Source].[OtherCost],
					[Target].[ChangedPartNumberId] = [Source].[ChangedPartNumberId],
					[Target].[PercentageOfMaterial] = [Source].[PercentageOfMaterial],
					[Target].[PercentageOfExpertise] = [Source].[PercentageOfExpertise],
					[Target].[PercentageOfCharges] = [Source].[PercentageOfCharges],
					[Target].[PercentageOfOthers] = [Source].[PercentageOfOthers],
					[Target].[PercentageOfTotal] = [Source].[PercentageOfTotal],
					[Target].[RevisedPartNumber] = [Source].[RevisedPartNumber],
					[Target].[ChangedPartNumberDescription] = [Source].[ChangedPartNumberDescription],
					[Target].[ChangedPartNumber] = [Source].[ChangedPartNumber],
					[Target].[WorkScope] = @WorkScopeCode,
					[Target].[Currency] = @CurrencyCode,
					[Target].[WFParentId] = [Source].[WFParentId],
					[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0),
					[Target].[Verified] = [Source].[Verified],
					[Target].[VerifiedBy] = [Source].[VerifiedBy],
					[Target].[VerifiedDate] = [Source].[VerifiedDate]

			WHEN NOT MATCHED THEN
				INSERT (
					[WorkflowDescription], [Version], [WorkScopeId], [ItemMasterId], [PartNumberDescription], [CustomerId], [CurrencyId], [WorkflowExpirationDate], [IsCalculatedBERThreshold], [IsFixedAmount], [FixedAmount], [IsPercentageOfNew], [CostOfNew],
					[PercentageOfNew], [IsPercentageOfReplacement], [CostOfReplacement], [PercentageOfReplacement], [Memo], [ManagementStructureId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[PartNumber], [CustomerName], [FlatRate], [BERThresholdAmount], [WorkOrderNumber], [CustomerCode], [OtherCost], [WorkflowCreateDate], [ChangedPartNumberId], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], 
					[PercentageOfOthers], [PercentageOfTotal], [RevisedPartNumber], [ChangedPartNumberDescription], [ChangedPartNumber], [WorkScope], [Currency], [WFParentId], [IsVersionIncrease], [Verified], [VerifiedBy], [VerifiedDate]
				)
				VALUES (
					[Source].[WorkflowDescription], @Version, [Source].[WorkScopeId], [Source].[ItemMasterId], [Source].[PartNumberDescription], [Source].[CustomerId], [Source].[CurrencyId], [Source].[WorkflowExpirationDate],
					[Source].[IsCalculatedBERThreshold], [Source].[IsFixedAmount], [Source].[FixedAmount], [Source].[IsPercentageOfNew], [Source].[CostOfNew], [Source].[PercentageOfNew], [Source].[IsPercentageOfReplacement], [Source].[CostOfReplacement],
					[Source].[PercentageOfReplacement], [Source].[Memo], [Source].[ManagementStructureId], @MasterCompanyId, [Source].[CreatedBy], @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, [Source].[PartNumber], @CustomerName, [Source].[FlatRate],
					[Source].[BERThresholdAmount], @WorkFlowNumber, [Source].[CustomerCode], [Source].[OtherCost], [Source].[WorkflowCreateDate], [Source].[ChangedPartNumberId], [Source].[PercentageOfMaterial], [Source].[PercentageOfExpertise],
					[Source].[PercentageOfCharges], [Source].[PercentageOfOthers], [Source].[PercentageOfTotal], [Source].[RevisedPartNumber], [Source].[ChangedPartNumberDescription], [Source].[ChangedPartNumber], @WorkScopeCode, @CurrencyCode,
					[Source].[WFParentId], 0, [Source].[Verified], [Source].[VerifiedBy], [Source].[VerifiedDate]
				);

				SET @NewWorkFlowMainId = SCOPE_IDENTITY();

				IF(ISNULL(@workFlowMainId, 0) > 0 AND @IsVersionIncrease = 1)
				BEGIN
					UPDATE [dbo].[workFlow] SET  [IsVersionIncrease] = 1,[UpdatedBy] =  @UpdatedBy ,[UpdatedDate] = GETUTCDATE() WHERE [WorkflowId] = @workFlowMainId;
				END
				IF(ISNULL(@workFlowMainId, 0) = 0)
				BEGIN
					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNumber AS BIGINT) + 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;
					SET @workFlowMainId = SCOPE_IDENTITY();
				END
		END
		
		--WORKFLOW CHARGES LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowChargesListType) > 0)
		BEGIN

			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkflowChargesList]
			--	SET [IsDeleted] = 1,
			--	    [IsVersionIncrease] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowChargesListId] NOT IN (SELECT [WorkflowChargesListId] FROM  @tbl_WorkflowChargesListType)
			--END

			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN				
					MERGE INTO [DBO].[WorkflowChargesList] AS [Target]
					USING @tbl_WorkflowChargesListType AS [Source] ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowChargesListId = SOURCE.WorkflowChargesListId)
					WHEN MATCHED THEN
						UPDATE SET
							[Target].[WorkflowChargeTypeId] = [Source].[WorkflowChargeTypeId],
							[Target].[Description] = [Source].[Description],
							[Target].[Quantity] = [Source].[Quantity],
							[Target].[UnitCost] = [Source].[UnitCost],
							[Target].[ExtendedCost] = [Source].[ExtendedCost],
							[Target].[UnitPrice] = [Source].[UnitPrice],
							[Target].[ExtendedPrice] = [Source].[ExtendedPrice],
							[Target].[VendorId] = [Source].[VendorId],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[VendorName] = [Source].[VendorName],
							[Target].[Order] = [Source].[Order],
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[Memo] = [Source].[Memo],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0)

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [WorkflowChargeTypeId], [Description], [Quantity], [UnitCost], [ExtendedCost], [UnitPrice], [ExtendedPrice], [VendorId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], 
							[CreatedDate], [UpdatedDate], [IsActive], [VendorName], [Order], [IsDeleted], [Memo], [WFParentId], [IsVersionIncrease]
						)
						VALUES (
							@workFlowMainId, [Source].[WorkflowChargeTypeId], [Source].[Description], [Source].[Quantity], [Source].[UnitCost], [Source].[ExtendedCost], [Source].[UnitPrice], [Source].[ExtendedPrice],
							[Source].[VendorId], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive],
							[Source].[VendorName], [Source].[Order], [Source].[IsDeleted], [Source].[Memo], [Source].[WFParentId], 0
						);	
				END
				ELSE
				BEGIN			
					INSERT INTO [DBO].[WorkflowChargesList] (
						[WorkflowId], [WorkflowChargeTypeId], [Description], [Quantity], 
						[UnitCost], [ExtendedCost], [UnitPrice], [ExtendedPrice],
						[VendorId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy],
						[CreatedDate], [UpdatedDate], [IsActive], [VendorName], [Order],
						[IsDeleted], [Memo], [WFParentId], [IsVersionIncrease]
					)
					SELECT 
						@workFlowMainId, [Source].[WorkflowChargeTypeId], [Source].[Description], 
						[Source].[Quantity], [Source].[UnitCost], [Source].[ExtendedCost],
						[Source].[UnitPrice], [Source].[ExtendedPrice], [Source].[VendorId],
						[Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy, 
						GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[VendorName],
						[Source].[Order], [Source].[IsDeleted], [Source].[Memo],
						[Source].[WFParentId], 0
					FROM @tbl_WorkflowChargesListType AS [Source];
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkflowChargesList]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END
				
				INSERT INTO [dbo].[WorkflowChargesList] (
					[WorkflowId], [WorkflowChargeTypeId], [Description], [Quantity], 
					[UnitCost], [ExtendedCost], [UnitPrice], [ExtendedPrice],
					[VendorId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy],
					[CreatedDate], [UpdatedDate], [IsActive], [VendorName], [Order],
					[IsDeleted], [Memo], [WFParentId], [IsVersionIncrease]
				)
				SELECT 
					@NewWorkFlowMainId, [Source].[WorkflowChargeTypeId], [Source].[Description], 
					[Source].[Quantity], [Source].[UnitCost], [Source].[ExtendedCost],
					[Source].[UnitPrice], [Source].[ExtendedPrice], [Source].[VendorId],
					[Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy, 
					GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[VendorName],
					[Source].[Order], [Source].[IsDeleted], [Source].[Memo],
					[Source].[WFParentId], 0
				FROM @tbl_WorkflowChargesListType AS [Source];	
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkflowChargesList]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		--WORKFLOW DIRECTIONS LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowDirectionType) > 0 )
		BEGIN

			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkFlowDirection]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowDirectionId] NOT IN (SELECT [WorkflowDirectionId] FROM  @tbl_WorkflowDirectionType)
			--END

			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkFlowDirection] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [DBO].[WorkFlowDirection] AS [Target]
					USING @tbl_WorkflowDirectionType AS [Source] ON (TARGET.[WorkflowId] = SOURCE.[WorkflowId] AND TARGET.[WorkflowDirectionId] = SOURCE.[WorkflowDirectionId]) 

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[Action] = [Source].[Action],
							[Target].[Description] = [Source].[Description],
							[Target].[Sequence] = [Source].[Sequence],
							[Target].[Memo] = [Source].[Memo],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[Order] = [Source].[Order],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0),
							[Target].[TaskName] = [Source].[TaskName],
							[Target].[ParentId] = [Source].[ParentId],
							[Target].[IsParent] = [Source].[IsParent],
							[Target].[IsTaskDetails] = [Source].[IsTaskDetails]

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [Action], [Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease],
							[TaskName], [ParentId], [IsParent], [IsTaskDetails]
						)
						VALUES (
							@workFlowMainId, [Source].[Action], [Source].[Description], [Source].[Sequence], [Source].[Memo], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy,
							GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[Order], [Source].[WFParentId], 0, [Source].[TaskName],
							[Source].[ParentId], [Source].[IsParent], [Source].[IsTaskDetails]
						);					
				END
				ELSE
				BEGIN
					INSERT INTO [DBO].[WorkFlowDirection] (
							[WorkflowId], [Action], [Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease],
							[TaskName], [ParentId], [IsParent], [IsTaskDetails]
					)
					SELECT @workFlowMainId, [Source].[Action], [Source].[Description], [Source].[Sequence], [Source].[Memo], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy,
							GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[Order], [Source].[WFParentId], 0, [Source].[TaskName],
							[Source].[ParentId], [Source].[IsParent], [Source].[IsTaskDetails]
					FROM @tbl_WorkflowDirectionType AS [Source];
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkFlowDirection]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [DBO].[WorkFlowDirection] (
							[WorkflowId], [Action], [Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease],
							[TaskName], [ParentId], [IsParent], [IsTaskDetails]
				)
				SELECT @NewWorkFlowMainId, [Source].[Action], [Source].[Description], [Source].[Sequence], [Source].[Memo], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy,
					   GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[Order], [Source].[WFParentId], 0, [Source].[TaskName],
					   [Source].[ParentId], [Source].[IsParent], [Source].[IsTaskDetails]
				FROM @tbl_WorkflowDirectionType AS [Source];				
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkFlowDirection]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		--WORKFLOW EQUIPMENTS LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowEquipmentListType) > 0 )
		BEGIN

			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkflowEquipmentList]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowEquipmentListId] NOT IN (SELECT [WorkflowEquipmentListId] FROM  @tbl_WorkflowEquipmentListType)
			--END
			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [DBO].[WorkflowEquipmentList] AS [Target]
					USING @tbl_WorkflowEquipmentListType AS [Source] ON ([Target].[WorkflowId] = [Source].[WorkflowId] AND [Target].[WorkflowEquipmentListId] = [Source].[WorkflowEquipmentListId])

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[AssetId] = [Source].[AssetId],
							[Target].[AssetTypeId] = [Source].[AssetTypeId],
							[Target].[AssetDescription] = [Source].[AssetDescription],
							[Target].[Quantity] = [Source].[Quantity],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[PartNumber] = [Source].[PartNumber],
							[Target].[Order] = [Source].[Order],
							[Target].[Memo] = [Source].[Memo],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0),
							[Target].[AssetAttributeTypeId] = [Source].[AssetAttributeTypeId]

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [AssetId], [AssetTypeId], [AssetDescription], [Quantity], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
							[PartNumber], [Order], [Memo], [WFParentId], [IsVersionIncrease], [AssetAttributeTypeId]
						)
						VALUES (
							@workFlowMainId, [Source].[AssetId], [Source].[AssetTypeId], [Source].[AssetDescription], [Source].[Quantity], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy,
							GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[PartNumber], [Source].[Order], [Source].[Memo], [Source].[WFParentId], 0,
							[Source].[AssetAttributeTypeId]
						);		
				END
				ELSE
				BEGIN
					INSERT INTO [DBO].[WorkflowEquipmentList] (
							[WorkflowId], [AssetId], [AssetTypeId], [AssetDescription], [Quantity], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
							[PartNumber], [Order], [Memo], [WFParentId], [IsVersionIncrease], [AssetAttributeTypeId])
					SELECT	@workFlowMainId, [Source].[AssetId], [Source].[AssetTypeId], [Source].[AssetDescription], [Source].[Quantity], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy,
							GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[PartNumber], [Source].[Order], [Source].[Memo], [Source].[WFParentId], 0,
							[Source].[AssetAttributeTypeId]
					FROM @tbl_WorkflowEquipmentListType AS [Source];			
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkflowEquipmentList]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [DBO].[WorkflowEquipmentList] (
							[WorkflowId], [AssetId], [AssetTypeId], [AssetDescription], [Quantity], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
							[PartNumber], [Order], [Memo], [WFParentId], [IsVersionIncrease], [AssetAttributeTypeId])
				  SELECT	@NewWorkFlowMainId, [Source].[AssetId], [Source].[AssetTypeId], [Source].[AssetDescription], [Source].[Quantity], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy,
							GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[PartNumber], [Source].[Order], [Source].[Memo], [Source].[WFParentId], 0,
							[Source].[AssetAttributeTypeId]
				FROM @tbl_WorkflowEquipmentListType AS [Source];
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkflowEquipmentList]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		--WORKFLOW EXCLUSIONS LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkFlowExclusionListType) > 0 )
		BEGIN

			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkFlowExclusion]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowExclusionId] NOT IN (SELECT [WorkflowExclusionId] FROM  @tbl_WorkFlowExclusionListType)
			--END

			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkFlowExclusion] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [DBO].[WorkFlowExclusion] AS [Target]
					USING @tbl_WorkFlowExclusionListType AS [Source] ON ([Target].[WorkflowId] = [Source].[WorkflowId] AND [Target].[WorkflowExclusionId] = [Source].[WorkflowExclusionId])

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[ItemMasterId] = [Source].[ItemMasterId],
							[Target].[UnitCost] = [Source].[UnitCost],
							[Target].[Quantity] = [Source].[Quantity],
							[Target].[ExtendedCost] = [Source].[ExtendedCost],
							[Target].[EstimtPercentOccurrance] = [Source].[EstimtPercentOccurrance],
							[Target].[Memo] = [Source].[Memo],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[PartNumber] = [Source].[PartNumber],
							[Target].[PartDescription] = [Source].[PartDescription],
							[Target].[Order] = [Source].[Order],
							[Target].[ConditionId] = [Source].[ConditionId],
							[Target].[ItemClassificationId] = [Source].[ItemClassificationId],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0)

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [ItemMasterId], [UnitCost], [Quantity], [ExtendedCost], [EstimtPercentOccurrance], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
							[IsActive], [IsDeleted], [PartNumber], [PartDescription], [Order], [ConditionId], [ItemClassificationId], [WFParentId], [IsVersionIncrease]
						)
						VALUES (
							@workFlowMainId, [Source].[ItemMasterId], [Source].[UnitCost], [Source].[Quantity], [Source].[ExtendedCost], [Source].[EstimtPercentOccurrance], [Source].[Memo], [Source].[TaskId],
							@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[PartNumber], [Source].[PartDescription],
							[Source].[Order], [Source].[ConditionId], [Source].[ItemClassificationId], [Source].[WFParentId], 0
						);	
				END
				ELSE
				BEGIN
					INSERT INTO [dbo].[WorkFlowExclusion] (
							[WorkflowId], [ItemMasterId], [UnitCost], [Quantity], [ExtendedCost], [EstimtPercentOccurrance], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
							[IsActive], [IsDeleted], [PartNumber], [PartDescription], [Order], [ConditionId], [ItemClassificationId], [WFParentId], [IsVersionIncrease])					
					SELECT	@workFlowMainId, [Source].[ItemMasterId], [Source].[UnitCost], [Source].[Quantity], [Source].[ExtendedCost], [Source].[EstimtPercentOccurrance], [Source].[Memo], [Source].[TaskId],
							@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[PartNumber], [Source].[PartDescription],
							[Source].[Order], [Source].[ConditionId], [Source].[ItemClassificationId], [Source].[WFParentId], 0
					FROM @tbl_WorkFlowExclusionListType AS [Source];
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkFlowExclusion]
					   SET [IsVersionIncrease] = 1
					 WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [dbo].[WorkFlowExclusion] (
						[WorkflowId], [ItemMasterId], [UnitCost], [Quantity], [ExtendedCost], [EstimtPercentOccurrance], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
						[IsActive], [IsDeleted], [PartNumber], [PartDescription], [Order], [ConditionId], [ItemClassificationId], [WFParentId], [IsVersionIncrease])					
				SELECT	@NewWorkFlowMainId, [Source].[ItemMasterId], [Source].[UnitCost], [Source].[Quantity], [Source].[ExtendedCost], [Source].[EstimtPercentOccurrance], [Source].[Memo], [Source].[TaskId],
						@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[PartNumber], [Source].[PartDescription],
						[Source].[Order], [Source].[ConditionId], [Source].[ItemClassificationId], [Source].[WFParentId], 0
				FROM @tbl_WorkFlowExclusionListType AS [Source];
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkFlowExclusion]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		-- WORKFLOW EXPERTIZE LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowExpertiseListType) > 0 )
		BEGIN
			
			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkflowExpertiseList]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowExpertiseListId] NOT IN (SELECT [WorkflowExpertiseListId] FROM  @tbl_WorkflowExpertiseListType)
			--END

			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkflowExpertiseList] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [DBO].[WorkflowExpertiseList] AS [Target]
					USING @tbl_WorkflowExpertiseListType AS [Source] ON ([Target].[WorkflowId] = [Source].[WorkflowId] AND [Target].[WorkflowExpertiseListId] = [Source].[WorkflowExpertiseListId])

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[ExpertiseTypeId] = [Source].[ExpertiseTypeId],
							[Target].[EstimatedHours] = [Source].[EstimatedHours],
							[Target].[LaborDirectRate] = [Source].[LaborDirectRate],
							[Target].[DirectLaborRate] = [Source].[DirectLaborRate],
							[Target].[OverheadBurden] = [Source].[OverheadBurden],
							[Target].[OverheadCost] = [Source].[OverheadCost],
							[Target].[StandardRate] = [Source].[StandardRate],
							[Target].[LaborOverheadCost] = [Source].[LaborOverheadCost],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[Order] = [Source].[Order],
							[Target].[Memo] = [Source].[Memo],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0),
							[Target].[OverheadburdenPercentId] = [Source].[OverheadburdenPercentId]

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [ExpertiseTypeId], [EstimatedHours], [LaborDirectRate], [DirectLaborRate], [OverheadBurden], [OverheadCost], [StandardRate], [LaborOverheadCost], [TaskId], [MasterCompanyId], [CreatedBy],
							[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [Memo], [WFParentId], [IsVersionIncrease], [OverheadburdenPercentId]
						)
						VALUES (
							@workFlowMainId, [Source].[ExpertiseTypeId], [Source].[EstimatedHours], [Source].[LaborDirectRate], [Source].[DirectLaborRate], [Source].[OverheadBurden], [Source].[OverheadCost], [Source].[StandardRate],
							[Source].[LaborOverheadCost], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted],
							[Source].[Order], [Source].[Memo], [Source].[WFParentId], 0, [Source].[OverheadburdenPercentId]
						);	
				END
				ELSE 
				BEGIN
					INSERT INTO [dbo].[WorkflowExpertiseList](
								[WorkflowId], [ExpertiseTypeId], [EstimatedHours], [LaborDirectRate], [DirectLaborRate], [OverheadBurden], [OverheadCost], [StandardRate], [LaborOverheadCost], [TaskId], [MasterCompanyId], [CreatedBy],
								[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [Memo], [WFParentId], [IsVersionIncrease], [OverheadburdenPercentId])
					     SELECT @workFlowMainId, [Source].[ExpertiseTypeId], [Source].[EstimatedHours], [Source].[LaborDirectRate], [Source].[DirectLaborRate], [Source].[OverheadBurden], [Source].[OverheadCost], [Source].[StandardRate],
								[Source].[LaborOverheadCost], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted],
								[Source].[Order], [Source].[Memo], [Source].[WFParentId], 0, [Source].[OverheadburdenPercentId]
					       FROM @tbl_WorkflowExpertiseListType AS [Source];	
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkflowExpertiseList]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [dbo].[WorkflowExpertiseList](
							[WorkflowId], [ExpertiseTypeId], [EstimatedHours], [LaborDirectRate], [DirectLaborRate], [OverheadBurden], [OverheadCost], [StandardRate], [LaborOverheadCost], [TaskId], [MasterCompanyId], [CreatedBy],
							[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [Memo], [WFParentId], [IsVersionIncrease], [OverheadburdenPercentId])
					 SELECT @NewWorkFlowMainId, [Source].[ExpertiseTypeId], [Source].[EstimatedHours], [Source].[LaborDirectRate], [Source].[DirectLaborRate], [Source].[OverheadBurden], [Source].[OverheadCost], [Source].[StandardRate],
							[Source].[LaborOverheadCost], [Source].[TaskId], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted],
							[Source].[Order], [Source].[Memo], [Source].[WFParentId], 0, [Source].[OverheadburdenPercentId]
					   FROM @tbl_WorkflowExpertiseListType AS [Source];	
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkflowExpertiseList]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		--WORKFLOW MATERIALS LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowMaterialType) > 0 )
		BEGIN
			
			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkflowMaterial]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowMaterialListId] NOT IN (SELECT [WorkflowMaterialListId] FROM  @tbl_WorkflowMaterialType)
			--END

			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkflowMaterial] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [DBO].[WorkflowMaterial] AS [Target]
					USING @tbl_WorkflowMaterialType AS [Source] ON ([Target].[WorkflowId] = [Source].[WorkflowId] AND [Target].[WorkflowMaterialListId] = [Source].[WorkflowMaterialListId])

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[ItemMasterId] = [Source].[ItemMasterId],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[Quantity] = [Source].[Quantity],
							[Target].[UnitOfMeasureId] = [Source].[UnitOfMeasureId],
							[Target].[ConditionCodeId] = [Source].[ConditionCodeId],
							[Target].[UnitCost] = [Source].[UnitCost],
							[Target].[ExtendedCost] = [Source].[ExtendedCost],
							[Target].[Price] = [Source].[Price],
							[Target].[ProvisionId] = [Source].[ProvisionId],
							[Target].[IsDeferred] = [Source].[IsDeferred],
							[Target].[WorkflowActionId] = [Source].[WorkflowActionId],
							[Target].[Memo] = [Source].[Memo],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[MaterialMandatoriesName] = [Source].[MaterialMandatoriesName],
							[Target].[PartNumber] = [Source].[PartNumber],
							[Target].[PartDescription] = [Source].[PartDescription],
							[Target].[ItemClassificationId] = [Source].[ItemClassificationId],
							[Target].[ExtendedPrice] = [Source].[ExtendedPrice],
							[Target].[Order] = [Source].[Order],
							[Target].[MaterialMandatoriesId] = [Source].[MaterialMandatoriesId],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0),
							[Target].[Figure] = [Source].[Figure],
							[Target].[Item] = [Source].[Item]

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [ItemMasterId], [TaskId], [Quantity], [UnitOfMeasureId], [ConditionCodeId], [UnitCost], [ExtendedCost], [Price], [ProvisionId], [IsDeferred], [WorkflowActionId], [Memo], [MasterCompanyId],
							[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MaterialMandatoriesName], [PartNumber], [PartDescription], [ItemClassificationId], [ExtendedPrice], [Order], [MaterialMandatoriesId],
							[WFParentId], [IsVersionIncrease], [Figure], [Item]
						)
						VALUES (
							@workFlowMainId, [Source].[ItemMasterId], [Source].[TaskId], [Source].[Quantity], [Source].[UnitOfMeasureId], [Source].[ConditionCodeId], [Source].[UnitCost], [Source].[ExtendedCost],
							[Source].[Price], [Source].[ProvisionId], [Source].[IsDeferred], [Source].[WorkflowActionId], [Source].[Memo], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(),
							GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[MaterialMandatoriesName], [Source].[PartNumber], [Source].[PartDescription], [Source].[ItemClassificationId], [Source].[ExtendedPrice], [Source].[Order],
							[Source].[MaterialMandatoriesId], [Source].[WFParentId], 0, [Source].[Figure], [Source].[Item]
						);
				END
				ELSE
				BEGIN
					INSERT INTO [WorkflowMaterial](
							[WorkflowId], [ItemMasterId], [TaskId], [Quantity], [UnitOfMeasureId], [ConditionCodeId], [UnitCost], [ExtendedCost], [Price], [ProvisionId], [IsDeferred], [WorkflowActionId], [Memo], [MasterCompanyId],
							[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MaterialMandatoriesName], [PartNumber], [PartDescription], [ItemClassificationId], [ExtendedPrice], [Order], [MaterialMandatoriesId],
							[WFParentId], [IsVersionIncrease], [Figure], [Item])
					SELECT	@workFlowMainId, [Source].[ItemMasterId], [Source].[TaskId], [Source].[Quantity], [Source].[UnitOfMeasureId], [Source].[ConditionCodeId], [Source].[UnitCost], [Source].[ExtendedCost],
							[Source].[Price], [Source].[ProvisionId], [Source].[IsDeferred], [Source].[WorkflowActionId], [Source].[Memo], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(),
							GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[MaterialMandatoriesName], [Source].[PartNumber], [Source].[PartDescription], [Source].[ItemClassificationId], [Source].[ExtendedPrice], [Source].[Order],
							[Source].[MaterialMandatoriesId], [Source].[WFParentId], 0, [Source].[Figure], [Source].[Item]
					FROM @tbl_WorkflowMaterialType AS [Source];						
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkflowMaterial]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [WorkflowMaterial](
							[WorkflowId], [ItemMasterId], [TaskId], [Quantity], [UnitOfMeasureId], [ConditionCodeId], [UnitCost], [ExtendedCost], [Price], [ProvisionId], [IsDeferred], [WorkflowActionId], [Memo], [MasterCompanyId],
							[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [MaterialMandatoriesName], [PartNumber], [PartDescription], [ItemClassificationId], [ExtendedPrice], [Order], [MaterialMandatoriesId],
							[WFParentId], [IsVersionIncrease], [Figure], [Item])
					SELECT	@NewWorkFlowMainId, [Source].[ItemMasterId], [Source].[TaskId], [Source].[Quantity], [Source].[UnitOfMeasureId], [Source].[ConditionCodeId], [Source].[UnitCost], [Source].[ExtendedCost],
							[Source].[Price], [Source].[ProvisionId], [Source].[IsDeferred], [Source].[WorkflowActionId], [Source].[Memo], @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(),
							GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[MaterialMandatoriesName], [Source].[PartNumber], [Source].[PartDescription], [Source].[ItemClassificationId], [Source].[ExtendedPrice], [Source].[Order],
							[Source].[MaterialMandatoriesId], [Source].[WFParentId], 0, [Source].[Figure], [Source].[Item]
					FROM @tbl_WorkflowMaterialType AS [Source];	
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkflowMaterial]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		--WORKFLOW MEASUREMENT LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowMeasurementListType) > 0 )
		BEGIN

			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkflowMeasurement]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowMeasurementId] NOT IN (SELECT [WorkflowMeasurementId] FROM  @tbl_WorkflowMeasurementListType)
			--END
			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkflowMeasurement] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [DBO].[WorkflowMeasurement] AS [Target]
					USING @tbl_WorkflowMeasurementListType AS [Source] ON ([Target].[WorkflowId] = [Source].[WorkflowId] AND [Target].[WorkflowMeasurementId] = [Source].[WorkflowMeasurementId])

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[Sequence] = [Source].[Sequence],
							[Target].[Stage] = [Source].[Stage],
							[Target].[Min] = [Source].[Min],
							[Target].[Max] = [Source].[Max],
							[Target].[Expected] = [Source].[Expected],
							[Target].[DiagramURL] = [Source].[DiagramURL],
							[Target].[Memo] = [Source].[Memo],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[ItemMasterId] = [Source].[ItemMasterId],
							[Target].[PartNumber] = [Source].[PartNumber],
							[Target].[Order] = [Source].[Order],
							[Target].[PartDescription] = [Source].[PartDescription],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0)

					WHEN NOT MATCHED THEN
						INSERT (
							[WorkflowId], [Sequence], [Stage], [Min], [Max], [Expected], [DiagramURL], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
							[UpdatedDate], [IsActive], [IsDeleted], [ItemMasterId], [PartNumber], [Order], [PartDescription], [WFParentId], [IsVersionIncrease]
						)
						VALUES (
							@workFlowMainId, [Source].[Sequence], [Source].[Stage], [Source].[Min], [Source].[Max], [Source].[Expected], [Source].[DiagramURL], [Source].[Memo], [Source].[TaskId],
							@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[ItemMasterId], [Source].[PartNumber],
							[Source].[Order], [Source].[PartDescription], [Source].[WFParentId], 0
						);
				END
				ELSE
				BEGIN
					INSERT INTO [dbo].[WorkflowMeasurement](
							[WorkflowId], [Sequence], [Stage], [Min], [Max], [Expected], [DiagramURL], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
							[UpdatedDate], [IsActive], [IsDeleted], [ItemMasterId], [PartNumber], [Order], [PartDescription], [WFParentId], [IsVersionIncrease]
						)
					SELECT	@workFlowMainId, [Source].[Sequence], [Source].[Stage], [Source].[Min], [Source].[Max], [Source].[Expected], [Source].[DiagramURL], [Source].[Memo], [Source].[TaskId],
							@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[ItemMasterId], [Source].[PartNumber],
							[Source].[Order], [Source].[PartDescription], [Source].[WFParentId], 0
					FROM @tbl_WorkflowMeasurementListType AS [Source]
				END

			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkflowMeasurement]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [dbo].[WorkflowMeasurement](
							[WorkflowId], [Sequence], [Stage], [Min], [Max], [Expected], [DiagramURL], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
							[UpdatedDate], [IsActive], [IsDeleted], [ItemMasterId], [PartNumber], [Order], [PartDescription], [WFParentId], [IsVersionIncrease])
					SELECT	@NewWorkFlowMainId, [Source].[Sequence], [Source].[Stage], [Source].[Min], [Source].[Max], [Source].[Expected], [Source].[DiagramURL], [Source].[Memo], [Source].[TaskId],
							@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), [Source].[IsActive], [Source].[IsDeleted], [Source].[ItemMasterId], [Source].[PartNumber],
							[Source].[Order], [Source].[PartDescription], [Source].[WFParentId], 0
					FROM @tbl_WorkflowMeasurementListType AS [Source]			
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkflowMeasurement]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END

		--WORKFLOW PUBLICATION LIST
		IF((SELECT COUNT(*) FROM @tbl_WorkflowPublicationsListType) > 0 )
		BEGIN
			
			--IF(ISNULL(@workFlowMainId, 0) > 0)
			--BEGIN
			--	UPDATE [dbo].[WorkflowPublications]
			--	SET [IsDeleted] = 1
			--	WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId AND [WorkflowPublicationsId] NOT IN (SELECT [WorkflowPublicationsId] FROM  @tbl_WorkflowPublicationsListType)
			--END

			IF (ISNULL(@IsVersionIncrease,0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[WorkflowPublications] WITH(NOLOCK) WHERE [WorkflowId] = @workFlowMainId AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN
					MERGE INTO [dbo].[WorkflowPublications] AS [Target]
					USING @tbl_WorkflowPublicationsListType AS [Source]
					ON ([Target].[WorkflowId] = [Source].[WorkflowId] AND [Target].[WorkflowPublicationsId] = [Source].[WorkflowPublicationsId])

					WHEN MATCHED THEN
						UPDATE SET
							[Target].[UpdatedBy] = @UpdatedBy,
							[Target].[UpdatedDate] = GETUTCDATE(),
							[Target].[IsDeleted] = [Source].[IsDeleted],
							[Target].[PublicationId] = [Source].[PublicationId],
							[Target].[PublicationDescription] = [Source].[PublicationDescription],
							[Target].[PublicationType] = [Source].[PublicationType],
							[Target].[Sequence] = [Source].[Sequence],
							[Target].[Source] = [Source].[Source],
							[Target].[AircraftManufacturer] = [Source].[AircraftManufacturer],
							[Target].[Model] = [Source].[Model],
							[Target].[Location] = [Source].[Location],
							[Target].[Revision] = [Source].[Revision],
							[Target].[RevisionDate] = [Source].[RevisionDate],
							[Target].[VerifiedBy] = [Source].[VerifiedBy],
							[Target].[VerifiedDate] = [Source].[VerifiedDate],
							[Target].[Status] = [Source].[Status],
							[Target].[Image] = [Source].[Image],
							[Target].[TaskId] = [Source].[TaskId],
							[Target].[MasterCompanyId] = @MasterCompanyId,
							[Target].[Order] = [Source].[Order],
							[Target].[Memo] = [Source].[Memo],
							[Target].[WFParentId] = [Source].[WFParentId],
							[Target].[IsVersionIncrease] = ISNULL(@IsVersionIncrease,0)

					WHEN NOT MATCHED THEN
						INSERT (
							[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsDeleted], [PublicationId], [PublicationDescription], [PublicationType], [Sequence], [Source], [AircraftManufacturer], [Model], [Location],
							[Revision], [RevisionDate], [VerifiedBy], [VerifiedDate], [Status], [Image], [TaskId], [WorkflowId], [MasterCompanyId], [Order], [IsActive], [Memo], [WFParentId], [IsVersionIncrease]
						)
						VALUES (
							@CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), [Source].[IsDeleted], [Source].[PublicationId], [Source].[PublicationDescription], [Source].[PublicationType],
							[Source].[Sequence], [Source].[Source], [Source].[AircraftManufacturer], [Source].[Model], [Source].[Location], [Source].[Revision], [Source].[RevisionDate], [Source].[VerifiedBy], [Source].[VerifiedDate],
							[Source].[Status], [Source].[Image], [Source].[TaskId], @workFlowMainId, @MasterCompanyId, [Source].[Order], [Source].[IsActive], [Source].[Memo], [Source].[WFParentId], 0
						);

					IF((SELECT COUNT(*) FROM @tbl_WorkflowPublicationDashNumber) > 0 )
					BEGIN
						DELETE FROM [dbo].[WorkflowPublicationDashNumber] WHERE [WorkflowId] = @workFlowMainId 
									AND [WorkflowPublicationsId] IN (SELECT [WorkflowPublicationsId] FROM  @tbl_WorkflowPublicationsListType)
									AND [WorkflowPublicationDashNumberId] NOT IN (SELECT [WorkflowPublicationDashNumberId] FROM  @tbl_WorkflowPublicationDashNumber)
					END
				END
				ELSE
				BEGIN
					INSERT INTO [dbo].[WorkflowPublications](
							[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsDeleted], [PublicationId], [PublicationDescription], [PublicationType], [Sequence], [Source], [AircraftManufacturer], [Model], [Location],
							[Revision], [RevisionDate], [VerifiedBy], [VerifiedDate], [Status], [Image], [TaskId], [WorkflowId], [MasterCompanyId], [Order], [IsActive], [Memo], [WFParentId], [IsVersionIncrease])
					SELECT	@CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), [Source].[IsDeleted], [Source].[PublicationId], [Source].[PublicationDescription], [Source].[PublicationType],
							[Source].[Sequence], [Source].[Source], [Source].[AircraftManufacturer], [Source].[Model], [Source].[Location], [Source].[Revision], [Source].[RevisionDate], [Source].[VerifiedBy], [Source].[VerifiedDate],
							[Source].[Status], [Source].[Image], [Source].[TaskId], @workFlowMainId, @MasterCompanyId, [Source].[Order], [Source].[IsActive], [Source].[Memo], [Source].[WFParentId], 0						
					   FROM @tbl_WorkflowPublicationsListType AS [Source];
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@workFlowMainId, 0) > 0)
				BEGIN
					UPDATE [dbo].[WorkflowPublications]
					   SET [IsVersionIncrease] = 1
					WHERE [WorkflowId] = @workFlowMainId
				END

				INSERT INTO [dbo].[WorkflowPublications](
							[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsDeleted], [PublicationId], [PublicationDescription], [PublicationType], [Sequence], [Source], [AircraftManufacturer], [Model], [Location],
							[Revision], [RevisionDate], [VerifiedBy], [VerifiedDate], [Status], [Image], [TaskId], [WorkflowId], [MasterCompanyId], [Order], [IsActive], [Memo], [WFParentId], [IsVersionIncrease])
					SELECT	@CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), [Source].[IsDeleted], [Source].[PublicationId], [Source].[PublicationDescription], [Source].[PublicationType],
							[Source].[Sequence], [Source].[Source], [Source].[AircraftManufacturer], [Source].[Model], [Source].[Location], [Source].[Revision], [Source].[RevisionDate], [Source].[VerifiedBy], [Source].[VerifiedDate],
							[Source].[Status], [Source].[Image], [Source].[TaskId], @NewWorkFlowMainId, @MasterCompanyId, [Source].[Order], [Source].[IsActive], [Source].[Memo], [Source].[WFParentId], 0						
					   FROM @tbl_WorkflowPublicationsListType AS [Source];
			END
		END
		ELSE
		BEGIN
			IF(ISNULL(@workFlowMainId, 0) > 0)
			BEGIN
				UPDATE [dbo].[WorkflowPublications]
				SET [IsDeleted] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE(),
					[IsVersionIncrease] = @IsVersionIncrease
				WHERE ISNULL([IsDeleted], 0) = 0 AND [WorkflowId] = @workFlowMainId
			END
		END		
	COMMIT  TRANSACTION

	--To Save The Template Task Mapping Details
	IF((SELECT COUNT(*) FROM @tbl_WorkFlowTaskType) > 0 AND ISNULL(@WorkFlowTaskIds, '') <> '')
	BEGIN
		INSERT INTO @WorkFlowTask ([WorkFlowTaskId], [WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [IsVersionIncrease], [Resolution], [MasterCompanyId],
					[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate])
		SELECT	WFT.[WorkFlowTaskId],  @workFlowMainId,  @WorkFlowNumber,  WFT.[TaskId],  WFT.[TaskDescription],  WFT.[SequenceNumber],  WFT.[Descrepancy], ISNULL(@IsVersionIncrease,0),  WFT.[Resolution],  @MasterCompanyId,
				CASE WHEN ISNULL(WFT.[WorkFlowTaskId], 0) > 0 AND ISNULL(WFT.[CreatedBy], '') <> '' THEN WFT.[CreatedBy] ELSE @CreatedBy END,  
				CASE WHEN ISNULL(WFT.[WorkFlowTaskId], 0) > 0 AND WFT.[CreatedDate] IS NOT NULL THEN WFT.[CreatedDate] ELSE @CreatedDate END,  @UpdatedBy,  @UpdatedDate
		FROM @tbl_WorkFlowTaskType WFT 

		UPDATE TMP
		SET TMP.WorkFlowTaskId = CASE WHEN ISNULL(TMP.WorkFlowTaskId, 0) = 0 AND ISNULL(WFT.WorkFlowTaskId, 0) > 0 THEN WFT.WorkFlowTaskId ELSE TMP.WorkFlowTaskId END
		FROM @WorkFlowTask TMP
		LEFT JOIN [DBO].[WorkFlowTask] WFT WITH(NOLOCK) ON TMP.TaskId = WFT.TaskId AND TMP.MasterCompanyId = WFT.MasterCompanyId AND TMP.WorkFlowId = WFT.WorkFlowId

		EXEC [dbo].[USP_SaveWorkFlowMappingDetails] @WorkFlowTask, @WorkFlowTaskIds, 0
	END

	--IF(ISNULL(@IsVersionIncrease, 0) = 1)
	--BEGIN
	--	--Creating Version Increase Template
	--	EXEC [dbo].[USP_SaveNewVersionTemplateDetails] @workFlowMainId, @versionNo, @WorkFlowNumber, @CreatedBy, @MasterCompanyId;
	--END

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
		@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments varchar(150) = 'USP_AddUpdateTemplateDetails',
		@ProcedureParameters varchar(3000) = '',
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