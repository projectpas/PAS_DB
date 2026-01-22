CREATE TABLE [dbo].[FollowUp] (
    [FollowUpId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [ModuleId]        INT            NOT NULL,
    [Subject]         VARCHAR (256)  NULL,
    [EntryDate]       DATETIME2 (7)  NULL,
    [FollowUpDate]    DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [CRMFollowUp_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [CRMFollowUp_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [CRMFollowUp_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [CRMFollowUp_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CRMFollowUp] PRIMARY KEY CLUSTERED ([FollowUpId] ASC),
    CONSTRAINT [FK_CRMFollowUp_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FollowUp_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [Unique_CRMFollowUp] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_FollowUpAudit]

   ON  [dbo].[FollowUp]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO FollowUpAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END