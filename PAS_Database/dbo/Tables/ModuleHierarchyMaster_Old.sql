CREATE TABLE [dbo].[ModuleHierarchyMaster_Old] (
    [Id]                 INT             IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (500)  NULL,
    [ParentId]           INT             NULL,
    [IsPage]             BIT             CONSTRAINT [DF__ModuleHie__IsPag__6F9F86DC] DEFAULT ((0)) NULL,
    [DisplayOrder]       INT             NULL,
    [ModuleCode]         NVARCHAR (500)  NULL,
    [IsMenu]             BIT             CONSTRAINT [DF_ModuleHierarchyMaster_IsMenu] DEFAULT ((0)) NOT NULL,
    [ModuleIcon]         VARCHAR (50)    NULL,
    [RouterLink]         NVARCHAR (200)  NULL,
    [PermissionConstant] VARCHAR (200)   NULL,
    [IsCreateMenu]       BIT             CONSTRAINT [DF_ModuleHierarchyMaster_IsCreateMenu] DEFAULT ((0)) NOT NULL,
    [ModuleId]           INT             NULL,
    [ListParentId]       BIGINT          NULL,
    [IsReport]           BIT             NULL,
    [ShowAsTopMenu]      BIT             DEFAULT ((0)) NULL,
    [NewModuleIcon]      VARCHAR (100)   NULL,
    [NewMenuName]        NVARCHAR (1000) NULL,
    CONSTRAINT [PK__ModuleHi__3214EC072ABE11CD] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK__ModuleHie__Paren__68536ACF] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[ModuleHierarchyMaster_Old] ([Id])
);

