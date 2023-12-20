CREATE TABLE [dbo].[GlobalSettings] (
    [GlobalSettingId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [CompanyId]        INT           NOT NULL,
    [CultureId]        BIGINT        NOT NULL,
    [CurrencyFormat]   VARCHAR (50)  NULL,
    [NumberFormat]     VARCHAR (50)  NULL,
    [DateFormat]       VARCHAR (50)  NULL,
    [PercentFormat]    VARCHAR (50)  NULL,
    [CreditLimtFormat] VARCHAR (50)  NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    [CultureName]      VARCHAR (10)  NULL,
    CONSTRAINT [PK_GlobalSettings] PRIMARY KEY CLUSTERED ([GlobalSettingId] ASC)
);

