/*********************           
 ** File:   [USP_GetPartPublications]     
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used to get Part Publications
 ** Purpose:         
 ** Date:   27/06/2025    
          
 ** PARAMETERS: @JournalBatchHeaderId bigint
         
 ** RETURN VALUE:           
 **********************           
 ** Change History           
 **********************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    27/06/2025  Moin Bloch			Created
    2    01/07/2025  Devendra Shekh     Allowing to fetch @cmmIds data Despite being Deleted/InActive
    3    11/02/2026   AYUSHI PATEL      Fixed duplicate record issue when applying revisionNumber logic.Moved COUNT() OVER() calculation to outer query after UNION to ensure consistent PublicationId formatting.
 
--   EXEC [dbo].[USP_GetPartPublications] 102544,1,'711'
     EXEC [dbo].[USP_GetPartPublications] 102544,1,''
     EXEC [dbo].[USP_GetPartPublications] 20751,1,''	
	 EXEC [dbo].[USP_GetPartPublications] 96877,1,'1083'
************************/
CREATE   PROCEDURE [dbo].[USP_GetPartPublications]
@ItemMasterId BIGINT = NULL,
@MasterCompanyId BIGINT  = NULL,
@cmmIds VARCHAR(200) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	IF(@cmmIds IS NULL OR @cmmIds = '')
	BEGIN
		SELECT 
			CASE 
				WHEN COUNT(*) OVER (PARTITION BY p.PublicationId) > 1
				THEN p.PublicationId + '_' + CAST(p.RevisionNum AS VARCHAR(20))
				ELSE p.PublicationId
			END AS PublicationId,
			[p].[PublicationRecordId],
			[p].[ExpirationDate],
			'' AS [FileName],
			'' AS [Link],
			[p].[CreatedDate]
		FROM [dbo].[Publication] AS [p] WITH (NOLOCK)
		INNER JOIN [dbo].[PublicationItemMasterMapping] AS [pim] WITH (NOLOCK) ON [p].[PublicationRecordId] = [pim].[PublicationRecordId]
		WHERE [p].[IsDeleted] = 0 AND [p].[IsActive] = 1
		  AND [pim].[IsDeleted] = 0
		  AND [pim].[IsActive] = 1
		  AND [pim].[ItemMasterId] = @ItemMasterId
	END
	ELSE
BEGIN
    ;WITH CombinedData AS
    (
        SELECT
            p.PublicationId,
            p.RevisionNum,
            p.PublicationRecordId,
            p.ExpirationDate,
            p.CreatedDate
        FROM dbo.Publication p WITH (NOLOCK)
        INNER JOIN dbo.PublicationItemMasterMapping pim WITH (NOLOCK)
            ON p.PublicationRecordId = pim.PublicationRecordId
        WHERE p.IsDeleted = 0 
          AND p.IsActive = 1
          AND pim.IsDeleted = 0
          AND pim.IsActive = 1
          AND pim.ItemMasterId = @ItemMasterId

        UNION

        SELECT
            p.PublicationId,
            p.RevisionNum,
            p.PublicationRecordId,
            p.ExpirationDate,
            p.CreatedDate
        FROM dbo.Publication p WITH (NOLOCK)
        INNER JOIN dbo.PublicationItemMasterMapping pim WITH (NOLOCK)
            ON p.PublicationRecordId = pim.PublicationRecordId
        WHERE pim.ItemMasterId = @ItemMasterId
          AND p.PublicationRecordId IN (SELECT Item FROM DBO.SPLITSTRING(@cmmIds, ','))
    )

    SELECT DISTINCT
        CASE 
            WHEN COUNT(*) OVER (PARTITION BY PublicationId) > 1
                THEN PublicationId + '_' + CAST(RevisionNum AS VARCHAR(20))
            ELSE PublicationId
        END AS PublicationId,
        PublicationRecordId,
        ExpirationDate,
        '' AS FileName,
        '' AS Link,
        CreatedDate
    FROM CombinedData;
END

    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'AddUpdateJournalBatchDetails' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS VARCHAR(100))  
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