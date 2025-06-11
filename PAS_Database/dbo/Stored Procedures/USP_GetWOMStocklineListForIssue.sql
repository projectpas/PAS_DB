/*************************************************************           
 ** File:   [USP_GetWOMStocklineListForIssue]           
 ** Author:   Devendra Shekh
 ** Description: This SP is Used to get Stockline list to Issue Stockline    
 ** Purpose:         
 ** Date:   11-June-2025       

 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------					--------------------------------          
    1    11-June-2025		 Devendra Shekh				Created

 exec dbo.USP_GetWOMStocklineListForIssue @PageNumber=1,@PageSize=10,@SortColumn=default,@SortOrder=1,@WorkFlowWorkOrderId=8694,@ItemMasterId=0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWOMStocklineListForIssue]
(
	@PageNumber INT,  
	@PageSize INT,  
	@SortColumn VARCHAR(50)=null,  
	@SortOrder INT,
	@WorkFlowWorkOrderId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL
)    
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN  
			DECLARE @ProvisionId BIGINT;
			DECLARE @WorkOrderId BIGINT;
			DECLARE @WorkOrderTypeId INT;
			DECLARE @MasterCompanyId INT;
			DECLARE @IsEnforcePickTicket BIT;
			DECLARE @CustomerID BIGINT;
			DECLARE @RecordFrom INT; 
			DECLARE @Count INT;  
			
			IF @SortColumn IS NULL
			BEGIN  
				SET @SortColumn = ('taskName')
			END

			SET @RecordFrom = (@PageNumber-1)*@PageSize; 

			IF OBJECT_ID(N'tempdb..#tmpWorkorderPickTicket') IS NOT NULL
			BEGIN
				DROP TABLE #tmpWorkorderPickTicket
			END
			
			CREATE TABLE #tmpWorkorderPickTicket
			(
				ID BIGINT NOT NULL IDENTITY, 
				[WorkOrderId] BIGINT NULL,
				[WorkOrderMaterialsId] BIGINT NULL,
				[StocklineId] BIGINT NULL,
				[QtyToShip] INT NULL,
				[IsKit] BIT NULL
			)

			IF OBJECT_ID(N'tempdb..#tmpWorkorderPickTicketMaterials') IS NOT NULL
			BEGIN
				DROP TABLE #tmpWorkorderPickTicketMaterials
			END
			
			CREATE TABLE #tmpWorkorderPickTicketMaterials
			(
				ID BIGINT NOT NULL IDENTITY, 
				[WorkOrderId] BIGINT NULL,
				[WorkOrderMaterialsId] BIGINT NULL,
				[QtyToShip] INT NULL,
				[IsKit] BIT NULL
			)

			IF OBJECT_ID(N'tempdb..#TMPWOIssueMaterialParentListData') IS NOT NULL
			BEGIN
				DROP TABLE #TMPWOIssueMaterialParentListData
			END

			CREATE TABLE #TMPWOIssueMaterialParentListData
			(
		 		[ParentID] BIGINT NOT NULL IDENTITY, 						 
		 		[WorkOrderMaterialsId] [bigint] NULL,
		 		[WorkFlowWorkOrderId] [bigint] NULL,
		 		[IsKit] [bit] NULL,
			)

			IF OBJECT_ID(N'tempdb..#TMPWOMaterialResultListData') IS NOT NULL
			BEGIN
				DROP TABLE #TMPWOMaterialResultListData
			END

			IF OBJECT_ID(N'tempdb..#listResult') IS NOT NULL
			BEGIN
				DROP TABLE #listResult
			END

			CREATE TABLE #listResult 
			(
				[WorkOrderId] [bigint] NULL,
				[WorkFlowWorkOrderId] [bigint] NULL,
				[WorkOrderMaterialsId] [bigint] NULL,
				[ItemMasterId] [bigint] NULL,
				[ConditionId] [bigint] NULL,
				[MasterCompanyId] [int] NULL,
				[Quantity] [int] NULL,
				[QuantityReserved] [int] NULL,
				[QuantityIssued] [int] NULL,
				[QuantityOnOrder] [int] NULL,
				[QtyToBeIssued] [int] NULL,
				[UnitCost] [decimal](20, 2) NULL,
				[ExtendedCost] [decimal](20, 2) NULL,
				[TaskId] [bigint] NULL,
				[ProvisionId] [int] NULL,
				[PartNumber] [varchar](50) NULL,
				[PartDescription] [nvarchar](max) NULL,
				[MainPartNumber] [varchar](50) NULL,
				[MainPartDescription] [nvarchar](max) NULL,
				[MainManufacturer] [varchar](250) NULL,
				[MainCondition] [varchar](250) NULL,
				[StockLineId] [bigint] NULL,
				[Condition] [varchar](100) NULL,
				[StockLineNumber] [varchar](50) NULL,
				[ControlNumber] [varchar](50) NULL,
				[IdNumber] [varchar](100) NULL,
				[Manufacturer] [varchar](50) NULL,
				[SerialNumber] [varchar](30) NULL,
				[QuantityAvailable] [int] NULL,
				[QuantityOnHand] [int] NULL,
				[StocklineQuantityOnOrder] [int] NULL,
				[StocklineQuantityTurnIn] [int] NULL,
				[UnitOfMeasure] [varchar](100) NULL,
				[Provision] [varchar](100) NULL,
				[ProvisionStatusCode] [varchar](20) NULL,
				[StockType] [varchar](20) NULL,
				[MSQuantityRequsted] [int] NULL,
				[MSQuantityReserved] [int] NULL,
				[MSQuantityIssued] [int] NULL,
				[QuantityPicked] [int] NULL,
				[MaterialsQuantityPicked] [int] NULL,
				[MSQtyToBeIssued] [int] NULL,
				[StocklineUnitCost] [decimal](20, 2) NULL,
				[MSQunatityRemaining] [int] NULL,
				[StocklineProvision] [varchar](100) NULL,
				[StocklineProvisionCode] [varchar](20) NULL,
				[IsStocklineAdded] [bit] NULL,
				[IsKitType] [bit] NULL,
				[KitId] [bigint] NULL,
				[IsAltPart] [bit] NULL,
				[IsEquPart] [bit] NULL,
				[TaskName] [varchar](200) NULL,
				[ControlNo] [varchar](50) NULL,
				[ControlId] [varchar](100) NULL,
			)

			SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
			SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderId = WorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND IsActive = 1 AND IsDeleted = 0;
			SELECT @WorkOrderTypeId = WorkOrderTypeId, @CustomerID = CustomerId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND IsActive = 1 AND IsDeleted = 0;
			SELECT @IsEnforcePickTicket = ISNULL(EnforcePickTicket,0) FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			IF(@ItemMasterId = 0)
			BEGIN
				SET @ItemMasterId = NULL;
			END
			
			IF(@IsEnforcePickTicket = 1)
			BEGIN
				INSERT INTO #tmpWorkorderPickTicketMaterials (WorkOrderId, WorkOrderMaterialsId, QtyToShip, IsKit)
				SELECT WorkOrderId, WorkOrderMaterialsId, SUM(QtyToShip), ISNULL(IsKitType, 0)
				FROM dbo.WorkorderPickTicket WITH(NOLOCK) 
				WHERE WorkorderId = @WorkOrderId AND IsConfirmed = 1 AND QtyToShip > 0 
				GROUP BY WorkOrderId, WorkOrderMaterialsId, IsKitType

				INSERT INTO #tmpWorkorderPickTicket (WorkOrderId, WorkOrderMaterialsId, StocklineId, QtyToShip, IsKit)
				SELECT WorkOrderId, WorkOrderMaterialsId, StocklineId, SUM(QtyToShip), ISNULL(IsKitType, 0)
				FROM dbo.WorkorderPickTicket WITH(NOLOCK) 
				WHERE WorkorderId = @WorkOrderId AND IsConfirmed = 1 AND QtyToShip > 0 
				GROUP BY WorkOrderId, WorkOrderMaterialsId, StocklineId, IsKitType

				-- Work Order Material Data
				INSERT INTO #TMPWOIssueMaterialParentListData
				SELECT DISTINCT WOM.WorkOrderMaterialsId, WOM.WorkFlowWorkOrderId, 0 AS IsKit
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND PTKT.StockLineId = WOMS.StockLineId AND PTKT.IsKit = 0
				JOIN #tmpWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MPTKT.IsKit = 0						
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 						
				--AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
				
				-- Work Order Material Kit Data
				INSERT INTO #TMPWOIssueMaterialParentListData
				SELECT DISTINCT WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId, WOM.WorkFlowWorkOrderId, 1 AS IsKit
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND PTKT.StockLineId = WOMS.StockLineId AND PTKT.IsKit = 1
				JOIN #tmpWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND MPTKT.IsKit = 1
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 						
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
			END
			ELSE
			BEGIN
				-- Work Order Material Data
				INSERT INTO #TMPWOIssueMaterialParentListData
				SELECT DISTINCT WOM.WorkOrderMaterialsId, WOM.WorkFlowWorkOrderId, 0 AS IsKit
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 						
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)

				-- Work Order Material Kit Data
				INSERT INTO #TMPWOIssueMaterialParentListData
				SELECT DISTINCT WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId, WOM.WorkFlowWorkOrderId, 1 AS IsKit
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId						
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 						
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
			END
			
			SELECT * INTO #TMPWOMaterialResultListData FROM #TMPWOIssueMaterialParentListData tmp 
			ORDER BY tmp.[WorkFlowWorkOrderId] ASC
			OFFSET @RecordFrom ROWS   
			FETCH NEXT @PageSize ROWS ONLY

			SELECT @Count = COUNT(ParentID) FROM #TMPWOIssueMaterialParentListData;

			IF(@IsEnforcePickTicket = 1)
			BEGIN
				
				INSERT INTO #listResult ([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder],
						[QtyToBeIssued], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition],
						[StockLineNumber], [ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision],
						[ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining],
						[StocklineProvision], [StocklineProvisionCode], [IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsId,						
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					WOM.QuantityReserved AS QtyToBeIssued,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartNumber 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartNumber
							ELSE IM.PartNumber
					END MainPartNumber,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartDescription 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartDescription
							ELSE IM.PartDescription
					END MainPartDescription,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.ManufacturerName 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.ManufacturerName
							ELSE IM.ManufacturerName
					END MainManufacturer,
					C.[Description] AS MainCondition,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					WOMS.QtyReserved AS MSQuantityReserved,
					WOMS.QtyIssued AS MSQuantityIssued,
					PTKT.QtyToShip AS QuantityPicked,
					MPTKT.QtyToShip AS MaterialsQuantityPicked,
					WOMS.QtyReserved AS MSQtyToBeIssued,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS StocklineUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS StocklineProvision,
					SP.StatusCode AS StocklineProvisionCode,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsKitType,
					0 AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND PTKT.StockLineId = WOMS.StockLineId AND PTKT.IsKit = 0
				JOIN #tmpWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MPTKT.IsKit = 0						
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 						
				AND WOM.WorkOrderMaterialsId IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOMaterialResultListData WHERE [IsKit] = 0)
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)

				INSERT INTO #listResult ([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder],
						[QtyToBeIssued], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition],
						[StockLineNumber], [ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision],
						[ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining],
						[StocklineProvision], [StocklineProvisionCode], [IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,	
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					WOM.QuantityReserved AS QtyToBeIssued,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartNumber 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartNumber
							ELSE IM.PartNumber
					END MainPartNumber,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartDescription 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartDescription
							ELSE IM.PartDescription
					END MainPartDescription,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.ManufacturerName 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.ManufacturerName
							ELSE IM.ManufacturerName
					END MainManufacturer,
					C.[Description] AS MainCondition,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					WOMS.QtyReserved AS MSQuantityReserved,
					WOMS.QtyIssued AS MSQuantityIssued,
					PTKT.QtyToShip AS QuantityPicked,
					MPTKT.QtyToShip AS MaterialsQuantityPicked,
					WOMS.QtyReserved AS MSQtyToBeIssued,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS StocklineUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS StocklineProvision,
					SP.StatusCode AS StocklineProvisionCode,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					1 AS IsKitType,
					(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
					dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId
					WHERE WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMK.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId) AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND PTKT.StockLineId = WOMS.StockLineId AND PTKT.IsKit = 1
				JOIN #tmpWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND MPTKT.IsKit = 1
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 						
				AND WOM.WorkOrderMaterialsKitId IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOMaterialResultListData WHERE [IsKit] = 1)
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
			END
			ELSE
			BEGIN
				
				INSERT INTO #listResult ([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder],
						[QtyToBeIssued], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition],
						[StockLineNumber], [ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision],
						[ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining],
						[StocklineProvision], [StocklineProvisionCode], [IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsId,						
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					WOM.QuantityReserved AS QtyToBeIssued,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartNumber 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartNumber
							ELSE IM.PartNumber
					END MainPartNumber,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartDescription 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartDescription
							ELSE IM.PartDescription
					END MainPartDescription,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.ManufacturerName 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.ManufacturerName
							ELSE IM.ManufacturerName
					END MainManufacturer,
					C.[Description] AS MainCondition,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					WOMS.QtyReserved AS MSQuantityReserved,
					WOMS.QtyIssued AS MSQuantityIssued,
					WOMS.QtyReserved AS QuantityPicked,
					WOM.QuantityReserved AS MaterialsQuantityPicked,
					WOMS.QtyReserved AS MSQtyToBeIssued,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS StocklineUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS StocklineProvision,
					SP.StatusCode AS StocklineProvisionCode,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsKitType,
					0 AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 		
				AND WOM.WorkOrderMaterialsId IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOMaterialResultListData WHERE [IsKit] = 0)
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)

				INSERT INTO #listResult ([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder],
						[QtyToBeIssued], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition],
						[StockLineNumber], [ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision],
						[ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining],
						[StocklineProvision], [StocklineProvisionCode], [IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					WOM.QuantityReserved AS QtyToBeIssued,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartNumber 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartNumber
							ELSE IM.PartNumber
					END MainPartNumber,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.PartDescription 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.PartDescription
							ELSE IM.PartDescription
					END MainPartDescription,
					CASE WHEN WOMS.IsAltPart = 1 THEN IM_AltMain.ManufacturerName 
							WHEN WOMS.IsEquPart = 1 THEN IM_EquMain.ManufacturerName
							ELSE IM.ManufacturerName
					END MainManufacturer,
					C.[Description] AS MainCondition,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					WOMS.QtyReserved AS MSQuantityReserved,
					WOMS.QtyIssued AS MSQuantityIssued,
					WOMS.QtyReserved AS QuantityPicked,
					WOM.QuantityReserved AS MaterialsQuantityPicked,
					WOMS.QtyReserved AS MSQtyToBeIssued,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS StocklineUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS StocklineProvision,
					SP.StatusCode AS StocklineProvisionCode,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					1 AS IsKitType,
					(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
					dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId
					WHERE WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMK.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId) AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId						
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
				AND WOM.IsDeleted = 0 				
				AND WOM.WorkOrderMaterialsKitId IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOMaterialResultListData WHERE [IsKit] = 1)
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
			END
		END

		SELECT *, @Count AS NumberOfItems FROM #listResult
		ORDER BY
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Quantity') THEN Quantity END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Quantity') THEN Quantity END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityReserved') THEN QuantityReserved END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityReserved') THEN QuantityReserved END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityIssued') THEN QuantityIssued END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityIssued') THEN QuantityIssued END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityOnOrder') THEN QuantityOnOrder END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityOnOrder') THEN QuantityOnOrder END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QtyToBeIssued') THEN QtyToBeIssued END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QtyToBeIssued') THEN QtyToBeIssued END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UnitCost') THEN UnitCost END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UnitCost') THEN UnitCost END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ExtendedCost') THEN ExtendedCost END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ExtendedCost') THEN ExtendedCost END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber') THEN PartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartNumber') THEN PartNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartDescription') THEN PartDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartDescription') THEN PartDescription END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainPartNumber') THEN MainPartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainPartNumber') THEN MainPartNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainPartDescription') THEN MainPartDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainPartDescription') THEN MainPartDescription END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainManufacturer') THEN MainManufacturer END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainManufacturer') THEN MainManufacturer END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainCondition') THEN MainCondition END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainCondition') THEN MainCondition END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Condition') THEN Condition END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Condition') THEN Condition END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StockLineNumber') THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StockLineNumber') THEN StockLineNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ControlNumber') THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ControlNumber') THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IdNumber') THEN IdNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IdNumber') THEN IdNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Manufacturer') THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Manufacturer') THEN Manufacturer END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SerialNumber') THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SerialNumber') THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityAvailable') THEN QuantityAvailable END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityAvailable') THEN QuantityAvailable END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityOnHand') THEN QuantityOnHand END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityOnHand') THEN QuantityOnHand END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineQuantityOnOrder') THEN StocklineQuantityOnOrder END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineQuantityOnOrder') THEN StocklineQuantityOnOrder END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineQuantityTurnIn') THEN StocklineQuantityTurnIn END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineQuantityTurnIn') THEN StocklineQuantityTurnIn END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UnitOfMeasure') THEN UnitOfMeasure END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UnitOfMeasure') THEN UnitOfMeasure END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Provision') THEN Provision END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Provision') THEN Provision END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ProvisionStatusCode') THEN ProvisionStatusCode END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ProvisionStatusCode') THEN ProvisionStatusCode END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StockType') THEN StockType END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StockType') THEN StockType END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQuantityRequsted') THEN MSQuantityRequsted END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQuantityRequsted') THEN MSQuantityRequsted END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQuantityReserved') THEN MSQuantityReserved END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQuantityReserved') THEN MSQuantityReserved END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQuantityIssued') THEN MSQuantityIssued END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQuantityIssued') THEN MSQuantityIssued END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityPicked') THEN QuantityPicked END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityPicked') THEN QuantityPicked END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MaterialsQuantityPicked') THEN MaterialsQuantityPicked END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MaterialsQuantityPicked') THEN MaterialsQuantityPicked END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQtyToBeIssued') THEN MSQtyToBeIssued END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQtyToBeIssued') THEN MSQtyToBeIssued END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineUnitCost') THEN StocklineUnitCost END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineUnitCost') THEN StocklineUnitCost END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQunatityRemaining') THEN MSQunatityRemaining END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQunatityRemaining') THEN MSQunatityRemaining END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineProvision') THEN StocklineProvision END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineProvision') THEN StocklineProvision END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineProvisionCode') THEN StocklineProvisionCode END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineProvisionCode') THEN StocklineProvisionCode END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsStocklineAdded') THEN IsStocklineAdded END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsStocklineAdded') THEN IsStocklineAdded END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsKitType') THEN IsKitType END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsKitType') THEN IsKitType END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsAltPart') THEN IsAltPart END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsAltPart') THEN IsAltPart END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsEquPart') THEN IsEquPart END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsEquPart') THEN IsEquPart END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'TaskName') THEN TaskName END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'TaskName') THEN TaskName END DESC

	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetWOMStocklineListForIssue' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			= @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END