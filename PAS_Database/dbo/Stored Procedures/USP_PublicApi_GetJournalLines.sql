/*************************************************************
 ** File:   [USP_PublicApi_GetJournalLines]
 ** Author: Moin Bloch
 ** Description: Lines (CommonBatchDetails) of the journal entries on one page (@JournalBatchDetailIds: comma separated).
 **              ManagementStructure = the line's AllMSlevels (saved when the entry was made) as plain text: the <p> tags
 **              removed, one level after the other separated by ", " (the level names are the company's own).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/journals (lines)
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Moin Bloch    Created
    2    24/11/2026   Moin Bloch    Management structure as one text (AllMSlevels without <p>), no fixed level labels

  EXEC [dbo].[USP_PublicApi_GetJournalLines] @MasterCompanyId = 1, @JournalBatchDetailIds = '5640'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetJournalLines]
    @MasterCompanyId       INT,
    @JournalBatchDetailIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @NL CHAR(1) = CHAR(10);
        DECLARE @Edge CHAR(1) = CHAR(1);

        SELECT
            -- Ids are used by the API to group lines per journal entry; not returned to clients.
            C.[JournalBatchDetailId],
            C.[CommonJournalBatchDetailId],
            C.[LineNumber],
            C.[GlAccountNumber],
            NULLIF(LTRIM(RTRIM(C.[GlAccountName])), '') AS [GlAccountDescription],
            ISNULL(C.[DebitAmount], 0) AS [DebitAmount],
            ISNULL(C.[CreditAmount], 0) AS [CreditAmount],
            C.[TransactionDate],
            -- Levels joined with ", "; a separator at the start or end is dropped (@Edge marks both ends).
            NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@Edge + REPLACE(T.[Text], @NL, ', ') + @Edge, @Edge + ', ', ''), ', ' + @Edge, ''), @Edge, ''))), '') AS [ManagementStructure]
        FROM [dbo].[CommonBatchDetails] C WITH (NOLOCK)
        -- AllMSlevels is HTML (<p>level</p><p>level</p>) or one level per text line: one level per line, spaces tidied.
        -- Each step uses the previous text once (SQL Server repeats an expression for every reference).
        CROSS APPLY (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.[AllMSlevels], ''), CHAR(13), ''), '</p><p>', @NL), '<p>', ''), '</p>', ''),
                                    CHAR(9), ' ') AS [Text]) A
        CROSS APPLY (SELECT REPLACE(REPLACE(REPLACE(A.[Text], ' ', '<>'), '><', ''), '<>', ' ') AS [Text]) B   -- runs of spaces -> one space
        CROSS APPLY (SELECT REPLACE(REPLACE(REPLACE(REPLACE(B.[Text], @NL + ' ', @NL), ' ' + @NL, @NL), @NL + @NL, @NL), @NL + @NL, @NL) AS [Text]) T
        WHERE C.[JournalBatchDetailId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@JournalBatchDetailIds, ','))
          AND C.[MasterCompanyId] = @MasterCompanyId
          AND C.[IsDeleted] = 0
        ORDER BY C.[JournalBatchDetailId], C.[CommonJournalBatchDetailId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetJournalLines'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@JournalBatchDetailIds, '') AS VARCHAR(100))
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