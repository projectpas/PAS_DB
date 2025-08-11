/*************************************************************           
 ** File:   [USP_GetExchangeQuoteAnalysisListData]        
 ** Author:  Ekta Chandegra 
 ** Description: This stored procedure is used to USP_GetExchangeQuoteAnalysisListData
 ** Purpose:           
 ** Date:  08/06/2025      
            
 ** PARAMETERS: 
           
 ***************************************************************************************         
 ** Change History             
 ***************************************************************************************
 
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
    1     08/06/2025      Ekta Chandegra        Created  

exec [dbo].[USP_GetExchangeQuoteAnalysisListData] @ExchangeQuoteId = 125
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteAnalysisListData]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Declare required variables
        DECLARE @MasterCompanyId BIGINT;
        DECLARE @CogsValue DECIMAL(18, 2) = 0;
        DECLARE @MiscCharges DECIMAL(18, 2) = 0;
        DECLARE @Freight DECIMAL(18, 2) = 0;

        -- Get MasterCompanyId
        SELECT @MasterCompanyId = MasterCompanyId
        FROM [dbo].[ExchangeQuote] WITH(NOLOCK)
        WHERE ExchangeQuoteId = @ExchangeQuoteId;

        -- Get COGS percentage value
        SELECT TOP 1 @CogsValue = ISNULL(p.PercentValue, 0)
        FROM [dbo].[ExchangeQuoteSetting] s WITH(NOLOCK)
        LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON s.COGS = p.PercentId
        WHERE s.MasterCompanyId = @MasterCompanyId;

        -- Get Misc Charges
        SELECT @MiscCharges = ISNULL(SUM(BillingAmount), 0)
        FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
        WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

        -- Get Freight Charges
        SELECT @Freight = ISNULL(SUM(BillingAmount), 0)
        FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
        WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

        -- Final data
        SELECT 
            eq.ExchangeQuoteId,
            (
                SELECT ISNULL(SUM(PeriodicBillingAmount), 0)
                FROM [dbo].[ExchangeQuoteScheduleBilling] WITH(NOLOCK)
                WHERE ExchangeQuoteId = eq.ExchangeQuoteId
            ) AS ExchangeFees,
            part.ExchangeOverhaulPrice AS OverhaulPrice,
            @MiscCharges AS OtherCharges
        FROM [dbo].[ExchangeQuote] eq WITH(NOLOCK)
        INNER JOIN [dbo].[ExchangeQuotePart] part WITH(NOLOCK) ON eq.ExchangeQuoteId = part.ExchangeQuoteId
        WHERE eq.ExchangeQuoteId = @ExchangeQuoteId;

    END TRY
    BEGIN CATCH
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteAnalysisListData'     
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
END;