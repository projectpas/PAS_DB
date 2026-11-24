/*************************************************************
 ** File:   [USP_PublicApi_GetJournalList]
 ** Author: Moin Bloch
 ** Description: Journal entries (BatchDetails) of the company, newest first (latest batch first, then latest JE), like the PAS Batch Listing / batch detail view.
 **              @Status is the JE status (Open, Printed, Posted); @JournalType the JE Type code (e.g. RPO, WIP, MJB);
 **              @EntryDateFrom / @EntryDateTo: entry date range, both inclusive (dates only).
 **              EffectiveDate = the manual journal's effective date, else the JE's transaction date (first line).
 **              PostDate / PostedBy only when the JE is posted, as the PAS Batch Listing.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/journals (journal entries)
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetJournalList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetJournalList]
    @MasterCompanyId  INT,
    @PageNumber       INT,
    @PageSize         INT,
    @BatchNumber      VARCHAR(50) = NULL,
    @JENumber         VARCHAR(50) = NULL,
    @JournalType      VARCHAR(50) = NULL,
    @Status           VARCHAR(50) = NULL,
    @AccountingPeriod VARCHAR(50) = NULL,
    @EntryDateFrom    DATE = NULL,
    @EntryDateTo      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH PagedJournal AS
        (
            SELECT D.[JournalBatchDetailId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[BatchDetails] D WITH (NOLOCK)
            INNER JOIN [dbo].[BatchHeader] H WITH (NOLOCK) ON H.[JournalBatchHeaderId] = D.[JournalBatchHeaderId]
            LEFT JOIN [dbo].[JournalType] JT WITH (NOLOCK) ON JT.[ID] = D.[JournalTypeId]
            LEFT JOIN [dbo].[BatchStatus] BS WITH (NOLOCK) ON BS.[Id] = D.[StatusId]
            WHERE H.[MasterCompanyId] = @MasterCompanyId
              AND H.[IsDeleted] = 0
              AND D.[IsDeleted] = 0
              AND (@BatchNumber IS NULL OR H.[BatchName] = @BatchNumber)
              AND (@JENumber IS NULL OR D.[JournalTypeNumber] = @JENumber)
              AND (@JournalType IS NULL OR JT.[JournalTypeCode] = @JournalType)
              AND (@Status IS NULL OR BS.[Name] = @Status)
              AND (@AccountingPeriod IS NULL OR D.[AccountingPeriod] = @AccountingPeriod)
              AND (@EntryDateFrom IS NULL OR D.[EntryDate] >= @EntryDateFrom)
              AND (@EntryDateTo IS NULL OR D.[EntryDate] < DATEADD(DAY, 1, @EntryDateTo))
            ORDER BY D.[JournalBatchHeaderId] DESC, D.[JournalBatchDetailId] DESC
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            D.[JournalBatchDetailId],   -- used by the API to attach the lines; not returned to clients
            H.[BatchName] AS [BatchNumber],
            D.[JournalTypeNumber] AS [JENumber],
            JT.[JournalTypeCode] AS [JournalType],
            D.[EntryDate],
            COALESCE(MJ.[EffectiveDate], TX.[TransactionDate]) AS [EffectiveDate],
            D.[AccountingPeriod],
            NULLIF(LTRIM(RTRIM(D.[CreatedBy])), '') AS [CreatedBy],
            -- As the PAS batch detail view (Input Method column).
            CASE WHEN ISNULL(D.[IsReversedJE], 0) = 1 THEN UPPER(D.[JournalTypeName]) + ' (REVERSED)' ELSE UPPER(D.[JournalTypeName]) END AS [InputMethod],
            BS.[Name] AS [Status],
            CASE WHEN BS.[Name] = 'Posted' THEN D.[PostedDate] END AS [PostDate],
            CASE WHEN BS.[Name] = 'Posted' THEN NULLIF(LTRIM(RTRIM(D.[PostedBy])), '') END AS [PostedBy],
            TX.[LineCount],
            P.[TotalRecords]
        FROM PagedJournal P
        INNER JOIN [dbo].[BatchDetails] D WITH (NOLOCK) ON D.[JournalBatchDetailId] = P.[JournalBatchDetailId]
        INNER JOIN [dbo].[BatchHeader] H WITH (NOLOCK) ON H.[JournalBatchHeaderId] = D.[JournalBatchHeaderId]
        LEFT JOIN [dbo].[JournalType] JT WITH (NOLOCK) ON JT.[ID] = D.[JournalTypeId]
        LEFT JOIN [dbo].[BatchStatus] BS WITH (NOLOCK) ON BS.[Id] = D.[StatusId]
        OUTER APPLY (SELECT COUNT(1) AS [LineCount], MIN(C.[TransactionDate]) AS [TransactionDate]
                     FROM [dbo].[CommonBatchDetails] C WITH (NOLOCK)
                     WHERE C.[JournalBatchDetailId] = D.[JournalBatchDetailId] AND C.[IsDeleted] = 0) TX
        -- Manual journal entries: the effective date of the manual journal.
        OUTER APPLY (SELECT TOP (1) M.[EffectiveDate]
                     FROM [dbo].[CommonBatchDetails] C WITH (NOLOCK)
                     INNER JOIN [dbo].[ManualJournalHeader] M WITH (NOLOCK) ON M.[ManualJournalHeaderId] = C.[ReferenceId]
                     WHERE C.[JournalBatchDetailId] = D.[JournalBatchDetailId] AND C.[ReferenceModule] = 'MANUALJOURNAL') MJ
        ORDER BY D.[JournalBatchHeaderId] DESC, D.[JournalBatchDetailId] DESC
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetJournalList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@BatchNumber, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@JENumber, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@JournalType, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@AccountingPeriod, '') AS VARCHAR(100))
                                                   + '@Parameter9 = ''' + CAST(ISNULL(@EntryDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter10 = ''' + CAST(ISNULL(@EntryDateTo, '') AS VARCHAR(100))
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