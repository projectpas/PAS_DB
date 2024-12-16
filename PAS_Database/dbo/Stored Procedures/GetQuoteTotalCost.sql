/*************************************************************             
 ** File:   [GetQuoteTotalCost]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetQuoteTotalCost
 ** Purpose:           
 ** Date:  13/12/2024        
            
 ** PARAMETERS: @soqId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    13/12/2024		EKTA CHANDEGRA	 Created  

 EXEC GetQuoteTotalCost 972
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetQuoteTotalCost]
    @soqId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		-- Declare variables to store the result of the query
		DECLARE @quoteTotals DECIMAL(18, 2);
		DECLARE @quoteCharges DECIMAL(18, 2);
		DECLARE @chargesBillingMethodId INT;
		DECLARE @totalCharges DECIMAL(18, 2);
		DECLARE @billingMethod INT = 3;

		-- Step 1: Calculate the Total Cost of the SalesOrderQuotePartCost
		SELECT @quoteTotals = ISNULL(SUM(spc.NetSaleAmount), 0)
		FROM [dbo].[SalesOrderQuotePartV1] soq WITH(NOLOCK)
		LEFT JOIN [dbo].[SalesOrderQuotePartCost] spc WITH(NOLOCK) ON soq.SalesOrderQuotePartId = spc.SalesOrderQuotePartId
		WHERE soq.SalesOrderQuoteId = @soqId 
			AND ISNULL(soq.IsActive,0) = 1 
			AND ISNULL(soq.IsDeleted,0) = 0;

		-- Step 2: Get the ChargesBillingMethodId from the SalesOrderQuote
		SELECT @chargesBillingMethodId = ChargesBilingMethodId, 
			   @totalCharges = TotalCharges
		FROM [dbo].[SalesOrderQuote] WITH(NOLOCK)
		WHERE SalesOrderQuoteId = @soqId;

		-- Step 3: If ChargesBillingMethodId is not 3, calculate quoteCharges
		IF @chargesBillingMethodId != @billingMethod
		BEGIN
			SELECT @quoteCharges = ISNULL(SUM(soq.BillingAmount), 0)
			FROM [dbo].[SalesOrderQuoteCharges] soq WITH(NOLOCK)
			WHERE soq.SalesOrderQuoteId = @soqId
				AND ISNULL(soq.IsActive,0) = 1
				AND ISNULL(soq.IsDeleted,0) = 0;
        
			SET @quoteTotals = @quoteTotals + @quoteCharges;
		END
		ELSE
		BEGIN
			-- Else, add the TotalCharges value from the SalesOrderQuote table if it exists
			SET @quoteTotals = @quoteTotals + ISNULL(@totalCharges, 0);
		END

		-- Return the final quote total
		SELECT @quoteTotals AS QuoteTotalCost;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetQuoteTotalCost'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@soqId, '') + ''
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