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
	
	EXEC GetReceivingReconciliationPoData 2100,3745,1
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetReceivingReconciliationPoData]
@PurchaseOrderId bigint,
@PurchaseOrderPartRecordId bigint,
@Type int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF(@Type = 1)
		BEGIN
			SELECT stk.StockLineNumber,
			       stk.ControlNumber,
				   stk.StockLineId,
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNumber,
				   po.PurchaseOrderId,
				   po.PurchaseOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
				   pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'POExtCost',
				   stk.RRQty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
				   (stk.RRQty) AS 'RemainingRRQty',
			       pop.PurchaseOrderPartRecordId,
				   1 AS 'Type',
				   'STOCK' AS 'StockType' 
			  FROM dbo.PurchaseOrder po WITH(NOLOCK)
			INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
			INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
			INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
			WHERE po.PurchaseOrderId = @PurchaseOrderId 
			AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
			AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) FROM dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId =@PurchaseOrderPartRecordId ),0) = 0
			GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
				     stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId
					 
			UNION ALL

			SELECT stk.StockLineNumber,
			       stk.ControlNumber,
				   stk.StockLineId,
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNumber,
				   po.PurchaseOrderId,
				   po.PurchaseOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   --stkdf.QuantityOnHand AS 'ReceivedQty',
				    SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
			       pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'POExtCost',
				   stk.RRQty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
				   (stk.RRQty) AS 'RemainingRRQty',
			       pop.PurchaseOrderPartRecordId,
				   1 as 'Type','STOCK' AS 'StockType' 
			  FROM dbo.PurchaseOrder po WITH(NOLOCK)
			INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
			INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
			INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
			WHERE po.PurchaseOrderId = @PurchaseOrderId 
			--AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
			--AND ISNULL((SELECT count(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId = @PurchaseOrderPartRecordId ),0) > 0
			GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
				     stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId
			UNION
			
			SELECT stk.NonStockInventoryNumber AS 'StockLineNumber',
				   stk.ControlNumber,
				   stk.NonStockInventoryId AS 'StockLineId',
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNumber,
				   po.PurchaseOrderId,
				   po.PurchaseOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				  -- stkdf.QuantityOnHand AS 'ReceivedQty',
				   SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
			       pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'POExtCost',
				   stk.RRQty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
				   (stk.RRQty) AS 'RemainingRRQty',
			       pop.PurchaseOrderPartRecordId,
				   1 AS 'Type',
				   'NONSTOCK' AS 'StockType' 
			  FROM dbo.PurchaseOrder po WITH(NOLOCK)
			INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
			INNER JOIN dbo.NonStockInventory stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId and stk.IsParent=1 --AND stk.RRQty > 0 -- AND  
			INNER JOIN dbo.NonStockInventoryDraft stkdf WITH(NOLOCK) ON stk.NonStockInventoryId = stkdf.NonStockInventoryId
			WHERE po.PurchaseOrderId = @PurchaseOrderId 
			AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
			AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId =@PurchaseOrderPartRecordId ),0) = 0			
			GROUP BY stk.NonStockInventoryNumber,stk.ControlNumber,stk.NonStockInventoryId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
				     stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId
		
			UNION ALL
			
			SELECT stk.NonStockInventoryNumber AS 'StockLineNumber',
			       stk.ControlNumber, 
				   stk.NonStockInventoryId AS 'StockLineId',
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNumber,
				   po.PurchaseOrderId,
				   po.PurchaseOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   --stkdf.QuantityOnHand AS 'ReceivedQty',
				   SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
			       pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'POExtCost',
				   stk.RRQty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
				   (stk.RRQty) AS 'RemainingRRQty',
			       pop.PurchaseOrderPartRecordId,
				   1 AS 'Type',
				   'NONSTOCK' AS 'StockType' 
			  FROM dbo.PurchaseOrder po WITH(NOLOCK)
			INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
			INNER JOIN dbo.NonStockInventory stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 --AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
			INNER JOIN dbo.NonStockInventoryDraft stkdf WITH(NOLOCK) ON stk.NonStockInventoryId = stkdf.NonStockInventoryId
			WHERE po.PurchaseOrderId = @PurchaseOrderId
			GROUP BY stk.NonStockInventoryNumber,stk.ControlNumber,stk.NonStockInventoryId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
				     stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.RRQty,pop.PurchaseOrderPartRecordId
					
			UNION
			
			SELECT stk.InventoryNumber AS 'StockLineNumber',
			       stk.ControlNumber, 
				   stk.AssetInventoryId AS 'StockLineId',
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNo AS 'SerialNumber',
				   po.PurchaseOrderId,
				   po.PurchaseOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   stkdf.Qty AS 'ReceivedQty',
			       pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stkdf.Qty) AS 'POExtCost',
				   stkdf.Qty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
				   (stk.RRQty) AS 'RemainingRRQty',
			       pop.PurchaseOrderPartRecordId,
				   1 AS 'Type',
				   'ASSET' AS 'StockType'
			  FROM dbo.PurchaseOrder po WITH(NOLOCK)
			INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
			INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId --and stk.IsParent=1 --AND stk.RRQty > 0 -- AND  
			INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
			WHERE po.PurchaseOrderId = @PurchaseOrderId 
			AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
			AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId =@PurchaseOrderPartRecordId ),0) = 0
			
			UNION ALL
			
			SELECT stk.InventoryNumber AS 'StockLineNumber',
			       stk.ControlNumber, 
				   stk.AssetInventoryId AS 'StockLineId',
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNo AS 'SerialNumber',
				   po.PurchaseOrderId,
				   po.PurchaseOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   stkdf.Qty AS 'ReceivedQty',
			       pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stkdf.Qty) AS 'POExtCost',
				   stkdf.Qty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stkdf.Qty) AS 'InvoicedExtCost',
				   (stk.RRQty) AS 'RemainingRRQty',
			       pop.PurchaseOrderPartRecordId,
				   1 AS 'Type',
				   'ASSET' AS 'StockType' 
			  FROM dbo.PurchaseOrder po WITH(NOLOCK)
			INNER JOIN dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
			INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId --and stk.IsParent=1 --AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
			INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
			WHERE po.PurchaseOrderId = @PurchaseOrderId
		END
		ELSE
		BEGIN
			--select DISTINCT stk.StockLineId,stk.StockLineNumber,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,stk.SerialNumber,po.RepairOrderId as 'PurchaseOrderId',po.RepairOrderNumber as 'POReference',
			--pop.QuantityOrdered as 'POQtyOrder',stkdf.QuantityOnHand as 'ReceivedQty',
			--pop.UnitCost as 'POUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'POExtCost',stkdf.QuantityOnHand as 'InvoicedQty',pop.UnitCost as 'InvoicedUnitCost',
			--(pop.UnitCost * stkdf.QuantityOnHand) as 'InvoicedExtCost',
			--pop.RepairOrderPartRecordId as 'PurchaseOrderPartRecordId',2 as 'Type' from RepairOrder po WITH(NOLOCK)
			--inner join RepairOrderPart pop WITH(NOLOCK) on po.RepairOrderId = pop.RepairOrderId 
			--inner join Stockline stk WITH(NOLOCK) on po.RepairOrderId = stk.RepairOrderId and stk.IsParent=1 AND stk.RRQty > 0 --AND stk.PurchaseOrderPartRecordId=pop.RepairOrderPartRecordId 
			--inner join StocklineDraft stkdf WITH(NOLOCK) on stk.StockLineId = stkdf.StockLineId
			--where po.RepairOrderId = @PurchaseOrderId 
			--AND pop.RepairOrderPartRecordId=@PurchaseOrderPartRecordId;

			SELECT stk.StockLineNumber,
			       stk.ControlNumber,
				   stk.StockLineId,
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNumber,
				   po.RepairOrderId AS 'PurchaseOrderId',
				   po.RepairOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   --stkdf.QuantityOnHand AS 'ReceivedQty',
				   SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
				   pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'POExtCost',
				   stk.RRQty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
				   (stk.RRQty)as 'RemainingRRQty',
				   pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
				   2 AS 'Type',
				   'STOCK' AS 'StockType' 
				FROM dbo.RepairOrder po WITH(NOLOCK)
				INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId
				INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
				INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
				WHERE po.RepairOrderId = @PurchaseOrderId 
				AND pop.RepairOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
				AND ISNULL((SELECT COUNT(POS.RepairOrderPartRecordId) FROM dbo.RepairOrderPart POS WITH(NOLOCK) WHERE POS.ParentId =@PurchaseOrderPartRecordId ),0) = 0			
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
				     stk.SerialNumber,po.RepairOrderId,po.RepairOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.RRQty,pop.RepairOrderPartRecordId

				UNION ALL
			
			SELECT stk.StockLineNumber,
			       stk.ControlNumber,
				   stk.StockLineId,
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNumber,
				   po.RepairOrderId AS 'PurchaseOrderId',
				   po.RepairOrderNumber AS 'POReference',
				   pop.QuantityOrdered AS 'POQtyOrder',
				   --stkdf.QuantityOnHand AS 'ReceivedQty',
				   SUM(ISNULL(stkdf.QuantityOnHand,0)) AS 'ReceivedQty',
				   pop.UnitCost AS 'POUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'POExtCost',
				   stk.RRQty AS 'InvoicedQty',
				   pop.UnitCost AS 'InvoicedUnitCost',
				   (pop.UnitCost * stk.RRQty) AS 'InvoicedExtCost',
				   (stk.RRQty)as 'RemainingRRQty',
				   pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
				   2 AS 'Type',
				   'STOCK' AS 'StockType' 
				FROM dbo.RepairOrder po WITH(NOLOCK)
				INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
				INNER JOIN dbo.Stockline stk WITH(NOLOCK) ON pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				INNER JOIN dbo.StocklineDraft stkdf WITH(NOLOCK) ON stk.StockLineId = stkdf.StockLineId
				WHERE po.RepairOrderId = @PurchaseOrderId
				GROUP BY stk.StockLineNumber,stk.ControlNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,
				     stk.SerialNumber,po.RepairOrderId,po.RepairOrderNumber,pop.QuantityOrdered,pop.UnitCost,stk.RRQty,pop.RepairOrderPartRecordId
					 				
				UNION
				
			SELECT stk.InventoryNumber AS 'StockLineNumber',
			       stk.ControlNumber,
				   stk.AssetInventoryId AS 'StockLineId',
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNo AS 'SerialNumber',
				   po.RepairOrderId AS 'PurchaseOrderId',
				   po.RepairOrderNumber AS 'POReference',
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
				   'ASSET' AS 'StockType' 
				FROM dbo.RepairOrder po WITH(NOLOCK)
				INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId
				INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId --and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
				INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				where po.RepairOrderId = @PurchaseOrderId 
				AND pop.RepairOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
				AND ISNULL((SELECT COUNT(POS.RepairOrderPartRecordId) from dbo.RepairOrderPart POS  WITH(NOLOCK) 
				WHERE POS.ParentId = @PurchaseOrderPartRecordId ),0) = 0
				
				UNION ALL
				
			SELECT stk.InventoryNumber AS 'StockLineNumber',
			       stk.ControlNumber,
				   stk.AssetInventoryId AS 'StockLineId',
				   pop.ItemMasterId,
				   pop.PartNumber,
				   pop.PartDescription,
				   stk.SerialNo AS 'SerialNumber',
				   po.RepairOrderId AS 'PurchaseOrderId',
				   po.RepairOrderNumber AS 'POReference',
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
				   'ASSET' AS 'StockType' 
				FROM dbo.RepairOrder po WITH(NOLOCK)
				INNER JOIN dbo.RepairOrderPart pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
				INNER JOIN dbo.AssetInventory stk WITH(NOLOCK) ON pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId --and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				INNER JOIN dbo.AssetInventoryDraft stkdf WITH(NOLOCK) ON stk.AssetInventoryId = stkdf.AssetInventoryId
				WHERE po.RepairOrderId = @PurchaseOrderId

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