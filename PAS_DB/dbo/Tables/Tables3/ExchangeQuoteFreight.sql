CREATE TABLE [dbo].[ExchangeQuoteFreight] (
    [ExchangeQuoteFreightId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]          BIGINT          NOT NULL,
    [ExchangeQuotePartId]      BIGINT          NULL,
    [ShipViaId]                BIGINT          NOT NULL,
    [Weight]                   VARCHAR (50)    NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [Amount]                   DECIMAL (20, 3) NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [BillingMethodId]          INT             NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [Length]                   DECIMAL (10, 2) NULL,
    [Width]                    DECIMAL (10, 2) NULL,
    [Height]                   DECIMAL (10, 2) NULL,
    [UOMId]                    BIGINT          NULL,
    [DimensionUOMId]           BIGINT          NULL,
    [CurrencyId]               INT             NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuoteFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuoteFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_ExchangeQuoteFreight_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_ExchangeQuoteFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [ShipViaName]              NVARCHAR (100)  NULL,
    [UOMName]                  NVARCHAR (100)  NULL,
    [DimensionUOMName]         NVARCHAR (100)  NULL,
    [CurrencyName]             NVARCHAR (100)  NULL,
    CONSTRAINT [PK_ExchangeQuoteFreight] PRIMARY KEY CLUSTERED ([ExchangeQuoteFreightId] ASC),
    CONSTRAINT [FK_ExchangeQuoteFreight_ExchangeQuote] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeQuoteFreightAudit]

   ON  [dbo].[ExchangeQuoteFreight]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeQuoteFreightAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END