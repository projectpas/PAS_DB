/*************************************************************             
 ** File:   [usp_PostReceivingReconcilationBatchDetails]             
 ** Author:   
 ** Description: This stored procedure is used to get Reconsilation Stockline data
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    30/05/2023   Satish Gohil   CREATED
	2    06/11/2023   Moin Bloch     Modify (Added Control Number)
	3    08/11/2023   Moin Bloch     Modify (Added Group By)
	4    09/07/2024   Moin Bloch     Modify (changed UnitCost Field From Part to stockline)
	5    17/07/2024   AMIT GHEDIYA   Modify (changed UnitCost Field From stockline to Part for RO)
	6    03/12/2024   Moin Bloch     Modify (Added isSerialized Field)
	7	 23/12/2024	  Abhishek Jirawla	Switching between Po view and PN view
	8	 01/01/2025	  Devendra Shekh	getting NonStockInventory where RRQty > 0
	9	 01/01/2025   RAJESH GAMI	Return the vendorProformaInvoiceNo and Deposit amount from the PO-RO
    10   06/01/2025   Moin Bloch     Modify (removed duplicate asset inventory list)
	11   08/01/2025   Moin Bloch     Modify (removed duplicate asset inventory list for RO)
	12   16/02/2025   Moin Bloch     Modify (Above 200 Qty We are not storing StocklineId in StocklineDraft So not able to get above 200Qty Record in Receiving Reconciliation) PN-15483
	13   23-Feb-2025  Rajesh Gami	 Resolved Getting records issue
	14   19/06/2026   Abhishek Jirawla	Adding IsPiecePart condition in RepairOrderPart table 
	15	 26/06/2026   Priyansh Patel  Uom conversion [PN-16939]
	16   01/07/2026   Priyansh Patel  Stock to pirchase conversion for purchase Order  [PN-16941]
	17   09/July/2026   RAJESH GAMI	[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	18   21/July/2026   RAJESH GAMI	[PN-17271] - Remove IsNonStock = 0 condition for the PurchaseOrder as we have to allow both 
	19   20/July/2026   RAJESH GAMI	[PN-17271] - Remove IsNonStock = 0 condition from all 4 Repair Order (RO) branches (mirroring the PO branches' fix above) so Non-Stock RO stocklines are returned too, not just Stock. Left the legacy NonStockInventory PO branches untouched (unreachable/inert dead code post-merge, safer to leave as-is for now).
	20   20/July/2026   RAJESH GAMI	[PN-17350] - Removed the 4 dead PO Non-Stock UNION branches (dbo.NonStockInventory/NonStockInventoryDraft) from the not-Multiple and Multiple Type=1 sections; the adjacent PO Stock branches already return non-stock rows unfiltered post PN-17271, making these branches unreachable duplicates.
	21   22/07/2026   Priyansh Patel   Added StockUnitOfMeasure property [PN-16941]
	22   06/08/2026   Priyansh Patel   Replace the StockLineDraft quantity with Stockline quantity [PN-16941]

	EXEC GetReceivingReconciliationPoData 2598,'Multiple',1
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetReceivingReconciliationPoData]
@PurchaseOrderId bigint,
@PurchaseOrderPartRecordId VARCHAR(50),
@Type int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF (@PurchaseOrderPartRecordId <> 'Multiple')
		BEGIN
			IF(@Type = 1)
			BEGIN
				SELECT stk.StockLineNumber,
				stk.ControlNumber,
				stk.StockLineId,
				CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
				pop.ItemMasterId,
				pop.PartNumber,
				pop.PartDescription,
				stk.SerialNumber,
				po.PurchaseOrderId,
				po.PurchaseOrderNumber AS 'POReference',
				pop.UnitOfMeasure AS 'UnitOfMeasure',
				stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
				pop.QuantityOrdered AS 'POQtyOrder',
				SUM(ISNULL(CV.ConvertedQty,0)) AS 'ReceivedQty',
				pop.UnitCost AS 'POUnitCost',
				(pop.UnitCost * MAX(CV.ConvertedRRQty)) AS 'POExtCost',
				MAX(CV.ConvertedRRQty) AS 'InvoicedQty',
				MAX(CV.ConvertedUnitCost) AS 'InvoicedUnitCost',
				(MAX(CV.ConvertedUnitCost) * MAX(CV.ConvertedRRQty)) AS 'InvoicedExtCost',
				MAX(CV.ConvertedRRQty) AS 'RemainingRRQty',
				pop.PurchaseOrderPartRecordId,
				1 AS 'Type',
				'STOCK' AS 'StockType',
				ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
				po.vendorProformaInvoiceNo AS vendorProformaInvoiceNo,
				ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
				INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
				CROSS APPLY (
				SELECT IsSameUOM     = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN 1 ELSE 0 END,
				ConvertedQty    = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure
				THEN stk.Quantity
				ELSE dbo.fn_ConvertUOM(stk.Quantity, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 0, po.MasterCompanyId)
				END,
				ConvertedRRQty  = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure
				THEN stk.RRQty
				ELSE dbo.fn_ConvertUOM(stk.RRQty, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 0, po.MasterCompanyId)
				END,
				ConvertedUnitCost = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure
					THEN stk.UnitCost
					ELSE dbo.fn_ConvertUOM(stk.UnitCost, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 1, po.MasterCompanyId)
				END
				) CV
				WHERE po.PurchaseOrderId = @PurchaseOrderId
					AND pop.PurchaseOrderPartRecordId = CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) FROM dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0 AND ISNULL(stk.IsNonStock,0) = 0
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered, pop.UnitCost,stk.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId,pop.UnitOfMeasure,stk.StockUnitOfMeasure,po.MasterCompanyId

				UNION ALL

				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.PurchaseOrderId,
					po.PurchaseOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stk.RRQty) AS 'POExtCost',
					stk.RRQty AS 'InvoicedQty',
					stk.UnitCost AS 'InvoicedUnitCost',
					(stk.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.PurchaseOrderPartRecordId,
					1 as 'Type','STOCK' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
					INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT)
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
				WHERE po.PurchaseOrderId = @PurchaseOrderId
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId,pop.UnitOfMeasure,stk.StockUnitOfMeasure 
				UNION
			
				SELECT stk.InventoryNumber AS 'StockLineNumber',
					stk.ControlNumber, 
					stk.AssetInventoryId AS 'StockLineId',
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNo AS 'SerialNumber',
					po.PurchaseOrderId,
					po.PurchaseOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure' ,
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					stkdf.Qty AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
					stkdf.Qty AS 'InvoicedQty',
					stk.UnitCost AS 'InvoicedUnitCost',
					(stk.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.PurchaseOrderPartRecordId,
					1 AS 'Type',
					'ASSET' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
					INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
					INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId --and stk.IsParent=1 --AND stk.RRQty > 0 -- AND  
					INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				WHERE po.PurchaseOrderId = @PurchaseOrderId 
					AND pop.PurchaseOrderPartRecordId=CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0
			
				UNION ALL
			
				SELECT stk.InventoryNumber AS 'StockLineNumber',
					stk.ControlNumber, 
					stk.AssetInventoryId AS 'StockLineId',
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNo AS 'SerialNumber',
					po.PurchaseOrderId,
					po.PurchaseOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					stkdf.Qty AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
					stkdf.Qty AS 'InvoicedQty',
					stk.UnitCost AS 'InvoicedUnitCost',
					(stk.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.PurchaseOrderPartRecordId,
					1 AS 'Type',
					'ASSET' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
					INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT)
					INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId --and stk.IsParent=1 --AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
					INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				WHERE po.PurchaseOrderId = @PurchaseOrderId
			END
			ELSE
			BEGIN
				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure' ,
					stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					--stkdf.QuantityOnHand AS 'ReceivedQty',
					SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stk.RRQty) AS 'POExtCost',
					stk.RRQty AS 'InvoicedQty',
					stk.RepairOrderUnitCost AS 'InvoicedUnitCost',
					(stk.RepairOrderUnitCost * stk.RRQty) AS 'InvoicedExtCost',
					(stk.RRQty)as 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'STOCK' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND ISNULL(POP.[IsPiecePart], 0) = 0
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
				WHERE po.RepairOrderId = @PurchaseOrderId 
					AND pop.RepairOrderPartRecordId = CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					AND ISNULL((SELECT COUNT(POS.RepairOrderPartRecordId) FROM dbo.RepairOrderPart POS WITH(NOLOCK) WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0			
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.RepairOrderId,po.RepairOrderNumber,pop.QuantityOrdered,stk.RepairOrderUnitCost,pop.UnitCost,stk.RRQty,pop.RepairOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId,pop.UnitOfMeasure,stk.StockUnitOfMeasure

				UNION ALL
			
				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure' ,
					stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					--stkdf.QuantityOnHand AS 'ReceivedQty',
					SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stk.RRQty) AS 'POExtCost',
					stk.RRQty AS 'InvoicedQty',
					stk.RepairOrderUnitCost AS 'InvoicedUnitCost',
					(stk.RepairOrderUnitCost * stk.RRQty) AS 'InvoicedExtCost',
					(stk.RRQty)as 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'STOCK' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) AND ISNULL(POP.[IsPiecePart], 0) = 0
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
				WHERE po.RepairOrderId = @PurchaseOrderId
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.RepairOrderId,po.RepairOrderNumber,pop.QuantityOrdered,stk.RepairOrderUnitCost,pop.UnitCost,stk.RRQty,pop.RepairOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId,pop.UnitOfMeasure,stk.StockUnitOfMeasure
					 				
				UNION
				
				SELECT stk.InventoryNumber AS 'StockLineNumber',
					stk.ControlNumber,
					stk.AssetInventoryId AS 'StockLineId',
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNo AS 'SerialNumber',
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					stkdf.Qty AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
					stkdf.Qty AS 'InvoicedQty',
					pop.UnitCost AS 'InvoicedUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'ASSET' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND ISNULL(POP.[IsPiecePart], 0) = 0
					INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId --and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
					INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				where po.RepairOrderId = @PurchaseOrderId 
					AND pop.RepairOrderPartRecordId=CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					AND ISNULL((SELECT COUNT(POS.RepairOrderPartRecordId) from dbo.RepairOrderPart POS  WITH(NOLOCK) 
				WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0
				
				UNION ALL
				
				SELECT stk.InventoryNumber AS 'StockLineNumber',
					stk.ControlNumber,
					stk.AssetInventoryId AS 'StockLineId',
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNo AS 'SerialNumber',
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					stkdf.Qty AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
					stkdf.Qty AS 'InvoicedQty',
					pop.UnitCost AS 'InvoicedUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'ASSET' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) AND ISNULL(POP.[IsPiecePart], 0) = 0
					INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId --and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
					INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				WHERE po.RepairOrderId = @PurchaseOrderId

			END
		END
		ELSE
		BEGIN
			IF(@Type = 1)
			BEGIN
				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.PurchaseOrderId,
					po.PurchaseOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					SUM(ISNULL(cv.ConvertedQty,0)) AS ReceivedQty,
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * SUM(ISNULL(cv.ConvertedRRQty,0))) AS 'POExtCost',
					SUM(ISNULL(cv.ConvertedRRQty,0))  AS 'InvoicedQty',
					MAX(cv.ConvertedUnitCost) AS 'InvoicedUnitCost',
					(stk.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
					SUM(ISNULL(cv.ConvertedRRQty,0))   AS 'RemainingRRQty',
					pop.PurchaseOrderPartRecordId,
					1 AS 'Type',
					'STOCK' AS 'StockType' ,
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
					INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
				--	INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
					CROSS APPLY (
					SELECT ConvertedQty = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN stk.QuantityOnHand
					ELSE dbo.fn_ConvertUOM(stk.QuantityOnHand, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 0, po.MasterCompanyId) END,
					ConvertedRRQty = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN stk.RRQty
					ELSE dbo.fn_ConvertUOM(stk.RRQty, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 0, po.MasterCompanyId) END,
					ConvertedUnitCost = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN stk.UnitCost
					ELSE dbo.fn_ConvertUOM(stk.UnitCost, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 1, po.MasterCompanyId)
					END
					) cv

				WHERE po.PurchaseOrderId = @PurchaseOrderId
					--AND pop.PurchaseOrderPartRecordId = CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					--AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) FROM dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered, pop.UnitCost,stk.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId ,pop.UnitOfMeasure, stk.StockUnitOfMeasure,po.MasterCompanyId
					 
				UNION ALL

				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.PurchaseOrderId,
					po.PurchaseOrderNumber AS 'POReference',
					--pop.UnitOfMeasure AS 'PurchaseUnitOfMeasure',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					--stkdf.QuantityOnHand AS 'ReceivedQty',
					--SUM(ISNULL(stk.QuantityOnHand,0)) AS 'ReceivedQty',
					SUM(ISNULL(cv.ConvertedQty,0)) AS ReceivedQty,
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * SUM(ISNULL(cv.ConvertedRRQty,0))) AS 'POExtCost',
					SUM(ISNULL(cv.ConvertedRRQty,0))  AS 'InvoicedQty',
					MAX(cv.ConvertedUnitCost) AS 'InvoicedUnitCost',
					(stk.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
					SUM(ISNULL(cv.ConvertedRRQty,0))   AS 'RemainingRRQty',
					pop.PurchaseOrderPartRecordId,
					1 as 'Type','STOCK' AS 'StockType' ,
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
					INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId --AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT)
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					--INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
					CROSS APPLY (
					SELECT ConvertedQty = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN stk.QuantityOnHand
					ELSE dbo.fn_ConvertUOM(stk.QuantityOnHand, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 0, po.MasterCompanyId) END,
					ConvertedRRQty = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN stk.RRQty
					ELSE dbo.fn_ConvertUOM(stk.RRQty, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 0, po.MasterCompanyId) END,
					ConvertedUnitCost = CASE WHEN NULLIF(pop.UnitOfMeasure,'') IS NULL OR NULLIF(stk.StockUnitOfMeasure,'') IS NULL OR pop.UnitOfMeasure = stk.StockUnitOfMeasure THEN stk.UnitCost
					ELSE dbo.fn_ConvertUOM(stk.UnitCost, stk.StockUnitOfMeasure, pop.UnitOfMeasure, 1, po.MasterCompanyId)
					END
					) cv

				WHERE po.PurchaseOrderId = @PurchaseOrderId
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId ,pop.UnitOfMeasure, stk.StockUnitOfMeasure, po.MasterCompanyId

				UNION
			
				SELECT stk.InventoryNumber AS 'StockLineNumber',
					stk.ControlNumber, 
					stk.AssetInventoryId AS 'StockLineId',
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNo AS 'SerialNumber',
					po.PurchaseOrderId,
					po.PurchaseOrderNumber AS 'POReference',
					--pop.UnitOfMeasure AS 'PurchaseUnitOfMeasure',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure', 
					pop.QuantityOrdered AS 'POQtyOrder',
					stkdf.Qty AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
					stkdf.Qty AS 'InvoicedQty',
					stk.UnitCost AS 'InvoicedUnitCost',
					(stk.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.PurchaseOrderPartRecordId,
					1 AS 'Type',
					'ASSET' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.PurchaseOrder po WITH(NOLOCK)
					INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
					INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId --and stk.IsParent=1 --AND stk.RRQty > 0 -- AND  
					INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				WHERE po.PurchaseOrderId = @PurchaseOrderId 
					--AND pop.PurchaseOrderPartRecordId=CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					--AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0
			
				--UNION ALL
			
				--SELECT stk.InventoryNumber AS 'StockLineNumber',
				--	stk.ControlNumber, 
				--	stk.AssetInventoryId AS 'StockLineId',
				--	CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
				--	pop.ItemMasterId,
				--	pop.PartNumber,
				--	pop.PartDescription,
				--	stk.SerialNo AS 'SerialNumber',
				--	po.PurchaseOrderId,
				--	po.PurchaseOrderNumber AS 'POReference',
				--	pop.QuantityOrdered AS 'POQtyOrder',
				--	stkdf.Qty AS 'ReceivedQty',
				--	pop.UnitCost AS 'POUnitCost',
				--	(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
				--	stkdf.Qty AS 'InvoicedQty',
				--	stk.UnitCost AS 'InvoicedUnitCost',
				--	(stk.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
				--	(stk.RRQty) AS 'RemainingRRQty',
				--	pop.PurchaseOrderPartRecordId,
				--	1 AS 'Type',
				--	'ASSET' AS 'StockType' ,
				--	ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
				--	Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
				--	ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				--FROM dbo.PurchaseOrder po WITH(NOLOCK)
				--	INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId --AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT)
				--	INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId --and stk.IsParent=1 --AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				--	INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				--WHERE po.PurchaseOrderId = @PurchaseOrderId
			END
			ELSE
			BEGIN
				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure', 
					pop.QuantityOrdered AS 'POQtyOrder',
					--stkdf.QuantityOnHand AS 'ReceivedQty',
					SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stk.RRQty) AS 'POExtCost',
					stk.RRQty AS 'InvoicedQty',
					stk.RepairOrderUnitCost AS 'InvoicedUnitCost',
					(stk.RepairOrderUnitCost * stk.RRQty) AS 'InvoicedExtCost',
					(stk.RRQty)as 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'STOCK' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND ISNULL(POP.[IsPiecePart], 0) = 0
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
				WHERE po.RepairOrderId = @PurchaseOrderId 
					--AND pop.RepairOrderPartRecordId = CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					--AND ISNULL((SELECT COUNT(POS.RepairOrderPartRecordId) FROM dbo.RepairOrderPart POS WITH(NOLOCK) WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0			
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.RepairOrderId,po.RepairOrderNumber,pop.QuantityOrdered,stk.RepairOrderUnitCost,pop.UnitCost,stk.RRQty,pop.RepairOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId,pop.UnitOfMeasure

				UNION ALL
			
				SELECT stk.StockLineNumber,
					stk.ControlNumber,
					stk.StockLineId,
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNumber,
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					stk.StockUnitOfMeasure AS 'StockUnitOfMeasure',
					pop.QuantityOrdered AS 'POQtyOrder',
					--stkdf.QuantityOnHand AS 'ReceivedQty',
					SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stk.RRQty) AS 'POExtCost',
					stk.RRQty AS 'InvoicedQty',
					stk.RepairOrderUnitCost AS 'InvoicedUnitCost',
					(stk.RepairOrderUnitCost * stk.RRQty) AS 'InvoicedExtCost',
					(stk.RRQty)as 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'STOCK' AS 'StockType' ,
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND ISNULL(POP.[IsPiecePart], 0) = 0 --AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT)
					INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				  --INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
					INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineNumber = stkdf.StockLineNumber AND stk.StocklineId = stkdf.StocklineId-- AND stk.ControlNumber = stkdf.ControlNumber
				WHERE po.RepairOrderId = @PurchaseOrderId
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,stk.isSerialized,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
					stk.SerialNumber,po.RepairOrderId,po.RepairOrderNumber,pop.QuantityOrdered,stk.RepairOrderUnitCost,pop.UnitCost,stk.RRQty,pop.RepairOrderPartRecordId,po.DepositAmount,Po.vendorProformaInvoiceNo,po.VendorProformaInvoiceId,pop.UnitOfMeasure,stk.StockUnitOfMeasure
					 				
				UNION
				
				SELECT stk.InventoryNumber AS 'StockLineNumber',
					stk.ControlNumber,
					stk.AssetInventoryId AS 'StockLineId',
					CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
					pop.ItemMasterId,
					pop.PartNumber,
					pop.PartDescription,
					stk.SerialNo AS 'SerialNumber',
					po.RepairOrderId AS 'PurchaseOrderId',
					po.RepairOrderNumber AS 'POReference',
					pop.UnitOfMeasure AS 'UnitOfMeasure',
					CAST(NULL AS VARCHAR(20)) AS 'StockUnitOfMeasure', 
					pop.QuantityOrdered AS 'POQtyOrder',
					stkdf.Qty AS 'ReceivedQty',
					pop.UnitCost AS 'POUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
					stkdf.Qty AS 'InvoicedQty',
					pop.UnitCost AS 'InvoicedUnitCost',
					(pop.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
					(stk.RRQty) AS 'RemainingRRQty',
					pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
					2 AS 'Type',
					'ASSET' AS 'StockType',
					ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
					Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
					ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				FROM dbo.RepairOrder po WITH(NOLOCK)
					INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND ISNULL(POP.[IsPiecePart], 0) = 0
					INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId --and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
					INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				where po.RepairOrderId = @PurchaseOrderId 
					--AND pop.RepairOrderPartRecordId=CAST(@PurchaseOrderPartRecordId AS BIGINT) AND POP.isParent  = 1
					--AND ISNULL((SELECT COUNT(POS.RepairOrderPartRecordId) from dbo.RepairOrderPart POS  WITH(NOLOCK) 
					--	WHERE POS.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT) ),0) = 0
				
				--UNION ALL
				
				--SELECT stk.InventoryNumber AS 'StockLineNumber',
				--	stk.ControlNumber,
				--	stk.AssetInventoryId AS 'StockLineId',
				--	CASE WHEN stk.isSerialized IS NULL THEN 0 ELSE stk.isSerialized END AS isSerialized,
				--	pop.ItemMasterId,
				--	pop.PartNumber,
				--	pop.PartDescription,
				--	stk.SerialNo AS 'SerialNumber',
				--	po.RepairOrderId AS 'PurchaseOrderId',
				--	po.RepairOrderNumber AS 'POReference',
				--	pop.QuantityOrdered AS 'POQtyOrder',
				--	stkdf.Qty AS 'ReceivedQty',
				--	pop.UnitCost AS 'POUnitCost',
				--	(pop.UnitCost * stkdf.Qty) AS 'POExtCost',
				--	stkdf.Qty AS 'InvoicedQty',
				--	pop.UnitCost AS 'InvoicedUnitCost',
				--	(pop.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
				--	(stk.RRQty) AS 'RemainingRRQty',
				--	pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
				--	2 AS 'Type',
				--	'ASSET' AS 'StockType',
				--	ISNULL(po.DepositAmount,0) AS VendorProformaAmount,
				--	Po.vendorProformaInvoiceNo As vendorProformaInvoiceNo,
				--	ISNULL(po.VendorProformaInvoiceId,0) AS VendorProformaInvoiceId
				--FROM dbo.RepairOrder po WITH(NOLOCK)
				--	INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId --AND pop.ParentId = CAST(@PurchaseOrderPartRecordId AS BIGINT)
				--	INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId --and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				--	INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				--WHERE po.RepairOrderId = @PurchaseOrderId

			END
		END
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingReconciliationPoData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
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