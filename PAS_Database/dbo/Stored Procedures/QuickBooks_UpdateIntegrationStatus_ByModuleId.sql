/*************************************************************           
 ** File:   [QuickBooks_UpdateIntegrationStatus_ByModuleId]           
 ** Author:   Devendra Shekh
 ** Description: Update AccountingIntegrationSettings [IntigrationStatus] by moduleId
 ** Date:    27-March-2024
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date					Author				Change Description            
 ** --   --------				-------				--------------------------------          
    1    27-March-2024			Devendra Shekh			Created
    2    02-Nov-2026			Moin Bloch				Removed NOLOCK on update target, corrected error log SP name and parameters

 EXECUTE [QuickBooks_UpdateIntegrationStatus_ByModuleId] 1, 10, '150'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_UpdateIntegrationStatus_ByModuleId]
@IntegrationTypeId INT = NULL,
@MasterCompanyId INT = NULL,
@ModuleId BIGINT = NULL,
@IntegrationStatus VARCHAR(200) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	BEGIN TRY

		/********
		Status For Integration:

		Disconnected
		Connected
		In Progress
		Failed
		Completed
		Pending
		********/
		IF(ISNULL(@ModuleId, 0) = 0)
		BEGIN
			UPDATE ACI
			SET [IntigrationStatus] = @IntegrationStatus 
			FROM dbo.AccountingIntegrationSettings ACI
			WHERE ACI.[IntegrationId] = @IntegrationTypeId AND ACI.[MasterCompanyId] = @MasterCompanyId;
		END
		ELSE
		BEGIN
			UPDATE ACI
			SET [IntigrationStatus] = @IntegrationStatus 
			FROM dbo.AccountingIntegrationSettings ACI
			WHERE ACI.[ModuleId] = @ModuleId AND ACI.[IntegrationId] = @IntegrationTypeId AND ACI.[MasterCompanyId] = @MasterCompanyId;
		END

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_UpdateIntegrationStatus_ByModuleId'
			,@ProcedureParameters VARCHAR(3000) = '@IntegrationTypeId = ' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))
												+ ', @MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
												+ ', @ModuleId = ' + CAST(ISNULL(@ModuleId, '') AS varchar(100))
												+ ', @IntegrationStatus = ' + ISNULL(@IntegrationStatus, '')
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END