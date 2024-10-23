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
 ** PR   Date         Author    Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/27/2024   Vishal Suthar Created
    2    10/17/2024   Vishal Suthar Modified to make use of new SO Part tables

EXEC [dbo].[GetPartsViewBySalesOrderId]  1103
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
			0 AS taxPercentage,
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
			ISNULL(st.Name, '') AS [status],
			CASE WHEN so.StatusId = 2 THEN 1 ELSE 0 END AS isApproved, -- Assuming 2 is Approved status (replace with appropriate constant)
			so.CustomerReference AS customerReference,
			ISNULL(imx.ExportECCN, '') AS eccn,
			ISNULL(imx.ITARNumber, '') AS itar,
			ISNULL(um.ShortName, '') AS uomName,
			part.Notes notes,
			-- Handle VersionNumber logic with appropriate SQL
			--dbo.GenerateVersionNumber(so.Version) AS VersionNumber,
			SOPC.MiscCharges AS misc,
			CASE WHEN so.ChargesBilingMethodId = 3 THEN 0 ELSE (SELECT ISNULL(SUM(SOCC.ExtendedCost), 0) FROM DBO.SalesOrderCharges SOCC WHERE SOCC.SalesOrderPartId = part.SalesOrderPartId) END AS miscCost,
			--(part.QtyOrder * part.UnitSalesPricePerUnit) + part.TaxAmount + ISNULL(SUM(ch.BillingAmount), 0) AS TotalSales,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.NetSaleAmount ELSE SOPC.NetSaleAmount END AS totalSales,
			CASE WHEN so.FreightBilingMethodId = 3 THEN 0 ELSE (SELECT ISNULL(SUM(SOFF.Amount), 0) FROM DBO.SalesOrderFreight SOFF WHERE SOFF.SalesOrderPartId = part.SalesOrderPartId) END AS freightCost,
			CASE WHEN SOSC.SalesOrderStocklineId IS NOT NULL THEN SOSC.UnitSalesPrice ELSE SOPC.UnitSalesPrice END unitSalesPricePerUnit,
			so.TotalCharges totalCharges,
			so.TotalFreight totalFreight,
			so.ChargesBilingMethodId chargesBilingMethodId,
			so.FreightBilingMethodId freightBilingMethodId,
			ISNULL(sbi.Freight, 0) AS freight,
			ISNULL(sob.SOBillingInvoicingItemId, 0) AS sobillingInvoicingItemId
		FROM DBO.SalesOrder so
		INNER JOIN DBO.SalesOrderPartV1 part ON so.SalesOrderId = part.SalesOrderId
		LEFT JOIN DBO.SalesOrderStocklineV1 stk ON stk.SalesOrderPartId = part.SalesOrderPartId
		LEFT JOIN DBO.StockLine qs ON stk.StockLineId = qs.StockLineId
		LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = part.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
		INNER JOIN DBO.ItemMaster itemMaster ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN DBO.ItemMasterExportInfo imx ON part.ItemMasterId = imx.ItemMasterId
		LEFT JOIN DBO.[Condition] cp ON part.ConditionId = cp.ConditionId
		LEFT JOIN DBO.SalesOrderQuote q ON so.SalesOrderQuoteId = q.SalesOrderQuoteId
		LEFT JOIN DBO.UnitOfMeasure iu ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
		LEFT JOIN DBO.SalesOrderReserveParts rPart ON part.SalesOrderPartId = rPart.SalesOrderPartId
		LEFT JOIN DBO.UnitOfMeasure um ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN DBO.PurchaseOrder po ON qs.PurchaseOrderId = po.PurchaseOrderId
		LEFT JOIN DBO.RepairOrder ro ON qs.RepairOrderId = ro.RepairOrderId
		LEFT JOIN DBO.CustomerFinancial cf ON so.CustomerId = cf.CustomerId
		LEFT JOIN DBO.Currency cur ON part.CurrencyId = cur.CurrencyId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus st ON so.StatusId = st.Id
		LEFT JOIN DBO.SalesOrderBillingInvoicingItem sob ON part.SalesOrderPartId = sob.SalesOrderPartId AND sob.IsVersionIncrease = 0 AND sob.IsProforma = 0
		LEFT JOIN DBO.SalesOrderBillingInvoicing sbi ON sob.SOBillingInvoicingId = sbi.SOBillingInvoicingId AND sbi.IsProforma = 0
		LEFT JOIN DBO.SalesOrderFreight f ON so.SalesOrderId = f.SalesOrderId AND f.ItemMasterId = part.ItemMasterId AND f.ConditionId = part.ConditionId AND f.IsActive = 1 AND f.IsDeleted = 0
		LEFT JOIN DBO.SalesOrderCharges ch ON so.SalesOrderId = ch.SalesOrderId AND ch.ItemMasterId = part.ItemMasterId AND ch.ConditionId = part.ConditionId AND ch.IsActive = 1 AND ch.IsDeleted = 0
		WHERE part.SalesOrderId = @SalesOrderId AND part.IsDeleted = 0;
	END
COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
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