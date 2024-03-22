CREATE TYPE [dbo].[IlsRfqQuoteDetailsType] AS TABLE (
    [CustomerRfqQuoteDetailsId] BIGINT          NULL,
    [CustomerRfqQuoteId]        BIGINT          NULL,
    [IlsQty]                    INT             NULL,
    [IlsTraceability]           VARCHAR (50)    NULL,
    [IlsUom]                    VARCHAR (50)    NULL,
    [IlsPrice]                  DECIMAL (10, 2) NULL,
    [IlsPriceType]              VARCHAR (50)    NULL,
    [IlsTagDate]                DATETIME2 (7)   NULL,
    [IlsLeadTime]               VARCHAR (50)    NULL,
    [IlsMinQty]                 INT             NULL,
    [IlsComment]                VARCHAR (MAX)   NULL,
    [IlsCondition]              VARCHAR (50)    NULL);



