CREATE TABLE [dbo].[SalesOrderSettings] (
    [SalesOrderSettingId]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [TypeId]                     INT           NOT NULL,
    [Prefix]                     VARCHAR (20)  NULL,
    [Sufix]                      VARCHAR (20)  NULL,
    [StartCode]                  BIGINT        NULL,
    [CurrentNumber]              BIGINT        NOT NULL,
    [DefaultStatusId]            INT           NOT NULL,
    [DefaultPriorityId]          BIGINT        NOT NULL,
    [SOListViewId]               INT           NOT NULL,
    [SOListStatusId]             INT           NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_SalesOrderSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_SalesOrderSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [SalesOrderSettings_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [SalesOrderSettings_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]             BIT           NULL,
    [EffectiveDate]              DATETIME2 (7) NULL,
    [AutoReserve]                BIT           NULL,
    [AllowInvoiceBeforeShipping] BIT           NULL,
    CONSTRAINT [PK_SalesOrderSettings] PRIMARY KEY CLUSTERED ([SalesOrderSettingId] ASC),
    CONSTRAINT [FK_SalesOrderSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderSettings_MasterSalesOrderQuoteStatus_DefaultStatusId] FOREIGN KEY ([DefaultStatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id]),
    CONSTRAINT [FK_SalesOrderSettings_MasterSalesOrderQuoteStatus_SOListStatusId] FOREIGN KEY ([SOListStatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id]),
    CONSTRAINT [FK_SalesOrderSettings_MasterSalesOrderQuoteTypes] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[MasterSalesOrderQuoteTypes] ([Id]),
    CONSTRAINT [FK_SalesOrderSettings_Priority] FOREIGN KEY ([DefaultPriorityId]) REFERENCES [dbo].[Priority] ([PriorityId])
);




GO






CREATE TRIGGER [dbo].[Trg_SalesOrderSettingsAudit]

   ON  [dbo].[SalesOrderSettings]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderSettingsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END