-- EXEC [DeleteMPN] 181,118,103,271,'admin'

CREATE PROCEDURE [dbo].[DeleteMPN]
@WOPartNoId BIGINT,
@WorkFlowWorkOrderId BIGINT,
@RecustomerId BIGINT,
@StockLineId BIGINT,
@UpdatedBy VARCHAR(256)

AS
	BEGIN
	DECLARE @TeardownId BIGINT
	DECLARE @WorkOrderTaskId BIGINT
	DECLARE @WorkOrderPublicationId BIGINT
	DECLARE @WorkOrderMaterialsId BIGINT
	DECLARE @WorkOrderLaborHeaderId BIGINT

	BEGIN TRY
		BEGIN TRANSACTION
				
			SELECT @TeardownId = WorkOrderTeardownId FROM WorkOrderTeardown WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
				
			/* Teardown deletion */
			DELETE FROM WorkOrderWorkPerformed WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderTestDataUsed WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderRemovalReasons WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderPreliinaryReview WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderPreAssmentResults WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderPreAssemblyInspection WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderPmaDerBulletins WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderFinalTest WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderFinalInspection WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderDiscovery WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderBulletinsModification WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderAdditionalComments WHERE WorkOrderTeardownId = @TeardownId
			DELETE FROM WorkOrderTeardown WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/* Work Order Task */
			SELECT @WorkOrderTaskId=WorkOrderTaskId FROM WorkOrderTask WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
			DELETE FROM WorkOrderTaskAttribute WHERE WorkOrderTaskId = @WorkOrderTaskId
			DELETE FROM WorkOrderTask WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/* Publications */
			SELECT @WorkOrderPublicationId=WorkOrderPublicationId FROM WorkOrderPublications WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
			DELETE FROM WorkOrderPublicationDashNumber WHERE WorkOrderPublicationId = @WorkOrderPublicationId
			DELETE FROM WorkOrderPublications WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
				
			/*Materials*/
			SELECT @WorkOrderMaterialsId=WorkOrderMaterialsId FROM WorkOrderMaterials WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
			DELETE FROM WorkOrderUnReservedStock WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
			DELETE FROM WorkOrderUnIssuedStock WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
			DELETE FROM WorkOrderStockLineReserve WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
			DELETE FROM WorkOrderReservedStock WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
			DELETE FROM WorkOrderMaterialStockLine WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
			DELETE FROM WorkOrderIssuedStock WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
			DELETE FROM WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Labour*/
			SELECT @WorkOrderLaborHeaderId=WorkOrderLaborHeaderId FROM WorkOrderLaborHeader WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
			DELETE FROM WorkOrderLabor WHERE WorkOrderLaborHeaderId = @WorkOrderLaborHeaderId
			DELETE FROM WorkOrderLaborHeader WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Freight*/
			DELETE FROM WorkOrderFreight WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Expertise*/
			DELETE FROM WorkOrderExpertise WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Exclusions*/
			DELETE FROM WorkOrderExclusions WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Documents*/
			DELETE FROM WorkOrderDocuments WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Directions*/
			DELETE FROM WorkOrderDirections WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Charges*/
			DELETE FROM WorkOrderCharges WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Assets*/
			DELETE FROM WorkOrderAssets WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Asset Audit*/
			DELETE FROM WorkOrderAssetAudit WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Address*/
			DELETE FROM WorkOrderAddress WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*WorkOrderWorkFlow*/
			DELETE FROM WorkOrderWorkFlow WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

			/*Work ORder Quote Task*/
			DELETE FROM WorkOrderQuoteTask WHERE WOPartNoId = @WOPartNoId

			/*WorkOrderMPNCostDetailsk*/
			DELETE FROM WorkOrderMPNCostDetails WHERE WOPartNoId = @WOPartNoId

			/*WorkOrderCostDetails*/
			DELETE FROM WorkOrderCostDetails WHERE WOPartNoId = @WOPartNoId

			/*WorkOrderCostDetails*/
			DELETE FROM WorkOrderBillingInvoicing WHERE WorkOrderPartNoId = @WOPartNoId

			/*WorkOrderPartNumber*/
			DELETE FROM WorkOrderPartNumber WHERE ID = @WOPartNoId

			/* Stock Line*/
			UPDATE Stockline SET WorkOrderId = 0, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() 
			WHERE StockLineId=@StockLineId

			/*Receiving*/
			UPDATE ReceivingCustomerWork SET WorkOrderId = 0, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE()
			WHERE ReceivingCustomerWorkId = @RecustomerId

	COMMIT TRANSACTION

	SELECT 'MPN Deleted successfully!' AS Response, 200 AS StatusId,@WOPartNoId AS WorkOrderPartNoId,
	@WorkFlowWorkOrderId AS WorkFlowWorkOrderId,@RecustomerId AS ReceivingCustomerWorkId,
	@StockLineId AS StockLineId,@UpdatedBy AS UpdatedBy

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteMPN' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WOPartNoId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END