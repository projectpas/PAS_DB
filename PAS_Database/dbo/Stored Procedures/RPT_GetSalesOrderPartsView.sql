/*************************************************************  
** Author:  <AMIT GHEDIYA>  
** Create date: <01/10/2024>  
** Description: 
 
EXEC [RPT_GetSalesOrderPartsView]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    01/10/2024  AMIT GHEDIYA    Created

EXEC RPT_GetSalesOrderPartsView 781

**************************************************************/
CREATE     PROCEDURE [dbo].[RPT_GetSalesOrderPartsView]              
	@salesOrderId BIGINT            
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;              
             
  BEGIN TRY              
   BEGIN           
   
		DECLARE @moduleId BIGINT;

		SET @moduleId = (SELECT ModuleId FROM dbo.module WHERE CodePrefix = 'SO');

		SELECT
			sp.SalesOrderId,
			sp.SalesOrderPartId,
			sp.SalesOrderQuoteId,
			sp.ItemMasterId,
			sp.StockLineId,
			UPPER(ISNULL(sl.StockLineNumber, '')) AS StockLineNumber,
			sp.FxRate,
			sp.Qty,
			sp.QtyRequested,
			sp.UnitSalePrice,
			sp.MarkUpPercentage,
			sp.SalesBeforeDiscount,
			sp.Discount,
			sp.DiscountAmount,
			ISNULL(CAST(sp.NetSales AS decimal), 0) AS NetSales,
			sp.MasterCompanyId,
			sp.CreatedBy,
			sp.CreatedDate,
			sp.UpdatedBy,
			sp.UpdatedDate,
			UPPER(im.PartNumber) AS PartNumber,
			UPPER(im.PartDescription) AS PartDescription,
			CASE WHEN sl.OEM = 1 THEN 1 ELSE 0 END AS IsOEM,
			CASE WHEN im.IsPma = 1 THEN 1 ELSE 0 END AS IsPMA,
			CASE WHEN im.IsDER = 1 THEN 1 ELSE 0 END AS IsDER,
			ISNULL(UPPER(im.ManufacturerName), '') AS ManufacturerName,
			--sp.MethodType,
			--sp.Method,
			sl.IsSerialized,
			ISNULL(sl.SerialNumber, '') AS SerialNumber,
			ISNULL(sl.ControlNumber, '') AS ControlNumber,
			sp.UnitCost,
			sp.Qty * ISNULL(sp.UnitSalesPricePerUnit, 0) AS SalesPriceExtended,
			sp.MarkupExtended,
			sp.SalesDiscountExtended,
			sp.NetSalePriceExtended,
			sp.UnitCostExtended,
			sp.MarginAmount,
			sp.MarginAmountExtended,
			sp.MarginPercentage,
			--COALESCE(currencyDisplayName, '') AS CurrencyDescription,
			sp.ConditionId,
			UPPER(ISNULL(cp.Description, '')) AS ConditionDescription,
			--filteresMiscCharges = (SELECT soc.BillingAmount FROM dbo.SalesOrderMicsCharges soc WITH(NOLOCK)
			--						WHERE soc.ItemMasterId = sp.ItemMasterId AND soc.ConditionId = sp.ConditionId
			--						AND soc.SalesOrderId = sp.SalesOrderId AND soc.SalesOrderPartId = sp.SalesOrderPartId
			--						),
			'-' AS filteresMiscCharges,
			ISNULL(sl.IdNumber, '') AS IdNumber,
			ISNULL(sl.TraceableToName, '') AS TraceableToName,
			ISNULL(sl.CertifiedBy, '') AS CertifiedBy,
			ISNULL(sl.ObtainFromName, '') AS ObtainFrom,
			ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
			ISNULL(q.OpenDate, GETDATE()) AS QuoteDate,
			ISNULL(sl.QuantityAvailable, 0) AS QtyAvailable,
			ISNULL(sl.QuantityOnHand, 0) AS QuantityOnHand,
			UPPER(ISNULL(iu.ShortName, '')) AS UOM,
			ISNULL(rPart.QtyToReserve, 0) AS QtyReserved,
			CASE WHEN (
				SELECT COUNT(*)
				FROM dbo.SalesOrderQuoteApproval WITH(NOLOCK)
				WHERE SalesOrderQuotePartId = sp.SalesOrderQuotePartId
				  AND IsDeleted = 0
				  AND CustomerStatusId = 1
			) > 0 THEN 1 ELSE 0 END AS IsApproved,
			UPPER(sp.CustomerReference) AS CustomerReference,
			ISNULL(imx.ExportECCN, '') AS ECCN,
			ISNULL(imx.ITARNumber, '') AS ITAR,
			ISNULL(um.ShortName, '') AS UomName,
			sp.CustomerRequestDate,
			sp.PromisedDate,
			sp.EstimatedShipDate,
			CASE WHEN sp.PriorityId = 0 THEN 1 ELSE sp.PriorityId END AS PriorityId,
			ISNULL(pri.Description, 'Routine') AS PriorityName,
			ISNULL(sp.StatusId, 1) AS StatusId,
			CASE
				WHEN sp.StatusId IS NULL OR sp.StatusId > 6 THEN 'Open'
				ELSE (
					SELECT Description
					FROM dbo.SOPartStatus WITH(NOLOCK)
					WHERE SOPartStatusId = sp.StatusId
				)
			END AS StatusName,
			COALESCE((
				SELECT SUM(QtyToShip)
				FROM dbo.SOPickTicket WITH(NOLOCK)
				WHERE SalesOrderId = @salesOrderId
				  AND SalesOrderPartId = sp.SalesOrderPartId
				  AND IsActive = 1
				  AND IsDeleted = 0
			), 0) AS QtyToShip,
			ISNULL(sp.Notes, '') AS Notes,
			ISNULL(sp.MarkupPerUnit, 0) AS MarkupPerUnit,
			ISNULL(sp.GrossSalePricePerUnit, 0) AS GrossSalePricePerUnit,
			ISNULL(sp.GrossSalePrice, 0) AS GrossSalePrice,
			ISNULL(sp.TaxPercentage, 0) AS TaxPercentage,
			ISNULL(sp.TaxType, '') AS TaxType,
			ISNULL(sp.TaxAmount, 0) AS TaxAmount,
			ISNULL(sp.AltOrEqType, '') AS AltOrEqType,
			COALESCE((
				SELECT COALESCE(SUM(BillingAmount), 0)
				FROM dbo.SalesOrderFreight WITH(NOLOCK)
				WHERE SalesOrderId = @salesOrderId
				  AND ItemMasterId = sp.ItemMasterId
				  AND ConditionId = sp.ConditionId
				  AND IsActive = 1
				  AND IsDeleted = 0
			), 0) AS Freight,
			COALESCE((
				SELECT COALESCE(SUM(BillingAmount), 0)
				FROM dbo.SalesOrderCharges WITH(NOLOCK)
				WHERE SalesOrderId = @salesOrderId
				  AND ItemMasterId = sp.ItemMasterId
				  AND ConditionId = sp.ConditionId
				  AND IsActive = 1
				  AND IsDeleted = 0
			), 0) AS Misc,
			CASE
				WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER'
				WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
				WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			END AS StockType,
			ISNULL(sp.ItemNo, 0) AS ItemNo,
			ISNULL(sp.POId, 0) AS POId,
			ISNULL(sp.PONumber, '') AS PONumber,
			ISNULL(sp.PONextDlvrDate, NULL) AS PONextDlvrDate,
			ISNULL(rop.RepairOrderPartRecordId, 0) AS ROId,
			ISNULL(ro.RepairOrderNumber, '') AS RONumber,
			ISNULL(rop.EstRecordDate, NULL) AS EstRecordDate,
			ISNULL(sp.UnitSalesPricePerUnit, 0) AS UnitSalesPricePerUnit,
			ISNULL(im.ItemClassificationName, '') AS ItemClassification,
			ISNULL(im.ItemGroup, '') AS ItemGroup,
			ISNULL(rop.EstRecordDate, NULL) AS roNextDlvrDate,
			ISNULL(cur.Code, '') AS CurrencyName,
			--Freight = this.Context.SalesOrder.Where(p => p.SalesOrderId == salesOrderId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().FreightBilingMethodId == 3 ? (decimal)this.Context.SalesOrder.Where(p => p.SalesOrderId == salesOrderId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().TotalFreight :
   --                                     (this.Context.SalesOrderFreight.Where(p => p.SalesOrderId == salesOrderId && p.ItemMasterId == sop.ItemMasterId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().BillingAmount == null ? 0 : (decimal)this.Context.SalesOrderFreight.Where(p => p.SalesOrderId == salesOrderId && p.ItemMasterId == sop.ItemMasterId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().BillingAmount),

			--MiscCharges = this.Context.SalesOrder.Where(p => p.SalesOrderId == salesOrderId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().ChargesBilingMethodId == 3 ? (decimal)this.Context.SalesOrder.Where(p => p.SalesOrderId == salesOrderId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().TotalCharges :
   --                                     (this.Context.SalesOrderCharges.Where(p => p.SalesOrderId == salesOrderId && p.ItemMasterId == sop.ItemMasterId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().BillingAmount == null ? 0 : (decimal)this.Context.SalesOrderCharges.Where(p => p.SalesOrderId == salesOrderId && p.ItemMasterId == sop.ItemMasterId && p.IsActive == true && p.IsDeleted == false).FirstOrDefault().BillingAmount),
			SubTotal = ISNULL(ISNULL(sp.UnitSalesPricePerUnit, 0) * ISNULL(sp.Qty,0) 
										+ CASE WHEN so.FreightBilingMethodId = 3 THEN so.TotalFreight 
										ELSE CASE WHEN sof.BillingAmount = NULL THEN 0 ELSE sof.BillingAmount END END,0),
			TotalFreight = ISNULL(CASE WHEN so.FreightBilingMethodId = 3 THEN so.TotalFreight 
										ELSE CASE WHEN sof.BillingAmount = NULL THEN 0 ELSE sof.BillingAmount END END,0),
			TotalCharges = ISNULL(CASE WHEN so.ChargesBilingMethodId = 3 THEN so.TotalCharges
							ELSE CASE WHEN soc.BillingAmount = NULL THEN 0 ELSE soc.BillingAmount END END,0),

			SalesTax = ISNULL(
				ISNULL(ISNULL(sp.UnitSalesPricePerUnit, 0) * ISNULL(sp.Qty,0) 
										+ CASE WHEN so.FreightBilingMethodId = 3 THEN so.TotalFreight 
										ELSE CASE WHEN sof.BillingAmount = NULL THEN 0 ELSE sof.BillingAmount END END,0) *
				(SELECT SUM(CAST(ISNULL(TR.TaxRate,0) as Decimal(18,2))) FROM dbo.CustomerTaxTypeRateMapping CTTR WITH(NOLOCK)
				INNER JOIN dbo.TaxType TT WITH(NOLOCK) ON CTTR.TaxTypeId = TT.TaxTypeId
				INNER JOIN dbo.TaxRate TR WITH(NOLOCK) ON CTTR.TaxRateId = TR.TaxRateId
				WHERE CustomerId=cust.CustomerId AND SiteId = posadd.SiteId AND TT.Code='SALES TAX' AND CTTR.IsDeleted=0 AND CTTR.IsActive=1) / 100
			,0),

			OtherTax = ISNULL(
				ISNULL(ISNULL(sp.UnitSalesPricePerUnit, 0) * ISNULL(sp.Qty,0) 
										+ CASE WHEN so.FreightBilingMethodId = 3 THEN so.TotalFreight 
										ELSE CASE WHEN sof.BillingAmount = NULL THEN 0 ELSE sof.BillingAmount END END,0) *
				(SELECT SUM(CAST(ISNULL(TR.TaxRate,0) as Decimal(18,2))) FROM dbo.CustomerTaxTypeRateMapping CTTR WITH(NOLOCK)
				INNER JOIN dbo.TaxType TT WITH(NOLOCK) ON CTTR.TaxTypeId = TT.TaxTypeId
				INNER JOIN dbo.TaxRate TR WITH(NOLOCK) ON CTTR.TaxRateId = TR.TaxRateId
				WHERE CustomerId=cust.CustomerId AND SiteId=posadd.SiteId AND (TT.Code != 'SALES TAX' OR TT.Code is null) AND CTTR.IsDeleted=0 AND CTTR.IsActive=1) / 100
			,0),
			Total =  ISNULL(ISNULL(sp.UnitSalesPricePerUnit, 0) * ISNULL(sp.Qty,0),0)
										
			--StockLineNumber = (SELECT stli.StockLineNumber FROM dbo.StockLine stli
			--				  WHERE stli.StockLineId = sp.StockLineId),
			--SerialNumber = (SELECT stli.SerialNumber FROM dbo.StockLine stli
			--				  WHERE stli.StockLineId = sp.StockLineId),
			--ControlNumber = (SELECT stli.ControlNumber FROM dbo.StockLine stli
			--				  WHERE stli.StockLineId = sp.StockLineId),
			--IdNumber = (SELECT stli.IdNumber FROM dbo.StockLine stli
			--				  WHERE stli.StockLineId = sp.StockLineId)
		FROM
			dbo.SalesOrderPart sp WITH(NOLOCK)
			LEFT JOIN dbo.StockLine sl WITH(NOLOCK) ON sp.StockLineId = sl.StockLineId
			LEFT JOIN dbo.ItemMaster im WITH(NOLOCK) ON sp.ItemMasterId = im.ItemMasterId
			LEFT JOIN dbo.ItemMasterExportInfo imx WITH(NOLOCK) ON im.ItemMasterId = imx.ItemMasterId
			LEFT JOIN dbo.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
			LEFT JOIN dbo.Condition cp WITH(NOLOCK) ON sp.ConditionId = cp.ConditionId
			LEFT JOIN dbo.SalesOrderQuote q WITH(NOLOCK) ON sp.SalesOrderQuoteId = q.SalesOrderQuoteId
			LEFT JOIN dbo.UnitOfMeasure iu WITH(NOLOCK) ON im.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
			LEFT JOIN dbo.SalesOrderReserveParts rPart WITH(NOLOCK) ON sp.SalesOrderPartId = rPart.SalesOrderPartId
			LEFT JOIN dbo.UnitOfMeasure um WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			LEFT JOIN dbo.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN dbo.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId
			LEFT JOIN dbo.Priority pri WITH(NOLOCK) ON sp.PriorityId = pri.PriorityId
			LEFT JOIN dbo.SalesOrder so WITH(NOLOCK) ON sp.SalesOrderId = so.SalesOrderId
			LEFT JOIN dbo.SalesOrderFreight sof WITH(NOLOCK) ON sof.SalesOrderId = so.SalesOrderId AND sof.ItemMasterId = sp.ItemMasterId AND sof.IsActive = 1 AND sof.IsDeleted = 0
			LEFT JOIN dbo.SalesOrderCharges soc WITH(NOLOCK) ON soc.SalesOrderId = so.SalesOrderId AND soc.ItemMasterId = sp.ItemMasterId AND soc.IsActive = 1 AND soc.IsDeleted = 0
			LEFT JOIN dbo.RepairOrderPart rop WITH(NOLOCK) ON sl.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
			LEFT JOIN dbo.Customer cust WITH(NOLOCK) ON so.CustomerId = cust.CustomerId
			LEFT JOIN dbo.CustomerFinancial custfc WITH(NOLOCK) ON cust.CustomerId = custfc.CustomerId
			LEFT JOIN dbo.Currency cur WITH(NOLOCK) ON custfc.CurrencyId = cur.CurrencyId
			LEFT JOIN dbo.AllAddress posadd WITH(NOLOCK) ON so.SalesOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @moduleId
			LEFT JOIN dbo.SOPickTicket pt ON sp.SalesOrderPartId = pt.SalesOrderPartId
		WHERE
			sp.SalesOrderId = @salesOrderId
			AND sp.IsDeleted = 0
			--AND rop.isAsset = 0
		ORDER BY
			sp.ItemNo;

   END              
             
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetSalesOrderPartsView'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@salesOrderId, '')              
              , @ApplicationName VARCHAR(100) = 'PAS'              
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
             
              exec spLogException              
                       @DatabaseName           = @DatabaseName              
                     , @AdhocComments          = @AdhocComments              
                     , @ProcedureParameters    = @ProcedureParameters              
                     , @ApplicationName        = @ApplicationName              
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;              
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)              
              RETURN(1);              
  END CATCH              
END