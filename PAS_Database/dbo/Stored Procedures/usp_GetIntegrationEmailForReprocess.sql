/*************************************************************
 ** File:   [usp_GetIntegrationEmailForReprocess]
 ** Author:  Bhargav Saliya
 ** Description: Returns one IntegrationEmail (any status) with its RFQ processing status, error and extracted data,
 **              plus its attachments. Used by the Email List Edit popup and the manual Re-Sync.
 ** Purpose:     RFQ Email List - Error Message / Edit / Re-Sync
 ** Date:   12 Oct 2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    12 Oct 2026	Bhargav Saliya		Created

 EXEC [dbo].[usp_GetIntegrationEmailForReprocess] 1, 1
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetIntegrationEmailForReprocess]
	@IntegrationEmailID BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT	IE.[IntegrationEmailID], IE.[Subject], IE.[EmailBody], IE.[ToEmail], IE.[FromEmail], IE.[CC], IE.[BCC], IE.[EmailReadBy], IE.[ReferenceId], IE.[ModuleId],
				IE.[EmailStatus], IE.[HasAttachments], IE.[EmailSection], IE.[ReceivedDate], IE.[MasterCompanyId], IE.[CreatedBy], IE.[UpdatedBy], IE.[CreatedDate],
				IE.[UpdatedDate], IE.[IsActive], IE.[IsDeleted], IE.[CustomerRfqId], IE.[IsProcessed], IE.[EmailStatusId], IE.[AttemptCount],
				IE.[ThirdPartyRFQId], IE.[ErrorMessage], IE.[RfqType], IE.[ExtractedData], ST.[EmailStatusName], ST.[IsEditable]
		FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)
		CROSS APPLY [dbo].[udfGetIntegrationEmailRfqStatus](IE.[IntegrationEmailID], IE.[EmailStatusId], IE.[CustomerRfqId], IE.[ThirdPartyRFQId], IE.[EmailSection], IE.[LastProcessedDate]) ST
		WHERE IE.[IntegrationEmailID] = @IntegrationEmailID
		  AND IE.[MasterCompanyId] = @MasterCompanyId
		  AND IE.[IsActive] = 1 AND IE.[IsDeleted] = 0;

		SELECT IEA.[IntegrationEmailAttachmentID], IEA.[IntegrationEmailID], IEA.[AttachmentName], IEA.[AttachmentPath]
		FROM [dbo].[IntegrationEmailAttachment] IEA WITH(NOLOCK)
		INNER JOIN [dbo].[IntegrationEmail] IE WITH(NOLOCK) ON IE.[IntegrationEmailID] = IEA.[IntegrationEmailID]
		WHERE IEA.[IntegrationEmailID] = @IntegrationEmailID
		  AND IE.[MasterCompanyId] = @MasterCompanyId;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_GetIntegrationEmailForReprocess'
		, @ProcedureParameters VARCHAR(3000) = '@IntegrationEmailID = ''' + CAST(ISNULL(@IntegrationEmailID, '') AS VARCHAR(100))
										   + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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
