/*************************************************************           
 ** File:   [USP_GetExchangeQuotePartView]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuotePartView
 ** Purpose:         
 ** Date:   07/11/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/11/2025   Ekta Chandegra     Created
    2    15/04/2026   RAJESH GAMI		 Getting StockUOM instead of POUOM  [PN-15903]
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from StockLine join and WHERE clause.
  EXEC USP_GetExchangeQuotePartView @ExchangeQuoteId = 113
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuotePartView]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		-------------------------------
		-- 1. Main Part View
		-------------------------------
		SELECT DISTINCT
			part.ExchangeQuotePartId,
			part.ExchangeQuoteId,
			part.ItemMasterId,
			part.StockLineId,
			qs.StockLineNumber,
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
			part.Currency,
			part.DepositeAmount,
			part.CoreDueDate,
			part.IsConvertedToSalesOrder,
			part.CustomerRequestDate,
			part.PromisedDate,
			part.EstimatedShipDate,
			part.IsRemark,
			part.RemarkText,
			ISNULL(uom.ShortName, '') AS UomName,
			part.QtyQuoted,

			-- Freight amount
			ISNULL((
				SELECT SUM(BillingAmount)
				FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
				WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
			), 0) AS Freight,

			-- Misc amount
			ISNULL((
				SELECT SUM(BillingAmount)
				FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
				WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
			), 0) AS Misc,

			im.ManufacturerName
		FROM [dbo].[ExchangeQuotePart] part WITH(NOLOCK)
		LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON part.ItemMasterId = im.ItemMasterId
		LEFT JOIN [dbo].[Condition] cond WITH(NOLOCK) ON part.ConditionId = cond.ConditionId
		INNER JOIN [dbo].[ExchangeQuote] soq WITH(NOLOCK) ON part.ExchangeQuoteId = soq.ExchangeQuoteId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
		WHERE part.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(part.IsDeleted,0) = 0 ;

		-------------------------------
		-- 2. Retrieve ExchangeQuoteScheduleBilling details
		-------------------------------
		SELECT 
		EXQS.ExchangeQuoteScheduleBillingId,
		EXQS.ExchangeQuotePartId,
		EXQS.ScheduleBillingDate,
		EXQS.PeriodicBillingAmount,
		EXQS.Cogs,
		EXQS.CogsAmount
		FROM [dbo].[ExchangeQuoteScheduleBilling] EXQS WITH(NOLOCK) WHERE EXQS.ExchangeQuoteId = @ExchangeQuoteId; 
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuotePartView'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteId = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100)) 
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