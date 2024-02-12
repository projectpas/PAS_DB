CREATE TABLE [dbo].[ILSInventoryUpload] (
    [ILSInventoryUploadId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EitReceived]          BIT            NOT NULL,
    [EmailSent]            BIT            NOT NULL,
    [ErrDescription]       NVARCHAR (MAX) NULL,
    [InventoryLoadId]      VARCHAR (100)  NULL,
    [FilePath]             NVARCHAR (MAX) NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [ILSInventoryUpload_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [ILSInventoryUpload_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [D_ILSInventoryUpload_Active] DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [D_ILSInventoryUpload_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ILSInventoryUpload] PRIMARY KEY CLUSTERED ([ILSInventoryUploadId] ASC),
    CONSTRAINT [FK_ILSInventoryUpload_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

