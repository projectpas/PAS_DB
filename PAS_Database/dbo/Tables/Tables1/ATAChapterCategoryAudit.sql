CREATE TABLE [dbo].[ATAChapterCategoryAudit] (
    [AuditATAChapterCategoryId] INT           IDENTITY (1, 1) NOT NULL,
    [ATAChapterCategoryId]      INT           NOT NULL,
    [CategoryName]              VARCHAR (256) NOT NULL,
    [Description]               VARCHAR (MAX) NULL,
    [Memo]                      VARCHAR (MAX) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_ATAChapterCategoryAudit] PRIMARY KEY CLUSTERED ([AuditATAChapterCategoryId] ASC)
);

