CREATE TABLE [dbo].[ExchangeQuotePart] (
    [ExchangeQuotePartId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]         BIGINT         NOT NULL,
    [ItemMasterId]            BIGINT         NULL,
    [StockLineId]             BIGINT         NULL,
    [ExchangeCurrencyId]      BIGINT         NULL,
    [LoanCurrencyId]          BIGINT         NULL,
    [ExchangeListPrice]       NUMERIC (9, 2) NULL,
    [EntryDate]               DATETIME2 (7)  NULL,
    [ExchangeOverhaulPrice]   NUMERIC (9, 2) NULL,
    [ExchangeCorePrice]       NUMERIC (9, 2) NULL,
    [EstOfFeeBilling]         INT            NULL,
    [BillingStartDate]        DATETIME2 (7)  NULL,
    [ExchangeOutrightPrice]   NUMERIC (9, 2) NULL,
    [DaysForCoreReturn]       INT            NULL,
    [BillingIntervalDays]     INT            NULL,
    [CurrencyId]              INT            NULL,
    [Currency]                VARCHAR (50)   NULL,
    [DepositeAmount]          NUMERIC (9, 2) NULL,
    [CoreDueDate]             DATETIME2 (7)  NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ExchangeQuotePart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ExchangeQuotePart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_ExchangeQuotePart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_ExchangeQuotePart_IsActive] DEFAULT ((1)) NOT NULL,
    [ConditionId]             BIGINT         NULL,
    [StockLineName]           NVARCHAR (100) NULL,
    [PartNumber]              NVARCHAR (100) NULL,
    [PartDescription]         NVARCHAR (MAX) NULL,
    [ConditionName]           NVARCHAR (100) NULL,
    [IsRemark]                BIT            CONSTRAINT [DF_ExchangeQuotePart_IsRemark] DEFAULT ((0)) NULL,
    [RemarkText]              VARCHAR (MAX)  NULL,
    [ExchangeOverhaulCost]    NUMERIC (9, 2) NULL,
    [QtyQuoted]               INT            NULL,
    [MethodType]              CHAR (1)       NULL,
    [IsConvertedToSalesOrder] BIT            DEFAULT ((0)) NOT NULL,
    [CustomerRequestDate]     DATETIME2 (7)  NULL,
    [PromisedDate]            DATETIME2 (7)  NULL,
    [EstimatedShipDate]       DATETIME2 (7)  NULL,
    CONSTRAINT [PK_ExchangeQuotePart] PRIMARY KEY CLUSTERED ([ExchangeQuotePartId] ASC),
    CONSTRAINT [FK_ExchangeQuote_ExchangeQuotePart] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId]),
    CONSTRAINT [FK_ExchangeQuotePart_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_ExchangeQuotePart_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ExchangeQuotePart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeQuotePart_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeQuotePartAudit]

   ON  [dbo].[ExchangeQuotePart]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeQuotePartAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END