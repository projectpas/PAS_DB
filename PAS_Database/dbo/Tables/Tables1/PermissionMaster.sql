CREATE TABLE [dbo].[PermissionMaster] (
    [PermissionID]   INT            IDENTITY (1, 1) NOT NULL,
    [PermissionName] VARCHAR (50)   NOT NULL,
    [CreatedBy]      NVARCHAR (400) NOT NULL,
    [CreatedDate]    DATETIME       CONSTRAINT [DF_PermissionMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]      NVARCHAR (400) NULL,
    [UpdatedDate]    DATETIME       NULL,
    [IsActive]       BIT            CONSTRAINT [DF_PermissionMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]      BIT            CONSTRAINT [DF_PermissionMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ParentID]       INT            NULL,
    CONSTRAINT [PK_PermissionMaster] PRIMARY KEY CLUSTERED ([PermissionID] ASC)
);

