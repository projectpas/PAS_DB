/*************************************************************           
 ** File:   [USP_GetWorkOrderMaterialsList]           
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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    02/22/2021   Hemant Saliya		Created
	2    07/22/2021   Hemant Saliya		Update WO & Sub WO Field Mapping to Get it from Stockline
	3    01/03/2021   Hemant Saliya		Update for Performance Improvement
    3    02/03/2023   Rajesh Gami		Update for Figure & Item Changes(Getting Figure and Item from the WorkOrderMaterial Table)  
	4    03/17/2023   Amit Ghediya		Added for get AlterPartNumber from WorkOrderMaterialStockLine.
	5    03/23/2023   Vishal Suthar		Modified query to handle KITs added in the material
	6    05/05/2023   Vishal Suthar		Added column for Stockline Condition
	7    05/09/2023   Vishal Suthar		Added filter for showing only qty remaining
	8    05/18/2023   Hemant Saliya		Updated PO Next Delivery Date Condition
	9    06/08/2023   Vishal Suthar		Fixed the EmployeeName in the WO Material
	10   06/27/2023   Vishal Suthar		Fixed the PO Next Delivery Date issue
	11   06/30/2023   Vishal Suthar		Fixed the RO Next Delivery Date issue
	12   07/19/2023   Hemant Saliya		Fixed the RO Next Delivery Date issue
	13   10/16/2023   Hemant Saliya		Update UOM changes
	14   10/19/2023   Hemant Saliya		Update Stockline Condition
	15   11/29/2023   Devendra Shekh	qty issue for qtyremaining resolved
	16   11/30/2023   Devendra Shekh	qty issue for qtyremaining resolved
	17   12/05/2023   Devendra Shekh	qty issue for qty to tender
	
 EXECUTE [dbo].[USP_GetWorkOrderMaterialsList] 3651,3119, 0
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWorkOrderMaterialsList]
(    
	@WorkOrderId BIGINT = NULL,   
	@WFWOId BIGINT  = NULL,
	@ShowPendingToIssue BIT  = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @MasterCompanyId INT;
				DECLARE @SubProvisionId INT;
				DECLARE @ForStockProvisionId INT;
				DECLARE @exchangeProvision varchar(100) = (SELECT TOP 1 Description FROM dbo.Provision WITH(NOLOCK) where UPPER(StatusCode) = 'EXCHANGE')
				DECLARE @CustomerID BIGINT;

				SELECT @MasterCompanyId = MasterCompanyId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId
				SELECT @SubProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'SUB WORK ORDER'
				SELECT @ForStockProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'FOR STOCK'
				SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WFWOId;

				IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpStockline
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMStockline
				END

				CREATE TABLE #tmpStockline
				(
					ID BIGINT NOT NULL IDENTITY, 						 
					[StockLineId] [bigint] NOT NULL,
					[ItemMasterId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QuantityOnHand] [int] NOT NULL,
					[QuantityReserved] [int] NULL,
					[QuantityAvailable] [int] NULL,
					[QuantityTurnIn] [int] NULL,
					[QuantityOnOrder] [int] NULL,
					[IsParent] [bit] NULL,
				)

				CREATE TABLE #tmpWOMStockline
				(
					ID BIGINT NOT NULL IDENTITY, 						 
					[StockLineId] [bigint] NOT NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QtyIssued] [int] NOT NULL,
					[QtyReserved] [int] NULL,
					[IsActive] BIT NULL,
					[IsDeleted] BIT NULL,
				)

				INSERT INTO #tmpStockline SELECT DISTINCT						
					SL.StockLineId, 						
					SL.ItemMasterId,
					SL.ConditionId,
					SL.QuantityOnHand,
					SL.QuantityReserved,
					SL.QuantityAvailable,
					SL.QuantityTurnIn,
					SL.QuantityOnOrder,
					SL.IsParent
				FROM dbo.Stockline SL WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = sl.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.IsParent = 1
				WHERE SL.MasterCompanyId = @MasterCompanyId 
				AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND  SL.IsActive = 1 AND SL.IsDeleted = 0

				INSERT INTO #tmpWOMStockline SELECT DISTINCT						
						WOMS.StockLineId, 						
						WOMS.WorkOrderMaterialsId,
						WOMS.ConditionId,
						WOMS.QtyIssued,
						WOMS.QtyReserved,
						WOMS.IsActive,
						WOMS.IsDeleted
				FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId 
				AND WOM.WorkFlowWorkOrderId = @WFWOId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

				IF OBJECT_ID(N'tempdb..#tmpStocklineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpStocklineKit
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWOMStocklineKit
				END

				CREATE TABLE #tmpStocklineKit
				(
					ID BIGINT NOT NULL IDENTITY, 						 
					[StockLineId] [bigint] NOT NULL,
					[ItemMasterId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QuantityOnHand] [int] NOT NULL,
					[QuantityReserved] [int] NULL,
					[QuantityAvailable] [int] NULL,
					[QuantityTurnIn] [int] NULL,
					[QuantityOnOrder] [int] NULL,
					[IsParent] [bit] NULL,
				)

				CREATE TABLE #tmpWOMStocklineKit
				(
					ID BIGINT NOT NULL IDENTITY, 						 
					[StockLineId] [bigint] NOT NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QtyIssued] [int] NOT NULL,
					[QtyReserved] [int] NULL,
					[IsActive] BIT NULL,
					[IsDeleted] BIT NULL,
				)

				INSERT INTO #tmpStocklineKit SELECT DISTINCT						
					SL.StockLineId, 						
					SL.ItemMasterId,
					SL.ConditionId,
					SL.QuantityOnHand,
					SL.QuantityReserved,
					SL.QuantityAvailable,
					SL.QuantityTurnIn,
					SL.QuantityOnOrder,
					SL.IsParent
				FROM dbo.Stockline SL WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = sl.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.IsParent = 1
				WHERE SL.MasterCompanyId = @MasterCompanyId 
				AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND  SL.IsActive = 1 AND SL.IsDeleted = 0

				INSERT INTO #tmpWOMStocklineKit SELECT DISTINCT						
						WOMS.StockLineId, 						
						WOMS.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						WOMS.ConditionId,
						WOMS.QtyIssued,
						WOMS.QtyReserved,
						WOMS.IsActive,
						WOMS.IsDeleted
				FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId 
				AND WOM.WorkFlowWorkOrderId = @WFWOId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

				IF (ISNULL(@ShowPendingToIssue, 0) = 1)
				BEGIN
					SELECT DISTINCT IM.PartNumber,
						IM.PartDescription,
						IMS.PartNumber StocklinePartNumber,
						IMS.PartDescription StocklinePartDescription,
						'' AS KitNumber,
						'' AS KitDescription,
						0 AS KitCost,
						0 as WOQMaterialKitMappingId,
						0 AS KitId,
						IM.ItemGroup,
						IM.ManufacturerName,
						SL.WorkOrderNumber,
						SWO.SubWorkOrderNo,
						WOM.WorkOrderId,
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
						Stk_C.Description AS StocklineCondition,
						WOM.UnitCost,
						IMPS.PP_UnitPurchasePrice AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						MSTL.UnitCost StocklineUnitCost,
						MSTL.ExtendedCost StocklineExtendedCost,
						MSTL.StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
							WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
							THEN 0
							ELSE MSTL.IsAltPart 
							END
						) AS IsWOMSAltPart,
						(CASE 
							WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
							THEN 0 
							ELSE MSTL.IsEquPart
							END
						) AS IsWOMSEquPart,
						(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
						(CASE 
							WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
							THEN 
								CASE 
								WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
								THEN 0
								ELSE MSTL.EquPartMasterPartId
								END
							ELSE MSTL.AltPartMasterPartId
							END)
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = (SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),
						PartQuantityAvailable = (SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),
						PartQuantityReserved = (SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						PartQuantityTurnIn = (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
										JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										),
						PartQuantityOnOrder = (SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = (SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QuantityReserved = (SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QunatityRemaining = (WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)),
						QunatityPicked = (SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND wopt.WorkorderId = WOM.WorkOrderId),
						
						MSTL.QtyReserved AS StocklineQtyReserved,
						ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
						MSTL.QtyIssued AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						--CASE WHEN ISNULL(MSTL_PO.WOMStockLineId,0)=0 THEN WOM.PONextDlvrDate
						--ELSE (CASE WHEN MSTL_PO.QuantityTurnIn > 0 THEN WOM.PONextDlvrDate ELSE SL.ReceivedDate  END)
						--END AS PONextDlvrDate,
						WOM.PONextDlvrDate,
						WOM.POId,
						WOM.Quantity,
						MSTL.Quantity AS StocklineQuantity,
						(WOM.QtyToTurnIn - ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)) AS PartQtyToTurnIn,
						CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
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
						--UOM.ShortName AS UOM,
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
						CASE WHEN SWO.StockLineId IS NULL THEN 0 ELSE  SWO.StockLineId END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						--Employeename =(SELECT TOP 1 (em.FirstName +' '+ em.LastName) FROM dbo.WorkOrder wo WITH (NOLOCK) JOIN dbo.Employee em WITH (NOLOCK) on  em.EmployeeId = wo.EmployeeId where wo.WorkOrderId=WOM.WorkOrderId ),
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,MSTL.Figure StockLineFigure
						,MSTL.Item StockLineItem
						,SL.StockLineId
						,0 AS IsKitType
						,0 AS KitQty
						,WOM.ExpectedSerialNumber AS ExpectedSerialNumber
						,(CASE WHEN P.Description = @exchangeProvision  AND (SELECT count(1) FROM dbo.Stockline stk WITH(NOLOCK) WHERE stk.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId)>0 THEN 1 ELSE 0 END)  AS IsExchangeTender
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @WFWOId
					AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)

					UNION ALL

					SELECT DISTINCT IM.PartNumber,
						IM.PartDescription,
						IMS.PartNumber StocklinePartNumber,
						IMS.PartDescription StocklinePartDescription,
						WOMKM.KitNumber AS KitNumber,
						(SELECT KM.KitDescription FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitDescription,
						(SELECT KM.KitCost FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitCost,
						0 as WOQMaterialKitMappingId,
						WOMKM.KitId AS KitId,
						IM.ItemGroup,
						IM.ManufacturerName,
						SL.WorkOrderNumber,
						SWO.SubWorkOrderNo,
						WOM.WorkOrderId,
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
						Stk_C.Description AS StocklineCondition,
						WOM.UnitCost,
						IMPS.PP_UnitPurchasePrice AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						MSTL.UnitCost StocklineUnitCost,
						MSTL.ExtendedCost StocklineExtendedCost,
						MSTL.StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
							WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
							THEN 0
							ELSE MSTL.IsAltPart 
							END
						) AS IsWOMSAltPart,
						(CASE 
							WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
							THEN 0 
							ELSE MSTL.IsEquPart
							END
						) AS IsWOMSEquPart,
						(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
						(CASE 
							WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
							THEN 
								CASE 
								WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
								THEN 0
								ELSE MSTL.EquPartMasterPartId
								END
							ELSE MSTL.AltPartMasterPartId
							END)
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = (SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),
						PartQuantityAvailable = (SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),
						PartQuantityReserved = (SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						PartQuantityTurnIn = (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
										JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										),
						PartQuantityOnOrder = (SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = (SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QuantityReserved = (SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QunatityRemaining = (WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)),
						QunatityPicked = (SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND wopt.WorkorderId = WOM.WorkOrderId),
						
						MSTL.QtyReserved AS StocklineQtyReserved,
						ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
						MSTL.QtyIssued AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						--CASE WHEN ISNULL(MSTL_PO.WorkOrderMaterialStockLineKitId,0)=0 THEN WOM.PONextDlvrDate
						--ELSE (CASE WHEN MSTL_PO.QuantityTurnIn > 0 THEN WOM.PONextDlvrDate ELSE SL.ReceivedDate  END)
						--END AS PONextDlvrDate,
						WOM.PONextDlvrDate,
						WOM.POId,
						WOM.Quantity,
						MSTL.Quantity AS StocklineQuantity,
						(WOM.QtyToTurnIn - ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)) AS PartQtyToTurnIn,
						CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
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
						--UOM.ShortName AS UOM,
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
						CASE WHEN SWO.StockLineId IS NULL THEN 0 ELSE  SWO.StockLineId END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						--Employeename =(SELECT TOP 1 (em.FirstName +' '+ em.LastName) FROM dbo.WorkOrder wo WITH (NOLOCK) JOIN dbo.Employee em WITH (NOLOCK) on  em.EmployeeId = wo.EmployeeId where wo.WorkOrderId=WOM.WorkOrderId ),
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Figure else MSTL.Figure end as StockLineFigure
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Item else MSTL.Item end StockLineItem
						,SL.StockLineId
						,1 AS IsKitType
						,(SELECT SUM(ISNULL(WOMK.Quantity, 0)) FROM dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId) AS KitQty
						,'' AS ExpectedSerialNumber
						,0  AS IsExchangeTender
						FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN [dbo].[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) ON WOMKM.WOPartNoId = WOWF.WorkOrderPartNoId AND WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @WFWOId
						AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)
					--AND (MSTL.Quantity - (SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
					--						WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0) > 0);
				END
				ELSE
				BEGIN
					SELECT DISTINCT IM.PartNumber,
						IM.PartDescription,
						IMS.PartNumber StocklinePartNumber,
						IMS.PartDescription StocklinePartDescription,
						'' AS KitNumber,
						'' AS KitDescription,
						0 AS KitCost,
						0 as WOQMaterialKitMappingId,
						0 AS KitId,
						IM.ItemGroup,
						IM.ManufacturerName,
						SL.WorkOrderNumber,
						SWO.SubWorkOrderNo,
						WOM.WorkOrderId,
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
						Stk_C.Description AS StocklineCondition,
						WOM.UnitCost,
						IMPS.PP_UnitPurchasePrice AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						MSTL.UnitCost StocklineUnitCost,
						MSTL.ExtendedCost StocklineExtendedCost,
						MSTL.StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
							WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
							THEN 0
							ELSE MSTL.IsAltPart 
							END
						) AS IsWOMSAltPart,
						(CASE 
							WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
							THEN 0 
							ELSE MSTL.IsEquPart
							END
						) AS IsWOMSEquPart,
						(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
						(CASE 
							WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
							THEN 
								CASE 
								WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
								THEN 0
								ELSE MSTL.EquPartMasterPartId
								END
							ELSE MSTL.AltPartMasterPartId
							END)
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = (SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),
						PartQuantityAvailable = (SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),
						PartQuantityReserved = (SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						PartQuantityTurnIn = (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
										JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										),
						PartQuantityOnOrder = (SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = (SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QuantityReserved = (SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QunatityRemaining = (WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)),
						QunatityPicked = (SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND wopt.WorkorderId = WOM.WorkOrderId),
						
						MSTL.QtyReserved AS StocklineQtyReserved,
						ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
						MSTL.QtyIssued AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						WOM.PONextDlvrDate,
						SL.ReceivedDate,
						WOM.POId,
						WOM.Quantity,
						MSTL.Quantity AS StocklineQuantity,
						(WOM.QtyToTurnIn - ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)) AS PartQtyToTurnIn,
						CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
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
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
						CASE WHEN SWO.StockLineId IS NULL THEN 0 ELSE  SWO.StockLineId END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,MSTL.Figure StockLineFigure
						,MSTL.Item StockLineItem
						,SL.StockLineId
						,0 AS IsKitType
						,0 AS KitQty
						,WOM.ExpectedSerialNumber AS ExpectedSerialNumber
						,(CASE WHEN P.Description = @exchangeProvision  AND (SELECT count(1) FROM dbo.Stockline stk WITH(NOLOCK) WHERE stk.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId)>0 THEN 1 ELSE 0 END)  AS IsExchangeTender
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = MSTL.ConditionId -- DO Not Modify this 
						--LEFT JOIN dbo.Stockline SL_PO WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId --SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @WFWOId

					UNION ALL

					SELECT DISTINCT IM.PartNumber,
						IM.PartDescription,
						IMS.PartNumber StocklinePartNumber,
						IMS.PartDescription StocklinePartDescription,
						WOMKM.KitNumber AS KitNumber,
						(SELECT KM.KitDescription FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitDescription,
						(SELECT KM.KitCost FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitCost,
						0 as WOQMaterialKitMappingId,
						WOMKM.KitId AS KitId,
						IM.ItemGroup,
						IM.ManufacturerName,
						SL.WorkOrderNumber,
						SWO.SubWorkOrderNo,
						WOM.WorkOrderId,
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
						Stk_C.Description AS StocklineCondition,
						WOM.UnitCost,
						IMPS.PP_UnitPurchasePrice AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						MSTL.UnitCost StocklineUnitCost,
						MSTL.ExtendedCost StocklineExtendedCost,
						MSTL.StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
							WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
							THEN 0
							ELSE MSTL.IsAltPart 
							END
						) AS IsWOMSAltPart,
						(CASE 
							WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
							THEN 0 
							ELSE MSTL.IsEquPart
							END
						) AS IsWOMSEquPart,
						(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
						(CASE 
							WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
							THEN 
								CASE 
								WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
								THEN 0
								ELSE MSTL.EquPartMasterPartId
								END
							ELSE MSTL.AltPartMasterPartId
							END)
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = (SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),
						PartQuantityAvailable = (SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),
						PartQuantityReserved = (SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						PartQuantityTurnIn = (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
										JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										),
						PartQuantityOnOrder = (SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = (SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QuantityReserved = (SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),
						QunatityRemaining = (WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
											JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0
											), 0)),
						QunatityPicked = (SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND wopt.WorkorderId = WOM.WorkOrderId),
						
						MSTL.QtyReserved AS StocklineQtyReserved,
						ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
						MSTL.QtyIssued AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						WOM.PONextDlvrDate,
						SL.ReceivedDate,
						WOM.POId,
						WOM.Quantity,
						MSTL.Quantity AS StocklineQuantity,
						(WOM.QtyToTurnIn - ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)) AS PartQtyToTurnIn,
						CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
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
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 1 END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE  SWO.SubWorkOrderId END AS SubWorkOrderId,
						CASE WHEN SWO.StockLineId IS NULL THEN 0 ELSE  SWO.StockLineId END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Figure else MSTL.Figure end as StockLineFigure
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Item else MSTL.Item end StockLineItem
						,SL.StockLineId
						,1 AS IsKitType
						,(SELECT SUM(ISNULL(WOMK.Quantity, 0)) FROM dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId) AS KitQty
						,'' AS ExpectedSerialNumber
						,0  AS IsExchangeTender
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId -- DO Not Modify this 
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = MSTL.ConditionId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN [dbo].[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) ON WOMKM.WOPartNoId = WOWF.WorkOrderPartNoId AND WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @WFWOId;
				END

				IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpStockline
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMStockline
				END

				IF OBJECT_ID(N'tempdb..#tmpStocklineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpStocklineKit
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWOMStocklineKit
				END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				PRINT 'HI'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderMaterialsList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@WFWOId ,'') +''
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