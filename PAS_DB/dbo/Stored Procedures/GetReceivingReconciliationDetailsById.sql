/*************************************************************               
--EXEC GetReceivingReconciliationDetailsById 27,0,'RPO'
************************************************************************/
CREATE PROCEDURE [dbo].[GetReceivingReconciliationDetailsById]
@ReceivingReconciliationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
				SELECT   [ReceivingReconciliationDetailId]
                 ,JBH.[ReceivingReconciliationId]
				 --,JBH.[BatchName]
                 ,[StocklineId]
                 ,[StocklineNumber]
                 ,[ItemMasterId]
                 ,[PartNumber]
                 ,[PartDescription]
                 ,[SerialNumber]
                 ,[POReference]
                 ,[POQtyOrder]
                 ,[ReceivedQty]
                 ,[POUnitCost]
                 ,[POExtCost]
                 ,[InvoicedQty]
                 ,[InvoicedUnitCost]
                 ,[InvoicedExtCost]
                 ,[AdjQty]
                 ,[AdjUnitCost]
                 ,[AdjExtCost]
                 ,[APNumber]
				 ,[PurchaseOrderId]
				 ,[PurchaseOrderPartRecordId]
				 ,[IsManual]
				 ,[PackagingId]
				 ,[Description]
				 ,[GlAccountId]
				 ,[Type]
				 FROM [dbo].[ReceivingReconciliationDetails] JBD WITH(NOLOCK)
				 Inner JOIN ReceivingReconciliationHeader JBH WITH(NOLOCK) ON JBD.ReceivingReconciliationId=JBH.ReceivingReconciliationId  
				 where JBD.ReceivingReconciliationId =@ReceivingReconciliationId
				 --and JBD.IsDeleted=@IsDeleted
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingReconciliationDetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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