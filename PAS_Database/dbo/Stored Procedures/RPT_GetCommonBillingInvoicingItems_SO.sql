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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    05/JUN/2025   RAJESH GAMI		CREATED
	2    18/JUN/2025   RAJESH GAMI		Proforma Amount Related Fixed 
	3    22/JUN/2025   RAJESH GAMI		Charges Type Issue Fixed 
	4    05/JUL/2025   RAJESH GAMI		added weight, and dimension fields for Commercial Invoice (Get from the Part table)
	5    17/JUL/2025   RAJESH GAMI		SO: Freight Charges Amount Issue Fixed
	6    17/JUL/2025   VISHAL SUTHAR	Trimming the Notes field with "<p></p>" tag in the beginning and end.
	7    12/Jan/2026   VISHAL SUTHAR	Use Serial Number from BillingInvoicingItems if exists
	8    15/May/2026   Bhargav Saliya	UOM Changes [PN-15067]
	9    18/06/2026    Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same
	10   25/06/2026    Bhargav saliya   Get Consume UOM
	11   08/07/2026    Bhargav saliya   did formatting for billing amount 
	12   13/07/2026    Bhargav saliya   did formatting for MiscChargesDetails amount (PN-17258)
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_SO] 9399,10
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
			IF OBJECT_ID(N'tempdb..#tmprRptInvoicingItem') IS NOT NULL
			BEGIN
				DROP TABLE #tmprRptInvoicingItem
			END
			SELECT 
			 
					--Freight = CASE
					--			WHEN so.FreightBilingMethodId = 3 THEN ISNULL(so.TotalFreight, 0)
					--			ELSE ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderFreight 
					--						 WHERE SalesOrderId = so.SalesOrderId 
					--						 AND ItemMasterId = sop.ItemMasterId 
					--						 AND IsActive = 1 AND IsDeleted = 0), 0)
					--		  END,
					--MiscCharges = CASE
					--				WHEN so.ChargesBilingMethodId = 3 THEN ISNULL(so.TotalCharges, 0)
					--				ELSE ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderCharges 
					--							 WHERE SalesOrderId = so.SalesOrderId 
					--							 AND ItemMasterId = sop.ItemMasterId 
					--							 AND IsActive = 1 AND IsDeleted = 0), 0)
					--			  END,
					Freight =bii.FreightCostPlus,
					MiscCharges = bii.MiscChargesCostPlus,
					ROW_NUMBER() OVER (PARTITION BY BII.BillingInvoicingItemId ORDER BY BI.BillingInvoicingId) as RowNo,
					SubReferenceId = ISNULL(stock.SalesOrderPartId, sop.SalesOrderPartId),
					ItemMasterId = sop.ItemMasterId,
					ConditionId = sop.ConditionId,
					SerialNumber = CASE WHEN BII.SerialNumber IS NOT NULL THEN UPPER(ISNULL(BII.SerialNumber,'')) ELSE UPPER(ISNULL(sl.SerialNumber,'')) END,
					PNumber = UPPER(im.PartNumber),
					PNDescription = UPPER(im.PartDescription),
					--Notes = ISNULL(stock.Notes, sop.Notes),
					Notes = CASE 
					  WHEN LOWER(LEFT(ISNULL(stock.Notes, sop.Notes), 3)) = '<p>'
						   AND LOWER(RIGHT(ISNULL(stock.Notes, sop.Notes), 4)) = '</p>'
					  THEN SUBSTRING(ISNULL(stock.Notes, sop.Notes), 4, LEN(ISNULL(stock.Notes, sop.Notes)) - 7)
					  ELSE ISNULL(stock.Notes, sop.Notes)
					END,
					UOM = UPPER(im.ConsumeUnitOfMeasure),
					Cond = UPPER(c.Description),
					QtyShipped = (CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(BII.QtyBilled, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(BII.QtyBilled, 0),im.[StockUnitOfMeasure],im.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) END),
					QTYOnBACKOrder = (CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sop.QtyRequested, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sop.QtyRequested, 0),im.[StockUnitOfMeasure],im.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) END) - (CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(BII.QtyBilled, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(BII.QtyBilled, 0),im.[StockUnitOfMeasure],im.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) END),
					UnitPrice = (CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(BII.UnitPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(BII.UnitPrice, 0),im.[StockUnitOfMeasure],im.[ConsumeUnitOfMeasure],1,so.MasterCompanyId) END),
					Amount = (CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(BII.PartCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(BII.PartCost, 0),im.[StockUnitOfMeasure],im.[ConsumeUnitOfMeasure],1,so.MasterCompanyId) END),
					StockLineId = sl.StockLineId,
					ISNULL(UPPER(SOP.ECCN),'-')ExportECCN,
					ISNULL(UPPER(SOP.HSCODE),'-')HSCode,
					UPPER(ISNULL(sl.StockLineNumber,''))StockLineNumber,
					UPPER(ISNULL(sl.ControlNumber,''))ControlNumber,
					UPPER(ISNULL(sl.IdNumber,''))IdNumber,
					ShipViaDetails = CASE 
					--WHEN BI.IsPerformaInvoice = 1 THEN '-'
										WHEN so.FreightBilingMethodId <> @FlateRateBillingMethodId THEN
											ISNULL((
												SELECT STRING_AGG(
													UPPER(CONCAT(f.ShipViaName, ': ', FORMAT(ISNULL(f.BillingAmount, 0), '0.00'))), ', '
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
					--WHEN BI.IsPerformaInvoice = 1 THEN '-'
										WHEN so.ChargesBilingMethodId <> @FlateRateBillingMethodId THEN
											ISNULL((
												SELECT STRING_AGG(
													UPPER(ct.[ChargeType]) + ':  ' + FORMAT(ISNULL(c.BillingAmount, 0), '0.00'), ',  '
												)
												FROM dbo.SalesOrderCharges c WITH(NOLOCK) INNER JOIN dbo.Charge ct  WITH(NOLOCK) ON c.ChargesTypeId = ct.ChargeId
												WHERE c.SalesOrderId = so.SalesOrderId 
												  AND c.ItemMasterId = sop.ItemMasterId 
												  AND c.ConditionId = sop.ConditionId 
												  AND  ISNULL(c.IsActive,0) = 1 
												  AND  ISNULL(c.IsDeleted,0) = 0
											), 'NA')
										ELSE 'NA'
									END,
									BI.[BillingInvoicingId],
									ROW_NUMBER() OVER (PARTITION BY BII.SubreferenceId,BII.ItemMasterId ORDER BY BI.BillingInvoicingId) as RowData,
									ISNULL(CAST(SOP.[Weight] as NVARCHAR),'-') as [Weight],
									ISNULL(CAST(SOP.SizeLength as NVARCHAR),'-') as [DimensionL],
									ISNULL(CAST(SOP.SizeWidth as NVARCHAR),'-')  as DimensionW,
									ISNULL(CAST(SOP.SizeHeight as NVARCHAR),'-')  as DimensionH
				INTO #tmprRptInvoicingItem
				FROM DBO.SalesOrder so WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON sop.SalesOrderPartId = BII.[SubReferenceId]
				INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BII.[BillingInvoicingId] = BI.[BillingInvoicingId]
				INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
				--LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON im.ItemMasterId = ime.ItemMasterId
				LEFT JOIN DBO.SalesOrderStockLineV1 stock WITH (NOLOCK) ON sop.SalesOrderPartId = stock.SalesOrderPartId
				LEFT JOIN DBO.SalesOrderPartCost sopc WITH (NOLOCK) ON sop.SalesOrderPartId = sopc.SalesOrderPartId
				LEFT JOIN DBO.SalesOrderStocklineCost sosc WITH (NOLOCK) ON stock.SalesOrderStocklineId = sosc.SalesOrderStocklineId
				LEFT JOIN DBO.Condition c WITH (NOLOCK) ON sop.ConditionId = c.ConditionId
				LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON BII.StockLineId = sl.StockLineId
				WHERE BI.BillingInvoicingId = @BillingInvoicingId	 
				--UPDATE #tmprRptInvoicingItem SET Freight = 0, MiscCharges = 0 WHERE RowData > 1
				SELECT 
						Freight,
						MiscCharges,
						RowNo,
						SubReferenceId,
						ItemMasterId,
						ConditionId,
						SerialNumber,
						PNumber,
						PNDescription,
						Notes,
						UOM,
						Cond,
						QtyShipped,
						QTYOnBACKOrder,
						UnitPrice,
						Amount,
						StockLineId,
						ExportECCN,
						HSCode,
						StockLineNumber,
						ControlNumber,
						IdNumber,
						ShipViaDetails,
						MiscChargesDetails,
						BillingInvoicingId,
						[Weight],
						[DimensionL],
						DimensionW,
						DimensionH,
						ROW_NUMBER() OVER (ORDER BY BillingInvoicingId) AS ItemNo
					FROM #tmprRptInvoicingItem
					WHERE RowNo = 1;
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