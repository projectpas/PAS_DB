CREATE TABLE [dbo].[AssetInventoryLog] (
    [AssetInventoryLogId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]         VARCHAR (400) NULL,
    [SuccessLog]          VARCHAR (50)  NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_AssetInventoryLog_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_AssetInventoryLog_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_AssetInventoryLog] PRIMARY KEY CLUSTERED ([AssetInventoryLogId] ASC)
);

