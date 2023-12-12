
-- =============================================
-- Author:		Deep Patel
-- Create date: 29-april-2021
-- Description:	Update name columns into corrosponding reference Id values from respective master table
-- =============================================
--  EXEC [dbo].[UpdateExchangeQuoteFreightNameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateExchangeQuoteFreightNameColumnsWithId]
	@ExchangeQuoteId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update soqf
		SET ShipViaName = sv.Name,
		UOMName = uom.ShortName,
		DimensionUOMName = duom.ShortName,
		CurrencyName = c.Code
		FROM [dbo].[ExchangeQuoteFreight] soqf WITH (NOLOCK)
		LEFT JOIN DBO.ShippingVia sv WITH (NOLOCK) ON soqf.ShipViaId = sv.ShippingViaId
		LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON soqf.UOMId = uom.UnitOfMeasureId
		LEFT JOIN DBO.UnitOfMeasure duom WITH (NOLOCK) ON soqf.DimensionUOMId = duom.UnitOfMeasureId
		LEFT JOIN DBO.Currency c WITH (NOLOCK) ON soqf.CurrencyId = c.CurrencyId
		Where soqf.ExchangeQuoteId = @ExchangeQuoteId
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeQuoteFreightNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeQuoteId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
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