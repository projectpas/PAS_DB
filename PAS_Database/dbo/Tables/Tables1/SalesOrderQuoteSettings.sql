CREATE TABLE [dbo].[SalesOrderQuoteSettings] (
    [SalesOrderQuoteSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [QuoteTypeId]              INT           NOT NULL,
    [ValidDays]                INT           NOT NULL,
    [Prefix]                   VARCHAR (20)  NULL,
    [Sufix]                    VARCHAR (20)  NULL,
    [StartCode]                BIGINT        NULL,
    [CurrentNumber]            BIGINT        NULL,
    [DefaultStatusId]          INT           NOT NULL,
    [DefaultPriorityId]        BIGINT        NOT NULL,
    [SOQListViewId]            INT           NOT NULL,
    [SOQListStatusId]          INT           NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [SalesOrderQuoteSettings_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [SalesOrderQuoteSettings_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]           BIT           NULL,
    [EffectiveDate]            DATETIME2 (7) NULL,
    CONSTRAINT [PK_SalesOrderQuoteSettings] PRIMARY KEY CLUSTERED ([SalesOrderQuoteSettingId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuoteSettings_MasterSalesOrderQuoteStatus_DefaultStatusId] FOREIGN KEY ([DefaultStatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id]),
    CONSTRAINT [FK_SalesOrderQuoteSettings_MasterSalesOrderQuoteStatus_SOQListStatusId] FOREIGN KEY ([SOQListStatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id]),
    CONSTRAINT [FK_SalesOrderQuoteSettings_MasterSalesOrderQuoteTypes] FOREIGN KEY ([QuoteTypeId]) REFERENCES [dbo].[MasterSalesOrderQuoteTypes] ([Id]),
    CONSTRAINT [FK_SalesOrderQuoteSettings_Priority] FOREIGN KEY ([DefaultPriorityId]) REFERENCES [dbo].[Priority] ([PriorityId])
);


GO






CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteSettingsAudit]

   ON  [dbo].[SalesOrderQuoteSettings]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderQuoteSettingsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END