CREATE TABLE [dbo].[Source] (
    [SourceId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [SourceName]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Source_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Source_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Source_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Source_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Source] PRIMARY KEY CLUSTERED ([SourceId] ASC),
    CONSTRAINT [FK_Source_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Source] UNIQUE NONCLUSTERED ([SourceName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_SourceAudit]

   ON  [dbo].[Source]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO SourceAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END