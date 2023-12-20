CREATE TABLE [dbo].[DefaultMessage] (
    [DefaultMessageId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]      VARCHAR (500)  NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DefaultMessage_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DefaultMessage_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [DefaultMessage_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [DefaultMessage_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ModuleID]         INT            NULL,
    CONSTRAINT [PK_DefaultMessage] PRIMARY KEY CLUSTERED ([DefaultMessageId] ASC),
    CONSTRAINT [FK_DefaultMessage_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_DefaultMessage_ModuleID] FOREIGN KEY ([ModuleID]) REFERENCES [dbo].[Module] ([ModuleId])
);


GO




CREATE TRIGGER [dbo].[Trg_DefaultMessageAudit]

   ON  [dbo].[DefaultMessage]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

    DECLARE @ModuleId INT

	DECLARE @ModuleName VARCHAR(256)



	SELECT @ModuleId=ModuleID FROM INSERTED

	SELECT @ModuleName=ModuleName FROM Module WHERE ModuleId=@ModuleId



	

INSERT INTO DefaultMessageAudit

SELECT *,@ModuleName FROM INSERTED

SET NOCOUNT ON;

END