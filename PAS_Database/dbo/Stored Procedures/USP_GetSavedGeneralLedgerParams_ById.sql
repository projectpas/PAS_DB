/*************************************************************           
 ** File:   [USP_GetSavedGeneralLedgerParams_ById]           
 ** Author:    Devendra Shekh
 ** Description:  Get Saved General Ledger Params ById
 ** Purpose:         
 ** Date:   23-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/23/2024   Devendra Shekh	     CREATED

exec USP_GetSavedGeneralLedgerParams_ById 1,1
**************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_GetSavedGeneralLedgerParams_ById]
	@GeneralLedgerSearchParamsId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
					GeneralLedgerSearchParamsId,
					UrlName,
					FromEffectiveDate,
					ToEffectiveDate,
					ISNULL(FromJournalId, '') AS 'FromJournalId',
					ISNULL(ToJournalId, '') AS 'ToJournalId',
					ISNULL(FromGLAccount, '') AS 'FromGLAccount',
					ISNULL(ToGLAccount, '') AS 'ToGLAccount',
					ISNULL(EmployeeId, 0) AS 'EmployeeId',
					ISNULL(Level1, '') AS 'Level1',
					ISNULL(Level2, '') AS 'Level2',
					ISNULL(Level3, '') AS 'Level3',
					ISNULL(Level4, '') AS 'Level4',
					ISNULL(Level5, '') AS 'Level5',
					ISNULL(Level6, '') AS 'Level6',
					ISNULL(Level7, '') AS 'Level7',
					ISNULL(Level8, '') AS 'Level8',
					ISNULL(Level9, '') AS 'Level9',
					ISNULL(Level10, '') AS 'Level10',
					MasterCompanyId,
					CreatedBy,
					CreatedDate,
					UpdatedBy,
					UpdatedDate,
					IsActive,
					IsDeleted
				FROM dbo.GeneralLedgerSearchParams GLSP WITH (NOLOCK)
				WHERE	GLSP.GeneralLedgerSearchParamsId = @GeneralLedgerSearchParamsId AND GLSP.MasterCompanyId = @MasterCompanyId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSavedGeneralLedgerParams_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@integrationID = '''+ ISNULL(@GeneralLedgerSearchParamsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END