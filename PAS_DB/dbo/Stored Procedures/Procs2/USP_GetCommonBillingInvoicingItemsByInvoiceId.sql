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

********************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCommonBillingInvoicingItemsByInvoiceId]
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
				  ,CST.[QuickBooksReferenceId] [ContactId]
				  ,ITM.[QuickBooksReferenceId] [LineItemID]
			   FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
			  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BII.[ReferenceId] = WO.[WorkOrderId]
			  INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID]
			  INNER JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOP.[ID] = WOF.[WorkOrderPartNoId]
			  INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON ITM.[ItemMasterId] = BII.[ItemMasterId]
			  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = WO.[CustomerId]
			   LEFT JOIN [dbo].[WorkOrderSettlementDetails] WOS WITH(NOLOCK) ON WOP.[ID] = wos.[workOrderPartNoId] AND WOS.[WorkOrderSettlementId] = @FinalCondCert
			   LEFT JOIN [dbo].[Condition] COND WITH(NOLOCK) ON WOP.[RevisedConditionId] = COND.[ConditionId]
			   WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsVersionIncrease],0) = 0 AND ISNULL(BII.[IsPerformaInvoice],0) = 0		  		  
		END 
		
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCommonBillingInvoicingItemsByInvoiceId' 
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