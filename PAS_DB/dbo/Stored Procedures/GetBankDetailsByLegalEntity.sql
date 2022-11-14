--EXEC GetBankDetailsByLegalEntity 1
CREATE PROCEDURE [dbo].[GetBankDetailsByLegalEntity]
@LegalEntityId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
			select LegalEntityBankingLockBoxId as 'BankingId',BankName,BankAccountNumber as 'BankAccountNumber','Lockbox' as 'Type',GLAccountId from dbo.LegalEntityBankingLockBox WITH(NOLOCK)
			where LegalEntityId=@LegalEntityId
			UNION ALL
			select iwp.InternationalWirePaymentId as 'BankingId',BankName,iwp.BeneficiaryBankAccount as 'BankAccountNumber','WirePayment' as 'Type',iwp.GLAccountId from dbo.InternationalWirePayment iwp WITH(NOLOCK)
			inner join dbo.LegalEntityInternationalWireBanking leiwp WITH(NOLOCK) on iwp.InternationalWirePaymentId = leiwp.InternationalWirePaymentId
			where leiwp.LegalEntityId=@LegalEntityId
			UNION
			select ACHId as 'BankingId',BankName,AccountNumber as 'BankAccountNumber','ACH' as 'Type',GLAccountId from dbo.ACH WITH(NOLOCK)
			where LegalEntityId=@LegalEntityId
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetBankDetailsByLegalEntity' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END