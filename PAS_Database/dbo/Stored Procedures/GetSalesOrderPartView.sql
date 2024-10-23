/*************************************************************           
 ** File:   [GetSalesOrderPartView]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Sales Order Quote Part Data
 ** Purpose:         
 ** Date:   09/26/2024
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/26/2024   Vishal Suthar     Created
     
-- EXEC [DBO].[GetSalesOrderPartView] 1103
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderPartView]
    @SalesOrderId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @ApprovedStatus INT = 2;
	DECLARE @DefaultPriorityId INT = 2;
	DECLARE @DefaultPriorityName VARCHAR(50) = 'ROUTINE';
	DECLARE @DefaultStatusId INT = 1;
	DECLARE @DefaultStatusName VARCHAR(50) = 'OPEN';

    SELECT 
        part.SalesOrderId,
        part.SalesOrderPartId,
        SO.SalesOrderQuoteId,
        part.ItemMasterId,
        Stk.StockLineId,
        ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
        part.FxRate,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN Stk.QtyOrder ELSE part.QtyOrder END AS Qty,
        part.QtyRequested,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.UnitSalesPrice ELSE PS.UnitSalesPrice END AS UnitSalePrice,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarkUpPercentage ELSE PS.MarkUpPercentage END MarkUpPercentage,
        0 SalesBeforeDiscount,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.DiscountPercentage ELSE PS.DiscountPercentage END Discount,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.DiscountAmount ELSE PS.DiscountAmount END DiscountAmount,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS NetSales,
        part.MasterCompanyId,
        part.CreatedBy,
        part.CreatedDate,
        part.UpdatedBy,
        part.UpdatedDate,
        itemMaster.PartNumber,
        itemMaster.PartDescription,
        ISNULL(qs.OEM, 0) AS IsOEM,
        itemMaster.IsPma,
        itemMaster.IsDER,
        UPPER(ISNULL(itemMaster.ManufacturerName, '')) AS ManufacturerName,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN 'S' ELSE 'I' END MethodType,
        '' AS Method,
        ISNULL(qs.IsSerialized, 0) AS IsSerialized,
        ISNULL(qs.SerialNumber, '') AS SerialNumber,
        ISNULL(qs.ControlNumber, '') AS ControlNumber,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.UnitCost ELSE PS.UnitCost END UnitCost,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.UnitSalesPriceExtended ELSE PS.UnitSalesPriceExtended END AS SalesPriceExtended,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarkUpAmount ELSE PS.MarkUpAmount END) * stk.QtyOrder), 0) MarkupExtended,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.DiscountAmount ELSE PS.DiscountAmount END) * stk.QtyOrder), 0) SalesDiscountExtended,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END) * stk.QtyOrder), 0) NetSalePriceExtended,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.UnitCostExtended ELSE PS.UnitCostExtended END UnitCostExtended,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarginAmount ELSE PS.MarginAmount END MarginAmount,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarginAmount ELSE PS.MarginAmount END) * stk.QtyOrder), 0) MarginAmountExtended,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarginPercentage ELSE PS.MarginPercentage END AS MarginPercentage,
        ISNULL(fcu.Code, '') AS CurrencyDescription,
        part.CurrencyId,
        part.ConditionId,
        ISNULL(cp.Description, '') AS ConditionDescription,
        ISNULL(qs.IdNumber, '') AS IdNumber,
        ISNULL(qs.TraceableToName, '') AS TraceableToName,
        ISNULL(qs.CertifiedBy, '') AS CertifiedBy,
        ISNULL(qs.ObtainFromName, '') AS ObtainFrom,
        ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
        ISNULL(q.OpenDate, GETDATE()) AS QuoteDate,
        ISNULL(qs.QuantityAvailable, 0) AS QtyAvailable,
        ISNULL(qs.QuantityOnHand, 0) AS QuantityOnHand,
        ISNULL(iu.ShortName, '') AS UOM,
        ISNULL(rPart.QtyToReserve, NULL) AS QtyReserved,
        CASE 
            WHEN EXISTS (SELECT 1 FROM DBO.SalesOrderApproval WHERE SalesOrderPartId = part.SalesOrderPartId AND IsDeleted = 0 AND CustomerStatusId = @ApprovedStatus) 
            THEN 1 ELSE 0 
        END AS IsApproved,
        ISNULL(SO.SalesOrderQuoteId, '') AS CustomerReference,
        ISNULL(imx.ExportECCN, '') AS ECCN,
        ISNULL(imx.ITARNumber, '') AS ITAR,
        ISNULL(um.ShortName, '') AS UomName,
        part.CustomerRequestDate,
        part.PromisedDate,
        part.EstimatedShipDate,
        ISNULL(part.PriorityId, @DefaultPriorityId) AS PriorityId,
        ISNULL(pri.Description, @DefaultPriorityName) AS PriorityName,
        ISNULL(part.StatusId, @DefaultStatusId) AS StatusId,
        ISNULL((SELECT Description FROM SOPartStatus WHERE SOPartStatusId = part.StatusId), @DefaultStatusName) AS StatusName,
        ISNULL((SELECT SUM(QtyToShip) FROM DBO.SOPickTicket WHERE SalesOrderId = part.SalesOrderId AND SalesOrderPartId = part.SalesOrderPartId AND IsActive = 1 AND IsDeleted = 0), 0) AS QtyToShip,
        part.Notes,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarkUpAmount ELSE PS.MarkUpAmount END MarkupPerUnit,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END AS GrossSalePricePerUnit,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END AS GrossSalePrice,
        0 AS TaxPercentage,
        '' TaxType,
        PS.TaxAmount AS TaxAmount,
        '' AS AltOrEqType,
        ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderFreight WHERE SalesOrderId = part.SalesOrderId AND ItemMasterId = part.ItemMasterId AND ConditionId = part.ConditionId AND IsActive = 1 AND IsDeleted = 0), 0) AS Freight,
        ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderCharges WHERE SalesOrderId = part.SalesOrderId AND ItemMasterId = part.ItemMasterId AND ConditionId = part.ConditionId AND IsActive = 1 AND IsDeleted = 0), 0) AS Misc,
        CASE 
            WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
            WHEN itemMaster.IsPma = 1 THEN 'PMA'
            WHEN itemMaster.IsDER = 1 THEN 'DER'
            ELSE 'OEM'
        END AS StockType,
        0 AS ItemNo,
        part.POId,
        part.PONumber,
        part.PONextDlvrDate,
        rop.RepairOrderPartRecordId AS ROId,
        ro.RepairOrderNumber AS RONumber,
        rop.EstRecordDate,
        (CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.UnitSalesPrice ELSE PS.UnitSalesPrice END) UnitSalesPricePerUnit,
        itemMaster.ItemClassificationName AS ItemClassification,
        itemMaster.ItemGroup,
        rop.EstRecordDate AS roNextDlvrDate
    FROM DBO.SalesOrderPartV1 part WITH (NOLOCK)
    LEFT JOIN DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
	LEFT JOIN SalesOrderPartCost PS ON PS.SalesOrderPartId = part.SalesOrderPartId
    LEFT JOIN SalesOrderStockLineCost SC ON SC.SalesOrderStocklineId = Stk.SalesOrderStocklineId
    LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
    LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
    LEFT JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN DBO.ItemMasterExportInfo imx WITH (NOLOCK) ON itemMaster.ItemMasterId = imx.ItemMasterId
    LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON itemMaster.ManufacturerId = mf.ManufacturerId
    LEFT JOIN DBO.Condition cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
    LEFT JOIN DBO.SalesOrderQuote q WITH (NOLOCK) ON SO.SalesOrderQuoteId = q.SalesOrderQuoteId
    LEFT JOIN DBO.UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
    LEFT JOIN DBO.SalesOrderReserveParts rPart WITH (NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId AND part.SalesOrderId = rPart.SalesOrderId
    LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
    LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN DBO.[Priority] pri WITH (NOLOCK) ON part.PriorityId = pri.PriorityId
    LEFT JOIN DBO.RepairOrderPart rop WITH (NOLOCK) ON qs.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
    LEFT JOIN DBO.Currency fcu WITH (NOLOCK) ON part.CurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
    WHERE part.SalesOrderId = @SalesOrderId
    AND part.IsDeleted = 0
    AND ISNULL(rop.isAsset, 0) = 0;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[GetSalesOrderPartView]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END