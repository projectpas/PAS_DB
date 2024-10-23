/*************************************************************           
 ** File:   [GetSalesOrderQuotePartView]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Sales Order Quote Part Data
 ** Purpose:         
 ** Date:   09/06/2024
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/06/2024   Vishal Suthar     Created
     
-- EXEC [DBO].[GetSalesOrderQuotePartView] 766, 'USD'
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderQuotePartView]
    @SalesQuoteId BIGINT,
    @CurrencyDisplayName NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    SELECT DISTINCT
        part.SalesOrderQuotePartId,
        stk.SalesOrderQuoteStocklineId,
        part.SalesOrderQuoteId,
        part.ItemMasterId,
        stk.StockLineId,
        ISNULL(qs.StockLineNumber, '') AS stockLineNumber,
        part.FxRate,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.QtyQuoted ELSE Part.QtyQuoted END AS QtyQuoted,
        ISNULL(part.QtyRequested, 0) AS QtyRequested,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.UnitSalesPrice ELSE PS.UnitSalesPrice END UnitSalePrice,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.MarkUpPercentage ELSE PS.MarkUpPercentage END MarkUpPercentage,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.DiscountAmount ELSE PS.DiscountAmount END SalesBeforeDiscount,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.DiscountPercentage ELSE PS.DiscountPercentage END Discount,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.DiscountAmount ELSE PS.DiscountAmount END DiscountAmount,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END NetSales,
        part.MasterCompanyId,
        part.CreatedBy,
        part.CreatedDate,
        part.UpdatedBy,
        part.UpdatedDate,
        itemMaster.PartNumber,
        itemMaster.PartDescription,
        ISNULL(qs.OEM, 0) AS isOEM,
        itemMaster.IsPma AS isPMA,
        itemMaster.IsDER AS isDER,
        CASE WHEN stk.StockLineId IS NOT NULL THEN 'S' ELSE 'I' END MethodType,
        '' AS Method,
        ISNULL(qs.SerialNumber, '') AS SerialNumber,
        ISNULL(qs.ControlNumber, '') AS ControlNumber,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.UnitCost ELSE PS.UnitCost END UnitCost,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.UnitSalesPriceExtended ELSE PS.UnitSalesPriceExtended END SalesPriceExtended,
        ISNULL(((CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.MarkUpAmount ELSE PS.MarkUpAmount END) * stk.QtyQuoted), 0) MarkupExtended,
        ISNULL(((CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.DiscountAmount ELSE PS.DiscountAmount END) * stk.QtyQuoted), 0) SalesDiscountExtended,
        ISNULL(((CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END) * stk.QtyQuoted), 0) NetSalePriceExtended,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.UnitCostExtended ELSE PS.UnitCostExtended END UnitCostExtended,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.MarginAmount ELSE PS.MarginAmount END MarginAmount,
        ISNULL(((CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.MarginAmount ELSE PS.MarginAmount END) * stk.QtyQuoted), 0) MarginAmountExtended,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.MarginPercentage ELSE PS.MarginPercentage END MarginPercentage,
        @CurrencyDisplayName AS CurrencyDescription,
        ISNULL(cp.ConditionId, 0) AS ConditionId,
        ISNULL(cp.Description, '') AS ConditionDescription,
        ISNULL(qs.IdNumber, '') AS IdNumber,
        CASE WHEN EXISTS (
                SELECT 1
                FROM SalesOrderQuoteApproval sqap
                WHERE sqap.SalesOrderQuotePartId = part.SalesOrderQuotePartId 
                  AND sqap.IsDeleted = 0 
                  AND sqap.CustomerStatusId = 1 -- Assuming 1 is 'Approved'
            ) THEN 1 ELSE 0 END AS IsApproved,
        ISNULL(UPPER(um.ShortName), '') AS UomName,
        ISNULL(po.PurchaseOrderNumber, '') AS PoNumber,
        ISNULL(ro.RepairOrderNumber, '') AS RoNumber,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.CustomerRequestDate ELSE part.CustomerRequestDate END CustomerRequestDate,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.PromisedDate ELSE part.PromisedDate END AS PromisedDate,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.EstimatedShipDate ELSE part.EstimatedShipDate END AS EstimatedShipDate,
		CASE WHEN part.PriorityId = 0 THEN 2 ELSE part.PriorityId END AS PriorityId,
        CASE WHEN part.PriorityId = 0 THEN 'Routine' ELSE ISNULL(pri.Description, 'Routine') END AS PriorityName,
        ISNULL(part.StatusId, 1) AS StatusId, -- Assuming 1 represents 'Open'
        ISNULL(st.Description, 'Open') AS StatusName,
        soq.CustomerReference CustomerReference,
        part.Notes AS Notes,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.MarkUpPercentage ELSE PS.MarkUpPercentage END MarkupPerUnit,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.GrossSaleAmount END GrossSalePricePerUnit,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.GrossSaleAmount END GrossSalePrice,
        TaxPercentage = 0,--dbo.GetCustomerTaxBaseOnPartDetail(part.SalesOrderQuoteId, part.SalesOrderQuotePartId, soq.CustomerId), 
        --ISNULL(part.TaxType, '') AS TaxType,
        '' AS TaxType,
        PS.TaxAmount TaxAmount,
        --ISNULL(part.QtyPrevQuoted, 0) AS QtyPrevQuoted,
        0 AS QtyPrevQuoted,
        --part.AltOrEqType,
        '' AltOrEqType,
        Freight = ISNULL((
            SELECT SUM(sqf.BillingAmount) 
            FROM SalesOrderQuoteFreight sqf
            WHERE sqf.SalesOrderQuoteId = @SalesQuoteId
              AND sqf.ItemMasterId = part.ItemMasterId
              AND sqf.ConditionId = part.ConditionId
              AND sqf.IsActive = 1
              AND sqf.IsDeleted = 0), 0),
        Misc = ISNULL((
            SELECT SUM(sqc.BillingAmount) 
            FROM SalesOrderQuoteCharges sqc
            WHERE sqc.SalesOrderQuoteId = @SalesQuoteId
              AND sqc.ItemMasterId = part.ItemMasterId
              AND sqc.ConditionId = part.ConditionId
              AND sqc.IsActive = 1
              AND sqc.IsDeleted = 0), 0),
        StockType = CASE 
            WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
            WHEN itemMaster.IsPma = 1 THEN 'PMA'
            WHEN itemMaster.IsDER = 1 THEN 'DER'
            ELSE 'OEM'
        END,
        qs.QuantityAvailable QtyAvailable,
        qs.QuantityOnHand,
        part.IsConvertedToSalesOrder,
        --ISNULL(part.ItemNo, 0) AS ItemNo,
        0 AS ItemNo,
        (CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN SC.UnitSalesPrice ELSE PS.UnitSalesPrice END) UnitSalesPricePerUnit,
        itemMaster.ItemClassificationName AS ItemClassification,
        itemMaster.ItemGroup,
        ISNULL(mf.Name, '') AS ManufacturerName,
        --part.SalesPriceExpiryDate,
        NULL SalesPriceExpiryDate,
        part.IsNoQuote
    FROM DBO.SalesOrderQuotePartV1 part
    LEFT JOIN SalesOrderQuoteStocklineV1 stk ON stk.SalesOrderQuotePartId = part.SalesOrderQuotePartId
    LEFT JOIN SalesOrderQuotePartCost PS ON PS.SalesOrderQuotePartId = part.SalesOrderQuotePartId
    LEFT JOIN SalesOrderQuoteStockLineCost SC ON SC.SalesOrderQuoteStocklineId = stk.SalesOrderQuoteStocklineId
    LEFT JOIN StockLine qs ON stk.StockLineId = qs.StockLineId
    INNER JOIN ItemMaster itemMaster ON part.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN [Condition] cp ON part.ConditionId = cp.ConditionId
    LEFT JOIN Manufacturer mf ON itemMaster.ManufacturerId = mf.ManufacturerId
    LEFT JOIN UnitOfMeasure um ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
    LEFT JOIN PurchaseOrder po ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN RepairOrder ro ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN Priority pri ON part.PriorityId = pri.PriorityId
    LEFT JOIN SalesOrderQuote soq ON part.SalesOrderQuoteId = soq.SalesOrderQuoteId
    LEFT JOIN SOPartStatus st ON part.StatusId = st.SOPartStatusId
    WHERE part.SalesOrderQuoteId = @SalesQuoteId AND part.IsDeleted = 0
    --ORDER BY part.ItemNo;
	END TRY

	BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[GetSalesOrderQuotePartView]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesQuoteId, '') AS VARCHAR(100)),
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