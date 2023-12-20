CREATE TABLE [dbo].[ExchangeQuoteScheduleBilling] (
    [ExchangeQuoteScheduleBillingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuotePartId]            BIGINT         NOT NULL,
    [ExchangeQuoteId]                BIGINT         NOT NULL,
    [ScheduleBillingDate]            DATETIME2 (7)  NOT NULL,
    [PeriodicBillingAmount]          NUMERIC (9, 2) NOT NULL,
    [Cogs]                           INT            NOT NULL,
    [CogsAmount]                     NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_ExchangeQuoteScheduleBilling] PRIMARY KEY CLUSTERED ([ExchangeQuoteScheduleBillingId] ASC),
    CONSTRAINT [FK_ExchangeQuoteScheduleBilling_ExchangeQuotePart] FOREIGN KEY ([ExchangeQuotePartId]) REFERENCES [dbo].[ExchangeQuotePart] ([ExchangeQuotePartId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeQuoteScheduleBillingAudit]

   ON  [dbo].[ExchangeQuoteScheduleBilling]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeQuoteScheduleBillingAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END