CREATE TABLE [dbo].[AttachmentModule] (
    [AttachmentModuleId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]               VARCHAR (100)  NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          NVARCHAR (256) NOT NULL,
    [UpdatedBy]          NVARCHAR (256) NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_AttachmentModule_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_AttachmentModule_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]           BIT            CONSTRAINT [DF_AttachmentModule_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_AttachmentModule_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AttachmentModule] PRIMARY KEY CLUSTERED ([AttachmentModuleId] ASC)
);

