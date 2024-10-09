/*************************************************************               
 ** File:   [USP_WO_Refresh_CreditLimit_Terms]               
 ** Author: BHARGAV SALIYA 
 ** Description:  This Store Procedure use to WO Refresh CreditLimit and Terms     
 ** Purpose:             
 ** Date:   26 SEP 2024      
              
 ** RETURN VALUE:               
 **********************************************************               
 ** Refresh CreditLimit and Terms               
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    26 SEP 2024	BHARGAV SALIYA		WO Refresh CreditLimit and Terms     
    2    10 OCT 2024	BHARGAV SALIYA		Updates PercentId, days and NetDays as per CreditTerms     
 
 EXEC [USP_WO_Refresh_CreditLimit_Terms] 3502,4401,true
 --exec dbo.USP_WO_Refresh_CreditLimit_Terms @CustomerId=3502,@wokorderId=4401,@IsGetCustomerCredirTems=1
********************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_WO_Refresh_CreditLimit_Terms]
	@CustomerId BIGINT,
	@workorderId BIGINT,
	@IsGetCustomerCredirTems BIT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @CeraditLimit DECIMAL(18,2),
                @CreditTermsId BIGINT,
				@CreaditTerms VARCHAR(50),
			    @AccountType VARCHAR(50),
				@AccountTypeId BIGINT,
				@CustomerName VARCHAR(100),
				@Days TINYINT,
				@NetDays TINYINT,
				@PercentId BIGINT;

		IF(@IsGetCustomerCredirTems = 1)
		BEGIN
			;WITH Result(CreditLimit, CreditTermId, AccountTypeName, AccountTypeId, CreditTermName, CustomerName) AS(
				SELECT  CF.CreditLimit AS CreditLimit,
						CF.CreditTermsId AS CreditTermId,
						CAF.AccountType AS AccountTypeName,
						C.CustomerAffiliationId AS AccountTypeId ,
						CR.[Name] AS CreditTermName,
						C.[Name] AS CustomerName
				FROM [dbo].[CustomerFinancial]  CF WITH (NOLOCK) 
					 LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = CF.CustomerId
					 LEFT JOIN [dbo].[CreditTerms] CR WITH (NOLOCK) ON CR.CreditTermsId = CF.CreditTermsId
					 LEFT JOIN [dbo].[CustomerAffiliation] CAF WITH (NOLOCK) ON C.CustomerAffiliationId = CAF.CustomerAffiliationId 
				WHERE  CF.CustomerId = @CustomerId)
				SELECT * FROM Result;
		END
		ELSE
		BEGIN
			SELECT @CeraditLimit = CF.CreditLimit,
				   @CreditTermsId = CF.CreditTermsId,
				   @AccountType =  CT.CustomerTypeName,
				   @AccountTypeId = CT.CustomerTypeId ,
				   @CreaditTerms = CR.[Name],
				   @CustomerName = C.[Name],
				   @Days = CR.[Days],
				   @NetDays = CR.NetDays,
				   @PercentId = CR.PercentId
			FROM [dbo].[CustomerFinancial]  CF WITH (NOLOCK) 
		    LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = CF.CustomerId
			LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId
			LEFT JOIN [dbo].[CreditTerms] CR WITH (NOLOCK) ON CR.CreditTermsId = CF.CreditTermsId
		    WHERE  CF.CustomerId = @CustomerId

			UPDATE [dbo].[Workorder]
			SET 
				[CreditTermId] = @CreditTermsId,
				[CreditLimit] =  @CeraditLimit,
				[CustomerName] = @CustomerName,
				[CreditTerms] = @CreaditTerms,
				[PercentId] = @PercentId,
				[Days] = @Days,
				[NetDays] = @NetDays

			FROM [dbo].[Workorder]  
			WHERE WorkorderId = @workorderId AND CustomerId = @CustomerId
			
			SELECT C.CustomerAffiliationId as [AccountTypeId],[CreditTermId],[CreditLimit],[CustomerName],[CreditTerms] as [CreditTermName],CustomerType as [AccountTypeName] 
			FROM [dbo].[Workorder] W WITH (NOLOCK)
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON W.CustomerId = C.CustomerId
			WHERE WorkorderId = @workorderId 
		END
		
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_WO_Refresh_CreditLimit_Terms' 
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