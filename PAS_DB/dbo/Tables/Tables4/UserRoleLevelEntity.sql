CREATE TABLE [dbo].[UserRoleLevelEntity] (
    [UserRoleLevelEntityId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [UserRoleLevelId]       BIGINT        NOT NULL,
    [UIRoleEntityId]        BIGINT        NOT NULL,
    [PermittedEditActionId] SMALLINT      NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NULL,
    [UpdatedBy]             VARCHAR (256) NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NULL,
    CONSTRAINT [PK_UserRoleLevelEntity] PRIMARY KEY CLUSTERED ([UserRoleLevelEntityId] ASC),
    CONSTRAINT [FK_UserRoleLevelEntity_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_UserRoleLevelEntity_PermittedEditAction] FOREIGN KEY ([PermittedEditActionId]) REFERENCES [dbo].[PermittedEditAction] ([PermittedEditActionId]),
    CONSTRAINT [FK_UserRoleLevelEntity_UIRoleEntity] FOREIGN KEY ([UIRoleEntityId]) REFERENCES [dbo].[UIRoleEntity] ([UIRoleEntityId]),
    CONSTRAINT [FK_UserRoleLevelEntity_UserRoleLevel] FOREIGN KEY ([UserRoleLevelId]) REFERENCES [dbo].[UserRoleLevel] ([UserRoleLevelId])
);

