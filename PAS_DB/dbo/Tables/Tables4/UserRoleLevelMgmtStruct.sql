CREATE TABLE [dbo].[UserRoleLevelMgmtStruct] (
    [UserRoleManagementStructureId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [UserRoleLevelId]               BIGINT        NOT NULL,
    [ManagementStructureId]         BIGINT        NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NULL,
    [UpdatedBy]                     VARCHAR (256) NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    [IsActive]                      BIT           NULL,
    [IsDelete]                      BIT           NULL,
    CONSTRAINT [PK_UserRoleLevelMgmtStruct] PRIMARY KEY CLUSTERED ([UserRoleManagementStructureId] ASC),
    CONSTRAINT [FK_UserRoleLevelMgmtStruct_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_UserRoleLevelMgmtStruct_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_UserRoleLevelMgmtStruct_UserRoleLevel] FOREIGN KEY ([UserRoleLevelId]) REFERENCES [dbo].[UserRoleLevel] ([UserRoleLevelId])
);

