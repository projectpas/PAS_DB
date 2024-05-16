/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <05/10/2023>  
** Description: <Re-Open Closed WO>  
  
Exec [USP_ReOpenClosedWorkOrder] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    05/10/2024  Hemant Saliya		 Re-Open Closed WO
** 2    05/16/2024  Hemant Saliya		 Handle for Do not allow to reverse Billing Entry Multiple Time

EXEC dbo.USP_ReOpenClosedWorkOrder 3433,'Admin'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_ReOpenClosedWorkOrder]
	@workOrderPartNoId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
	BEGIN
	
	DECLARE @ModuleId INT;
	DECLARE @SubModuleId INT;
	DECLARE @WorkOrderId BIGINT;
	DECLARE @MasterCompanyId BIGINT;
	DECLARE @StockLineId BIGINT = 0;
	DECLARE @BillingInvoicingId BIGINT;
	DECLARE @IsShippingDone INT;
	DECLARE @IsBillingDone INT;
	DECLARE @DistributionMasterId BIGINT;
	DECLARE @DistributionCode VARCHAR(50);
	DECLARE @ReferencePartId BIGINT;    
    DECLARE @ReferencePieceId BIGINT=0;  
	DECLARE @InvoiceId BIGINT=0;  
	DECLARE @IssueQty BIGINT=0; 
	DECLARE @issued bit=0; 
	DECLARE @laborType VARCHAR(200)='';
	DECLARE @Amount DECIMAL(18,2) = 0;    
    DECLARE @ModuleName VARCHAR(200)='WO';
	DECLARE @WOTypeId INT= 0;
	DECLARE @CustomerWOTypeId INT= 0;
	DECLARE @InternalWOTypeId INT= 0;
	DECLARE @IsPaymentReceived BIT = NULL;
	DECLARE @WorkOrderSettlementId BIGINT = 9; --Fixed for Final Condition Changed
	DECLARE @8130WorkOrderSettlementId BIGINT; --Fixed for Final Condition Changed
	DECLARE @ShippingWorkOrderSettlementId BIGINT = 10; --Fixed for Parts Shipped
	DECLARE @BillingWorkOrderSettlementId BIGINT = 11; --Fixed for Parts Invoiced
	DECLARE @WorkOrderStatusId INT;
	DECLARE @WorkOrderStageId INT;
	DECLARE @ClosedWorkOrderStatusId INT;
	DECLARE @WorkOrderNum VARCHAR(200);
	DECLARE @ExistingValue VARCHAR(200);
	DECLARE @NewValue VARCHAR(200) = 'OPEN';
	DECLARE @MPNPartNum VARCHAR(200);
	DECLARE @RefferenceId BIGINT, @SubRefferenceId BIGINT, @TemplateBody VARCHAR(MAX), @HistoryText VARCHAR(MAX), @StatusCode VARCHAR(100);
					
	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('WOSETTLEMENTTAB')    
			SELECT @WorkOrderId = WorkOrderId, @ReferencePartId = WorkFlowWorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkOrderPartNoId = @workOrderPartNoId    
			
			SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
			SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'
			SELECT @8130WorkOrderSettlementId = WorkOrderSettlementId FROM WorkOrderSettlement WHERE UPPER(WorkOrderSettlementName) = 'RELEASE CERTS (E.G. 8130) REVIEWED'
			SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
			SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';
			SELECT @WorkOrderStatusId = id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE [Status] = 'OPEN'

			SELECT @ClosedWorkOrderStatusId = id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE StatusCode = 'CLOSED'
			SELECT @WorkOrderNum = WorkOrderNum, @WOTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
			
			SELECT @StockLineId = StockLineId,@MasterCompanyId = WOP.MasterCompanyId, @ExistingValue = UPPER(WS.[Status]), @MPNPartNum = IM.partnumber 
			FROM dbo.WorkOrderPartNumber WOP WITH (NOLOCK) 
			JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
			JOIN dbo.WorkOrderStatus WS WITH (NOLOCK) ON WOP.WorkOrderStatusId = WS.Id
			WHERE WOP.ID = @workOrderPartNoId

			SELECT @WorkOrderStageId = WorkOrderStageId FROM dbo.WorkOrderStage WITH(NOLOCK) WHERE [StageCode] = 'RECEIVED' AND MasterCompanyId = @MasterCompanyId

			SELECT @IsShippingDone = CASE WHEN COUNT(WOS.WorkOrderShippingId) > 0 THEN 1 ELSE 0 END 
			FROM dbo.WorkOrderShipping WOS WITH (NOLOCK) 
				JOIN dbo.WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId 
			WHERE WOSI.WorkOrderPartNumId = @workOrderPartNoId --AND (ISNULL(AirwayBill, '') != '' ) --OR ISNULL(isIgnoreAWB, 0) = 1

			SELECT @IsPaymentReceived = CASE WHEN (ISNULL(SUM(WOBI.RemainingAmount),0) - ISNULL(SUM(WOBI.GrandTotal), 0)) = 0 THEN 0 ELSE 1 END,
				   @BillingInvoicingId = MAX(WOBI.BillingInvoicingId)
			FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
				JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
			WHERE WOBII.WorkOrderPartId = @WorkOrderPartNoId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.IsDeleted = 0 AND
				ISNULL(WOBII.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 AND WOBII.IsDeleted = 0

			--SELECT @IsShippingDone IsShippingDone, @IsPaymentReceived IsPaymentReceived
			IF(ISNULL(@IsPaymentReceived, 0) = 0) --ISNULL(@IsShippingDone,0) = 0 AND 
			BEGIN
				PRINT 'START'
				IF(ISNULL(@IsShippingDone,0) > 0 AND ISNULL(@WOTypeId,0) = @CustomerWOTypeId)
				BEGIN
					/* Update Stock Line Qty If Shipping is Done and Customer Stock */
					UPDATE Stockline SET 
						QuantityOnHand = CASE WHEN QuantityOnHand = 0 THEN ISNULL(QuantityOnHand, 0) + 1 ELSE QuantityOnHand END,
						QuantityReserved = CASE WHEN QuantityReserved = 0 THEN ISNULL(QuantityReserved, 0) + 1 ELSE QuantityReserved END,
						UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),
						Memo = CASE WHEN ISNULL(Memo,'') = '' THEN '</p>Updated Quntity From Work Order : ' + @WorkOrderNum + ' </p>' ELSE REPLACE(Memo, '</p>','<br>') + 'Updated Quntity From Work Order From Work Order : ' + @WorkOrderNum + ' </p>' END
					WHERE StockLineId=@StockLineId
				END

				IF(ISNULL(@IsShippingDone,0) > 0 AND ISNULL(@WOTypeId,0) != @CustomerWOTypeId)
				BEGIN
					/* Update Stock Line Qty If Shipping is Done And not Customer Stock */
					UPDATE Stockline SET 
						QuantityOnHand = ISNULL(QuantityOnHand, 0) + 1,
						QuantityReserved = ISNULL(QuantityReserved, 0) + 1,
						UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),
						Memo = CASE WHEN ISNULL(Memo,'') = '' THEN '</p>Updated Quntity From Work Order : ' + @WorkOrderNum + ' </p>' ELSE REPLACE(Memo, '</p>','<br>') + 'Updated Quntity From Work Order From Work Order : ' + @WorkOrderNum + ' </p>' END
					WHERE StockLineId=@StockLineId
				END

				IF(ISNULL(@BillingInvoicingId,0) > 0)
				BEGIN
					/* Update Work Order Billing Status to Re-Generate Invoice */
					UPDATE WorkOrderBillingInvoicing SET 
						InvoiceStatus = 'Reviewed', 
						InvoiceFilePath = '', 
						WorkOrderShippingId = Null,
						UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()						
					WHERE BillingInvoicingId = @BillingInvoicingId
				END 

				UPDATE dbo.WorkOrderPartNumber SET IsFinishGood = 0, IsClosed = 0, isLocked = 0, WorkOrderStatusId = @WorkOrderStatusId, WorkOrderStageId = @WorkOrderStageId WHERE ID = @workOrderPartNoId;

				UPDATE dbo.WorkOrder 
					SET WorkOrderStatusId = CASE WHEN ISNULL(WorkOrderStatusId, 0) = @ClosedWorkOrderStatusId THEN @WorkOrderStatusId ELSE WorkOrderStatusId END
				WHERE WorkOrderId = @WorkOrderId;

				UPDATE dbo.WorkOrderSettlementDetails SET IsMasterValue = 0, Isvalue_NA = 0 
				WHERE WorkOrderId = @WorkOrderId AND workOrderPartNoId = @workOrderPartNoId AND WorkOrderSettlementId IN (@8130WorkOrderSettlementId, @ShippingWorkOrderSettlementId, @BillingWorkOrderSettlementId)
				
				UPDATE WorkOrderSettlementDetails SET IsMastervalue = 1, Isvalue_NA = 0
				FROM dbo.WorkOrderSettlementDetails WSD WITH(NOLOCK)
				WHERE WSD.WorkOrderId = @WorkOrderId AND WSD.workOrderPartNoId =  @WorkOrderPartNoId AND WSD.WorkOrderSettlementId = @WorkOrderSettlementId 

				SET @StatusCode = 'REOPENCLOSEDWO';

				SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

				SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', ISNULL(@WorkOrderNum,''));
				SET @TemplateBody = REPLACE(@TemplateBody, '##WoMPN##', ISNULL(@MPNPartNum,''));				
				SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', ISNULL(@ExistingValue,''));
				SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', ISNULL(@NewValue,''));

				PRINT 'RE-OPEN WO History'
				EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, @ExistingValue, @NewValue, @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy,  NULL , @UpdatedBy, NULL
				PRINT 'END RE-OPEN WO DETAILS'

				DECLARE @ActionId INT;
				
				SELECT @ActionId  = ActionId FROM StklineHistory_Action WHERE UPPER([Type]) = UPPER('Re-OpenWorkOrder') -- Re-OpenWorkOrder
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @workOrderPartNoId, @ActionId = @ActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;
				
				DECLARE @IsRestrict BIT;
				DECLARE @IsAccountByPass BIT;

				EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdatedBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

				IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
				BEGIN
					IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0)  
					BEGIN  
						EXEC [dbo].[USP_BatchTriggerBasedonDistribution]     
						@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
					END
				END

				IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
				BEGIN
					IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)  
					BEGIN  
						EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]      
						@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
					END
				END			

				--REVERSE BILLING ENTRY FOR CUSTOMER WO
				SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('WOINVOICINGTAB')   
				DECLARE @IsInvoiceEntry BIT;

				SELECT @InvoiceId = MAX(WOBI.BillingInvoicingId) FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
					JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
				WHERE WOBII.WorkOrderPartId = @workOrderPartNoId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.IsDeleted = 0 AND
					ISNULL(WOBII.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 AND WOBII.IsDeleted = 0 AND ISNULL(WOBI.IsReversedJE, 0) = 0

				SELECT @IsInvoiceEntry = CASE WHEN COUNT(WorkOrderBatchId) > 0 THEN 1 ELSE 0 END FROM  dbo.WorkOrderBatchDetails WITH(NOLOCK) WHERE InvoiceId = @BillingInvoicingId
				IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0 AND ISNULL(@IsInvoiceEntry, 0) > 0)
				BEGIN
					PRINT 'REVERSE BILLING ENTRY FOR CUSTOMER WO'
					IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0)  
					BEGIN  
						PRINT'IN'
						EXEC [dbo].[USP_BatchTriggerBasedonDistribution]     
						@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
					
						UPDATE dbo.WorkOrderBillingInvoicing SET IsReversedJE = 1 WHERE BillingInvoicingId = @InvoiceId
					END

					PRINT 'END REVERSE BILLING ENTRY FOR CUSTOMER WO'
				END
				
				--REVERSE BILLING ENTRY FOR INTERNAL WO
				IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0 AND ISNULL(@IsInvoiceEntry, 0) > 0)
				BEGIN
					PRINT 'REVERSE BILLING ENTRY FOR INTERNAL WO'
					IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0)  
					BEGIN  
						PRINT 'IN'
						EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]      
						@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
					
						UPDATE dbo.WorkOrderBillingInvoicing SET IsReversedJE = 1 WHERE BillingInvoicingId = @InvoiceId
					
					END
					PRINT 'END REVERSE BILLING ENTRY FOR INTERNAL WO'
				END

				PRINT 'END'

			END
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ReOpen_FinishGood_WorkOrder' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderPartNoId, '') + ''
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