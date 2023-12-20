CREATE TABLE [dbo].[UIRoleEntity] (
    [UIRoleEntityId]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [EntityName]                VARCHAR (100) NULL,
    [RoleCategorizationLevelId] BIGINT        NOT NULL,
    [ModuleName]                VARCHAR (100) NULL,
    [ScreenName]                VARCHAR (100) NULL,
    [TableName]                 VARCHAR (100) NULL,
    [FieldName]                 VARCHAR (100) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NULL,
    [UpdatedBy]                 VARCHAR (256) NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NULL,
    [ParentId]                  BIGINT        NULL,
    CONSTRAINT [PK_UIRoleEntity] PRIMARY KEY CLUSTERED ([UIRoleEntityId] ASC),
    CONSTRAINT [FK_UIRoleEntity_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_UIRoleEntity_RoleCategorizationLevel] FOREIGN KEY ([RoleCategorizationLevelId]) REFERENCES [dbo].[RoleCategorizationLevel] ([RoleCategorizationLevelId])
);

