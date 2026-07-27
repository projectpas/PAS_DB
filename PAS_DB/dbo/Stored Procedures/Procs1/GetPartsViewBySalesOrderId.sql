/*************************************************************           
 ** File:   [GetPartsViewBySalesOrderId]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get SO analysis data
 ** Purpose:         
 ** Date:   09/27/2024
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/27/2024   Vishal Suthar		Created
    2    10/17/2024   Vishal Suthar		Modified to make use of new SO Part tables
    3    11/28/2024   Vishal Suthar		Fixed an issue with Analysis data
    4    11/29/2024   Vishal Suthar		Fixed an issue with Tax Amount Calculation
    5    12/02/2024   Vishal Suthar		Fixed an issue with Freight calculation
	6    07-07-2025   Moin Bloch		Changed Old To New Billing Table
	7    08-07-2025   Moin Bloch		Fix For Approval Status
	8    30-07-2025   RAJESH GAMI		Fixed: Getting Freight and CHarges amount from the billing invoicing if any invoice generated otherwise as it is & Check the invoice is generated for the same SO or not.
	9    01-09-2025   BHARGAV SALIYA	Fixed: Quote Number Binded issue in Analysis tab.
	10   19-SEP-2025  RAJESH GAMI	    Added return field: netSalesPricePerUnit
	11   30-SEP-2025  Vishal Suthar	    Fix for showing Freight Cost in Freight
	12    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	13    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	14    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from part join and WHERE clause.

EXEC [dbo].[GetPartsViewBySalesOrderId]  879
**************************************************************/
CREATE   PROCEDURE [dbo].[GetPartsViewBySalesOrderId]
    @SalesOrderId INT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN	
	  	
		DECLARE @SOModuleId INT; 
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		DECLARE @IsInvoiceGenerated BIT = CASE WHEN (SELECT TOP 1 BillingInvoicingId FROM DBO.BillingInvoicing WITH(NOLOCK) WHERE ModuleId = @SOModuleId AND ReferenceId = @SalesOrderId AND ISNULL(IsVersionIncrease,0) = 0 AND ISNULL(IsPerformaInvoice,0) = 0 ) > 0 THEN 1 ELSE 0 END
		DECLARE @SentForInternalApproval INT = 1
        DECLARE @SubmitInternalApproval INT = 2
        DECLARE @SentForCustomerApproval INT = 3
        DECLARE @SubmitCustomerApproval INT = 4
        DECLARE @Approved INT = 5
		
		CREATE TABLE #ProcedureOutput (
			SalesTax DECIMAL(18, 2),
			OtherTax DECIMAL(18, 2),
			TotalTax DECIMAL(18, 2)
		);

		CREATE TABLE #TempJoinData (
			Param1 INT,
			Param2 INT,
			Param3 INT
		);

		-- Populate with data from the JOIN
		INSERT INTO #TempJoinData (Param1, Param2, Param3)
		SELECT so.SalesOrderId, part.SalesOrderPartId, so.CustomerId
		FROM DBO.SalesOrder so WITH(NOLOCK)
		INNER JOIN DBO.SalesOrderPartV1 part WITH(NOLOCK) ON so.SalesOrderId = part.SalesOrderId
		WHERE part.SalesOrderId = @SalesOrderId AND part.IsDeleted = 0;

		-- Temporary table to hold tax amounts
		CREATE TABLE #TempTaxAmount (
			PartId INT,
			SalesTaxPercentage DECIMAL(18, 2)
		);

		-- Cursor to iterate over the joined data
		DECLARE @Param1 INT, @Param2 INT, @Param3 INT;
		DECLARE @TaxAmount DECIMAL(18, 2);

		DECLARE cur CURSOR FOR
		SELECT Param1, Param2, Param3
		FROM #TempJoinData;

		OPEN cur;

		FETCH NEXT FROM cur INTO @Param1, @Param2, @Param3;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Clear previous procedure output
			DELETE FROM #ProcedureOutput;

			INSERT INTO #ProcedureOutput (SalesTax, OtherTax, TotalTax)
			EXEC dbo.USP_GetCustomerTax_Information_ProductSale_SO_Analysis @Param1, @Param2, @Param3;

			-- Insert the tax amount into the temporary table
			INSERT INTO #TempTaxAmount
			SELECT @Param2, SalesTax FROM #ProcedureOutput;

			FETCH NEXT FROM cur INTO @Param1, @Param2, @Param3;
		END;

		CLOSE cur;
		DEALLOCATE cur;

		SELECT DISTINCT
			part.SalesOrderId salesOrderId,
			part.SalesOrderPartId salesOrderPartId,
			so.SalesOrderQuoteId salesOrderQuoteId,
			part.ItemMasterId itemMasterId,
			stk.StockLineId stockLineId,
			ISNULL(qs.StockLineNumber, '') AS stockLineNumber,
			part.FxRate fxRate,
			CASE WHEN stk.SalesOrderStocklineId IS NOT NULL THEN stk.QtyOrder ELSE part.QtyOrder END qty,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.UnitSalesPrice ELSE SOPC.UnitSalesPrice END AS unitSalePrice,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.MarkUpPercentage ELSE SOPC.MarkUpPercentage END markUpPercentage,
			0 AS salesBeforeDiscount,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.DiscountPercentage ELSE SOPC.DiscountPercentage END discount,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.DiscountAmount ELSE SOPC.DiscountAmount END discountAmount,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.NetSaleAmount ELSE SOPC.NetSaleAmount END netSales,
			part.MasterCompanyId masterCompanyId,
			part.CreatedBy createdBy,
			part.CreatedDate createdDate,
			part.UpdatedBy updatedBy,
			part.UpdatedDate updatedDate,
			itemMaster.PartNumber partNumber,
			itemMaster.PartDescription partDescription,
			itemMaster.IsOEM isOEM,
			itemMaster.IsPMA AS isPMA,
			itemMaster.IsDER isDER,
			CASE WHEN stk.SalesOrderStocklineId IS NOT NULL THEN 'S' ELSE 'I' END methodType,
			'' method,
			ISNULL(qs.IsSerialized, 0) AS isSerialized,
			ISNULL(qs.SerialNumber, '') AS serialNumber,
			ISNULL(qs.ControlNumber, '') AS controlNumber,
			0 grossSalePricePerUnit,
			0 grossSalePrice,
			so.OpenDate openDate,
			-- Implement the custom function for tax calculation in SQL
			t.SalesTaxPercentage AS taxPercentage,
			'' AS taxType,
			SOPC.TaxAmount AS taxAmount,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.MarginAmount ELSE SOPC.MarginAmount END markupPerUnit,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.UnitCost ELSE SOPC.UnitCost END AS unitCost,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.UnitSalesPriceExtended ELSE SOPC.UnitSalesPriceExtended END salesPriceExtended,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.MarkUpAmount ELSE SOPC.MarkUpAmount END markupExtended,
			0 salesDiscountExtended,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.NetSaleAmount ELSE SOPC.NetSaleAmount END netSalePriceExtended,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.UnitCostExtended ELSE SOPC.UnitCostExtended END AS unitCostExtended,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.MarginAmount ELSE SOPC.MarginAmount END AS marginAmount,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.MarginAmount ELSE SOPC.MarginAmount END marginAmountExtended,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.MarginPercentage ELSE SOPC.MarginPercentage END AS marginPercentage,
			ISNULL(cur.Code, '') AS currency,
			part.ConditionId conditionId,
			ISNULL(cp.Description, '') AS conditionDescription,
			ISNULL(qs.IdNumber, '') AS idNumber,
			so.SalesOrderNumber salesOrderNumber,
			ISNULL(q.SalesOrderQuoteNumber, '') AS salesOrderQuoteNumber,
			ISNULL(CONVERT(VARCHAR, q.OpenDate), '') AS quoteDate,
			ISNULL(qs.QuantityAvailable, 0) AS qtyAvailable,
			ISNULL(iu.ShortName, '') AS uom,
			--ISNULL(rPart.QtyToReserve, NULL) AS qtyReserved,
			ISNULL(stk.QtyReserved, NULL) AS qtyReserved,
			--ISNULL(st.Name, '') AS [status],			
			CASE WHEN sp.ApprovalActionId =  @SentForInternalApproval THEN 'Send for Internal Approval'
			     WHEN sp.ApprovalActionId =  @SubmitInternalApproval THEN 'Submitted for Internal Approval'
				 WHEN sp.ApprovalActionId =  @SentForCustomerApproval THEN 'Send for Customer Approval'
				 WHEN sp.ApprovalActionId =  @SubmitCustomerApproval THEN 'Submitted for Cust Approval'
				 WHEN sp.ApprovalActionId =  @Approved THEN 'Approved'
			ELSE 'PENDING' END AS [status],
			CASE WHEN so.StatusId = 2 THEN 1 ELSE 0 END AS isApproved, -- Assuming 2 is Approved status (replace with appropriate constant)
			so.CustomerReference AS customerReference,
			ISNULL(imx.ExportECCN, '') AS eccn,
			ISNULL(imx.ITARNumber, '') AS itar,
			ISNULL(um.ShortName, '') AS uomName,
			part.Notes notes,
			-- Handle VersionNumber logic with appropriate SQL
			--dbo.GenerateVersionNumber(so.Version) AS VersionNumber,
			so.VersionNumber AS versionNumber,
			CASE WHEN sob.BillingInvoicingItemId > 0 THEN ISNULL(sob.MiscChargesCostPlus,0) ELSE SOPC.MiscCharges END AS misc,
			CASE WHEN sob.BillingInvoicingItemId > 0 THEN ISNULL(sob.MiscChargesCostPlus,0) ELSE CASE WHEN so.ChargesBilingMethodId = 3 THEN 0 ELSE (SELECT ISNULL(SUM(SOCC.ExtendedCost), 0) FROM DBO.SalesOrderCharges SOCC WHERE SOCC.SalesOrderPartId = part.SalesOrderPartId) END END AS miscCost,
			--(part.QtyOrder * part.UnitSalesPricePerUnit) + part.TaxAmount + ISNULL(SUM(ch.BillingAmount), 0) AS TotalSales,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.NetSaleAmount ELSE SOPC.NetSaleAmount END AS totalSales,
			CASE WHEN sob.BillingInvoicingItemId > 0 THEN ISNULL(sob.FreightCostPlus,0)  ELSE CASE WHEN so.FreightBilingMethodId = 3 THEN 0 ELSE (SELECT ISNULL(SUM(SOFF.Amount), 0) FROM DBO.SalesOrderFreight SOFF WHERE SOFF.SalesOrderPartId = part.SalesOrderPartId) END END AS freightCost,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.UnitSalesPrice ELSE SOPC.UnitSalesPrice END unitSalesPricePerUnit,
			CASE WHEN sob.BillingInvoicingItemId > 0 THEN ISNULL(sob.MiscChargesCostPlus,0) ELSE so.TotalCharges END totalCharges,
			CASE WHEN sob.BillingInvoicingItemId > 0 THEN ISNULL(sob.FreightCostPlus,0) ELSE  so.TotalFreight END totalFreight,
			so.ChargesBilingMethodId chargesBilingMethodId,
			so.FreightBilingMethodId freightBilingMethodId,
			--CASE WHEN sob.BillingInvoicingItemId IS NOT NULL THEN ISNULL(sob.FreightCostPlus, 0) ELSE 
			--	CASE 
			--		WHEN so.FreightBilingMethodId = 3 THEN 0 
			--		ELSE ISNULL((SELECT SUM(b.Amount)
			--					FROM DBO.SalesOrderFreight b WITH (NOLOCK)
			--					WHERE b.SalesOrderId = @SalesOrderId AND b.IsActive = 1 AND b.IsDeleted = 0
			--						AND b.ItemMasterId = part.ItemMasterId AND b.ConditionId = part.ConditionId), 0)
			--		END
			--	END AS freight,
			ISNULL((SELECT SUM(b.Amount) FROM DBO.SalesOrderFreight b WITH (NOLOCK) WHERE b.SalesOrderId = @SalesOrderId AND b.IsActive = 1 AND b.IsDeleted = 0 AND b.ItemMasterId = part.ItemMasterId AND b.ConditionId = part.ConditionId), 0) AS freight,
			0 AS sobillingInvoicingItemId,
			@IsInvoiceGenerated isInvoiceGenerated,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SOSC.NetSaleAmountPerUnit, 0) ELSE ISNULL(SOPC.NetSaleAmountPerUnit, 0) END AS netSalesPricePerUnit
		FROM DBO.SalesOrder so WITH(NOLOCK)
		INNER JOIN DBO.SalesOrderPartV1 part WITH(NOLOCK) ON so.SalesOrderId = part.SalesOrderId
		LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH(NOLOCK) ON stk.SalesOrderPartId = part.SalesOrderPartId
		LEFT JOIN DBO.StockLine qs WITH(NOLOCK) ON stk.StockLineId = qs.StockLineId
		LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = part.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
		INNER JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN DBO.ItemMasterExportInfo imx WITH (NOLOCK) ON part.ItemMasterId = imx.ItemMasterId
		LEFT JOIN DBO.[Condition] cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
		LEFT JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuotePartId = part.SalesOrderQuotePartId
		LEFT JOIN DBO.SalesOrderQuote q WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = q.SalesOrderQuoteId
		LEFT JOIN DBO.UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
		LEFT JOIN DBO.SalesOrderReserveParts rPart WITH (NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId
		LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
		LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
		LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON so.CustomerId = cf.CustomerId
		LEFT JOIN DBO.Currency cur WITH (NOLOCK) ON part.CurrencyId = cur.CurrencyId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus st WITH (NOLOCK) ON so.StatusId = st.Id
	    LEFT JOIN DBO.SalesOrderApproval sp WITH (NOLOCK) ON part.SalesOrderPartId = sp.SalesOrderPartId AND sp.SalesOrderId = @SalesOrderId AND sp.IsDeleted = 0 AND sp.IsActive =1
		LEFT JOIN DBO.BillingInvoicingItems sob WITH (NOLOCK) ON part.SalesOrderPartId = sob.SubReferenceId AND stk.StockLineId = sob.StockLineId AND ISNULL(sob.IsVersionIncrease,0) = 0 AND ISNULL(sob.IsPerformaInvoice,0) = 0  AND sob.[ModuleId] =@SOModuleId
		LEFT JOIN DBO.BillingInvoicing sbi WITH (NOLOCK) ON sob.BillingInvoicingId = sbi.BillingInvoicingId AND sbi.ReferenceId = @SalesOrderId AND ISNULL(sbi.IsPerformaInvoice,0) = 0 AND sbi.[ModuleId] =@SOModuleId
		LEFT JOIN DBO.SalesOrderFreight f WITH (NOLOCK) ON so.SalesOrderId = f.SalesOrderId AND f.ItemMasterId = part.ItemMasterId AND f.ConditionId = part.ConditionId AND f.IsActive = 1 AND f.IsDeleted = 0
		LEFT JOIN DBO.SalesOrderCharges ch WITH (NOLOCK) ON so.SalesOrderId = ch.SalesOrderId AND ch.ItemMasterId = part.ItemMasterId AND ch.ConditionId = part.ConditionId AND ch.IsActive = 1 AND ch.IsDeleted = 0
		LEFT JOIN #TempTaxAmount t ON part.SalesOrderPartId = t.PartId
		WHERE part.SalesOrderId = @SalesOrderId AND part.IsDeleted = 0 ;
	END
COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'GetPartsViewBySalesOrderId'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@SalesOrderId, '') + ''
		,@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END