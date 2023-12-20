/*************************************************************           
 ** File:   [USP_GetWorkOrdMaterialsStocklineListForAddInKitMaterial]           
 ** Author:   Vishal Suthar
 ** Description: This SP is Used to get Stockline list to add into KIT material    
 ** Purpose:         
 ** Date:   04/05/2023        
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    04/05/2023   Vishal Suthar		Created
     
 EXECUTE USP_GetWorkOrdMaterialsStocklineListForAddInKitMaterial 881,0,1293,0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWorkOrdMaterialsStocklineListForAddInKitMaterial]
(    
	@WorkFlowWorkOrderId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL,
	@WorkOrderMaterialsId BIGINT = NULL,
	@KitId BIGINT = NULL
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

				SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPAIR' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @CustomerID = WO.CustomerId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

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
			
				CREATE TABLE #AltPartList 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[ItemMasterId] [bigint] NULL,
					[AltItemMasterId] [bigint] NULL
				)

				CREATE TABLE #EquPartList 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[ItemMasterId] [bigint] NULL,
					[EquItemMasterId] [bigint] NULL
				)
				
				INSERT INTO #AltPartList
				([ItemMasterId], [AltItemMasterId])
				SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
					LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
					LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
					JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
				WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId

				INSERT INTO #EquPartList
				([ItemMasterId], [EquItemMasterId])
				SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
				FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
					LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
					LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
					JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
				WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId

				SELECT  DISTINCT WOM.WorkOrderId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderMaterialsKitId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						WOM.ItemMasterId,
						0 AS AltPartMasterPartId,
						0 AS EquPartMasterPartId,
						WOM.ConditionCodeId AS ConditionId,
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
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
						AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
						AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
						AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId)

				UNION ALL

				SELECT  DISTINCT WOM.WorkOrderId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderMaterialsKitId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						Alt.AltItemMasterId ItemMasterId,
						Alt.ItemMasterId AS AltPartMasterPartId,
						Alt.ItemMasterId AS EquPartMasterPartId,
						WOM.ConditionCodeId AS ConditionId,
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
						IM_AltMain.PartNumber MainPartNumber,
						IM_AltMain.PartDescription MainPartDescription,
						IM_AltMain.ManufacturerName MainManufacturer,
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
					FROM #AltPartList Alt
						JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
						JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
						JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
						AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
						AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
						AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId)

				UNION ALL

				SELECT  DISTINCT WOM.WorkOrderId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderMaterialsKitId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						Equ.EquItemMasterId ItemMasterId,
						Equ.ItemMasterId AS AltPartMasterPartId,
						Equ.ItemMasterId AS EquPartMasterPartId,
						WOM.ConditionCodeId AS ConditionId,
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
						IM_EquMain.PartNumber MainPartNumber,
						IM_EquMain.PartDescription MainPartDescription,
						IM_EquMain.ManufacturerName MainManufacturer,
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
					FROM #EquPartList Equ
						JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
						JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
						JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
						AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
						AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
						AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId)
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrdMaterialsStocklineListForAddInKitMaterial' 
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