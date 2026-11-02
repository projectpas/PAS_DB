/*************************************************************
 ** File:   [USP_GetDueQuickBooksAutoSyncModules]
 ** Author:    Moin Bloch
 ** Description: Returns QuickBooks modules whose sync Interval (minutes) has elapsed since LastRun
 **              and stamps LastRun so the same module is not picked again before the next interval
 ** Purpose:
 ** Date:   11/02/2026
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date			Author			Change Description
 ** --   --------		-------			--------------------------------
	1    11/02/2026     Moin Bloch	     CREATED

 EXEC [dbo].[USP_GetDueQuickBooksAutoSyncModules] 1
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDueQuickBooksAutoSyncModules]
	@MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		DECLARE @QBIntegrationTypeId INT = 1;

        UPDATE [dbo].[AccountingIntegrationSettings]
           SET [LastRun] = GETUTCDATE()
        OUTPUT INSERTED.[AccountingIntegrationSettingsId],
               INSERTED.[IntegrationId],
               INSERTED.[ModuleId],
               INSERTED.[ModuleName],
               INSERTED.[MasterCompanyId]
         WHERE [MasterCompanyId] = @MasterCompanyId
           AND [IntegrationId]   = @QBIntegrationTypeId
           AND [IsActive]        = 1
           AND [IsDeleted]       = 0
           AND ISNULL([AllowBulkSync], 0) = 1
           AND ISNULL([Interval], 0) > 0
           AND DATEADD(MINUTE, [Interval], [LastRun]) <= GETUTCDATE();
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID            INT,
                @DatabaseName          VARCHAR(100) = DB_NAME(),
                @AdhocComments         VARCHAR(150)  = 'USP_GetDueQuickBooksAutoSyncModules',
                @ProcedureParameters   VARCHAR(3000) = '@MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(50)),
                @ApplicationName       VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName         = @DatabaseName,
            @AdhocComments        = @AdhocComments,
            @ProcedureParameters  = @ProcedureParameters,
            @ApplicationName      = @ApplicationName,
            @ErrorLogID           = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END
