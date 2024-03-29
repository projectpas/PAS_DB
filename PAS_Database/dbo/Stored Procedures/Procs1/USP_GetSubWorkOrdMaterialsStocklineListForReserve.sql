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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    12/24/2021   Hemant Saliya		Created
	2    08/11/2023   Amit Ghediya		Not allow AR condition record when populate reserve list

     
 EXECUTE [USP_GetSubWorkOrdMaterialsStocklineListForReserve] 31

**************************************************************/ 
    
CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrdMaterialsStocklineListForReserve]    
(    
@SubWOPartNoId BIGINT = NULL,
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
				DECLARE @Provision VARCHAR(50);
				DECLARE @ProvisionCode VARCHAR(50);
				DECLARE @CustomerID BIGINT;
				DECLARE @ARConditionId BIGINT;
				DECLARE @MasterCompanyId INT;
				
				SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @MasterCompanyId = WO.MasterCompanyId ,@CustomerID = WO.CustomerId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.SubWorkOrderPartNumber SWOP WITH(NOLOCK) on WO.WorkOrderId = SWOP.WorkOrderId WHERE SWOP.SubWOPartNoId = @SubWOPartNoId;
				SELECT @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END

				SELECT  WOM.WorkOrderId,
						WOM.SubWorkOrderId,
						WOM.SubWOPartNoId,
						WOM.SubWorkOrderMaterialsId,						
						WOM.ItemMasterId,
						WOM.ConditionCodeId AS ConditionId,
						WOM.MasterCompanyId,
						WOM.Quantity,
						WOM.QuantityReserved,
						WOM.QuantityIssued,
						(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
						CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
						AS MSQuantityRequsted,
						WOMS.QtyReserved AS MSQuantityReserved,
						WOMS.QtyIssued AS MSQuantityIssued,
						CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
						CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
						CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
						LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
					AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
					AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
					AND WOM.ConditionCodeId <> @ARConditionId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrdMaterialsStocklineListForReserve' 
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