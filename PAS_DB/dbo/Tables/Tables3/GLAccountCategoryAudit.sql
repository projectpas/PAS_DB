CREATE TABLE [dbo].[GLAccountCategoryAudit] (
    [GLAccountCategoryAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLAccountCategoryId]      BIGINT        NOT NULL,
    [GLAccountCategoryName]    VARCHAR (200) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) NOT NULL,
    [IsActive]                 BIT           NOT NULL,
    [IsDeleted]                BIT           NOT NULL,
    [GLCID]                    INT           NOT NULL,
    CONSTRAINT [PK_GLAccountCategoryAudit] PRIMARY KEY CLUSTERED ([GLAccountCategoryAuditId] ASC),
    CONSTRAINT [FK_GLAccountCategoryAudit_GLAccountCategory] FOREIGN KEY ([GLAccountCategoryId]) REFERENCES [dbo].[GLAccountCategory] ([GLAccountCategoryId])
);

