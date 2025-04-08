/*****************************************************************************           
 ** File:   [USP_GetWorkOrderBillingInvoicingItemData]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to GET Work Order Billing Invoicing Data
 ** Purpose:         
 ** Date:   27/03/2025      
 ** RETURN VALUE:           
 ******************************************************************************           
 ** Change History           
 ******************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    27/03/2025   Moin Bloch    Created
     
--   EXEC [dbo].[USP_GetWorkOrderBillingInvoicingItemData] 7929,1,3193
--   EXEC [dbo].[USP_GetWorkOrderBillingInvoicingItemData] 7930,1,3193
********************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderBillingInvoicingItemData]
@WorkOrderPartId BIGINT = NULL,
@qtyShipped INT = NULL,
@billingInvoicingId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	    
		DECLARE @FinalCondCert INT
	    SELECT @FinalCondCert = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Final Cond/Cert'

		SELECT TOP 1 
			1 AS [ItemNo],
			CASE WHEN BI.[IsVersionIncrease] IS NOT NULL AND BI.[IsVersionIncrease] = 1 THEN
			     CASE WHEN BI.[RevisedSerialNumber] IS NOT NULL THEN BI.[RevisedSerialNumber]
					  WHEN WOP.[RevisedSerialNumber] IS NOT NULL THEN WOP.[RevisedSerialNumber]
					  ELSE SL.[SerialNumber]
				  END
				  ELSE 
				  CASE 
				      WHEN WOP.[RevisedSerialNumber] IS NOT NULL THEN WOP.[RevisedSerialNumber]
					  ELSE SL.[SerialNumber]
				  END
			END AS [SerialNumber],    
			CASE 
				WHEN BI.[IsVersionIncrease] IS NOT NULL AND BI.[IsVersionIncrease] = 1 AND BI.[ItemMasterId] > 0 THEN IMV.[PartNumber]
				WHEN IMT.[ItemMasterId] IS NOT NULL THEN WOP.[RevisedPartNumber]
				ELSE IM.[PartNumber]
			END AS [PNumber],
			CASE 
				WHEN BI.[IsVersionIncrease] IS NOT NULL AND BI.[IsVersionIncrease] = 1 AND BI.[ItemMasterId] > 0 THEN IMV.[PartDescription]
				WHEN IMT.[ItemMasterId] IS NOT NULL THEN WOP.[RevisedPartDescription]
				ELSE IM.[PartDescription]
			END AS [PNDescription],
			wo.[Notes],
			CASE 
				WHEN IUR.[UnitOfMeasureId] IS NOT NULL THEN 
					CASE 
						WHEN IU.[UnitOfMeasureId] IS NOT NULL THEN IU.[ShortName]
						ELSE ''
					END
				ELSE 
					CASE 
						WHEN IUR.[UnitOfMeasureId] IS NOT NULL THEN IUR.[ShortName]
						ELSE ''
					END
			END UOM,
			CASE 
				WHEN BID.[ConditionId] IS NOT NULL THEN 
					(SELECT TOP 1 
						CASE 
							WHEN c.[Memo] <> '' THEN c.[Memo] 
							ELSE c.[Code] 
						END
					 FROM  [dbo].[Condition] c WITH(NOLOCK)
					 WHERE c.[ConditionId] = BID.[ConditionId] 
					 AND c.[MasterCompanyId] = BID.[MasterCompanyId])
				WHEN WOS.[WorkOrderSettlementId] IS NOT NULL THEN WOS.[conditionName]
				ELSE 
					CASE 
						WHEN COND.[ConditionId] IS NOT NULL THEN COND.[Memo]
					ELSE ''
				END
			END [Cond],
			ISNULL(@qtyShipped,0) [QtyShipped],
			(WOP.[Quantity] - ISNULL(@qtyShipped,0)) [QTYOnBACKOrder],
			0 [Amount],
			BID.[UnitPrice],
			BI.[CostPlusType] 
		FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WO.[WorkOrderId] = WOP.[WorkOrderId]
		INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] BID WITH(NOLOCK) ON WOP.[ID] = BID.[WorkOrderPartId]
		INNER JOIN [dbo].[WorkOrderBillingInvoicing] BI WITH(NOLOCK) ON BID.[BillingInvoicingId] = BI.[BillingInvoicingId]
		INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WOP.[ItemMasterId] = IM.[ItemMasterId]
		 LEFT JOIN [dbo].[UnitOfMeasure] IU WITH(NOLOCK) ON IM.[ConsumeUnitOfMeasureId] = IU.[UnitOfMeasureId]
		 LEFT JOIN [dbo].[ItemMaster] IMT WITH(NOLOCK) ON WOP.[RevisedItemmasterid] = IMT.[ItemMasterId]
		 LEFT JOIN [dbo].[UnitOfMeasure] IUR WITH(NOLOCK) ON IMT.[ConsumeUnitOfMeasureId] = IUR.[UnitOfMeasureId]
		 LEFT JOIN [dbo].[WorkOrderSettlementDetails] WOS WITH(NOLOCK) ON WOP.[ID] = wos.[workOrderPartNoId] AND WOS.[WorkOrderSettlementId] = @FinalCondCert
		 LEFT JOIN [dbo].[Condition] COND WITH(NOLOCK) ON WOP.[RevisedConditionId] = COND.[ConditionId]
		 LEFT JOIN [dbo].[StockLine] SL WITH(NOLOCK) ON WOP.[StockLineId] = SL.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] IMV WITH(NOLOCK) ON BI.[ItemMasterId] = IMV.[ItemMasterId]
		WHERE WOP.[ID] = @WorkOrderPartId AND BI.[BillingInvoicingId] = @billingInvoicingId;

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingInvoicingItemData' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderPartId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@qtyShipped, '') AS VARCHAR(100)) +
													 '@Parameter3 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100)) 
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