/*************************************************************           
 ** File:   [USP_MakeSalesOrderPartViewFromSalesQuote]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_MakeSalesOrderPartViewFromSalesQuote
 ** Purpose:         
 ** Date:    09/17/2025  
 ** PARAMETERS:  @ExchangeQuotePartId BIGINT, @ExchangeQuoteId BIGINT, @MasterCompanyId INT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    09/17/2025  EKTA CHANDEGRA    Created
    2    09/July/2026  RAJESH GAMI    [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	     
exec [dbo].[USP_MakeSalesOrderPartViewFromSalesQuote] @ExchangeQuotePartId=126, @ExchangeQuoteId=155, @MasterCompanyId=1
************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_MakeSalesOrderPartViewFromSalesQuote]
    @ExchangeQuotePartId BIGINT,
    @ExchangeQuoteId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
	
	    -- Get Default Priority Id
		DECLARE @PriorityId BIGINT;
		SELECT TOP 1 @PriorityId = DefaultPriorityId
		FROM [dbo].[ExchangeSalesOrderSettings] WITH (NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId;

		-- Get the PartView (main record)
		SELECT 
			sop.ConditionName,
			sop.ConditionId,
			ISNULL(sop.CreatedBy, 'admin') AS CreatedBy,
			sop.ItemMasterId,
			sop.MasterCompanyId,
			sop.MethodType,	
			sop.PartDescription,
			sop.PartNumber,
			sop.QtyQuoted,
			sop.QtyQuoted AS Qty,
			sop.QtyQuoted AS QtyRequested,
			0 AS ExchangeSalesOrderId,
			NULL AS ExchangeSalesOrderPartId,
			sop.ExchangeQuoteId,
			st.SerialNumber,
			CASE WHEN sop.StockLineId <= 0 THEN NULL ELSE sop.StockLineId END AS StockLineId,
			sop.StockLineName,
			ISNULL(sop.UpdatedBy, 'admin') AS UpdatedBy,
			GETUTCDATE() AS UpdatedDate,
			GETUTCDATE() AS CreatedDate,
			sop.ExchangeQuotePartId,
			sop.CustomerRequestDate,
			sop.PromisedDate,
			sop.EstimatedShipDate,
			sq.StatusId,
			sop.ExchangeListPrice,
			sop.EntryDate,
			sop.ExchangeOverhaulPrice,
			sop.ExchangeCorePrice,
			sop.EstOfFeeBilling,
			sop.BillingStartDate,
			sop.ExchangeOutrightPrice,
			sop.DaysForCoreReturn,
			sop.BillingIntervalDays,
			sop.Currency,
			sop.DepositeAmount,
			sop.ExchangeOverhaulCost,
			st.UnitCost,
			@PriorityId AS PriorityId,
			sop.CoreDueDate,
			sop.CoreDueDate AS ExpectedCoreRetDate,
			CAST(sq.FunctionalCurrencyId AS INT) AS CurrencyId,
			sq.ReportCurrencyId AS ExchangeCurrencyId,
			CAST(sq.ForeignExchangeRate AS DECIMAL(18,4)) AS FxRate
		FROM [dbo].[ExchangeQuotePart] sop WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeQuote] sq WITH(NOLOCK) ON sop.ExchangeQuoteId = sq.ExchangeQuoteId
		INNER JOIN [dbo].[ExchangeSalesOrderSettings] es WITH(NOLOCK) ON sop.MasterCompanyId = es.MasterCompanyId
		LEFT JOIN [dbo].[Stockline] st WITH(NOLOCK) ON st.StockLineId = sop.StockLineId AND ISNULL(st.IsNonStock,0) = 0
		WHERE sop.ExchangeQuotePartId = @ExchangeQuotePartId
		  AND sop.ExchangeQuoteId = @ExchangeQuoteId;

		-- Get the ScheduleBilling child records (like exchangeSOScheduleBilling list in EF)
		SELECT
			qsb.ExchangeQuotePartId AS ExchangeSalesOrderPartId,
			qsb.ExchangeQuoteId     AS ExchangeSalesOrderId,
			qsb.ScheduleBillingDate,
			qsb.PeriodicBillingAmount,
			qsb.Cogs,
			qsb.CogsAmount,
			'Part' AS Type,
			1 AS StatusId,
			1 AS BillingTypeId,
			1 AS Qty
		FROM [dbo].[ExchangeQuoteScheduleBilling] qsb WITH(NOLOCK)
		WHERE qsb.ExchangeQuotePartId = @ExchangeQuotePartId
		  AND qsb.ExchangeQuoteId = @ExchangeQuoteId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_MakeSalesOrderPartViewFromSalesQuote'   
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ExchangeQuotePartId, '') AS varchar(100) ) + ''',
													 @Parameter2 = '''+ CAST(ISNULL(@ExchangeQuoteId, '') AS varchar(100) ) + ''',
													 @Parameter3 = '''+ CAST(ISNULL(@MasterCompanyId, '') AS varchar(100) ) + ''
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
END;