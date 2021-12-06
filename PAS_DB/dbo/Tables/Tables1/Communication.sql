CREATE TABLE [dbo].[Communication] (
    [CommunicationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [Contact]         VARCHAR (256)  NOT NULL,
    [Subject]         VARCHAR (MAX)  NULL,
    [ModuleId]        INT            NOT NULL,
    [PostedDate]      DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [CRMCommunication_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [CRMCommunication_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [CRMCommunication_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [CRMCommunication_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CRMCommunication] PRIMARY KEY CLUSTERED ([CommunicationId] ASC),
    CONSTRAINT [FK_Communication_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [FK_CRMCommunication_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO






CREATE TRIGGER [dbo].[Trg_CommunicationAudit]

   ON  [dbo].[Communication]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CommunicationAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END