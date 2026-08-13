-- ===== PROCEDURE: [dbo].[USP_GetSalesOrderQuotePartsView]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetSalesOrderQuotePartsView.sql) =====
/*************************************************************           
 ** File:   [USP_GetSalesOrderQuotePartsView]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to retrieve SOQ data for print
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    12/04/2024   Vishal Suthar Created
	2    06/11/2026   Vishal Suthar Added/Fixed Order By to keep the sequence same. 
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    22/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 exclusion(s) left over from the PN-17008/17009 transitional phase; Non-Stock parts were showing blank details (or being entirely excluded) when printing a Sales Order Quote/Sales Order.
    6    11/August/2026			Priyansh Patel                       [PN-17573]SOQ/SO/Invoice Print: Added IsNonStock and IsService so SOQ Print can hide Stockline Number/Serial Number for Non-Stock Service Items.

  EXEC [dbo].[USP_GetSalesOrderQuotePartsView] 701
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalesOrderQuotePartsView]
    @SalesQuoteId INT,
	@CurrencyDisplayName VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY 
	BEGIN TRANSACTION

	DECLARE @ApprovedApprovalStatusId BIGINT = 2;
	DECLARE @RoutinePriorityId BIGINT = 2;
	DECLARE @OpenStatusId BIGINT = 1;

    SELECT DISTINCT
        part.SalesOrderQuotePartId,
        part.SalesOrderQuoteId,
        part.ItemMasterId,
        stk.StockLineId,
        qs.StockLineNumber,
        part.FxRate,
        part.QtyQuoted,
        ISNULL(part.QtyRequested, 0) AS QtyRequested,
        ISNULL(partc.UnitSalesPrice, 0) AS UnitSalesPrice,
        ISNULL(partc.MarkUpPercentage, 0) AS MarkUpPercentage,
        ISNULL(partc.GrossSaleAmount, 0) AS SalesBeforeDiscount,
        partc.DiscountPercentage AS Discount,
        ISNULL(partc.DiscountAmount, 0) AS DiscountAmount,
        ISNULL(partc.NetSaleAmount, 0) AS NetSales,
        part.MasterCompanyId,
        part.CreatedBy,
        part.CreatedDate,
        part.UpdatedBy,
        part.UpdatedDate,
        itemMaster.PartNumber,
        itemMaster.PartDescription,
        CASE WHEN qs.StockLineId IS NULL THEN 0 ELSE qs.OEM END AS isOEM,
        itemMaster.IsPma,
        itemMaster.IsDER,
        CASE WHEN stk.StockLineId IS NOT NULL THEN 'S' ELSE 'I' END AS MethodType,
        '' AS Method,
        ISNULL(qs.SerialNumber, '') AS SerialNumber,
        ISNULL(qs.ControlNumber, '') AS ControlNumber,
        ISNULL(partc.UnitCost, 0) AS UnitCost,
        ISNULL(partc.UnitSalesPriceExtended, 0) AS SalesPriceExtended,
        ISNULL(partc.MarkUpAmount, 0) AS MarkupExtended,
        ISNULL(partc.DiscountAmount, 0) AS SalesDiscountExtended,
        ISNULL(partc.NetSaleAmount, 0) AS NetSalePriceExtended,
        ISNULL(partc.UnitCostExtended, 0) AS UnitCostExtended,
        ISNULL(partc.MarginAmount, 0) AS MarginAmount,
        ISNULL(partc.MarginAmount, 0) AS MarginAmountExtended,
        ISNULL(partc.MarginPercentage, 0) AS MarginPercentage,
        @CurrencyDisplayName AS CurrencyDescription,
        ISNULL(cp.ConditionId, 0) AS ConditionId,
        ISNULL(cp.Description, '') AS ConditionDescription,
        ISNULL(qs.IdNumber, '') AS IdNumber,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM SalesOrderQuoteApproval sa 
                WHERE sa.SalesOrderQuotePartId = part.SalesOrderQuotePartId 
                  AND sa.IsDeleted = 0 
                  AND sa.CustomerStatusId = @ApprovedApprovalStatusId
            ) THEN 1
            ELSE 0
        END AS IsApproved,
        ISNULL(um.ShortName, '') AS UomName,
        ISNULL(po.PurchaseOrderNumber, '') AS PoNumber,
        ISNULL(ro.RepairOrderNumber, '') AS RoNumber,
        part.CustomerRequestDate,
        part.PromisedDate,
        part.EstimatedShipDate,
        ISNULL(part.PriorityId, @RoutinePriorityId) AS PriorityId,
        ISNULL(pri.Description, 'Routine') AS PriorityName,
        ISNULL(part.StatusId, @OpenStatusId) AS StatusId,
        ISNULL(
            (SELECT TOP 1 Description 
             FROM SOQPartStatus 
             WHERE SOQPartStatusId = part.StatusId), 
            'Open'
        ) AS StatusName,
        soq.CustomerReference,
        ISNULL(part.Notes, '') AS Notes,
        ISNULL(partc.MarkUpAmount, 0) AS MarkupPerUnit,
        0 AS GrossSalePricePerUnit,
        ISNULL(partc.GrossSaleAmount, 0) AS GrossSalePrice,
        ISNULL(partc.TaxPercentage, 0) AS TaxPercentage,
        '' AS TaxType,
        ISNULL(partc.TaxAmount, 0) AS TaxAmount,
        ISNULL(part.QtyQuoted, 0) AS QtyPrevQuoted,
        '' AS AltOrEqType,
        ISNULL((
            SELECT SUM(BillingAmount) 
            FROM SalesOrderQuoteFreight 
            WHERE SalesOrderQuoteId = @SalesQuoteId 
              AND ItemMasterId = part.ItemMasterId 
              AND ConditionId = part.ConditionId 
              AND IsActive = 1 
              AND IsDeleted = 0
        ), 0) AS Freight,
        ISNULL((
            SELECT SUM(BillingAmount) 
            FROM SalesOrderQuoteCharges 
            WHERE SalesOrderQuoteId = @SalesQuoteId 
              AND ItemMasterId = part.ItemMasterId 
              AND ConditionId = part.ConditionId 
              AND IsActive = 1 
              AND IsDeleted = 0
        ), 0) AS Misc,
        CASE 
            WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
            WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 0 THEN 'PMA'
            WHEN itemMaster.IsPma = 0 AND itemMaster.IsDER = 1 THEN 'DER'
            ELSE 'OEM'
        END AS StockType,
        qs.QuantityAvailable,
        qs.QuantityOnHand,
        part.IsConvertedToSalesOrder,
        0 AS ItemNo,
        partc.NetSaleAmount AS UnitSalesPricePerUnit,
        itemMaster.ItemClassificationName AS ItemClassification,
        ISNULL(itemMaster.IsNonStock, 0) AS IsNonStock,
        ISNULL(itemMaster.IsService, 0) AS IsService,
        itemMaster.ItemGroup,
        ISNULL(mf.Name, '') AS ManufacturerName
    FROM 
    DBO.SalesOrderQuotePartV1 AS part WITH (NOLOCK)
    LEFT JOIN DBO.SalesOrderQuoteStocklineV1 AS stk WITH (NOLOCK) ON part.SalesOrderQuotePartId = stk.SalesOrderQuotePartId
    LEFT JOIN DBO.StockLine AS qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
    INNER JOIN DBO.SalesOrderQuotePartCost AS partc WITH (NOLOCK) ON part.SalesOrderQuotePartId = partc.SalesOrderQuotePartId
    INNER JOIN DBO.ItemMaster AS itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN DBO.Condition AS cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
    LEFT JOIN DBO.Manufacturer AS mf WITH (NOLOCK) ON itemMaster.ManufacturerId = mf.ManufacturerId
    LEFT JOIN DBO.UnitOfMeasure AS um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
    LEFT JOIN DBO.PurchaseOrder AS po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN DBO.RepairOrder AS ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN DBO.Priority AS pri WITH (NOLOCK) ON part.PriorityId = pri.PriorityId
    INNER JOIN DBO.SalesOrderQuote AS soq WITH (NOLOCK) ON part.SalesOrderQuoteId = soq.SalesOrderQuoteId
    WHERE part.SalesOrderQuoteId = @SalesQuoteId AND part.IsDeleted = 0
     ORDER BY part.SalesOrderQuotePartId;

	COMMIT  TRANSACTION  
  END TRY      
  BEGIN CATCH        
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSalesOrderQuotePartsView'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesQuoteId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END;