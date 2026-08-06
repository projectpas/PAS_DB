/*************************************************************           
 ** File:   [GetExchangeQuotePartViewBySalesOrderId]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeQuotePartViewBySalesOrderId
 ** Purpose:         
 ** Date:   06/11/2025      
          
 ** PARAMETERS: @ExchangeSalesOrderId bigint,
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/11/2025   Ekta Chandegra     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from StockLine join and WHERE clause.
 EXEC GetExchangeQuotePartViewBySalesOrderId @ExchangeSalesOrderId=165
************************************************************************/
CREATE PROCEDURE [dbo].[GetExchangeQuotePartViewBySalesOrderId]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT DISTINCT
			part.ExchangeQuoteId,
			part.ItemMasterId,
			part.StockLineId,
			ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
			ISNULL(UPPER(qs.SerialNumber), '') AS SerialNumber,
			part.MasterCompanyId,
			part.CreatedBy,
			part.CreatedDate,
			part.UpdatedBy,
			part.UpdatedDate,
			im.PartNumber,
			im.PartDescription,
			ISNULL(cond.ConditionId, 0) AS ConditionId,
			ISNULL(cond.Description, '') AS ConditionDescription,
			part.ExchangeCurrencyId,
			part.LoanCurrencyId,
			part.ExchangeListPrice,
			part.EntryDate,
			part.ExchangeOverhaulPrice,
			part.ExchangeCorePrice,
			part.EstOfFeeBilling,
			part.BillingStartDate,
			part.ExchangeOutrightPrice,
			part.DaysForCoreReturn,
			part.BillingIntervalDays,
			part.ExchangeOverhaulCost,
			ISNULL(part.Currency,'') AS Currency,
			part.DepositeAmount,
			part.CoreDueDate,
			part.IsConvertedToSalesOrder,
			part.CustomerRequestDate,
			part.PromisedDate,
			part.EstimatedShipDate,
			part.IsRemark,
			ISNULL(part.RemarkText,'') AS RemarkText,
			ISNULL(uom.ShortName, '') AS UomName,
			part.QtyQuoted
		FROM [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK)
        LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
        INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON part.ItemMasterId = im.ItemMasterId
        LEFT JOIN [dbo].[Condition] cond WITH(NOLOCK) ON part.ConditionId = cond.ConditionId
        INNER JOIN [dbo].[ExchangeSalesOrder] eso WITH(NOLOCK) ON part.ExchangeSalesOrderId = eso.ExchangeSalesOrderId
        LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
        WHERE part.ExchangeSalesOrderId = @ExchangeSalesOrderId
            AND ISNULL(part.IsDeleted,0) = 0 ;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeQuotePartViewBySalesOrderId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END