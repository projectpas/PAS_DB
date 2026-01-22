/*****************************************************************************           
 ** File:   [USP_GetWorkOrderBillingInvoicingItems]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get WorkOrder Billing Invoicing Items
 ** Purpose:         
 ** Date:   08/04/2025      
 ** RETURN VALUE:           
 ******************************************************************************           
 ** Change History           
 ******************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/04/2025   Moin Bloch    Created
	2    08-07-2025   Moin Bloch    SP NOT IN USE
     
--   EXEC [dbo].[USP_GetWorkOrderBillingInvoicingItems] 3239
********************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderBillingInvoicingItems]
@BillingInvoicingId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		
		SELECT * FROM dbo.BillingInvoicing WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId;

		SELECT * FROM dbo.BillingInvoicingItems WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId;
	--SELECT TOP 1 BI.[BillingInvoicingId]
	--		    ,BI.[WorkOrderId]
	--		    ,BI.[WorkFlowWorkOrderId]
	--		    ,BI.[WorkOrderPartNoId]
	--		    ,BI.[ItemMasterId]
	--		    ,BI.[InvoiceTypeId]
	--		    ,BI.[InvoiceNo]
	--		    ,BI.[CustomerId]
	--		    ,BI.[InvoiceDate]
	--		    ,BI.[InvoiceTime]
	--		    ,BI.[PrintDate]
	--		    ,BI.[ShipDate]
	--		    ,BI.[NoofPieces]
	--		    ,BI.[EmployeeId]
	--		    ,BI.[GateStatus]
	--		    ,BI.[SoldToCustomerId]
	--		    ,BI.[SoldToSiteId]
	--		    ,BI.[ShipToCustomerId]
	--		    ,BI.[ShipToSiteId]
	--		    ,BI.[ShipToAttention]
	--		    ,BI.[ManagementStructureId]
	--		    ,BI.[Notes]
	--		    ,BI.[CostPlusType]
	--		    ,ISNULL(BI.[TotalWorkOrder],0) [TotalWorkOrder]
	--		    ,BI.[TotalWorkOrderValue]
	--		    ,ISNULL(BI.[Material],0) [Material]
	--		    ,BI.[MaterialValue]
	--		    ,ISNULL(BI.[LaborOverHead],0) [LaborOverHead]
	--		    ,BI.[LaborOverHeadValue]
	--		    ,ISNULL(BI.[MiscCharges],0) [MiscCharges]
	--		    ,BI.[MiscChargesValue]
	--		    ,ISNULL(BI.[ProForma],0) [ProForma]
	--		    ,ISNULL(BI.[PartialInvoice],0) [PartialInvoice]
	--		    ,ISNULL(BI.[CostPlusRateCombo],0) [CostPlusRateCombo]
	--		    ,BI.[ShipViaId]
	--		    ,BI.[WayBillRef]
	--		    ,BI.[Tracking]
	--		    ,BI.[MasterCompanyId]
	--		    ,BI.[CreatedBy]
	--		    ,BI.[UpdatedBy]
	--		    ,BI.[CreatedDate]
	--		    ,BI.[UpdatedDate]
	--		    ,BI.[IsActive]
	--		    ,BI.[IsDeleted]
	--		    ,BI.[CurrencyId]
	--		    ,ISNULL(BI.[AvailableCredit],0) [AvailableCredit]
	--		    ,ISNULL(BI.[TotalWorkOrderCost],0) [TotalWorkOrderCost]
	--		    ,ISNULL(BI.[TotalWorkOrderCostPlus],0) [TotalWorkOrderCostPlus]
	--		    ,ISNULL(BI.[MaterialCost],0) [MaterialCost]
	--		    ,ISNULL(BI.[MaterialCostPlus],0) [MaterialCostPlus]
	--		    ,ISNULL(BI.[LaborOverHeadCost],0) [LaborOverHeadCost]
	--		    ,ISNULL(BI.[LaborOverHeadCostPlus],0) [LaborOverHeadCostPlus]
	--		    ,ISNULL(BI.[MiscChargesCost],0) [MiscChargesCost]
	--		    ,ISNULL(BI.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
	--		    ,ISNULL(BI.[GrandTotal],0) [GrandTotal]
	--		    ,BI.[RevisionTypeId]
	--		    ,BI.[WorkOrderShippingId]
	--		    ,BI.[InvoiceStatus]
	--		    ,BI.[InvoiceFilePath]
	--		    ,BI.[RevType]
	--		    ,BI.[VersionNo]
	--		    ,ISNULL(BI.[IsVersionIncrease],0) [IsVersionIncrease]
	--		    ,ISNULL(BI.[FreightCost],0) [FreightCost]
	--		    ,ISNULL(BI.[FreightCostPlus],0) [FreightCostPlus]
	--		    ,ISNULL(BI.[Freight],0) [Freight]
	--		    ,ISNULL(BI.[FreightValue],0) [FreightValue]
	--		    ,BI.[CustomerDomensticShippingShipViaId]
	--		    ,BI.[ShippingAccountInfo]
	--		    ,ISNULL(BI.[RemainingAmount],0) [RemainingAmount]
	--		    ,BI.[PostedDate]
	--		    ,ISNULL(BI.[TaxRate],0) [TaxRate]
	--		    ,ISNULL(BI.[SalesTax],0) [SalesTax]
	--		    ,ISNULL(BI.[OtherTax],0) [OtherTax]
	--		    ,ISNULL(BI.[SubTotal],0) [SubTotal]
	--		    ,ISNULL(BI.[IsCustomerShipping],0) [IsCustomerShipping]
	--		    ,ISNULL(BI.[CreditMemoUsed],0) [CreditMemoUsed]
	--		    ,BI.[ConditionId]
	--		    ,BI.[RevisedSerialNumber]
	--		    ,ISNULL(BI.[IsPerformaInvoice],0) [IsPerformaInvoice]
	--		    ,ISNULL(BI.[DepositAmount],0) [DepositAmount]
	--		    ,ISNULL(BI.[IsInvoicePosted],0) [IsInvoicePosted]
	--		    ,ISNULL(BI.[UsedDeposit],0) [UsedDeposit]
	--		    ,ISNULL(BI.[ProformaDeposit],0) [ProformaDeposit]
	--		    ,ISNULL(BI.[IsUpdated],0) [IsUpdated]			    
	--		    ,ISNULL(BI.[isCreatedFromQuote],0) [isCreatedFromQuote]
	--		    ,ISNULL(BI.[IsQuickBookGeneratedInvoice],0) [IsQuickBookGeneratedInvoice]
	--			,ISNULL(BI.[IsReversedJE],0) [IsReversedJE]
	--			,BI.[QuickBooksReferenceId]
	--			,BI.[LastSyncDate]
	--			,BI.[SyncToken]
	-- FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
	--INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]
	--INNER JOIN [dbo].[WorkOrderPartNumber] SOP WITH(NOLOCK) ON BI.[WorkOrderId] = SOP.[WorkOrderId]
	--INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
	-- LEFT JOIN [dbo].[UnitOfMeasure] IU WITH(NOLOCK) ON ITM.[ConsumeUnitOfMeasureId] = IU.[UnitOfMeasureId]
	-- LEFT JOIN [dbo].[Condition] CP WITH(NOLOCK) ON BI.[ConditionId] = CP.[ConditionId]
	-- LEFT JOIN [dbo].[StockLine] SL WITH(NOLOCK) ON SOP.[StockLineId] = SL.[StockLineId]
	--  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;

	--SELECT BII.[BillingInvoicingItemId]
	--	  ,BII.[BillingInvoicingId]
	--	  --,BII.[NoofPieces]
	--	  --,BII.[WorkOrderPartId]
	--	  ,BII.[ItemMasterId]
	--	  ,BII.[MasterCompanyId]
	--	  ,BII.[CreatedBy]
	--	  ,BII.[UpdatedBy]
	--	  ,BII.[CreatedDate]
	--	  ,BII.[UpdatedDate]
	--	  ,BII.[IsActive]
	--	  ,BII.[IsDeleted]
	--	  ,ISNULL(BII.[UnitPrice],0) [UnitPrice]
	--	  ,ISNULL(BII.[MaterialCost],0) [MaterialCost]
	--	  ,ISNULL(BII.[LaborCost],0) [LaborCost]
	--	  ,ISNULL(BII.[MiscCharges],0) [MiscCharges]
	--	  ,ISNULL(BII.[Freight],0) [Freight]
	--	  ,ISNULL(BII.[SubTotal],0) [SubTotal]
	--	  ,BII.[TaxRate]
	--	  ,ISNULL(BII.[SalesTax],0) [SalesTax]
	--	  ,BII.[OtherTaxRate]
	--	  ,ISNULL(BII.[OtherTax],0)  [OtherTax]
	--	  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
	--	  ,BII.[PDFPath]
	--	  ,BII.[VersionNo]
	--	  ,ISNULL(BII.[IsVersionIncrease],0) [IsVersionIncrease]
	--	  ,BII.[ConditionId]
	--	  ,ISNULL(BII.[IsPerformaInvoice],0) [IsPerformaInvoice]
 --         ,ISNULL(BI.[IsInvoicePosted],0) [IsInvoicePosted]
	-- FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
	--INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]	
	--  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;


	 
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