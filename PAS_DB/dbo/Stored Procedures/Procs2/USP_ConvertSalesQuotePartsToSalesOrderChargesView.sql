/*************************************************************           
 ** File:   [USP_ConvertSalesQuotePartsToSalesOrderChargesView]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to ConvertSalesQuotePartsToSalesOrderChargesView
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
	     
exec [dbo].[USP_ConvertSalesQuotePartsToSalesOrderChargesView] @ExchangeQuoteId=149
************************************************************************/ 
CREATE PROCEDURE [dbo].[USP_ConvertSalesQuotePartsToSalesOrderChargesView]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT  
			soc.ChargesTypeId,
			soc.VendorId,
			soc.Quantity,
			soc.Description,
			soc.UnitCost,
			soc.MarkupPercentageId,
			soc.HeaderMarkupPercentageId,
			soc.ExtendedCost,
			soc.MarkupFixedPrice,
			soc.HeaderMarkupId,
			soc.BillingMethodId,
			soc.BillingRate,
			soc.BillingAmount,
			soc.RefNum,
			soc.MasterCompanyId,
			soc.CreatedBy,
			soc.UpdatedBy,
			GETUTCDATE() AS CreatedDate,
			GETUTCDATE() AS UpdatedDate,
			ISNULL(soc.IsActive,0) AS IsActive,
			ISNULL(soc.IsDeleted,0) AS IsDeleted,
			soc.UOMId AS UomId,
			ISNULL(um.ShortName, '') AS UomName
		FROM [dbo].[ExchangeQuoteCharges] soc WITH(NOLOCK)
		LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON soc.UOMId = um.UnitOfMeasureId
		WHERE soc.ExchangeQuoteId = @ExchangeQuoteId
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID int,
			@DatabaseName varchar(100) = DB_NAME()
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_ConvertSalesQuotePartsToSalesOrderChargesView',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END;