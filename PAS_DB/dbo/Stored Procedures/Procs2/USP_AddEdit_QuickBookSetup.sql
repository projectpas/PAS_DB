/*************************************************************           
 ** File:   [USP_AddEdit_QuickBookSetup]           
 ** Author:    Devendra Shekh
 ** Description:  to add/update the quickbook setup data
 ** Purpose:         
 ** Date:   02-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/02/2024   Devendra Shekh	     CREATED

exec USP_AddEdit_QuickBookSetup 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_AddEdit_QuickBookSetup]
@AccountingIntegrationSetupId BIGINT = NULL,
@IntegrationId INT = NULL,
@ClientId VARCHAR(500) = NULL,
@ClientSecret VARCHAR(500) = NULL,
@RedirectUrl VARCHAR(5000) = NULL,
@Environment VARCHAR(500) = NULL,
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy  VARCHAR(256) = NULL,
@IsDeleted BIT = NULL,
@IsEnabled BIT = NULL,
@APIKey VARCHAR(500) = NULL

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				IF(ISNULL(@AccountingIntegrationSetupId, 0) = 0)
				BEGIN
       				INSERT INTO [dbo].[AccountingIntegrationSetup] ([IntegrationId], [ClientId], [ClientSecret], [RedirectUrl], [Environment], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate], [IsActive], [IsDeleted], [IsEnabled], [APIKey])
					VALUES (@IntegrationId, @ClientId, @ClientSecret, @RedirectUrl, @Environment, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @IsEnabled, @APIKey)
				END
				ELSE
				BEGIN
					UPDATE [dbo].[AccountingIntegrationSetup]
					SET 
						[IntegrationId] = @IntegrationId
					   ,[ClientId] = @ClientId
					   ,[ClientSecret] = @ClientSecret
					   ,[RedirectUrl] = @RedirectUrl
					   ,[Environment] = @Environment 
					   ,[IsEnabled] = @IsEnabled
					   ,[APIKey] = @APIKey
					   ,[UpdatedBy] = @UpdatedBy
					   ,[UpdatedDate] = GETUTCDATE()
					   ,[IsDeleted] = @IsDeleted
				  WHERE AccountingIntegrationSetupId= @AccountingIntegrationSetupId
				END			
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEdit_QuickBookSetup' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AccountingIntegrationSetupId, '') + ''
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