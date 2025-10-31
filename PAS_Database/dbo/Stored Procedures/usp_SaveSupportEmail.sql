/*************************************************************           
 ** File:   [usp_SaveSupportEmail]           
 ** Author:   Devendra Shekh
 ** Description: This SP is used save email from support gmail account
 ** Purpose:         
 ** Date:   28-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    28-Oct-2025		Devendra Shekh		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveSupportEmail]
@MessageId           NVARCHAR(255) = NULL,
@Subject             VARCHAR(500),
@EmailBody           NVARCHAR(MAX),
@ToEmail             NVARCHAR(320),
@FromEmail           NVARCHAR(320),
@CC                  NVARCHAR(320) = NULL,
@BCC                 NVARCHAR(320) = NULL,
@EmailReadBy         NVARCHAR(320) = NULL,
@HasAttachments      BIT = NULL,
@EmailSection        INT,
@ReceivedDate        DATETIME2(7) = NULL,
@MasterCompanyId     INT,
@CreatedBy           VARCHAR(256),
@UpdatedBy           VARCHAR(256),
@CreatedDate         DATETIME2(7),
@UpdatedDate         DATETIME2(7),
@IsActive            BIT,
@IsDeleted           BIT,
@IsRead              BIT = NULL,
@TicketNumber		 VARCHAR(MAX) = NULL,
@SupportEmailId      BIGINT OUTPUT,
@CustomerTicketId	 BIGINT OUTPUT,
@IsNewEmail			 BIT OUTPUT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON  
	BEGIN TRY  
		
		DECLARE @TotalRecord INT = 0;
		SELECT @CustomerTicketId = 0, @IsNewEmail = 0;

		IF NOT EXISTS(SELECT 1 FROM [dbo].[SupportEmail] WITH(NOLOCK) WHERE [FromEmail] = @FromEmail AND [Subject] = @Subject  AND [EmailReadBy] = @EmailReadBy AND [MessageId] = @MessageId)
		BEGIN
			INSERT INTO [dbo].[SupportEmail] 
			([MessageId],[Subject],[EmailBody],[ToEmail],[FromEmail],[CC],[BCC],[EmailReadBy],[HasAttachments],[EmailSection],[ReceivedDate],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
			[IsActive],[IsDeleted],[IsRead],[IsProcessed],[EmailStatusId],[AttemptCount])
			VALUES 
			(@MessageId,@Subject,@EmailBody,@ToEmail,@FromEmail,@CC,@BCC,@EmailReadBy,@HasAttachments,@EmailSection,@ReceivedDate,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,
			@IsActive,@IsDeleted,@IsRead,0,NULL,NULL);

			SET @SupportEmailId = SCOPE_IDENTITY();	
			SET @IsNewEmail = 1;			
		END
		ELSE
		BEGIN
			SELECT @SupportEmailId = [SupportEmailId], @CustomerTicketId = ISNULL([CustomerTicketId], 0) FROM [dbo].[SupportEmail] WITH(NOLOCK) WHERE [FromEmail] = @FromEmail AND [Subject] = @Subject AND [EmailReadBy] = @EmailReadBy AND [MessageId] = @MessageId;
		END

		IF(ISNULL(@TicketNumber, '') <> '') AND (ISNULL(@CustomerTicketId, 0) = 0)
		BEGIN
			SELECT TOP 1 @CustomerTicketId = ISNULL([CustomerTicketId], 0) FROM [dbo].[CustomerTicket] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [TicketID] = @TicketNumber;

			UPDATE [dbo].[SupportEmail] SET [CustomerTicketId] = @CustomerTicketId WHERE [SupportEmailId] = @SupportEmailId;
		END

	END TRY
	BEGIN CATCH	
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_SaveSupportEmail'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Subject, '') as varchar(255))
			+ '@Parameter2 = ''' + CAST(ISNULL(@ToEmail, '') as varchar(255)) 
			+ '@Parameter3 = ''' + CAST(ISNULL(@FromEmail, '') as varchar(255))  
			+ '@Parameter4 = ''' + CAST(ISNULL(@EmailReadBy, '') as varchar(255))		
			+ '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
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