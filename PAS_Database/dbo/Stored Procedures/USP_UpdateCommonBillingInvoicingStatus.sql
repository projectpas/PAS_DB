/*************************************************************             
 ** File:   [USP_UpdateCommonBillingInvoicingStatus]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Update Common Billing Invoicing Status
 ** Purpose:           
 ** Date:   05/06/2025
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				-------------------------------            
    1    05/06/2025   Moin Bloch		Created
	2    10/06/2025   Rajesh Gami		Implemented SO
EXEC  [dbo].[USP_UpdateCommonBillingInvoicingStatus] 4349
**************************************************************/ 
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
 BEGIN TRANSACTION  
 BEGIN
 		DECLARE @InvoicedStatusId INT = 0
		DECLARE @InvoicedStatus VARCHAR(50)=''
		SELECT @InvoicedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Invoiced'
		SELECT @InvoicedStatus = [Status] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [InvoiceStatusId] = @InvoiceStatusId

		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN		
	
			DECLARE @WorkOrderTypeId BIGINT = 0
			DECLARE @WorkOrderNum VARCHAR(50)='',@CustomerName VARCHAR(50)=''			 
			DECLARE @DistributionMasterId  INT = 0,@DistributionSetupId INT = 0
			DECLARE @ShippingPostName VARCHAR(50)='ShippingPost'
			DECLARE @oldValue VARCHAR(50) = 'False';
            DECLARE @newValue VARCHAR(50) = 'True';
			DECLARE @ValidBatchDetails BIT = 1
			DECLARE @Customer INT,@Internal INT
			DECLARE @DistributionCode VARCHAR(50)=''		
			DECLARE @IsRestrict BIT;
			DECLARE @IsAccountByPass BIT;					

			SELECT @Customer = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';
			SELECT @Internal = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal';				

			IF(ISNULL(@IsPerformaInvoice,0) = 0)
			BEGIN					   						
				SELECT @WorkOrderTypeId = WO.[WorkOrderTypeId],  
					   @CustomerName = CU.[Name],
					   @WorkOrderNum = WO.[WorkOrderNum]
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
				INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON WO.[CustomerId] = CU.[CustomerId]
				WHERE [WorkOrderId] = @ReferenceId

				UPDATE [dbo].[BillingInvoicing] 
				   SET [UpdatedDate] = GETUTCDATE(),
					   [PostedDate] = GETUTCDATE(),
					   [InvoiceStatusId] = @InvoiceStatusId,
					   [InvoiceStatus] = @InvoicedStatus,
					   [UpdatedBy] = @UpdatedBy
				 WHERE [BillingInvoicingId] = @BillingInvoicingId

				IF(@InvoiceStatusId = @InvoicedStatusId)
				BEGIN
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
								EXEC [dbo].[USP_BatchTriggerBasedonDistribution] @DistributionMasterId,@ReferenceId,0,0,@BillingInvoicingId,0,0,'',1,0,'WO',@MasterCompanyId,@UpdatedBy;
							END
						END
						-- WO Customer
						IF(@WorkOrderTypeId = @Internal)
						BEGIN
							EXEC [dbo].[USP_GetSubLadgerGLAccountRestriction] @DistributionCode, @MasterCompanyId, 0, @UpdatedBy, @IsRestrict = @IsRestrict OUTPUT, @IsAccountByPass = @IsAccountByPass OUTPUT
							IF(@IsAccountByPass <> 1)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO] @DistributionMasterId,@ReferenceId,0,0,@BillingInvoicingId,0,0,'',1,0,'WO',@MasterCompanyId,@UpdatedBy;
							END
						END
					END
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
						   [UpdatedBy] = @UpdatedBy
					 WHERE [BillingInvoicingId] = @BillingInvoicingId
				 END
			END

			
		END /*********END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId)/*********START: SALES ORDER ********/
		BEGIN
			UPDATE [dbo].[BillingInvoicing] 
					   SET [UpdatedDate] = GETUTCDATE(),
						   [PostedDate] = GETUTCDATE(),
						   [InvoiceStatusId] = @InvoiceStatusId,
						   [InvoiceStatus] = @InvoicedStatus,
						   [UpdatedBy] = @UpdatedBy,
						   IsInvoicePosted = 1,IsUpdated =1
					 WHERE [BillingInvoicingId] = @BillingInvoicingId
		END/*********END: SALES ORDER ********/
 END   
 COMMIT  TRANSACTION  
 END TRY           
 BEGIN CATCH      
  IF @@trancount > 0        
   ROLLBACK TRAN;    
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