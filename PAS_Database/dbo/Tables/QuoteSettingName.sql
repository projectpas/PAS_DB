CREATE TABLE [dbo].[QuoteSettingName] (
    [QuoteSettingNameId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [QuoteSettingName]   VARCHAR (100) NULL,
    [Code]               VARCHAR (50)  NULL,
    [MasterCompanyId]    INT           NULL,
    [CreatedBy]          VARCHAR (256) NOT NULL,
    [CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_QuoteSettingName_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]          VARCHAR (256) NOT NULL,
    [UpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_QuoteSettingName_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]          BIT           CONSTRAINT [DF_QuoteSettingName_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]           BIT           CONSTRAINT [DF_QuoteSettingName_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_QuoteSettingName] PRIMARY KEY CLUSTERED ([QuoteSettingNameId] ASC)
);

