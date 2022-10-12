--EXEC GetReceivingReconciliationPoData 182,325
/************************************************************************/
CREATE PROCEDURE [dbo].[GetReceivingReconciliationPoData]
@PurchaseOrderId bigint,
@PurchaseOrderPartRecordId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		select stk.StockLineNumber,stk.StockLineId,pop.ItemMasterId,pop.PartNumber,pop.PartDescription,stk.SerialNumber,po.PurchaseOrderId,po.PurchaseOrderNumber as 'POReference',pop.QuantityOrdered as 'POQtyOrder',stkdf.QuantityOnHand as 'ReceivedQty',
		pop.UnitCost as 'POUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'POExtCost',stkdf.QuantityOnHand as 'InvoicedQty',pop.UnitCost as 'InvoicedUnitCost',(pop.UnitCost * stkdf.QuantityOnHand) as 'InvoicedExtCost',
		pop.PurchaseOrderPartRecordId from PurchaseOrder po WITH(NOLOCK)
		inner join PurchaseOrderPart pop WITH(NOLOCK) on po.PurchaseOrderId = pop.PurchaseOrderId
		inner join Stockline stk WITH(NOLOCK) on po.PurchaseOrderId = stk.PurchaseOrderId and stk.IsParent=1 AND stk.RRQty > 0 -- AND stk.PurchaseOrderPartRecordId=pop.PurchaseOrderPartRecordId 
		inner join StocklineDraft stkdf WITH(NOLOCK) on stk.StockLineId = stkdf.StockLineId
		where po.PurchaseOrderId = @PurchaseOrderId AND pop.PurchaseOrderPartRecordId=@PurchaseOrderPartRecordId;
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