--exec [USP_GetJournalHeaderDetailsById] 24


Create   PROCEDURE [dbo].[USP_GetJournalHeaderDetailsById]
@ManualJournalHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					mhd.ManualJournalHeaderId,
					mhd.LedgerId,
					UPPER(lg.LedgerName) AS [LedgerName],
					UPPER(le.Name) AS [Name],
					mhd.JournalNumber,
					UPPER(mhd.JournalDescription) AS [JournalDescription],
					mhd.EntryDate,
					mhd.AccountingPeriodId,
					acc.PeriodName,
					mhd.EmployeeId,
					em.FirstName + ' ' + em.LastName AS [User],
					mhd.FunctionalCurrencyId,
					cr.CurrencyId,
					cr.Code,
					CASE
						WHEN mhd.IsRecuring = 1 THEN 'Yes'
						ELSE 'No' End As [RECURING],
					CASE
						WHEN mhd.IsRecuring = 1 THEN 'No'
						ELSE 'Yes' End As [REVERSING]
				FROM [DBO].ManualJournalHeader mhd WITH (NOLOCK) 
				LEFT JOIN [DBO].[AccountingCalendar] acc WITH(NOLOCK) ON acc.AccountingCalendarId = mhd.AccountingPeriodId
				LEFT JOIN [DBO].[Employee] em WITH(NOLOCK) ON em.EmployeeId = mhd.EmployeeId
				LEFT JOIN [DBO].[Ledger] lg WITH(NOLOCK) ON lg.LedgerId = mhd.LedgerId
				LEFT JOIN [DBO].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = mhd.LedgerId
				LEFT JOIN [DBO].[Currency] cr WITH(NOLOCK) ON cr.CurrencyId = mhd.FunctionalCurrencyId
				--LEFT JOIN [DBO].[ManualJournalHeader] mhd WITH(NOLOCK) ON mjd.ManualJournalHeaderId = mhd.ManualJournalHeaderId
				--LEFT JOIN [DBO].[GLAccount] gl WITH(NOLOCK) ON mjd.GLAccountId = gl.GLAccountId
				WHERE mhd.ManualJournalHeaderId = @ManualJournalHeaderId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetJournalHeaderDetailsById' 
              , @ProcedureParameters VARCHAR(3000)  = '@ManualJournalHeaderId = '''+ ISNULL(@ManualJournalHeaderId, '') + ''
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