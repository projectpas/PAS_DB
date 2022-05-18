/*************************************************************           
 ** File:   [USP_GetSubWorkOrdMaterialsStocklineListForIssue]           
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
    1    01/03/2022   Hemant Saliya Created

     
 EXECUTE USP_GetSubWorkOrdMaterialsStocklineListForIssue 28,0

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetSubWorkOrdMaterialsStocklineListForIssue]    
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
				DECLARE @WorkOrderId BIGINT;
				DECLARE @WorkOrderTypeId INT;
				DECLARE @MasterCompanyId INT;
				DECLARE @IsEnforcePickTicket BIT;
				DECLARE @CustomerID BIGINT;

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
				)

				SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @WorkOrderTypeId = Id FROM dbo.WorkOrderType WITH(NOLOCK) WHERE UPPER([Description]) = 'CUSTOMER' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderId = WorkOrderId FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId AND IsActive = 1 AND IsDeleted = 0;
				SELECT @CustomerID = CustomerId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId;
				SELECT @IsEnforcePickTicket = ISNULL(EnforcePickTicket,0) FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END

				if(@IsEnforcePickTicket = 1)
				BEGIN

					INSERT INTO #tmpSubWorkorderPickTicketMaterials (WorkOrderId, SubWorkOrderId, SubWOPartNoId, SubWorkOrderMaterialsId, QtyToShip)
					SELECT WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, SUM(QtyToShip)
					FROM dbo.SubWorkorderPickTicket WITH(NOLOCK) 
					WHERE WorkorderId = @WorkOrderId AND SubWorkorderPartNoId = @SubWOPartNoId AND IsConfirmed = 1 AND QtyToShip > 0 
					GROUP BY WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId

					INSERT INTO #tmpSubWorkorderPickTicket (WorkOrderId, SubWorkOrderId, SubWOPartNoId, SubWorkOrderMaterialsId, StocklineId, QtyToShip)
					SELECT WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, StocklineId, SUM(QtyToShip)
					FROM dbo.SubWorkorderPickTicket WITH(NOLOCK) 
					WHERE WorkorderId = @WorkOrderId AND IsConfirmed = 1 AND QtyToShip > 0 
					GROUP BY WorkOrderId, SubWorkOrderId, SubWorkorderPartNoId, SubWorkOrderMaterialsId, StocklineId

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
						WOM.QuantityReserved AS QtyToBeIssued,
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
						PTKT.QtyToShip AS QuantityPicked,
						MPTKT.QtyToShip AS MaterialsQuantityPicked,
						WOMS.QtyReserved AS MSQtyToBeIssued,
						CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						SP.Description AS MatStlProvision,
						SP.StatusCode AS MatStlProvisionCode,
						CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
						JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
						JOIN #tmpSubWorkorderPickTicket PTKT WITH (NOLOCK) ON PTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND PTKT.StockLineId = WOMS.StockLineId 
						JOIN #tmpSubWorkorderPickTicketMaterials MPTKT WITH (NOLOCK) ON MPTKT.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId						
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0 
						AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
					
				END
				ELSE
				BEGIN
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
						WOM.QuantityReserved AS QtyToBeIssued,
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
						WOMS.QtyReserved AS QuantityPicked,
						WOM.QuantityReserved AS MaterialsQuantityPicked,
						WOMS.QtyReserved AS MSQtyToBeIssued,
						CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
						MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
						SP.Description AS MatStlProvision,
						SP.StatusCode AS MatStlProvisionCode,
						CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId AND WOMS.QtyReserved > 0
						JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOMS.StockLineId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
						LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
					WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityOnHand,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0 
					AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrdMaterialsStocklineListForIssue' 
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