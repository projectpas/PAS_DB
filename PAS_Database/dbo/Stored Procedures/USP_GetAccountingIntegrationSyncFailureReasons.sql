/*************************************************************
 ** File:   [USP_GetAccountingIntegrationSyncFailureReasons]
 ** Author:    Moin Bloch
 ** Description: Groups the error messages returned by QuickBooks (logged in AccountingIntegrationLogs)
 **              for one module since the sync started, so the UI can show why records failed
 ** Purpose:
 ** Date:   11/02/2026
 ** PARAMETERS:
 ** RETURN VALUE: Reason, FailedCount
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date			Author			Change Description
 ** --   --------		-------			--------------------------------
	1    11/02/2026     Moin Bloch	     CREATED

 EXEC [dbo].[USP_GetAccountingIntegrationSyncFailureReasons] 1, 2, 1, '2026-11-02 16:44:00'
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetAccountingIntegrationSyncFailureReasons]
	@IntegrationId   INT,
	@ModuleId        BIGINT,
	@MasterCompanyId INT,
	@FromDate        DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
		;WITH Faults AS (
			SELECT [ReferenceId],
				   CASE WHEN [Payload] LIKE '%<Message>%</Message>%'
						THEN SUBSTRING([Payload], CHARINDEX('<Message>', [Payload]) + 9,
									   CHARINDEX('</Message>', [Payload]) - CHARINDEX('<Message>', [Payload]) - 9)
						WHEN [Payload] LIKE '%"Message":"%'
						THEN SUBSTRING([Payload], CHARINDEX('"Message":"', [Payload]) + 11,
									   CHARINDEX('"', [Payload], CHARINDEX('"Message":"', [Payload]) + 11) - CHARINDEX('"Message":"', [Payload]) - 11)
				   END AS [Reason]
			  FROM [dbo].[AccountingIntegrationLogs] WITH (NOLOCK)
			 WHERE [IntegrationId]   = @IntegrationId
			   AND [ModuleId]        = @ModuleId
			   AND [MasterCompanyId] = @MasterCompanyId
			   AND [CreatedDate]    >= @FromDate
			   AND ([Payload] LIKE '%<Fault%' OR [Payload] LIKE '%"Fault"%')
		)
		SELECT LTRIM(RTRIM([Reason])) AS [Reason],
			   COUNT(DISTINCT [ReferenceId]) AS [FailedCount]
		  FROM Faults
		 WHERE ISNULL([Reason], '') <> ''
		 GROUP BY LTRIM(RTRIM([Reason]))
		 ORDER BY [FailedCount] DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID            INT,
                @DatabaseName          VARCHAR(100) = DB_NAME(),
                @AdhocComments         VARCHAR(150)  = 'USP_GetAccountingIntegrationSyncFailureReasons',
                @ProcedureParameters   VARCHAR(3000) = '@IntegrationId = ' + CAST(ISNULL(@IntegrationId, '') AS VARCHAR(50)) +
														', @ModuleId = ' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(50)) +
														', @MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(50)),
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
