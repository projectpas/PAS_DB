CREATE TABLE [dbo].[ATAChapterCategory] (
    [ATAChapterCategoryId] INT            IDENTITY (1, 1) NOT NULL,
    [CategoryName]         VARCHAR (256)  NOT NULL,
    [Description]          VARCHAR (MAX)  NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [ATAChapterCategory_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [ATAChapterCategory_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [IsActive]             BIT            CONSTRAINT [D_ATAChapterCategory_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [D_ATAChapterCategory_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ATAChapterCategory] PRIMARY KEY CLUSTERED ([ATAChapterCategoryId] ASC),
    CONSTRAINT [FK_ATAChapterCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ATAChapterCategory] UNIQUE NONCLUSTERED ([CategoryName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ATAChapterCategoryAudit]

   ON  [dbo].[ATAChapterCategory]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ATAChapterCategoryAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END