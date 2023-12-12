
/*************************************************************               
 ** File:   [ProcStockListFromItemMasterId]               
 ** Author:  BHARGAV SALIYA    
 ** Description:  This Store Procedure use to  Refresh CreditLimit and Terms     
 ** Purpose:             
 ** Date:   19/09/2023          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** Refresh CreditLimit and Terms               
 **********************************************************               
 ** PR   Date         Author  Change Description                
 ** --   --------     -------  --------------------------------              
    1    19/09/2023  BHARGAV SALIYA    Refresh CreditLimit and Terms     
 
 EXEC [USP_Refresh_CreditLimit_Terms] 77,281,1
********************************************************************/ 

CREATE     PROCEDURE [dbo].[USP_Refresh_CreditLimit_Terms]
@CustomerId bigint,
@SalesOrderQuoteId bigint,
@IsGetCustomerCredirTems bit

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION

		declare @CeraditLimit DECIMAL,
                @CreditTermsId BIGINT,
				@CreaditTerms VARCHAR(50),
			    @AccountType VARCHAR(50),
				@AccountTypeId BIGINT,
				@CustomerName VARCHAR(100)


	IF(@IsGetCustomerCredirTems = 1)
	BEGIN
		;WITH Result(CreditLimit, CreditTermId, AccountTypeName, AccountTypeId, CreditTermName, CustomerName) AS(
		select  CF.CreditLimit AS CreditLimit,
						CF.CreditTermsId AS CreditTermId,
						CT.CustomerTypeName AS AccountTypeName,
				        CT.CustomerTypeId AS AccountTypeId ,
						CR.[Name] AS CreditTermName,
				        C.[Name] AS CustomerName
                from [dbo].[CustomerFinancial]  CF WITH (NOLOCK) 
	                 LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = CF.CustomerId
	                 LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId
	                 LEFT JOIN [dbo].[CreditTerms] CR WITH (NOLOCK) ON CR.CreditTermsId = CF.CreditTermsId
	            where  CF.CustomerId = @CustomerId)
				SELECT * FROM Result;
	END
	ELSE
	BEGIN
		select @CeraditLimit = CF.CreditLimit,
				       @CreditTermsId = CF.CreditTermsId,
				       @AccountType =  CT.CustomerTypeName,
				       @AccountTypeId = CT.CustomerTypeId ,
				       @CreaditTerms = CR.[Name],
				       @CustomerName = C.[Name] 
                from [dbo].[CustomerFinancial]  CF WITH (NOLOCK) 
	                 LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = CF.CustomerId
	                 LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId
	                 LEFT JOIN [dbo].[CreditTerms] CR WITH (NOLOCK) ON CR.CreditTermsId = CF.CreditTermsId
	            where  CF.CustomerId = @CustomerId

				UPDATE [dbo].[SalesOrderQuote]
                SET 
				    [AccountTypeId] = @AccountTypeId,
					[CreditTermId] = @CreditTermsId,
					[CreditLimit] =  @CeraditLimit,
					[CustomerName] = @CustomerName,
                    [CreditTermName] = @CreaditTerms,
					[AccountTypeName] = @AccountType

				FROM [dbo].[SalesOrderQuote]  
				WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND CustomerId = @CustomerId
			
			   SELECT [AccountTypeId],[CreditTermId],[CreditLimit],[CustomerName],[CreditTermName],[AccountTypeName] FROM [SalesOrderQuote] 
			   WHERE SalesOrderQuoteId = @SalesOrderQuoteId 
	END

				
		
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Refresh_CreditLimit_Terms' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END