/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <05/10/2023>  
** Description: <Re-Open Finish Good WO And Reverse MPN Stockline>  
  
Exec [ReverseWorkOrder] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    05/10/2023  Hemant Saliya		 Re-Open Finish Good WO And Reverse MPN Stockline
** 2    07/24/2023  Vishal Suthar		 Added stockline history for re-open finished goods
** 3	27/07/2023  Satish Gohil		 Account Entry Added
** 4    04/08/2023  Satish Gohil		 Seprate Accounting Entry WO Type Wise
** 5    08/09/2023  Devendra Shekh		 updating WorkOrderSettlementDetails
** 6    08/11/2023  Devendra Shekh		 added Isvalue_NA for updating WorkOrderSettlementDetails
** 7    08/11/2023  Devendra Shekh		 added isperforma Flage for WO  

EXEC dbo.USP_ReOpen_FinishGood_WorkOrder 286,'Admin'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_ReOpen_FinishGood_WorkOrder]
	@workOrderPartNoId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
	BEGIN
	
	DECLARE @ModuleId INT;
	DECLARE @SubModuleId INT;
	DECLARE @WorkOrderId BIGINT
	DECLARE @MasterCompanyId BIGINT
	DECLARE @StockLineId BIGINT
	DECLARE @BillingInvoicingId BIGINT
	DECLARE @IsShippingDone INT
	DECLARE @IsBillingDone INT
	DECLARE @DistributionMasterId bigint 
	DECLARE @ReferencePartId bigint    
    DECLARE @ReferencePieceId bigint=0  
	DECLARE @InvoiceId bigint=0  
	DECLARE @IssueQty bigint=0 
	DECLARE @issued bit=0 
	DECLARE @laborType varchar(200)='DIRECTLABOR'
	DECLARE @Amount decimal(18,2)    
    DECLARE @ModuleName varchar(200)='WO'
	DECLARE @WOTypeId INT= 0;
	DECLARE @CustomerWOTypeId INT= 0;
	DECLARE @InternalWOTypeId INT= 0;
					
	BEGIN TRY
		BEGIN TRANSACTION
			SELECT @DistributionMasterId = ID FROM dbo.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('WOSETTLEMENTTAB')    
			SELECT @ReferencePartId = WorkFlowWorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkOrderPartNoId = @workOrderPartNoId    
			
			SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
			SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'

			IF((SELECT COUNT(ID) FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNoId AND ISNULL(IsFinishGood,0) = 1 AND ISNULL(IsClosed, 0) = 0) >  0)
			BEGIN
				SELECT @StockLineId = StockLineId,@MasterCompanyId = MasterCompanyId FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNoId

				SELECT @IsShippingDone = COUNT(WSI.WorkOrderShippingItemId) FROM dbo.WorkOrderShippingItem WSI WITH (NOLOCK) 
				WHERE WSI.WorkOrderPartNumId = @workOrderPartNoId

				SELECT @BillingInvoicingId = WOB.BillingInvoicingId FROM dbo.WorkOrderBillingInvoicingItem WOBI WITH (NOLOCK) 
					JOIN dbo.WorkOrderBillingInvoicing WOB WITH (NOLOCK) ON WOBI.BillingInvoicingId = WOB.BillingInvoicingId AND ISNULL(WOB.IsPerformaInvoice, 0) = 0
				WHERE WOBI.WorkOrderPartId = @workOrderPartNoId

				IF(ISNULL(@IsShippingDone,0) > 0)
				BEGIN
					/* Update Stock Line Qty If Shipping is Done */
					UPDATE Stockline SET 
						QuantityAvailable = CASE WHEN QuantityAvailable = 0 THEN ISNULL(QuantityAvailable, 0) + 1 ELSE QuantityAvailable END, 
						QuantityOnHand = CASE WHEN QuantityOnHand = 0 THEN ISNULL(QuantityOnHand, 0) + 1 ELSE QuantityOnHand END,
						UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()						
					WHERE StockLineId=@StockLineId
				END

				IF(ISNULL(@BillingInvoicingId,0) > 0)
				BEGIN
					/* Update Stock Line Qty If Shipping is Done */
					UPDATE WorkOrderBillingInvoicing SET 
						InvoiceStatus = 'Reviewed', 
						InvoiceFilePath = '', 
						UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()						
					WHERE BillingInvoicingId = @BillingInvoicingId
				END

				UPDATE dbo.WorkOrderPartNumber SET IsFinishGood = 0 WHERE ID = @workOrderPartNoId;

				SELECT @WorkOrderId = WOP.WorkOrderId FROM dbo.WorkOrderPartNumber WOP WITH (NOLOCK) WHERE ID = @workOrderPartNoId;
				SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
				SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';

				UPDATE dbo.WorkOrderSettlementDetails SET IsMasterValue = 0, Isvalue_NA = 0 WHERE workOrderPartNoId = @workOrderPartNoId
				AND WorkOrderSettlementId = (SELECT WorkOrderSettlementId FROM WorkOrderSettlement WHERE WorkOrderSettlementName = 'Release Certs (e.g. 8130) Reviewed');

				DECLARE @ActionId INT;
				SET @ActionId = 10; -- Re-OpenFinishedGood
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @workOrderPartNoId, @ActionId = @ActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;
				
				SELECT TOP 1 @WOTypeId =WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId

				IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId)
				BEGIN
					IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)  
					BEGIN  
						EXEC [dbo].[USP_BatchTriggerBasedonDistribution]     
						@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
					END
				END

				IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId)
				BEGIN
					IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)  
					BEGIN  
						EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]      
						@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
					END
				END			

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