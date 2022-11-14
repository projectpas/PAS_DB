--EXEC GetReceivingReconciliationPoData 10354,10575,1
/************************************************************************/
CREATE PROCEDURE [dbo].[GetReceivingReconciliationPoData]
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
			select stk.StockLineNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber as 'POReference',pop.QuantityOrdered as 'POQtyOrder',stkdf.QuantityOnHand as 'ReceivedQty',
			pop.UnitCost as 'POUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'POExtCost',stkdf.QuantityOnHand as 'InvoicedQty',pop.UnitCost as 'InvoicedUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'InvoicedExtCost',
			pop.PurchaseOrderPartRecordId,1 as 'Type' from dbo.PurchaseOrder po WITH(NOLOCK)
			inner join dbo.PurchaseOrderPart pop WITH(NOLOCK) on po.PurchaseOrderId = pop.PurchaseOrderId
			inner join dbo.Stockline stk WITH(NOLOCK) on stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
			inner join dbo.StocklineDraft stkdf WITH(NOLOCK) on stk.StockLineId = stkdf.StockLineId
			where po.PurchaseOrderId = @PurchaseOrderId 
			AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
			AND ISNULL((SELECT count(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId =@PurchaseOrderPartRecordId ),0) = 0
			UNION ALL
			select stk.StockLineNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber as 'POReference',pop.QuantityOrdered as 'POQtyOrder',stkdf.QuantityOnHand as 'ReceivedQty',
			pop.UnitCost as 'POUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'POExtCost',stkdf.QuantityOnHand as 'InvoicedQty',pop.UnitCost as 'InvoicedUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'InvoicedExtCost',
			pop.PurchaseOrderPartRecordId,1 as 'Type' from dbo.PurchaseOrder po WITH(NOLOCK)
			inner join dbo.PurchaseOrderPart pop WITH(NOLOCK) on po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
			inner join dbo.Stockline stk WITH(NOLOCK) on pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
			inner join dbo.StocklineDraft stkdf WITH(NOLOCK) on stk.StockLineId = stkdf.StockLineId
			where po.PurchaseOrderId = @PurchaseOrderId 
			--AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
			--AND ISNULL((SELECT count(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId = @PurchaseOrderPartRecordId ),0) > 0
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

			select stk.StockLineNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,stk.SerialNumber,po.RepairOrderId as 'PurchaseOrderId',po.RepairOrderNumber as 'POReference',pop.QuantityOrdered as 'POQtyOrder',stkdf.QuantityOnHand as 'ReceivedQty',
				pop.UnitCost as 'POUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'POExtCost',stkdf.QuantityOnHand as 'InvoicedQty',pop.UnitCost as 'InvoicedUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'InvoicedExtCost',
				pop.RepairOrderPartRecordId as 'PurchaseOrderPartRecordId',2 as 'Type' from dbo.RepairOrder po WITH(NOLOCK)
				inner join dbo.RepairOrderPart pop WITH(NOLOCK) on po.RepairOrderId = pop.RepairOrderId
				inner join dbo.Stockline stk WITH(NOLOCK) on stk.RepairOrderPartRecordId=pop.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND  
				inner join dbo.StocklineDraft stkdf WITH(NOLOCK) on stk.StockLineId = stkdf.StockLineId
				where po.RepairOrderId = @PurchaseOrderId 
				AND pop.RepairOrderPartRecordId=@PurchaseOrderPartRecordId AND POP.isParent  = 1
				AND ISNULL((SELECT count(POS.RepairOrderPartRecordId) from dbo.RepairOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId =@PurchaseOrderPartRecordId ),0) = 0
				UNION ALL
				select stk.StockLineNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,stk.SerialNumber,po.RepairOrderId as 'PurchaseOrderId',po.RepairOrderNumber as 'POReference',pop.QuantityOrdered as 'POQtyOrder',stkdf.QuantityOnHand as 'ReceivedQty',
				pop.UnitCost as 'POUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'POExtCost',stkdf.QuantityOnHand as 'InvoicedQty',pop.UnitCost as 'InvoicedUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'InvoicedExtCost',
				pop.RepairOrderPartRecordId as 'PurchaseOrderPartRecordId',2 as 'Type' from dbo.RepairOrder po WITH(NOLOCK)
				inner join dbo.RepairOrderPart pop WITH(NOLOCK) on po.RepairOrderId = pop.RepairOrderId AND pop.ParentId = @PurchaseOrderPartRecordId
				inner join dbo.Stockline stk WITH(NOLOCK) on pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
				inner join dbo.StocklineDraft stkdf WITH(NOLOCK) on stk.StockLineId = stkdf.StockLineId
				where po.RepairOrderId = @PurchaseOrderId

		END
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
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