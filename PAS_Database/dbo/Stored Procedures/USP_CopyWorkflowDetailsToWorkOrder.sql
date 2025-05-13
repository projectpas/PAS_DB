/*************************************************************
 ** File:   [USP_CopyWorkflowDetailsToWorkOrder]
 ** Author: HEMANT SALIYA
 ** Description: This stored procedure is used to Copy Work flow to Work Order
 ** Purpose:
 ** Date:   01/20/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------   
	1    02/10/2025   HEMANT SALIYA		Initial Drafted
	2    02/17/2025   HEMANT SALIYA		Handel for Task Based or Teardown Based.
	3    02/28/2025   HEMANT SALIYA		Updated for Task Sequence.
	4    03/30/2025   HEMANT SALIYA		Resolved Issue Does not Copied Work flow direction sub child.
	5    05/13/2025   Ekta Chandegra	Resolved wrong sequence number issue when copy work flow directions.

exec sp_executesql N'EXEC USP_CopyWorkflowDetailsToWorkOrder @WorkOrderId,@WorkflowId,@WorkOrderPartNumberId,@MasterCompanyId,@CreatedBy, @CreatedById, 
@ListItem ',N'@WorkOrderId bigint,@WorkflowId bigint,@WorkOrderPartNumberId bigint,@MasterCompanyId int,@CreatedBy nvarchar(16),@CreatedById bigint,@listItem nvarchar(28)',
@WorkOrderId=8625,@WorkflowId=2852,@WorkOrderPartNumberId=8253,@MasterCompanyId=1,@CreatedBy=N'Brandon  Taylor ',@CreatedById=58,@listItem=N',Directions'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CopyWorkflowDetailsToWorkOrder]
	@WorkOrderId BIGINT = 0,
	@WorkflowId BIGINT = 0,
	@WorkOrderPartNumberId BIGINT = 0,
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

			IF (@WorkOrderPartNumberId > 0)
			BEGIN
				IF (@WorkOrderId > 0)
				BEGIN
					DECLARE @WorkFlowWorkOrderId BIGINT;
					SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM DBO.WorkOrderWorkFlow WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNoId = @workOrderPartNumberId;
					SELECT @IsTaskBasedWO = ISNULL(WorkOrderFormTypeId, 0)  FROM DBO.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId 

					IF EXISTS (SELECT TOP 1 1 FROM DBO.Workflow WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1 AND (WorkflowExpirationDate IS NULL OR CAST(WorkflowExpirationDate AS date) >= GETUTCDATE()))
					BEGIN
						DECLARE @IsMaterialsAllreadyCopied BIT = 0;
						DECLARE @IsChargesAllreadyCopied BIT = 0;
						DECLARE @IsExpertiseAlreadyCopied BIT = 0;
						DECLARE @IsEquipmentsAlreadyCopied BIT = 0;
						DECLARE @IsDirectionsAllreadyCopied BIT = 0;
						DECLARE @IsTaskAllreadyCopied BIT = 0;
						DECLARE @LaborHeaderId BIGINT;

						SELECT TOP 1 @LaborHeaderId = WorkOrderLaborHeaderId
						FROM DBO.WorkOrderLaborHeader WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsDeleted, 0) = 0;

						-- Check if expertise has already been copied
						IF @LaborHeaderId IS NOT NULL
						BEGIN
							SELECT TOP 1 @IsExpertiseAlreadyCopied = CAST(IsFromWorkFlow AS BIT)
							FROM DBO.WorkOrderLabor WITH (NOLOCK) WHERE WorkOrderLaborHeaderId = @LaborHeaderId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;
						END

						SELECT TOP 1 @IsEquipmentsAlreadyCopied = CAST(IsFromWorkFlow AS BIT)
						FROM DBO.WorkOrderAssets WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsMaterialsAllreadyCopied = CAST(IsFromWorkFlow AS BIT) FROM DBO.WorkOrderMaterials WITH (NOLOCK)
						WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsChargesAllreadyCopied = CAST(IsFromWorkFlow AS BIT)
						FROM DBO.WorkOrderCharges WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsTaskAllreadyCopied = CAST(IsFromWorkFlow AS BIT)
						FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsFromWorkFlow, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

						SELECT TOP 1 @IsDirectionsAllreadyCopied = CAST(WTI.IsFromWorkFlow AS BIT)
						FROM DBO.WorkOrderTask WOT WITH (NOLOCK) JOIN dbo.WorkOrderTaskInstruction WTI WITH (NOLOCK) ON WOT.WorkOrderTaskId = WTI.WorkOrderTaskId
						WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(WTI.IsFromWorkFlow, 0) = 1 AND ISNULL(WTI.IsDeleted, 0) = 0;

						UPDATE DBO.WorkOrderWorkFlow
						SET WorkOrderId = @WorkOrderId,
							UpdatedDate = GETUTCDATE(),
							UpdatedBy = @createdBy,
							IsActive = 1,
							IsDeleted = 0,
							MasterCompanyId = @MasterCompanyId
						WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNoId = @workOrderPartNumberId;

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

										IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @WorkFlowTasksId)
										BEGIN
											INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
														WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
											SELECT TOP 1
												@WorkOrderId, 
												@WorkFlowWorkOrderId,
												WFT.TaskId,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												@workOrderPartNumberId AS WorkOrderPartNumberId,
												ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
												T.IsPrintInWO AS IsIncludeInPrint,											
												0 as HasInstruction,
												T.[Description] as TaskName,
												1 AS IsFromWorkFlow
											FROM dbo.WorkFlowTask WFT WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFT.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFT.TaskId = @WorkFlowTasksId       

											SELECT @WorkOrderTasksId = SCOPE_IDENTITY(); --Need to check for Multiple Records

											INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
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

										IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @ChargesWorkFlowTaskId)
										BEGIN
											SELECT @WorkOrderChargesTaskId = WorkOrderTaskId FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @ChargesWorkFlowTaskId
										END
										ELSE
										BEGIN
											INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
													WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
											SELECT TOP 1
												@WorkOrderId, 
												@WorkFlowWorkOrderId,
												WFC.TaskId,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												@workOrderPartNumberId AS WorkOrderPartNumberId,
												ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
												T.IsPrintInWO AS IsIncludeInPrint,											
												0 as HasInstruction,
												T.[Description] as TaskName,
												1 AS IsFromWorkFlow
											FROM dbo.WorkflowChargesList WFC WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFC.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFC.TaskId = @ChargesWorkFlowTaskId       

											SELECT @WorkOrderChargesTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

											INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
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
										
										INSERT INTO DBO.WorkOrderCharges (CreatedBy,CreatedDate,IsActive,IsDeleted,ChargesTypeId,MasterCompanyId,Quantity,UpdatedBy,UpdatedDate,VendorId,
										WorkOrderId,WorkFlowWorkOrderId,Description,ExtendedCost,IsFromWorkFlow,TaskId,UnitCost,ReferenceNo)
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
											@WorkFlowWorkOrderId AS WorkFlowWorkOrderId,
											[Description] AS Description,
											ISNULL(ExtendedCost, 0) AS ExtendedCost,
											1 AS IsFromWorkFlow,
											@WorkOrderChargesTaskId AS TaskId,
											ISNULL(UnitCost, 0) AS UnitCost,
											'' AS ReferenceNo
										FROM DBO.WorkflowChargesList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND TaskId = @ChargesWorkFlowTaskId  ;
										
										SET @ChargesCount = @ChargesCount + 1;
									END
								END
								ELSE
								BEGIN
								--For Teardown WO									
									INSERT INTO DBO.WorkOrderCharges (CreatedBy,CreatedDate,IsActive,IsDeleted,ChargesTypeId,MasterCompanyId,Quantity,UpdatedBy,UpdatedDate,VendorId,
									WorkOrderId,WorkFlowWorkOrderId,Description,ExtendedCost,IsFromWorkFlow,TaskId,UnitCost,ReferenceNo)
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
										@WorkFlowWorkOrderId AS WorkFlowWorkOrderId,
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
								FROM DBO.WorkOrderCharges woc
								JOIN DBO.WorkflowChargesList wfc ON wfc.WorkflowId = @WorkflowId 
									AND woc.WorkOrderId = @WorkOrderId AND woc.MasterCompanyId = @MasterCompanyId
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

									IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @ToolsWorkFlowTaskId)
									BEGIN
										SELECT @ToolsWorkOrderTaskId = WorkOrderTaskId FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @ToolsWorkFlowTaskId
									END
									ELSE
									BEGIN
										INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
												WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
										SELECT TOP 1
											@WorkOrderId, 
											@WorkFlowWorkOrderId,
											WFE.TaskId,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											@CreatedBy AS CreatedBy,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate,
											1 AS IsActive,
											0 AS IsDeleted,
											@workOrderPartNumberId AS WorkOrderPartNumberId,
											ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
											T.IsPrintInWO AS IsIncludeInPrint,											
											0 as HasInstruction,
											T.[Description] as TaskName,
											1 AS IsFromWorkFlow
										FROM dbo.WorkflowEquipmentList WFE WITH (NOLOCK) 
											JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
										WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @ToolsWorkFlowTaskId       

										SELECT @ToolsWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

										INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
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
									INSERT INTO DBO.WorkOrderAssets (AssetRecordId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,Quantity,WorkOrderId,
													WorkFlowWorkOrderId,TaskId)
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
										@workOrderId AS WorkOrderId,
										@WorkFlowWorkOrderId AS WorkFlowWorkOrderId,
										@ToolsWorkOrderTaskId AS TaskId
									FROM DBO.WorkflowEquipmentList wfe WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND TaskId = @ToolsWorkFlowTaskId ;

									UPDATE woa
									SET woa.IsFromWorkFlow = 1
									FROM DBO.WorkOrderAssets woa
									JOIN DBO.WorkflowEquipmentList wfe ON wfe.WorkflowId = @WorkflowId 
										AND woa.WorkOrderId = @workOrderId AND woa.MasterCompanyId = @masterCompanyId
										AND woa.AssetRecordId = wfe.AssetId AND wfe.TaskId = @ToolsWorkFlowTaskId
										AND woa.TaskId = @ToolsWorkOrderTaskId;

									SET @ToolsCount = @ToolsCount + 1;
								END
							END
							ELSE
							BEGIN
								IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowEquipmentList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
								BEGIN
									INSERT INTO DBO.WorkOrderAssets (AssetRecordId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,Quantity,WorkOrderId,
									WorkFlowWorkOrderId,TaskId)
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
										@workOrderId AS WorkOrderId,
										@WorkFlowWorkOrderId AS WorkFlowWorkOrderId,
										wfe.TaskId AS TaskId
									FROM DBO.WorkflowEquipmentList wfe WITH (NOLOCK) WHERE WorkflowId = @WorkflowId;

									UPDATE woa
									SET woa.IsFromWorkFlow = 1
									FROM DBO.WorkOrderAssets woa
									JOIN DBO.WorkflowEquipmentList wfe ON wfe.WorkflowId = @WorkflowId 
										AND woa.WorkOrderId = @workOrderId AND woa.MasterCompanyId = @masterCompanyId
										AND woa.AssetRecordId = wfe.AssetId AND woa.TaskId = wfe.TaskId;
								END
							END
						END

						IF (@IsExpertiseAlreadyCopied <> 1 AND @Labor = 'Labor')
						BEGIN
							IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkflowExpertiseList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId)
							BEGIN
								INSERT INTO DBO.WorkOrderExpertise (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,WorkOrderId,MasterCompanyId,ExpertiseTypeId,EstimatedHours,
								WorkFlowWorkOrderId,TaskId)
								SELECT 
									@createdBy AS CreatedBy,
									@createdBy AS UpdatedBy,
									GETUTCDATE() AS CreatedDate,
									GETUTCDATE() AS UpdatedDate,
									1 AS IsActive,
									0 AS IsDeleted,
									@workOrderId AS WorkOrderId,
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
									AND woe.WorkOrderId = @workOrderId AND woe.MasterCompanyId = @masterCompanyId
									AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;
							END
						END

						IF (@IsMaterialsAllreadyCopied <> 1 AND @Materials = 'Materials')
						BEGIN
							DECLARE @IsDER BIT, @IsPMA BIT;

							SELECT @IsDER = ISNULL(IsDER, 0), @IsPMA = ISNULL(IsPMA, 0) FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNumberId;

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

									IF(ISNULL(@PartNumber, '') <> '')
										SET @PartIgnored = @PartIgnored + @PartNumber + ', '
								END

								IF (@IsDER = 0 AND @IsPMA = 1)
								BEGIN
									SELECT TOP 1 @PartNumber = PartNumber
									FROM ItemMaster WITH (NOLOCK)
									WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsPMA, 0) = 1

									IF(ISNULL(@PartNumber, '') <> '')
										SET @PartIgnored = @PartIgnored + @PartNumber + ', '
								END

								-- If IsDER = 1 and IsPMA = 0
								IF @IsDER = 1 AND @IsPMA = 0
								BEGIN
									SELECT TOP 1 @PartNumber = PartNumber
									FROM ItemMaster WITH (NOLOCK)
									WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsDER, 0) = 1

									IF(ISNULL(@PartNumber, '') <> '')
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

								SELECT TOP 1 @WorkFlowWorkOrderId = WorkFlowWorkOrderId
								FROM DBO.WorkOrderWorkFlow WITH (NOLOCK)
								WHERE WorkOrderPartNoId = @workOrderPartNumberId AND WorkOrderId = @workOrderId

								IF(@IsTaskBasedWO > 0)
								BEGIN
									IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @TaskId)
										BEGIN
											SELECT @MaterialsWorkOrderTaskId = WorkOrderTaskId FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @TaskId
										END
										ELSE
										BEGIN
											INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
													WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
											SELECT TOP 1
												@WorkOrderId, 
												@WorkFlowWorkOrderId,
												WFM.TaskId,
												CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
												@CreatedBy AS CreatedBy,
												@CreatedBy AS UpdatedBy,
												GETUTCDATE() AS CreatedDate,
												GETUTCDATE() AS UpdatedDate,
												1 AS IsActive,
												0 AS IsDeleted,
												@workOrderPartNumberId AS WorkOrderPartNumberId,
												ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
												T.IsPrintInWO AS IsIncludeInPrint,											
												0 as HasInstruction,
												T.[Description] as TaskName,
												1 AS IsFromWorkFlow
											FROM dbo.WorkflowMaterial WFM WITH (NOLOCK) 
												JOIN dbo.Task T WITH (NOLOCK) ON WFM.TaskId = T.TaskId
											WHERE WorkflowId = @WorkflowId AND WFM.TaskId = @TaskId       

											SELECT @MaterialsWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

											INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
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
								
									SELECT TOP 1 @WorkOrderMaterialsId = WorkOrderMaterialsId
									FROM DBO.WorkOrderMaterials WITH (NOLOCK)
									WHERE WorkOrderId = @workOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId
									AND MasterCompanyId = @masterCompanyId AND ItemMasterId = @ItemMasterId
									AND ConditionCodeId = @ConditionCodeId AND Item = @Item AND Figure = @Figure AND TaskId = @MaterialsWorkOrderTaskId;
								END
								ELSE
								BEGIN
									SELECT TOP 1 @WorkOrderMaterialsId = WorkOrderMaterialsId
									FROM DBO.WorkOrderMaterials WITH (NOLOCK)
									WHERE WorkOrderId = @workOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId
									AND MasterCompanyId = @masterCompanyId AND ItemMasterId = @ItemMasterId
									AND ConditionCodeId = @ConditionCodeId AND Item = @Item AND Figure = @Figure AND TaskId = @TaskId;
								END

								SELECT @IsDER = ISNULL(IsDER, 0), @IsPMA = ISNULL(IsPMA, 0) FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNumberId;

								IF (@IsDER = 1 AND @IsPMA = 1)
								BEGIN
									IF EXISTS (SELECT 1 FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND (ISNULL(IsDER, 0) = 1 OR ISNULL(IsPMA, 0) = 1))
										SET @IsIgnorePartExist = 1
								END
								ELSE IF (@IsDER = 0 AND @IsPMA = 1)
								BEGIN
									IF EXISTS (SELECT 1 FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsPMA, 0) = 1)
										SET @IsIgnorePartExist = 1
								END
								ELSE IF (@IsDER = 1 AND @IsPMA = 0)
								BEGIN
									IF EXISTS (SELECT 1 FROM DBO.ItemMaster WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsDER, 0) = 1)
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
										INSERT INTO DBO.WorkOrderMaterials (CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, 
																		IsActive, IsDeleted, MasterCompanyId, WorkOrderId, WorkFlowWorkOrderId, 
																		ItemMasterId, TaskId, ConditionCodeId, MaterialMandatoriesId, 
																		ItemClassificationId, Quantity, UnitOfMeasureId, UnitCost, ExtendedCost, 
																		Memo, IsDeferred, ProvisionId, Figure, Item, IsFromWorkFlow)
										SELECT @createdBy, @createdBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 
											   @masterCompanyId, @workOrderId, @WorkFlowWorkOrderId, @ItemMasterId, 
											   CASE WHEN ISNULL(@IsTaskBasedWO, 0) > 0 THEN @MaterialsWorkOrderTaskId ELSE @TaskId END AS TaskId, 
											   @ConditionCodeId, 
											   (SELECT Id FROM @MaterialMandatories WHERE UPPER([Name]) = UPPER(@MaterialMandatoriesName)), 
											   wfm.ItemClassificationId, @Quantity, wfm.UnitOfMeasureId, @UnitCost, @ExtendedCost, 
											   @Memo, @IsDeferred, @ProvisionId, @Figure, @Item, 1
										FROM DBO.WorkflowMaterial wfm WITH (NOLOCK) WHERE WorkflowId = @WorkflowId AND TaskId = @TaskId AND wfm.WorkflowMaterialListId = @WorkflowMaterialListId;
									END
								END

								UPDATE DBO.WorkOrderMaterials SET IsFromWorkFlow = 1 WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;

								FETCH NEXT FROM newmaterial_cursors INTO @ItemMasterId, @ConditionCodeId, @Item, @Figure, @TaskId, @Quantity, @UnitCost, @ExtendedCost, @MaterialMandatoriesName, @Memo, @IsDeferred, @WorkflowMaterialListId
							END

							CLOSE newmaterial_cursors
							DEALLOCATE newmaterial_cursors
						END

						IF (@IsExpertiseAlreadyCopied <> 1 AND @Labor = 'Labor')
						BEGIN
							DECLARE @TaskStatusId BIGINT, @EmployeeId BIGINT, @ManagementStructureId INT, @LaborHoursId INT, @laborHoursMedthodId INT, @WorkOrderLaborHeaderId BIGINT;
							
							SELECT TOP 1 @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM DBO.WorkOrderWorkFlow WITH (NOLOCK)
							WHERE WorkOrderPartNoId = @workOrderPartNumberId AND WorkOrderId = @workOrderId

							SELECT TOP 1 @TaskStatusId = TaskStatusId FROM DBO.TaskStatus WITH (NOLOCK) WHERE [Description] = 'PENDING' AND MasterCompanyId = @MasterCompanyId
							SELECT TOP 1 @EmployeeId = EmployeeId FROM DBO.Employee WITH (NOLOCK) WHERE FirstName = 'TBD' AND MasterCompanyId = @MasterCompanyId
							SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNumberId AND MasterCompanyId = @MasterCompanyId
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

							IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderLaborHeader WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId)
							BEGIN								
								SELECT @WorkOrderLaborHeaderId = WorkOrderLaborHeaderId FROM DBO.WorkOrderLaborHeader WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId
								
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

											IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @LaborWorkFlowTaskId)
											BEGIN
												SELECT @LaborWorkOrderTaskId = WorkOrderTaskId FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @LaborWorkFlowTaskId
											END
											ELSE
											BEGIN
												INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
														WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
												SELECT TOP 1
													@WorkOrderId, 
													@WorkFlowWorkOrderId,
													WFE.TaskId,
													CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
													@CreatedBy AS CreatedBy,
													@CreatedBy AS UpdatedBy,
													GETUTCDATE() AS CreatedDate,
													GETUTCDATE() AS UpdatedDate,
													1 AS IsActive,
													0 AS IsDeleted,
													@workOrderPartNumberId AS WorkOrderPartNumberId,
													ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
													T.IsPrintInWO AS IsIncludeInPrint,											
													0 as HasInstruction,
													T.[Description] as TaskName,
													1 AS IsFromWorkFlow
												FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) 
													JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
												WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId       

												SELECT @LaborWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

												INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
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

											INSERT INTO DBO.WorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours,BurdaenRatePercentageId,
											BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, WorkOrderLaborHeaderId, StandardHours, StandardMinute, StatusChangedDate)
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
												AND woe.WorkOrderId = @workOrderId AND woe.MasterCompanyId = @masterCompanyId
												AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;

											SET @LaborCount = @LaborCount + 1;
										END

									END
									ELSE 
									BEGIN
										INSERT INTO DBO.WorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours,BurdaenRatePercentageId,
											BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, WorkOrderLaborHeaderId, StandardHours, StandardMinute, StatusChangedDate)
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
												AND woe.WorkOrderId = @workOrderId AND woe.MasterCompanyId = @masterCompanyId
												AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId;
									END
								END
							END
							ELSE 
							BEGIN
								DECLARE @ExpertiseId BIGINT;
								SELECT TOP 1 @ExpertiseId = CAST(wfe.ExpertiseTypeId AS INT) FROM DBO.WorkflowExpertiseList wfe WITH(NOLOCK) WHERE WorkflowId = @WorkflowId;

								INSERT INTO dbo.workOrderLaborHeader(WorkOrderId,WorkFlowWorkOrderId,DataEnteredBy,HoursorClockorScan,WorkOrderHoursType,
										MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,ExpertiseId,EmployeeId,WOPartNoId)
								SELECT @WorkOrderId, @WorkFlowWorkOrderId, @createdById AS DataEnteredBy, @laborHoursMedthodId AS HoursorClockorScan, @LaborHoursId As WorkOrderHoursType,
										@MasterCompanyId, @createdBy AS CreatedBy, @createdBy AS UpdatedBy,GETUTCDATE() AS CreatedDate,GETUTCDATE() AS UpdatedDate,
										1 AS IsActive, 0 AS IsDeleted, @ExpertiseId, @createdById, @workOrderPartNumberId

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

											IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @LaborWorkFlowTaskId)
											BEGIN
												SELECT @LaborWorkOrderTaskId = WorkOrderTaskId FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @LaborWorkFlowTaskId
											END
											ELSE
											BEGIN
												INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
														WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
												SELECT TOP 1
													@WorkOrderId, 
													@WorkFlowWorkOrderId,
													WFE.TaskId,
													CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
													@CreatedBy AS CreatedBy,
													@CreatedBy AS UpdatedBy,
													GETUTCDATE() AS CreatedDate,
													GETUTCDATE() AS UpdatedDate,
													1 AS IsActive,
													0 AS IsDeleted,
													@workOrderPartNumberId AS WorkOrderPartNumberId,
													ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
													T.IsPrintInWO AS IsIncludeInPrint,											
													0 as HasInstruction,
													T.[Description] as TaskName,
													1 AS IsFromWorkFlow
												FROM dbo.WorkflowExpertiseList WFE WITH (NOLOCK) 
													JOIN dbo.Task T WITH (NOLOCK) ON WFE.TaskId = T.TaskId
												WHERE WorkflowId = @WorkflowId AND WFE.TaskId = @LaborWorkFlowTaskId       

												SELECT @LaborWorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

												INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,
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

											INSERT INTO DBO.WorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours, BurdaenRatePercentageId,
													BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, WorkOrderLaborHeaderId,StandardHours, StandardMinute, StatusChangedDate)
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
												AND woe.WorkOrderId = @workOrderId AND woe.MasterCompanyId = @masterCompanyId
												AND woe.ExpertiseTypeId = wfe.ExpertiseTypeId AND woe.TaskId = wfe.TaskId AND wfe.TaskId = @LaborWorkFlowTaskId;

											SET @LaborCount = @LaborCount + 1;
										END

									END
									ELSE
									BEGIN
										INSERT INTO DBO.WorkOrderLabor (CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, ExpertiseId,MasterCompanyId,[Hours],AdjustedHours, BurdaenRatePercentageId,
											BurdenRateAmount,DirectLaborOHCost,TotalCostPerHour,TotalCost, Memo, TaskId,TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, WorkOrderLaborHeaderId,StandardHours, StandardMinute, StatusChangedDate)
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
											AND woe.WorkOrderId = @workOrderId AND woe.MasterCompanyId = @masterCompanyId
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

									IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @WorkFlowTaskId)
									BEGIN
										SELECT @WorkOrderTaskId = WorkOrderTaskId FROM DBO.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId =  @WorkFlowWorkOrderId AND TaskId = @WorkFlowTaskId
									END
									ELSE
									BEGIN
										INSERT INTO DBO.WorkOrderTask(WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,
											WorkOrderPartNumberId,SequenceNumber,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
										SELECT TOP 1
											@WorkOrderId, 
											@WorkFlowWorkOrderId,
											WFD.TaskId,
											CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
											@CreatedBy AS CreatedBy,
											@CreatedBy AS UpdatedBy,
											GETUTCDATE() AS CreatedDate,
											GETUTCDATE() AS UpdatedDate,
											1 AS IsActive,
											0 AS IsDeleted,
											@workOrderPartNumberId AS WorkOrderPartNumberId,
											ISNULL((SELECT COALESCE(MAX([SequenceNumber]), 0)  +  1 FROM dbo.WorkOrderTask WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId GROUP BY WorkOrderId, WorkFlowWorkOrderId), 1),
											T.IsPrintInWO AS IsIncludeInPrint,
											0 as HasInstruction,
											T.[Description] as TaskName,
											1 AS IsFromWorkFlow
										FROM dbo.WorkflowDirection WFD WITH (NOLOCK) 
											JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
										WHERE WorkflowId = @WorkflowId AND ISNULL(WFD.IsTaskDetails, 0) = 1 AND WFD.TaskId = @WorkFlowTaskId            -- Here Need to add condition for Parent Task 										

										SELECT @WorkOrderTaskId = SCOPE_IDENTITY(); --Need to check for Multiple Records

										INSERT INTO dbo.WorkOrderTaskDetails(WorkOrderTaskId,Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,PrintInWO, PrintInWOQ, IsPrintInspector,IsPrintTechnician)
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
									
									INSERT INTO #tmpWorkflowDirection(WorkOrderTaskId,WorkflowDirectionId,ParentId,IsParent,InstructionTitle,SequenceNumber,InstructionDetails,PrintInWO,
												MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsFromWorkFlow)
									SELECT @WorkOrderTaskId AS WorkOrderTaskId, 
										WFD.WorkflowDirectionId AS WorkflowDirectionId,
										WFD.ParentId,
										ISNULL(WFD.IsParent, 0) AS IsParent,
										WFD.[Action] AS InstructionTitle, 
										WFD.[Sequence] AS SequenceNumber, 
										WFD.[Description] AS InstructionDetails,
										T.IsPrintInWO AS PrintInWO,
										CAST(@MasterCompanyId AS INT) AS MasterCompanyId,
										@CreatedBy AS CreatedBy,
										@CreatedBy AS UpdatedBy,
										GETUTCDATE() AS CreatedDate,
										GETUTCDATE() AS UpdatedDate, 
										1 AS IsActive,	
										0 AS IsDeleted,
										1 AS IsFromWorkFlow									
									FROM dbo.WorkflowDirection WFD WITH (NOLOCK) 
										LEFT JOIN dbo.Task T WITH (NOLOCK) ON WFD.TaskId = T.TaskId
									WHERE WorkflowId = @WorkflowId AND ISNULL(WFD.IsTaskDetails, 0) = 0 AND WFD.TaskId = @WorkFlowTaskId AND ISNULL(WFD.IsActive, 0) = 1 AND ISNULL(WFD.IsDeleted, 0) = 0
									ORDER BY WFD.ParentId ,  ISNULL(ParentId, WorkflowDirectionId), SequenceNumber;
									--ORDER BY WFD.[Sequence] ASC,  WFD.ParentId ASC,ISNULL(WFD.IsParent, 0) DESC

									DECLARE @TotalRecords BIGINT = 0, @CurrentRecordId BIGINT = 1, @NewOrderTaskInstId BIGINT, @ParentWorkflowDirectionId BIGINT;

									SELECT @TotalRecords = COUNT([ID]) FROM #tmpWorkflowDirection;

									WHILE(ISNULL(@CurrentRecordId , 0) <= ISNULL(@TotalRecords, 0))
									BEGIN
										DECLARE @CurrWorkflowDirectionId BIGINT;
										DECLARE @CurrParentWorkflowDirectionId BIGINT;
										DECLARE @NextParentSequence INT;
										DECLARE @IsParent BIT;
										DECLARE @CustomSequenceNumber INT;

										-- Get current instruction's data
										SELECT 
											@CurrWorkflowDirectionId = WorkflowDirectionId,
											@CurrParentWorkflowDirectionId = ParentId,
											@IsParent = IsParent,
											@CustomSequenceNumber = SequenceNumber
										FROM #tmpWorkflowDirection
										WHERE ID = @CurrentRecordId;

										-- Determine sequence number
										IF @CurrParentWorkflowDirectionId IS NULL
										BEGIN
											-- Generate sequence for parent nodes
											SELECT @NextParentSequence = ISNULL(MAX(SequenceNumber), 0) + 1
											FROM [dbo].[WorkOrderTaskInstruction] WITH(NOLOCK)
											WHERE WorkOrderTaskId = @WorkOrderTaskId AND ParentId IS NULL;
										END
										ELSE
										BEGIN
											-- Use sequence number from source temp table for children
											SET @NextParentSequence = @CustomSequenceNumber;
										END

										SELECT @ParentWorkflowDirectionId = WorkflowDirectionId  FROM #tmpWorkflowDirection WHERE ID = @CurrentRecordId


										INSERT INTO [dbo].[WorkOrderTaskInstruction](WorkOrderTaskId,ParentId,IsParent,InstructionTitle,SequenceNumber,InstructionDetails,PrintInWO,
												MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsFromWorkFlow)
										SELECT WorkOrderTaskId,NewParentId,IsParent,InstructionTitle,@NextParentSequence,InstructionDetails,PrintInWO,
												MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,IsFromWorkFlow
										FROM #tmpWorkflowDirection WHERE ID = @CurrentRecordId

										SET @NewOrderTaskInstId = SCOPE_IDENTITY();

										UPDATE #tmpWorkflowDirection SET NewParentId  = @NewOrderTaskInstId FROM #tmpWorkflowDirection WHERE ParentId = @ParentWorkflowDirectionId

										SET @CurrentRecordId += 1;
									END

									-- Update SequenceNumber recursively
									;WITH Numbered AS (
										SELECT 
											WorkOrderTaskInstructionId,
											ROW_NUMBER() OVER (
												PARTITION BY ParentId, WorkOrderTaskId
												ORDER BY WorkOrderTaskInstructionId
											) AS NewSequenceNumber
										FROM [dbo].[WorkOrderTaskInstruction] WITH(NOLOCK)
										WHERE WorkOrderTaskId = @WorkOrderTaskId
									)
									UPDATE WOTI
									SET 
										WOTI.SequenceNumber = N.NewSequenceNumber,
										WOTI.UpdatedBy = @CreatedBy,
										WOTI.UpdatedDate = GETUTCDATE()
									FROM [dbo].[WorkOrderTaskInstruction] WOTI
									INNER JOIN Numbered N ON WOTI.WorkOrderTaskInstructionId = N.WorkOrderTaskInstructionId;


									-- Update ParentSequenceNumber recursively

									;WITH RecursiveCTE AS (
										SELECT 
											WorkOrderTaskInstructionId, ParentId, SequenceNumber,
											CAST(SequenceNumber AS VARCHAR(MAX)) AS ParentSequenceNumber
										FROM [dbo].[WorkOrderTaskInstruction] WITH(NOLOCK)
										WHERE WorkOrderTaskId = @WorkOrderTaskId AND ParentId IS NULL

										UNION ALL

										SELECT 
											W.WorkOrderTaskInstructionId, W.ParentId, W.SequenceNumber,
											CAST(R.ParentSequenceNumber + '.' + CAST(W.SequenceNumber AS VARCHAR) AS VARCHAR(MAX))
										FROM [dbo].[WorkOrderTaskInstruction] W WITH(NOLOCK)
										INNER JOIN RecursiveCTE R ON W.ParentId = R.WorkOrderTaskInstructionId
										WHERE W.WorkOrderTaskId = @WorkOrderTaskId
									)
									UPDATE WOTI
									SET WOTI.ParentSequenceNumber = R.ParentSequenceNumber,
										WOTI.UpdatedBy = @CreatedBy,
										WOTI.UpdatedDate = GETUTCDATE()
									FROM [dbo].[WorkOrderTaskInstruction] WOTI
									INNER JOIN RecursiveCTE R ON WOTI.WorkOrderTaskInstructionId = R.WorkOrderTaskInstructionId;

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
        , @AdhocComments     VARCHAR(150)    = 'USP_CopyWorkflowDetailsToWorkOrder'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@WorkOrderId AS varchar(10)) ,'') +''
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