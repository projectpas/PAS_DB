

/*************************************************************           
 ** File:   [USP_Lot_GetAllLotViewsByLotId]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to Get all the views of LOT(All PN, PN IN Stock,PN SOLD, PN REPAIRED etc...
 ** Purpose:         
 ** Date:   15/04/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/04/2023  Rajesh Gami   Created
     
-- EXEC USP_Lot_GetAllLotViewsByLotId 7,'ViewAllPN',1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetAllLotViewsByLotId]
@LotId bigint, 
@Type VARCHAR(50) = '',
@MasterCompanyId int
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN		
			DECLARE @LOT_PO_Type VARCHAR(100) = 'PO'; DECLARE @LOT_RO_Type VARCHAR(100)= 'RO'; DECLARE @LOT_SO_Type VARCHAR(100)= 'SO';	DECLARE @LOT_WO_Type VARCHAR(100)= 'WO';
			DECLARE @LOT_TransIn_LOT VARCHAR(100) = 'Trans In(Lot)'; DECLARE @LOT_TransIn_PO VARCHAR(100) = 'Trans In(PO)';	DECLARE @LOT_TransIn_RO VARCHAR(100) = 'Trans In(RO)';
			DECLARE @LOT_TransIn_SO VARCHAR(100) = 'Trans In(SO)'; DECLARE @LOT_TransIn_WO VARCHAR(100) = 'Trans In(WO)'; DECLARE @LOT_TransOut_LOT VARCHAR(100) = 'Trans Out(Lot)';
			DECLARE @LOT_TransOut_PO VARCHAR(100) = 'Trans Out(PO)'; DECLARE @LOT_TransOut_RO VARCHAR(100) = 'Trans Out(RO)';
			DECLARE @LOT_TransOut_SO VARCHAR(100) = 'Trans Out(SO)'; DECLARE @LOT_TransOut_WO VARCHAR(100) = 'Trans Out(WO)'; 
			DECLARE @LotTransIn VARCHAR(100) = 'Trans In', @LotPO VARCHAR(100) = 'Purchase Order',@LotRO VARCHAR(100) = 'Repair Order',@LotSO VARCHAR(100) = 'Sales Order', @LotWO VARCHAR(100) = 'Work Order';
			DECLARE @AppModuleId INT = 0;
			SELECT @AppModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Lot';
				DECLARE @AppModuleCustomerId INT = 0;
				DECLARE @AppModuleVendorId INT = 0;
				DECLARE @AppModuleCompanyId INT = 0;
				DECLARE @AppModuleOthersId INT = 0;
				SELECT @AppModuleCustomerId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer';
				SELECT @AppModuleVendorId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor';
				SELECT @AppModuleCompanyId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Company';
				SELECT @AppModuleOthersId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Others';
			IF(UPPER(@Type) = UPPER('ViewAllPN'))
			BEGIN
				SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(ro.RepairOrderId,0) RepairOrderId
				,ISNULL(wo.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,UPPER(sl.UnitOfMeasure) AS Uom
				,(CASE WHEN UPPER(ltCal.Type) = UPPER(@LOT_TransOut_SO) THEN 'SOLD' ELSE UPPER(ltCal.Type) END) Status
				--,(CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) Qty
				,ltCal.Qty AS Qty
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				--,ISNULL(ltCal.TransferredInCost,0.00) TransUnitCost
				,(CASE  WHEN ltCal.Type = @LOT_TransOut_SO OR ltCal.Type = @LOT_TransOut_LOT OR  ltCal.Type = @LOT_TransOut_RO THEN ltCal.TransferredOutCost ELSE ltCal.TransferredInCost END) TransUnitCost
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) UnitCost
				,(ISNULL(sl.PurchaseOrderUnitCost,0) * ltCal.Qty) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				--,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END))) TotalCost
				,ltCal.SalesUnitPrice UnitSalesPrice
				,ltCal.ExtSalesUnitPrice ExtPrice
				,ltCal.MarginAmount MarginAmt
				,ltCal.Margin Margin
				--,(ISNULL(sl.UnitCost,0) * (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) ExtPrice
				--,(( (ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END))) * ISNULL(per.PercentValue,0) ) /100) AS MarginAmt
				--,ISNULL(per.PercentValue,0) Margin
				,(CASE WHEN ltCal.Type = @LOT_TransIn_LOT OR ltCal.Type = @LOT_TransOut_LOT THEN @LotTransIn 
					   WHEN ltCal.Type = @LOT_TransIn_PO THEN @LotPO
					   WHEN ltCal.Type = @LOT_TransIn_RO OR ltCal.Type = @LOT_TransOut_RO THEN @LotRO 
					   WHEN ltCal.Type = @LOT_TransOut_SO THEN @LotSO 
					   WHEN ltCal.Type = @LOT_TransIn_WO THEN @LotWO 
				ELSE '' END) HowAcquired
				,(CASE WHEN ltCal.Type = @LOT_TransIn_LOT OR ltCal.Type = @LOT_TransOut_LOT THEN sl.StockLineNumber 
					   WHEN ltCal.Type = @LOT_TransIn_PO THEN po.PurchaseOrderNumber
					   WHEN ltCal.Type = @LOT_TransIn_RO OR ltCal.Type = @LOT_TransOut_RO THEN ro.RepairOrderNumber 
					   WHEN ltCal.Type = @LOT_TransOut_SO THEN so.SalesOrderNumber 
					   WHEN ltCal.Type = @LOT_TransIn_WO THEN wo.WorkOrderNum 
				ELSE '' END) AS AcquiredRef
				,po.PurchaseOrderNumber PoNum
				,ro.RepairOrderNumber RoNum
				,wo.WorkOrderNum WoNum
				,''  QuoteNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor 
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,lot.ReferenceNumber ReferenceNum
				,sl.CustomerName
				,'' Co
				,'' Bu
				,'' Div
				,'' Dept
				,sl.Memo
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,ltin.CreatedDate
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				--,sl.TraceableToName
				--,sl.TaggedByName
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,0 Adjustment
				,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN CU.[Name] 
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN VE.[VendorName]
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN CO.[Name]	
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName] 
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 Inner JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(ltCal.Type) = UPPER(@LOT_TransOut_SO)
					 LEFT JOIN DBO.SalesOrderPart sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId

					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.UnitOfMeasure uom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					 LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId 
					 LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId 
					 LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) ON sl.WorkOrderId = wo.WorkOrderId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	

					 LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CUT.[CustomerId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VET.[VendorId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CTT.[LegalEntityId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = SL.[TaggedBy]

				WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId
				ORDER BY ltin.CreatedDate DESC
			END
			ELSE IF(UPPER(@Type) = UPPER('PNInStockView'))
			BEGIN
				SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(ro.RepairOrderId,0) RepairOrderId
				,ISNULL(wo.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				--,(CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) Qty
					,ltCal.Qty AS Qty
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) UnitCost
				,(ISNULL(sl.UnitCost,0) * ltCal.Qty) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				--,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END))) TotalCost
				,ro.RepairOrderNumber RoNum
				,''  WoNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,im.ManufacturerName
				,sl.itemType
				,UPPER(sl.UnitOfMeasure) AS Uom		
				,per.PercentValue
							,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN CU.[Name] 
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN VE.[VendorName]
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN CO.[Name]	
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName] 
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,0 Adjustment
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(ltCal.Type) = UPPER(@LOT_TransOut_SO)
					 LEFT JOIN DBO.SalesOrderPart sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId

					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId 
					 LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId 
					 LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) ON sl.WorkOrderId = wo.WorkOrderId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
					 	 LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CUT.[CustomerId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VET.[VendorId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CTT.[LegalEntityId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = SL.[TaggedBy]
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId AND ISNULL(sl.QuantityOnHand,0) > 0 AND (UPPER(ltCal.Type) NOT IN (UPPER(@LOT_TransOut_SO), UPPER(@LOT_TransOut_RO),UPPER(@LOT_TransOut_LOT)))
				 ORDER BY ltin.CreatedDate DESC
			END
			ELSE IF(UPPER(@Type) = UPPER('PNSoldView'))
			BEGIN
				SELECT
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(ro.RepairOrderId,0) RepairOrderId
				,ISNULL(wo.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,'SOLD' AS Status
				,So.CustomerName
				,sobi.InvoiceDate
				--,(CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) Qty
				,ltCal.Qty Qty
				,ltCal.SalesUnitPrice UnitPrice
				,ltCal.ExtSalesUnitPrice ExtendedPrice
				--,ISNULL(sl.PurchaseOrderUnitCost,0.00) AS UnitPrice
				--,((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(SL.PurchaseOrderUnitCost,0.00)) AS ExtendedPrice
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,(CASE WHEN ISNULL(ltcal.Qty,0) > 0 THEN ISNULL(ltcal.cogs,0.00)/ ltCal.Qty ELSE 0 END) AS Cost
				--,(ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) ExtCost
				,(ISNULL(ltcal.cogs,0)) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,(ISNULL(ltcal.cogs,0.00) + ISNULL(sl.RepairOrderUnitCost,0)) TotalDirectCost
				,ltCal.MarginAmount MarginAmt
				,ltCal.Margin Margin
				--,CASE WHEN (((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.UnitCost,0.00)) - ((ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) + ISNULL(sl.RepairOrderUnitCost,0))) < 0 THEN 0 ELSE (((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.UnitCost,0.00)) - (((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.PurchaseOrderUnitCost,0)) + ISNULL(sl.RepairOrderUnitCost,0))) END  MarginAmt
				--,CAST((CASE WHEN ((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.UnitCost,0.00)) = 0 THEN 0 ELSE ((CASE WHEN (((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.UnitCost,0.00)) - ((ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) + ISNULL(sl.RepairOrderUnitCost,0))) < 0 OR (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) <=0 THEN 0 ELSE (((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.UnitCost,0.00)) - ((ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) + ISNULL(sl.RepairOrderUnitCost,0))) END) / ((CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) * ISNULL(sl.UnitCost,0.00))) * 100.00 END) as Decimal(10,2)) Margin
				,ro.RepairOrderNumber RoNum
				,''  WoNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
							,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN CU.[Name] 
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN VE.[VendorName]
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN CO.[Name]	
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName] 
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,0 Adjustment
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 INNER JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(ltCal.Type) = UPPER(@LOT_TransOut_SO)
					 INNER JOIN DBO.SalesOrderPart sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId 
					 LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId 
					 LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) ON sl.WorkOrderId = wo.WorkOrderId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
					 	 LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CUT.[CustomerId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VET.[VendorId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CTT.[LegalEntityId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = SL.[TaggedBy]
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId AND UPPER(ltCal.Type) = UPPER(@LOT_TransOut_SO)
				 ORDER BY ltin.CreatedDate DESC
			END
			ELSE IF(UPPER(@Type) = UPPER('RepairedView'))
			BEGIN
				SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(ro.RepairOrderId,0) RepairOrderId
				,ISNULL(wo.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,UPPER(sl.UnitOfMeasure) AS Uom
				,ltCal.Qty Qty
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) AS UnitPrice
				--,(ISNULL(sl.UnitCost,0) * (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) AS ExtendedPrice
				,(ISNULL(sl.UnitCost,0) * ltCal.Qty) AS ExtendedPrice
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) Cost
				--,(ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) ExtCost
				,(ISNULL(sl.PurchaseOrderUnitCost,0)* ltCal.Qty) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				--,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(sl.PurchaseOrderUnitCost,0))) TotalCost
				,ro.RepairOrderNumber RoNum
				,wo.WorkOrderNum WoNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
							,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN CU.[Name] 
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN VE.[VendorName]
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN CO.[Name]	
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName] 
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,0 Adjustment
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(ltCal.Type) = UPPER(@LOT_TransOut_SO)
					 LEFT JOIN DBO.SalesOrderPart sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.UnitOfMeasure uom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					 LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId 
					 LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId 
					 LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) ON sl.WorkOrderId = wo.WorkOrderId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
					 	 LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CUT.[CustomerId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VET.[VendorId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CTT.[LegalEntityId] = SL.[TraceableTo]
					 LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = SL.[TaggedBy]
					 LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = SL.[TaggedBy]
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId AND (UPPER(ltCal.Type) = UPPER(@LOT_TransIn_RO))
				 ORDER BY ltin.CreatedDate DESC
			END
			ELSE IF(UPPER(@Type) = UPPER('OtherCost'))
			BEGIN
			;WITH Lot_CTE AS(
				SELECT
				 lot.LotId
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId
				--,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				--,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				--,sl.StockLineId
				--,sl.SerialNumber AS SerialNum
				--,sl.StockLineNumber StkLineNum
				--,c.Description AS Condition
				--,UPPER(sl.UnitOfMeasure) AS Uom
				--,(CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END) Qty
				--,ltCal.Qty
				--,ISNULL(sl.UnitCost,0.00) AS UnitPrice
				--,(ltCal.Qty * ISNULL(sl.UnitCost,0.00)) AS ExtendedPrice
				--,ISNULL(sl.UnitCost,0.00) Cost
				--,(ISNULL(sl.UnitCost,0)* ltCal.Qty) ExtCost
				--,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				--,ISNULL(sl.UnitCost,0) TotalCost
				--,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(sl.PurchaseOrderUnitCost,0))) TotalCost
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'') VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				--,UPPER(MSD.LastMSLevel)	LastMSLevel
				--,UPPER(MSD.AllMSlevels) AllMSlevels
				--,ISNULL(po.TotalFreight,0) AS FreightCost
				--,ISNULL(po.TotalCharges,0) AS ChargesCost
				,ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.PurchaseOrderFreight PF WITH(NOLOCK) WHERE PF.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) AS FreightCost
				,ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.PurchaseOrderCharges PC WITH(NOLOCK) WHERE PC.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) AS ChargesCost
				,Po.CreatedDate AS PoDate
				,po.PurchaseOrderNumber AS PoNum
				--,sl.ConditionId
				--,sl.ItemMasterId
				--,sl.CustomerId
				--,sl.ControlNumber
				--,sl.IdNumber
				,part.PartNumber
				,part.PartDescription
				,part.Condition
				,part.Manufacturer
				FROM DBO.PurchaseOrder po WITH(NOLOCK)
					 INNER JOIN DBO.LOT lot WITH(NOLOCK) on po.LotId = lot.LotId
					 INNER JOIN PurchaseOrderPart part WITH(NOLOCK) on part.PurchaseOrderId = po.PurchaseOrderId
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId AND ltCal.ReferenceId = po.PurchaseOrderId AND ltCal.ChildId = part.PurchaseOrderPartRecordId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.UnitOfMeasure uom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON po.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId 
					   AND (ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.PurchaseOrderFreight PF WITH(NOLOCK) WHERE PF.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) > 0 
							OR ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.PurchaseOrderCharges PC WITH(NOLOCK) WHERE PC.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) >0)
				 )

				 Select * from Lot_CTE Group by LotId,PurchaseOrderId,Vendor,VendorCode,VendorId,FreightCost,ChargesCost,PoDate,PoNum,PartNumber,PartDescription,Condition,Manufacturer ORDER BY PoDate DESC
			END
		END
	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
		    SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Lot_GetAllLotViewsByLotId' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LotId, '') + ''',
														@Parameter2 = ' + ISNULL(@Type,'') + ', 
														@Parameter3 = ' + ISNULL(@MasterCompanyId,'') + ''
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