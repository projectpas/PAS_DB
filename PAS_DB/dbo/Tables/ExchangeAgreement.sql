CREATE TABLE [dbo].[ExchangeAgreement] (
    [ExchangeAgreementId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]          BIGINT         NULL,
    [ExchangeQuoteNumber]      VARCHAR (100)  NULL,
    [ExchangeSalesOrderId]     BIGINT         NULL,
    [ExchangeSalesOrderNumber] VARCHAR (100)  NULL,
    [ExchangeListPrice]        NUMERIC (9, 2) NULL,
    [ExchangeOutrightPrice]    NUMERIC (9, 2) NULL,
    [CoreDueDate]              DATETIME       NULL,
    [CustomerReference]        VARCHAR (100)  NULL,
    [SellerName]               VARCHAR (100)  NULL,
    [SalesPersonName]          VARCHAR (100)  NULL,
    [IsExchangeQuote]          BIT            CONSTRAINT [DF_ExchangeAgreement_IsExchangeQuote] DEFAULT ((0)) NULL,
    [IsExchangeSO]             BIT            CONSTRAINT [DF_ExchangeAgreement_IsExchangeSO] DEFAULT ((0)) NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ExchangeAgreement_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ExchangeAgreement_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DF_ExchangeAgreement_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DF_ExchangeAgreement_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_ExchangeAgreement] PRIMARY KEY CLUSTERED ([ExchangeAgreementId] ASC)
);

