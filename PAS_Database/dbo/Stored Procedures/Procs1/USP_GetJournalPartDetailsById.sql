--exec [USP_GetJournalPartDetailsById] 24

Create   PROCEDURE [dbo].[USP_GetJournalPartDetailsById]
@ManualJournalHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					mjd.ManualJournalDetailsId,
                    mjd.ManualJournalHeaderId,
                    mjd.GlAccountId,
                    mjd.Debit,
                    mjd.Credit,
                    UPPER(mjd.Description) AS [Description],
                    mjd.ManagementStructureId,
                    UPPER(mjd.LastMSLevel) AS [LastMSLevel],
                    UPPER(mjd.AllMSlevels) AS [AllMSlevels],
                    mjd.MasterCompanyId,
                    mjd.CreatedBy,
                    mjd.CreatedDate,
                    mjd.UpdatedBy,
                    mjd.UpdatedDate,
                    gl.AccountCode + ' - ' + UPPER(gl.AccountName) AS  glAccountName,
					UPPER(msd.Level1Name) AS [SE],
					UPPER(msd.Level2Name) AS [BU],
					UPPER(msd.Level3Name) AS [DIV],
					UPPER(msd.Level4Name) AS [DEPT]
				FROM [DBO].[ManualJournalDetails] mjd WITH (NOLOCK) 
				LEFT JOIN [DBO].[ManualJournalHeader] mhd WITH(NOLOCK) ON mjd.ManualJournalHeaderId = mhd.ManualJournalHeaderId
				LEFT JOIN [DBO].[GLAccount] gl WITH(NOLOCK) ON mjd.GLAccountId = gl.GLAccountId
				LEFT JOIN [DBO].[ManagementStructureDetails] msd with(nolock) on mjd.ManagementStructureId = msd.MSDetailsId
				WHERE mjd.ManualJournalHeaderId = @ManualJournalHeaderId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetJournalPartDetailsById' 
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