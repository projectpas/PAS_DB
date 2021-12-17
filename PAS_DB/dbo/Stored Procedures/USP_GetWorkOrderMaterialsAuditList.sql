
/*************************************************************           
 ** File:   [USP_GetWorkOrderMaterialsAuditList]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Materials List    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya Created
     
 EXECUTE USP_GetWorkOrderMaterialsAuditList 37

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderMaterialsAuditList]    
(    
@WorkOrderMaterialsId BIGINT = NULL  
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN    
				SELECT  
					WOM.PartNum  as PartNumber,
					WOM.PartDescription as PartDescription, 
					WorkOrderNumber = (select top 1(WO.WorkOrderNum) from  WorkOrder wo WITH (NOLOCK) where wo.WorkOrderId=WOM.WorkOrderId ),
					WOM.WorkOrderId,
					SWO.SubWorkOrderNo,
					'' AS SalesOrder,
					S.Name AS Site,
					W.Name AS WareHouse,
					l.Name AS Location,
					SLF.Name AS Shelf,
					B.Name AS Bin,
					WOM.PartStatusId,
					WOM.Provision AS Provision,
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
					wom.Condition AS Condition,
					WOM.UnitCost,
					WOM.ExtendedCost,
					MSTL.StockLIneId,
					SL.StockLineNumber,
					SL.SerialNumber,
					SL.IdNumber AS ControlId,
					SL.ControlNumber AS ControlNo,
					SL.ReceiverNumber AS Receiver,
					PartQuantityOnHand = (SELECT SUM(sl.QuantityOnHand)
									FROM WorkOrderMaterialStockLine womsl WITH (NOLOCK) JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
									),
					PartQuantityAvailable = (SELECT SUM(sl.QuantityAvailable) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
									),
					PartQuantityReserved = (SELECT SUM(sl.QuantityReserved) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
									),
					PartQuantityTurnIn = (SELECT SUM(sl.QuantityTurnIn) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
									),
					PartQuantityOnOrder = (SELECT SUM(sl.QuantityOnOrder) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
									),
					CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND
								IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
					Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId 
								WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
					MSTL.Quantity AS StocklineQuantity,
					QuantityIssued = WOM.QuantityIssued,
					WOM.QuantityReserved,
					QunatityRemaining = ISNULL(WOM.QuantityIssued, 0),
					WOM.QtyOnOrder, 
					WOM.QtyOnBkOrder,
					WOM.PONum AS PurchaseOrderNumber,
					WOM.Quantity,
					WOM.ConditionCodeId,
					WOM.UnitOfMeasureId,
					WOM.WorkOrderMaterialsId,
					WOM.WorkFlowWorkOrderId,
					WOM.WorkOrderId,
					IM.ItemMasterId,
					IM.ItemClassificationId,
					IM.PurchaseUnitOfMeasureId,
					WOM.Memo,
					WOM.IsDeferred,
					WOM.TaskId,
					wom.TaskName,
					MM.Name AS MandatoryOrSupplemental,
					WOM.MaterialMandatoriesId,
					WOM.MasterCompanyId,
					WOM.ParentWorkOrderMaterialsId,
					WOM.IsAltPart,
					WOM.IsEquPart,
					WOM.ItemClassification AS ItemClassification,
					UOM.ShortName AS UOM,
					CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
					IsRoleUp = 0,
					WOM.ProvisionId,
					CASE WHEN SBWOMM.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreaetd,
					CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
					isnull(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
					WOM.CreatedBy,
					WOM.UpdatedBy,
					WOM.CreatedDate,
					WOM.UpdatedDate,
					ROP.EstRecordDate 'RONextDlvrDate',
					RO.RepairOrderNumber
				FROM dbo.WorkOrderMaterialsAudit WOM WITH (NOLOCK)  
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
					JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
					JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
					JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
					LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
					LEFT JOIN dbo.Site S WITH (NOLOCK) ON S.SiteId = IM.SiteId
					LEFT JOIN dbo.Warehouse W WITH (NOLOCK) ON W.WarehouseId = IM.WarehouseId
					LEFT JOIN dbo.Location L WITH (NOLOCK) ON L.LocationId = IM.LocationId
					LEFT JOIN dbo.Shelf SLF WITH (NOLOCK) ON SLF.ShelfId = IM.ShelfId
					LEFT JOIN dbo.Bin B WITH (NOLOCK) ON B.BinId = IM.BinId
					LEFT JOIN dbo.SubWorkOrderMaterialMapping SBWOMM WITH (NOLOCK) ON SBWOMM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
					LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
					LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
					LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
				WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderMaterialsListAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderMaterialsId, '') + ''
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