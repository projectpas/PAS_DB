CREATE TABLE [dbo].[XeroAccountingGLConfig] (
    [XeroGLConfigId]  INT           IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT        NOT NULL,
    [ModuleName]      VARCHAR (100) NOT NULL,
    [GLAccountId]     BIGINT        NOT NULL,
    [AccountCode]     VARCHAR (50)  NOT NULL,
    [AccountName]     VARCHAR (200) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_XeroAccountingGLConfig] PRIMARY KEY CLUSTERED ([XeroGLConfigId] ASC),
    CONSTRAINT [FK_XeroAccountingGLConfig_GLAccount] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_XeroAccountingGLConfig_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

