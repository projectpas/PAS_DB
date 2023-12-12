CREATE TABLE [dbo].[JournalCategory] (
    [ID]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Journal_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Journal_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_JournalCategory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_JournalCategory_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [CategoryName]    VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_JournalCategory] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_JournalCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_JournalCategory] UNIQUE NONCLUSTERED ([CategoryName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_JournalCategoryAudit]

   ON  [dbo].[JournalCategory]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO JournalCategoryAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END