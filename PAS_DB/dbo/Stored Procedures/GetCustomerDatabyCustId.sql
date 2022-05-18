

-- EXEC [dbo].[GetCustomerDatabyCustId] 14
CREATE PROCEDURE [dbo].[GetCustomerDatabyCustId]
	@customerId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		
	SELECT 
	   C.CustomerCode
	  ,c.Name as ShipToSiteName
	  ,CF.CreditLimit  AS CreditLimit
	  ,cts.[Name]  AS CreditTerm
	  ,CR.Code  AS BaseCurrency
	  FROM dbo.Customer C WITH (NOLOCK) 
		INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
		LEFT JOIN dbo.CustomerFinancial CF  WITH (NOLOCK) ON CF.CustomerId=C.CustomerId
		LEFT JOIN dbo.CreditTerms cts WITH (NOLOCK) ON cts.CreditTermsId = CF.CreditTermsId
		LEFT JOIN dbo.Currency CR  WITH (NOLOCK) ON CR.CurrencyId=CF.CurrencyId
	  WHERE C.CustomerId=@customerId

	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCustomerDatabyCustId' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@customerId AS VARCHAR(10)), '') + ''
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