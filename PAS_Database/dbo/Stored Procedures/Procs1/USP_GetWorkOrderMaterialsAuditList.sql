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
    1    02/22/2021   Hemant Saliya   Created
    2    02/06/2023   Rajesh Gami     Added Figure and Item field for the audit
    3    11/02/2025   Bhargav Saliya  UTC Date Changes
	4    26/03/2026   RAJESH GAMI     UOM Changes [PN-14832]
	5	 19/06/2026	  Ayushi		  [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 EXECUTE USP_GetWorkOrderMaterialsAuditList 37
**************************************************************/     
CREATE     PROCEDURE [dbo].[USP_GetWorkOrderMaterialsAuditList]    
(    
@WorkOrderMaterialsId BIGINT = NULL,  
@EmployeeId BIGINT = NULL  
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN    

			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
			SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE E.EmployeeId = @EmployeeId;
			
			WITH WOM_CTE AS
					(
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
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND ISNULL(sl.IsNonStock,0) = 0
									),
					PartQuantityAvailable = (SELECT SUM(sl.QuantityAvailable) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND ISNULL(sl.IsNonStock,0) = 0
									),
					PartQuantityReserved = (SELECT SUM(sl.QuantityReserved) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND ISNULL(sl.IsNonStock,0) = 0
									),
					PartQuantityTurnIn = (SELECT SUM(sl.QuantityTurnIn) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND ISNULL(sl.IsNonStock,0) = 0
									),
					PartQuantityOnOrder = (SELECT SUM(sl.QuantityOnOrder) FROM WorkOrderMaterialStockLine womsl  WITH (NOLOCK)
									JOIN StockLine sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
									Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND ISNULL(sl.IsNonStock,0) = 0
									),
					CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND
								IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
					Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId 
								WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
					MSTL.Quantity AS StocklineQuantity,
					QuantityIssued = WOM.QuantityIssued,
					WOM.QuantityReserved,
					QunatityRemaining = ISNULL(WOM.Quantity, 0) - ISNULL(WOM.QuantityIssued, 0),
					WOM.QtyOnOrder, 
					WOM.QtyOnBkOrder,
					WOM.PONum AS PurchaseOrderNumber,
					WOM.Quantity,
					WOM.ConditionCodeId,
					WOM.UnitOfMeasureId,
					WOM.WorkOrderMaterialsId,
					WOM.WorkFlowWorkOrderId,
					IM.ItemMasterId,
					IM.ItemClassificationId,
					IM.PurchaseUnitOfMeasureId,
					WOM.Memo,
					ISNULL(MSTL.Notes, WOM.Notes) AS Notes,
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
					uomConsume.ShortName AS UOM,
					CASE WHEN WOM.IsDeferred IS NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
					IsRoleUp = 0,
					WOM.ProvisionId,
					CASE WHEN SBWOMM.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreated,
					CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
					isnull(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
					WOM.CreatedBy,
					WOM.UpdatedBy,
					CASE WHEN CAST(WOM.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOM.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
					CASE WHEN CAST(WOM.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOM.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
					ROP.EstRecordDate 'RONextDlvrDate',
					RO.RepairOrderNumber
					,WOM.Figure
					,WOM.Item
					,uomStock.ShortName uomStock
					,uomConsume.ShortName uomConsume
				FROM dbo.WorkOrderMaterialsAudit WOM WITH (NOLOCK)  
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
					--JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
					JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
					JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
					LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId AND ISNULL(SL.IsNonStock,0) = 0
					LEFT JOIN dbo.UnitOfMeasure uomStock WITH (NOLOCK) ON uomStock.UnitOfMeasureId = SL.StockUnitOfMeasureId
					LEFT JOIN dbo.UnitOfMeasure uomConsume WITH (NOLOCK) ON uomConsume.UnitOfMeasureId = SL.ConsumeUnitOfMeasureId
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
			 AND ISNULL(IM.IsNonStock,0) = 0
				)
				SELECT
					PartNumber,
					PartDescription,
					WorkOrderNumber,
					WorkOrderId,
					SubWorkOrderNo,
					SalesOrder,
					Site,
					WareHouse,
					Location,
					Shelf,
					Bin,
					PartStatusId,
					Provision,
					StockType,
					ItemType,
					Condition,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(UnitCost,0) ELSE dbo.fn_ConvertUOM(UnitCost,uomStock,uomConsume,1,MasterCompanyId) END AS UnitCost,
					(CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(UnitCost,0) ELSE dbo.fn_ConvertUOM(UnitCost,uomStock,uomConsume,1,MasterCompanyId) END * CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(Quantity,0) ELSE dbo.fn_ConvertUOM(Quantity,uomStock,uomConsume,0,MasterCompanyId) END) AS ExtendedCost,
					StockLineId,
					StockLineNumber,
					SerialNumber,
					ControlId,
					ControlNo,
					Receiver,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(PartQuantityOnHand,0) ELSE dbo.fn_ConvertUOM(PartQuantityOnHand,uomStock,uomConsume,0,MasterCompanyId) END AS PartQuantityOnHand,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(PartQuantityAvailable,0) ELSE dbo.fn_ConvertUOM(PartQuantityAvailable,uomStock,uomConsume,0,MasterCompanyId) END AS PartQuantityAvailable,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(PartQuantityReserved,0) ELSE dbo.fn_ConvertUOM(PartQuantityReserved,uomStock,uomConsume,0,MasterCompanyId) END AS PartQuantityReserved,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(PartQuantityTurnIn,0) ELSE dbo.fn_ConvertUOM(PartQuantityTurnIn,uomStock,uomConsume,0,MasterCompanyId) END AS PartQuantityTurnIn,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(PartQuantityOnOrder,0) ELSE dbo.fn_ConvertUOM(PartQuantityOnOrder,uomStock,uomConsume,0,MasterCompanyId) END AS PartQuantityOnOrder,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(StocklineQuantity,0) ELSE dbo.fn_ConvertUOM(StocklineQuantity,uomStock,uomConsume,0,MasterCompanyId) END AS StocklineQuantity,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(QuantityIssued,0) ELSE dbo.fn_ConvertUOM(QuantityIssued,uomStock,uomConsume,0,MasterCompanyId) END AS QuantityIssued,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(QuantityReserved,0) ELSE dbo.fn_ConvertUOM(QuantityReserved,uomStock,uomConsume,0,MasterCompanyId) END AS QuantityReserved,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(QunatityRemaining,0) ELSE dbo.fn_ConvertUOM(QunatityRemaining,uomStock,uomConsume,0,MasterCompanyId) END AS QunatityRemaining,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(QtyOnOrder,0) ELSE dbo.fn_ConvertUOM(QtyOnOrder,uomStock,uomConsume,0,MasterCompanyId) END AS QtyOnOrder,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(QtyOnBkOrder,0) ELSE dbo.fn_ConvertUOM(QtyOnBkOrder,uomStock,uomConsume,0,MasterCompanyId) END AS QtyOnBkOrder,
					PurchaseOrderNumber,
					CASE WHEN ISNULL(uomStock,'') = ISNULL(uomConsume,'') THEN ISNULL(Quantity,0) ELSE dbo.fn_ConvertUOM(Quantity,uomStock,uomConsume,0,MasterCompanyId) END AS Quantity,
					ConditionCodeId,
					UnitOfMeasureId,
					WorkOrderMaterialsId,
					WorkFlowWorkOrderId,
					ItemMasterId,
					ItemClassificationId,
					PurchaseUnitOfMeasureId,
					Memo,
					Notes,
					IsDeferred,
					TaskId,
					TaskName,
					MandatoryOrSupplemental,
					MaterialMandatoriesId,
					MasterCompanyId,
					ParentWorkOrderMaterialsId,
					IsAltPart,
					IsEquPart,
					ItemClassification,
					UOM,
					Defered,
					IsRoleUp,
					ProvisionId,
					IsSubWorkOrderCreated,
					SubWorkOrderId,
					IsFromWorkFlow,
					CreatedBy,
					UpdatedBy,
					CreatedDate,
					UpdatedDate,
					RONextDlvrDate,
					RepairOrderNumber,
					Figure,
					Item,
					uomStock,
					uomConsume,CostDate,Currency
				FROM WOM_CTE;
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