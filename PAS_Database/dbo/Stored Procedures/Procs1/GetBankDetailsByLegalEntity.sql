
-- EXEC GetBankDetailsByLegalEntity 1
CREATE     PROCEDURE [dbo].[GetBankDetailsByLegalEntity]
@LegalEntityId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
			SELECT LegalEntityBankingLockBoxId AS 'BankingId',BankName,BankAccountNumber AS 'BankAccountNumber','Operating Account' AS 'Type',GLAccountId,CASE WHEN IsPrimay = 1 THEN 1 ELSE 0 END AS IsPrimay,LegalEntityId FROM dbo.LegalEntityBankingLockBox WITH(NOLOCK)
			WHERE LegalEntityId=@LegalEntityId AND (AccountTypeId=1 OR AccountTypeId=3)
			UNION ALL
			SELECT iwp.InternationalWirePaymentId AS 'BankingId',BankName,iwp.BeneficiaryBankAccount AS 'BankAccountNumber','WirePayment' AS 'Type',iwp.GLAccountId,CASE WHEN IsPrimay = 1 THEN 1 ELSE 0 END AS IsPrimay,LegalEntityId FROM dbo.InternationalWirePayment iwp WITH(NOLOCK)
			INNER JOIN dbo.LegalEntityInternationalWireBanking leiwp WITH(NOLOCK) ON iwp.InternationalWirePaymentId = leiwp.InternationalWirePaymentId
			WHERE leiwp.LegalEntityId=@LegalEntityId
			UNION
			SELECT ACHId AS 'BankingId',BankName,AccountNumber AS 'BankAccountNumber','ACH' AS 'Type',GLAccountId,CASE WHEN IsPrimay = 1 THEN 1 ELSE 0 END AS IsPrimay,LegalEntityId FROM dbo.ACH WITH(NOLOCK)
			WHERE LegalEntityId=@LegalEntityId
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