CREATE TABLE [dbo].[MasterDiscountTypeAudit] (
    [MasterDiscountTypeAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                        INT           NOT NULL,
    [Name]                      VARCHAR (50)  NULL,
    [Description]               VARCHAR (250) NULL,
    [GLAccountId]               BIGINT        NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME      NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NULL,
    [UpdatedDate]               DATETIME      NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_MasterDiscountTypeAudit] PRIMARY KEY CLUSTERED ([MasterDiscountTypeAuditId] ASC)
);

