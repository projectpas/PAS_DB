CREATE TABLE [dbo].[RoleCategorizationLevel] (
    [RoleCategorizationLevelId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]               VARCHAR (100) NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NULL,
    [UpdatedBy]                 VARCHAR (256) NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NULL,
    CONSTRAINT [PK_RoleCategorizationLevel] PRIMARY KEY CLUSTERED ([RoleCategorizationLevelId] ASC),
    CONSTRAINT [FK_RoleCategorizationLevel_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

