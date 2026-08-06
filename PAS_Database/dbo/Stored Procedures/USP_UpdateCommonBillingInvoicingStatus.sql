
/*********************             
 ** File:   [USP_UpdateCommonBillingInvoicingStatus]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Update Common Billing Invoicing Status
 ** Purpose:           
 ** Date:   05/06/2025
         
 **********************             
  ** Change History             
 **********************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				-------------------------------            
    1    05/06/2025   Moin Bloch		Created
	2    10/06/2025   Rajesh Gami		Implemented SO
	3    18/06/2025   Moin Bloch		Update Status in Proforma
	4    04/07/2025   Devendra Shekh	Update UsedDeposite for SO
	5    04/07/2025   Moin Bloch		Update [IsStandardInvoicePosted] Status for Proforma
	6    04/07/2025   Moin Bloch		Update Comment Un USED SP
	7    09/07/2025   Moin Bloch		Fix For Deposit Amount
	8    23/07/2025   Rajesh Gami		Remove Transaction
	9    27/03/2026   Moin Bloch	    Rename Internal To Internal Repair   PN-15850
	10   09/06/2026   Rajesh Gami	    [IsStandardInvoicePosted] = 1 Update for the proforma invoice while Standard Invoice being INVOICED   PN-16775
	11    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
    EXEC [dbo].[USP_UpdateCommonBillingInvoicingStatus] 10157,8998,0,3,15,'ADMIN User',1

**********************/ 
CREATE PROCEDURE [dbo].[USP_UpdateCommonBillingInvoicingStatus]    
@BillingInvoicingId BIGINT = NULL,
@ReferenceId BIGINT = NULL,
@IsPerformaInvoice BIT = NULL,
@InvoiceStatusId INT = NULL,
@ModuleId INT = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@MasterCompanyId INT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
 --BEGIN TRANSACTION  
 BEGIN
		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT,@WOSubModuleId INT
		DECLARE @ProformaDepositAmount DECIMAL(18,2) = 0;
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		SELECT @WOSubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';

		DECLARE @InvoicedStatusId INT = 0
		DECLARE @InvoicedStatus VARCHAR(50)=''
		SELECT @InvoicedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Invoiced'
		SELECT @InvoicedStatus = [Status] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [InvoiceStatusId] = @InvoiceStatusId

		IF(@ModuleId = @WOModuleId) /****START: WORK ORDER ***/
		BEGIN		
			DECLARE @CodeTypeId BIGINT			
			DECLARE @WorkOrderTypeId BIGINT = 0
			DECLARE @WorkOrderNum VARCHAR(50)='',@CustomerName VARCHAR(50)=''			 
			DECLARE @DistributionMasterId  INT = 0,@DistributionSetupId INT = 0
			DECLARE @ShippingPostName VARCHAR(50)='ShippingPost'
			DECLARE @oldValue VARCHAR(50) = 'False';
            DECLARE @newValue VARCHAR(50) = 'True';
			DECLARE @ValidBatchDetails BIT = 1
			DECLARE @Customer INT,@Internal INT
			DECLARE @DistributionCode VARCHAR(50)=''		
			DECLARE @IsRestrict BIT,@IsAccountByPass BIT;			 
			DECLARE @CustomerId BIGINT = 0, @SubReferenceId BIGINT = 0;
			DECLARE @WOMSModuleId INT = 0;
			DECLARE @InvoiceNo VARCHAR(256) = '';	
			DECLARE @GrandTotal DECIMAL(18,2) = 0;
			DECLARE @WorkOrderSettlementDetailId BIGINT = 0,@WorkOrderSettlementId BIGINT = 0,@WorkFlowWorkOrderId BIGINT = 0
			DECLARE @PartNumber VARCHAR(50)='',@TemplateBody VARCHAR(MAX)=''
			DECLARE @UpdatedDate DATETIME2(7);			
						
			SELECT @InvoicedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Invoiced';
			
			SELECT @InvoicedStatus = [Status] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [InvoiceStatusId] = @InvoiceStatusId;

			SELECT @Customer = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';
			
			SELECT @Internal = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';	
			
			SELECT @WOMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
			
			SELECT @CodeTypeId = [CodeTypeId] from CodeTypes WHERE [CodeType] = 'WOInvoice';

			SELECT @WorkOrderTypeId = WO.[WorkOrderTypeId],  
				       @CustomerId = WO.[CustomerId],					   
					   @CustomerName = CU.[Name],
					   @WorkOrderNum = WO.[WorkOrderNum]
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
				INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON WO.[CustomerId] = CU.[CustomerId]
				WHERE [WorkOrderId] = @ReferenceId


			SELECT @ProformaDepositAmount = SUM(ISNULL(BI.DepositAmount, 0)) - SUM(ISNULL(BI.UsedDeposit, 0))  
			FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)			
			WHERE BI.[ReferenceId] = @ReferenceId AND BI.ModuleId  =  @ModuleId AND ISNULL(BI.IsPerformaInvoice, 0) = 1 

			IF(ISNULL(@IsPerformaInvoice,0) = 0)
			BEGIN					   						
				UPDATE [dbo].[BillingInvoicing] 
				   SET [UpdatedDate] = GETUTCDATE(),
					   [PostedDate] = GETUTCDATE(),
					   [InvoiceStatusId] = @InvoiceStatusId,
					   [InvoiceStatus] = @InvoicedStatus,
					   [DepositAmount] = CASE WHEN ISNULL([DepositAmount],0) >= @ProformaDepositAmount AND ISNULL(IsPerformaInvoice, 0) = 0 THEN @ProformaDepositAmount ELSE ISNULL([DepositAmount],0) END ,
					   [RemainingAmount] = CASE WHEN ISNULL([DepositAmount],0) >= @ProformaDepositAmount AND ISNULL(IsPerformaInvoice, 0) = 0 THEN ISNULL([GrandTotal],0) - @ProformaDepositAmount ELSE ISNULL([GrandTotal],0) - ISNULL([DepositAmount],0) END ,
					   [UpdatedBy] = @UpdatedBy					  
				 WHERE [BillingInvoicingId] = @BillingInvoicingId

				IF(@InvoiceStatusId = @InvoicedStatusId)
				BEGIN	
					SELECT @InvoiceNo = [InvoiceNo], 
					       @GrandTotal =  ISNULL([GrandTotal],0)
					  FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
					 WHERE [BillingInvoicingId] = @BillingInvoicingId 

					 SELECT TOP 1 @SubReferenceId = BII.[SubReferenceId],
					              @WorkFlowWorkOrderId = WOF.[WorkFlowWorkOrderId]
					  FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
					  JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON BII.[SubReferenceId] = WOF.[WorkOrderPartNoId]
					 WHERE BII.[BillingInvoicingId] = @BillingInvoicingId 

					 SELECT @InvoiceNo = [InvoiceNo], 
					        @GrandTotal =  ISNULL([GrandTotal],0)
					   FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
					  WHERE [BillingInvoicingId] = @BillingInvoicingId 

					UPDATE [dbo].[BillingInvoicing] 
					   SET [IsInvoicePosted] = 1
					 WHERE [BillingInvoicingId] = @BillingInvoicingId

					  UPDATE [dbo].[BillingInvoicing] 
					    SET [IsStandardInvoicePosted] = 1
					  WHERE [ReferenceId] = @ReferenceId 
					    AND [ModuleId] = @ModuleId 
						AND [IsPerformaInvoice] = 1	

					 IF OBJECT_ID(N'tempdb..#TempUpdateBillingDetailsForPerforma') IS NOT NULL    
					 BEGIN    
						DROP TABLE #TempUpdateBillingDetailsForPerforma
					 END

					 CREATE TABLE #TempUpdateBillingDetailsForPerforma
					 (
						[PKID] [BIGINT] NOT NULL IDENTITY,			
						[BillingInvoicingId] [BIGINT],
						[ModuleId] [INT] NULL,
						[ReferenceId] [BIGINT] NULL,		
						[DepositAmount] [DECIMAL](18,2) NULL,
						[UsedDeposit] [DECIMAL](18,2) NULL				
					 )
					 					
					 INSERT INTO #TempUpdateBillingDetailsForPerforma([BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit])
															  SELECT [BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit] 
					 FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [ReferenceId] = @ReferenceId AND [ModuleId] = @ModuleId AND [IsPerformaInvoice] = 1 AND ISNULL([IsVersionIncrease],0) = 0


					 DECLARE @DepositAmount DECIMAL(18,2) = 0,@UsedDeposit DECIMAL(18,2) = 0
					 DECLARE @TotalRecordPRo INT = 0,@MinIdPro BIGINT = 1

					 SELECT @DepositAmount = ISNULL([DepositAmount],0) FROM [dbo].[BillingInvoicing] WHERE [BillingInvoicingId] = @BillingInvoicingId  


					SELECT @TotalRecordPRo = COUNT(*), @MinIdPro = MIN([PKID]) FROM #TempUpdateBillingDetailsForPerforma    

					WHILE @MinIdPro <= @TotalRecordPRo
					BEGIN
						DECLARE @PendingDeposit DECIMAL(18,2)=0,@PerformaBillingInvoicingId BIGINT = 0
						DECLARE @PerformaDepositAmount DECIMAL(18,2)=0

						SELECT @PerformaBillingInvoicingId = [BillingInvoicingId],
						       @ModuleId = [ModuleId],
							   @ReferenceId = [ReferenceId], 
							   @PerformaDepositAmount = ISNULL([DepositAmount],0),  
							   @UsedDeposit = ISNULL([UsedDeposit],0) 
						  FROM #TempUpdateBillingDetailsForPerforma WHERE [PKID] = @MinIdPro
			
						IF(@DepositAmount > 0) 
						BEGIN	
							SET @PendingDeposit = @PerformaDepositAmount - @UsedDeposit    

							UPDATE [dbo].[BillingInvoicing] SET [UsedDeposit] = CASE WHEN @DepositAmount >= @PendingDeposit THEN ISNULL([UsedDeposit],0) + @PendingDeposit ELSE ISNULL([UsedDeposit],0) + @DepositAmount END
							 WHERE [BillingInvoicingId] = @PerformaBillingInvoicingId
				
							SET @DepositAmount =  CASE WHEN @DepositAmount >= @PendingDeposit THEN @DepositAmount - @PendingDeposit ELSE 0 END 				
						END

						SET @MinIdPro = @MinIdPro + 1;
					END
					
					EXEC [dbo].[USP_UpdateDepositAmount] @BillingInvoicingId, 1

					SELECT @DistributionMasterId = [ID],
					       @DistributionCode = [DistributionCode]
					FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'WOINVOICINGTAB';

					SELECT @DistributionSetupId = [ID]					       
					FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					WHERE [DistributionMasterId] = @DistributionMasterId
					  AND [MasterCompanyId] = @MasterCompanyId
					  AND ([GlAccountId] IS NULL OR [GlAccountId] = 0)
					  AND ISNULL([IsManualText], 0) = 0;

					IF(@DistributionSetupId > 0)
					BEGIN
						SET @ValidBatchDetails = 0
					END
					IF(@ValidBatchDetails = 1)
					BEGIN
						-- WO Customer
						IF(@WorkOrderTypeId = @Customer)
						BEGIN
							EXEC [dbo].[USP_GetSubLadgerGLAccountRestriction] @DistributionCode, @MasterCompanyId, 0, @UpdatedBy, @IsRestrict = @IsRestrict OUTPUT, @IsAccountByPass = @IsAccountByPass OUTPUT
							IF(@IsAccountByPass <> 1)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionNew] @DistributionMasterId,@ReferenceId,0,0,@BillingInvoicingId,0,0,'',1,0,'WO',@MasterCompanyId,@UpdatedBy;
							END
						END
						-- WO Customer
						IF(@WorkOrderTypeId = @Internal)
						BEGIN
							EXEC [dbo].[USP_GetSubLadgerGLAccountRestriction] @DistributionCode, @MasterCompanyId, 0, @UpdatedBy, @IsRestrict = @IsRestrict OUTPUT, @IsAccountByPass = @IsAccountByPass OUTPUT
							IF(@IsAccountByPass <> 1)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWONew] @DistributionMasterId,@ReferenceId,0,0,@BillingInvoicingId,0,0,'',1,0,'WO',@MasterCompanyId,@UpdatedBy;
							END
						END
					END
					
					EXEC [dbo].[USP_CreateCustomerGeneralLedger] @CustomerId,@WOMSModuleId,@BillingInvoicingId,@InvoiceNo,0,@GrandTotal,@MasterCompanyId,'WorkOrder',@UpdatedBy
										
					SELECT @WorkOrderSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] =  'Work Order Invoiced'

					SELECT @WorkOrderSettlementDetailId = [WorkOrderSettlementDetailId] 
					  FROM [dbo].[WorkOrderSettlementDetails] WITH(NOLOCK) 
					 WHERE [WorkOrderId] = @ReferenceId
					   AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
					   AND [WorkOrderSettlementId] = @WorkOrderSettlementId

					IF(@WorkOrderSettlementDetailId > 0)
					BEGIN
						UPDATE [dbo].[WorkOrderSettlementDetails] 
						   SET [IsMastervalue] = 1, 
						       [Isvalue_NA] = 0
						 WHERE [WorkOrderSettlementDetailId] = @WorkOrderSettlementDetailId;
					END

					-- NOT ADDED Due to we are updating [IsInvoicePosted] flag in Proforma and common Billing also in this strod pro
					
					-- EXEC [dbo].[USP_UpdateWOProformaInvoice] @ReferenceId,@WorkFlowWorkOrderId,@BillingInvoicingId

					--EXEC [dbo].[USP_UpdateUsedDepositForProforma_byIdNew] @BillingInvoicingId

					EXEC dbo.[USP_SaveCustomerARBalance] @CodeTypeId, @BillingInvoicingId, @CustomerId, 0, @GrandTotal,'',@MasterCompanyId,@UpdatedBy,@UpdatedBy,0
 
				 END			
			END	
			ELSE
			BEGIN
				 IF(@InvoiceStatusId = @InvoicedStatusId)
				 BEGIN
					UPDATE [dbo].[BillingInvoicing] 
					   SET [UpdatedDate] = GETUTCDATE(),
						   [PostedDate] = GETUTCDATE(),
						   [InvoiceStatusId] = @InvoiceStatusId,
						   [InvoiceStatus] = @InvoicedStatus,
						   [UpdatedBy] = @UpdatedBy
					 WHERE [BillingInvoicingId] = @BillingInvoicingId
				 END
				 ELSE
				 BEGIN
					UPDATE [dbo].[BillingInvoicing] 
					   SET [UpdatedDate] = GETUTCDATE(),						   						   
						   [InvoiceStatusId] = @InvoiceStatusId,
						   [InvoiceStatus] = @InvoicedStatus,
					       [UpdatedBy] = @UpdatedBy				
					 WHERE [BillingInvoicingId] = @BillingInvoicingId
				 END
			END

			SELECT TOP 1 @SubReferenceId = BII.[SubReferenceId],
			 	         @PartNumber = ITM.[partnumber]
			FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
			INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON BII.ItemMasterId = ITM.ItemMasterId
			WHERE BII.[BillingInvoicingId] = @BillingInvoicingId 

			 AND ISNULL(ITM.IsNonStock,0) = 0
			SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @ShippingPostName;
			SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', @WorkOrderNum)
			SET @TemplateBody = REPLACE(@TemplateBody, '#WoMPN#', @PartNumber)
			SET @TemplateBody = REPLACE(@TemplateBody, '#CustName#', @CustomerName)
			SET @UpdatedDate = GETUTCDATE()			
			
			EXEC [dbo].[USP_History] @ModuleId,@ReferenceId,@WOSubModuleId,@SubReferenceId,@OldValue,@NewValue,@TemplateBody,'ShippingPost',@MasterCompanyId,@UpdatedBy,@UpdatedDate,@UpdatedBy,@UpdatedDate
						
		END /****END: WORK ORDER ***/
		ELSE IF(@ModuleId = @SOModuleId)/****START: SALES ORDER ***/
		BEGIN

			SELECT @ProformaDepositAmount = SUM(ISNULL(BI.DepositAmount, 0)) - SUM(ISNULL(BI.UsedDeposit, 0))  
			FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)			
			WHERE BI.[ReferenceId] = @ReferenceId AND BI.ModuleId =  @ModuleId AND ISNULL(BI.IsPerformaInvoice, 0) = 1 

			IF(ISNULL(@IsPerformaInvoice,0) = 0)
			BEGIN					   						
				UPDATE [dbo].[BillingInvoicing] 
				SET		[UpdatedDate] = GETUTCDATE(),
						[PostedDate] = GETUTCDATE(),
						[InvoiceStatusId] = @InvoiceStatusId,
						[InvoiceStatus] = @InvoicedStatus,
						[DepositAmount] = CASE WHEN ISNULL([DepositAmount],0) >= @ProformaDepositAmount AND ISNULL(IsPerformaInvoice, 0) = 0 THEN @ProformaDepositAmount ELSE ISNULL([DepositAmount],0) END ,
						[RemainingAmount] = CASE WHEN ISNULL([DepositAmount],0) >= @ProformaDepositAmount AND ISNULL(IsPerformaInvoice, 0) = 0 THEN ISNULL([GrandTotal],0) - @ProformaDepositAmount ELSE ISNULL([GrandTotal],0) - ISNULL([DepositAmount],0) END ,
						[UpdatedBy] = @UpdatedBy					  
				 WHERE	[BillingInvoicingId] = @BillingInvoicingId

				IF(@InvoiceStatusId = @InvoicedStatusId)
				BEGIN
					IF OBJECT_ID('tempdb..#TempUpdateSOBillingDetailsForPerforma') IS NOT NULL
					BEGIN
						DROP TABLE #TempUpdateSOBillingDetailsForPerforma
					END

					CREATE TABLE #TempUpdateSOBillingDetailsForPerforma
					(
						[PKID] [BIGINT] NOT NULL IDENTITY,
						[BillingInvoicingId] [BIGINT],
						[ModuleId] [INT] NULL,
						[ReferenceId] [BIGINT] NULL,		
						[DepositAmount] [DECIMAL](18,2) NULL,
						[UsedDeposit] [DECIMAL](18,2) NULL				
					)
					 					
					INSERT INTO #TempUpdateSOBillingDetailsForPerforma([BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit])
															SELECT [BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit] 
					FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [ReferenceId] = @ReferenceId AND ModuleId = @ModuleId AND [IsPerformaInvoice] = 1 AND ISNULL([IsVersionIncrease],0) = 0

					DECLARE @SODepositAmount DECIMAL(18,2) = 0,@SOUsedDeposit DECIMAL(18,2) = 0
					DECLARE @SOTotalRecordPRo INT = 0,@SOMinIdPro BIGINT = 1

					SELECT @SODepositAmount = ISNULL([DepositAmount],0) FROM [dbo].[BillingInvoicing] WHERE [BillingInvoicingId] = @BillingInvoicingId  

					SELECT @SOTotalRecordPRo = COUNT(*), @SOMinIdPro = MIN([PKID]) FROM #TempUpdateSOBillingDetailsForPerforma    

					WHILE @SOMinIdPro <= @SOTotalRecordPRo
					BEGIN
						DECLARE @SOPendingDeposit DECIMAL(18,2)=0,@SOPerformaBillingInvoicingId BIGINT = 0
						DECLARE @SOPerformaDepositAmount DECIMAL(18,2)=0
						SELECT @SOPerformaBillingInvoicingId = [BillingInvoicingId],
								@ModuleId = [ModuleId],
								@ReferenceId = [ReferenceId], 
								@SOPerformaDepositAmount = ISNULL([DepositAmount],0),
								@SOUsedDeposit = ISNULL([UsedDeposit],0)
							FROM #TempUpdateSOBillingDetailsForPerforma WHERE [PKID] = @SOMinIdPro
			
						IF(@SODepositAmount > 0)
						BEGIN	
							SET @SOPendingDeposit = @SOPerformaDepositAmount - @SOUsedDeposit

							IF(@SOPendingDeposit > 0)
							BEGIN
								UPDATE [dbo].[BillingInvoicing] SET [UsedDeposit] = CASE WHEN @SODepositAmount >= @SOPendingDeposit THEN ISNULL([UsedDeposit], 0) + @SOPendingDeposit ELSE @SODepositAmount END
								WHERE [BillingInvoicingId] = @SOPerformaBillingInvoicingId
							END
				
							SET @SODepositAmount =  CASE WHEN @SODepositAmount >= @SOPendingDeposit THEN @SODepositAmount - @SOPendingDeposit ELSE 0 END 				
						END

						SET @SOMinIdPro = @SOMinIdPro + 1;
					END

					EXEC [dbo].[USP_UpdateDepositAmount] @BillingInvoicingId, 1

					UPDATE [dbo].[BillingInvoicing] 
					   SET [UpdatedDate] = GETUTCDATE(),
						   [PostedDate] = GETUTCDATE(),
						   [InvoiceStatusId] = @InvoiceStatusId,
						   [InvoiceStatus] = @InvoicedStatus,
						   [UpdatedBy] = @UpdatedBy,
						   IsInvoicePosted = 1,IsUpdated =1
					 WHERE [BillingInvoicingId] = @BillingInvoicingId

					 UPDATE [dbo].[BillingInvoicing] 
					    SET [IsStandardInvoicePosted] = 1
					  WHERE [ReferenceId] = @ReferenceId 
					    AND [ModuleId] = @ModuleId 
						AND [IsPerformaInvoice] = 1
				END				 
			END
			BEGIN
				 IF(@InvoiceStatusId = @InvoicedStatusId)
				 BEGIN
					UPDATE [dbo].[BillingInvoicing] 
					   SET [UpdatedDate] = GETUTCDATE(),
						   [PostedDate] = GETUTCDATE(),
						   [InvoiceStatusId] = @InvoiceStatusId,
						   [InvoiceStatus] = @InvoicedStatus,
						   [UpdatedBy] = @UpdatedBy
					 WHERE [BillingInvoicingId] = @BillingInvoicingId
				 END
				 ELSE
				 BEGIN
					UPDATE [dbo].[BillingInvoicing] 
					   SET [UpdatedDate] = GETUTCDATE(),						   						   
						   [InvoiceStatusId] = @InvoiceStatusId,
						   [InvoiceStatus] = @InvoicedStatus,
					       [UpdatedBy] = @UpdatedBy				
					 WHERE [BillingInvoicingId] = @BillingInvoicingId
				 END
			END
			
		END/****END: SALES ORDER ***/
 END   
 --COMMIT  TRANSACTION  
 END TRY           
 BEGIN CATCH      
  IF @@trancount > 0        
   --ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateCommonBillingInvoicingStatus'     
			, @ProcedureParameters VARCHAR(3000) = '@BillingInvoicingId = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
 END CATCH      
END