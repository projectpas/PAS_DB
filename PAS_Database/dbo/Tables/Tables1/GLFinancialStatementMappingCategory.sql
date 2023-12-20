CREATE TABLE [dbo].[GLFinancialStatementMappingCategory] (
    [GLFinancialStatementMappingCategoryId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLFinancialStatementMappingCategoryName] VARCHAR (200) NOT NULL,
    [MasterCompanyId]                         INT           NOT NULL,
    [CreatedBy]                               VARCHAR (256) NULL,
    [UpdatedBy]                               VARCHAR (256) NULL,
    [CreatedDate]                             DATETIME2 (7) NOT NULL,
    [UpdatedDate]                             DATETIME2 (7) NOT NULL,
    [IsActive]                                BIT           NULL,
    [IsDelete]                                BIT           NULL,
    CONSTRAINT [PK_GLFinancialStatementMappingCategory] PRIMARY KEY CLUSTERED ([GLFinancialStatementMappingCategoryId] ASC),
    CONSTRAINT [FK_GLFinancialStatementMappingCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

