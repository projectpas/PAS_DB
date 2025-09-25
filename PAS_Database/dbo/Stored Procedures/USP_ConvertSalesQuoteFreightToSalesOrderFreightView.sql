/*************************************************************           
 ** File:   [USP_ConvertSalesQuoteFreightToSalesOrderFreightView]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_ConvertSalesQuoteFreightToSalesOrderFreightView
 ** Purpose:         
 ** Date:    09/15/2025  

 ** PARAMETERS: @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    09/15/2025  EKTA CHANDEGRA    Created
	     
exec [dbo].[USP_ConvertSalesQuoteFreightToSalesOrderFreightView] @ExchangeQuoteId=149
************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_ConvertSalesQuoteFreightToSalesOrderFreightView]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT
			sof.ShipViaId,
			sof.Weight,
			sof.Memo,
			sof.Amount,
			sof.MarkupPercentageId,
			sof.HeaderMarkupPercentageId,
			sof.MarkupFixedPrice,
			sof.HeaderMarkupId,
			sof.BillingMethodId,
			sof.BillingRate,
			sof.BillingAmount,
			sof.Length,
			sof.Width,
			sof.Height,
			sof.UOMId,
			sof.DimensionUOMId,
			sof.CurrencyId,
			sof.MasterCompanyId,
			sof.CreatedBy,
			sof.UpdatedBy,
			GETUTCDATE() AS CreatedDate,
			GETUTCDATE() AS UpdatedDate,
			ISNULL(sof.IsActive,0) AS IsActive,
			ISNULL(sof.IsDeleted,0) AS IsDeleted
		FROM [dbo].[ExchangeQuoteFreight] sof WITH(NOLOCK)
		WHERE sof.ExchangeQuoteId = @ExchangeQuoteId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_ConvertSalesQuoteFreightToSalesOrderFreightView'   
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