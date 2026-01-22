CREATE TABLE [dbo].[Notes] (
    [NotesId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [Subject]         VARCHAR (256)  NULL,
    [Title]           VARCHAR (256)  NULL,
    [EntryDate]       DATETIME2 (7)  NULL,
    [FollowUpDate]    DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [CRMNotes_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [CRMNotes_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [CRMNotes_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [CRMNotes_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [ModuleId]        INT            NULL,
    [Description]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_[CRMNotes] PRIMARY KEY CLUSTERED ([NotesId] ASC),
    CONSTRAINT [FK_CRMNotes_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Notes_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [Unique_CRMNotes] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_NotesAudit]

   ON  [dbo].[Notes]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO NotesAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END