/*************************************************************           
 ** File:   [USP_GetExchangeSalesOrderFreightAuditByFreightId]           
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderFreightAuditByFreightId
 ** Purpose:         
 ** Date:    05/30/2025  

 ** PARAMETERS: @ExchangeSalesOrderFreightId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    05/30/2025  EKTA CHANDEGRA    Created
	     
-- EXEC USP_GetExchangeSalesOrderFreightAuditByFreightId @ExchangeId = 73 
************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderFreightAuditByFreightId]
    @ExchangeSalesOrderFreightId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @TMBillingMethod INT, @ActualBillingMethod INT;
		SELECT @TMBillingMethod =  BillingMethodId FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE Description = 'T&M';
		SELECT @ActualBillingMethod =  BillingMethodId FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE Description = 'Actual';
        SELECT DISTINCT
            sf.AuditExchangeSalesOrderFreightId,
            sf.ExchangeSalesOrderFreightId,
            sf.ExchangeSalesOrderId,
            sf.ExchangeSalesOrderPartId,
            sf.Amount,
            sf.CreatedBy,
            sf.CreatedDate,
            sf.IsActive,
            sf.IsDeleted,
            sf.MasterCompanyId,
            sf.Memo,
            sf.ShipViaId,
            sf.UpdatedBy,
            sf.UpdatedDate,
            sf.Weight,
            sf.ShipViaName AS ShipVia,
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
            CASE 
                WHEN sf.BillingMethodId = @TMBillingMethod THEN 'TM'     
                WHEN sf.BillingMethodId = @ActualBillingMethod THEN 'Actual'  
                ELSE ''
            END AS BillingMethodName,
            sf.BillingRate,
            sf.BillingAmount,
            sf.UOMName AS UOM,
            sf.DimensionUOMName AS DimensionUOM,
            sf.CurrencyName AS Currency
        FROM [dbo].[ExchangeSalesOrderFreightAudit] sf WITH(NOLOCK)
        WHERE sf.ExchangeSalesOrderFreightId = @ExchangeSalesOrderFreightId
        ORDER BY sf.AuditExchangeSalesOrderFreightId DESC;
    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderFreightAuditByFreightId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderFreightId = ''' + CAST(ISNULL(@ExchangeSalesOrderFreightId, '') AS VARCHAR(100)) 
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