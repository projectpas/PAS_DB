-------------------------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_GetWorkOrderMaterialsList]           
 ** Author:   subhash Saliya
 ** Description: This stored procedure is used retrieve Work Order Materials Rollup List    
 ** Purpose:         
 ** Date:   04/05/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/05/2021   Subhash Saliya Created
     
 EXECUTE USP_GetRollupMaterialList 325

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetRollupMaterialList]    
(    
@workOrderMaterialId BIGINT = NULL 
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	
	SELECT  IM.PartNumber,
			IM.PartDescription, 
			WOWF.WorkOrderNumber,
			WOWF.WorkOrderId,
			SWO.SubWorkOrderNo,
			'' AS SalesOrder,
			S.Name AS Site,
			W.Name AS WareHouse,
			l.Name AS Location,
			SLF.Name AS Shelf,
			B.Name AS Bin,
			WOM.PartStatusId,
			P.Description AS Provision,
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
			sl.StockLineNumber,
			pop.AltEquiPartNumber as AltPartNumber,
			sl.SerialNumber,
			sl.IdNumber as ControlId,
			sl.ControlNumber as ControlNo,
			PartQuantityOnHand = sl.QuantityOnHand,
			PartQuantityAvailable = sl.QuantityAvailable,
			PartQuantityReserved = (SELECT SUM(sl.QuantityReserved) FROM WorkOrderMaterialStockLine womsl 
							JOIN StockLine sl on womsl.StockLIneId = sl.StockLIneId 
							Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
							),
			sl.QuantityTurnIn as PartQuantityTurnIn,
			PartQuantityOnOrder = sl.QuantityOnOrder,
			sl.ReceiverNumber as Receiver,
			CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND
						IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
			Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN Currency CUR ON IMPS.PP_CurrencyId = CUR.CurrencyId 
						WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
			QuantityIssued = wsl.QtyIssued,
			QuantityReserved = wsl.QtyReserved,
			QunatityRemaining = WOM.Quantity - (SELECT SUM(womsl.QtyReserved) FROM WorkOrderMaterialStockLine womsl Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId),
			WOM.Quantity,
			wsl.ConditionId as ConditionCodeId,
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
			T.Description AS TaskName,
			MM.Name AS MandatoryOrSupplemental,
			WOM.MaterialMandatoriesId,
            WOM.MasterCompanyId,
            WOM.ParentWorkOrderMaterialsId,
            WOM.IsAltPart,
            WOM.IsEquPart,
			ITC.Description AS ItemClassification,
			UOM.ShortName AS UOM,
			CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
			IsRoleUp = 1,
            WOM.ProvisionId,
			CASE WHEN SBWOMM.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreated,
			CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
			isnull(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
	        StockLIneId = (SELECT top 1 sl.StockLIneId
							FROM WorkOrderMaterialStockLine womsl JOIN StockLine sl on womsl.StockLIneId = sl.StockLIneId
							Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
							),
			wom.Quantity as QunatityRequried,
			pop.QuantityBackOrdered as QunatityBackOrder,
			po.PurchaseOrderNumber as PurchaseOrderNumber,
			ro.NeedByDate as NeedDate,
			ro.RepairOrderNumber as RepairOrderNumber,
			tl.TimeRemaining as TimeLife,
			wsl.UnitPrice as Price,
			wsl.ExtendedPrice,
            wsl.UnitCost,
            wsl.ExtendedCost
	    FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
		join dbo.WorkOrderMaterialStockLine wsl on wom.WorkOrderMaterialsId = wsl.WorkOrderMaterialsId
		join dbo.StockLine sl on wsl.StockLIneId = sl.StockLineId
		JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
		JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
		JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
		JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
		JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
		left join dbo.PurchaseOrderPart pop on sl.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
		left join dbo.PurchaseOrder po on pop.PurchaseOrderId = po.PurchaseOrderId
		left join dbo.RepairOrderPart rop on sl.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
		left join dbo.RepairOrder ro on rop.RepairOrderId = ro.RepairOrderId
		left join dbo.TimeLife tl on sl.TimeLifeCyclesId = tl.TimeLifeCyclesId
		LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
		LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
		LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
		LEFT JOIN dbo.Site S WITH (NOLOCK) ON S.SiteId = IM.SiteId
		LEFT JOIN dbo.Warehouse W WITH (NOLOCK) ON W.WarehouseId = IM.WarehouseId
		LEFT JOIN dbo.Location L WITH (NOLOCK) ON L.LocationId = IM.LocationId
		LEFT JOIN dbo.Shelf SLF WITH (NOLOCK) ON SLF.ShelfId = IM.ShelfId
		LEFT JOIN dbo.Bin B WITH (NOLOCK) ON B.BinId = IM.BinId
		LEFT JOIN dbo.SubWorkOrderMaterialMapping SBWOMM WITH (NOLOCK) ON SBWOMM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
		LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
		WHERE WOM.WorkOrderMaterialsId = @workOrderMaterialId --AND WOM.IsAltPart = 0 AND WOM.IsEquPart = 0;
END