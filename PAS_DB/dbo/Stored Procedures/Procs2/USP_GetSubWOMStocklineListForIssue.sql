/*************************************************************           
 ** File:   [USP_GetSubWOMStocklineListForIssue]           
 ** Author:   Devendra Shekh
 ** Description: This SP is Used to get Stockline list to Issue Stockline for Sub Work Order    
 ** Purpose:         
 ** Date:   11-June-2025          
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------					--------------------------------          
    1    03-June-2025		 Devendra Shekh				Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
 exec dbo.USP_GetSubWOMStocklineListForIssue @PageNumber=1,@PageSize=100,@SortColumn=default,@SortOrder=1,@SubWOPartNoId=413,@ItemMasterId=0
**************************************************************/ 
    
CREATE   PROCEDURE [dbo].[USP_GetSubWOMStocklineListForIssue]    
(    
	@PageNumber INT,  
	@PageSize INT,  
	@SortColumn VARCHAR(50)=null,  
	@SortOrder INT,
	@SubWOPartNoId BIGINT = NULL,
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

			IF OBJECT_ID(N'tempdb..#tmpSubWorkorderPickTicket') IS NOT NULL
			BEGIN
				DROP TABLE #tmpSubWorkorderPickTicket
			END
			
			CREATE TABLE #tmpSubWorkorderPickTicket
			(
					ID BIGINT NOT NULL IDENTITY, 
					[WorkOrderId] BIGINT NULL,
					[SubWorkOrderId] BIGINT NULL,
					[SubWOPartNoId] BIGINT NULL,
					[SubWorkOrderMaterialsId] BIGINT NULL,
					[StocklineId] BIGINT NULL,
					[QtyToShip] INT NULL,
					[IsKit] BIT NULL
			)

			IF OBJECT_ID(N'tempdb..#tmpSubWorkorderPickTicketMaterials') IS NOT NULL
			BEGIN
			DROP TABLE #tmpSubWorkorderPickTicketMaterials
			END
			
			CREATE TABLE #tmpSubWorkorderPickTicketMaterials
			(
					ID BIGINT NOT NULL IDENTITY, 
					[WorkOrderId] BIGINT NULL,
					[SubWorkOrderId] BIGINT NULL,
					[SubWOPartNoId] BIGINT NULL,
					[SubWorkOrderMaterialsId] BIGINT NULL,
					[QtyToShip] INT NULL,
					[IsKit] BIT NULL
			)

			IF OBJECT_ID(N'tempdb..#TMPSubWOIssueMaterialParentListData') IS NOT NULL
			BEGIN
				DROP TABLE #TMPSubWOIssueMaterialParentListData
			END

			CREATE TABLE #TMPSubWOIssueMaterialParentListData
			(
		 		[ParentID] BIGINT NOT NULL IDENTITY, 						 
		 		[SubWorkOrderMaterialsId] [bigint] NULL,
		 		[SubWOPartNoId] [bigint] NULL,
		 		[IsKit] [bit] NULL,
			)

			IF OBJECT_ID(N'tempdb..#TMPSubWOMaterialResultListData') IS NOT NULL
			BEGIN
				DROP TABLE #TMPSubWOMaterialResultListData
			END

			IF OBJECT_ID(N'tempdb..#listResult') IS NOT NULL
			BEGIN
				DROP TABLE #listResult
			END

			CREATE TABLE #listResult 
			(
				[WorkOrderId] [bigint] NULL,
				[SubWorkOrderId] [bigint] NULL,
				[SubWOPartNoId] [bigint] NULL,
				[SubWorkOrderMaterialsId] [bigint] NULL,
				[ItemMasterId] [bigint] NULL,
				[ConditionId] [bigint] NULL,
				[MasterCompanyId] [int] NULL,
				[Quantity] [int] NULL,
				[QuantityReserved] [int] NULL,
				[QuantityIssued] [int] NULL,
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
			SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderId = WorkOrderId FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId AND IsActive = 1 AND IsDeleted = 0;
			SELECT @CustomerID = CustomerId, @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId;
			SELECT @IsEnforcePickTicket = ISNULL(EnforcePickTicket,0) FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			IF(@ItemMasterId = 0)
			BEGIN
				SET @ItemMasterId = NULL;
			END

			IF(@IsEnforcePickTicket = 1)
			BEGIN
				INSERT INTO #tmpSubWorkorderPickTicketMaterials (WorkOrderId, SubWorkOrderId, SubWOPartNoId, SubWorkOrderMaterialsId, QtyToShip, IsKit)
				SELECT WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, SUM(QtyToShip), ISNULL(IsKitType, 0)
				FROM dbo.SubWorkorderPickTicket WITH(NOLOCK) 
				WHERE WorkorderId = @WorkOrderId AND SubWorkorderPartNoId = @SubWOPartNoId AND ISNULL(IsConfirmed, 0) = 1 AND ISNULL(QtyToShip, 0) > 0 
				GROUP BY WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, IsKitType

				INSERT INTO #tmpSubWorkorderPickTicket (WorkOrderId, SubWorkOrderId, SubWOPartNoId, SubWorkOrderMaterialsId, StocklineId, QtyToShip, IsKit)
				SELECT WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, StocklineId, SUM(QtyToShip), ISNULL(IsKitType, 0)
				FROM dbo.SubWorkorderPickTicket WITH(NOLOCK) 
				WHERE WorkorderId = @WorkOrderId AND ISNULL(IsConfirmed, 0) = 1 AND ISNULL(QtyToShip, 0) > 0 
				GROUP BY WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, StocklineId, IsKitType

				-- Sub Work Order Material Data
				INSERT INTO #TMPSubWOIssueMaterialParentListData
				SELECT DISTINCT WOM.SubWorkOrderMaterialsId, WOM.SubWOPartNoId, 0 AS IsKit
				FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpSubWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND PTKT.StockLineId = WOMS.StockLineId 
				JOIN #tmpSubWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId		
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
				
				-- Sub Work Order Material Kit Data
				 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 INSERT INTO #TMPSubWOIssueMaterialParentListData
				SELECT DISTINCT WOM.SubWorkOrderMaterialsKitId AS WorkOrderMaterialsId, WOM.SubWOPartNoId, 1 AS IsKit
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpSubWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND PTKT.StockLineId = WOMS.StockLineId 
				JOIN #tmpSubWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId		
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 END
			ELSE
			BEGIN
				-- Sub Work Order Material Data
				INSERT INTO #TMPSubWOIssueMaterialParentListData
				SELECT DISTINCT WOM.SubWorkOrderMaterialsId, WOM.SubWOPartNoId, 0 AS IsKit
				FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)

				-- Sub Work Order Material Kit Data
				 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 INSERT INTO #TMPSubWOIssueMaterialParentListData
				SELECT DISTINCT WOM.SubWorkOrderMaterialsKitId AS WorkOrderMaterialsId, WOM.SubWOPartNoId, 1 AS IsKit
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 END

			SELECT * INTO #TMPSubWOMaterialResultListData FROM #TMPSubWOIssueMaterialParentListData tmp 
			ORDER BY tmp.[SubWOPartNoId] ASC
			OFFSET @RecordFrom ROWS   
			FETCH NEXT @PageSize ROWS ONLY

			SELECT @Count = COUNT(ParentID) FROM #TMPSubWOIssueMaterialParentListData;

			IF(@IsEnforcePickTicket = 1)
			BEGIN

				INSERT INTO #listResult ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QtyToBeIssued], 
						[UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition], [StockLineNumber], 
						[ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType],
						[MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], [StocklineProvisionCode],
						[IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT  WOM.WorkOrderId,
					WOM.SubWorkOrderId,
					WOM.SubWOPartNoId,
					WOM.SubWorkOrderMaterialsId,						
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					ISNULL(WOM.QuantityReserved, 0) AS QuantityReserved,
					ISNULL(WOM.QuantityIssued, 0) AS QuantityIssued,
					ISNULL(WOM.QuantityReserved, 0) AS QtyToBeIssued,
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
					ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
					ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
					ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
					ISNULL(PTKT.QtyToShip, 0) AS QuantityPicked,
					ISNULL(MPTKT.QtyToShip, 0) AS MaterialsQuantityPicked,
					ISNULL(WOMS.QtyReserved, 0) AS MSQtyToBeIssued,
					CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS MatStlProvision,
					SP.StatusCode AS MatStlProvisionCode,
					CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsKitType,
					0 AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpSubWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND PTKT.StockLineId = WOMS.StockLineId 
				JOIN #tmpSubWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId		
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND WOM.SubWorkOrderMaterialsId IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOMaterialResultListData WHERE [IsKit] = 0)
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)

				 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 INSERT INTO #listResult ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QtyToBeIssued], 
						[UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition], [StockLineNumber], 
						[ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType],
						[MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], [StocklineProvisionCode],
						[IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT  WOM.WorkOrderId,
					WOM.SubWorkOrderId,
					WOM.SubWOPartNoId,
					WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,						
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					ISNULL(WOM.QuantityReserved, 0) AS QuantityReserved,
					ISNULL(WOM.QuantityIssued, 0) AS QuantityIssued,
					ISNULL(WOM.QuantityReserved, 0) AS QtyToBeIssued,
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
					ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
					ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLinekit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
					ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
					ISNULL(PTKT.QtyToShip, 0) AS QuantityPicked,
					ISNULL(MPTKT.QtyToShip, 0) AS MaterialsQuantityPicked,
					ISNULL(WOMS.QtyReserved, 0) AS MSQtyToBeIssued,
					CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS MatStlProvision,
					SP.StatusCode AS MatStlProvisionCode,
					CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					1 AS IsKitType,
					(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[SubWorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
					dbo.SubWorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.SubWorkOrderMaterialsKitMappingId = WOMKM.SubWorkOrderMaterialsKitMappingId
					WHERE WOMK.SubWOPartNoId = @SubWOPartNoId AND WOMK.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId) AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				JOIN #tmpSubWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND PTKT.StockLineId = WOMS.StockLineId 
				JOIN #tmpSubWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId		
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND WOM.SubWorkOrderMaterialsKitId IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOMaterialResultListData WHERE [IsKit] = 1)
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
					
			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 END
			ELSE
			BEGIN

				INSERT INTO #listResult ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QtyToBeIssued], 
						[UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition], [StockLineNumber], 
						[ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType],
						[MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], [StocklineProvisionCode],
						[IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT  WOM.WorkOrderId,
					WOM.SubWorkOrderId,
					WOM.SubWOPartNoId,
					WOM.SubWorkOrderMaterialsId,						
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					ISNULL(WOM.QuantityReserved, 0) AS QuantityReserved,
					ISNULL(WOM.QuantityIssued, 0) AS QuantityIssued,
					ISNULL(WOM.QuantityReserved, 0) AS QtyToBeIssued,
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
					ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
					ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
					ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
					ISNULL(WOMS.QtyReserved, 0) AS QuantityPicked,
					ISNULL(WOM.QuantityReserved, 0) AS MaterialsQuantityPicked,
					ISNULL(WOMS.QtyReserved, 0) AS MSQtyToBeIssued,
					CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS MatStlProvision,
					SP.StatusCode AS MatStlProvisionCode,
					CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsKitType,
					0 AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND WOM.SubWorkOrderMaterialsId IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOMaterialResultListData WHERE [IsKit] = 0)
				--AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)

				 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 INSERT INTO #listResult ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [ItemMasterId], [ConditionId], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QtyToBeIssued], 
						[UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber], [MainPartDescription], [MainManufacturer], [MainCondition], [StockLineId], [Condition], [StockLineNumber], 
						[ControlNumber], [IdNumber], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn], [UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType],
						[MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [QuantityPicked], [MaterialsQuantityPicked], [MSQtyToBeIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], [StocklineProvisionCode],
						[IsStocklineAdded], [IsKitType], [KitId], [IsAltPart], [IsEquPart], [TaskName], [ControlNo], [ControlId]
				)
				SELECT  WOM.WorkOrderId,
					WOM.SubWorkOrderId,
					WOM.SubWOPartNoId,
					WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,						
					WOM.ItemMasterId,
					WOM.ConditionCodeId AS ConditionId,
					WOM.MasterCompanyId,
					WOM.Quantity,
					ISNULL(WOM.QuantityReserved, 0) AS QuantityReserved,
					ISNULL(WOM.QuantityIssued, 0) AS QuantityIssued,
					ISNULL(WOM.QuantityReserved, 0) AS QtyToBeIssued,
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
					ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
					ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
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
					CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
					AS MSQuantityRequsted,
					ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
					ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
					ISNULL(WOMS.QtyReserved, 0) AS QuantityPicked,
					ISNULL(WOM.QuantityReserved, 0) AS MaterialsQuantityPicked,
					ISNULL(WOMS.QtyReserved, 0) AS MSQtyToBeIssued,
					CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					SP.Description AS MatStlProvision,
					SP.StatusCode AS MatStlProvisionCode,
					CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					1 AS IsKitType,
					(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[SubWorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
					dbo.SubWorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.SubWorkOrderMaterialsKitMappingId = WOMKM.SubWorkOrderMaterialsKitMappingId
					WHERE WOMK.SubWOPartNoId = @SubWOPartNoId AND WOMK.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId) AS KitId,
					ISNULL(WOMS.IsAltPart, 0) AS IsAltPart,
					ISNULL(WOMS.IsEquPart, 0) AS IsEquPart,
					TS.[Description] AS 'TaskName',
					SL.ControlNumber,
					SL.IdNumber
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
				JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
				JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
				JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
				LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
				LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
				 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
				 LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
				 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
				  LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
				LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
				LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
				LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND ISNULL(SL.IsParent, 0) = 1 AND WOM.IsDeleted = 0 
				AND WOM.SubWorkOrderMaterialsKitId IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOMaterialResultListData WHERE [IsKit] = 1)
				--AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)

			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				 END
		END

		SELECT *, @Count AS NumberOfItems FROM #listResult
		ORDER BY
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Quantity') THEN [Quantity] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Quantity') THEN [Quantity] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityReserved') THEN [QuantityReserved] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityReserved') THEN [QuantityReserved] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityIssued') THEN [QuantityIssued] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityIssued') THEN [QuantityIssued] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QtyToBeIssued') THEN [QtyToBeIssued] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QtyToBeIssued') THEN [QtyToBeIssued] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UnitCost') THEN [UnitCost] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UnitCost') THEN [UnitCost] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ExtendedCost') THEN [ExtendedCost] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ExtendedCost') THEN [ExtendedCost] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber') THEN [PartNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartNumber') THEN [PartNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartDescription') THEN [PartDescription] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartDescription') THEN [PartDescription] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainPartNumber') THEN [MainPartNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainPartNumber') THEN [MainPartNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainPartDescription') THEN [MainPartDescription] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainPartDescription') THEN [MainPartDescription] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainManufacturer') THEN [MainManufacturer] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainManufacturer') THEN [MainManufacturer] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MainCondition') THEN [MainCondition] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MainCondition') THEN [MainCondition] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Condition') THEN [Condition] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Condition') THEN [Condition] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StockLineNumber') THEN [StockLineNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StockLineNumber') THEN [StockLineNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ControlNumber') THEN [ControlNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ControlNumber') THEN [ControlNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IdNumber') THEN [IdNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IdNumber') THEN [IdNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Manufacturer') THEN [Manufacturer] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Manufacturer') THEN [Manufacturer] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SerialNumber') THEN [SerialNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SerialNumber') THEN [SerialNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityAvailable') THEN [QuantityAvailable] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityAvailable') THEN [QuantityAvailable] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityOnHand') THEN [QuantityOnHand] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityOnHand') THEN [QuantityOnHand] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineQuantityOnOrder') THEN [StocklineQuantityOnOrder] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineQuantityOnOrder') THEN [StocklineQuantityOnOrder] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineQuantityTurnIn') THEN [StocklineQuantityTurnIn] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineQuantityTurnIn') THEN [StocklineQuantityTurnIn] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UnitOfMeasure') THEN [UnitOfMeasure] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UnitOfMeasure') THEN [UnitOfMeasure] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Provision') THEN [Provision] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Provision') THEN [Provision] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ProvisionStatusCode') THEN [ProvisionStatusCode] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ProvisionStatusCode') THEN [ProvisionStatusCode] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StockType') THEN [StockType] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StockType') THEN [StockType] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQuantityRequsted') THEN [MSQuantityRequsted] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQuantityRequsted') THEN [MSQuantityRequsted] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQuantityReserved') THEN [MSQuantityReserved] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQuantityReserved') THEN [MSQuantityReserved] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQuantityIssued') THEN [MSQuantityIssued] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQuantityIssued') THEN [MSQuantityIssued] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QuantityPicked') THEN [QuantityPicked] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QuantityPicked') THEN [QuantityPicked] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MaterialsQuantityPicked') THEN [MaterialsQuantityPicked] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MaterialsQuantityPicked') THEN [MaterialsQuantityPicked] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQtyToBeIssued') THEN [MSQtyToBeIssued] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQtyToBeIssued') THEN [MSQtyToBeIssued] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineUnitCost') THEN [StocklineUnitCost] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineUnitCost') THEN [StocklineUnitCost] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MSQunatityRemaining') THEN [MSQunatityRemaining] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MSQunatityRemaining') THEN [MSQunatityRemaining] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineProvision') THEN [StocklineProvision] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineProvision') THEN [StocklineProvision] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StocklineProvisionCode') THEN [StocklineProvisionCode] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StocklineProvisionCode') THEN [StocklineProvisionCode] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsStocklineAdded') THEN [IsStocklineAdded] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsStocklineAdded') THEN [IsStocklineAdded] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsKitType') THEN [IsKitType] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsKitType') THEN [IsKitType] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsAltPart') THEN [IsAltPart] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsAltPart') THEN [IsAltPart] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IsEquPart') THEN [IsEquPart] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IsEquPart') THEN [IsEquPart] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'TaskName') THEN [TaskName] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'TaskName') THEN [TaskName] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ControlNo') THEN [ControlNo] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ControlNo') THEN [ControlNo] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ControlId') THEN [ControlId] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ControlId') THEN [ControlId] END DESC

	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWOMStocklineListForIssue' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNoId, '') + ''
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