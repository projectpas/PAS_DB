CREATE TABLE [dbo].[GLAccountMiscCategoryAudit] (
    [GLAccountMiscCategoryAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLAccountMiscCategoryId]      BIGINT        NOT NULL,
    [Name]                         VARCHAR (30)  NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    CONSTRAINT [PK_GLAccountMiscCategoryAudit] PRIMARY KEY CLUSTERED ([GLAccountMiscCategoryAuditId] ASC)
);

