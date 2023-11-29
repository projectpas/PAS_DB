/*************************************************************           
 ** File:   [USP_GetWorkOrdMaterialsStocklineListForIssue]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to get Stockline list to Issue Stockline    
 ** Purpose:         
 ** Date:   01/03/2022       
          
 ** PARAMETERS:           
 @WorkFlowWorkOrderId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2022   Hemant Saliya		Created
	2    03/27/2023   Hemant Saliya		Added WO Materials KIT Changes
	3    03/28/2023   Vishal Suthar		Added WO Materials KIT Changes
	4    25/05/2023   Hemant Saliya		Update for Internal WO Type Issue 
	5    10/04/2023   Hemant Saliya		Condition Group Changes

 EXECUTE USP_GetWorkOrdMaterialsStocklineListForIssue 2940,0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWorkOrdMaterialsStocklineListForIssue]
(    
	@WorkFlowWorkOrderId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL
)    
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @ProvisionId BIGINT;
				DECLARE @WorkOrderId BIGINT;
				DECLARE @WorkOrderTypeId INT;
				DECLARE @MasterCompanyId INT;
				DECLARE @IsEnforcePickTicket BIT;
				DECLARE @CustomerID BIGINT;

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

				SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderId = WorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND IsActive = 1 AND IsDeleted = 0;
				SELECT @WorkOrderTypeId = WorkOrderTypeId, @CustomerID = CustomerId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND IsActive = 1 AND IsDeleted = 0;
				SELECT @IsEnforcePickTicket = ISNULL(EnforcePickTicket,0) FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END

				If (@IsEnforcePickTicket = 1)
				BEGIN
				PRINT '0'
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
						--IM.PartNumber AS MainPartNumber,
						--IM.PartDescription AS MainPartDescription, 
						--IM.ManufacturerName MainManufacturer,
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
						CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						SP.Description AS MatStlProvision,
						SP.StatusCode AS MatStlProvisionCode,
						CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
						0 AS IsKitType,
						0 AS KitId,
						WOMS.IsAltPart,
						WOMS.IsEquPart
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
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
						AND WOM.IsDeleted = 0 						
						--AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)

					UNION ALL

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
						CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						SP.Description AS MatStlProvision,
						SP.StatusCode AS MatStlProvisionCode,
						CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
						1 AS IsKitType,
						(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
						dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId
						WHERE WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMK.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId) AS KitId,
						WOMS.IsAltPart,
						WOMS.IsEquPart
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
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
						AND WOM.IsDeleted = 0 						
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
					
				END
				ELSE
				BEGIN
					PRINT '1'
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
						--IM.PartNumber AS MainPartNumber,
						--IM.PartDescription AS MainPartDescription, 
						--IM.ManufacturerName MainManufacturer,
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
						CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						SP.Description AS MatStlProvision,
						SP.StatusCode AS MatStlProvisionCode,
						CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
						0 AS IsKitType,
						0 AS KitId,
						WOMS.IsAltPart,
						WOMS.IsEquPart
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
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
						AND WOM.IsDeleted = 0 						
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)

					UNION ALL

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
						CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						SP.Description AS MatStlProvision,
						SP.StatusCode AS MatStlProvisionCode,
						CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
						1 AS IsKitType,
						(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
						dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId
						WHERE WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMK.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId) AS KitId,
						WOMS.IsAltPart,
						WOMS.IsEquPart
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
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityOnHand,0) > 0 
						AND WOM.IsDeleted = 0 						
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
				END
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrdMaterialsStocklineListForIssue' 
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