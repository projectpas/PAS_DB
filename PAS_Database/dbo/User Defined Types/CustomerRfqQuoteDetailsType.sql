CREATE TYPE [dbo].[CustomerRfqQuoteDetailsType] AS TABLE (
    [ServiceType] INT             NULL,
    [QuotePrice]  DECIMAL (10, 2) NULL,
    [QuoteTat]    DECIMAL (10, 2) NULL,
    [Low]         DECIMAL (10, 2) NULL,
    [Mid]         DECIMAL (10, 2) NULL,
    [High]        DECIMAL (10, 2) NULL,
    [AvgTat]      DECIMAL (10, 2) NULL,
    [QuoteTatQty] INT             NULL,
    [QuoteCond]   VARCHAR (150)   NULL,
    [QuoteTrace]  VARCHAR (150)   NULL);

