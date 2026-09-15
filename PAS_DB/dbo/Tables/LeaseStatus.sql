CREATE TABLE [dbo].[LeaseStatus] (
    [LeaseStatusId]   INT            IDENTITY (1, 1) NOT NULL,
    [Name]            NVARCHAR (100) NOT NULL,
    [Description]     NVARCHAR (500) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       NVARCHAR (100) NULL,
    [UpdatedBy]       NVARCHAR (100) NULL,
    [CreatedDate]     DATETIME       CONSTRAINT [DF_LeaseStatus_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME       CONSTRAINT [DF_LeaseStatus_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_LeaseStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_LeaseStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseStatus] PRIMARY KEY CLUSTERED ([LeaseStatusId] ASC)
);

