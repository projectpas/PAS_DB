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
** 8    02/19/2024	HEMANT SALIYA	     Updated for Restrict Accounting Entry by Master Company
** 9    04/09/2024	Devendra Shekh	     Updated for QuantityReserved for Stockline instead of QuantityAvailable
** 10   04/26/2024	HEMANT SALIYA	     Updated for Re-Open WO Changes
** 11   05/16/2024  Hemant Saliya		 Handle for Do not allow to reverse Billing Entry Multiple Time
** 12   01/15/2025  Hemant Saliya		 Reverse Billing Entry
** 13   02/05/2025  Hemant Saliya        Commented By Hemnat to Handle MTI Issue will work Later 05-02-2005
** 14	04/24/2025	Devendra Shekh		 Modify (Added [IsManualText] check for DistributionSetup)
** 15   06/25/2025  Moin Bloch		     Change Old To new Table
** 16   12/22/2025  Hemant Saliya        Handle Reopen Billing case for Posted Invoice.
** 17   27/03/2026  Moin Bloch	         Rename Internal To Internal Repair   PN-15850
** 18   25/06/2026   Moin Bloch	         Replace To Common Accounting SP PN-16871
** 19   02/09/2026   Ayushi Patel        [PN-14788] history marker for the Re-Open Finish Good action itself (the triggers above capture its side-effects, not the action that caused them).
EXEC dbo.USP_ReOpen_FinishGood_WorkOrder 286,'Admin'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_ReOpen_FinishGood_WorkOrder]
	@workOrderPartNoId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
	BEGIN
	
	DECLARE @ModuleId INT;
	DECLARE @SubModuleId INT;
	DECLARE @WorkOrderId BIGINT;
	DECLARE @MasterCompanyId BIGINT;
	DECLARE @StockLineId BIGINT;
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
	DECLARE @laborType VARCHAR(200)='DIRECTLABOR';
	DECLARE @Amount DECIMAL(18,2);    
    DECLARE @ModuleName VARCHAR(200)='WO';
	DECLARE @WOTypeId INT= 0;
	DECLARE @CustomerWOTypeId INT= 0;
	DECLARE @InternalWOTypeId INT= 0;
	DECLARE @IsInvoiceGenerated BIT = NULL;
	DECLARE @8130WorkOrderSettlementId BIGINT;
	DECLARE @ShippingWorkOrderSettlementId BIGINT = 10; --Fixed for Parts Shipped
	DECLARE @BillingWorkOrderSettlementId BIGINT = 11; --Fixed for Parts Invoiced
	DECLARE @WorkOrderNum VARCHAR(200);
	DECLARE @IsPaymentReceived BIT = NULL;
	DECLARE @WOModuleId INT=0	
	DECLARE @InvoiceStatusId BIGINT=0
					
	BEGIN TRY
		BEGIN TRANSACTION
		    SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
			SELECT @InvoiceStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(nolock) WHERE [Status] = 'Reviewed'
			SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('WOSETTLEMENTTAB')    
			SELECT @ReferencePartId = WorkFlowWorkOrderId, @WorkOrderId = WorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkOrderPartNoId = @workOrderPartNoId    
			
			SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
			SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal Repair'
			SELECT @8130WorkOrderSettlementId = WorkOrderSettlementId FROM WorkOrderSettlement WHERE UPPER(WorkOrderSettlementName) = 'RELEASE CERTS (E.G. 8130) REVIEWED'
			SELECT TOP 1 @WOTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId
			SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
			SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';
			SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId

			IF((SELECT COUNT(ID) FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNoId AND ISNULL(IsFinishGood,0) = 1 AND ISNULL(IsClosed, 0) = 0) >  0)
			BEGIN
				PRINT 'Start ReOpen FinishGood Execution'
				SELECT @StockLineId = StockLineId,@MasterCompanyId = MasterCompanyId FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @workOrderPartNoId

				SELECT @IsShippingDone = CASE WHEN COUNT(WOS.WorkOrderShippingId) > 0 THEN 1 ELSE 0 END 
				FROM dbo.WorkOrderShipping WOS WITH (NOLOCK) 
					JOIN dbo.WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId 
				WHERE WOSI.WorkOrderPartNumId = @workOrderPartNoId --AND (ISNULL(AirwayBill, '') != '') OR ISNULL(isIgnoreAWB, 0) = 1

				-- NEW TABLE
				SELECT @IsInvoiceGenerated = CASE WHEN COUNT(WOBI.[BillingInvoicingId]) > 0 THEN 1 ELSE 0 END,
					   @BillingInvoicingId = MAX(WOBI.[BillingInvoicingId])
				FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) 
					JOIN [dbo].[BillingInvoicingItems] WOBII WITH (NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
				WHERE WOBII.[SubReferenceId] = @WorkOrderPartNoId AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0 AND
					ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0 AND WOBI.[ModuleId] = @WOModuleId

				-- NEW TABLE 
				SELECT @IsPaymentReceived = CASE WHEN (ISNULL(SUM(WOBI.[RemainingAmount]),0) - ISNULL(SUM(WOBI.[GrandTotal]), 0)) = 0 THEN 0 ELSE 1 END,
					   @BillingInvoicingId = MAX(WOBI.[BillingInvoicingId])
				FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) 
					JOIN [dbo].[BillingInvoicingItems] WOBII WITH (NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
				WHERE WOBII.[SubReferenceId] = @WorkOrderPartNoId AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0 AND
					ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0 AND WOBI.[ModuleId] = @WOModuleId
					
				IF(ISNULL(@IsPaymentReceived, 0) = 0)
				BEGIN
					IF(ISNULL(@IsShippingDone,0) > 0 AND ISNULL(@WOTypeId,0) = @CustomerWOTypeId)
					BEGIN
						PRINT 'Update Stock Line Qty If Shipping is Done and Customer Stock'
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
						PRINT ' Update Stock Line Qty If Shipping is Done And not Customer Stock'
						/* Update Stock Line Qty If Shipping is Done And not Customer Stock */
						UPDATE Stockline SET 
							QuantityOnHand = ISNULL(QuantityOnHand, 0) + 1,
							QuantityReserved = ISNULL(QuantityReserved, 0) + 1,
							UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),
							Memo = CASE WHEN ISNULL(Memo,'') = '' THEN '</p>Updated Quntity From Work Order : ' + @WorkOrderNum + ' </p>' ELSE REPLACE(Memo, '</p>','<br>') + 'Updated Quntity From Work Order From Work Order : ' + @WorkOrderNum + ' </p>' END
						WHERE StockLineId=@StockLineId
					END

					IF(ISNULL(@IsInvoiceGenerated,0) > 0)
					BEGIN							
						
						PRINT 'Update Work Order Billing Status to Re-Generate Invoice'
						/* Update Work Order Billing Status to Re-Generate Invoice */

						-- NEW TABLE 
						UPDATE [dbo].[BillingInvoicing] SET 
							[InvoiceStatus] = 'Reviewed', 
							[InvoiceStatusId] = @InvoiceStatusId,
							[IsInvoicePosted] = NULL,
							[PostedDate] = NULL,
							[InvoiceFilePath] = '', 
							[WorkOrderShippingId] = NULL,
							[UpdatedBy] = @UpdatedBy, 
							[UpdatedDate] = GETUTCDATE()							
						WHERE [BillingInvoicingId] = @BillingInvoicingId

					END

					UPDATE dbo.WorkOrderPartNumber SET IsFinishGood = 0, isLocked = 0 WHERE ID = @workOrderPartNoId;

					UPDATE dbo.WorkOrderSettlementDetails SET IsMasterValue = 0, Isvalue_NA = 0
					WHERE WorkOrderId = @WorkOrderId AND workOrderPartNoId = @workOrderPartNoId AND WorkOrderSettlementId IN (@8130WorkOrderSettlementId, @ShippingWorkOrderSettlementId, @BillingWorkOrderSettlementId)

					
					INSERT INTO dbo.WorkOrderSettlementFieldHistory (WorkOrderPartNoId, ColumnKey, OldValue, NewValue, ChangedBy, ChangedAt)
					VALUES (@workOrderPartNoId, N'reOpenFinishGood', N'No', N'Yes', @UpdatedBy, SYSUTCDATETIME());

					DECLARE @ActionId INT;
					SELECT @ActionId  = ActionId FROM StklineHistory_Action WHERE UPPER([Type]) = UPPER('Re-OpenFinishedGood') -- Re-Open Finished Good

					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @workOrderPartNoId, @ActionId = @ActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;

					DECLARE @IsRestrict BIT;
					DECLARE @IsAccountByPass BIT;

					EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdatedBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

					IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
					BEGIN
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)  
						BEGIN  
							EXEC [dbo].[USP_BatchTriggerBasedonDistribution]     
							@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
						END
					END

					IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
					BEGIN
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)  
						BEGIN  
							EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]      
							@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
						END
					END			

					--REVERSE BILLING ENTRY
					SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('WOINVOICINGTAB')   
					DECLARE @IsInvoiceEntry BIT;

					--NEW TABLE
					SELECT @InvoiceId = MAX(WOBI.[BillingInvoicingId]) 
					  FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) 
					  JOIN [dbo].[BillingInvoicingItems] WOBII WITH (NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
					WHERE WOBII.[SubReferenceId] = @workOrderPartNoId AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0 AND
						ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0 AND ISNULL(WOBI.[IsReversedJE], 0) = 0
						AND  WOBI.[ModuleId] = @WOModuleId

					DECLARE @WOBatchTriggerType BatchTriggerWorkOrderType;
					DECLARE @IWOBatchTriggerType BatchTriggerWorkOrderType;

					SELECT @IsInvoiceEntry = CASE WHEN COUNT(WorkOrderBatchId) > 0 THEN 1 ELSE 0 END FROM  dbo.WorkOrderBatchDetails WITH(NOLOCK) WHERE InvoiceId = @BillingInvoicingId
					IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0 AND ISNULL(@IsInvoiceEntry, 0) > 0)
					BEGIN
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)  
						BEGIN  
							--EXEC [dbo].[USP_BatchTriggerBasedonDistribution]     
							--@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    

							INSERT INTO @WOBatchTriggerType VALUES 
							(@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,1,@ModuleName,@MasterCompanyId,@UpdatedBy)
					
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)
							BEGIN
								EXEC [USP_BatchTriggerBasedonDistributionForWO] @WOBatchTriggerType;
							END	

							--NEW TABLE
							UPDATE [dbo].[BillingInvoicing] SET [IsReversedJE] = 1 WHERE [BillingInvoicingId] = @InvoiceId
						END
					END
				
					--REVERSE BILLING ENTRY FOE INTERNAL WO
					IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0 AND ISNULL(@IsInvoiceEntry, 0) > 0)
					BEGIN
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)  
						BEGIN  
							--EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]      
							--@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdatedBy    
							
							INSERT INTO @IWOBatchTriggerType VALUES (@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,1,@ModuleName,@MasterCompanyId,@UpdatedBy)

							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)
							BEGIN
								EXEC [USP_BatchTriggerForInternalWOBasedonDistribution] @IWOBatchTriggerType;
							END	
							--NEW TABLE
							UPDATE [dbo].[BillingInvoicing] SET [IsReversedJE] = 1 WHERE [BillingInvoicingId] = @InvoiceId
						END
					END
					PRINT 'END ReOpen FinishGood Execution'

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
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@workOrderPartNoId, '') AS VARCHAR(100)) 
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