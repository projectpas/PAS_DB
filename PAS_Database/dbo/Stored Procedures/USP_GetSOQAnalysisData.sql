/*************************************************************           
 ** File:   [USP_GetSOQAnalysisData]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get SOQ analysis data
 ** Purpose:         
 ** Date:   09/19/2024
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/19/2024   Vishal Suthar		Created
    2    10/17/2024   Vishal Suthar		Modified to make use of new SOQ Part tables

EXEC [dbo].[USP_GetSOQAnalysisData] 766
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSOQAnalysisData] 
(
	@SalesOrderQuoteId BIGINT = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN	
			DECLARE @ApprovedStatus BIGINT = 4;

			SELECT DISTINCT
				part.SalesOrderQuotePartId salesOrderQuotePartId,
				part.SalesOrderQuoteId salesOrderQuoteId,
				soq.SalesOrderQuoteNumber salesOrderQuoteNumber,
				part.ItemMasterId itemMasterId,
				stk.StockLineId stockLineId,
				qs.StockLineNumber AS stockLineNumber,
				part.FxRate fxRate,
				CASE WHEN stk.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.QtyQuoted ELSE part.QtyQuoted END qtyQuoted,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.UnitSalesPrice ELSE SOQPC.UnitSalesPrice END AS unitSalePrice,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.MarkUpPercentage ELSE SOQPC.MarkUpPercentage END markUpPercentage,
				0 AS salesBeforeDiscount,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.DiscountPercentage ELSE SOQPC.DiscountPercentage END discount,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.DiscountAmount ELSE SOQPC.DiscountAmount END discountAmount,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.NetSaleAmount ELSE SOQPC.NetSaleAmount END netSales,
				part.MasterCompanyId masterCompanyId,
				part.CreatedBy createdBy,
				part.CreatedDate createdDate,
				part.UpdatedBy updatedBy,
				part.UpdatedDate updatedDate,
				itemMaster.PartNumber partNumber,
				itemMaster.PartDescription partDescription,
				itemMaster.IsOEM isOEM,
				itemMaster.IsPma AS isPMA,
				itemMaster.IsDER AS isDER,
				CASE WHEN stk.SalesOrderQuoteStocklineId IS NOT NULL THEN 'S' ELSE 'I' END AS methodType,
				'' AS method,
				ISNULL(qs.SerialNumber, '') AS serialNumber,
				ISNULL(qs.ControlNumber, '') AS controlNumber,
				0 AS grossSalePricePerUnit,
				0 AS grossSalePrice,
				soq.OpenDate AS quoteDate,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.MarginAmount ELSE SOQPC.MarginAmount END markupPerUnit,
				SOQPC.TaxAmount AS taxAmount,
				-- Call your existing Tax function logic here
				0 AS taxPercentage,
				'' AS taxType,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.UnitCost ELSE SOQPC.UnitCost END AS unitCost,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.UnitSalesPriceExtended ELSE SOQPC.UnitSalesPriceExtended END salesPriceExtended,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.MarkUpAmount ELSE SOQPC.MarkUpAmount END markupExtended,
				0 salesDiscountExtended,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.NetSaleAmount ELSE SOQPC.NetSaleAmount END netSalePriceExtended,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.UnitCostExtended ELSE SOQPC.UnitCostExtended END AS unitCostExtended,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.MarginAmount ELSE SOQPC.MarginAmount END AS marginAmount,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.MarginAmount ELSE SOQPC.MarginAmount END marginAmountExtended,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.MarginPercentage ELSE SOQPC.MarginPercentage END AS marginPercentage,
				curr.Code AS currency,
				soq.StatusName AS status,
				soq.CustomerReference AS customerReference,
				part.ConditionId AS conditionId,
				cond.[Description] AS conditionDescription,
				ISNULL(qs.IdNumber, '') AS idNumber,
				CASE WHEN soq.StatusId = 4 THEN 1 ELSE 0 END AS isApproved,
				ISNULL(um.ShortName, '') AS uomName,
				ISNULL(po.PurchaseOrderNumber, '') AS poNumber,
				ISNULL(ro.RepairOrderNumber, '') AS roNumber,
				part.Notes AS notes,
				soq.VersionNumber AS versionNumber,
				SOQPC.Freight AS freight,
				CASE WHEN soq.FreightBilingMethodId = 3 THEN 0 ELSE (SELECT ISNULL(SUM(SOQFF.Amount), 0) FROM DBO.SalesOrderQuoteFreight SOQFF WHERE SOQFF.SalesOrderQuotePartId = part.SalesOrderQuotePartId) END AS freightCost,
				SOQPC.MiscCharges AS misc,
				CASE WHEN soq.ChargesBilingMethodId = 3 THEN 0 ELSE (SELECT ISNULL(SUM(SOQCC.ExtendedCost), 0) FROM DBO.SalesOrderQuoteCharges SOQCC WHERE SOQCC.SalesOrderQuotePartId = part.SalesOrderQuotePartId) END AS miscCost,
				CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN SOQSC.UnitSalesPrice ELSE SOQPC.UnitSalesPrice END unitSalesPricePerUnit,
				soq.TotalCharges AS totalCharges,
				soq.TotalFreight AS totalFreight,
				soq.ChargesBilingMethodId AS chargesBilingMethodId,
				soq.FreightBilingMethodId AS freightBilingMethodId
			FROM DBO.SalesOrderQuote soq WITH (NOLOCK)
			INNER JOIN DBO.SalesOrderQuotePartV1 part WITH (NOLOCK) ON soq.SalesOrderQuoteId = part.SalesOrderQuoteId
			LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			INNER JOIN DBO.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			LEFT JOIN DBO.SalesOrderQuoteStockLineCost SOQSC WITH (NOLOCK) ON SOQSC.SalesOrderQuoteStocklineId = stk.SalesOrderQuoteStocklineId
			LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
			LEFT JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
			LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
			LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON soq.CustomerId = cf.CustomerId
			LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON cf.CurrencyId = curr.CurrencyId
			LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = part.ConditionId
			LEFT JOIN SalesOrderQuoteFreight soqf ON part.SalesOrderQuotePartId = soqf.SalesOrderQuotePartId
			LEFT JOIN SalesOrderQuoteCharges soqc ON part.SalesOrderQuotePartId = soqc.SalesOrderQuotePartId
			WHERE part.SalesOrderQuoteId = @SalesOrderQuoteId
			AND part.IsDeleted = 0;
	  END
    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_GetSOQAnalysisData'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@SalesOrderQuoteId, '') + ''
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