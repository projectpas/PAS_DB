CREATE TABLE [dbo].[ItemMasterSettings] (
    [ItemMasterSettingsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GlAccountId]          BIGINT        NOT NULL,
    [GLAccount]            VARCHAR (100) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (50)  NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_ItemMasterSettings_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]            VARCHAR (50)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_ItemMasterSettings_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF__ItemMasterSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF__ItemMasterSettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    [UnitOfMeasureId]      BIGINT        NULL,
    [UnitOfMeasure]        VARCHAR (100) NULL,
    CONSTRAINT [PK_ItemMasterSettings] PRIMARY KEY CLUSTERED ([ItemMasterSettingsId] ASC)
);



