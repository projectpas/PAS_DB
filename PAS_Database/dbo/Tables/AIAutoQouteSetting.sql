CREATE TABLE [dbo].[AIAutoQouteSetting] (
    [AIAutoQouteSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [QuoteSettingNameId]   INT           NULL,
    [QuoteSettingName]     VARCHAR (100) NULL,
    [Code]                 VARCHAR (50)  NULL,
    [Sequence]             INT           NULL,
    [QuoteSendReviewId]    INT           NULL,
    [QuoteSendReview]      VARCHAR (100) NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_AIAutoQouteSetting_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_AIAutoQouteSetting_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_AIAutoQouteSetting_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_AIAutoQouteSetting_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_AIAutoQouteSetting] PRIMARY KEY CLUSTERED ([AIAutoQouteSettingId] ASC),
    CONSTRAINT [FK_AIAutoQouteSetting_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

