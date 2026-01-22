CREATE TABLE [dbo].[SalesOrderFreight] (
    [SalesOrderFreightId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]        BIGINT          NULL,
    [SalesOrderId]             BIGINT          NOT NULL,
    [SalesOrderPartId]         BIGINT          NULL,
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
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_SalesOrderFreight_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_SalesOrderFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [ShipViaName]              VARCHAR (50)    NULL,
    [UOMName]                  VARCHAR (50)    NULL,
    [DimensionUOMName]         VARCHAR (100)   NULL,
    [CurrencyName]             VARCHAR (50)    NULL,
    [ItemMasterId]             BIGINT          NULL,
    [ConditionId]              BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderFreight] PRIMARY KEY CLUSTERED ([SalesOrderFreightId] ASC),
    CONSTRAINT [FK_SalesOrderFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderFreight_SalesOrder] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderFreight_ShippingVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId])
);


GO


CREATE TRIGGER [dbo].[Trg_SalesOrderFreightAudit]

   ON  [dbo].[SalesOrderFreight]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderFreightAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END