/*************************************************************           
 ** File:   [USP_GetExchangeQuoteChargesAuditByChargeId]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteChargesAuditByChargeId
 ** Purpose:         
 ** Date:   07/03/2025      
          
 ** PARAMETERS:  @ExchangeQuoteChargesId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/03/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeQuoteChargesAuditByChargeId @ExchangeQuoteChargesId = 50

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteChargesAuditByChargeId]
    @ExchangeQuoteChargesId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @TMBillingId BIGINT, @ActualBillingId BIGINT, @TMDescription VARCHAR(100), @ActualDescription VARCHAR(100);
		SELECT @TMBillingId = BillingMethodId, @TMDescription = Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE [Description] = 'T&M';
		SELECT @ActualBillingId = BillingMethodId, @ActualDescription = Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE [Description] = 'Actual';
	

		SELECT DISTINCT
			soc.AuditExchangeQuoteChargesId,
			soc.ExchangeQuoteChargesId,
			soc.ExchangeQuoteId,
			soc.ExchangeQuotePartId,
			soc.ChargesTypeId,
			ct.ChargeType AS ChargeType,
			soc.Description,
			soc.Quantity,
			soc.UnitCost,
			soc.ExtendedCost,
			soc.MarkupFixedPrice,
			soc.VendorId,
			soc.VendorName AS VendorName,
			soc.BillingMethodId,
			BillingMethodName = 
				CASE soc.BillingMethodId
					WHEN @TMBillingId THEN @TMDescription      
					WHEN @ActualBillingId THEN @ActualDescription   
					ELSE ''
				END,
			soc.BillingRate,
			soc.BillingAmount,
			soc.MarkupPercentageId,
			soc.CreatedBy,
			soc.CreatedDate,
			ISNULL(soc.IsActive,0) AS IsActive,
			ISNULL(soc.IsDeleted,0) AS IsDeleted,
			soc.MasterCompanyId,
			soc.HeaderMarkupId,
			soc.HeaderMarkupPercentageId,
			soc.UpdatedBy,
			soc.UpdatedDate,
			soc.RefNum,
			GLAccountName = ISNULL(gl.AccountName, ''),
			soc.UOMId,
			UOM = ISNULL(um.ShortName, '')
		FROM [dbo].[ExchangeQuoteChargesAudit] soc WITH(NOLOCK)
		LEFT JOIN [dbo].[Charge] ct WITH(NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON soc.UOMId = um.UnitOfMeasureId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		WHERE soc.ExchangeQuoteChargesId = @ExchangeQuoteChargesId
		ORDER BY soc.AuditExchangeQuoteChargesId DESC;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteChargesAuditByChargeId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteChargesId = ''' + CAST(ISNULL(@ExchangeQuoteChargesId, '') AS VARCHAR(100))
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