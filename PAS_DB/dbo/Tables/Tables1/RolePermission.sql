CREATE TABLE [dbo].[RolePermission] (
    [Id]                      BIGINT IDENTITY (1, 1) NOT NULL,
    [UserRoleId]              BIGINT NOT NULL,
    [ModuleHierarchyMasterId] INT    NOT NULL,
    [CanAdd]                  BIT    CONSTRAINT [DF__RolePermi__CanAd__74C2C9C8] DEFAULT ((0)) NULL,
    [CanView]                 BIT    CONSTRAINT [DF__RolePermi__CanVi__75B6EE01] DEFAULT ((0)) NULL,
    [CanUpdate]               BIT    CONSTRAINT [DF__RolePermi__CanUp__76AB123A] DEFAULT ((0)) NULL,
    [CanDelete]               BIT    CONSTRAINT [DF__RolePermi__CanDe__779F3673] DEFAULT ((0)) NULL,
    [Reports]                 BIT    CONSTRAINT [DF__RolePermi__Repor__78935AAC] DEFAULT ((0)) NULL,
    [CanUpload]               BIT    CONSTRAINT [DF__RolePermi__CanUp__79877EE5] DEFAULT ((0)) NULL,
    [CanDownload]             BIT    CONSTRAINT [DF__RolePermi__CanDo__7A7BA31E] DEFAULT ((0)) NULL,
    [PermissionID]            INT    CONSTRAINT [DF_RolePermission_PermissionID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK__RolePerm__3214EC076FCCF7AB] PRIMARY KEY CLUSTERED ([Id] ASC)
);



