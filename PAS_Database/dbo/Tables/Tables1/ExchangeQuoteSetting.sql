CREATE TABLE [dbo].[ExchangeQuoteSetting] (
    [ExchangeQuoteSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Typeid]                 INT           NOT NULL,
    [Prefix]                 VARCHAR (20)  NULL,
    [Sufix]                  VARCHAR (20)  NULL,
    [StartCode]              BIGINT        NULL,
    [CurrentNumber]          BIGINT        NOT NULL,
    [DefaultStatusId]        INT           NOT NULL,
    [DefaultPriorityId]      BIGINT        NOT NULL,
    [COGS]                   INT           NOT NULL,
    [DaysForCoreReturn]      INT           NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_ExchangeQuoteSetting_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_ExchangeQuoteSetting_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_ExchangeQuoteSetting_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_ExchangeQuoteSetting_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]         BIT           NULL,
    [ValidDays]              INT           DEFAULT ((0)) NOT NULL,
    [EffectiveDate]          DATETIME2 (7) NULL,
    CONSTRAINT [PK_ExchangeQuoteSetting] PRIMARY KEY CLUSTERED ([ExchangeQuoteSettingId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeQuoteSettingAudit]

   ON  [dbo].[ExchangeQuoteSetting]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeQuoteSettingAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END