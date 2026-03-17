
/*****************************************************************************************           
 ** File:   [RPT_GetCommonBillingInvoicingItems]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get Common Billing Invoicing Items
 ** Purpose:         
 ** Date:   02/06/2025      
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/06/2025   Moin Bloch    Created
	2    18/06/2025   Moin Bloch    Fix For Condition in pdf
	3    18/06/2025   Moin Bloch    Added WorkFlowWorkOrderId
	4    24/06/2025   Moin Bloch    Fix For Duplicate Part
    5	 27/02/2026   Ayushi Patel  PN-15602 PN-15604 return ItemNo for WoInvoice Report 
	6    17/03/2026   Ayushi Patel  PN-15746 Return CustomerReference partwise 
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems] 89,15
********************************************************************************************/
CREATE PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems]
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
			
	    SELECT DISTINCT BII.[BillingInvoicingItemId]
			  ,BII.[BillingInvoicingId]
			  ,BII.[ModuleId]
			  ,BII.[ReferenceId]
			  ,BII.[SubModuleId]
			  ,BII.[SubReferenceId]
			  ,BII.[ItemMasterId]
			  ,BII.[StocklineId]
			  ,BII.[ConditionId]
			  ,UPPER(BII.[CostPlusType]) [CostPlusType]
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
			  ,ISNULL(BII.[SalesTax],0) + ISNULL(BII.[OtherTax],0) [Taxes]
			  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
			  ,BII.[PDFPath]
			  ,BII.[VersionNo] 
			  ,ISNULL(BII.[IsVersionIncrease],0) [IsVersionIncrease]
			  ,ISNULL(BII.[IsPerformaInvoice],0) [IsPerformaInvoice]
			  ,BII.[MasterCompanyId]			  
			  ,UPPER(WOP.[RevisedPartNumber]) [PNumber]			
			  ,UPPER(WOP.[RevisedPartDescription])  [PNDescription]
			  ,UPPER(WOP.[RevisedSerialNumber])  [SerialNumber]
			  ,CASE WHEN WOP.[RevisedConditionId] IS NOT NULL THEN  CASE WHEN COND.[Memo] <> '' THEN UPPER(COND.[Memo]) ELSE UPPER(COND.[Code]) END
			        WHEN WOS.[WorkOrderSettlementId] IS NOT NULL THEN UPPER(WOS.[conditionName])
				ELSE (SELECT TOP 1 CASE WHEN c.[Memo] <> '' THEN UPPER(c.[Memo]) ELSE UPPER(c.[Code]) END FROM [dbo].[Condition] c WITH(NOLOCK) 
					   WHERE c.[ConditionId] = BII.[ConditionId] AND c.[MasterCompanyId] = BII.[MasterCompanyId])
				END [Cond]				  			  							
			  ,WO.[Notes]
			  ,UOM.[ShortName] [PurchaseUnitOfMeasure]
			  ,BII.WorkFlowWorkOrderId
			  ,CASE WHEN ISNULL(BII.[IsMiscChargesCheck],0) = 0 THEN 0
			        WHEN ISNULL(BII.[IsPerformaInvoice],0) = 1 THEN 0 
				    ELSE ISNULL(BII.[MiscChargesCostPlus],0)
			   END [IsCharges]			
			  ,ISNULL(BI.[IsCreatedFromQuote],0) [IsCreatedFromQuote]
			  ,ROW_NUMBER() OVER (ORDER BY BII.[BillingInvoicingId]) AS ItemNo
			  ,WOP.CustomerReference
		   FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
		  INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BII.[BillingInvoicingId] = BI.[BillingInvoicingId] AND BI.ModuleId = @WOModuleId
		  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BII.[ReferenceId] = WO.[WorkOrderId] AND BII.ModuleId = @WOModuleId
		  INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID] AND BII.ModuleId = @WOModuleId
		  INNER JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOP.[ID] = WOF.[WorkOrderPartNoId]
		   LEFT JOIN [dbo].[WorkOrderSettlementDetails] WOS WITH(NOLOCK) ON WOP.[ID] = wos.[workOrderPartNoId] AND WOS.[WorkOrderSettlementId] = @FinalCondCert
		   LEFT JOIN [dbo].[Condition] COND WITH(NOLOCK) ON WOP.[RevisedConditionId] = COND.[ConditionId]
		   LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON WOP.[RevisedItemmasterid] = ITM.[ItemMasterId]
		   LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH(NOLOCK) ON [ITM].[PurchaseUnitOfMeasureId] = UOM.[UnitOfMeasureId]
		   --LEFT JOIN [dbo].[WorkOrderCharges] WOC WITH(NOLOCK) ON BII.[WorkFlowWorkOrderId] = WOC.[WorkFlowWorkOrderId] AND woc.[IsDeleted] = 0  AND BII.ModuleId = @WOModuleId
		  WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND BII.ModuleId = @WOModuleId
		  		  
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