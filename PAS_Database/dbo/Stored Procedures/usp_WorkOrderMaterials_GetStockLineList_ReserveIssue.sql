/*************************************************************           
 ** File:   [usp_WorkOrderMaterials_GetStockLineList_ReserveIssue]           
 ** Author:   Devendra Shekh
 ** Description: This SP is Used to get Stockline list to reserve/issue material / kit Stockline    
 ** Date:   24-Sept-2025   
 ** PARAMETERS:  @WorkFlowWorkOrderId BIGINT, @ItemMasterId BIGINT, @WorkOrderMaterialsId BIGINT, @KitId BIGINT, @IncludeCustomerStock BIT   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author						Change Description            
 ** --   --------			-------					--------------------------------          
    1    24-Sept-2025		Devendra Shekh					Created
	2    16-March-2026		AMIT GHEDIYA					Allow AR condition to reserve (PN-15562)
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
exec usp_WorkOrderMaterials_GetStockLineList_ReserveIssue @WorkFlowWorkOrderId=9904,@ItemMasterId=0,@WorkOrderMaterialsId=0,@KitId=0,@IncludeCustomerStock=0
**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_WorkOrderMaterials_GetStockLineList_ReserveIssue]
(    
	@WorkFlowWorkOrderId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL,
	@WorkOrderMaterialsId BIGINT = NULL,
	@KitId BIGINT = NULL,
	@IncludeCustomerStock BIT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN  
			DECLARE @ProvisionId BIGINT;
			DECLARE @SubWOProvisionId BIGINT;
			DECLARE @Provision VARCHAR(50);
			DECLARE @ProvisionCode VARCHAR(50);
			DECLARE @CustomerID BIGINT;
			DECLARE @MasterCompanyId BIGINT;
			DECLARE @ARConditionId BIGINT;
			DECLARE @ConditionGroup VARCHAR(50);				

			SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
			SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
			SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
			SELECT @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId;

			IF(@ItemMasterId = 0)
			BEGIN
				SET @ItemMasterId = NULL;
			END

			IF(@WorkOrderMaterialsId = 0)
			BEGIN
				SET @WorkOrderMaterialsId = NULL;
			END

			IF(@KitId = 0)
			BEGIN
				SET @KitId = NULL;
			END

			IF OBJECT_ID(N'tempdb..#AltPartList') IS NOT NULL
			BEGIN
				DROP TABLE #AltPartList 
			END

			IF OBJECT_ID(N'tempdb..#EquPartList') IS NOT NULL
			BEGIN
				DROP TABLE #EquPartList 
			END

			IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
			BEGIN
				DROP TABLE #ConditionGroup 
			END
			
			CREATE TABLE #AltPartList 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[ItemMasterId] [BIGINT] NULL,
				[AltItemMasterId] [BIGINT] NULL
			)

			CREATE TABLE #EquPartList 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[ItemMasterId] [BIGINT] NULL,
				[EquItemMasterId] [BIGINT] NULL
			)

			CREATE TABLE #ConditionGroup 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[ConditionId] [BIGINT] NULL,
				[WorkOrderMaterialsId] [BIGINT] NULL,
				[ConditionGroup] VARCHAR(50) NULL,
			)

			-- Check Restrict PMA / DER : Start
			IF OBJECT_ID(N'tempdb..#AllowItemMasterIds') IS NOT NULL
			BEGIN
				DROP TABLE #AllowItemMasterIds
			END

			CREATE TABLE #AllowItemMasterIds(
				[RecordId] BIGINT IDENTITY(1,1),
				[ItemMasterId] BIGINT,      
			)

			IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialStockLineResult') IS NOT NULL
			BEGIN
				DROP TABLE #tmpWorkOrderMaterialStockLineResult
			END

			CREATE TABLE #tmpWorkOrderMaterialStockLineResult (
				[RecordId] BIGINT IDENTITY(1,1),
				[WorkOrderId] BIGINT NULL,      
				[WorkFlowWorkOrderId] BIGINT NULL,      
				[WorkOrderMaterialsId] BIGINT NULL,      
				[WOMStockLineId] BIGINT NULL,      
				[ItemMasterId] BIGINT NULL,      
				[AltPartMasterPartId] BIGINT NULL,      
				[EquPartMasterPartId] BIGINT NULL,      
				[ConditionId] BIGINT NULL,      
				[StocklineConditionId] BIGINT NULL,      
				[ConditionGroup] VARCHAR(50) NULL,      
				[MasterCompanyId] BIGINT NULL,      
				[Quantity] INT NULL,      
				[QuantityReserved] INT NULL,      
				[QuantityIssued] INT NULL,      
				[QuantityOnOrder] INT NULL,      
				[QtyToBeReserved] INT NULL,      
				[UnitCost] DECIMAL(18, 2) NULL,      
				[ExtendedCost] DECIMAL(18, 2) NULL,      
				[TaskId] BIGINT NULL,      
				[ProvisionId] BIGINT NULL,      
				[PartNumber] VARCHAR(50) NULL,      
				[PartDescription] NVARCHAR(MAX) NULL,      
				[MainPartNumber] VARCHAR(50) NULL,      
				[MainPartDescription] NVARCHAR(MAX) NULL,      
				[MainManufacturer] VARCHAR(250) NULL,      
				[MainCondition] VARCHAR(256) NULL,
				[StocklineId] BIGINT NULL, 
				[Condition] VARCHAR(100) NULL, 
				[StockLineNumber] VARCHAR(50) NULL, 
				[ControlNumber] VARCHAR(50) NULL, 
				[IdNumber] VARCHAR(100) NULL, 
				[Manufacturer] VARCHAR(50) NULL, 
				[SerialNumber] VARCHAR(30) NULL, 
				[QuantityAvailable] INT NULL, 
				[QuantityOnHand] INT NULL, 
				[CreatedDate] DATETIME2 NULL, 
				[StocklineQuantityOnOrder] INT NULL, 
				[StocklineQuantityTurnIn] INT NULL, 
				[UnitOfMeasure] VARCHAR(100) NULL, 
				[Provision] VARCHAR(100) NULL, 
				[ProvisionStatusCode] VARCHAR(20) NULL, 
				[StockType] VARCHAR(30) NULL, 
				[MSQuantityRequsted] INT NULL, 
				[MSQuantityReserved] INT NULL, 
				[MSQuantityIssued] INT NULL, 
				[SLUnitCost] DECIMAL(18, 2) NULL, 
				[MSQunatityRemaining] INT NULL, 
				[MatStlProvision] VARCHAR(100) NULL, 
				[MatStlProvisionCode] VARCHAR(20) NULL, 
				[IsStocklineAdded] BIT NULL,
				[IsAltPart] BIT NULL,
				[IsEquPart] BIT NULL,
				[TaskName] VARCHAR(200) NULL, 
				[KitId] BIGINT NULL,      
			)
					
			DECLARE	@RestrictDER BIT = 0, @RestrictPMA BIT = 0;
			DECLARE @StkItemTypeId INT;
			DECLARE @WOPartNOId BIGINT;
			DECLARE @RestrictPartModuleId INT = 1;

			SELECT @WOPartNOId = WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND MasterCompanyId = @MasterCompanyId;
			SELECT @StkItemTypeId = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE UPPER([Name]) = 'STOCK';
			SELECT @RestrictPMA = ISNULL([IsPMA], 0), @RestrictDER = ISNULL([IsDER], 0) FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WOPartNOId;
				
			--- FOR OEM
			INSERT INTO #AllowItemMasterIds([ItemMasterId])SELECT [ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.IsActive = 1 AND IM.IsDeleted = 0 AND IM.ItemTypeId = @StkItemTypeId
			AND IM.MasterCompanyId = @MasterCompanyId AND ISNULL(IM.IsOEM ,0) = 1 AND ISNULL(IsDER ,0) = 0 AND ISNULL(IM.IsNonStock,0) = 0 ;

			--FOR PMA
			IF(ISNULL(@RestrictPMA, 0) <> 1)
			BEGIN
				INSERT INTO #AllowItemMasterIds([ItemMasterId])SELECT [ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.IsActive = 1 AND IM.IsDeleted = 0 AND IM.ItemTypeId = @StkItemTypeId
				AND IM.MasterCompanyId = @MasterCompanyId AND ISNULL(IM.IsPma ,0) = 1 AND ISNULL(IsDER ,0) = 0 AND ISNULL(IM.IsNonStock,0) = 0 ;
			END

			--FOR DER
			IF(ISNULL(@RestrictDER, 0) <> 1)
			BEGIN
				INSERT INTO #AllowItemMasterIds([ItemMasterId])SELECT [ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.IsActive = 1 AND IM.IsDeleted = 0 AND IM.ItemTypeId = @StkItemTypeId
				AND IM.MasterCompanyId = @MasterCompanyId AND ISNULL(IM.IsDER ,0) = 1 AND ISNULL(IM.IsNonStock,0) = 0 ;
			END

			--Except Parts
			--INSERT INTO #AllowItemMasterIds([ItemMasterId])SELECT [ItemMasterId] FROM [dbo].[RestrictedParts] RS WITH(NOLOCK) WHERE RS.IsActive = 1 AND RS.IsDeleted = 0 AND RS.ModuleId = @RestrictPartModuleId AND RS.ReferenceId = @CustomerID;
			-- Check Restrict PMA / DER : End

			-- Saving Work Order Materials Part Details
			INSERT INTO #AltPartList
			([ItemMasterId], [AltItemMasterId])
			SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
			FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
				LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
				LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
			 AND ISNULL(IM_NhaTla.IsNonStock,0) = 0
				 WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId --AND WOM.ConditionCodeId <> @ARConditionId
			AND NhaTla.MappingItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			INSERT INTO #EquPartList
			([ItemMasterId], [EquItemMasterId])
			SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
			FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
				LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
				LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
			 AND ISNULL(IM_NhaTla.IsNonStock,0) = 0
				 WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId --AND WOM.ConditionCodeId <> @ARConditionId
			AND NhaTla.MappingItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			IF(ISNULL(@WorkOrderMaterialsId, 0) > 0)
			BEGIN
				SELECT @ConditionGroup = C.GroupCode FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId
					
				INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
				SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsId, C.GroupCode 
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
				WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId --AND WOM.ConditionCodeId <> @ARConditionId

				INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
				SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
				WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId
			END
			BEGIN
				INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
				SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsId, C.GroupCode 
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND C.MasterCompanyId = @MasterCompanyId --AND WOM.ConditionCodeId <> @ARConditionId

				INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
				SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
				WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId
			END

			INSERT INTO #tmpWorkOrderMaterialStockLineResult
			SELECT  WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsId,		
					WOMS.WOMStockLineId,
					WOM.ItemMasterId,
					0 AS AltPartMasterPartId,
					0 AS EquPartMasterPartId,
					WOM.ConditionCodeId AS ConditionId,
					SL.ConditionId AS StocklineConditionId,
					@ConditionGroup AS ConditionGroup,
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
					IM.PartNumber AS MainPartNumber,
					IM.PartDescription AS MainPartDescription, 
					IM.ManufacturerName AS MainManufacturer,
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
					SL.CreatedDate,
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
					CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
					CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsAltPart,
					0 AS IsEquPart
					,TS.[Description] AS 'TaskName' 
					,0 AS [KitId]
				FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
					LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId --(SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId)
					LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
					LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId --AND WOM.ConditionCodeId <> @ARConditionId 
					AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  							
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
					AND WOM.ItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
					 INSERT INTO #tmpWorkOrderMaterialStockLineResult
			SELECT  WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsId,		
					WOMS.WOMStockLineId,
					Alt.AltItemMasterId ItemMasterId,
					Alt.ItemMasterId AS AltPartMasterPartId,
					Alt.ItemMasterId AS EquPartMasterPartId,
					WOM.ConditionCodeId AS ConditionId,
					SL.ConditionId AS StocklineConditionId,
					@ConditionGroup AS ConditionGroup,
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
					IM_AltMain.PartNumber AS MainPartNumber,
					IM_AltMain.PartDescription AS MainPartDescription,
					IM_AltMain.ManufacturerName AS MainManufacturer,
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
					SL.CreatedDate,
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
					CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
					CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					1 AS IsAltPart,
					0 AS IsEquPart
					,TS.[Description] AS 'TaskName' 
					,0 AS [KitId]
				FROM #AltPartList Alt
					JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
					LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
					LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
					 AND ISNULL(IM_AltMain.IsNonStock,0) = 0
					 LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
					LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
					AND WOM.ItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
					 INSERT INTO #tmpWorkOrderMaterialStockLineResult
			SELECT  WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsId,		
					WOMS.WOMStockLineId,	
					Equ.EquItemMasterId ItemMasterId,
					Equ.ItemMasterId AS AltPartMasterPartId,
					Equ.ItemMasterId AS EquPartMasterPartId,
					WOM.ConditionCodeId AS ConditionId,
					SL.ConditionId AS StocklineConditionId,
					@ConditionGroup AS ConditionGroup,
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
					IM_EquMain.PartNumber MainPartNumber,
					IM_EquMain.PartDescription MainPartDescription,
					IM_EquMain.ManufacturerName MainManufacturer,
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
					SL.CreatedDate,
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
					CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
					CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
					CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsAltPart,
					1 AS IsEquPart
					,TS.[Description] AS 'TaskName' 
					,0 AS [KitId]
				FROM #EquPartList Equ
					JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
					LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
					 AND ISNULL(IM_EquMain.IsNonStock,0) = 0
					 LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
					LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
					LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
					AND WOM.ItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

					-- Saving Work Order Materials Kit Part Details
			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0 TRUNCATE TABLE #AltPartList;
			TRUNCATE TABLE #EquPartList;
			TRUNCATE TABLE #ConditionGroup;

			INSERT INTO #AltPartList
			([ItemMasterId], [AltItemMasterId])
			SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
			FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
				LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
				LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
				 AND ISNULL(IM_NhaTla.IsNonStock,0) = 0
				 JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
			WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId --AND WOM.ConditionCodeId <> @ARConditionId
			AND NhaTla.MappingItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			INSERT INTO #EquPartList
			([ItemMasterId], [EquItemMasterId])
			SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
			FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
				LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
				LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
				 AND ISNULL(IM_NhaTla.IsNonStock,0) = 0
				 JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
			WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId --AND WOM.ConditionCodeId <> @ARConditionId
			AND NhaTla.MappingItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
			SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsKitId, C.GroupCode FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) 
			JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
			JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND C.MasterCompanyId = @MasterCompanyId --AND WOM.ConditionCodeId <> @ARConditionId

			INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
			SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
			WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

			INSERT INTO #tmpWorkOrderMaterialStockLineResult
			SELECT  DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsKitId,
					WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
					WOM.ItemMasterId,
					0 AS AltPartMasterPartId,
					0 AS EquPartMasterPartId,
					WOM.ConditionCodeId AS ConditionId,
					SL.ConditionId AS StocklineConditionId,
					@ConditionGroup AS ConditionGroup,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					IM.PartNumber AS MainPartNumber,
					IM.PartDescription AS MainPartDescription, 
					IM.ManufacturerName MainManufacturer,
					--SL.Condition  AS MainCondition,
					C.[Description]  AS MainCondition,
					SL.StocklineId,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SL.Manufacturer,
					SL.SerialNumber,
					SL.QuantityAvailable AS QuantityAvailable,
					SL.QuantityOnHand AS QuantityOnHand,
					SL.CreatedDate,
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
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
					CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsAltPart,
					0 AS IsEquPart
					,TS.[Description] AS 'TaskName' 
					,WOMKM.KitId AS [KitId]
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
					JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
					JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
					LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
					LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
					LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId --AND WOM.ConditionCodeId <> @ARConditionId 
					AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
					AND WOM.ItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
					 INSERT INTO #tmpWorkOrderMaterialStockLineResult
			SELECT  DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsKitId,
					WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
					Alt.AltItemMasterId ItemMasterId,
					Alt.ItemMasterId AS AltPartMasterPartId,
					Alt.ItemMasterId AS EquPartMasterPartId,
					WOM.ConditionCodeId AS ConditionId,
					SL.ConditionId AS StocklineConditionId,
					@ConditionGroup AS ConditionGroup,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					IM_AltMain.PartNumber AS MainPartNumber,
					IM_AltMain.PartDescription AS MainPartDescription,
					IM_AltMain.ManufacturerName AS MainManufacturer,
					C.[Description]  AS MainCondition,
					SL.StocklineId,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SL.Manufacturer,
					SL.SerialNumber,
					SL.QuantityAvailable AS QuantityAvailable,
					SL.QuantityOnHand AS QuantityOnHand,
					SL.CreatedDate,
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
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
					CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					1 AS IsAltPart,
					0 AS IsEquPart
					,TS.[Description] AS 'TaskName' 
					,WOMKM.KitId AS [KitId]
				FROM #AltPartList Alt
					JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
					JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
					JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
					JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
					LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
					LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
					LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
					AND WOM.ItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

			 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(IM_AltMain.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
					 INSERT INTO #tmpWorkOrderMaterialStockLineResult
			SELECT  DISTINCT WOM.WorkOrderId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderMaterialsKitId,
					WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
					Equ.EquItemMasterId ItemMasterId,
					Equ.ItemMasterId AS AltPartMasterPartId,
					Equ.ItemMasterId AS EquPartMasterPartId,
					WOM.ConditionCodeId AS ConditionId,
					SL.ConditionId AS StocklineConditionId,
					@ConditionGroup AS ConditionGroup,
					WOM.MasterCompanyId,
					WOM.Quantity,
					WOM.QuantityReserved,
					WOM.QuantityIssued,
					WOM.QtyOnOrder AS QuantityOnOrder,
					(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
					WOM.UnitCost,
					WOM.ExtendedCost,
					WOM.TaskId,
					WOM.ProvisionId,
					IM.PartNumber,
					IM.PartDescription, 
					IM_EquMain.PartNumber AS MainPartNumber,
					IM_EquMain.PartDescription AS MainPartDescription,
					IM_EquMain.ManufacturerName AS MainManufacturer,
					SL.Condition  AS MainCondition,
					SL.StocklineId,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SL.Manufacturer,
					SL.SerialNumber,
					SL.QuantityAvailable AS QuantityAvailable,
					SL.QuantityOnHand AS QuantityOnHand,
					SL.CreatedDate,
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
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
					MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
					CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
					CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
					CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
					0 AS IsAltPart,
					1 AS IsEquPart
					,TS.[Description] AS 'TaskName' 
					,WOMKM.KitId AS [KitId]
				FROM #EquPartList Equ
					JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
					JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
					JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
					JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
					LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
					LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
				WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
					AND WOM.ItemMasterId IN (SELECT [ItemMasterId] FROM #AllowItemMasterIds)

				 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(IM_EquMain.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
					 SELECT * FROM #tmpWorkOrderMaterialStockLineResult;

			END
		END TRY    
		BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_WorkOrderMaterials_GetStockLineList_ReserveIssue' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
		, @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
		EXEC spLogException 
				@DatabaseName			= @DatabaseName
				, @AdhocComments			= @AdhocComments
				, @ProcedureParameters		= @ProcedureParameters
				, @ApplicationName			= @ApplicationName
				, @ErrorLogID              = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END