/*****************************************************************************************           
 ** File:   [USP_GetCommonBillingInvoicingItems]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get Common Billing Invoicing Items
 ** Purpose:         
 ** Date:   19/05/2025      
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    19/05/2025   Moin Bloch    Created
    2    06/06/2025   Rajesh Gami   Created    
	3    10/06/2025   Moin Bloch    Added CustomerId
--   EXEC [dbo].[USP_GetCommonBillingInvoicingItems] 20070,15
********************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCommonBillingInvoicingItems]
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
				DECLARE @FinalCondCert INT
				SELECT @FinalCondCert = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Final Cond/Cert'

			--SELECT TOP 1 BI.[BillingInvoicingId]
			--			,BI.[ReferenceId]
			--			,WOW.[WorkFlowWorkOrderId]
			--			,BII.[SubReferenceId]
			--			,BII.[ItemMasterId]
			--			,BI.[InvoiceTypeId]
			--			,BI.[InvoiceNo]
			--			,WO.[CustomerId]
			--			,BI.[InvoiceDate]
			--			,BI.[InvoiceTime]
			--			,BI.[PrintDate]
			--			,NULL [ShipDate]  
			--			,BII.QtyBilled                         --[NoofPieces]
			--			,BI.[EmployeeId]
			--			,'' [GateStatus]   
			--			,BID.[SoldToCustomerId]
			--			,BID.[SoldToSiteId]
			--			,BID.[ShipToCustomerId]
			--			,BID.[ShipToSiteId]
			--			,BID.[ShipToAttention]
			--			,BI.[ManagementStructureId]
			--			,BI.[Notes]
			--			,BI.[CostPlusType]
			--			,BII.[IsTotalCheck]                     --[TotalWorkOrder]   
			--			,BII.[TotalBillingCostPercent]          --[TotalWorkOrderValue] 
			--			,BII.[IsMaterialCheck]                  --[Material]  
			--			,BII.[MaterialCostPercent]              --[MaterialValue]  
			--			,BII.[IsLaborCheck]                     --[LaborOverHead]   
			--			,BII.[LaborCostPercent]                 --[LaborOverHeadValue] 
			--			,BII.[IsMiscChargesCheck]               --[MiscCharges]       
			--			,BII.[MiscChargesCostPercent]           --[MiscChargesValue]  
			--			,BII.[IsPerformaInvoice]                --[ProForma]           
			--			,0 [PartialInvoice]      ------------------------
			--			,0 [CostPlusRateCombo]     ------------------------
			--			,BID.[CustomerDomensticShippingShipViaId] [ShipViaId]
			--			,BID.[WayBillRef]
			--			,'' [Tracking]  ------------------------
			--			,BI.[MasterCompanyId]
			--			,BI.[CreatedBy]
			--			,BI.[UpdatedBy]
			--			,BI.[CreatedDate]
			--			,BI.[UpdatedDate]
			--			,BI.[IsActive]
			--			,BI.[IsDeleted]
			--			,BI.[CurrencyId]
			--			,0 [AvailableCredit]          ------------------------
			--			,BII.[TotalBillingCost]           --[TotalWorkOrderCost]
			--			,BII.[TotalBillingCostPlus]       --[TotalWorkOrderCostPlus]
			--			,ISNULL(BII.[MaterialCost],0) [MaterialCost]
			--			,ISNULL(BII.[MaterialCostPlus],0) [MaterialCostPlus]
			--			,ISNULL(BII.[LaborCost],0) [LaborOverHeadCost]
			--			,ISNULL(BII.[LaborCostPlus],0) [LaborOverHeadCostPlus]
			--			,ISNULL(BII.[MiscCharges],0) [MiscChargesCost]
			--			,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
			--			,ISNULL(BI.[GrandTotal],0) [GrandTotal]
			--			,BI.[RevisionTypeId]
			--			,BI.[WorkOrderShippingId]
			--			,BI.[InvoiceStatus]
			--			,BI.[InvoiceFilePath]
			--			,BI.[RevType]
			--			,BI.[VersionNo]
			--			,ISNULL(BI.[IsVersionIncrease],0) [IsVersionIncrease]
			--			,ISNULL(BII.[Freight],0) [FreightCost]
			--			,ISNULL(BII.[FreightCostPlus],0) [FreightCostPlus]
			--			,ISNULL(BII.[Freight],0) [Freight]
			--			,ISNULL(BII.[FreightCostPercent],0) [FreightValue]
			--			,BID.[CustomerDomensticShippingShipViaId]
			--			,BID.[ShipAccountInfo]   [ShippingAccountInfo]
			--			,0 [RemainingAmount]   ------------------------
			--			,BI.[PostedDate]
			--			,ISNULL(BI.[SalesTax],0) [TaxRate]
			--			,ISNULL(BI.[SalesTax],0) [SalesTax]
			--			,ISNULL(BI.[OtherTax],0) [OtherTax]
			--			,ISNULL(BI.[SubTotal],0) [SubTotal]
			--			,0 [IsCustomerShipping]  ------------------------
			--			,0 [CreditMemoUsed]      ------------------------
			--			,BIi.[ConditionId]
			--			,SOP.[RevisedSerialNumber]
			--			,ISNULL(BI.[IsPerformaInvoice],0) [IsPerformaInvoice]
			--			,ISNULL(BI.[DepositAmount],0) [DepositAmount]
			--			,ISNULL(BI.[IsInvoicePosted],0) [IsInvoicePosted]
			--			,ISNULL(BI.[UsedDeposit],0) [UsedDeposit]
			--			,ISNULL(BI.[ProformaDeposit],0) [ProformaDeposit]
			--			,ISNULL(BI.[IsUpdated],0) [IsUpdated]			    
			--			,ISNULL(BI.[isCreatedFromQuote],0) [isCreatedFromQuote]
			--			,ISNULL(BI.[IsQuickBookGeneratedInvoice],0) [IsQuickBookGeneratedInvoice]
			--			,ISNULL(BI.[IsReversedJE],0) [IsReversedJE]
			--			,BI.[QuickBooksReferenceId]
			--			,BI.[LastSyncDate]
			--			,BI.[SyncToken]
			-- FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
			--INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]
			--INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
			--INNER JOIN [dbo].[WorkOrderPartNumber] SOP WITH(NOLOCK) ON BI.[ReferenceId] = SOP.[WorkOrderId]
			--INNER JOIN [dbo].[WorkOrderWorkFlow] WOW WITH(NOLOCK) ON BII.[SubReferenceId] = WOW.[WorkOrderPartNoId]	
			--INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]	
			--INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
			-- LEFT JOIN [dbo].[UnitOfMeasure] IU WITH(NOLOCK) ON ITM.[ConsumeUnitOfMeasureId] = IU.[UnitOfMeasureId]
			-- LEFT JOIN [dbo].[Condition] CP WITH(NOLOCK) ON SOP.[ConditionId] = BII.[ConditionId]
			-- LEFT JOIN [dbo].[StockLine] SL WITH(NOLOCK) ON SOP.[StockLineId] = SL.[StockLineId]
			--  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;

			--SELECT BII.[BillingInvoicingItemId]
			--	  ,BII.[BillingInvoicingId]
			--	  ,BII.[QtyBilled] [NoofPieces]  ------------------------
			--	  ,BII.[SubReferenceId]
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
			--	  ,BII.[SalesTaxPercent] 
			--	  ,ISNULL(BII.[SalesTax],0) [SalesTax]
			--	  ,BII.[OtherTaxPercent]
			--	  ,ISNULL(BII.[OtherTax],0)  [OtherTax]
			--	  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
			--	  ,BII.[PDFPath]
			--	  ,BII.[VersionNo]
			--	  ,ISNULL(BII.[IsVersionIncrease],0) [IsVersionIncrease]
			--	  ,BII.[ConditionId]
			--	  ,ISNULL(BII.[IsPerformaInvoice],0) [IsPerformaInvoice]
			--	  ,BI.[IsInvoicePosted]  
			-- FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
			--INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]	
			--  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;
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
			  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) 
			  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]
			  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;

			SELECT BII.[BillingInvoicingItemId]
				  ,BII.[BillingInvoicingId]
				  ,BII.[ModuleId]
				  ,BII.[ReferenceId]
				  ,BII.[SubModuleId]
				  ,BII.[SubReferenceId]
				  ,BII.[ItemMasterId]
				  ,BII.[StocklineId]
				  ,BII.[ConditionId]
				  ,BII.[CostPlusType]
				  ,ISNULL(BII.[UnitPrice],0) [UnitPrice]
				  ,ISNULL(BII.[QtyBilled],0) [QtyBilled]
				  ,ISNULL(BII.[PartCost],0) [PartCost]
				  ,ISNULL(BII.[IsTotalCheck],0) [IsTotalCheck]
				  ,ISNULL(BII.[TotalBillingCost],0) [TotalBillingCost]
				  ,ISNULL(BII.[TotalBillingCostPercent],0) [TotalBillingCostPercent]
				  ,ISNULL(BII.[TotalBillingCostPlus],0) [TotalBillingCostPlus]
				  ,ISNULL(BII.[IsMaterialCheck],0) [IsMaterialCheck]
				  ,ISNULL(BII.[MaterialCost],0) [MaterialCost]
				  ,ISNULL(BII.[MaterialCostPercent],0) [MaterialCostPercent]
				  ,ISNULL(BII.[MaterialCostPlus],0) [MaterialCostPlus]
				  ,ISNULL(BII.[IsLaborCheck],0) [IsLaborCheck]
				  ,ISNULL(BII.[LaborCost],0) [LaborCost]
				  ,ISNULL(BII.[LaborCostPercent],0) [LaborCostPercent]
				  ,ISNULL(BII.[LaborCostPlus],0) [LaborCostPlus]
				  ,ISNULL(BII.[IsFreightCheck],0) [IsFreightCheck]
				  ,ISNULL(BII.[Freight],0) [Freight] 
				  ,ISNULL(BII.[FreightCostPercent],0) [FreightCostPercent]
				  ,ISNULL(BII.[FreightCostPlus],0) [FreightCostPlus]
				  ,ISNULL(BII.[IsMiscChargesCheck],0) [IsMiscChargesCheck]
				  ,ISNULL(BII.[MiscCharges],0) [MiscCharges]
				  ,ISNULL(BII.[MiscChargesCostPercent],0) [MiscChargesCostPercent]
				  ,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
				  ,ISNULL(BII.[SubTotal],0) [SubTotal] 
				  ,ISNULL(BII.[SalesTaxPercent],0) [SalesTaxPercent]
				  ,ISNULL(BII.[SalesTax],0) [SalesTax]
				  ,ISNULL(BII.[OtherTaxPercent],0) [OtherTaxPercent]
				  ,ISNULL(BII.[OtherTax],0) [OtherTax]
				  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
				  ,BII.[PDFPath]
				  ,BII.[VersionNo]
				  ,ISNULL(BII.[IsVersionIncrease],0) [IsVersionIncrease]
				  ,ISNULL(BII.[IsPerformaInvoice],0) [IsPerformaInvoice]
				  ,BII.[MasterCompanyId]
				  ,BII.[CreatedBy]
				  ,BII.[UpdatedBy]
				  ,BII.[CreatedDate]
				  ,BII.[UpdatedDate]
				  ,BII.[IsActive]
				  ,BII.[IsDeleted]
				  ,WOP.[RevisedPartNumber] [PNumber]			
				  ,WOP.[RevisedPartDescription]  [PNDescription]
				  ,WOP.[RevisedSerialNumber]  [SerialNumber]    						 
				  ,CASE WHEN BII.[ConditionId] IS NOT NULL THEN 
						(SELECT TOP 1 CASE WHEN c.[Memo] <> '' THEN c.[Memo] ELSE c.[Code] END FROM  [dbo].[Condition] c WITH(NOLOCK) 
						   WHERE c.[ConditionId] = BII.[ConditionId] AND c.[MasterCompanyId] = BII.[MasterCompanyId])
						WHEN WOS.[WorkOrderSettlementId] IS NOT NULL THEN WOS.[conditionName]
						ELSE 
							CASE 		WHEN COND.[ConditionId] IS NOT NULL THEN COND.[Memo]
								ELSE '' 
							END
						END [Cond]								
				  ,WO.[Notes]
			   FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
			  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BII.[ReferenceId] = WO.[WorkOrderId]
			  INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID]
			  INNER JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOP.[ID] = WOF.[WorkOrderPartNoId]
			   LEFT JOIN [dbo].[WorkOrderSettlementDetails] WOS WITH(NOLOCK) ON WOP.[ID] = wos.[workOrderPartNoId] AND WOS.[WorkOrderSettlementId] = @FinalCondCert
			   LEFT JOIN [dbo].[Condition] COND WITH(NOLOCK) ON WOP.[RevisedConditionId] = COND.[ConditionId]
			  WHERE BII.[BillingInvoicingId] = @BillingInvoicingId;
		  		  
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
			  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) 
			  INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BI.[ReferenceId] = SO.[SalesOrderId]
			  WHERE BI.[BillingInvoicingId] = @BillingInvoicingId;

			SELECT BII.[BillingInvoicingItemId]
				  ,BII.[BillingInvoicingId]
				  ,BII.[ModuleId]
				  ,BII.[ReferenceId]
				  ,BII.[SubModuleId]
				  ,BII.[SubReferenceId]
				  ,BII.[ItemMasterId]
				  ,BII.[StocklineId]
				  ,BII.[ConditionId]
				  ,BII.[CostPlusType]
				  ,ISNULL(BII.[UnitPrice],0) [UnitPrice]
				  ,ISNULL(BII.[QtyBilled],0) [QtyBilled]
				  ,ISNULL(BII.[PartCost],0) [PartCost]
				  ,ISNULL(BII.[IsTotalCheck],0) [IsTotalCheck]
				  ,ISNULL(BII.[TotalBillingCost],0) [TotalBillingCost]
				  ,ISNULL(BII.[TotalBillingCostPercent],0) [TotalBillingCostPercent]
				  ,ISNULL(BII.[TotalBillingCostPlus],0) [TotalBillingCostPlus]
				  ,ISNULL(BII.[IsMaterialCheck],0) [IsMaterialCheck]
				  ,ISNULL(BII.[MaterialCost],0) [MaterialCost]
				  ,ISNULL(BII.[MaterialCostPercent],0) [MaterialCostPercent]
				  ,ISNULL(BII.[MaterialCostPlus],0) [MaterialCostPlus]
				  ,ISNULL(BII.[IsLaborCheck],0) [IsLaborCheck]
				  ,ISNULL(BII.[LaborCost],0) [LaborCost]
				  ,ISNULL(BII.[LaborCostPercent],0) [LaborCostPercent]
				  ,ISNULL(BII.[LaborCostPlus],0) [LaborCostPlus]
				  ,ISNULL(BII.[IsFreightCheck],0) [IsFreightCheck]
				  ,ISNULL(BII.[Freight],0) [Freight] 
				  ,ISNULL(BII.[FreightCostPercent],0) [FreightCostPercent]
				  ,ISNULL(BII.[FreightCostPlus],0) [FreightCostPlus]
				  ,ISNULL(BII.[IsMiscChargesCheck],0) [IsMiscChargesCheck]
				  ,ISNULL(BII.[MiscCharges],0) [MiscCharges]
				  ,ISNULL(BII.[MiscChargesCostPercent],0) [MiscChargesCostPercent]
				  ,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
				  ,ISNULL(BII.[SubTotal],0) [SubTotal] 
				  ,ISNULL(BII.[SalesTaxPercent],0) [SalesTaxPercent]
				  ,ISNULL(BII.[SalesTax],0) [SalesTax]
				  ,ISNULL(BII.[OtherTaxPercent],0) [OtherTaxPercent]
				  ,ISNULL(BII.[OtherTax],0) [OtherTax]
				  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
				  ,BII.[PDFPath]
				  ,BII.[VersionNo]
				  ,ISNULL(BII.[IsVersionIncrease],0) [IsVersionIncrease]
				  ,ISNULL(BII.[IsPerformaInvoice],0) [IsPerformaInvoice]
				  ,BII.[MasterCompanyId]
				  ,BII.[CreatedBy]
				  ,BII.[UpdatedBy]
				  ,BII.[CreatedDate]
				  ,BII.[UpdatedDate]
				  ,BII.[IsActive]
				  ,BII.[IsDeleted]
				  ,WOP.[PartNumber] [PNumber]			
				  ,WOP.[PartDescription]  [PNDescription]
				  ,''  [SerialNumber]    						 
				  ,COND.Description [Cond]								
				  ,WO.[Notes]
			   FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
			  INNER JOIN [dbo].[SalesOrder] WO WITH(NOLOCK) ON BII.[ReferenceId] = WO.[SalesOrderId]
			  INNER JOIN [dbo].[SalesOrderPartV1] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[SalesOrderPartId]
			  LEFT JOIN [dbo].[Condition] COND WITH(NOLOCK) ON BII.ConditionId = COND.[ConditionId]
			  WHERE BII.[BillingInvoicingId] = @BillingInvoicingId;
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