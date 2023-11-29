﻿CREATE TABLE [dbo].[CustomerRfqQuoteDetails] (
    [CustomerRfqQuoteDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerRfqQuoteId]        BIGINT          NULL,
    [ServiceType]               INT             NULL,
    [QuotePrice]                DECIMAL (10, 2) NULL,
    [QuoteTat]                  DECIMAL (10, 2) NULL,
    [Low]                       DECIMAL (10, 2) NULL,
    [Mid]                       DECIMAL (10, 2) NULL,
    [High]                      DECIMAL (10, 2) NULL,
    [AvgTat]                    DECIMAL (10, 2) NULL,
    [QuoteTatQty]               INT             NULL,
    [QuoteCond]                 VARCHAR (150)   NULL,
    [QuoteTrace]                VARCHAR (150)   NULL,
    [CreatedBy]                 VARCHAR (50)    NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_CustomerRfqQuoteDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)    NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_CustomerRfqQuoteDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_CustomerRfqQuoteDetailsIsActi_59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_CustomerRfqQuoteDetailsIsDele_5AEE82B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerRfqQuoteDetails] PRIMARY KEY CLUSTERED ([CustomerRfqQuoteDetailsId] ASC),
    CONSTRAINT [FK_CustomerRfqQuoteDetails_CustomerRfqQuote] FOREIGN KEY ([CustomerRfqQuoteId]) REFERENCES [dbo].[CustomerRfqQuote] ([CustomerRfqQuoteId])
);

