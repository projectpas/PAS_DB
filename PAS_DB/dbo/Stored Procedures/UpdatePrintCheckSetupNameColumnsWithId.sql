-- =============================================
-- =============================================
--  EXEC [dbo].[UpdatePrintCheckSetupNameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdatePrintCheckSetupNameColumnsWithId]
	@PrintingId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		UPDATE P
		SET BankName = LC.BankName,
		BankAccountNumber = LCBN.BankAccountNumber,
		GlAccount = (GL.AccountCode + ' - ' + GL.AccountName)
		FROM PrintCheckSetup P WITH(NOLOCK)
		LEFT JOIN LegalEntityBankingLockBox LC WITH(NOLOCK) ON P.BankId = LC.LegalEntityBankingLockBoxId
		LEFT JOIN LegalEntityBankingLockBox LCBN WITH(NOLOCK) ON P.BankAccountId = LCBN.LegalEntityBankingLockBoxId
		LEFT JOIN GLAccount GL WITH(NOLOCK) ON P.GLAccountId = GL.GLAccountId
		WHERE P.PrintingId = @PrintingId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdatePrintCheckSetupNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PrintingId, '') + ''
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