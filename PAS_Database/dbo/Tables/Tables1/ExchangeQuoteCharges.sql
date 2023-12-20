CREATE TABLE [dbo].[ExchangeQuoteCharges] (
    [ExchangeQuoteChargesId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]          BIGINT          NOT NULL,
    [ExchangeQuotePartId]      BIGINT          NULL,
    [ChargesTypeId]            BIGINT          NOT NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 INT             NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]             DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [BillingMethodId]          INT             NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuoteCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuoteCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_ExchangeQuoteCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_ExchangeQuoteCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [VendorName]               NVARCHAR (100)  NULL,
    [ChargeName]               NVARCHAR (100)  NULL,
    [MarkupName]               NVARCHAR (100)  NULL,
    CONSTRAINT [PK_ExchangeQuoteCharges] PRIMARY KEY CLUSTERED ([ExchangeQuoteChargesId] ASC),
    CONSTRAINT [FK_ExchangeQuoteCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_ExchangeQuoteCharges_ExchangeQuote] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeQuoteChargesAudit]

   ON  [dbo].[ExchangeQuoteCharges]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeQuoteChargesAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END