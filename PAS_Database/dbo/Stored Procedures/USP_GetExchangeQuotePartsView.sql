/*************************************************************           
 ** File:   [USP_GetExchangeQuotePartsView]             
 ** Author:  Ekta Chandegra 
 ** Description: This stored procedure is used to USP_GetExchangeQuotePartsView
 ** Purpose:           
 ** Date:  08/04/2025       
            
 ** PARAMETERS: @ExchangeQuoteId BIGINT
           
 ***************************************************************************************         
 ** Change History             
 ***************************************************************************************
    1     08/04/2025      Ekta Chandegra        Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from StockLine join and WHERE clause.
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
exec [dbo].[USP_GetExchangeQuotePartsView] @ExchangeQuoteId = 121
************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetExchangeQuotePartsView]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		-- First Result Set: Main Exchange Quote Part View
		SELECT 
			part.ExchangeQuotePartId,
			part.ExchangeQuoteId,
			part.ItemMasterId,
			part.StockLineId,
			qs.StockLineNumber,
			UPPER(ISNULL(qs.SerialNumber, '')) AS SerialNumber,
			part.MasterCompanyId,
			part.CreatedBy,
			part.CreatedDate,
			part.UpdatedBy,
			part.UpdatedDate,
			itemMaster.PartNumber,
			itemMaster.PartDescription,
			ISNULL(cp.ConditionId, 0) AS ConditionId,
			ISNULL(cp.Description, '') AS ConditionDescription,
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
			ISNULL(um.ShortName, '') AS UomName,
			part.QtyQuoted,

			-- Freight and Misc per ExchangeQuoteId
			ISNULL((
				SELECT SUM(BillingAmount)
				FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
				WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
			), 0) AS Freight,

			ISNULL((
				SELECT SUM(BillingAmount)
				FROM dbo.ExchangeQuoteCharges WITH(NOLOCK)
				WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
			), 0) AS Misc

		FROM [dbo].[ExchangeQuotePart] part WITH(NOLOCK)
		INNER JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		INNER JOIN [dbo].[ExchangeQuote] soq WITH(NOLOCK) ON part.ExchangeQuoteId = soq.ExchangeQuoteId
		LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
		LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
		LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		WHERE part.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(part.IsDeleted,0) = 0 ;

		-- Second Result Set: Schedule Billings
		SELECT *
		FROM [dbo].[ExchangeQuoteScheduleBilling] WITH(NOLOCK)
		WHERE ExchangeQuotePartId IN (
			SELECT ExchangeQuotePartId
			FROM dbo.ExchangeQuotePart WITH(NOLOCK)
			WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsDeleted,0) = 0
		);
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuotePartsView'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ExchangeQuoteId, '') AS varchar(100) ) + ''
			,@ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1);
	END CATCH
END