/*************************************************************           
 ** File:   [USP_GetExchangeQuotePartView]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuotePartView
 ** Purpose:         
 ** Date:   07/17/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/17/2025   Ekta Chandegra     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
  EXEC USP_GetExchangeQuotePartViewByQuoteId @ExchangeQuoteId = 10119

************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetExchangeQuotePartViewByQuoteId]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT DISTINCT
			eqp.ExchangeQuotePartId,
			eqp.ExchangeQuoteId,
			eqp.ItemMasterId,
			eqp.StockLineId,
			sl.StockLineNumber,
			UPPER(ISNULL(sl.SerialNumber, '')) AS SerialNumber,
			eqp.MasterCompanyId,
			eqp.CreatedBy,
			eqp.CreatedDate,
			eqp.UpdatedBy,
			eqp.UpdatedDate,
			im.PartNumber,
			im.PartDescription,
			ISNULL(cond.ConditionId, 0) AS ConditionId,
			ISNULL(cond.Description, '') AS ConditionDescription,
			eqp.ExchangeCurrencyId,
			eqp.LoanCurrencyId,
			eqp.ExchangeListPrice,
			eqp.EntryDate,
			eqp.ExchangeOverhaulPrice,
			eqp.ExchangeCorePrice,
			eqp.EstOfFeeBilling,
			eqp.BillingStartDate,
			eqp.ExchangeOutrightPrice,
			eqp.DaysForCoreReturn,
			eqp.BillingIntervalDays,
			eqp.ExchangeOverhaulCost,
			eqp.Currency,
			eqp.DepositeAmount,
			eqp.CoreDueDate,
			eqp.IsConvertedToSalesOrder,
			eqp.CustomerRequestDate,
			eqp.PromisedDate,
			eqp.EstimatedShipDate,
			eqp.IsRemark,
			eqp.RemarkText,
			ISNULL(uom.ShortName, '') AS UomName,
			eqp.QtyQuoted,

			-- Freight Amount
			ISNULL((
				SELECT SUM(f.BillingAmount)
				FROM [dbo].[ExchangeQuoteFreight] f WITH(NOLOCK)
				WHERE f.ExchangeQuoteId = eqp.ExchangeQuoteId
				  AND ISNULL(f.IsActive,0) = 1 AND ISNULL(f.IsDeleted,0) = 0
			), 0) AS Freight,

			-- Misc Charges
			ISNULL((
				SELECT SUM(c.BillingAmount)
				FROM [dbo].[ExchangeQuoteCharges] c WITH(NOLOCK)
				WHERE c.ExchangeQuoteId = eqp.ExchangeQuoteId
				  AND ISNULL(c.IsActive,0) = 1 AND ISNULL(c.IsDeleted,0) = 0
			), 0) AS Misc

		FROM [dbo].[ExchangeQuotePart] eqp WITH(NOLOCK)
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON eqp.ItemMasterId = im.ItemMasterId
		INNER JOIN [dbo].[ExchangeQuote] soq WITH(NOLOCK) ON eqp.ExchangeQuoteId = soq.ExchangeQuoteId
		LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON eqp.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
		LEFT JOIN [dbo].[Condition] cond WITH(NOLOCK) ON eqp.ConditionId = cond.ConditionId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
		WHERE eqp.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(eqp.IsDeleted,0) = 0 AND ISNULL(im.IsNonStock,0) = 0 ;

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
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuotePartViewByQuoteId'     
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