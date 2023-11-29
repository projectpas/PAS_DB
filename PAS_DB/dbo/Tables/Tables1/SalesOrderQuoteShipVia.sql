CREATE TABLE [dbo].[SalesOrderQuoteShipVia] (
    [SalesOrderQuoteShipViaId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]        BIGINT          NOT NULL,
    [UserType]                 INT             NOT NULL,
    [ReferenceId]              BIGINT          NOT NULL,
    [ShipViaId]                BIGINT          NOT NULL,
    [ShippingCost]             DECIMAL (20, 3) NOT NULL,
    [HandlingCost]             DECIMAL (20, 3) NOT NULL,
    [IsOnlyPOShipVia]          BIT             NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteShipVia_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteShipVia_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [ShippingAccountNo]        VARCHAR (100)   NULL,
    [ShipVia]                  VARCHAR (400)   NULL,
    [IsActive]                 BIT             DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [IsDeleted]                BIT             DEFAULT ((0)) NOT NULL,
    [ShippingViaId]            BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderQuoteShipVia] PRIMARY KEY CLUSTERED ([SalesOrderQuoteShipViaId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteShipVia_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId])
);



