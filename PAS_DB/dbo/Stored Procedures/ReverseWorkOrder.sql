
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <07/30/2021>  
** Description: <Delete WO Details and Reverse MPN Stockline>  
  
Exec [ReverseWorkOrder] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    07/04/2022  Hemant Saliya    Delete WO Details And Reverse MPN Stockline

EXEC dbo.ReverseWorkOrder 286,'Admin'

**************************************************************/ 

CREATE PROCEDURE [dbo].[ReverseWorkOrder]
@WorkOrderId BIGINT,
@UpdatedBy VARCHAR(256),
@IsQtyReserved BIT = null OUTPUT

AS
	BEGIN
	DECLARE @TeardownId BIGINT
	DECLARE @WorkOrderTaskId BIGINT
	DECLARE @WorkOrderPublicationId BIGINT
	DECLARE @WorkOrderMaterialsId BIGINT
	DECLARE @WorkOrderLaborHeaderId BIGINT
	DECLARE @WorkFlowWorkOrderId BIGINT
	DECLARE @WorkOrderPartNumberId BIGINT
	DECLARE @MasterCompanyId BIGINT
	DECLARE @ResIssueCount INT = 0;
	DECLARE @IsWOCloseCount INT = 0;	
	DECLARE @StockLineId BIGINT
	DECLARE @RCustomerWorkId BIGINT
	DECLARE @IsSubWO INT = 0;
	DECLARE @SubWorkOrderId BIGINT;
	DECLARE @SubWOPartNoId BIGINT;
	DECLARE @SubWOStockLineId BIGINT;
	DECLARE @SubWorkOrderLaborHeaderId BIGINT;
	DECLARE @SubResIssueCount INT = 0;
	DECLARE @IsSWOClose INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION

			SELECT @ResIssueCount = SUM(ISNULL(QuantityReserved,0) + ISNULL(QuantityIssued,0)) FROM dbo.WorkOrderMaterials WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId 

			SELECT @SubResIssueCount = SUM(ISNULL(QuantityReserved,0) + ISNULL(QuantityIssued,0)) FROM dbo.SubWorkOrderMaterials WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId 

			SELECT @IsWOCloseCount = COUNT(ID) FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND (IsFinishGood = 1 OR IsClosed = 1)

			SELECT @IsSubWO = COUNT(SubWorkOrderId) FROM dbo.SubWorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId

			SELECT @IsSWOClose = COUNT(SubWorkOrderId) FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId AND ISNULL(IsClosed, 0) = 0

			/* Sub Work Order deletion */
			IF(ISNULL(@IsSubWO,0) >= 0 AND (ISNULL(@SubResIssueCount,0) <= 0 OR ISNULL(@IsSWOClose,0) = 0))
			BEGIN
				PRINT 'Start SWO'
				DECLARE db_cursor CURSOR FOR 
				SELECT SubWOPartNoId FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId 

				OPEN db_cursor  
				FETCH NEXT FROM db_cursor INTO @SubWOPartNoId
				WHILE @@FETCH_STATUS = 0  
				BEGIN  
					PRINT 'SubWO'
					PRINT @SubWOPartNoId
					SELECT @TeardownId = SubWorkOrderTeardownId FROM dbo.SubWorkOrderTeardown WITH (NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId
					SELECT @SubWOStockLineId = StockLineId, @SubWorkOrderId = SubWorkOrderId FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId
					
					/* SUB WO Materials deletion */
					DELETE FROM dbo.SubWorkOrderStockLineReserve WHERE SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM dbo.SubWorkOrderMaterials WHERE SubWOPartNoId = @SubWOPartNoId)
					DELETE FROM dbo.SubWorkOrderMaterialStockLine WHERE SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM dbo.SubWorkOrderMaterials WHERE SubWOPartNoId = @SubWOPartNoId)
					DELETE FROM dbo.SubWorkOrderMaterials WHERE SubWOPartNoId = @SubWOPartNoId

					/* SUB WO Teardown deletion */
					--DELETE FROM [dbo].[CommonWorkOrderTearDownAudit] WHERE SubWOPartNoId = @SubWOPartNoId
					DELETE FROM [dbo].[CommonWorkOrderTearDown] WHERE SubWOPartNoId = @SubWOPartNoId AND IsSubWorkOrder = 1

					/* SUB WO Labour deletion*/
					SELECT @SubWorkOrderLaborHeaderId=SubWorkOrderLaborHeaderId FROM dbo.SubWorkOrderLaborHeader WITH (NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId
					DELETE FROM dbo.SubWorkOrderLabor WHERE SubWorkOrderLaborHeaderId = @SubWorkOrderLaborHeaderId
					DELETE FROM dbo.SubWorkOrderLaborHeader WHERE SubWOPartNoId = @SubWOPartNoId

					/* SUB WO  Freight*/
					DELETE FROM dbo.SubWorkOrderFreight WHERE SubWOPartNoId = @SubWOPartNoId

					/*SUB WO Documents*/
					DELETE FROM dbo.SubWorkOrderDocuments WHERE SubWOPartNoId = @SubWOPartNoId

					/*SUB WO Charges*/
					DELETE FROM dbo.SubWorkOrderCharges WHERE SubWOPartNoId = @SubWOPartNoId

					/*SUB WO Asset Audit*/
					DELETE FROM SubWOCheckInCheckOutWorkOrderAssetAudit WHERE SubWOPartNoId = @SubWOPartNoId
					DELETE FROM dbo.SubWorkOrderAssetAudit WHERE SubWOPartNoId = @SubWOPartNoId

					/*SUB WO Assets*/
					DELETE FROM SubWOCheckInCheckOutWorkOrderAsset WHERE SubWOPartNoId = @SubWOPartNoId
					DELETE FROM dbo.SubWorkOrderAsset WHERE SubWOPartNoId = @SubWOPartNoId
								
					/*SUB WorkOrderMPNCostDetails*/
					DELETE FROM dbo.SubWorkOrderMPNCostDetail WHERE SubWOPartNoId = @SubWOPartNoId
								
					/*SUB WorkOrderCostDetails*/
					DELETE FROM dbo.SubWorkOrderCostDetails WHERE SubWOPartNoId = @SubWOPartNoId

					/*SUB WO Release From Details*/
					DELETE FROM dbo.SubWorkOrder_ReleaseFrom_8130 WHERE SubWOPartNoId = @SubWOPartNoId

					/*SUB WorkOrder Settlement Details*/
					DELETE FROM dbo.SubWorkOrderSettlementDetailsAudit WHERE SubWOPartNoId = @SubWOPartNoId
					DELETE FROM dbo.SubWorkOrderSettlementDetails WHERE SubWOPartNoId = @SubWOPartNoId

					PRINT 'Sub Stock Line'
					/* Stock Line*/
					UPDATE Stockline SET WorkOrderId = NULL, SubWorkOrderId = NULL, QuantityAvailable = ISNULL(QuantityAvailable, 0) + 1, QuantityReserved = ISNULL(QuantityReserved, 0) - 1, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() 
					WHERE StockLineId=@SubWOStockLineId

					UPDATE dbo.Stockline SET SubWOPartNoId = NULL WHERE SubWOPartNoId = @SubWOPartNoId

					PRINT 'Sub WorkOrderPartNumber'
					/*Sub WorkOrderPartNumber*/
					DELETE FROM dbo.SubWorkOrderPartNumberAudit WHERE SubWOPartNoId = @SubWOPartNoId
					DELETE FROM dbo.SubWorkOrderPartNumber WHERE SubWOPartNoId = @SubWOPartNoId

					PRINT 'SubWorkOrder Material Mapping'
					/*Sub SubWorkOrder Material Mapping*/
					DELETE FROM dbo.SubWorkOrderMaterialMapping WHERE SubWorkOrderId = @SubWorkOrderId

					PRINT 'Sub WorkOrder'
					/*SUB WorkOrder*/					
					IF((SELECT COUNT(ISNULL(SubWOPartNoId,0)) FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId) <= 0)
					BEGIN
						DELETE FROM dbo.SubWorkOrderAudit WHERE SubWorkOrderId = @SubWorkOrderId
						DELETE FROM SubWorkOrder WHERE SubWorkOrderId = @SubWorkOrderId
						PRINT 'Sub WorkOrder Complete'
					END					

				  FETCH NEXT FROM db_cursor INTO @SubWOPartNoId
				END 
				CLOSE db_cursor  
				DEALLOCATE db_cursor

				PRINT 'Delete Sub WorkOrder'
				/*SUB WorkOrder*/
				IF((SELECT COUNT(ISNULL(SubWOPartNoId,0)) FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId) <= 0)
				BEGIN
					PRINT 'SubWorkOrder Material Mapping'
					/*Sub SubWorkOrder Material Mapping*/
					DELETE FROM dbo.SubWorkOrderMaterialMapping WHERE SubWorkOrderId IN (SELECT SubWorkOrderId FROM dbo.SubWorkOrder WHERE WorkOrderId = @WorkOrderId)

					DELETE FROM dbo.SubWorkOrderAudit WHERE WorkOrderId = @WorkOrderId
					DELETE FROM SubWorkOrder WHERE WorkOrderId = @WorkOrderId
					PRINT 'Sub WorkOrder Complete'
				END
			END

			/* Work Order deletion */
			IF(ISNULL(@ResIssueCount, 0) <= 0 AND ISNULL(@IsWOCloseCount,0) <= 0 AND ISNULL(@SubResIssueCount,0) <= 0)
			BEGIN
				DECLARE db_cursor CURSOR FOR 
				SELECT WorkFlowWorkOrderId FROM dbo.WorkOrderWorkFlow WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId 

				OPEN db_cursor  
				FETCH NEXT FROM db_cursor INTO @WorkFlowWorkOrderId

				WHILE @@FETCH_STATUS = 0  
				BEGIN  
					PRINT 'Start Removing WorkOrder'
					SELECT @WorkOrderPartNumberId = WorkOrderPartNoId, @MasterCompanyId = MasterCompanyId FROM dbo.WorkOrderWorkFlow WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					SELECT @TeardownId = WorkOrderTeardownId FROM WorkOrderTeardown WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					SELECT @StockLineId = StockLineId, @RCustomerWorkId = ReceivingCustomerWorkId FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @WorkOrderPartNumberId 
					
					PRINT 'Delete Sub WorkOrder'
					/*SUB WorkOrder*/
					IF((SELECT COUNT(ISNULL(SubWOPartNoId,0)) FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId) <= 0)
					BEGIN
						DELETE FROM dbo.SubWorkOrderAudit WHERE WorkOrderId = @WorkOrderId
						DELETE FROM SubWorkOrder WHERE WorkOrderId = @WorkOrderId
						PRINT 'Sub WorkOrder Complete'
					END

					/* Stock Line WorkOrderMaterialsId Update*/
					UPDATE dbo.Stockline SET WorkOrderMaterialsId = NULL 
					WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)

					/* Materials deletion */
					DELETE FROM dbo.WorkOrderIssuedStock WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
					DELETE FROM dbo.WorkOrderUnIssuedStock WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
					DELETE FROM dbo.WorkOrderReservedStock WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
					DELETE FROM dbo.WorkOrderUnReservedStock WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
					DELETE FROM dbo.WorkOrderStockLineReserve WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
					DELETE FROM dbo.WorkOrderMaterialStockLine WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
					DELETE FROM dbo.WorkOrderMaterials WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM dbo.WorkOrderMaterials WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)

					/* Teardown deletion */
					--DELETE FROM [dbo].[CommonWorkOrderTearDownAudit] WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					DELETE FROM [dbo].[CommonWorkOrderTearDown] WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					/*Labour deletion*/
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

					/*Asset Audit*/
					
					DELETE FROM CheckInCheckOutWorkOrderAssetAudit WHERE WorkOrderPartNoId = @WorkOrderPartNumberId
					DELETE FROM WorkOrderAssetsAudit WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					/*Assets*/
					DELETE FROM CheckInCheckOutWorkOrderAsset WHERE WorkOrderPartNoId = @WorkOrderPartNumberId
					DELETE FROM WorkOrderAssets WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					/*Work Order Quote Materials*/
					DELETE FROM WorkOrderQuoteMaterial WHERE WorkOrderQuoteDetailsId IN (SELECT WorkOrderQuoteDetailsId FROM WorkOrderQuoteDetails WHERE WOPartNoId = @WorkOrderPartNumberId)

					/*Work Order Quote Task*/
					DELETE FROM WorkOrderQuoteTask WHERE WOPartNoId = @WorkOrderPartNumberId

					/*Work Order Quote*/
					DELETE FROM WorkOrderQuoteDetails WHERE WOPartNoId = @WorkOrderPartNumberId

					/*WorkOrderMPNCostDetailsk*/
					DELETE FROM WorkOrderMPNCostDetails WHERE WOPartNoId = @WorkOrderPartNumberId

					/*WorkOrderCostDetails*/
					DELETE FROM WorkOrderCostDetails WHERE WOPartNoId = @WorkOrderPartNumberId

					/*WorkOrderCostDetails*/
					DELETE FROM WorkOrderBillingInvoicingItemAudit WHERE WorkOrderPartId = @WorkOrderPartNumberId
					DELETE FROM WorkOrderBillingInvoicingAudit WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					DELETE FROM WorkOrderBillingInvoicingItem WHERE WorkOrderPartId = @WorkOrderPartNumberId
					DELETE FROM WorkOrderBillingInvoicing WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					/*Release From Details*/
					DELETE FROM dbo.Work_ReleaseFrom_8130 WHERE workOrderPartNoId = @WorkOrderPartNumberId

					/*WorkOrder Settlement Details*/
					DELETE FROM dbo.WorkOrderSettlementDetailsAudit WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					DELETE FROM dbo.WorkOrderSettlementDetails WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					/*WorkOrderPartNumber*/
					DELETE FROM WorkOrderPartNumberAudit WHERE WOPartNoId = @WorkOrderPartNumberId
					DELETE FROM WorkOrderPartNumber WHERE ID = @WorkOrderPartNumberId

					--/*WorkOrderWorkFlow*/
					DELETE FROM WorkOrderWorkFlowAudit WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					DELETE FROM WorkOrderWorkFlow WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					/* Stock Line*/
					UPDATE Stockline SET WorkOrderId = NULL, QuantityAvailable = ISNULL(QuantityAvailable, 0) + 1, QuantityReserved = ISNULL(QuantityReserved, 0) - 1, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() 
					WHERE StockLineId=@StockLineId

					/* Stock Line*/
					UPDATE Stockline SET WorkOrderId = NULL, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() 
					WHERE WorkOrderId=@WorkOrderId
					
					/*Receiving*/
					UPDATE ReceivingCustomerWork SET WorkOrderId = NULL, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE()
					WHERE ReceivingCustomerWorkId = @RCustomerWorkId

					/*WorkOrder*/
					IF((SELECT COUNT(ID) FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId) <= 0)
					BEGIN
						/*Work Order Quote*/
						DELETE FROM WorkOrderQuote WHERE WorkOrderId = @WorkOrderId

						DELETE FROM WorkOrderAudit WHERE WorkOrderId = @WorkOrderId
						DELETE FROM WorkOrder WHERE WorkOrderId = @WorkOrderId
					END
					  
				  FETCH NEXT FROM db_cursor INTO @WorkFlowWorkOrderId
				END 
				CLOSE db_cursor  
				DEALLOCATE db_cursor
			END

			IF(ISNULL(@ResIssueCount, 0) > 0 OR ISNULL(@IsWOCloseCount,0) > 0 OR ISNULL(@SubResIssueCount,0) > 0)			
			BEGIN
				SET @IsQtyReserved = 1;
			END
			ELSE
			BEGIN
				SET @IsQtyReserved = 0;
			END

	COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'ReverseWorkOrder' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNumberId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID				= @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END