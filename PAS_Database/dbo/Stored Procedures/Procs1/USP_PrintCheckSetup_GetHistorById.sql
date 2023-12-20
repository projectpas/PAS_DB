--exec [USP_PrintCheckSetup_GetHistorById] 1

CREATE   PROCEDURE [dbo].[USP_PrintCheckSetup_GetHistorById]
@PrintingId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					t.AuditPrintingId,
					t.PrintingId,
					t.StartNum,
					t.ConfirmStartNum,
					t.BankId,
					ISNULL(t.BankName,'') AS BankName,
					t.BankAccountId,
					ISNULL(t.BankAccountNumber,'') AS  BankAccountNumber,
					t.GLAccountId,
					ISNULL(t.GlAccount,'') AS GlAccount,
					t.ConfirmBankAccInfo,
					ISNULL(t.BankRef,'') AS BankRef,
					ISNULL(t.CcardPaymentRef,'') AS CcardPaymentRef,
					CASE WHEN t.[Type] = 1 THEN 'Check' WHEN t.[Type] = 2 THEN 'Wire' WHEN t.[Type] = 3 THEN 'Credit Card' ELSE '' END as 'TypeName',
					t.Type,
					t.MasterCompanyId,
					t.CreatedBy,
					t.UpdatedBy,
					t.CreatedDate,
					t.UpdatedDate,
					t.IsActive,
					t.IsDeleted
				FROM [DBO].[PrintCheckSetupAudit] t WITH (NOLOCK) 
				WHERE t.PrintingId = @PrintingId ORDER BY t.AuditPrintingId DESC
				--WHERE t.PrintingId = @PrintingId AND t.BankName IS NOT NUll ORDER BY t.PrintingId DESC
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PrintCheckSetup_GetHistorById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PrintingId, '') + ''
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