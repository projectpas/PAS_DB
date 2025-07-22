/*************************************************************           
 ** File:   [USP_GetExchangeQuoteFreightAuditByFreightId]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteFreightAuditByFreightId
 ** Purpose:         
 ** Date:   07/03/2025      
          
 ** PARAMETERS:  @ExchangeQuoteFreightId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/03/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeQuoteFreightAuditByFreightId @ExchangeQuoteFreightId = 50

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteFreightAuditByFreightId]
    @ExchangeQuoteFreightId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	
	BEGIN TRY
		DECLARE @TMBillingId BIGINT, @ActualBillingId BIGINT, @TMDescription VARCHAR(100), @ActualDescription VARCHAR(100);
		SELECT @TMBillingId = BillingMethodId, @TMDescription = Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE [Description] = 'T&M';
		SELECT @ActualBillingId = BillingMethodId, @ActualDescription = Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE [Description] = 'Actual';

		SELECT DISTINCT
			sf.AuditExchangeQuoteFreightId,
			sf.ExchangeQuoteFreightId,
			sf.ExchangeQuoteId,
			sf.ExchangeQuotePartId,
			sf.Amount,
			sf.CreatedBy,
			sf.CreatedDate,
			ISNULL(sf.IsActive,0) AS IsActive,
			ISNULL(sf.IsDeleted,0) AS IsDeleted,
			sf.MasterCompanyId,
			sf.Memo,
			sf.ShipViaId,
			sf.UpdatedBy,
			sf.UpdatedDate,
			sf.Weight,
			ShipVia = sf.ShipViaName,
			sf.Length,
			sf.Width,
			sf.Height,
			sf.UOMId,
			sf.DimensionUOMId,
			sf.CurrencyId,
			sf.MarkupFixedPrice,
			sf.MarkupPercentageId,
			sf.HeaderMarkupId,
			sf.HeaderMarkupPercentageId,
			sf.BillingMethodId,
			BillingMethodName = 
				CASE sf.BillingMethodId
					WHEN @TMBillingId THEN @TMDescription       
					WHEN @ActualBillingId THEN @ActualDescription    
					ELSE ''
				END,
			sf.BillingRate,
			sf.BillingAmount,
			UOM = sf.UOMName,
			DimensionUOM = sf.DimensionUOMName,
			Currency = sf.CurrencyName
		FROM [dbo].[ExchangeQuoteFreightAudit] sf WITH(NOLOCK)
		WHERE sf.ExchangeQuoteFreightId = @ExchangeQuoteFreightId
		ORDER BY sf.AuditExchangeQuoteFreightId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteFreightAuditByFreightId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteFreightId = ''' + CAST(ISNULL(@ExchangeQuoteFreightId, '') AS VARCHAR(100))
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