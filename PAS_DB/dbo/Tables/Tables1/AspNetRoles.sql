CREATE TABLE [dbo].[AspNetRoles] (
    [Id]               NVARCHAR (450) NOT NULL,
    [ConcurrencyStamp] NVARCHAR (MAX) NULL,
    [CreatedBy]        NVARCHAR (MAX) NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_AspNetRoles_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [Description]      NVARCHAR (MAX) NULL,
    [Name]             NVARCHAR (256) NULL,
    [NormalizedName]   NVARCHAR (256) NULL,
    [UpdatedBy]        NVARCHAR (MAX) NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DF_AspNetRoles_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [RoleNameIndex]
    ON [dbo].[AspNetRoles]([NormalizedName] ASC) WHERE ([NormalizedName] IS NOT NULL);

