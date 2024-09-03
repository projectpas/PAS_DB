/*************************************************************           
 ** File:   [USP_GetQuickBookSetupDetails_ById]           
 ** Author:    Devendra Shekh
 ** Description:  TO GET QuickBook Setup Details By Id
 ** Purpose:         
 ** Date:   02-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/02/2024   Devendra Shekh	     CREATED

exec USP_GetQuickBookSetupDetails_ById 
**************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_GetQuickBookSetupDetails_ById]
	@AccountingIntegrationSetupId bigint = null,
	@MasterCompanyId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
				ACI.AccountingIntegrationSetupId, 
				ACI.IntegrationId,
				ISNULL(ACI.ClientId, '') AS 'ClientId',
				ISNULL(ACI.ClientSecret, '') AS 'ClientSecret',
				ISNULL(ACI.RedirectUrl, '') AS 'RedirectUrl',
				ISNULL(ACI.Environment, '') AS 'Environment',
				ISNULL(ACI.APIKey, '') AS 'APIKey',
				ISNULL(ACI.IsEnabled, 0) AS 'IsEnabled',
				ACI.MasterCompanyId,			
				ACI.CreatedDate,
				ACI.CreatedBy,
				ACI.UpdatedDate,
				ACI.UpdatedBy,
				ACI.IsActive,
				ACI.IsDeleted
				FROM dbo.AccountingIntegrationSetup ACI WITH (NOLOCK)
				WHERE	ACI.AccountingIntegrationSetupId = @AccountingIntegrationSetupId AND ACI.MasterCompanyId = @MasterCompanyId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetQuickBookSetupDetails_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@integrationID = '''+ ISNULL(@AccountingIntegrationSetupId, '') + ''
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