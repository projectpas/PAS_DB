CREATE TABLE [dbo].[UserRole] (
    [Id]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            NVARCHAR (100) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [IsActive]        BIT            DEFAULT ((1)) NULL,
    [IsDeleted]       BIT            DEFAULT ((0)) NULL,
    [UpdatedBy]       NVARCHAR (100) NULL,
    [UpdatedDate]     DATETIME       NULL,
    [CreatedBy]       NVARCHAR (100) NULL,
    [CreatedDate]     DATETIME       NULL,
    [MasterCompanyId] INT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_UserRole_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

