/*************************************************************
 ** File:   [usp_ClaimIntegrationEmailForProcessing]
 ** Author:  Bhargav Saliya
 ** Description: Atomically marks an IntegrationEmail as InProgress before RFQ processing starts, so the scheduled
 **              SaveEmailRFQs job and a manual Re-Sync can never process the same email at the same time
 **              (which could create a duplicate RFQ). Returns [IsClaimed] = 1 when the caller may process it.
 ** Purpose:     RFQ Email List - Error Message / Edit / Re-Sync
 ** Date:   12 Oct 2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    12 Oct 2026	Bhargav Saliya		Created

 -- Status ids (EmailStatusEnum): 1 = Pending, 2 = InProgress, 3 = Completed, 4 = Failed
 -- @IsManualResync = 0 (scheduler) never picks Failed emails; 1 (user Re-Sync) may.
 -- An InProgress claim older than 30 minutes is treated as abandoned (e.g. API restarted mid-process).
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_ClaimIntegrationEmailForProcessing]
	@IntegrationEmailID BIGINT,
	@IsManualResync BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @InProgressEmailStatus INT = 2, @CompletedEmailStatus INT = 3, @FailedEmailStatus INT = 4;
		DECLARE @StaleMinutes INT = 30;

		UPDATE IEM
		SET IEM.[EmailStatusId] = @InProgressEmailStatus,
			IEM.[LastProcessedDate] = GETUTCDATE(),
			IEM.[UpdatedDate] = GETUTCDATE()
		FROM [dbo].[IntegrationEmail] IEM WITH(UPDLOCK, ROWLOCK)
		WHERE IEM.[IntegrationEmailID] = @IntegrationEmailID
		  AND IEM.[IsActive] = 1 AND IEM.[IsDeleted] = 0
		  AND IEM.[EmailSection] <> 4 -- Trash
		  -- never re-process an email that already produced an RFQ
		  AND ISNULL(IEM.[CustomerRfqId], 0) = 0
		  AND ISNULL(IEM.[ThirdPartyRFQId], 0) = 0
		  AND NOT EXISTS(SELECT 1 FROM [dbo].[VendorRFQPart] VRP WITH(NOLOCK) WHERE VRP.[IntegrationEmailID] = IEM.[IntegrationEmailID])
		  AND ISNULL(IEM.[EmailStatusId], 0) <> @CompletedEmailStatus
		  AND (@IsManualResync = 1 OR ISNULL(IEM.[EmailStatusId], 0) <> @FailedEmailStatus)
		  AND (ISNULL(IEM.[EmailStatusId], 0) <> @InProgressEmailStatus
			   OR (SELECT MAX(D.[Dt]) FROM (VALUES (IEM.[LastProcessedDate]), (IEM.[UpdatedDate])) D([Dt])) < DATEADD(MINUTE, -@StaleMinutes, GETUTCDATE()));

		DECLARE @RowsClaimed INT = @@ROWCOUNT;

		SELECT CAST(CASE WHEN @RowsClaimed > 0 THEN 1 ELSE 0 END AS BIT) AS [IsClaimed];
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_ClaimIntegrationEmailForProcessing'
		, @ProcedureParameters VARCHAR(3000) = '@IntegrationEmailID = ''' + CAST(ISNULL(@IntegrationEmailID, '') AS VARCHAR(100))
		, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END
