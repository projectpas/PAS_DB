/*************************************************************           
 ** File:   [USP_GetWorkOrdMaterialsStocklineListForUnReserve]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to get Stockline list to Un Reserve Stockline    
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
    1    01/03/2022   Hemant Saliya Created
	2    10/04/2023   Hemant Saliya		Condition Group Changes
	3    26/06/2024   Devendra Shekh	added TaskName To Select
    4    04-March-2026 Rajesh Gami		Implemented UOM Changes [PN-14832]
	5	 19/06/2026	  Ayushi		    [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
 EXECUTE USP_GetWorkOrdMaterialsStocklineListForUnReserve 99,15
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrdMaterialsStocklineListForUnReserve]
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

				SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @WorkOrderTypeId = Id FROM dbo.WorkOrderType WITH(NOLOCK) WHERE UPPER([Description]) = 'CUSTOMER' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderId = WorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND IsActive = 1 AND IsDeleted = 0;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END
			;WITH cte AS(
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
						WOM.QuantityReserved AS QtyToBeUnReserved,
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
						uomConsume.ShortName UnitOfMeasure,
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
						0 AS KitId,
						WOMS.IsAltPart,
						WOMS.IsEquPart
						,TS.[Description] AS 'TaskName' 
						,uomStock.ShortName AS StockUOM, 
						uomConsume.ShortName AS ConsumeUOM
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
						LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
						LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
						LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = SL.StockUnitOfMeasureId
						LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = SL.ConsumeUnitOfMeasureId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND SL.IsParent = 1 
					AND WOM.IsDeleted = 0  AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
				
				UNION ALL

				SELECT  WOM.WorkOrderId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,						
						WOM.ItemMasterId,
						WOM.ConditionCodeId AS ConditionId,
						WOM.MasterCompanyId,
						WOM.Quantity,
						WOM.QuantityReserved,
						WOM.QuantityIssued,
						WOM.QtyOnOrder AS QuantityOnOrder,
						WOM.QuantityReserved AS QtyToBeUnReserved,
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
						uomConsume.ShortName UnitOfMeasure,
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
						(SELECT ISNULL(WOMKM.KitId, 0) FROM dbo.[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) INNER JOIN 
						dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId
						WHERE WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMK.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId) AS KitId,
						WOMS.IsAltPart,
						WOMS.IsEquPart
						,TS.[Description] AS 'TaskName'
						,uomStock.ShortName AS StockUOM, 
						uomConsume.ShortName AS ConsumeUOM
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOMS.ItemMasterId
						LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = WOMS.AltPartMasterPartId
						LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = WOMS.EquPartMasterPartId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
						LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
						LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = SL.StockUnitOfMeasureId
						LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = SL.ConsumeUnitOfMeasureId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND SL.IsParent = 1 
					AND WOM.IsDeleted = 0  AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
					)
					SELECT  
						WorkOrderId,
						WorkFlowWorkOrderId,
						WorkOrderMaterialsId,
						ItemMasterId,
						ConditionId,
						MasterCompanyId,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(Quantity,0) ELSE dbo.fn_ConvertUOM(Quantity,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS Quantity,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QuantityReserved,0) ELSE dbo.fn_ConvertUOM(QuantityReserved,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QuantityReserved,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QuantityIssued,0) ELSE dbo.fn_ConvertUOM(QuantityIssued,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QuantityIssued,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QuantityOnOrder,0) ELSE dbo.fn_ConvertUOM(QuantityOnOrder,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QuantityOnOrder,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QtyToBeUnReserved,0) ELSE dbo.fn_ConvertUOM(QtyToBeUnReserved,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QtyToBeUnReserved,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(UnitCost,0) ELSE dbo.fn_ConvertUOM(UnitCost,StockUOM,ConsumeUOM,1,[MasterCompanyId]) END AS UnitCost,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(ExtendedCost,0) ELSE dbo.fn_ConvertUOM(ExtendedCost,StockUOM,ConsumeUOM,1,[MasterCompanyId]) END AS ExtendedCost,
						TaskId,
						ProvisionId,
						PartNumber,
						PartDescription,
						MainPartNumber,
						MainPartDescription,
						MainManufacturer,
						MainCondition,
						StocklineId,
						Condition,
						StockLineNumber,
						ControlNumber,
						IdNumber,
						Manufacturer,
						SerialNumber,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QuantityAvailable,0) ELSE dbo.fn_ConvertUOM(QuantityAvailable,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QuantityAvailable,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QuantityOnHand,0) ELSE dbo.fn_ConvertUOM(QuantityOnHand,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QuantityOnHand,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(StocklineQuantityOnOrder,0) ELSE dbo.fn_ConvertUOM(StocklineQuantityOnOrder,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS StocklineQuantityOnOrder,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(StocklineQuantityTurnIn,0) ELSE dbo.fn_ConvertUOM(StocklineQuantityTurnIn,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS StocklineQuantityTurnIn,
						UnitOfMeasure,
						Provision,
						ProvisionStatusCode,
						StockType,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(MSQuantityRequsted,0) ELSE dbo.fn_ConvertUOM(MSQuantityRequsted,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS MSQuantityRequsted,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(MSQuantityReserved,0) ELSE dbo.fn_ConvertUOM(MSQuantityReserved,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS MSQuantityReserved,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(MSQuantityIssued,0) ELSE dbo.fn_ConvertUOM(MSQuantityIssued,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS MSQuantityIssued,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(QuantityPicked,0) ELSE dbo.fn_ConvertUOM(QuantityPicked,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS QuantityPicked,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(MaterialsQuantityPicked,0) ELSE dbo.fn_ConvertUOM(MaterialsQuantityPicked,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS MaterialsQuantityPicked,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(MSQtyToBeIssued,0) ELSE dbo.fn_ConvertUOM(MSQtyToBeIssued,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS MSQtyToBeIssued,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(SLUnitCost,0) ELSE dbo.fn_ConvertUOM(SLUnitCost,StockUOM,ConsumeUOM,1,[MasterCompanyId]) END AS SLUnitCost,
						CASE WHEN ISNULL(StockUOM,'') = ISNULL(ConsumeUOM,'') THEN ISNULL(MSQunatityRemaining,0) ELSE dbo.fn_ConvertUOM(MSQunatityRemaining,StockUOM,ConsumeUOM,0,[MasterCompanyId]) END AS MSQunatityRemaining,
						MatStlProvision,
						MatStlProvisionCode,
						IsStocklineAdded,
						KitId,
						IsAltPart,
						IsEquPart,
						TaskName
					FROM CTE;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrdMaterialsStocklineListForUnReserve' 
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