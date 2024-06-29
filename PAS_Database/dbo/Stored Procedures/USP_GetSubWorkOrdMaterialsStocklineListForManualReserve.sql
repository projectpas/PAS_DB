/*************************************************************           
 ** File:   [USP_GetSubWorkOrdMaterialsStocklineListForManualReserve]           
 ** Author:   Devendra Shekh
 ** Description: This SP is Used to get Stockline list to reserve Stockline for sub wo - manual reserve
 ** Purpose:         
 ** Date:   12/14/2023       
          
 ** PARAMETERS:           
 @SubWOPartNoId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author					Change Description            
 ** --   --------		-------				--------------------------------          
    1    12/14/2021		 HEMANT SALIYA				Created
    2    12/19/2023		 Devendra Shekh				changes for customerid select
	3    12/19/2023		HEMANT SALIYA				Updated for Customer stock check box not validating
     
 EXECUTE USP_GetSubWorkOrdMaterialsStocklineListForManualReserve 3118,0,0,3375,0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrdMaterialsStocklineListForManualReserve]
(    
	@SubWOPartNoId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL,
	@SubWorkOrderMaterialsId BIGINT = NULL,
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
				DECLARE @CustomerID BIGINT; -- not used
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @ARConditionId BIGINT;
				DECLARE @ConditionId BIGINT;
				DECLARE @ConditionGroup VARCHAR(50);

				SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
				--SELECT @MasterCompanyId = WO.MasterCompanyId FROM dbo.SubWorkOrder WO WITH(NOLOCK) JOIN dbo.SubWorkOrderPartNumber WOWF WITH(NOLOCK) on WO.SubWorkOrderId = WOWF.SubWorkOrderId WHERE WOWF.SubWOPartNoId = @SubWOPartNoId;
				
				SELECT DISTINCT TOP 1 @CustomerID = WO.CustomerId, @MasterCompanyId = SWO.MasterCompanyId 
				FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on WO.WorkOrderId = SWO.WorkOrderId 
					JOIN dbo.SubWorkOrderPartNumber SWOPN WITH(NOLOCK) on SWOPN.SubWorkOrderId = SWO.SubWorkOrderId WHERE SWOPN.SubWOPartNoId = @subWOPartNoId;

				SELECT @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END

				IF(@SubWorkOrderMaterialsId = 0)
				BEGIN
					SET @SubWorkOrderMaterialsId = NULL;
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
					[SubWorkOrderMaterialsId] [BIGINT] NULL,
					[ConditionGroup] VARCHAR(50) NULL,
				)

				IF(ISNULL(@KitId, 0) = 0)
				BEGIN
				
					INSERT INTO #AltPartList
					([ItemMasterId], [AltItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
					WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #EquPartList
					([ItemMasterId], [EquItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
					WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

					IF(ISNULL(@SubWorkOrderMaterialsId, 0) > 0)
					BEGIN
						SELECT @ConditionGroup = C.GroupCode FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId
					
						INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT ConditionId, WOM.SubWorkOrderMaterialsId, C.GroupCode 
						FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
						WHERE WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT C.ConditionId, CG.SubWorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
						WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

					END
					BEGIN
						INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT ConditionId, WOM.SubWorkOrderMaterialsId, C.GroupCode 
						FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT C.ConditionId, CG.SubWorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
						WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId
					END


					SELECT  WOM.WorkOrderId,
							WOM.SubWorkOrderId,
							WOM.SubWOPartNoId,
							WOM.SubWorkOrderMaterialsId,		
							WOMS.SWOMStockLineId,
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
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
							0 AS IsAltPart,
							0 AS IsEquPart
							,TS.[Description] AS 'TaskName' 
						FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId --(SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId)
							LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  							
							--AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1))
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)

					UNION ALL

					SELECT  WOM.WorkOrderId,
							WOM.SubWorkOrderId,
							WOM.SubWOPartNoId,
							WOM.SubWorkOrderMaterialsId,		
							WOMS.SWOMStockLineId,
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
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
							1 AS IsAltPart,
							0 AS IsEquPart
							,TS.[Description] AS 'TaskName' 
						FROM #AltPartList Alt
							JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
							LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
							LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							--AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)

					UNION ALL

					SELECT  WOM.WorkOrderId,
							WOM.SubWorkOrderId,
							WOM.SubWOPartNoId,
							WOM.SubWorkOrderMaterialsId,		
							WOMS.SWOMStockLineId,	
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
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
							0 AS IsAltPart,
							1 AS IsEquPart
							,TS.[Description] AS 'TaskName' 
						FROM #EquPartList Equ
							JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
							LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)
				END
				ELSE
				BEGIN

					INSERT INTO #AltPartList
					([ItemMasterId], [AltItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
					WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #EquPartList
					([ItemMasterId], [EquItemMasterId])
					SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
					FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
						LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
						LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
					WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
					SELECT DISTINCT ConditionId, WOM.SubWorkOrderMaterialsKitId, C.GroupCode FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) 
					JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
					JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOMKM.KitId = @KitId AND WOM.SubWOPartNoId = @SubWOPartNoId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

					INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
					SELECT DISTINCT C.ConditionId, CG.SubWorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
					WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

					SELECT  DISTINCT WOM.WorkOrderId,
							WOM.SubWorkOrderId,
							WOM.SubWOPartNoId,
							WOM.SubWorkOrderMaterialsKitId,
							WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
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
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
							0 AS IsAltPart,
							0 AS IsEquPart
							,TS.[Description] AS 'TaskName' 
						FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@KitId IS NULL OR WOMKM.KitId = @KitId)

					UNION ALL

					SELECT  DISTINCT WOM.WorkOrderId,
							WOM.SubWorkOrderId,
							WOM.SubWOPartNoId,
							WOM.SubWorkOrderMaterialsKitId,
							WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
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
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
							1 AS IsAltPart,
							0 AS IsEquPart
							,TS.[Description] AS 'TaskName' 
						FROM #AltPartList Alt
							JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
							JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (@KitId IS NULL OR WOMKM.KitId = @KitId)

					UNION ALL

					SELECT  DISTINCT WOM.WorkOrderId,
							WOM.SubWorkOrderId,
							WOM.SubWOPartNoId,
							WOM.SubWorkOrderMaterialsKitId,
							WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
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
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
							0 AS IsAltPart,
							1 AS IsEquPart
							,TS.[Description] AS 'TaskName' 
						FROM #EquPartList Equ
							JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
							JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
							JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
							LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
							LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrdMaterialsStocklineListForManualReserve' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNoId, '') + ''
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