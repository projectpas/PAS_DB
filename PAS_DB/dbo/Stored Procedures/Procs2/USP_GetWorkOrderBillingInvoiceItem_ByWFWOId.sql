/*****************************************************************************           
 ** File:   [USP_GetWorkOrderBillingInvoiceItem_ByWFWOId]           
 ** Author:   Devendra Shekh 
 ** Description: This stored procedure is used to Get WorkOrder Billing Invoicing Item 
 ** Date:   22-April-2025 
 ** RETURN VALUE:           
 ******************************************************************************           
 ** Change History           
 ******************************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    22-April-2025		Devendra Shekh		Created
	2    13-June-2025		Moin Bloch		    Removed old to new table
		
EXEC [dbo].[USP_GetWorkOrderBillingInvoiceItem_ByWFWOId] 8936, 8686
********************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderBillingInvoiceItem_ByWFWOId]
@WorkOrderId BIGINT = NULL,
@WorkFlowWorkOrderId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		-- COMMENT DUE TO OLD TABLE

		--SELECT	TOP 1 BII.[WOBillingInvoicingItemId]
		--		,BII.[BillingInvoicingId]
		--		,BII.[NoofPieces]
		--		,BII.[WorkOrderPartId]
		--		,BII.[ItemMasterId]
		--		,BII.[MasterCompanyId]
		--		,BII.[CreatedBy]
		--		,BII.[UpdatedBy]
		--		,BII.[CreatedDate]
		--		,BII.[UpdatedDate]
		--		,BII.[IsActive]
		--		,BII.[IsDeleted]
		--		,ISNULL(BII.[UnitPrice],0) [UnitPrice]
		--		,ISNULL(BII.[MaterialCost],0) [MaterialCost]
		--		,ISNULL(BII.[LaborCost],0) [LaborCost]
		--		,ISNULL(BII.[MiscCharges],0) [MiscCharges]
		--		,ISNULL(BII.[Freight],0) [Freight]
		--		,ISNULL(BII.[SubTotal],0) [SubTotal]
		--		,BII.[TaxRate]
		--		,ISNULL(BII.[SalesTax],0) [SalesTax]
		--		,BII.[OtherTaxRate]
		--		,ISNULL(BII.[OtherTax],0)  [OtherTax]
		--		,ISNULL(BII.[GrandTotal],0) [GrandTotal]
		--		,BII.[PDFPath]
		--		,BII.[VersionNo]
		--		,ISNULL(BII.[IsVersionIncrease],0) [IsVersionIncrease]
		--		,BII.[ConditionId]
		--		,ISNULL(BII.[IsPerformaInvoice],0) [IsPerformaInvoice]
		--		,ISNULL(BII.[IsInvoicePosted],0) [IsInvoicePosted]
		--FROM [dbo].[WorkOrderBillingInvoicing] BI WITH(NOLOCK)
		--INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] BII WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId] AND ISNULL(BII.IsVersionIncrease, 0) = 0 AND ISNULL(BII.IsPerformaInvoice, 0) = 0
		--INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON BII.WorkOrderPartId = WF.WorkOrderPartNoId	
		--WHERE	BI.WorkOrderId = @WorkOrderId AND WF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
		--		 AND ISNULL(BI.IsVersionIncrease, 0) = 0 AND ISNULL(BI.IsPerformaInvoice, 0) = 0
		--ORDER BY BII.CreatedDate DESC

		-- New Table
		DECLARE @WOModuleId INT = 0

		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		SELECT	TOP 1 
				BII.[BillingInvoicingId]				
		FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
		INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId] AND BII.[ModuleId] = @WOModuleId AND ISNULL(BII.[IsVersionIncrease], 0) = 0 AND ISNULL(BII.[IsPerformaInvoice], 0) = 0
		INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON BII.[SubReferenceId] = WF.[WorkOrderPartNoId]	
		WHERE BI.[ReferenceId] = @WorkOrderId AND WF.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND ISNULL(BI.[IsVersionIncrease], 0) = 0 AND ISNULL(BI.[IsPerformaInvoice], 0) = 0
		
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingInvoicingItems' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
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