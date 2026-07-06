/*************************************************************
 ** File:   [USP_CopyWorkFlowDetailsToSubWorkOrder]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to Copy Work flow to Work Order
 ** Purpose:
 ** Date:   07-02-2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------   
	1    07-02-2025   Vishal Suthar		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

exec sp_executesql N'EXEC USP_CopyWorkFlowDetailsToSubWorkOrder @WorkOrderId,@WorkflowId,@WorkOrderPartNumberId,@MasterCompanyId,@CreatedBy, @CreatedById, 
@ListItem ',N'@WorkOrderId bigint,@WorkflowId bigint,@WorkOrderPartNumberId bigint,@MasterCompanyId int,@CreatedBy nvarchar(16),@CreatedById bigint,@listItem nvarchar(28)',
@WorkOrderId=8625,@WorkflowId=2852,@WorkOrderPartNumberId=8253,@MasterCompanyId=1,@CreatedBy=N'Brandon  Taylor ',@CreatedById=58,@listItem=N',Directions'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CopyWorkFlowDetailsToSubWorkOrder]
	@SubWorkOrderId BIGINT = 0,
	@WorkflowId BIGINT = 0,
	@SWOPartNumberId BIGINT = 0,
	@MasterCompanyId INT = 0,	
	@CreatedBy VARCHAR(200) = NULL,
	@CreatedById BIGINT = 0,
	@ListItem VARCHAR(200) = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			DECLARE @Materials NVARCHAR(50), @Labor NVARCHAR(50), @Tools NVARCHAR(50), @Charges NVARCHAR(50), @Directions NVARCHAR(50), @Task NVARCHAR(50), @PartIgnored NVARCHAR(50) = '';
			DECLARE @SplitTable TABLE (Item NVARCHAR(MAX));
			DECLARE @IsTaskBasedWO BIT = 0;
			DECLARE @WorkOrderId BIGINT = NULL;

			INSERT INTO @SplitTable (Item)
			SELECT Item FROM DBO.SPLITSTRING(@ListItem, ',');

			IF EXISTS (SELECT 1 FROM @SplitTable WHERE Item LIKE '%Task%')
			BEGIN
				SET @Task = 'Task';
			END

			IF EXISTS (SELECT 1 FROM @SplitTable WHERE Item LIKE '%Materials%')
			BEGIN
				SET @Materials = 'Materials';
			END

			IF EXISTS (SELECT 1 FROM @SplitTable WHERE Item LIKE '%Labor%')
			BEGIN
				SET @Labor = 'Labor';
			END

			IF EXISTS (SELECT 1 FROM @SplitTable WHERE Item LIKE '%Tools%')
			BEGIN
				SET @Tools = 'Tools';
			END

			IF EXISTS (SELECT 1 FROM @SplitTable WHERE Item LIKE '%Charges%')
			BEGIN
				SET @Charges = 'Charges';
			END

			IF EXISTS (SELECT 1 FROM @SplitTable WHERE Item LIKE '%Directions%')
			BEGIN
				SET @Directions = 'Directions';
			END

			IF (@SWOPartNumberId > 0)
			BEGIN
				IF (@SubWorkOrderId > 0)
				BEGIN
					--DECLARE @WorkFlowWorkOrderId BIGINT;
					--SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM DBO.WorkOrderWorkFlow WITH (NOLOCK) WHERE WorkOrderId = @SubWorkOrderId AND WorkOrderPartNoId = @SWOPartNumberId;

					SELECT @WorkOrderId = ISNULL(WorkOrderId, 0)  FROM DBO.SubWorkOrder WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId 
					SELECT @IsTaskBasedWO = ISNULL(WorkOrderFormTypeId, 0)  FROM DBO.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId; 

					IF EXISTS (SELECT TOP 1 1 FROM DBO.Workflow WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1 AND (WorkflowExpirationDate IS NULL OR CAST(WorkflowExpirationDate AS date) >= GETUTCDATE()))
					BEGIN
						DECLARE @IsMaterialsAllreadyCopied BIT = 0;
						DECLARE @IsChargesAllreadyCopied BIT = 0;
						DECLARE @IsExpertiseAlreadyCopied BIT = 0;
						DECLARE @IsEquipmentsAlreadyCopied BIT = 0;
						DECLARE @IsDirectionsAllreadyCopied BIT = 0;
						DECLARE @IsTaskAllreadyCopied BIT = 0;
						DECLARE @LaborHeaderId BIGINT;

						SELECT TOP 1 @LaborHeaderId = SubWorkOrderLaborHeaderId
						FROM DBO.SubWorkOrderLaborHeader WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND ISNULL(IsDeleted, 0) = 0;

						-- Check if expertise has already been copied
						IF @LaborHeaderId IS NOT NULL
						BEGIN
							SELECT TOP 1 @IsExpertiseAlreadyCopied = CAST(IsFromWorkFlow AS BIT)
							FROM DBO.SubWorkOrderLabor WITH (NOLOCK) WHERE SubWorkOrderLaborHeaderId = @LaborHeaderId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;
						END

						SELECT TOP 1 @IsEquipmentsAlreadyCopied = CAST(IsFromWorkFlow AS BIT)
						FROM DBO.SubWorkOrderAsset WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsMaterialsAllreadyCopied = CAST(IsFromWorkFlow AS BIT) FROM DBO.SubWorkOrderMaterials WITH (NOLOCK)
						WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsChargesAllreadyCopied = CAST(IsFromWorkFlow AS BIT)
						FROM DBO.SubWorkOrderCharges WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsTaskAllreadyCopied = CAST(IsFromWorkFlow AS BIT)
						FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsDirectionsAllreadyCopied = CAST(WTI.IsFromWorkFlow AS BIT)
						FROM DBO.SubWorkOrderTask WOT WITH (NOLOCK) JOIN dbo.SubWorkOrderTaskInstruction WTI WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WTI.SubWorkOrderTaskId
						WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND ISNULL(WTI.IsFromWorkFlow, 0) = 1 AND ISNULL(WTI.IsDeleted, 0) = 0;

						--UPDATE DBO.WorkOrderWorkFlow
						--SET WorkOrderId = @SubWorkOrderId,
						--	UpdatedDate = GETUTCDATE(),
						--	UpdatedBy = @createdBy,
						--	IsActive = 1,
						--	IsDeleted = 0,
						--	MasterCompanyId = @MasterCompanyId
						--WHERE WorkOrderId = @SubWorkOrderId AND WorkOrderPartNoId = @SWOPartNumberId;

						UPDATE WOWF
						SET BERThresholdAmount = workFlow.BERThresholdAmount,
							ChangedPartNumberId = workFlow.ChangedPartNumberId,
							CostOfNew = workFlow.CostOfNew,
							CostOfReplacement = workFlow.CostOfReplacement,
							CurrencyId = workFlow.CurrencyId,
							CustomerId = workFlow.CustomerId,
							FixedAmount = workFlow.FixedAmount,
							IsCalculatedBERThreshold = workFlow.IsCalculatedBERThreshold,
							IsFixedAmount = workFlow.IsFixedAmount,
							IsPercentageOfNew = workFlow.IsPercentageOfNew,
							IsPercentageOfReplacement = workFlow.IsPercentageOfReplacement,
							ItemMasterId = workFlow.ItemMasterId,
							Memo = workFlow.Memo,
							OtherCost = workFlow.OtherCost,
							PercentageOfNew = workFlow.PercentageOfNew,
							PercentageOfReplacement = workFlow.PercentageOfReplacement,
							Version = workFlow.Version,
							WorkflowDescription = workFlow.WorkflowDescription,
							WorkflowCreateDate = workFlow.WorkflowCreateDate,
							WorkflowExpirationDate = workFlow.WorkflowExpirationDate,
							WorkflowId = workFlow.WorkflowId
						FROM DBO.WorkOrderWorkFlow WOWF
							INNER JOIN DBO.Workflow workFlow ON WOWF.WorkflowId = workFlow.WorkflowId
						WHERE WOWF.WorkflowId = @WorkflowId;

						IF (@IsTaskAllreadyCopied <> 1 AND @IsTaskBasedWO = 1)
						BEGIN
							IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkFlowTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
							BEGIN
								IF(@IsTaskBasedWO > 0)
								BEGIN
									DECLARE @TaskTotalCounts INT = 0;
									DECLARE @TaskCount INT = 1;
									DECLARE @WorkOrderTasksId BIGINT;
									DECLARE @WorkFlowTasksId BIGINT;

									IF OBJECT_ID(N'tempdb..#tmpWorkFlowTask') IS NOT NULL
									BEGIN
									DROP TABLE #tmpWorkFlowTask
									END
			
									CREATE TABLE #tmpWorkFlowTask
									(
										ID BIGINT NOT NULL IDENTITY, 
										[TaskId] [bigint] NOT NULL,
										[WorkflowId] [bigint] NOT NULL,
									)
									
									INSERT INTO #tmpWorkFlowTask(TaskId, WorkflowId)
									SELECT TaskId, WorkflowId FROM dbo.WorkFlowTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0 ORDER BY SequenceNumber ASC

									SELECT @TaskTotalCounts = COUNT(ID) FROM #tmpWorkFlowTask;

									WHILE @TaskCount<= @TaskTotalCounts
									BEGIN
										SELECT DISTINCT @WorkFlowTasksId = TaskId FROM #tmpWorkFlowTask WHERE WorkflowId = @WorkflowId AND ID = ISNULL(@TaskCount, 0)

										IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId =  @SWOPartNumberId AND TaskId = @WorkFlowTasksId)
										BEGIN
											INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
														SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
											SELECT TOP 1
												@WorkOrderId,
												@SubWorkOrderId, 
												@SWOPartNumberId,
												WFT.TaskId,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
												T.IsPrintInWO AS IsIncludeInPrint,											
												0 as HasInstruction,
												T.[Description] as TaskName,
												1 AS IsFromWorkFlow
											FROM dbo.WorkFlowTask WFT WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFT.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFT.TaskId = @WorkFlowTasksId       

											SELECT @WorkOrderTasksId = SCOPE_IDENTITY(); --Need to check for Multiple Records

											INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
														IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
											SELECT TOP 1 
												@WorkOrderTasksId, 
												WFT.Descrepancy AS Descrepancy, 
												WFT.Resolution AS Resolution,
												0 as HasInstruction,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate, 
												1 AS IsActive,	
												0 AS IsDeleted,
												T.IsPrintInWO AS IsIncludeInPrint,
												T.IsPrintInWOQ AS IsPrintInWOQ,
												T.IsPrintInspector AS IsPrintInspector,
												T.IsPrintTechnician AS IsPrintTechnician
											FROM dbo.WorkFlowTask WFT WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFT.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFT.TaskId = @WorkFlowTasksId
										END

										SET @TaskCount = @TaskCount + 1;
									END

									IF OBJECT_ID(N'tempdb..#tmpWorkFlowTask') IS NOT NULL
									BEGIN
									DROP TABLE #tmpWorkFlowTask
									END
								END
							END
						END

						IF (@IsChargesAllreadyCopied <> 1 AND @Charges = 'Charges')
						BEGIN
							PRINT 'Start Charges';
							IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowChargesList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
							BEGIN
								--For Task Based WO
								IF(@IsTaskBasedWO > 0)
								BEGIN
									DECLARE @WorkOrderChargesTaskId BIGINT;
									DECLARE @ChargesTotalCounts INT = 0;
									DECLARE @ChargesCount INT = 1;
									DECLARE @ChargesWorkFlowTaskId BIGINT;

									IF OBJECT_ID(N'tempdb..#tmpWorkflowChargesTask') IS NOT NULL
									BEGIN
									DROP TABLE #tmpWorkflowChargesTask
									END
			
									CREATE TABLE #tmpWorkflowChargesTask
									(
										ID BIGINT NOT NULL IDENTITY, 
										[TaskId] [bigint] NOT NULL,
										[WorkflowId] [bigint] NOT NULL,
									)
									
									INSERT INTO #tmpWorkflowChargesTask(TaskId, WorkflowId)
									SELECT DISTINCT TaskId, WorkflowId FROM dbo.WorkflowChargesList WFC WITH (NOLOCK) WHERE WorkflowId = @WorkflowId

									SELECT @ChargesTotalCounts = COUNT(ID) FROM #tmpWorkflowChargesTask;

									WHILE @ChargesCount<= @ChargesTotalCounts
									BEGIN
									
										SELECT DISTINCT @ChargesWorkFlowTaskId = TaskId FROM #tmpWorkflowChargesTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ID = ISNULL(@ChargesCount, 0)

										IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @ChargesWorkFlowTaskId)
										BEGIN
											SELECT @WorkOrderChargesTaskId = SubWorkOrderTaskId FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @ChargesWorkFlowTaskId
										END
										ELSE
										BEGIN
											INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
													SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
											SELECT TOP 1
												@WorkOrderId,
												@SubWorkOrderId, 
												@SWOPartNumberId,
												WFC.TaskId,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
												T.IsPrintInWO AS IsIncludeInPrint,											
												0 as HasInstruction,
												T.[Description] as TaskName,
												1 AS IsFromWorkFlow
											FROM dbo.WorkflowChargesList WFC WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFC.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFC.TaskId = @ChargesWorkFlowTaskId       

											SELECT @WorkOrderChargesTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

											INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
														IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
											SELECT TOP 1 
												@WorkOrderChargesTaskId, 
												T.Descrepancy AS Descrepancy, 
												T.Resolution AS Resolution,
												0 as HasInstruction,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate, 
												1 AS IsActive,	
												0 AS IsDeleted,
												T.IsPrintInWO AS IsIncludeInPrint,
												T.IsPrintInWOQ AS IsPrintInWOQ,
												T.IsPrintInspector AS IsPrintInspector,
												T.IsPrintTechnician AS IsPrintTechnician
											FROM dbo.WorkflowChargesList WFC WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFC.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFC.TaskId = @ChargesWorkFlowTaskId  
										END
										
										INSERT INTO DBO.SubWorkOrderCharges (CreatedBy,CreatedDate,IsActive,IsDeleted,ChargesTypeId,MasterCompanyId,Quantity,UpdatedBy,UpdatedDate,VendorId,
										WorkOrderId,SubWorkOrderId,SubWOPartNoId,Description,ExtendedCost,IsFromWorkFlow,TaskId,UnitCost,ReferenceNo)
										SELECT 
											@CreatedBy AS CreatedBy,
											GETUTCDATE() AS CreatedDate,
											1 AS IsActive,
											0 AS IsDeleted,
											CAST(WorkflowChargeTypeId AS INT) AS ChargesTypeId,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											ISNULL(CAST(Quantity AS INT), 0) AS Quantity,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS UpdatedDate,
											VendorId AS VendorId,
											@WorkOrderId AS WorkOrderId,
											@SubWorkOrderId AS SubWorkOrderId,
											@SWOPartNumberId AS SubWOPartNoId,
											[Description] AS Description,
											ISNULL(ExtendedCost, 0) AS ExtendedCost,
											1 AS IsFromWorkFlow,
											@WorkOrderChargesTaskId AS TaskId,
											ISNULL(UnitCost, 0) AS UnitCost,
											'' AS ReferenceNo
										FROM DBO.WorkflowChargesList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND TaskId = @ChargesWorkFlowTaskId;
										
										SET @ChargesCount = @ChargesCount + 1;
									END
								END
								ELSE
								BEGIN
								--For Teardown WO									
									INSERT INTO DBO.SubWorkOrderCharges (CreatedBy,CreatedDate,IsActive,IsDeleted,ChargesTypeId,MasterCompanyId,Quantity,UpdatedBy,UpdatedDate,VendorId,
									WorkOrderId,SubWorkOrderId,SubWOPartNoId,Description,ExtendedCost,IsFromWorkFlow,TaskId,UnitCost,ReferenceNo)
									SELECT 
										@CreatedBy AS CreatedBy,
										GETUTCDATE() AS CreatedDate,
										1 AS IsActive,
										0 AS IsDeleted,
										CAST(WorkflowChargeTypeId AS INT) AS ChargesTypeId,
										CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
										ISNULL(CAST(Quantity AS INT), 0) AS Quantity,
										@CreatedBy AS UpdatedBy,
										GETUTCDATE() AS UpdatedDate,
										VendorId AS VendorId,
										@WorkOrderId AS WorkOrderId,
										@SubWorkOrderId AS SubWorkOrderId,
										@SWOPartNumberId AS SubWOPartNoId,
										[Description] AS Description,
										ISNULL(ExtendedCost, 0) AS ExtendedCost,
										1 AS IsFromWorkFlow,
										TaskId AS TaskId,
										ISNULL(UnitCost, 0) AS UnitCost,
										'' AS ReferenceNo
									FROM DBO.WorkflowChargesList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId;
								END

								UPDATE woc
								SET woc.IsFromWorkFlow = 1
								FROM DBO.SubWorkOrderCharges woc
								JOIN DBO.WorkflowChargesList wfc ON wfc.WorkflowId = @WorkflowId 
									AND woc.SubWorkOrderId = @SubWorkOrderId AND woc.MasterCompanyId = @MasterCompanyId
									AND woc.ChargesTypeId = CAST(wfc.WorkflowChargeTypeId AS INT) AND woc.TaskId = wfc.TaskId;
							END

							IF OBJECT_ID(N'tempdb..#tmpWorkflowChargesTask') IS NOT NULL
							BEGIN
							DROP TABLE #tmpWorkflowChargesTask
							END
							PRINT 'END Charges';
						END

						IF (@IsEquipmentsAlreadyCopied <> 1 AND @Tools = 'Tools')
						BEGIN
							IF(@IsTaskBasedWO > 0)
							BEGIN
								DECLARE @ToolsWorkOrderTaskId BIGINT;
								DECLARE @ToolsTotalCounts INT = 0;
								DECLARE @ToolsCount INT = 1;
								DECLARE @ToolsWorkFlowTaskId BIGINT;

								IF OBJECT_ID(N'tempdb..#tmpWorkflowToolsTask') IS NOT NULL
								BEGIN
								DROP TABLE #tmpWorkflowToolsTask
								END
			
								CREATE TABLE #tmpWorkflowToolsTask
								(
									ID BIGINT NOT NULL IDENTITY, 
									[TaskId] [bigint] NOT NULL,
									[WorkflowId] [bigint] NOT NULL,
								)
								
								INSERT INTO #tmpWorkflowToolsTask(TaskId, WorkflowId)
								SELECT DISTINCT TaskId, WorkflowId FROM dbo.WorkflowEquipmentList WFC WITH (NOLOCK) WHERE WorkflowId = @WorkflowId

								SELECT @ToolsTotalCounts = COUNT(ID) FROM #tmpWorkflowToolsTask;

								WHILE @ToolsCount<= @ToolsTotalCounts
								BEGIN
									SELECT DISTINCT @ToolsWorkFlowTaskId = TaskId FROM #tmpWorkflowToolsTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ID = ISNULL(@ToolsCount, 0)

									IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @ToolsWorkFlowTaskId)
									BEGIN
										SELECT @ToolsWorkOrderTaskId = SubWorkOrderTaskId FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @ToolsWorkFlowTaskId
									END
									ELSE
									BEGIN
										INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
												SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
										SELECT TOP 1
											@WorkOrderId,
											@SubWorkOrderId, 
											@SWOPartNumberId,
											WFE.TaskId,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											@CreatedBy AS CreatedBy,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate,
											1 AS IsActive,
											0 AS IsDeleted,
											ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
											T.IsPrintInWO AS IsIncludeInPrint,											
											0 as HasInstruction,
											T.[Description] as TaskName,
											1 AS IsFromWorkFlow
										FROM dbo.WorkflowEquipmentList WFE WITH (NOLOCK) 
											JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
										WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @ToolsWorkFlowTaskId       

										SELECT @ToolsWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

										INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
													IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
										SELECT TOP 1 
											@ToolsWorkOrderTaskId, 
											T.Descrepancy AS Descrepancy, 
											T.Resolution AS Resolution,
											0 as HasInstruction,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											@CreatedBy AS CreatedBy,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate, 
											1 AS IsActive,	
											0 AS IsDeleted,
											T.IsPrintInWO AS IsIncludeInPrint,
											T.IsPrintInWOQ AS IsPrintInWOQ,
											T.IsPrintInspector AS IsPrintInspector,
											T.IsPrintTechnician AS IsPrintTechnician
										FROM dbo.WorkflowEquipmentList WFE WITH (NOLOCK) 
											JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
										WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @ToolsWorkFlowTaskId  
									END

									--SELECT 'INSERT: WorkOrderAssets'
									INSERT INTO DBO.SubWorkOrderAsset (AssetRecordId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,Quantity,WorkOrderId,SubWorkOrderId,
													SubWOPartNoId,TaskId)
									SELECT 
										wfe.AssetId AS AssetRecordId,
										@createdBy AS CreatedBy,
										@createdBy AS UpdatedBy,
										GETUTCDATE() AS CreatedDate,
										GETUTCDATE() AS UpdatedDate,
										1 AS IsActive,
										0 AS IsDeleted,
										@masterCompanyId AS MasterCompanyId,
										COALESCE(wfe.Quantity, 0) AS Quantity,
										@WorkOrderId AS WorkOrderId,
										@SubWorkOrderId AS SubWorkOrderId,
										@SWOPartNumberId AS SubWOPartNoId,
										@ToolsWorkOrderTaskId AS TaskId
									FROM DBO.WorkflowEquipmentList wfe WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND TaskId = @ToolsWorkFlowTaskId ;

									UPDATE woa
									SET woa.IsFromWorkFlow = 1
									FROM DBO.SubWorkOrderAsset woa
									JOIN DBO.WorkflowEquipmentList wfe ON wfe.WorkflowId = @WorkflowId 
										AND woa.SubWorkOrderId = @SubWorkOrderId AND woa.MasterCompanyId = @masterCompanyId
										AND woa.AssetRecordId = wfe.AssetId AND wfe.TaskId = @ToolsWorkFlowTaskId
										AND woa.TaskId = @ToolsWorkOrderTaskId;

									SET @ToolsCount = @ToolsCount + 1;
								END
							END
							ELSE
							BEGIN
								IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowEquipmentList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
								BEGIN
									INSERT INTO DBO.SubWorkOrderAsset (AssetRecordId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,Quantity,WorkOrderId,SubWorkOrderId,
									SubWOPartNoId,TaskId)
									SELECT 
										wfe.AssetId AS AssetRecordId,
										@createdBy AS CreatedBy,
										@createdBy AS UpdatedBy,
										GETUTCDATE() AS CreatedDate,
										GETUTCDATE() AS UpdatedDate,
										1 AS IsActive,
										0 AS IsDeleted,
										@masterCompanyId AS MasterCompanyId,
										COALESCE(wfe.Quantity, 0) AS Quantity,
										@WorkOrderId AS WorkOrderId,
										@SubWorkOrderId AS SubWorkOrderId,
										@SWOPartNumberId AS SubWOPartNoId,
										wfe.TaskId AS TaskId
									FROM DBO.WorkflowEquipmentList wfe WITH (NOLOCK) WHERE WorkflowId = @WorkflowId;

									UPDATE woa
									SET woa.IsFromWorkFlow = 1
									FROM DBO.SubWorkOrderAsset woa
									JOIN DBO.WorkflowEquipmentList wfe ON wfe.WorkflowId = @WorkflowId 
										AND woa.SubWorkOrderId = @SubWorkOrderId AND woa.MasterCompanyId = @masterCompanyId
										AND woa.AssetRecordId = wfe.AssetId AND woa.TaskId = wfe.TaskId;
								END
							END
						END

						IF (@IsExpertiseAlreadyCopied <> 1 AND @Labor = 'Labor')
						BEGIN
							IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowExpertiseList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
							BEGIN
								DECLARE @WorkFlowWorkOrderId BIGINT;

								SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM WorkOrderWorkFlow WHERE WorkOrderId = @WorkOrderId;

								INSERT INTO DBO.WorkOrderExpertise (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,WorkOrderId,MasterCompanyId,ExpertiseTypeId,EstimatedHours,
								WorkFlowWorkOrderId,TaskId)
								SELECT 
									@createdBy AS CreatedBy,
									@createdBy AS UpdatedBy,
									GETUTCDATE() AS CreatedDate,
									GETUTCDATE() AS UpdatedDate,
									1 AS IsActive,
									0 AS IsDeleted,
									@SubWorkOrderId AS WorkOrderId,
									@masterCompanyId AS MasterCompanyId,
									CAST(wfe.ExpertiseTypeId AS INT) AS ExpertiseTypeId,
									wfe.EstimatedHours AS EstimatedHours,
									@WorkFlowWorkOrderId AS WorkFlowWorkOrderId,
									wfe.TaskId AS TaskId
								FROM DBO.WorkflowExpertiseList wfe WITH (NOLOCK) WHERE WorkflowId = @WorkflowId;

								UPDATE woe
								SET woe.IsFromWorkFlow = 1
								FROM DBO.WorkOrderExpertise woe
								JOIN DBO.WorkflowExpertiseList wfe ON wfe.WorkflowId = @WorkflowId 
									AND woe.WorkOrderId = @SubWorkOrderId AND woe.MasterCompanyId = @masterCompanyId
									AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;
							END
						END

						IF (@IsMaterialsAllreadyCopied <> 1 AND @Materials = 'Materials')
						BEGIN
							DECLARE @IsDER BIT, @IsPMA BIT;

							SELECT @IsDER = ISNULL(IsDER, 0), @IsPMA = ISNULL(IsPMA, 0) FROM DBO.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWOPartNoId = @SWOPartNumberId;

							DECLARE @ItemMasterId BIGINT, @PartNumber NVARCHAR(MAX)

							DECLARE material_cursors CURSOR FOR
							SELECT ItemMasterId FROM DBO.WorkflowMaterial WITH (NOLOCK) WHERE WorkflowId = @WorkflowId;

							OPEN material_cursors
							FETCH NEXT FROM material_cursors INTO @ItemMasterId

							WHILE @@FETCH_STATUS = 0
							BEGIN
								IF(@IsDER = 1 AND @IsPMA = 1)
								BEGIN
									SELECT TOP 1 @PartNumber = PartNumber
									FROM ItemMaster WITH (NOLOCK)
									WHERE ItemMasterId = @ItemMasterId AND (ISNULL(IsDER, 0) = 1 OR ISNULL(IsPMA, 0) = 1)

									 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 IF(ISNULL(@PartNumber, '') <> '')
										SET @PartIgnored = @PartIgnored + @PartNumber + ', '
								END

								IF (@IsDER = 0 AND @IsPMA = 1)
								BEGIN
									SELECT TOP 1 @PartNumber = PartNumber
									FROM ItemMaster WITH (NOLOCK)
									WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsPMA, 0) = 1

									 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 IF(ISNULL(@PartNumber, '') <> '')
										SET @PartIgnored = @PartIgnored + @PartNumber + ', '
								END

								IF @IsDER = 1 AND @IsPMA = 0
								BEGIN
									SELECT TOP 1 @PartNumber = PartNumber
									FROM ItemMaster WITH (NOLOCK)
									WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsDER, 0) = 1

									 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 IF(ISNULL(@PartNumber, '') <> '')
										SET @PartIgnored = @PartIgnored + @PartNumber + ', '
								END

								FETCH NEXT FROM material_cursors INTO @ItemMasterId
							END

							CLOSE material_cursors
							DEALLOCATE material_cursors

							IF LEN(@PartIgnored) > 0
							BEGIN
								SET @PartIgnored = 'Customer has resticted PMA or DER Part. So, Following Part Number are ignored while Transfer : ' + LEFT(@PartIgnored, LEN(@PartIgnored) - 1)
							END

							DECLARE @ProvisionId BIGINT;
							DECLARE @ProvisionEnum_REPLACE VARCHAR(100) = 'REPLACE';
							DECLARE @MaterialsWorkOrderTaskId BIGINT;

							SELECT TOP 1 @ProvisionId = ProvisionId FROM DBO.Provision WITH (NOLOCK)
							WHERE StatusCode = @ProvisionEnum_REPLACE AND ISNULL(IsActive, 0) = 1 AND ISNULL(isDeleted, 0) = 0 ;

							-- Fetch MaterialMandatories
							DECLARE @MaterialMandatories TABLE (Id BIGINT, Name NVARCHAR(MAX))
							INSERT INTO @MaterialMandatories
							SELECT Id, UPPER(Name) FROM MaterialMandatories WHERE ISNULL(IsDeleted, 0) = 0

							-- Cursor to iterate over materialList
							DECLARE @ConditionCodeId BIGINT, @Item NVARCHAR(MAX),
									@Figure NVARCHAR(MAX), @TaskId BIGINT, @Quantity INT, 
									@UnitCost DECIMAL(18,2), @ExtendedCost DECIMAL(18,2), 
									@MaterialMandatoriesName NVARCHAR(MAX), @Memo NVARCHAR(MAX),
									@IsDeferred BIT, @WorkflowMaterialListId BIGINT

							DECLARE newmaterial_cursors CURSOR FOR
							SELECT ItemMasterId, ConditionCodeId, Item, Figure, TaskId, Quantity, UnitCost, ExtendedCost, MaterialMandatoriesName, Memo, IsDeferred, WorkflowMaterialListId
							FROM DBO.WorkflowMaterial WITH (NOLOCK) WHERE WorkflowId = @WorkflowId;

							OPEN newmaterial_cursors
							FETCH NEXT FROM newmaterial_cursors INTO @ItemMasterId, @ConditionCodeId, @Item, @Figure, @TaskId, @Quantity, @UnitCost, @ExtendedCost, @MaterialMandatoriesName, @Memo, @IsDeferred, @WorkflowMaterialListId

							WHILE @@FETCH_STATUS = 0
							BEGIN
								DECLARE @IsIgnorePartExist BIT = 0, @WorkOrderMaterialsId BIGINT

								IF(@IsTaskBasedWO > 0)
								BEGIN
									IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @TaskId)
										BEGIN
											SELECT @MaterialsWorkOrderTaskId = SubWorkOrderTaskId FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @TaskId;
										END
										ELSE
										BEGIN
											INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
													SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
											SELECT TOP 1
												@WorkOrderId,
												@SubWorkOrderId,
												@SWOPartNumberId,
												WFM.TaskId,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
												T.IsPrintInWO AS IsIncludeInPrint,											
												0 as HasInstruction,
												T.[Description] as TaskName,
												1 AS IsFromWorkFlow
											FROM dbo.WorkflowMaterial WFM WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFM.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFM.TaskId = @TaskId       

											SELECT @MaterialsWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

											INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
														IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
											SELECT TOP 1
												@MaterialsWorkOrderTaskId, 
												T.Descrepancy AS Descrepancy, 
												T.Resolution AS Resolution,
												0 as HasInstruction,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate, 
												1 AS IsActive,	
												0 AS IsDeleted,
												T.IsPrintInWO AS IsIncludeInPrint,
												T.IsPrintInWOQ AS IsPrintInWOQ,
												T.IsPrintInspector AS IsPrintInspector,
												T.IsPrintTechnician AS IsPrintTechnician
											FROM dbo.WorkflowMaterial WFM WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFM.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFM.TaskId = @TaskId  
										END
								
									SELECT TOP 1 @WorkOrderMaterialsId = SubWorkOrderMaterialsId
									FROM DBO.SubWorkOrderMaterials WITH (NOLOCK)
									WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId
									AND MasterCompanyId = @masterCompanyId AND ItemMasterId = @ItemMasterId
									AND ConditionCodeId = @ConditionCodeId AND Item = @Item AND Figure = @Figure AND TaskId = @MaterialsWorkOrderTaskId;
								END
								ELSE
								BEGIN
									SELECT TOP 1 @WorkOrderMaterialsId = SubWorkOrderMaterialsId
									FROM DBO.SubWorkOrderMaterials WITH (NOLOCK)
									WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId
									AND MasterCompanyId = @masterCompanyId AND ItemMasterId = @ItemMasterId
									AND ConditionCodeId = @ConditionCodeId AND Item = @Item AND Figure = @Figure AND TaskId = @TaskId;
								END

								SELECT @IsDER = ISNULL(IsDER, 0), @IsPMA = ISNULL(IsPMA, 0) FROM DBO.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWOPartNoId = @SWOPartNumberId;

								IF (@IsDER = 1 AND @IsPMA = 1)
								BEGIN
									IF EXISTS (SELECT 1 FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND (ISNULL(IsDER, 0) = 1 OR ISNULL(IsPMA, 0) = 1) AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 )
										SET @IsIgnorePartExist = 1
								END
								ELSE IF (@IsDER = 0 AND @IsPMA = 1)
								BEGIN
									IF EXISTS (SELECT 1 FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsPMA, 0) = 1 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 )
										SET @IsIgnorePartExist = 1
								END
								ELSE IF (@IsDER = 1 AND @IsPMA = 0)
								BEGIN
									IF EXISTS (SELECT 1 FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsDER, 0) = 1 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 )
										SET @IsIgnorePartExist = 1
								END

								IF (@IsIgnorePartExist = 0)
								BEGIN
									IF (ISNULL(@WorkOrderMaterialsId, 0) > 0)
									BEGIN
										-- Update existing material
										UPDATE DBO.WorkOrderMaterials
										SET Quantity = ISNULL(Quantity, 0) + ISNULL(@Quantity, 0),
											ExtendedCost = (ISNULL(Quantity, 0) + ISNULL(@Quantity, 0)) * ISNULL(@UnitCost, 0),
											UpdatedBy = @createdBy
										WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
									END
									ELSE
									BEGIN
										-- Insert new material
										INSERT INTO DBO.SubWorkOrderMaterials (CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, 
																		IsActive, IsDeleted, MasterCompanyId, WorkOrderId, SubWorkOrderId, SubWOPartNoId, 
																		ItemMasterId, TaskId, ConditionCodeId, MaterialMandatoriesId, 
																		ItemClassificationId, PartStatusId, Quantity, UnitOfMeasureId, UnitCost, ExtendedCost, 
																		Memo, IsDeferred, ProvisionId, Figure, Item, IsFromWorkFlow)
										SELECT @createdBy, @createdBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 
											   @masterCompanyId, @WorkOrderId, @SubWorkOrderId, @SWOPartNumberId, @ItemMasterId, 
											   CASE WHEN ISNULL(@IsTaskBasedWO, 0) > 0 THEN @MaterialsWorkOrderTaskId ELSE @TaskId END AS TaskId, 
											   @ConditionCodeId, 
											   (SELECT Id FROM @MaterialMandatories WHERE UPPER([Name]) = UPPER(@MaterialMandatoriesName)), 
											   wfm.ItemClassificationId, 0, @Quantity, wfm.UnitOfMeasureId, @UnitCost, @ExtendedCost, 
											   @Memo, @IsDeferred, @ProvisionId, @Figure, @Item, 1
										FROM DBO.WorkflowMaterial wfm WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND TaskId = @TaskId AND wfm.WorkflowMaterialListId = @WorkflowMaterialListId;
									END
								END

								UPDATE DBO.SubWorkOrderMaterials SET IsFromWorkFlow = 1 WHERE SubWorkOrderMaterialsId = @WorkOrderMaterialsId;

								FETCH NEXT FROM newmaterial_cursors INTO @ItemMasterId, @ConditionCodeId, @Item, @Figure, @TaskId, @Quantity, @UnitCost, @ExtendedCost, @MaterialMandatoriesName, @Memo, @IsDeferred, @WorkflowMaterialListId
							END

							CLOSE newmaterial_cursors
							DEALLOCATE newmaterial_cursors
						END

						IF (@IsExpertiseAlreadyCopied <> 1 AND @Labor = 'Labor')
						BEGIN
							DECLARE @TaskStatusId BIGINT, @EmployeeId BIGINT, @ManagementStructureId INT, @LaborHoursId INT, @laborHoursMedthodId INT, @WorkOrderLaborHeaderId BIGINT;
							
							SELECT TOP 1 @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM DBO.WorkOrderWorkFlow WITH (NOLOCK)
							WHERE WorkOrderPartNoId = @SWOPartNumberId AND WorkOrderId = @SubWorkOrderId

							SELECT TOP 1 @TaskStatusId = TaskStatusId FROM DBO.TaskStatus WITH (NOLOCK) WHERE [Description] = 'PENDING' AND MasterCompanyId = @MasterCompanyId
							SELECT TOP 1 @EmployeeId = EmployeeId FROM DBO.Employee WITH (NOLOCK) WHERE FirstName = 'TBD' AND MasterCompanyId = @MasterCompanyId
							SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @SWOPartNumberId AND MasterCompanyId = @MasterCompanyId
							SELECT TOP 1 @LaborHoursId = ISNULL(LaborHoursId, 1), @laborHoursMedthodId = ISNULL(laborHoursMedthodId, 1) FROM DBO.LaborOHSettings WITH (NOLOCK) WHERE ManagementStructureId = @ManagementStructureId AND MasterCompanyId = @MasterCompanyId

							DECLARE @LaborWorkOrderTaskId BIGINT;
							DECLARE @LaborTotalCounts INT = 0;
							DECLARE @LaborCount INT = 1;
							DECLARE @LaborWorkFlowTaskId BIGINT;

							IF OBJECT_ID(N'tempdb..#tmpWorkflowLaborTask') IS NOT NULL
							BEGIN
							DROP TABLE #tmpWorkflowLaborTask
							END
			
							CREATE TABLE #tmpWorkflowLaborTask
							(
								ID BIGINT NOT NULL IDENTITY, 
								[TaskId] [bigint] NOT NULL,
								[WorkflowId] [bigint] NOT NULL,
							)

							IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderLaborHeader WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId)
							BEGIN								
								SELECT @WorkOrderLaborHeaderId = SubWorkOrderLaborHeaderId FROM DBO.SubWorkOrderLaborHeader WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId
								
								IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowExpertiseList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
								BEGIN
									IF(@IsTaskBasedWO > 0)
									BEGIN
										INSERT INTO #tmpWorkflowLaborTask(TaskId, WorkflowId)
										SELECT DISTINCT TaskId, WorkflowId FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) WHERE WorkflowId = @WorkflowId

										SELECT @LaborTotalCounts = COUNT(ID) FROM #tmpWorkflowLaborTask;

										WHILE @LaborCount<= @LaborTotalCounts
										BEGIN
											SELECT DISTINCT @LaborWorkFlowTaskId = TaskId FROM #tmpWorkflowLaborTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ID = ISNULL(@LaborCount, 0)

											IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @LaborWorkFlowTaskId)
											BEGIN
												SELECT @LaborWorkOrderTaskId = SubWorkOrderTaskId FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @LaborWorkFlowTaskId
											END
											ELSE
											BEGIN
												INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
														SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
												SELECT TOP 1
													@WorkOrderId, 
													@SubWorkOrderId, 
													@SWOPartNumberId,
													WFE.TaskId,
													CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
													@CreatedBy AS CreatedBy,
													@CreatedBy AS UpdatedBy,
													GETUTCDATE() AS CreatedDate,
													GETUTCDATE() AS UpdatedDate,
													1 AS IsActive,
													0 AS IsDeleted,
													ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
													T.IsPrintInWO AS IsIncludeInPrint,											
													0 as HasInstruction,
													T.[Description] as TaskName,
													1 AS IsFromWorkFlow
												FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) 
													JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
												WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId       

												SELECT @LaborWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

												INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
															IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
												SELECT TOP 1 @LaborWorkOrderTaskId, 
													T.Descrepancy AS Descrepancy, 
													T.Resolution AS Resolution,
													0 as HasInstruction,
													CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
													@CreatedBy AS CreatedBy,
													@CreatedBy AS UpdatedBy,
													GETUTCDATE() AS CreatedDate,
													GETUTCDATE() AS UpdatedDate, 
													1 AS IsActive,	
													0 AS IsDeleted,
													T.IsPrintInWO AS IsIncludeInPrint,
													T.IsPrintInWOQ AS IsPrintInWOQ,
													T.IsPrintInspector AS IsPrintInspector,
													T.IsPrintTechnician AS IsPrintTechnician
												FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) 
													JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
												WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId 

											END

											INSERT INTO DBO.SubWorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours,BurdaenRatePercentageId,
											BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, SubWorkOrderLaborHeaderId, StandardHours, StandardMinute, StatusChangedDate)
											SELECT 
												@createdBy AS CreatedBy,
												@createdBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												CAST(wfe.ExpertiseTypeId AS INT) AS ExpertiseId,
												@masterCompanyId AS MasterCompanyId,
												wfe.EstimatedHours AS [Hours],
												wfe.EstimatedHours AS AdjustedHours,
												wfe.OverheadburdenPercentId AS BurdaenRatePercentageId,
												ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS BurdenRateAmount,
												ISNULL(wfe.LaborDirectRate, 0) AS DirectLaborOHCost,
												ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS TotalCostPerHour,
												--Calculate Hour and Minutes and total Cost
												ISNULL((LEFT(CAST(wfe.EstimatedHours AS varchar(100)), CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))) - 1)) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0))  
												 + (((RIGHT(CAST(wfe.EstimatedHours AS varchar(100)), LEN(CAST(wfe.EstimatedHours AS varchar(100))) - CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))))) * 100) / 60) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0)), 0) 
												AS TotalCost,
												wfe.memo,
												@LaborWorkOrderTaskId AS TaskId,
												@TaskStatusId AS TaskStatusId,
												NULL AS EmployeeId,
												1 AS BillableId,
												1 AS IsFromWorkFlow,
												@WorkOrderLaborHeaderId AS WorkOrderLaborHeaderId,
												T.StandardHours,
												T.StandardMinute,
												GETUTCDATE() AS StatusChangedDate
											FROM DBO.WorkflowExpertiseList wfe WITH(NOLOCK) 
												JOIN dbo.Task T ON T.TaskId = wfe.TaskId 
											WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId ;

											UPDATE woe
											SET woe.IsFromWorkFlow = 1
											FROM DBO.WorkOrderExpertise woe
											JOIN DBO.WorkflowExpertiseList wfe ON wfe.WorkflowId = @WorkflowId AND wfe.TaskId = @LaborWorkFlowTaskId
												AND woe.WorkOrderId = @SubWorkOrderId AND woe.MasterCompanyId = @masterCompanyId
												AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;

											SET @LaborCount = @LaborCount + 1;
										END

									END
									ELSE 
									BEGIN
										INSERT INTO DBO.SubWorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours,BurdaenRatePercentageId,
											BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, SubWorkOrderLaborHeaderId, StandardHours, StandardMinute, StatusChangedDate)
											SELECT 
												@createdBy AS CreatedBy,
												@createdBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												CAST(wfe.ExpertiseTypeId AS INT) AS ExpertiseId,
												@masterCompanyId AS MasterCompanyId,
												wfe.EstimatedHours AS [Hours],
												wfe.EstimatedHours AS AdjustedHours,
												wfe.OverheadburdenPercentId AS BurdaenRatePercentageId,
												ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS BurdenRateAmount,
												ISNULL(wfe.LaborDirectRate, 0) AS DirectLaborOHCost,
												ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS TotalCostPerHour,
												--Calculate Hour and Minutes and total Cost
												ISNULL((LEFT(CAST(wfe.EstimatedHours AS varchar(100)), CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))) - 1)) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0))  
												 + (((RIGHT(CAST(wfe.EstimatedHours AS varchar(100)), LEN(CAST(wfe.EstimatedHours AS varchar(100))) - CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))))) * 100) / 60) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0)), 0) 
												AS TotalCost,
												wfe.memo,
												wfe.TaskId AS TaskId,
												@TaskStatusId AS TaskStatusId,
												NULL AS EmployeeId,
												1 AS BillableId,
												1 AS IsFromWorkFlow,
												@WorkOrderLaborHeaderId AS WorkOrderLaborHeaderId,
												T.StandardHours,
												T.StandardMinute,
												GETUTCDATE() AS StatusChangedDate
											FROM DBO.WorkflowExpertiseList wfe WITH(NOLOCK) 
												JOIN dbo.Task T ON T.TaskId = wfe.TaskId 
											WHERE WorkflowId = @WorkflowId;

											UPDATE woe
											SET woe.IsFromWorkFlow = 1
											FROM DBO.WorkOrderExpertise woe
											JOIN DBO.WorkflowExpertiseList wfe ON wfe.WorkflowId = @WorkflowId
												AND woe.WorkOrderId = @SubWorkOrderId AND woe.MasterCompanyId = @masterCompanyId
												AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;
									END
								END
							END
							ELSE 
							BEGIN
								DECLARE @ExpertiseId BIGINT;
								SELECT TOP 1 @ExpertiseId = CAST(wfe.ExpertiseTypeId AS INT) FROM DBO.WorkflowExpertiseList wfe WITH(NOLOCK) WHERE WorkflowId = @WorkflowId;

								INSERT INTO dbo.SubWorkOrderLaborHeader(WorkOrderId,SubWorkOrderId,SubWOPartNoId,DataEnteredBy,HoursorClockorScan,WorkOrderHoursType,
										MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,ExpertiseId,EmployeeId)
								SELECT @WorkOrderId, @SubWorkOrderId, @SWOPartNumberId, @createdById AS DataEnteredBy, @laborHoursMedthodId AS HoursorClockorScan, @LaborHoursId As WorkOrderHoursType,
										@MasterCompanyId, @createdBy AS CreatedBy, @createdBy AS UpdatedBy,GETUTCDATE() AS CreatedDate,GETUTCDATE() AS UpdatedDate,
										1 AS IsActive, 0 AS IsDeleted, @ExpertiseId, @createdById

								SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()  

								IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowExpertiseList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
								BEGIN
									IF(@IsTaskBasedWO > 0)
									BEGIN
										DELETE FROM #tmpWorkflowLaborTask

										INSERT INTO #tmpWorkflowLaborTask(TaskId, WorkflowId)
										SELECT DISTINCT TaskId, WorkflowId FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) WHERE WorkflowId = @WorkflowId

										SELECT @LaborTotalCounts = COUNT(ID) FROM #tmpWorkflowLaborTask;

										WHILE @LaborCount<= @LaborTotalCounts
										BEGIN
											SELECT DISTINCT @LaborWorkFlowTaskId = TaskId FROM #tmpWorkflowLaborTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ID = ISNULL(@LaborCount, 0)

											IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @LaborWorkFlowTaskId)
											BEGIN
												SELECT @LaborWorkOrderTaskId = SubWorkOrderTaskId FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @LaborWorkFlowTaskId
											END
											ELSE
											BEGIN
												INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
														SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
												SELECT TOP 1
													@WorkOrderId, 
													@SubWorkOrderId, 
													@SWOPartNumberId,
													WFE.TaskId,
													CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
													@CreatedBy AS CreatedBy,
													@CreatedBy AS UpdatedBy,
													GETUTCDATE() AS CreatedDate,
													GETUTCDATE() AS UpdatedDate,
													1 AS IsActive,
													0 AS IsDeleted,
													ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
													T.IsPrintInWO AS IsIncludeInPrint,											
													0 as HasInstruction,
													T.[Description] as TaskName,
													1 AS IsFromWorkFlow
												FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) 
													JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
												WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId       

												SELECT @LaborWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

												INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
															IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
												SELECT TOP 1 
													@LaborWorkOrderTaskId, 
													T.Descrepancy AS Descrepancy, 
													T.Resolution AS Resolution,
													0 as HasInstruction,
													CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
													@CreatedBy AS CreatedBy,
													@CreatedBy AS UpdatedBy,
													GETUTCDATE() AS CreatedDate,
													GETUTCDATE() AS UpdatedDate, 
													1 AS IsActive,	
													0 AS IsDeleted,
													T.IsPrintInWO AS IsIncludeInPrint,
													T.IsPrintInWOQ AS IsPrintInWOQ,
													T.IsPrintInspector AS IsPrintInspector,
													T.IsPrintTechnician AS IsPrintTechnician
												FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) 
													JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
												WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId 

											END

											INSERT INTO DBO.SubWorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours, BurdaenRatePercentageId,
													BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, SubWorkOrderLaborHeaderId,StandardHours, StandardMinute, StatusChangedDate)
											SELECT 
												@createdBy AS CreatedBy,
												@createdBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												CAST(wfe.ExpertiseTypeId AS INT) AS ExpertiseId,
												@masterCompanyId AS MasterCompanyId,
												wfe.EstimatedHours AS [Hours],
												wfe.EstimatedHours AS AdjustedHours,
												wfe.OverheadburdenPercentId AS BurdaenRatePercentageId,
												ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS BurdenRateAmount,
												ISNULL(wfe.LaborDirectRate, 0) AS DirectLaborOHCost,
												ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS TotalCostPerHour,
												--Calculate Hour and Minutes and total Cost
												ISNULL((LEFT(CAST(wfe.EstimatedHours AS varchar(100)), CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))) - 1)) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0))  
												 + (((RIGHT(CAST(wfe.EstimatedHours AS varchar(100)), LEN(CAST(wfe.EstimatedHours AS varchar(100))) - CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))))) * 100) / 60) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0)), 0) 
												AS TotalCost,
												wfe.memo,
												@LaborWorkOrderTaskId AS TaskId,
												@TaskStatusId AS TaskStatusId,
												NULL AS EmployeeId,
												1 AS BillableId,
												1 AS IsFromWorkFlow,
												@WorkOrderLaborHeaderId AS WorkOrderLaborHeaderId,
												T.StandardHours,
												T.StandardMinute,
												GETUTCDATE() AS StatusChangedDate
											FROM DBO.WorkflowExpertiseList wfe WITH(NOLOCK)  
												JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = wfe.TaskId 
											WHERE WorkflowId = @WorkflowId AND wfe.TaskId = @LaborWorkFlowTaskId;

											UPDATE woe
											SET woe.IsFromWorkFlow = 1
											FROM DBO.WorkOrderExpertise woe
											JOIN DBO.WorkflowExpertiseList wfe ON wfe.WorkflowId = @WorkflowId 
												AND woe.WorkOrderId = @SubWorkOrderId AND woe.MasterCompanyId = @masterCompanyId
												AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId AND wfe.TaskId = @LaborWorkFlowTaskId;

											SET @LaborCount = @LaborCount + 1;
										END

									END
									ELSE
									BEGIN
										INSERT INTO DBO.SubWorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours, BurdaenRatePercentageId,
											BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, SubWorkOrderLaborHeaderId,StandardHours, StandardMinute, StatusChangedDate)
										SELECT 
											@createdBy AS CreatedBy,
											@createdBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate,
											1 AS IsActive,
											0 AS IsDeleted,
											CAST(wfe.ExpertiseTypeId AS INT) AS ExpertiseId,
											@masterCompanyId AS MasterCompanyId,
											wfe.EstimatedHours AS [Hours],
											wfe.EstimatedHours AS AdjustedHours,
											wfe.OverheadburdenPercentId AS BurdaenRatePercentageId,
											ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS BurdenRateAmount,
											ISNULL(wfe.LaborDirectRate, 0) AS DirectLaborOHCost,
											ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0) AS TotalCostPerHour,
											--Calculate Hour and Minutes and total Cost
											ISNULL((LEFT(CAST(wfe.EstimatedHours AS varchar(100)), CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))) - 1)) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0))  
											 + (((RIGHT(CAST(wfe.EstimatedHours AS varchar(100)), LEN(CAST(wfe.EstimatedHours AS varchar(100))) - CHARINDEX('.', CAST(wfe.EstimatedHours AS varchar(100))))) * 100) / 60) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0)), 0) 
											AS TotalCost,
											wfe.memo,
											wfe.TaskId AS TaskId,
											@TaskStatusId AS TaskStatusId,
											NULL AS EmployeeId,
											1 AS BillableId,
											1 AS IsFromWorkFlow,
											@WorkOrderLaborHeaderId AS WorkOrderLaborHeaderId,
											T.StandardHours,
											T.StandardMinute,
											GETUTCDATE() AS StatusChangedDate
										FROM DBO.WorkflowExpertiseList wfe WITH(NOLOCK)  
											JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = wfe.TaskId 
										WHERE WorkflowId = @WorkflowId;

										UPDATE woe
										SET woe.IsFromWorkFlow = 1
										FROM DBO.WorkOrderExpertise woe
										JOIN DBO.WorkflowExpertiseList wfe ON wfe.WorkflowId = @WorkflowId 
											AND woe.WorkOrderId = @SubWorkOrderId AND woe.MasterCompanyId = @masterCompanyId
											AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;
									END
								END
							END
						END
						
						IF (@IsDirectionsAllreadyCopied <> 1 AND @Directions = 'Directions' AND @IsTaskBasedWO = 1)
						BEGIN
							IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowDirection WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
							BEGIN
								DECLARE @WorkOrderTaskId BIGINT;
								DECLARE @TotalCounts INT = 0;
								DECLARE @Count INT = 1;
								DECLARE @WorkFlowTaskId BIGINT;

								IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialsKit') IS NOT NULL
								BEGIN
								DROP TABLE #tmpWorkflowDirectionTask
								END
			
								CREATE TABLE #tmpWorkflowDirectionTask
								(
									ID BIGINT NOT NULL IDENTITY, 
									[TaskId] [bigint] NOT NULL,
									[WorkflowId] [bigint] NOT NULL,
								)
									
								INSERT INTO #tmpWorkflowDirectionTask(TaskId, WorkflowId)
								SELECT DISTINCT TaskId, WorkflowId FROM dbo.WorkflowDirection WFD WITH (NOLOCK) WHERE WorkflowId = @WorkflowId

								SELECT @TotalCounts = COUNT(ID) FROM #tmpWorkflowDirectionTask;

								WHILE @Count<= @TotalCounts
								BEGIN
									SELECT DISTINCT @WorkFlowTaskId = TaskId FROM #tmpWorkflowDirectionTask WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ID = ISNULL(@Count, 0)

									IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId =  @SWOPartNumberId AND TaskId = @WorkFlowTaskId)
									BEGIN
										SELECT @WorkOrderTaskId = SubWorkOrderTaskId FROM DBO.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId AND TaskId = @WorkFlowTaskId
									END
									ELSE
									BEGIN
										INSERT INTO DBO.SubWorkOrderTask(WorkOrderId,SubWorkOrderId,SubWOPartNoId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
											SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
										SELECT TOP 1
											@WorkOrderId,
											@SubWorkOrderId,
											@SWOPartNumberId,
											WFD.TaskId,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											@CreatedBy AS CreatedBy,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate,
											1 AS IsActive,
											0 AS IsDeleted,
											ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.SubWorkOrderTask WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWOPartNoId = @SWOPartNumberId GROUP BY SubWorkOrderId, SubWOPartNoId), 1),
											T.IsPrintInWO AS IsIncludeInPrint,
											0 as HasInstruction,
											T.[Description] as TaskName,
											1 AS IsFromWorkFlow
										FROM dbo.WorkflowDirection WFD WITH (NOLOCK) 
											JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
										WHERE WorkflowId = @WorkflowId AND ISNULL(WFD.IsTaskDetails, 0) = 1 AND WFD.TaskId = @WorkFlowTaskId            -- Here Need to add condition for Parent Task 										

										SELECT @WorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

										INSERT INTO dbo.SubWorkOrderTaskDetails(SubWorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
										SELECT TOP 1 
											@WorkOrderTaskId, 
											WFD.[Action] AS Descrepancy, 
											WFD.[Description] AS Resolution,
											0 as HasInstruction,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											@CreatedBy AS CreatedBy,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate, 
											1 AS IsActive,	
											0 AS IsDeleted,
											T.IsPrintInWO AS IsIncludeInPrint,											
											T.IsPrintInWOQ AS IsPrintInWOQ,
											T.IsPrintInspector AS IsPrintInspector,
											T.IsPrintTechnician AS IsPrintTechnician
										FROM dbo.WorkflowDirection WFD WITH (NOLOCK) 
											JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
										WHERE WorkflowId = @WorkflowId AND ISNULL(WFD.IsTaskDetails, 0) = 1 AND WFD.TaskId = @WorkFlowTaskId       -- Here Need to add condition for Parent Task
									END

									IF OBJECT_ID(N'tempdb..#tmpWorkflowDirection') IS NOT NULL
									BEGIN
									DROP TABLE #tmpWorkflowDirection
									END
			
									CREATE TABLE #tmpWorkflowDirection
									(
										ID BIGINT NOT NULL IDENTITY, 
										[WorkOrderTaskId] [BIGINT] NOT NULL,
										[WorkflowDirectionId] [BIGINT] NOT NULL,
										[ParentId] [BIGINT] NULL,
										[IsParent] BIT NULL,
										[InstructionTitle] VARCHAR(MAX) NULL,
										[SequenceNumber] VARCHAR(100) NULL,
										[InstructionDetails] VARCHAR(MAX) NULL,
										[PrintInWO] BIT NULL,
										[MasterCompanyId] [INT] NULL,
										[CreatedBy] VARCHAR(100) NULL,
										[UpdatedBy] VARCHAR(100) NULL,
										[CreatedDate] DATETIME NULL,
										[UpdatedDate] DATETIME NULL,
										[IsActive] BIT NULL,
										[IsDeleted] BIT NULL,										
										[IsFromWorkFlow] BIT NULL,
										[NewParentId] [BIGINT] NULL,
									)
									
									;WITH ParentInstructions AS (
										SELECT 
											WFD.WorkflowDirectionId,
											NULL AS ParentId,
											1 AS IsParent,
											WFD.[Action] AS InstructionTitle,
											WFD.[Description] AS InstructionDetails,
											T.IsPrintInWO,
											ROW_NUMBER() OVER (ORDER BY WFD.WorkflowDirectionId) AS ParentSequence
										FROM dbo.WorkflowDirection WFD WITH (NOLOCK)
										LEFT JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
										WHERE WFD.WorkflowId = @WorkflowId 
											AND ISNULL(WFD.IsTaskDetails, 0) = 0
											AND WFD.TaskId = @WorkFlowTaskId
											AND ISNULL(WFD.IsParent, 0) = 1
											AND ISNULL(WFD.IsActive, 0) = 1 
											AND ISNULL(WFD.IsDeleted, 0) = 0
									),
									ChildInstructions AS (
										SELECT 
											WFD.WorkflowDirectionId,
											WFD.ParentId,
											0 AS IsParent,
											WFD.[Action] AS InstructionTitle,
											WFD.[Description] AS InstructionDetails,
											T.IsPrintInWO,
											ROW_NUMBER() OVER (
												PARTITION BY WFD.ParentId 
												ORDER BY WFD.WorkflowDirectionId
											) AS ChildSequence
										FROM dbo.WorkflowDirection WFD WITH (NOLOCK)
										LEFT JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
										WHERE WFD.WorkflowId = @WorkflowId 
											AND ISNULL(WFD.IsTaskDetails, 0) = 0
											AND WFD.TaskId = @WorkFlowTaskId
											AND ISNULL(WFD.IsParent, 0) = 0
											AND ISNULL(WFD.IsActive, 0) = 1 
											AND ISNULL(WFD.IsDeleted, 0) = 0
									)

									INSERT INTO #tmpWorkflowDirection(WorkOrderTaskId,WorkflowDirectionId,ParentId,IsParent,InstructionTitle,SequenceNumber,InstructionDetails,PrintInWO,
												MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsFromWorkFlow)
									SELECT 
										@WorkOrderTaskId,
										p.WorkflowDirectionId,
										NULL AS ParentId,
										1 AS IsParent,
										p.InstructionTitle,
										CAST(p.ParentSequence AS VARCHAR(100)) AS SequenceNumber,
										p.InstructionDetails,
										p.IsPrintInWO,
										@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 1
									FROM ParentInstructions p

									UNION ALL

									SELECT 
										@WorkOrderTaskId,
										c.WorkflowDirectionId,
										c.ParentId,
										0 AS IsParent,
										c.InstructionTitle,
										CAST(c.ChildSequence AS VARCHAR(100)) AS SequenceNumber,
										c.InstructionDetails,
										c.IsPrintInWO,
										@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 1
									FROM ChildInstructions c
									ORDER BY ParentId, IsParent DESC, SequenceNumber;

									--FROM dbo.WorkflowDirection WFD WITH (NOLOCK) 
									--	LEFT JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
									--WHERE WorkflowId = @WorkflowId AND ISNULL(WFD.IsTaskDetails, 0) = 0 AND WFD.TaskId = @WorkFlowTaskId AND ISNULL(WFD.IsActive, 0) = 1 AND ISNULL(WFD.IsDeleted, 0) = 0
									--ORDER BY WFD.ParentId ,  ISNULL(ParentId, WorkflowDirectionId), SequenceNumber;
									
									DECLARE @TotalRecords BIGINT = 0, @CurrentRecordId BIGINT = 1, @NewOrderTaskInstId BIGINT, @ParentWorkflowDirectionId BIGINT;

									SELECT @TotalRecords = COUNT([ID]) FROM #tmpWorkflowDirection;

									WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecordId, 0))
									BEGIN
										
										SELECT @ParentWorkflowDirectionId = WorkflowDirectionId  FROM #tmpWorkflowDirection WHERE ID = @CurrentRecordId

										INSERT INTO SubWorkOrderTaskInstruction(SubWorkOrderTaskId,ParentId,IsParent,InstructionTitle,SequenceNumber,InstructionDetails,PrintInWO,
												MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsFromWorkFlow)
										SELECT WorkOrderTaskId,NewParentId,IsParent,InstructionTitle,SequenceNumber,InstructionDetails,PrintInWO,
												MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsFromWorkFlow
										FROM #tmpWorkflowDirection WHERE ID = @CurrentRecordId

										SET @NewOrderTaskInstId = SCOPE_IDENTITY();

										UPDATE #tmpWorkflowDirection SET NewParentId  = @NewOrderTaskInstId FROM #tmpWorkflowDirection WHERE ParentId = @ParentWorkflowDirectionId

										SET @CurrentRecordId += 1;
									END

									IF OBJECT_ID(N'tempdb..#tmpWorkflowDirection') IS NOT NULL
									BEGIN
									DROP TABLE #tmpWorkflowDirection
									END

									SET @count = @count + 1;
								END

							END
						END
					
					END
				END
			END

			SELECT @PartIgnored AS PartIgnored
		END
		COMMIT TRANSACTION
	END TRY
BEGIN CATCH
SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
   IF @@trancount > 0
    PRINT 'ROLLBACK'
	CLOSE material_cursors
	DEALLOCATE material_cursors

	CLOSE newmaterial_cursors
	DEALLOCATE newmaterial_cursors
    ROLLBACK TRAN;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CopyWorkFlowDetailsToSubWorkOrder'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@SubWorkOrderId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END