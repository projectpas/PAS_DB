/*************************************************************
 ** File:   [usp_SaveIntegrationEmailProcessResult]
 ** Author:  Bhargav Saliya
 ** Description: Saves the RFQ processing result (status + specific error) against an IntegrationEmail
 **              and writes a row to IntegrationEmailProcessHistory for every attempt.
 ** Purpose:     RFQ Email List - Error Message / Edit / Re-Sync
 ** Date:   12 Oct 2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    12 Oct 2026	Bhargav Saliya		Created

 -- Status ids (EmailStatusEnum): 1 = Pending, 2 = InProgress, 3 = Completed, 4 = Failed
 -- @IncrementAttempt = 1 : technical/retryable failure (keeps usp_UpdateIntegrationEmailStatus 10-try limit)

 EXEC [dbo].[usp_SaveIntegrationEmailProcessResult] 1, 4, 'Customer is missing', 'CustomerRFQ', NULL, 'Auto', 0, 'System'
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveIntegrationEmailProcessResult]
	@IntegrationEmailID BIGINT,
	@EmailStatusId INT,
	@ErrorMessage NVARCHAR(1000) = NULL,
	@RfqType VARCHAR(50) = NULL,
	@ExtractedData NVARCHAR(MAX) = NULL,
	@ProcessSource VARCHAR(50) = 'Auto',
	@IncrementAttempt BIT = 0,
	@ProcessedBy VARCHAR(256) = 'System'
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @PendingEmailStatus INT = 1, @CompletedEmailStatus INT = 3, @FailedEmailStatus INT = 4;
		DECLARE @TryLimit INT = 10;

		BEGIN TRANSACTION;

			UPDATE IEM
			SET IEM.[EmailStatusId] = CASE WHEN @IncrementAttempt = 1 AND @EmailStatusId = @PendingEmailStatus AND ISNULL(IEM.[AttemptCount], 0) + 1 >= @TryLimit
										   THEN @FailedEmailStatus ELSE @EmailStatusId END,
				IEM.[AttemptCount] = CASE WHEN @IncrementAttempt = 1 THEN ISNULL(IEM.[AttemptCount], 0) + 1 ELSE IEM.[AttemptCount] END,
				-- A successful run always clears the previous error
				IEM.[ErrorMessage] = CASE WHEN @EmailStatusId = @CompletedEmailStatus THEN NULL
										  ELSE COALESCE(NULLIF(LTRIM(RTRIM(@ErrorMessage)), ''), IEM.[ErrorMessage], N'Processing failed after maximum retry attempts') END,
				IEM.[RfqType] = COALESCE(@RfqType, IEM.[RfqType]),
				IEM.[ExtractedData] = COALESCE(@ExtractedData, IEM.[ExtractedData]),
				IEM.[LastProcessedDate] = GETUTCDATE(),
				IEM.[UpdatedBy] = ISNULL(@ProcessedBy, IEM.[UpdatedBy]),
				IEM.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[IntegrationEmail] IEM
			WHERE IEM.[IntegrationEmailID] = @IntegrationEmailID;

			INSERT INTO [dbo].[IntegrationEmailProcessHistory]
				([IntegrationEmailID], [EmailStatusId], [ErrorMessage], [RfqType], [ExtractedData], [AttemptCount], [ProcessSource], [MasterCompanyId], [CreatedBy], [CreatedDate])
			SELECT IEM.[IntegrationEmailID], IEM.[EmailStatusId], IEM.[ErrorMessage], IEM.[RfqType], IEM.[ExtractedData], IEM.[AttemptCount],
				   ISNULL(@ProcessSource, 'Auto'), IEM.[MasterCompanyId], ISNULL(@ProcessedBy, 'System'), GETUTCDATE()
			FROM [dbo].[IntegrationEmail] IEM WITH(NOLOCK)
			WHERE IEM.[IntegrationEmailID] = @IntegrationEmailID;

		COMMIT TRANSACTION;

		SELECT IEM.[IntegrationEmailID], IEM.[EmailStatusId], IEM.[ErrorMessage]
		FROM [dbo].[IntegrationEmail] IEM WITH(NOLOCK)
		WHERE IEM.[IntegrationEmailID] = @IntegrationEmailID;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_SaveIntegrationEmailProcessResult'
		, @ProcedureParameters VARCHAR(3000) = '@IntegrationEmailID = ''' + CAST(ISNULL(@IntegrationEmailID, '') AS VARCHAR(100))
										   + '@EmailStatusId = ''' + CAST(ISNULL(@EmailStatusId, '') AS VARCHAR(100))
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
