CREATE TABLE [dbo].[ItemCategoryAudit] (
    [ItemCategoryAuditId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [ItemCategoryId]      TINYINT       NOT NULL,
    [Description]         VARCHAR (50)  NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NULL,
    [UpdatedBy]           VARCHAR (256) NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    [IsActive]            BIT           NULL,
    CONSTRAINT [PK_ItemCategoryAudit] PRIMARY KEY CLUSTERED ([ItemCategoryAuditId] ASC)
);

