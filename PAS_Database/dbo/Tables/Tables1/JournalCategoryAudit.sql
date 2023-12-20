CREATE TABLE [dbo].[JournalCategoryAudit] (
    [JournalCategoryID] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ID]                BIGINT         NOT NULL,
    [Description]       VARCHAR (MAX)  NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [CategoryName]      VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_JournalCategoryAudit] PRIMARY KEY CLUSTERED ([JournalCategoryID] ASC)
);

