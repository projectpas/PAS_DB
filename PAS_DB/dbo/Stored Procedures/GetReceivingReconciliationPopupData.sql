--EXEC GetReceivingReconciliationPopupData 86
/************************************************************************/
CREATE PROCEDURE [dbo].[GetReceivingReconciliationPopupData]
@VendorId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		select DISTINCT po.PurchaseOrderId,po.PurchaseOrderNumber,pop.PartNumber,pop.PartDescription,pop.PurchaseOrderPartRecordId,po.CreatedDate,1 as 'Type' from PurchaseOrder po WITH(NOLOCK)
		inner join PurchaseOrderPart pop WITH(NOLOCK) on po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 AND pop.ItemType='Stock'
		inner join Stockline stk WITH(NOLOCK) on po.PurchaseOrderId = stk.PurchaseOrderId and stk.IsParent=1 AND stk.RRQty > 0
		where po.VendorId=@VendorId
		group by po.PurchaseOrderId,po.PurchaseOrderNumber,pop.PartNumber,pop.PartDescription,pop.PurchaseOrderPartRecordId,po.CreatedDate
		UNION
		select DISTINCT po.RepairOrderId as 'PurchaseOrderId',po.RepairOrderNumber as 'PurchaseOrderNumber',pop.PartNumber,pop.PartDescription,pop.RepairOrderPartRecordId as 'PurchaseOrderPartRecordId',po.CreatedDate
		,2 as 'Type' from RepairOrder po WITH(NOLOCK)
		inner join RepairOrderPart pop WITH(NOLOCK) on po.RepairOrderId = pop.RepairOrderId AND pop.isParent=1 AND pop.ItemType='Stock'
		inner join Stockline stk WITH(NOLOCK) on po.RepairOrderId = stk.RepairOrderId and stk.IsParent=1 AND stk.RRQty > 0
		where po.VendorId=@VendorId
		group by po.RepairOrderId,po.RepairOrderNumber,pop.PartNumber,pop.PartDescription,pop.RepairOrderPartRecordId,po.CreatedDate;
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingReconciliationPopupData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '') + ''
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