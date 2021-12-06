﻿
/*************************************************************           
 ** File:   [USP_GetSubWorkOrderMaterialsList]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Sub Materials List    
 ** Purpose:         
 ** Date:   03/23/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/23/2021   Hemant Saliya Created
     
 EXECUTE USP_GetSubWorkOrderMaterialsList 49

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetSubWorkOrderMaterialsList]    
(    
@subWOPartNoId BIGINT = NULL  
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					SELECT DISTINCT 
						IM.PartNumber,
						IM.PartDescription, 
						IM.ItemGroup,
						IM.ManufacturerName,
						W.WorkOrderNum As WorkOrderNumber,
						WOM.WorkOrderId,
						SWO.SubWorkOrderNo as SubWorkOrderNo,
						SWO.SubWorkOrderId,
						'' AS SalesOrder,
						IM.SiteName AS Site,
						IM.WarehouseName AS WareHouse,
						IM.LocationName AS Location,
						IM.ShelfName AS Shelf,
						IM.BinName AS Bin,
						WOM.PartStatusId,
						P.Description AS Provision,
						P.StatusCode AS ProvisionStatusCode,
						CASE 
						WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
						WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
						WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType,
						CASE 
						WHEN IM.ItemTypeId = 1 THEN 'Stock'
						WHEN IM.ItemTypeId = 2 THEN 'Non Stock'
						WHEN IM.ItemTypeId = 3 THEN 'Equipment'
						WHEN IM.ItemTypeId = 4 THEN 'Loan'
						ELSE ''
						END AS ItemType,
						C.Description AS Condition,						
						WOM.UnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						MSTL.StockLIneId,						 
						MSTL.UnitCost StocklineUnitCost,
						MSTL.ExtendedCost StocklineExtendedCost,
						MSTL.ProvisionId AS StockLineProvisionId,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,

						PartQuantityOnHand = (SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM dbo.StockLine sl  WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),
						PartQuantityAvailable = (SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM dbo.StockLine sl  WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),
						PartQuantityReserved = (SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl  WITH (NOLOCK)
										JOIN dbo.StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						PartQuantityTurnIn = (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl WITH (NOLOCK) 
										JOIN dbo.StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						PartQuantityOnOrder = (SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl  WITH (NOLOCK)
										JOIN dbo.StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND
									IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN dbo.Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = (SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl WITH (NOLOCK) 
										WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QuantityReserved = (SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl  WITH (NOLOCK)
											WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QunatityRemaining = WOM.Quantity - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl  WITH (NOLOCK)
											WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),
						MSTL.Quantity AS StocklineQuantity,
						MSTL.QtyReserved AS StocklineQtyReserved,
						MSTL.QtyIssued AS StocklineQtyIssued,
						SL.QuantityTurnIn as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						WOM.Quantity,
						WOM.ConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderId,
						IM.ItemMasterId,
						IM.ItemClassificationId,
						IM.PurchaseUnitOfMeasureId,
						WOM.Memo,
						WOM.IsDeferred,
						WOM.TaskId,
						WOM.TaskName AS TaskName,
						MM.Name AS MandatoryOrSupplemental,
						WOM.MaterialMandatoriesId,
						WOM.MasterCompanyId,
						WOM.IsAltPart,
						WOM.IsEquPart,
						WOM.ItemClassification AS ItemClassification,
						UOM.ShortName AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						WOM.SubWorkOrderMaterialsId,
						WOM.SubWOPartNoId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						SL.StockLineId AS  StockLIneId ,
						Employeename = (SELECT TOP 1 (EMP.FirstName +''+ EMP.LastName) FROM dbo.Employee EMP WITH (NOLOCK) WHERE W.EmployeeID = EMP.EmployeeID  )
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.WorkOrder W WITH (NOLOCK) ON W.WorkOrderId = WOM.WorkOrderId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId						
						JOIN dbo.SubWorkOrderPartNumber wo WITH (NOLOCK) ON wo.SubWOPartNoId = WOM.SubWOPartNoId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.SubWorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId			
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId
					WHERE WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @subWOPartNoId AND ISNULL(WOM.IsAltPart, 0) = 0 AND ISNULL(WOM.IsEquPart, 0) = 0;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderMaterialsList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWOPartNoId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END