/*****************************************************************************************           
 ** File:   [USP_GetCommonBillingInvoicing]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get Common Billing Invoicing
 ** Purpose:         
 ** Date:   27/06/2025      
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    27/06/2025   Moin Bloch    Created

--   EXEC [dbo].[USP_GetCommonBillingInvoicing] 20070,15
********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCommonBillingInvoicing]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
	
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN								
			SELECT BI.[BillingInvoicingId]
				  ,BI.[ModuleId]
				  ,BI.[ReferenceId]
				  ,BI.[InvoiceTypeId]
				  ,BI.[InvoiceNo]
				  ,BI.[InvoiceDate]
				  ,BI.[InvoiceTime]
				  ,BI.[PrintDate]
				  ,BI.[EmployeeId]
				  ,BI.[CurrencyId]
				  ,BI.[RevisionTypeId]
				  ,BI.[InvoiceStatusId]
				  ,BI.[InvoiceStatus]
				  ,BI.[InvoiceFilePath]
				  ,BI.[RevType]
				  ,BI.[VersionNo]
				  ,BI.[CostPlusType]
				  ,ISNULL(BI.[IsPerformaInvoice],0) [IsPerformaInvoice]
				  ,ISNULL(BI.[IsVersionIncrease],0) [IsVersionIncrease]
				  ,BI.[PostedDate]
				  ,ISNULL(BI.[SubTotal],0) [SubTotal]
				  ,ISNULL(BI.[OtherTax],0) [OtherTax]
				  ,ISNULL(BI.[SalesTax],0) [SalesTax]
				  ,ISNULL(BI.[DepositAmount],0) [DepositAmount]
				  ,ISNULL(BI.[GrandTotal],0) [GrandTotal]
				  ,ISNULL(BI.[IsInvoicePosted],0) [IsInvoicePosted]
				  ,ISNULL(BI.[UsedDeposit],0) [UsedDeposit]
				  ,ISNULL(BI.[ProformaDeposit],0) [ProformaDeposit]
				  ,BI.[Notes]
				  ,BI.[WorkOrderShippingId]
				  ,BI.[ManagementStructureId]
				  ,BI.[MasterCompanyId]
				  ,BI.[CreatedBy]
				  ,BI.[UpdatedBy]
				  ,BI.[CreatedDate]
				  ,BI.[UpdatedDate]
				  ,BI.[IsActive]
				  ,BI.[IsDeleted]
				  ,ISNULL(BI.[IsReversedJE],0) [IsReversedJE]
				  ,BI.[QuickBooksReferenceId]
				  ,ISNULL(BI.[IsUpdated],0) [IsUpdated]
				  ,BI.[LastSyncDate]
				  ,BI.[SyncToken]
				  ,ISNULL(BI.[IsCreatedFromQuote],0) [IsCreatedFromQuote]
				  ,ISNULL(BI.[IsQuickBookGeneratedInvoice],0) [IsQuickBookGeneratedInvoice]
				  ,WO.[CustomerId]
				  ,ISNULL(BI.[RemainingAmount],0) [RemainingAmount]
			  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) 
			  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]
			  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;
			  				  		  
		END 
		ELSE IF(@ModuleId = @SOModuleId) /*********START: SASLES ORDER ********/
		BEGIN
				SELECT BI.[BillingInvoicingId]
				  ,BI.[ModuleId]
				  ,BI.[ReferenceId]
				  ,BI.[InvoiceTypeId]
				  ,BI.[InvoiceNo]
				  ,BI.[InvoiceDate]
				  ,BI.[InvoiceTime]
				  ,BI.[PrintDate]
				  ,BI.[EmployeeId]
				  ,BI.[CurrencyId]
				  ,BI.[RevisionTypeId]
				  ,BI.[InvoiceStatusId]
				  ,BI.[InvoiceStatus]
				  ,BI.[InvoiceFilePath]
				  ,BI.[RevType]
				  ,BI.[VersionNo]
				  ,BI.[CostPlusType]
				  ,ISNULL(BI.[IsPerformaInvoice],0) [IsPerformaInvoice]
				  ,ISNULL(BI.[IsVersionIncrease],0) [IsVersionIncrease]
				  ,BI.[PostedDate]
				  ,ISNULL(BI.[SubTotal],0) [SubTotal]
				  ,ISNULL(BI.[OtherTax],0) [OtherTax]
				  ,ISNULL(BI.[SalesTax],0) [SalesTax]
				  ,ISNULL(BI.[DepositAmount],0) [DepositAmount]
				  ,ISNULL(BI.[GrandTotal],0) [GrandTotal]
				  ,ISNULL(BI.[IsInvoicePosted],0) [IsInvoicePosted]
				  ,ISNULL(BI.[UsedDeposit],0) [UsedDeposit]
				  ,ISNULL(BI.[ProformaDeposit],0) [ProformaDeposit]
				  ,BI.[Notes]
				  ,BI.[WorkOrderShippingId]
				  ,BI.[ManagementStructureId]
				  ,BI.[MasterCompanyId]
				  ,BI.[CreatedBy]
				  ,BI.[UpdatedBy]
				  ,BI.[CreatedDate]
				  ,BI.[UpdatedDate]
				  ,BI.[IsActive]
				  ,BI.[IsDeleted]
				  ,ISNULL(BI.[IsReversedJE],0) [IsReversedJE]
				  ,BI.[QuickBooksReferenceId]
				  ,ISNULL(BI.[IsUpdated],0) [IsUpdated]
				  ,BI.[LastSyncDate]
				  ,BI.[SyncToken]
				  ,ISNULL(BI.[IsCreatedFromQuote],0) [IsCreatedFromQuote]
				  ,ISNULL(BI.[IsQuickBookGeneratedInvoice],0) [IsQuickBookGeneratedInvoice]
				  ,SO.[CustomerId]
				  ,ISNULL(BI.[RemainingAmount],0) [RemainingAmount]
			  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) 
			  INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BI.[ReferenceId] = SO.[SalesOrderId]
			  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;

		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingInvoicingItems' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
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