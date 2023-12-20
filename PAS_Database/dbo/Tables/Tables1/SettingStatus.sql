CREATE TABLE [dbo].[SettingStatus] (
    [Id]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (30)  NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (100) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_SettingStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (100) NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_SettingStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_SettingStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_SettingStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SettingStatus] PRIMARY KEY CLUSTERED ([Id] ASC)
);

