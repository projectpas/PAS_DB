
-- =============================================
-- Author:		Deep patel
-- Create date: 10-july-2021
-- Description:	Update name columns into corrosponding reference Id values from respective master table
-- =============================================
--  EXEC [dbo].[UpdateExchangeQuoteChargeNameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateExchangeSalesOrderChargeNameColumnsWithId]
	@ExchangeSalesOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update eqc
		SET VendorName = v.VendorName,
		ChargeName = C.ChargeType,
		MarkupName = p.PercentValue -- Mark up name is pased as input from soq create component whichis percentage
		FROM [dbo].[ExchangeSalesOrderCharges] eqc WITH (NOLOCK)
		LEFT JOIN DBO.Vendor v WITH (NOLOCK) ON eqc.VendorId = v.VendorId
		LEFT JOIN DBO.Charge c WITH (NOLOCK) ON eqc.ChargesTypeId = c.ChargeId
		LEFT JOIN DBO.[Percent] p WITH (NOLOCK) ON eqc.MarkupPercentageId = p.PercentId
		Where eqc.ExchangeSalesOrderId = @ExchangeSalesOrderId
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeSalesOrderChargeNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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