﻿/*************************************************************           
 ** File:   [USP_GetWorkOrdMaterialsStocklineListForReserve]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to get Stockline list to reserve Stockline    
 ** Purpose:         
 ** Date:   12/24/2021        
          
 ** PARAMETERS:           
 @WorkFlowWorkOrderId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/24/2021   Hemant Saliya		Created
	2    03/27/2023   Hemant Saliya		Updated for Add Kit Changes
	3    04/19/2023   Amit Ghediya		Removed AR condition record when populate reserve list
	4    04/19/2023   Hemant Saliya		Allow Customer stockltok use in other customer
	5    10/04/2023   Hemant Saliya		Condition Group Changes
	6    29/06/2024   Devendra Shekh	added TaskName To Select
     
 EXECUTE USP_GetWorkOrdMaterialsStocklineListForReserve 3118,0,0,3375,0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWorkOrdMaterialsStocklineListForReserve]
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
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @ProvisionId BIGINT;
				DECLARE @SubWOProvisionId BIGINT;
				DECLARE @Provision VARCHAR(50);
				DECLARE @ProvisionCode VARCHAR(50);
				DECLARE @CustomerID BIGINT;
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @ARConditionId BIGINT;
				DECLARE @ConditionId BIGINT;
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

				IF(ISNULL(@KitId, 0) = 0)
				BEGIN
				
					INSERT INTO #AltPartList
					([ItemMasterId], [AltItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #EquPartList
					([ItemMasterId], [EquItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

					IF(ISNULL(@WorkOrderMaterialsId, 0) > 0)
					BEGIN
						SELECT @ConditionGroup = C.GroupCode FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId
					
						INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsId, C.GroupCode 
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
						WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
						WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

					END
					BEGIN
						INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsId, C.GroupCode 
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
						WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId
					END


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
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId --(SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId)
							LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  							
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)

					UNION ALL

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
						FROM #AltPartList Alt
							JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
							LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
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

					UNION ALL

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
						FROM #EquPartList Equ
							JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
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
				END
				ELSE
				BEGIN

					INSERT INTO #AltPartList
					([ItemMasterId], [AltItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
					WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #EquPartList
					([ItemMasterId], [EquItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
					WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
					SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsKitId, C.GroupCode FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) 
					JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
					JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOMKM.KitId = @KitId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
					SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
					WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

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
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@KitId IS NULL OR WOMKM.KitId = @KitId)

					UNION ALL

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

					UNION ALL

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
				END

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrdMaterialsStocklineListForReserve' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
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