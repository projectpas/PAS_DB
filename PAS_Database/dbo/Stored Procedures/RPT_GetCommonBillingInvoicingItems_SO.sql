/*****************************************************************************************           
 ** File:   [RPT_GetCommonBillingInvoicingItems_SO]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get Common Billing Invoicing Items FOR SO Invoice SSRS
 ** Purpose:         
 ** Date:   05/JUN/2025     
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/JUN/2025   RAJESH GAMI   CREATED
     
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_SO] 20086,15
********************************************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems_SO]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		DECLARE @FlateRateBillingMethodId INT = (SELECT BillingMethodId FROM BillingMethod WITH(NOLOCK) WHERE Description = 'Flate Rate')
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
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
				ROW_NUMBER() OVER (PARTITION BY BII.BillingInvoicingItemId ORDER BY BI.BillingInvoicingId) as ItemNo,
                SubReferenceId = ISNULL(stock.SalesOrderPartId, sop.SalesOrderPartId),
                ItemMasterId = sop.ItemMasterId,
                ConditionId = sop.ConditionId,
                SerialNumber = sl.SerialNumber,
                PNumber = im.PartNumber,
                PNDescription = im.PartDescription,
                Notes = ISNULL(stock.Notes, sop.Notes),
                UOM = im.PurchaseUnitOfMeasure,
                Cond = c.Description,
                QtyShipped = ISNULL(BII.QtyBilled,0),
                QTYOnBACKOrder = ISNULL(sop.QtyRequested, 0) - ISNULL(BII.QtyBilled,0),
                UnitPrice = ISNULL(BII.UnitPrice, 0),
                Amount = ISNULL(BII.PartCost, 0),
                StockLineId = sl.StockLineId,
				ime.ExportECCN,
				ime.HSCode,
				sl.StockLineNumber,
				sl.ControlNumber,
				sl.IdNumber,
				ShipViaDetails = CASE 
									WHEN so.FreightBilingMethodId <> @FlateRateBillingMethodId THEN
										ISNULL((
											SELECT STRING_AGG(
												CONCAT(f.ShipViaName, ': ', FORMAT(ISNULL(f.BillingAmount, 0), '')), ', '
											) 
											FROM DBO.SalesOrderFreight f WITH(NOLOCK)
											WHERE f.SalesOrderId = so.SalesOrderId 
											  AND f.ItemMasterId = sop.ItemMasterId 
											  AND f.ConditionId = sop.ConditionId 
											  AND ISNULL(f.IsActive,0) = 1 
											  AND ISNULL(f.IsDeleted,0) = 0
										), 'NA')
									ELSE 'NA'
								END,
				MiscChargesDetails = CASE 
									WHEN so.ChargesBilingMethodId <> @FlateRateBillingMethodId THEN
										ISNULL((
											SELECT STRING_AGG(
												ct.[Name] + ':  ' + FORMAT(ISNULL(c.BillingAmount, 0), ''), ',  '
											)
											FROM dbo.SalesOrderCharges c WITH(NOLOCK) INNER JOIN dbo.ChargesTypes ct  WITH(NOLOCK) ON c.ChargesTypeId = ct.Id
											WHERE c.SalesOrderId = so.SalesOrderId 
											  AND c.ItemMasterId = sop.ItemMasterId 
											  AND c.ConditionId = sop.ConditionId 
											  AND  ISNULL(c.IsActive,0) = 1 
											  AND  ISNULL(c.IsDeleted,0) = 0
										), 'NA')
									ELSE 'NA'
								END
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
            LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON BII.StockLineId = sl.StockLineId
            WHERE BI.BillingInvoicingId = @BillingInvoicingId	  		  
		END 
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingItems_SO' 
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