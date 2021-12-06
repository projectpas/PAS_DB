CREATE TABLE [dbo].[SalesOrderQuoteFreight] (
    [SalesOrderQuoteFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]        BIGINT          NOT NULL,
    [SalesOrderQuotePartId]    BIGINT          NULL,
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
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_SalesOrderQuoteFreight_IsACtive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_SalesOrderQuoteFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [ShipViaName]              NVARCHAR (100)  NULL,
    [UOMName]                  NVARCHAR (100)  NULL,
    [DimensionUOMName]         NVARCHAR (100)  NULL,
    [CurrencyName]             NVARCHAR (100)  NULL,
    [ItemMasterId]             BIGINT          NULL,
    [ConditionId]              BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderQuoteFreight] PRIMARY KEY CLUSTERED ([SalesOrderQuoteFreightId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteFreight_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderQuoteFreight_ShippingVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId])
);


GO


CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteFreightAudit]

   ON  [dbo].[SalesOrderQuoteFreight]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderQuoteFreightAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END