CREATE TABLE [dbo].[Email] (
    [EmailId]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmailTypeId]       BIGINT         NULL,
    [Subject]           VARCHAR (MAX)  NULL,
    [ContactById]       BIGINT         NULL,
    [ContactDate]       DATETIME2 (7)  NOT NULL,
    [EmailBody]         VARCHAR (MAX)  NOT NULL,
    [ToEmail]           VARCHAR (4000) NOT NULL,
    [FromEmail]         VARCHAR (4000) NOT NULL,
    [AttachmentId]      BIGINT         NULL,
    [ModuleId]          INT            NOT NULL,
    [ReferenceId]       BIGINT         NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_Email_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_Email_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [Email_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [Email_DC_Delete] DEFAULT ((0)) NOT NULL,
    [BCC]               VARCHAR (100)  NULL,
    [CC]                VARCHAR (100)  NULL,
    [CustomerContactId] BIGINT         CONSTRAINT [DF__Email__CustomerC__1177DDF8] DEFAULT ((0)) NULL,
    [WorkOrderPartNo]   BIGINT         NULL,
    [Type]              INT            CONSTRAINT [DF_Email_Type] DEFAULT ((1)) NOT NULL,
    [EmailStatus]       BIT            NULL,
    [EmailSentTime]     DATETIME2 (7)  NULL,
    [IsAttach]          BIT            NULL,
    [EmailStatusId]     INT            DEFAULT ('1') NULL,
    [AttemptCount]      BIGINT         NULL,
    [EmployeeId]        BIGINT         NULL,
    CONSTRAINT [PK_Email] PRIMARY KEY CLUSTERED ([EmailId] ASC),
    CONSTRAINT [FK_Email_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);








GO

CREATE TRIGGER [dbo].[Trg_EmailAudit]

   ON  [dbo].[Email]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[EmailAudit]

	SELECT * FROM INSERTED

	DECLARE @event_type varchar(42)
	DECLARE @EmailId bigint,@EmailAuditId bigint;
   IF EXISTS(SELECT * FROM inserted)
     IF EXISTS(SELECT * FROM deleted)
    SELECT @event_type = 'update'
   ELSE
    SELECT @event_type = 'insert'
   ELSE
   IF EXISTS(SELECT * FROM deleted)
    SELECT @event_type = 'delete'
   ELSE
    --no rows affected - cannot determine event
    SELECT @event_type = 'unknown'
	SELECT @EmailId = EmailId FROM INSERTED

	SELECT @EmailAuditId = SCOPE_IDENTITY();

	--Get Employee Email for CC email.
	DECLARE @EmployeeId BIGINT = 0,
			@ContactById BIGINT = 0,
			@EmployeeEmail VARCHAR(200),
			@CCEmail VARCHAR(200),
			@IsIncludeInCC BIT;
	SELECT @ContactById = ISNULL([ContactById],0), @CCEmail = ISNULL([CC],'') FROM [DBO].[Email] WHERE [EmailId] = @EmailId;

	IF(@ContactById > 0)
	BEGIN
		SELECT @EmployeeEmail = ISNULL([Email],''),@IsIncludeInCC = ISNULL([IsIncludeInCC],0) FROM [DBO].[Employee] WHERE [EmployeeId] = @ContactById;
	END

	IF(@event_type ='insert')
	BEGIN
		IF(@EmployeeEmail != '' AND @IsIncludeInCC > 0)
		BEGIN
			IF(@CCEmail != '')
			BEGIN
				 UPDATE [DBO].[Email] SET [EmailStatusId] = 1,[CC] = [CC] + ',' + @EmployeeEmail WHERE [EmailId] = @EmailId;
				 UPDATE [DBO].[EmailAudit] SET [EmailStatusId] = 1,[CC] = [CC] + ',' + @EmployeeEmail WHERE [EmailAuditId] = @EmailAuditId;
			END
			ELSE
			BEGIN
				 UPDATE [DBO].[Email] SET [EmailStatusId] = 1,[CC] = @EmployeeEmail WHERE [EmailId] = @EmailId;
				 UPDATE [DBO].[EmailAudit] SET [EmailStatusId] = 1,[CC] = @EmployeeEmail WHERE [EmailAuditId] = @EmailAuditId;
			END
		END
		ELSE
		BEGIN
			UPDATE [DBO].[Email] SET [EmailStatusId] = 1 WHERE [EmailId] = @EmailId;
		END
	END

	SET NOCOUNT ON;
END