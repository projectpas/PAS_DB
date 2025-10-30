/*************************************************************           
 ** File:   [usp_GetSupportEmail]           
 ** Author:   Devendra Shekh
 ** Description: This SP is used to get the SupportEmail Data 
 ** Purpose:         
 ** Date:   29-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    29-Oct-2025		Devendra Shekh		Created

EXEC [DBO].[usp_GetSupportEmail] 1, 'email.poweraerosuites@gmail.com'
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetSupportEmail]
(
    @MasterCompanyId INT = NULL,
    @EmailReadBy NVARCHAR(320) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY 

		SELECT TOP 1
			[SupportEmailId],
			[CustomerTicketId],
			[MessageId],
			[Subject],
			[EmailBody],
			[ToEmail],
			[FromEmail],
			[CC],
			[BCC],
			[EmailReadBy],
			[HasAttachments],
			[EmailSection],
			[ReceivedDate],
			[MasterCompanyId],
			[CreatedBy],
			[UpdatedBy],
			[CreatedDate],
			[UpdatedDate],
			[IsActive],
			[IsDeleted],
			[IsRead],
			[IsProcessed],
			[EmailStatusId],
			[AttemptCount]
		FROM [dbo].[SupportEmail] WITH (NOLOCK)
		WHERE [EmailReadBy] = @EmailReadBy AND [IsActive] = 1 AND [IsDeleted] = 0
		ORDER BY [ReceivedDate] DESC;

	END TRY
		BEGIN CATCH	
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetSupportEmail'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(255))
			+ '@Parameter2 = ''' + CAST(ISNULL(@EmailReadBy, '') as varchar(100)) 
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END