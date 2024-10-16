﻿
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <01/23/2023>  
** Description: <Save Work Order Materials reserve & Issue Stockline Details>  
  
EXEC [USP_AutoReserveAllWorkOrderMaterials] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date				Author				  Change Description  
** --   --------		-------					--------------------------------
** 1    01/23/2023		 HEMANT SALIYA			Save Work Order Materials reserve Stockline Details
** 2    01/23/2023		 HEMANT SALIYA			Added Altername and Equiv Part Selection
** 3    07/19/2023		 Devendra Shekh			Adding wohistory while part reserve
** 4    07/24/2023		 Vishal Suthar			Added new stockline history
** 5    07/26/2023		 HEMANT SALIYA			Allow User to reserver & Issue other Customer Stock as well
** 6    08/18/2023       AMIT GHEDIYA           Updated for historytext for Wohistory.
** 7    08/18/2023       HEMANT SALIYA          Updated for Condition Group Change
** 8    08/18/2023       HEMANT SALIYA          Updated for Module Id Changes
** 9    06/27/2024       HEMANT SALIYA			Update Stockline Qty Issue fox for MTI(Same Stk with multiple Lines)
** 10   08/02/2024       HEMANT SALIYA			Fixed MTI stk Reserve Qty was not updating
** 11   09/23/2024		 HEMANT SALIYA	        Re-Calculate WOM Qty Res & Qty Issue
** 12   10/03/2024		 RAJESH GAMI 	        Implement the ReferenceNumber column data into WOMaterial | Kit Stockline table. 
EXEC USP_AutoReserveAllWorkOrderMaterials 4761,0,0,98,0
exec sp_executesql N'exec USP_AutoReserveAllWorkOrderMaterials @WorkFlowWorkOrderId, @IncludeAlternate, @IncludeEquiv, @EmployeeId, @IncludeCustomerStk',N'@WorkFlowWorkOrderId bigint,@IncludeAlternate bit,@IncludeEquiv bit,@EmployeeId bigint,@IncludeCustomerStk bit',@WorkFlowWorkOrderId=4761,@IncludeAlternate=0,@IncludeEquiv=0,@EmployeeId=98,@IncludeCustomerStk=0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_AutoReserveAllWorkOrderMaterials]
@WorkFlowWorkOrderId BIGINT,
@IncludeAlternate BIT,
@IncludeEquiv BIT,
@EmployeeId BIGINT,
@IncludeCustomerStock BIT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DECLARE @ProvisionId BIGINT;
					DECLARE @MasterCompanyId BIGINT;
					DECLARE @SubWOProvisionId BIGINT;
					DECLARE @Provision VARCHAR(50);
					DECLARE @ProvisionCode VARCHAR(50);
					DECLARE @ARCondition VARCHAR(50);
					DECLARE @ARConditionId VARCHAR(50);
					DECLARE @CustomerID BIGINT;
					DECLARE @tmpStockLineId BIGINT;

					DECLARE @ARcount INT = 1;
					DECLARE @ARTotalCounts INT = 0;
					DECLARE @tmpActQuantity INT = 0;
					DECLARE @QtytToRes INT = 0;
					DECLARE @NewWorkOrderMaterialsId BIGINT;
					DECLARE @NewStockline BIGINT;
					DECLARE @ModuleId INT;
					DECLARE @SubModuleId INT;
					DECLARE @TotalCountsBoth INT;
					DECLARE @MaterialRefNo VARCHAR(100) = 'Auto Reserve Stock', @WONumber VARCHAR(100);
					DECLARE @Autocount INT;
					DECLARE @Materialscount INT;
					DECLARE @Autoslcount INT;
					DECLARE @AutoTotalCounts INT;
					DECLARE @ActionId INT;
					DECLARE @historypartnumber VARCHAR(150);
					DECLARE @historyWorkOrderPartNoId  BIGINT;
					DECLARE @historyItemMasterId BIGINT;
					DECLARE @HistoryWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
									@historyWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
									@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
									@WorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
									@WorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT;


					SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId, @WONumber=WO.WorkOrderNum  FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
					SELECT @ARCondition = [Description], @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

					SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module

					IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
					BEGIN
						DROP TABLE #ConditionGroup 
					END

					CREATE TABLE #ConditionGroup 
					(
						ID BIGINT NOT NULL IDENTITY, 
						[ConditionId] [BIGINT] NULL,
						[ConditionGroup] VARCHAR(50) NULL,
					)

					INSERT INTO #ConditionGroup (ConditionId, ConditionGroup)
					SELECT ConditionId, GroupCode FROM dbo.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

					--#STEP : 1 RESERVE EXISTING STOCKLINE					
					SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionCodeId AS ConditionId,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							QtyToBeReserved = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 
							SL.StocklineId,
							SL.Condition,
							SL.StockLineNumber,
							SL.ControlNumber,
							SL.IdNumber,
							SL.Manufacturer,
							SL.SerialNumber,
							SL.QuantityAvailable AS QuantityAvailable,
							SL.QuantityOnHand AS QuantityOnHand,
							ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
							ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
							SL.UnitOfMeasure,
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,							
							CASE WHEN (ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							@EmployeeId AS ReservedById,
							WOMS.UpdatedBy AS ReservedBy,
							SL.UnitCost AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded	
						INTO #tmpReserveIssueWOMaterialsStockline
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tmpC.ConditionGroup = C.GroupCode) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId AND WOMS.ConditionId != @ARConditionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					
					--#STEP : 1.1 RESERVE EXISTING STOCKLINE
				
					IF((SELECT COUNT(1) FROM #tmpReserveIssueWOMaterialsStockline) > 0)
					BEGIN
						--CASE 1 UPDATE WORK ORDER MATERILS
						PRINT '#STEP : 1.1 RESERVE EXISTING STOCKLINE'
						DECLARE @count INT;
						DECLARE @count1 INT;
						DECLARE @slcount INT;
						DECLARE @TotalCounts INT;
						DECLARE @StocklineId BIGINT; 						
						DECLARE @ReferenceId BIGINT;
						DECLARE @IsAddUpdate BIT; 
						DECLARE @ExecuteParentChild BIT; 
						DECLARE @UpdateQuantities BIT;
						DECLARE @IsOHUpdated BIT; 
						DECLARE @AddHistoryForNonSerialized BIT; 						
						DECLARE @SubReferenceId BIGINT;
						DECLARE @ReservePartStatus INT;
						DECLARE @WorkOrderMaterialsId BIGINT;
						DECLARE @IsSerialised BIT;
						DECLARE @stockLineQty INT;
						DECLARE @stockLineQtyAvailable INT;
						DECLARE @UpdateBy varchar(200);

						SET @ReservePartStatus = 1; -- FOR RESERTVE
						SET @IsAddUpdate = 0;
						SET @ExecuteParentChild = 1;
						SET @UpdateQuantities = 1;
						SET @IsOHUpdated = 0;
						SET @AddHistoryForNonSerialized = 0;					
						SET @slcount = 1;
						SET @count = 1;
						SET @count1 = 1;

						IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
						BEGIN
						DROP TABLE #tmpReserveWOMaterialsStockline
						END
			
						CREATE TABLE #tmpReserveWOMaterialsStockline
						(
							ID BIGINT NOT NULL IDENTITY, 
							[WorkOrderId] BIGINT NULL,
							[WorkFlowWorkOrderId] BIGINT NULL,
							[WorkOrderMaterialsId] BIGINT NULL,
							[StockLineId] BIGINT NULL,
							[ItemMasterId] BIGINT NULL,
							[ConditionId] BIGINT NULL,
							[ProvisionId] BIGINT NULL,
							[TaskId] BIGINT NULL,
							[ReservedById] BIGINT NULL,
							[Condition] VARCHAR(500) NULL,
							[PartNumber] VARCHAR(500) NULL,
							[PartDescription] VARCHAR(max) NULL,
							[Quantity] INT NULL,
							[QtyToBeReserved] INT NULL,
							[QuantityActReserved] INT NULL,
							[ControlNo] VARCHAR(500) NULL,
							[ControlId] VARCHAR(500) NULL,
							[StockLineNumber] VARCHAR(500) NULL,
							[SerialNumber] VARCHAR(500) NULL,
							[ReservedBy] VARCHAR(500) NULL,						 
							[IsStocklineAdded] BIT NULL,
							[MasterCompanyId] BIGINT NULL,
							[UpdatedBy] VARCHAR(500) NULL,
							[UnitCost] DECIMAL(18,2),
							[IsSerialized] BIT
						)

						IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
						BEGIN
						DROP TABLE #tmpIgnoredStockline
						END
			
						CREATE TABLE #tmpIgnoredStockline
						(
							ID BIGINT NOT NULL IDENTITY, 
							[Condition] VARCHAR(500) NULL,
							[PartNumber] VARCHAR(500) NULL,
							[ControlNo] VARCHAR(500) NULL,
							[ControlId] VARCHAR(500) NULL,
							[StockLineNumber] VARCHAR(500) NULL,
						)

						INSERT INTO #tmpReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized])
						SELECT DISTINCT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
							[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QtyToBeReserved], tblMS.[ControlNumber], tblMS.[IdNumber],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized
						FROM #tmpReserveIssueWOMaterialsStockline tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND SL.QuantityAvailable >= tblMS.MSQunatityRemaining

						SELECT @TotalCounts = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;
						SELECT @TotalCountsBoth = MAX(ID) FROM #tmpReserveWOMaterialsStockline;

						INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
						SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNumber], tblMS.[IdNumber], tblMS.[StockLineNumber] FROM #tmpReserveIssueWOMaterialsStockline tblMS  
						WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpReserveWOMaterialsStockline)

						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @count<= @TotalCounts
						BEGIN
							--Added for WO History 
							SELECT @historyModuleId = moduleId FROM dbo.Module WHERE ModuleName = 'WorkOrder';
							SELECT @historySubModuleId = moduleId FROM dbo.Module WHERE ModuleName = 'WorkOrderMPN';
							SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'ReserveParts';
							SELECT @HistoryWorkOrderMaterialsId = WorkOrderMaterialsId,
								   @historyWorkOrderId = WorkOrderId, @UpdateBy = UpdatedBy,
								   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
								   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved,
								   @historypartNumber = PartNumber
							FROM #tmpReserveWOMaterialsStockline WHERE ID = @count;

							SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @HistoryWorkOrderMaterialsId;
							SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

							SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
							SELECT @ConditionCode = Code FROM dbo.Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
							SELECT @HistoryStockLineNum = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

							SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historypartNumber,''));
						
							SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
							SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
							SELECT @HistoryWorkOrderMaterialsId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK);
							
							IF(@historyQtyToBeReserved > 0)
							BEGIN
								EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','Reserved Parts',@TemplateBody,'ReserveParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
							END

							UPDATE WorkOrderMaterials 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),									
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM dbo.WorkOrderMaterials WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count
							SET @count = @count + 1;
						END;
					
						PRINT '--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS'

						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@TotalCounts > 0 )
						BEGIN
							MERGE dbo.WorkOrderMaterialStockLine AS TARGET
							USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
									TARGET.UnitCost = ISNULL(SOURCE.UnitCost, 0),
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0),
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0),
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy,
									TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,ReferenceNumber) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, SOURCE.QuantityActReserved, 0, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0,@MaterialRefNo + ' - '+@WONumber);
						END

						PRINT '--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY'
						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE dbo.WorkOrderMaterialStockLine 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) ,ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
						FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						PRINT '--FOR UPDATED WORKORDER MATERIALS QTY'
						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE dbo.WorkOrderMaterials 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterials WOM  WITH(NOLOCK)
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterials.Quantity,0)	
						
						--RE-CALCULATE WOM QTY RES & QTY ISSUE					
						UPDATE dbo.WorkOrderMaterials 
						SET QuantityIssued = GropWOM.QtyIssued, QuantityReserved = GropWOM.QtyReserved
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, ISNULL(SUM(WOMS.QtyReserved), 0) QtyReserved, ISNULL(SUM(WOMS.QtyIssued), 0) QtyIssued, WOM.WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId 
								AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND 
						(ISNULL(GropWOM.QtyReserved,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityReserved,0)	OR ISNULL(GropWOM.QtyIssued,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityIssued,0))

						DECLARE @countKitStockline INT = 1;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countKitStockline <= @TotalCountsBoth
						BEGIN
							DECLARE @tmpKitStockLineId BIGINT = 0;

							SELECT @tmpKitStockLineId = StockLineId FROM #tmpReserveWOMaterialsStockline WHERE ID = @countKitStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActReserved,0),
								WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE tmpRSL.ID = @countKitStockline AND  Sl.StockLineId = @tmpKitStockLineId

							SET @countKitStockline = @countKitStockline + 1;
						END;

						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @count1<= @TotalCounts
						BEGIN
							SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @count1

							EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
							SET @count1 = @count1 + 1;
						END;

						PRINT '--FOR STOCK LINE HISTORY'
						--FOR STOCK LINE HISTORY
						WHILE @slcount<= @TotalCounts
						BEGIN
							DECLARE @ReservedQty bigint = 0;

							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.WorkOrderId,
									@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
									@ReservedQty = QuantityActReserved,
									@UpdateBy = UpdatedBy
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @slcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

							SET @ActionId = 2; -- Reserve
							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

							SET @slcount = @slcount + 1;
						END;

						IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
						BEGIN
							DROP TABLE #tmpIgnoredStockline
						END

						IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
						BEGIN
							DROP TABLE #tmpReserveWOMaterialsStockline
						END
					END

					--#STEP : 2 RESERVE KIT ALTERNATE PARTS 
					IF(ISNULL(@IncludeAlternate, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#AltPartList') IS NOT NULL
						BEGIN
							DROP TABLE #AltPartList 
						END
			
						CREATE TABLE #AltPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						INSERT INTO #AltPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 1 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId != @ARConditionId

						SELECT  
							WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsKitId,
							WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,	
							Alt.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS AltPartMasterPartId,
							WOM.ConditionCodeId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsAltPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineKITAlt
						FROM #AltPartList Alt
							JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId AND WOM.ConditionCodeId != @ARConditionId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineKITAlt') IS NOT NULL
						BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStocklineKITAlt
						END
			
						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineKITAlt
						(
							ID BIGINT NOT NULL IDENTITY, 
							[WorkOrderId] BIGINT NULL,
							[WorkFlowWorkOrderId] BIGINT NULL,
							[WorkOrderMaterialsId] BIGINT NULL,
							[StockLineId] BIGINT NULL,
							[ItemMasterId] BIGINT NULL,
							[AltPartMasterPartId] BIGINT NULL,
							[ConditionId] BIGINT NULL,
							[ProvisionId] BIGINT NULL,
							[TaskId] BIGINT NULL,
							[ReservedById] BIGINT NULL,
							[Condition] VARCHAR(500) NULL,
							[PartNumber] VARCHAR(500) NULL,
							[PartDescription] VARCHAR(max) NULL,
							[Quantity] INT NULL,
							[QuantityAvailable] INT NULL,
							[QuantityOnHand] INT NULL,
							[ActQuantity] INT NULL,
							[QtyToBeReserved] INT NULL,
							[QuantityActReserved] INT NULL,
							[ControlNo] VARCHAR(500) NULL,
							[ControlId] VARCHAR(500) NULL,
							[StockLineNumber] VARCHAR(500) NULL,
							[SerialNumber] VARCHAR(500) NULL,
							[ReservedBy] VARCHAR(500) NULL,						 
							[IsStocklineAdded] BIT NULL,
							[MasterCompanyId] BIGINT NULL,
							[UpdatedBy] VARCHAR(500) NULL,
							[UnitCost] DECIMAL(18,2),
							[IsSerialized] BIT,
							[IsAltPart] BIT,
							[IsActive] BIT,
							[IsDeleted] BIT,
							[CreatedDate] DATETIME2 NULL,
						)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineKITAlt ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId], [AltPartMasterPartId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized], [IsAltPart],[IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId],tblMS.[AltPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
							[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
							SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsAltPart], 1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineKITAlt tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup) 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineKITAlt;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineKITAlt WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineKITAlt
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineKITAlt
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineKITAlt tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineKITAlt
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineKITAlt tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineKITAlt WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMKITAlt FROM #tmpAutoReserveWOMaterialsStocklineKITAlt

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMKITAlt) > 0)
						BEGIN
							SET @Autocount = 0;
							SET @Materialscount = 0;
							SET @Autoslcount = 0;
							SET @AutoTotalCounts = 0;

							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMKITAlt;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE WorkOrderMaterialsKIT 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM dbo.WorkOrderMaterialsKIT WOM JOIN #tmpAutoReserveWOMKITAlt tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKITId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN							
								MERGE dbo.WorkOrderMaterialStockLineKIT AS TARGET
								USING #tmpAutoReserveWOMKITAlt AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsKITId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsAltPart = SOURCE.IsAltPart,
										TARGET.AltPartMasterPartId = SOURCE.AltPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsKITId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, IsAltPart, AltPartMasterPartId,ReferenceNumber) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsAltPart, SOURCE.AltPartMasterPartId,@MaterialRefNo + ' - '+@WONumber);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE dbo.WorkOrderMaterialStockLineKIT 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) ,ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
							FROM dbo.WorkOrderMaterialStockLineKIT WOMS JOIN #tmpAutoReserveWOMKITAlt tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE dbo.WorkOrderMaterialsKIT 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKITId AS WorkOrderMaterialsId
								FROM dbo.WorkOrderMaterialsKIT WOM 
								JOIN dbo.WorkOrderMaterialStockLineKIT WOMS ON WOMS.WorkOrderMaterialsKITId = WOM.WorkOrderMaterialsKITId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsKITId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterialsKIT.WorkOrderMaterialsKITId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterialsKIT.Quantity,0)			

							DECLARE @countStockline INT = 1;
							DECLARE @TotalCountsBothKITAlt INT;
							SELECT @TotalCountsBothKITAlt = MAX(ID) FROM #tmpAutoReserveWOMKITAlt;

							--FOR FOR UPDATED STOCKLINE QTY
							WHILE @countStockline <= @TotalCountsBothKITAlt
							BEGIN
								DECLARE @RowNum1 INT = 0;
								SET @tmpStockLineId = 0;
								SELECT @tmpStockLineId = StockLineId, @RowNum1 = Row_Num  FROM #tmpAutoReserveWOMKITAlt WHERE ID = @countStockline

								--FOR UPDATED STOCKLINE QTY
								UPDATE dbo.Stockline
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
									QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
									WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
								FROM dbo.Stockline SL JOIN #tmpAutoReserveWOMKITAlt tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
								WHERE Sl.StockLineId = @tmpStockLineId AND tmpRSL.Row_Num = @RowNum1

								SET @countStockline = @countStockline + 1;
							END;

							--FOR UPDATE TOTAL WORK ORDER COST
							WHILE @Materialscount<= @AutoTotalCounts
							BEGIN
								SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
								FROM #tmpAutoReserveWOMKITAlt tmpWOM 
								WHERE tmpWOM.ID = @Materialscount

								EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
								SET @Materialscount = @Materialscount + 1;
							END;

							--FOR STOCK LINE HISTORY
							WHILE @Autoslcount<= @AutoTotalCounts
							BEGIN
								SELECT	@StocklineId = tmpWOM.StockLineId,
										@MasterCompanyId = tmpWOM.MasterCompanyId,
										@ReferenceId = tmpWOM.WorkOrderId,
										@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
										@ReservedQty = QuantityActReserved,
										@UpdateBy = UpdatedBy
								FROM #tmpAutoReserveWOMKITAlt tmpWOM 
								WHERE tmpWOM.ID = @Autoslcount

								SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

								SET @ActionId = 2; -- Reserve
								EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

								SET @Autoslcount = @Autoslcount + 1;
							END;
						END
					END

					--#STEP : 2.1 RESERVE MATERIALS ALTERNATE PARTS 
					IF(ISNULL(@IncludeAlternate, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#MaterialsAltPartList') IS NOT NULL
						BEGIN
							DROP TABLE #MaterialsAltPartList 
						END
			
						CREATE TABLE #MaterialsAltPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						INSERT INTO #MaterialsAltPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 1 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId != @ARConditionId

						SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							Alt.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS AltPartMasterPartId,
							WOM.ConditionCodeId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,		
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsAltPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineMaterialsAlt
						FROM #MaterialsAltPartList Alt
							JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId AND WOM.ConditionCodeId != @ARConditionId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineMaterialsAlt') IS NOT NULL
						BEGIN
							DROP TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt
						END
			
						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt
						(
							ID BIGINT NOT NULL IDENTITY, 
							[WorkOrderId] BIGINT NULL,
							[WorkFlowWorkOrderId] BIGINT NULL,
							[WorkOrderMaterialsId] BIGINT NULL,
							[StockLineId] BIGINT NULL,
							[ItemMasterId] BIGINT NULL,
							[AltPartMasterPartId] BIGINT NULL,
							[ConditionId] BIGINT NULL,
							[ProvisionId] BIGINT NULL,
							[TaskId] BIGINT NULL,
							[ReservedById] BIGINT NULL,
							[Condition] VARCHAR(500) NULL,
							[PartNumber] VARCHAR(500) NULL,
							[PartDescription] VARCHAR(max) NULL,
							[Quantity] INT NULL,
							[QuantityAvailable] INT NULL,
							[QuantityOnHand] INT NULL,
							[ActQuantity] INT NULL,
							[QtyToBeReserved] INT NULL,
							[QuantityActReserved] INT NULL,
							[ControlNo] VARCHAR(500) NULL,
							[ControlId] VARCHAR(500) NULL,
							[StockLineNumber] VARCHAR(500) NULL,
							[SerialNumber] VARCHAR(500) NULL,
							[ReservedBy] VARCHAR(500) NULL,						 
							[IsStocklineAdded] BIT NULL,
							[MasterCompanyId] BIGINT NULL,
							[UpdatedBy] VARCHAR(500) NULL,
							[UnitCost] DECIMAL(18,2),
							[IsSerialized] BIT,
							[IsAltPart] BIT,
							[IsActive] BIT,
							[IsDeleted] BIT,
							[CreatedDate] DATETIME2 NULL,
						)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineMaterialsAlt ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[AltPartMasterPartId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsAltPart],[IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId],tblMS.[AltPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
							[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
							SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsAltPart],1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineMaterialsAlt tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup) 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt 
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt 
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMMaterialsAlt FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMMaterialsAlt) > 0)
						BEGIN
							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMMaterialsAlt;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE WorkOrderMaterials 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM dbo.WorkOrderMaterials WOM JOIN #tmpAutoReserveWOMMaterialsAlt tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE dbo.WorkOrderMaterialStockLine AS TARGET
								USING #tmpAutoReserveWOMMaterialsAlt AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsAltPart = SOURCE.IsAltPart,
										TARGET.AltPartMasterPartId = SOURCE.AltPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,IsAltPart,AltPartMasterPartId,ReferenceNumber) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsAltPart, SOURCE.AltPartMasterPartId,@MaterialRefNo + ' - '+@WONumber);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE dbo.WorkOrderMaterialStockLine 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0),ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
							FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpAutoReserveWOMMaterialsAlt tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE dbo.WorkOrderMaterials 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
								FROM dbo.WorkOrderMaterials WOM 
								JOIN dbo.WorkOrderMaterialStockLine WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterials.Quantity,0)	
							
							--RE-CALCULATE WOM QTY RES & QTY ISSUE					
							UPDATE dbo.WorkOrderMaterials 
							SET QuantityIssued = GropWOM.QtyIssued, QuantityReserved = GropWOM.QtyReserved
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, ISNULL(SUM(WOMS.QtyReserved), 0) QtyReserved, ISNULL(SUM(WOMS.QtyIssued), 0) QtyIssued, WOM.WorkOrderMaterialsId   
								FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
								JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								JOIN #tmpAutoReserveWOMMaterialsAlt tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId 
									AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND 
							(ISNULL(GropWOM.QtyReserved,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityReserved,0)	OR ISNULL(GropWOM.QtyIssued,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityIssued,0))

							SET @countStockline = 1;
							DECLARE @TotalCountsBothAlt INT;
							SELECT @TotalCountsBothAlt = MAX(ID) FROM #tmpAutoReserveWOMMaterialsAlt;

							--FOR FOR UPDATED STOCKLINE QTY
							WHILE @countStockline <= @TotalCountsBothAlt
							BEGIN
								DECLARE @RowNum2 INT = 0;
								SET @tmpStockLineId = 0;

								SELECT @tmpStockLineId = StockLineId, @RowNum2 = Row_Num  FROM #tmpAutoReserveWOMMaterialsAlt WHERE ID = @countStockline

								--FOR UPDATED STOCKLINE QTY
								UPDATE dbo.Stockline
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
									QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
									WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
								FROM dbo.Stockline SL JOIN #tmpAutoReserveWOMMaterialsAlt tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
								WHERE Sl.StockLineId = @tmpStockLineId AND tmpRSL.Row_Num = @RowNum2

								SET @countStockline = @countStockline + 1;
							END;
							

							--FOR UPDATE TOTAL WORK ORDER COST
							WHILE @Materialscount<= @AutoTotalCounts
							BEGIN
								SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
								FROM #tmpAutoReserveWOMMaterialsAlt tmpWOM 
								WHERE tmpWOM.ID = @Materialscount

								EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
								SET @Materialscount = @Materialscount + 1;
							END;

							--FOR STOCK LINE HISTORY
							WHILE @Autoslcount<= @AutoTotalCounts
							BEGIN
								SELECT	@StocklineId = tmpWOM.StockLineId,
										@MasterCompanyId = tmpWOM.MasterCompanyId,
										@ReferenceId = tmpWOM.WorkOrderId,
										@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
										@ReservedQty = tmpWOM.QuantityActReserved,
										@UpdateBy = tmpWOM.UpdatedBy
								FROM #tmpAutoReserveWOMMaterialsAlt tmpWOM 
								WHERE tmpWOM.ID = @Autoslcount

								SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

								SET @ActionId = 2; -- Reserve
								EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

								SET @Autoslcount = @Autoslcount + 1;
							END;
						END				
					END

					--#STEP : 3 RESERVE KIT EQUIVALENT PARTS 
					IF(ISNULL(@IncludeEquiv, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#EquPartList') IS NOT NULL
						BEGIN
							DROP TABLE #EquPartList 
						END
			
						CREATE TABLE #EquPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						INSERT INTO #EquPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 2 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId != @ARConditionId

						SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsKitId,
							WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,	
							Equ.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS EquPartMasterPartId,
							WOM.ConditionCodeId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsEquPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineKITEqu
						FROM #EquPartList Equ
							JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId AND WOM.ConditionCodeId != @ARConditionId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineKITEqu') IS NOT NULL
						BEGIN
							DROP TABLE #tmpAutoReserveWOMaterialsStocklineKITEqu
						END
			
						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineKITEqu
						(
							ID BIGINT NOT NULL IDENTITY, 
							[WorkOrderId] BIGINT NULL,
							[WorkFlowWorkOrderId] BIGINT NULL,
							[WorkOrderMaterialsId] BIGINT NULL,
							[StockLineId] BIGINT NULL,
							[ItemMasterId] BIGINT NULL,
							[EquPartMasterPartId] BIGINT NULL,										 
							[ConditionId] BIGINT NULL,
							[ProvisionId] BIGINT NULL,
							[TaskId] BIGINT NULL,
							[ReservedById] BIGINT NULL,
							[Condition] VARCHAR(500) NULL,
							[PartNumber] VARCHAR(500) NULL,
							[PartDescription] VARCHAR(max) NULL,
							[Quantity] INT NULL,
							[QuantityAvailable] INT NULL,
							[QuantityOnHand] INT NULL,
							[ActQuantity] INT NULL,
							[QtyToBeReserved] INT NULL,
							[QuantityActReserved] INT NULL,
							[ControlNo] VARCHAR(500) NULL,
							[ControlId] VARCHAR(500) NULL,
							[StockLineNumber] VARCHAR(500) NULL,
							[SerialNumber] VARCHAR(500) NULL,
							[ReservedBy] VARCHAR(500) NULL,						 
							[IsStocklineAdded] BIT NULL,
							[MasterCompanyId] BIGINT NULL,
							[UpdatedBy] VARCHAR(500) NULL,
							[UnitCost] DECIMAL(18,2),
							[IsSerialized] BIT,
							[IsEquPart] BIT,
							[IsActive] BIT,
							[IsDeleted] BIT,
							[CreatedDate] DATETIME2 NULL,
						)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineKITEqu ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[EquPartMasterPartId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsEquPart],[IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId], tblMS.[EquPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
							[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
							SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsEquPart], 1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineKITEqu tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup)
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineKITEqu;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineKITEqu WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineKITEqu
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineKITEqu
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineKITEqu tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineKITEqu
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineKITEqu tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineKITEqu WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMKITEqu FROM #tmpAutoReserveWOMaterialsStocklineKITEqu

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMKITEqu) > 0)
						BEGIN
							SET @Autocount = 0;
							SET @Materialscount = 0;
							SET @Autoslcount = 0;
							SET @AutoTotalCounts = 0;

							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMKITEqu;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE WorkOrderMaterialsKIT 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM dbo.WorkOrderMaterialsKIT WOM JOIN #tmpAutoReserveWOMKITEqu tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKITId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE dbo.WorkOrderMaterialStockLineKIT AS TARGET
								USING #tmpAutoReserveWOMKITEqu AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsKITId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsEquPart = SOURCE.IsEquPart,
										TARGET.EquPartMasterPartId = SOURCE.EquPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsKITId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, IsEquPart , EquPartMasterPartId,ReferenceNumber) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsEquPart , SOURCE.EquPartMasterPartId,@MaterialRefNo + ' - '+@WONumber);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE dbo.WorkOrderMaterialStockLineKIT 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0),ReferenceNumber = @MaterialRefNo + ' - '+@WONumber  
							FROM dbo.WorkOrderMaterialStockLineKIT WOMS JOIN #tmpAutoReserveWOMKITEqu tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE dbo.WorkOrderMaterialsKIT 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKITId AS WorkOrderMaterialsId
								FROM dbo.WorkOrderMaterialsKIT WOM 
								JOIN dbo.WorkOrderMaterialStockLineKIT WOMS ON WOMS.WorkOrderMaterialsKITId = WOM.WorkOrderMaterialsKITId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsKITId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterialsKIT.WorkOrderMaterialsKITId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterialsKIT.Quantity,0)			

							SET @countStockline = 1;
							DECLARE @TotalCountsBothKITEqu INT;
							SELECT @TotalCountsBothKITEqu = MAX(ID) FROM #tmpAutoReserveWOMKITEqu;

							--FOR FOR UPDATED STOCKLINE QTY
							WHILE @countStockline <= @TotalCountsBothKITEqu
							BEGIN
								DECLARE @RowNum3 INT = 0;
								SET @tmpStockLineId = 0;

								SELECT @tmpStockLineId = StockLineId, @RowNum3 = Row_Num  FROM #tmpAutoReserveWOMKITEqu WHERE ID = @countStockline

								--FOR UPDATED STOCKLINE QTY
								UPDATE dbo.Stockline
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
									QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
									WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
								FROM dbo.Stockline SL JOIN #tmpAutoReserveWOMKITEqu tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
								WHERE Sl.StockLineId = @tmpStockLineId AND tmpRSL.Row_Num = @RowNum3

								SET @countStockline = @countStockline + 1;
							END;

							--FOR UPDATE TOTAL WORK ORDER COST
							WHILE @Materialscount<= @AutoTotalCounts
							BEGIN
								SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
								FROM #tmpAutoReserveWOMKITEqu tmpWOM 
								WHERE tmpWOM.ID = @Materialscount

								EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
								SET @Materialscount = @Materialscount + 1;
							END;

							--FOR STOCK LINE HISTORY
							WHILE @Autoslcount<= @AutoTotalCounts
							BEGIN
								SELECT	@StocklineId = tmpWOM.StockLineId,
										@MasterCompanyId = tmpWOM.MasterCompanyId,
										@ReferenceId = tmpWOM.WorkOrderId,
										@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
										@ReservedQty = tmpWOM.QuantityActReserved,
										@UpdateBy = tmpWOM.UpdatedBy
								FROM #tmpAutoReserveWOMKITEqu tmpWOM 
								WHERE tmpWOM.ID = @Autoslcount

								SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

								SET @ActionId = 2; -- Reserve
								EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

								SET @Autoslcount = @Autoslcount + 1;
							END;
						END
					END

					--#STEP : 3.1 RESERVE MATERIALS EQUIVALENT PARTS 
					IF(ISNULL(@IncludeEquiv, 0) = 1)
					BEGIN
						SELECT '3.1 RESERVE MATERIALS EQUIVALENT PARTS '
						IF OBJECT_ID(N'tempdb..#MaterialsEquPartList') IS NOT NULL
						BEGIN
							DROP TABLE #MaterialsEquPartList 
						END
			
						CREATE TABLE #MaterialsEquPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						INSERT INTO #MaterialsEquPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 2 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId != @ARConditionId

						SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							Equ.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS EquPartMasterPartId,
							WOM.ConditionCodeId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,		
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsEquPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineMaterialsEqu
						FROM #MaterialsEquPartList Equ
							JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId AND WOM.ConditionCodeId != @ARConditionId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							
						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineMaterialsEqu') IS NOT NULL
						BEGIN
							DROP TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu
						END
			
						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu
						(
							ID BIGINT NOT NULL IDENTITY, 
							[WorkOrderId] BIGINT NULL,
							[WorkFlowWorkOrderId] BIGINT NULL,
							[WorkOrderMaterialsId] BIGINT NULL,
							[StockLineId] BIGINT NULL,
							[ItemMasterId] BIGINT NULL,
							[EquPartMasterPartId] BIGINT NULL,
							[ConditionId] BIGINT NULL,
							[ProvisionId] BIGINT NULL,
							[TaskId] BIGINT NULL,
							[ReservedById] BIGINT NULL,
							[Condition] VARCHAR(500) NULL,
							[PartNumber] VARCHAR(500) NULL,
							[PartDescription] VARCHAR(max) NULL,
							[Quantity] INT NULL,
							[QuantityAvailable] INT NULL,
							[QuantityOnHand] INT NULL,
							[ActQuantity] INT NULL,
							[QtyToBeReserved] INT NULL,
							[QuantityActReserved] INT NULL,
							[ControlNo] VARCHAR(500) NULL,
							[ControlId] VARCHAR(500) NULL,
							[StockLineNumber] VARCHAR(500) NULL,
							[SerialNumber] VARCHAR(500) NULL,
							[ReservedBy] VARCHAR(500) NULL,						 
							[IsStocklineAdded] BIT NULL,
							[MasterCompanyId] BIGINT NULL,
							[UpdatedBy] VARCHAR(500) NULL,
							[UnitCost] DECIMAL(18,2),
							[IsSerialized] BIT,
							[IsEquPart] BIT,
							[IsActive] BIT,
							[IsDeleted] BIT,
							[CreatedDate] DATETIME2 NULL,
						)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineMaterialsEqu ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[EquPartMasterPartId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsEquPart], [IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId],tblMS.[EquPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
							[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
							SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsEquPart],1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineMaterialsEqu tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup)  
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu 
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu 
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMMaterialsEqu FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMMaterialsEqu) > 0)
						BEGIN
							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMMaterialsEqu;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE WorkOrderMaterials 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM dbo.WorkOrderMaterials WOM JOIN #tmpAutoReserveWOMMaterialsEqu tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE dbo.WorkOrderMaterialStockLine AS TARGET
								USING #tmpAutoReserveWOMMaterialsEqu AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsEquPart = SOURCE.IsEquPart,
										TARGET.EquPartMasterPartId = SOURCE.EquPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, IsEquPart, EquPartMasterPartId,ReferenceNumber) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsEquPart, SOURCE.EquPartMasterPartId,@MaterialRefNo + ' - '+@WONumber);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE dbo.WorkOrderMaterialStockLine 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) ,ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
							FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpAutoReserveWOMMaterialsEqu tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE dbo.WorkOrderMaterials 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
								FROM dbo.WorkOrderMaterials WOM 
								JOIN dbo.WorkOrderMaterialStockLine WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterials.Quantity,0)		
							
							--RE-CALCULATE WOM QTY RES & QTY ISSUE					
							UPDATE dbo.WorkOrderMaterials 
							SET QuantityIssued = GropWOM.QtyIssued, QuantityReserved = GropWOM.QtyReserved
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, ISNULL(SUM(WOMS.QtyReserved), 0) QtyReserved, ISNULL(SUM(WOMS.QtyIssued), 0) QtyIssued, WOM.WorkOrderMaterialsId   
								FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
								JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								JOIN #tmpAutoReserveWOMMaterialsEqu tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId 
									AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND 
							(ISNULL(GropWOM.QtyReserved,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityReserved,0)	OR ISNULL(GropWOM.QtyIssued,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityIssued,0))

							SET @countStockline = 1;
							DECLARE @TotalCountsBothEqu INT;
							SELECT @TotalCountsBothEqu = MAX(ID) FROM #tmpAutoReserveWOMMaterialsEqu;

							--FOR FOR UPDATED STOCKLINE QTY
							WHILE @countStockline <= @TotalCountsBothEqu
							BEGIN
								DECLARE @RowNum4 INT = 0;
								SET @tmpStockLineId = 0;

								SELECT @tmpStockLineId = StockLineId, @RowNum4 = Row_Num FROM #tmpAutoReserveWOMMaterialsEqu WHERE ID = @countStockline

								--FOR UPDATED STOCKLINE QTY
								UPDATE dbo.Stockline
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
									QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
									WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
								FROM dbo.Stockline SL JOIN #tmpAutoReserveWOMMaterialsEqu tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
								WHERE Sl.StockLineId = @tmpStockLineId AND tmpRSL.Row_Num = @RowNum4

								SET @countStockline = @countStockline + 1;
							END;

							--FOR UPDATE TOTAL WORK ORDER COST
							WHILE @Materialscount<= @AutoTotalCounts
							BEGIN
								SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
								FROM #tmpAutoReserveWOMMaterialsEqu tmpWOM 
								WHERE tmpWOM.ID = @Materialscount

								EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
								SET @Materialscount = @Materialscount + 1;
							END;

							--FOR STOCK LINE HISTORY
							WHILE @Autoslcount<= @AutoTotalCounts
							BEGIN
								SELECT	@StocklineId = tmpWOM.StockLineId,
										@MasterCompanyId = tmpWOM.MasterCompanyId,
										@ReferenceId = tmpWOM.WorkOrderId,
										@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
										@ReservedQty = tmpWOM.QuantityActReserved,
										@UpdateBy = tmpWOM.UpdatedBy
								FROM #tmpAutoReserveWOMMaterialsEqu tmpWOM 
								WHERE tmpWOM.ID = @Autoslcount

								SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

								SET @ActionId = 2; -- Reserve
								EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

								SET @Autoslcount = @Autoslcount + 1;
							END;
						END				
					END
					
					--#STEP : 4 RESERVE NEW STOCKLINE
					SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionCodeId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded	
						INTO #tmpAutoReserveIssueWOMaterialsStockline
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId) AND WOM.ConditionCodeId != @ARConditionId
					
					IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStockline
					END

					CREATE TABLE #tmpAutoReserveWOMaterialsStockline
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[WorkFlowWorkOrderId] BIGINT NULL,
						[WorkOrderMaterialsId] BIGINT NULL,
						[StockLineId] BIGINT NULL,
						[ItemMasterId] BIGINT NULL,
						[ConditionId] BIGINT NULL,
						[ProvisionId] BIGINT NULL,
						[TaskId] BIGINT NULL,
						[ReservedById] BIGINT NULL,
						[Condition] VARCHAR(500) NULL,
						[PartNumber] VARCHAR(500) NULL,
						[PartDescription] VARCHAR(max) NULL,
						[Quantity] INT NULL,
						[QuantityAvailable] INT NULL,
						[QuantityOnHand] INT NULL,
						[ActQuantity] INT NULL,
						[QtyToBeReserved] INT NULL,
						[QuantityActReserved] INT NULL,
						[ControlNo] VARCHAR(500) NULL,
						[ControlId] VARCHAR(500) NULL,
						[StockLineNumber] VARCHAR(500) NULL,
						[SerialNumber] VARCHAR(500) NULL,
						[ReservedBy] VARCHAR(500) NULL,						 
						[IsStocklineAdded] BIT NULL,
						[MasterCompanyId] BIGINT NULL,
						[UpdatedBy] VARCHAR(500) NULL,
						[UnitCost] DECIMAL(18,2),
						[IsSerialized] BIT,
						[IsActive] BIT,
						[IsDeleted] BIT,
						[CreatedDate] DATETIME2 NULL,
						[ConditionGroupCode] VARCHAR(50) NULL,
					)

					INSERT INTO #tmpAutoReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsActive], [IsDeleted], [CreatedDate], ConditionGroupCode)
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
						[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
						SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, 1, 0, SL.CreatedDate, ConditionGroupCode
					FROM #tmpAutoReserveIssueWOMaterialsStockline tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tmpC.ConditionGroup = tblMS.ConditionGroupCode)
					WHERE SL.QuantityAvailable > 0 
					AND SL.IsParent = 1 
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					ORDER BY SL.CreatedDate

					SET @ARcount = 1;
					SET @ARTotalCounts = 0;
					SET @tmpActQuantity = 0;
					SET @QtytToRes = 0;
					SET @NewWorkOrderMaterialsId = 0;
					SET @NewStockline = 0;

					SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStockline ;
					
					WHILE @ARcount<= @ARTotalCounts
					BEGIN						 
						SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStockline WHERE ID = @ARcount

						SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
						FROM #tmpAutoReserveWOMaterialsStockline 
						WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
						GROUP BY WorkOrderMaterialsId

						IF(@QtytToRes > 0)
						BEGIN
							UPDATE #tmpAutoReserveWOMaterialsStockline 
							SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
								IsActive = 1, IsStocklineAdded = 1
							FROM #tmpAutoReserveWOMaterialsStockline tmpWOM
							WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

							UPDATE #tmpAutoReserveWOMaterialsStockline
							SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
							FROM #tmpAutoReserveWOMaterialsStockline tmpWOM
							WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
						END

						--Added for WO History 
							SELECT @historyModuleId = moduleId FROM dbo.Module WHERE ModuleName = 'WorkOrder';
							SELECT @historySubModuleId = moduleId FROM dbo.Module WHERE ModuleName = 'WorkOrderMPN';
							SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'ReserveParts';
							SELECT @HistoryWorkOrderMaterialsId = WorkOrderMaterialsId,
								   @historyWorkOrderId = WorkOrderId, @UpdateBy = UpdatedBy,
								   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
								   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved,
								   @historypartNumber = PartNumber
							FROM #tmpAutoReserveWOMaterialsStockline WHERE ID = @ARcount;

							SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @HistoryWorkOrderMaterialsId;
							SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

							SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
							SELECT @ConditionCode = Code FROM dbo.Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
							SELECT @HistoryStockLineNum = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

							SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historypartNumber,''));
						
							SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
							SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpAutoReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
							SELECT @HistoryWorkOrderMaterialsId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK);
							
							IF(@QtytToRes > 0)
							BEGIN
								EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','Reserved Parts',@TemplateBody,'ReserveParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
							END
						
						SET @ARcount = @ARcount + 1;
					END;

					DELETE FROM #tmpAutoReserveWOMaterialsStockline WHERE IsStocklineAdded != 1

					SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOM FROM #tmpAutoReserveWOMaterialsStockline

					IF((SELECT COUNT(1) FROM #tmpAutoReserveWOM) > 0)
					BEGIN
						SET @Autoslcount = 1;
						SET @Autocount = 1;
						SET @Materialscount = 1;

						SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOM;
		
						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @Autocount<= @AutoTotalCounts
						BEGIN
							UPDATE WorkOrderMaterials 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM dbo.WorkOrderMaterials WOM JOIN #tmpAutoReserveWOM tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.Row_Num = @Autocount
							SET @Autocount = @Autocount + 1;
						END;

						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@AutoTotalCounts > 0 )
						BEGIN
							MERGE dbo.WorkOrderMaterialStockLine AS TARGET
							USING #tmpAutoReserveWOM AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
									TARGET.UnitCost = SOURCE.UnitCost,
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,ReferenceNumber) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0,@MaterialRefNo + ' - '+@WONumber);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE dbo.WorkOrderMaterialStockLine 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) ,ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
						FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpAutoReserveWOM tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						UPDATE dbo.WorkOrderMaterialStockLine 
						SET ConditionId = SL.ConditionId
						FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpAutoReserveWOM tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						INNER JOIN  dbo.Stockline SL on SL.StockLineId =  WOMS.StockLineId
						
						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE dbo.WorkOrderMaterials 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterials WOM 
							JOIN dbo.WorkOrderMaterialStockLine WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterials.Quantity,0)			

						--RE-CALCULATE WOM QTY RES & QTY ISSUE					
						UPDATE dbo.WorkOrderMaterials 
						SET QuantityIssued = GropWOM.QtyIssued, QuantityReserved = GropWOM.QtyReserved
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, ISNULL(SUM(WOMS.QtyReserved), 0) QtyReserved, ISNULL(SUM(WOMS.QtyIssued), 0) QtyIssued, WOM.WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							JOIN #tmpAutoReserveWOM tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId 
								AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND 
						(ISNULL(GropWOM.QtyReserved,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityReserved,0)	OR ISNULL(GropWOM.QtyIssued,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityIssued,0))
						
						SET @countStockline = 1;
						DECLARE @TotalCountsBothWOM INT;
						SELECT @TotalCountsBothWOM = MAX(ID) FROM #tmpAutoReserveWOM;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countStockline <= @TotalCountsBothWOM
						BEGIN
							DECLARE @RowNum5 INT = 0;
							SET @tmpStockLineId = 0 ;

							SELECT @tmpStockLineId = StockLineId, @RowNum5 = Row_Num  FROM #tmpAutoReserveWOM WHERE ID = @countStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
								WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							FROM dbo.Stockline SL JOIN #tmpAutoReserveWOM tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE Sl.StockLineId = @tmpStockLineId AND tmpRSL.Row_Num = @RowNum5

							SET @countStockline = @countStockline + 1;
						END;

						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @Materialscount<= @AutoTotalCounts
						BEGIN
							SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
							FROM #tmpAutoReserveWOM tmpWOM 
							WHERE tmpWOM.ID = @Materialscount

							EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
							SET @Materialscount = @Materialscount + 1;
						END;

						--FOR STOCK LINE HISTORY
						WHILE @Autoslcount<= @AutoTotalCounts
						BEGIN
							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.WorkOrderId,
									@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
									@ReservedQty = tmpWOM.QuantityActReserved,
									@UpdateBy = tmpWOM.UpdatedBy
							FROM #tmpAutoReserveWOM tmpWOM 
							WHERE tmpWOM.ID = @Autoslcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

							SET @ActionId = 2; -- Reserve
							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

							SET @Autoslcount = @Autoslcount + 1;
						END;

					END
					
					--#STEP : 5 RESERVE NEW STOCKLINE KIT MATERIALS
					SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionCodeId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,		
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded	
						INTO #tmpAutoReserveIssueWOMaterialsStocklineKIT
						FROM dbo.WorkOrderMaterialsKIT WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId) AND WOM.ConditionCodeId != @ARConditionId

					IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineKIT') IS NOT NULL
					BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStocklineKIT
					END
			
					CREATE TABLE #tmpAutoReserveWOMaterialsStocklineKIT
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[WorkFlowWorkOrderId] BIGINT NULL,
						[WorkOrderMaterialsId] BIGINT NULL,
						[StockLineId] BIGINT NULL,
						[ItemMasterId] BIGINT NULL,
						[ConditionId] BIGINT NULL,
						[ProvisionId] BIGINT NULL,
						[TaskId] BIGINT NULL,
						[ReservedById] BIGINT NULL,
						[Condition] VARCHAR(500) NULL,
						[PartNumber] VARCHAR(500) NULL,
						[PartDescription] VARCHAR(max) NULL,
						[Quantity] INT NULL,
						[QuantityAvailable] INT NULL,
						[QuantityOnHand] INT NULL,
						[ActQuantity] INT NULL,
						[QtyToBeReserved] INT NULL,
						[QuantityActReserved] INT NULL,
						[ControlNo] VARCHAR(500) NULL,
						[ControlId] VARCHAR(500) NULL,
						[StockLineNumber] VARCHAR(500) NULL,
						[SerialNumber] VARCHAR(500) NULL,
						[ReservedBy] VARCHAR(500) NULL,						 
						[IsStocklineAdded] BIT NULL,
						[MasterCompanyId] BIGINT NULL,
						[UpdatedBy] VARCHAR(500) NULL,
						[UnitCost] DECIMAL(18,2),
						[IsSerialized] BIT,
						[IsActive] BIT,
						[IsDeleted] BIT,
						[CreatedDate] DATETIME2 NULL,
						[ConditionGroupCode] VARCHAR(50) NULL,
					)

					INSERT INTO #tmpAutoReserveWOMaterialsStocklineKIT ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsActive], [IsDeleted], [CreatedDate], ConditionGroupCode)
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId,  
						[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
						SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, 1, 0, SL.CreatedDate, ConditionGroupCode
					FROM #tmpAutoReserveIssueWOMaterialsStocklineKIT tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tmpC.ConditionGroup = tblMS.ConditionGroupCode)
					WHERE SL.QuantityAvailable > 0 
					AND SL.IsParent = 1 
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					ORDER BY SL.CreatedDate

					SET @ARcount = 1;
					SET @ARTotalCounts = 0;
					SET @tmpActQuantity = 0;
					SET @QtytToRes = 0;
					SET @NewWorkOrderMaterialsId = 0;
					SET @NewStockline = 0;

					SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineKIT;

					WHILE @ARcount<= @ARTotalCounts
					BEGIN						 
						SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineKIT WHERE ID = @ARcount

						SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
						FROM #tmpAutoReserveWOMaterialsStocklineKIT
						WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
						GROUP BY WorkOrderMaterialsId

						IF(@QtytToRes > 0)
						BEGIN
							UPDATE #tmpAutoReserveWOMaterialsStocklineKIT
							SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
								IsActive = 1, IsStocklineAdded = 1
							FROM #tmpAutoReserveWOMaterialsStocklineKIT tmpWOM
							WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

							UPDATE #tmpAutoReserveWOMaterialsStocklineKIT
							SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
							FROM #tmpAutoReserveWOMaterialsStocklineKIT tmpWOM
							WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
						END

						--Added for WO History 
						SELECT @historyModuleId = moduleId FROM dbo.Module WHERE ModuleName = 'WorkOrder';
						SELECT @historySubModuleId = moduleId FROM dbo.Module WHERE ModuleName = 'WorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'ReserveParts';
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderMaterialsId,
							   @historyWorkOrderId = WorkOrderId, @UpdateBy = UpdatedBy,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved,
							   @historypartNumber = PartNumber
						FROM #tmpAutoReserveWOMaterialsStocklineKIT WHERE ID = @ARcount;
						
						SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @HistoryWorkOrderMaterialsId;
						SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
						
						SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
						
						SELECT @ConditionCode = Code FROM dbo.Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						
						SELECT @HistoryStockLineNum = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;
						
						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historypartNumber,''));
						
						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpAutoReserveWOMaterialsStocklineKIT tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK);
						
						IF(@QtytToRes > 0)
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','Reserved Kit Parts',@TemplateBody,'ReserveParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END
					
						SET @ARcount = @ARcount + 1;
					END;

					DELETE FROM #tmpAutoReserveWOMaterialsStocklineKIT WHERE IsStocklineAdded != 1

					SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMKIT FROM #tmpAutoReserveWOMaterialsStocklineKIT

					IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMKIT) > 0)
					BEGIN
						SET @Autocount = 0;
						SET @Materialscount = 0;
						SET @Autoslcount = 0;
						SET @AutoTotalCounts = 0;

						SET @Autoslcount = 1;
						SET @Autocount = 1;
						SET @Materialscount = 1;

						SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMKIT;
		
						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @Autocount<= @AutoTotalCounts
						BEGIN
						
							UPDATE WorkOrderMaterialsKIT 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM dbo.WorkOrderMaterialsKIT WOM JOIN #tmpAutoReserveWOMKIT tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKITId AND tmpWOM.Row_Num = @Autocount
							SET @Autocount = @Autocount + 1;
						END;

						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@AutoTotalCounts > 0 )
						BEGIN
							MERGE dbo.WorkOrderMaterialStockLineKIT AS TARGET
							USING #tmpAutoReserveWOMKIT AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsKITId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
									TARGET.UnitCost = SOURCE.UnitCost,
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo + ' - '+@WONumber 
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsKITId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,ReferenceNumber) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0,@MaterialRefNo + ' - '+@WONumber);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE dbo.WorkOrderMaterialStockLineKIT 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0),ReferenceNumber = @MaterialRefNo + ' - '+@WONumber  
						FROM dbo.WorkOrderMaterialStockLineKIT WOMS JOIN #tmpAutoReserveWOMKIT tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						UPDATE dbo.WorkOrderMaterialStockLineKIT 
						SET ConditionId = SL.ConditionId
						FROM dbo.WorkOrderMaterialStockLineKIT WOMS JOIN #tmpAutoReserveWOMKIT tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
						INNER JOIN  dbo.Stockline SL on SL.StockLineId =  WOMS.StockLineId

						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE dbo.WorkOrderMaterialsKIT 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKITId AS WorkOrderMaterialsId
							FROM dbo.WorkOrderMaterialsKIT WOM 
							JOIN dbo.WorkOrderMaterialStockLineKIT WOMS ON WOMS.WorkOrderMaterialsKITId = WOM.WorkOrderMaterialsKITId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsKITId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterialsKIT.WorkOrderMaterialsKITId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterialsKIT.Quantity,0)			

						SET @countStockline = 1;
						DECLARE @TotalCountsBothWOMKIT INT;
						SELECT @TotalCountsBothWOMKIT = MAX(ID) FROM #tmpAutoReserveWOMKIT;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countStockline <= @TotalCountsBothWOMKIT
						BEGIN
							DECLARE @RowNum6 INT = 0;
							SET @tmpStockLineId = 0;

							SELECT @tmpStockLineId = StockLineId, @RowNum6 = Row_Num FROM #tmpAutoReserveWOMKIT WHERE ID = @countStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
								WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
							FROM dbo.Stockline SL JOIN #tmpAutoReserveWOMKIT tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE Sl.StockLineId = @tmpStockLineId AND tmpRSL.Row_Num = @RowNum6

							SET @countStockline = @countStockline + 1;
						END;

						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @Materialscount<= @AutoTotalCounts
						BEGIN
							SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
							FROM #tmpAutoReserveWOMKIT tmpWOM 
							WHERE tmpWOM.ID = @Materialscount

							EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
					
							SET @Materialscount = @Materialscount + 1;
						END;

						--FOR STOCK LINE HISTORY
						WHILE @Autoslcount<= @AutoTotalCounts
						BEGIN
							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.WorkOrderId,
									@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
									@ReservedQty = tmpWOM.QuantityActReserved,
									@UpdateBy = tmpWOM.UpdatedBy
							FROM #tmpAutoReserveWOMKIT tmpWOM 
							WHERE tmpWOM.ID = @Autoslcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

							SET @ActionId = 2; -- Reserve
							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

							SET @Autoslcount = @Autoslcount + 1;
						END;
					END
				END
				--ROLLBACK TRAN;
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_ReserveIssueWorkOrderMaterialsStockline' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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