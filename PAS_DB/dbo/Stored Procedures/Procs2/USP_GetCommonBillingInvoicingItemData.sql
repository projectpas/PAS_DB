/*****************************************************************************           
 ** File: [USP_GetCommonBillingInvoicingItemData]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to GET Common Billing Invoicing Data
 ** Purpose:         
 ** Date:   16/05/2025      
 ** RETURN VALUE:           
 ******************************************************************************           
 ** Change History           
 ******************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/05/2025   Moin Bloch		Created
    2    05/06/2025   RAJESH GAMI		SO implemented
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
--   EXEC [dbo].[USP_GetWorkOrderBillingInvoicingItemData] 7929,1,3193,2
********************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCommonBillingInvoicingItemData]
@SubReferenceId BIGINT = NULL,
@qtyShipped INT = NULL,
@billingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL,
@Opr INT = NULL,
@StocklineId BIGINT = NULL
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
IF(@Opr = 1)   		
		BEGIN
			DECLARE @FinalCondCert INT
			SELECT @FinalCondCert = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Final Cond/Cert'

			SELECT TOP 1 
					1 AS [ItemNo],			
					WOP.[RevisedSerialNumber] AS [SerialNumber],    			
					WOP.[RevisedPartNumber] AS [PNumber],			
					WOP.[RevisedPartDescription] AS [PNDescription],
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
					BID.[CostPlusType],
					WOF.WorkOrderPartNoId,
					WOF.WorkFlowWorkOrderId
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WO.[WorkOrderId] = WOP.[WorkOrderId]
				INNER JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOP.[ID] = WOF.[WorkOrderPartNoId]
				INNER JOIN [dbo].[BillingInvoicingItems] BID WITH(NOLOCK) ON WOP.[ID] = BID.[SubReferenceId]
				INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BID.[BillingInvoicingId] = BI.[BillingInvoicingId]
				INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WOP.[ItemMasterId] = IM.[ItemMasterId]
				 LEFT JOIN [dbo].[UnitOfMeasure] IU WITH(NOLOCK) ON IM.[ConsumeUnitOfMeasureId] = IU.[UnitOfMeasureId]
				 LEFT JOIN [dbo].[ItemMaster] IMT WITH(NOLOCK) ON WOP.[RevisedItemmasterid] = IMT.[ItemMasterId]
				  AND ISNULL(IMT.IsNonStock,0) = 0
				  LEFT JOIN [dbo].[UnitOfMeasure] IUR WITH(NOLOCK) ON IMT.[ConsumeUnitOfMeasureId] = IUR.[UnitOfMeasureId]
				 LEFT JOIN [dbo].[WorkOrderSettlementDetails] WOS WITH(NOLOCK) ON WOP.[ID] = wos.[workOrderPartNoId] AND WOS.[WorkOrderSettlementId] = @FinalCondCert
				 LEFT JOIN [dbo].[Condition] COND WITH(NOLOCK) ON WOP.[RevisedConditionId] = COND.[ConditionId]
				-- LEFT JOIN [dbo].[StockLine] SL WITH(NOLOCK) ON WOP.[StockLineId] = SL.[StockLineId]
				 --LEFT JOIN [dbo].[ItemMaster] IMV WITH(NOLOCK) ON BID.[ItemMasterId] = IMV.[ItemMasterId]
				  WHERE WOP.[ID] = @SubReferenceId AND BI.[BillingInvoicingId] = @billingInvoicingId AND ISNULL(IM.IsNonStock,0) = 0 ;	
		END
		IF(@Opr = 2)   		
		BEGIN
			SELECT ISNULL([FreightFlatBillingAmount],0) [FreightFlatBillingAmount]
			  FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) 
			 WHERE [WOPartNoId] = @SubReferenceId AND ISNULL([QuoteMethod],0) = 1
		END
	END /*********END: WORK ORDER ********/ 
	ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
	BEGIN
		 SELECT TOP 1
                Freight = CASE 
                            WHEN so.FreightBilingMethodId = 3 THEN ISNULL(so.TotalFreight, 0)
                            ELSE ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderFreight 
                                         WHERE SalesOrderId = so.SalesOrderId 
                                         AND ItemMasterId = sop.ItemMasterId 
                                         AND IsActive = 1 AND IsDeleted = 0), 0)
                          END,
                MiscCharges = CASE 
                                WHEN so.ChargesBilingMethodId = 3 THEN ISNULL(so.TotalCharges, 0)
                                ELSE ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderCharges 
                                             WHERE SalesOrderId = so.SalesOrderId 
                                             AND ItemMasterId = sop.ItemMasterId 
                                             AND IsActive = 1 AND IsDeleted = 0), 0)
                              END,
                ItemNo = 0,
                SubReferenceId = ISNULL(stock.SalesOrderPartId, sop.SalesOrderPartId),
                ItemMasterId = sop.ItemMasterId,
                ConditionId = sop.ConditionId,
                SerialNumber = sl.SerialNumber,
                PNumber = im.PartNumber,
                PNDescription = im.PartDescription,
                Notes = ISNULL(stock.Notes, sop.Notes),
                UOM = im.PurchaseUnitOfMeasure,
                Cond = c.Description,
                QtyShipped = @QtyShipped,
                QTYOnBACKOrder = ISNULL(sop.QtyRequested, 0) - @QtyShipped,
                UnitPrice = ISNULL(BII.UnitPrice, 0),
                Amount = ISNULL(BII.PartCost, 0),
                StockLineId = stock.StockLineId,
				ime.ExportECCN,
				ime.HSCode
            FROM DBO.SalesOrder so WITH (NOLOCK)
            INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON sop.SalesOrderPartId = BII.[SubReferenceId]
			INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BII.[BillingInvoicingId] = BI.[BillingInvoicingId]
            INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
			LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON im.ItemMasterId = ime.ItemMasterId
            LEFT JOIN DBO.SalesOrderStockLineV1 stock WITH (NOLOCK) ON sop.SalesOrderPartId = stock.SalesOrderPartId
            LEFT JOIN DBO.SalesOrderPartCost sopc WITH (NOLOCK) ON sop.SalesOrderPartId = sopc.SalesOrderPartId
            LEFT JOIN DBO.SalesOrderStocklineCost sosc WITH (NOLOCK) ON stock.SalesOrderStocklineId = sosc.SalesOrderStocklineId
            LEFT JOIN DBO.Condition c WITH (NOLOCK) ON sop.ConditionId = c.ConditionId
            LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON stock.StockLineId = sl.StockLineId
            WHERE sop.SalesOrderPartId = @SubReferenceId
              AND (@StocklineId IS NULL OR stock.StockLineId = @StocklineId)
	 AND ISNULL(im.IsNonStock,0) = 0
               END /*********END: WORK ORDER ********/
	

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingInvoicingItemData' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SubReferenceId, '') AS VARCHAR(100)) + 
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