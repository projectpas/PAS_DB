CREATE TABLE [dbo].[WIPGLAccountSetupAudit] (
    [WIPGLAccountSetupAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WIPGLAccountId]           BIGINT        NULL,
    [WIPCategoryId]            BIGINT        NULL,
    [GLAccountId]              BIGINT        NULL,
    [CreatedBy]                VARCHAR (256) NULL,
    [CreatedDate]              DATETIME2 (7) NULL,
    [UpdatedBy]                VARCHAR (256) NULL,
    [UpdatedDate]              DATETIME2 (7) NULL,
    [IsActive]                 BIT           NULL,
    [IsDeleted]                BIT           NULL,
    [MasterCompanyId]          INT           NULL,
    PRIMARY KEY CLUSTERED ([WIPGLAccountSetupAuditId] ASC)
);

