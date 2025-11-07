/*************************************************************           
 ** File:   [GetSalesOrderQuoteParts]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get sales order quote part details for view    
 ** Purpose:         
 ** Date:   09/20/2024
          
 ** PARAMETERS:
 
 ** RETURN VALUE:

 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/20/2024   Vishal Suthar Created
    2    12/03/2024   Vishal Suthar Handled null values
    3    12/09/2024   Vishal Suthar Fix for qty issue when stockline is not added
  	4    19-SEP-2025  RAJESH GAMI	    Added return field: netSalesPricePerUnit        
	5    05-NOV-2025  RAJESH GAMI	    Added return field: TotalPartCost 
 -- EXEC DBO.GetSalesOrderQuoteParts 1300
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSalesOrderQuoteParts]
    @SalesQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;
	BEGIN TRY

	
    	IF OBJECT_ID(N'tempdb..#tmpSOPartTblView') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSOPartTblView
		END

		SELECT DISTINCT
			part.SalesOrderQuotePartId,
			part.SalesOrderQuoteId,
			part.ItemMasterId,
			Stk.StockLineId,
			qs.StockLineNumber,
			part.FxRate,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(stk.QtyQuoted, 0) ELSE (CASE WHEN part.QtyQuoted = 0 THEN part.QtyRequested ELSE part.QtyQuoted END) END QtyQuoted,
			ISNULL(part.QtyRequested, 0) AS QtyRequested,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.UnitSalesPrice, 0) ELSE ISNULL(SOQPC.UnitSalesPrice, 0) END UnitSalePrice,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.MarkUpPercentage, 0) ELSE ISNULL(SOQPC.MarkUpPercentage, 0) END MarkUpPercentage,
			0 SalesBeforeDiscount,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.DiscountPercentage, 0) ELSE ISNULL(SOQPC.DiscountPercentage, 0) END Discount,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.DiscountAmount, 0) ELSE ISNULL(SOQPC.DiscountAmount, 0) END DiscountAmount,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.NetSaleAmount, 0) ELSE ISNULL(SOQPC.NetSaleAmount, 0) END NetSales,
			SOQPC.MasterCompanyId,
			part.CreatedBy,
			part.CreatedDate,
			part.UpdatedBy,
			part.UpdatedDate,
			itemMaster.PartNumber,
			itemMaster.PartDescription,
			ISNULL(qs.[OEM], 0) AS isOEM,
			ISNULL(itemMaster.IsPma, 0) AS isPMA,
			ISNULL(itemMaster.IsDER, 0) AS isDER,
			CASE WHEN Stk.SalesOrderQuoteStocklineId IS NOT NULL THEN 'S' ELSE 'I' END MethodType,
			'' Method,
			ISNULL(qs.SerialNumber, '') AS SerialNumber,
			ISNULL(qs.ControlNumber, '') AS ControlNumber,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.UnitCost, 0) ELSE ISNULL(SOQPC.UnitCost, 0) END UnitCost,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.UnitSalesPriceExtended, 0) ELSE ISNULL(SOQPC.UnitSalesPriceExtended, 0) END SalesPriceExtended,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.MarkUpAmount, 0) ELSE ISNULL(SOQPC.MarkUpAmount, 0) END MarkupExtended,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.DiscountAmount, 0) ELSE ISNULL(SOQPC.DiscountAmount, 0) END SalesDiscountExtended,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.UnitSalesPriceExtended, 0) ELSE ISNULL(SOQPC.UnitSalesPriceExtended, 0) END NetSalePriceExtended,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.UnitCostExtended, 0) ELSE ISNULL(SOQPC.UnitCostExtended, 0) END UnitCostExtended,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.MarginAmount, 0) ELSE ISNULL(SOQPC.MarginAmount, 0) END MarginAmount,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.MarginAmount, 0) ELSE ISNULL(SOQPC.MarginAmount, 0) END MarginAmountExtended,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.MarginPercentage, 0) ELSE ISNULL(SOQPC.MarginPercentage, 0) END MarginPercentage,
			COALESCE(fcu.Code, '') AS CurrencyDescription,
			part.CurrencyId,
			COALESCE(cp.ConditionId, 0) AS ConditionId,
			COALESCE(cp.Description, '') AS ConditionDescription,
			COALESCE(qs.IdNumber, '') AS IdNumber,
			CASE
				WHEN EXISTS (
					SELECT 1
					FROM SalesOrderQuoteApproval
					WHERE SalesOrderQuotePartId = part.SalesOrderQuotePartId
					  AND IsDeleted = 0
					  AND CustomerStatusId = CAST(1 AS INT) -- Assuming 1 is Approved
				) THEN 1
				ELSE 0
			END AS IsApproved,
			COALESCE(um.ShortName, '') AS UomName,
			COALESCE(po.PurchaseOrderNumber, '') AS PoNumber,
			COALESCE(ro.RepairOrderNumber, '') AS RoNumber,
			part.CustomerRequestDate,
			part.PromisedDate,
			part.EstimatedShipDate,
			CASE
				WHEN part.PriorityId = 0 THEN CAST(1 AS BIGINT) -- Assuming 1 is Routine
				ELSE part.PriorityId
			END AS PriorityId,
			COALESCE(pri.Description, 'Routine') AS PriorityName,
			COALESCE(part.StatusId, CAST(1 AS INT)) AS StatusId, -- Assuming 1 is Open
			CASE WHEN (part.StatusId IS NULL OR part.StatusId > 6) THEN 'Open' ELSE (SELECT [Description] FROM DBO.SOPartStatus WHERE SOPartStatusId = part.StatusId) END AS StatusName,
			soq.CustomerReference,
			COALESCE(part.Notes, '') AS Notes,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.MarkUpAmount, 0) ELSE ISNULL(SOQPC.MarkUpAmount, 0) END MarkupPerUnit,
			0 GrossSalePricePerUnit,
			0 GrossSalePrice,
			--dbo.GetCustomerTaxBasebOnPartDetail(part.SalesOrderQuoteId, part.SalesOrderQuotePartId, soq.CustomerId) AS TaxPercentage,
			SOQPC.TaxPercentage TaxPercentage,
			'' TaxType,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQPC.TaxAmount, 0) ELSE ISNULL(SOQPC.TaxAmount, 0) END TaxAmount,
			part.QtyQuoted AS QtyPrevQuoted,
			'' AltOrEqType,
			COALESCE(
				(SELECT SUM(BillingAmount)
				 FROM DBO.SalesOrderQuoteFreight WITH (NOLOCK)
				 WHERE SalesOrderQuoteId = @SalesQuoteId
				   AND ItemMasterId = part.ItemMasterId
				   AND ConditionId = part.ConditionId
				   AND IsActive = 1
				   AND IsDeleted = 0), 0) AS Freight,
			COALESCE(
				(SELECT SUM(BillingAmount)
				 FROM DBO.SalesOrderQuoteCharges WITH (NOLOCK)
				 WHERE SalesOrderQuoteId = @SalesQuoteId
				   AND ItemMasterId = part.ItemMasterId
				   AND ConditionId = part.ConditionId
				   AND IsActive = 1
				   AND IsDeleted = 0), 0) AS Misc,
			CASE
				WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
				WHEN itemMaster.IsPma = 1 THEN 'PMA'
				WHEN itemMaster.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			END AS StockType,
			stk.QtyAvailable,
			qs.QuantityOnHand,
			part.IsConvertedToSalesOrder,
			0 AS ItemNo,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN (ISNULL(SOQSC.NetSaleAmount, 0) / ISNULL(Stk.QtyQuoted, 1)) ELSE (ISNULL(SOQPC.NetSaleAmount, 0) / ISNULL(CASE WHEN part.QtyQuoted > 0 THEN part.QtyQuoted ELSE part.QtyRequested END, 1)) END UnitSalesPricePerUnit,
			itemMaster.ItemClassificationName,
			itemMaster.ItemGroup,
			COALESCE(mf.Name, '') AS ManufacturerName,
			part.SalesPriceExpiryDate,
			part.IsNoQuote,
			CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.NetSaleAmountPerUnit, 0) ELSE ISNULL(SOQPC.NetSaleAmountPerUnit, 0) END netSalesPricePerUnit,
			SOQPC.UnitSalesPrice MainUnitSalesPrice,
			ISNULL((CASE WHEN SOQSC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SOQSC.NetSaleAmount, 0) ELSE ISNULL(SOQPC.NetSaleAmount, 0) END), 0) NetSalePriceExtendedPart

		INTO #tmpSOPartTblView 
		FROM DBO.SalesOrderQuotePartV1 part WITH (NOLOCK)
		LEFT JOIN DBO.SalesOrderQuoteStocklineV1 Stk WITH (NOLOCK) ON part.SalesOrderQuotePartId = Stk.SalesOrderQuotePartId
		LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
		LEFT JOIN DBO.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId = part.SalesOrderQuotePartId
		LEFT JOIN DBO.SalesOrderQuoteStockLineCost SOQSC WITH (NOLOCK) ON SOQSC.SalesOrderQuoteStocklineId = Stk.SalesOrderQuoteStocklineId
		LEFT JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN DBO.Condition cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
		LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON itemMaster.ManufacturerId = mf.ManufacturerId
		LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
		LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
		LEFT JOIN DBO.[Priority] pri WITH (NOLOCK) ON part.PriorityId = pri.PriorityId
		LEFT JOIN DBO.SalesOrderQuote soq WITH (NOLOCK) ON part.SalesOrderQuoteId = soq.SalesOrderQuoteId
		LEFT JOIN DBO.Currency fcu WITH (NOLOCK) ON part.CurrencyId = fcu.CurrencyId
		WHERE part.SalesOrderQuoteId = @SalesQuoteId AND part.IsDeleted = 0
		ORDER BY part.SalesOrderQuotePartId;


		;WITH CTE_Cost AS (
			SELECT 
				SalesOrderQuotePartId,
				SUM(ISNULL(QtyQuoted, 0)) AS TotalQtyQuoted,
				SUM(ISNULL(NetSalePriceExtendedPart, 0)) AS TotalNetSalePriceExtended
			FROM #tmpSOPartTblView
			GROUP BY SalesOrderQuotePartId
		)
		SELECT 
			main.*,
			(((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
			  + ISNULL(c.TotalNetSalePriceExtended, 0)) AS TotalPartCost
		FROM #tmpSOPartTblView main
		LEFT JOIN CTE_Cost c ON main.SalesOrderQuotePartId = c.SalesOrderQuotePartId;

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments varchar(150) = 'GetSalesOrderQuoteParts',
        @ProcedureParameters varchar(3000) = '@SalesOrderQuoteId = ''' + CAST(ISNULL(@SalesQuoteId, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName,
						@AdhocComments = @AdhocComments,
						@ProcedureParameters = @ProcedureParameters,
						@ApplicationName = @ApplicationName,
						@ErrorLogID = @ErrorLogID OUTPUT;
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1);
	END CATCH
END