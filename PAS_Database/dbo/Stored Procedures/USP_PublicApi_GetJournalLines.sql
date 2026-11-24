/*************************************************************
 ** File:   [USP_PublicApi_GetJournalLines]
 ** Author: Moin Bloch
 ** Description: Lines (CommonBatchDetails) of the journal entries on one page (@JournalBatchDetailIds: comma separated).
 **              Management structure as saved on the line when the entry was made (AllMSlevels: LE / BU / DIV / DEPT);
 **              lines without it: the line's management structure (EntityStructureSetup).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/journals (lines)
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Moin Bloch    Created

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
            CASE WHEN MS.[Found] = 1 THEN MS.[LE] ELSE ESL.[LE] END AS [LegalEntity],
            CASE WHEN MS.[Found] = 1 THEN MS.[BU] ELSE ESL.[BU] END AS [BusinessUnit],
            CASE WHEN MS.[Found] = 1 THEN MS.[DIV] ELSE ESL.[DIV] END AS [Division],
            CASE WHEN MS.[Found] = 1 THEN MS.[DEPT] ELSE ESL.[DEPT] END AS [Department]
        FROM [dbo].[CommonBatchDetails] C WITH (NOLOCK)
        -- AllMSlevels holds one "LE : ..." / "BU : ..." / "DIV : ..." / "DEPT : ..." per <p> or per line: one level per text line.
        CROSS APPLY (SELECT REPLACE(@NL + REPLACE(REPLACE(REPLACE(ISNULL(C.[AllMSlevels], ''), CHAR(13), ''), '<p>', ''), '</p>', @NL) + @NL,
                                    @NL + ' ', @NL) AS [Text]) X
        CROSS APPLY (SELECT CHARINDEX(@NL + 'LE :', X.[Text]) AS [P1], CHARINDEX(@NL + 'BU :', X.[Text]) AS [P2],
                            CHARINDEX(@NL + 'DIV :', X.[Text]) AS [P3], CHARINDEX(@NL + 'DEPT :', X.[Text]) AS [P4]) P
        CROSS APPLY (SELECT
            CASE WHEN P.[P1] > 0 OR P.[P2] > 0 OR P.[P3] > 0 OR P.[P4] > 0 THEN 1 ELSE 0 END AS [Found],
            CASE WHEN P.[P1] > 0 THEN NULLIF(LTRIM(RTRIM(SUBSTRING(X.[Text], P.[P1] + 5, CHARINDEX(@NL, X.[Text], P.[P1] + 1) - P.[P1] - 5))), '') END AS [LE],
            CASE WHEN P.[P2] > 0 THEN NULLIF(LTRIM(RTRIM(SUBSTRING(X.[Text], P.[P2] + 5, CHARINDEX(@NL, X.[Text], P.[P2] + 1) - P.[P2] - 5))), '') END AS [BU],
            CASE WHEN P.[P3] > 0 THEN NULLIF(LTRIM(RTRIM(SUBSTRING(X.[Text], P.[P3] + 6, CHARINDEX(@NL, X.[Text], P.[P3] + 1) - P.[P3] - 6))), '') END AS [DIV],
            CASE WHEN P.[P4] > 0 THEN NULLIF(LTRIM(RTRIM(SUBSTRING(X.[Text], P.[P4] + 7, CHARINDEX(@NL, X.[Text], P.[P4] + 1) - P.[P4] - 7))), '') END AS [DEPT]) MS
        -- Lines without saved levels: the line's management structure.
        LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.[EntityStructureId] = C.[ManagementStructureId]
        OUTER APPLY (SELECT
            (SELECT L.[Code] + ' - ' + L.[Description] FROM [dbo].[ManagementStructureLevel] L WITH (NOLOCK) WHERE L.[ID] = ES.[Level1Id]) AS [LE],
            (SELECT L.[Code] + ' - ' + L.[Description] FROM [dbo].[ManagementStructureLevel] L WITH (NOLOCK) WHERE L.[ID] = ES.[Level2Id]) AS [BU],
            (SELECT L.[Code] + ' - ' + L.[Description] FROM [dbo].[ManagementStructureLevel] L WITH (NOLOCK) WHERE L.[ID] = ES.[Level3Id]) AS [DIV],
            (SELECT L.[Code] + ' - ' + L.[Description] FROM [dbo].[ManagementStructureLevel] L WITH (NOLOCK) WHERE L.[ID] = ES.[Level4Id]) AS [DEPT]) ESL
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