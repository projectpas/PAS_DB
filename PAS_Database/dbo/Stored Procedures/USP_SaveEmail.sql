/*************************************************************           
 ** File: [USP_SaveEmail]           
 ** Author: Bhargav Saliya
 ** Description: save the Email Details
 ** Date: 18-July-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1	18-July-2025    Bhargav Saliya		Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SaveEmail]
    @EmailTypeId BIGINT,
    @Subject VARCHAR(MAX) = NULL,
    @ContactById BIGINT = NULL,
    @ContactDate DATETIME2,
    @EmailBody VARCHAR(MAX),
    @ToEmail VARCHAR(4000),
    @FromEmail VARCHAR(4000),
    @AttachmentId BIGINT = NULL,
    @ModuleId INT,
    @ReferenceId BIGINT,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256),
    @CreatedDate DATETIME2,
    @UpdatedDate DATETIME2,
    @IsActive BIT,
    @IsDeleted BIT,
    @BCC VARCHAR(100) = NULL,
    @CC VARCHAR(100) = NULL,
    @CustomerContactId BIGINT = NULL,
    @WorkOrderPartNo BIGINT = NULL,
    @Type INT,
    @EmailStatus BIT = NULL,
    @EmailSentTime DATETIME2 = NULL,
    @IsAttach BIT = NULL,
    @EmailStatusId INT = NULL,
    @AttemptCount BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		INSERT INTO [dbo].[Email] ([EmailTypeId], [Subject], [ContactById], [ContactDate], [EmailBody], [ToEmail], [FromEmail], [AttachmentId], [ModuleId], [ReferenceId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [BCC], [CC], [CustomerContactId], [WorkOrderPartNo], [Type], [EmailStatus], [EmailSentTime], [IsAttach], [EmailStatusId], [AttemptCount])
		VALUES (@EmailTypeId, @Subject, @ContactById, @ContactDate, @EmailBody, @ToEmail, @FromEmail, @AttachmentId, @ModuleId, @ReferenceId, @MasterCompanyId, @CreatedBy, @UpdatedBy, @CreatedDate, @UpdatedDate, @IsActive, @IsDeleted, @BCC, @CC, @CustomerContactId, @WorkOrderPartNo, @Type, @EmailStatus, @EmailSentTime, @IsAttach, @EmailStatusId, @AttemptCount);

	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveEmail' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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