CREATE TYPE [dbo].[SuggestedPriceTableType] AS TABLE (
    [PartNumber]           VARCHAR (256) NULL,
    [PNDescription]        VARCHAR (256) NULL,
    [Condition]            VARCHAR (256) NULL,
    [IlsPrice]             DECIMAL (18)  NULL,
    [SOUnitPrice]          DECIMAL (18)  NULL,
    [SOQUnitPrice]         DECIMAL (18)  NULL,
    [PurchaseSalePrice]    DECIMAL (18)  NULL,
    [MarkupPercentId]      BIGINT        NULL,
    [MarkUpPercentValue]   DECIMAL (18)  NULL,
    [CostPlusPrice]        DECIMAL (18)  NULL,
    [RecommendedPrice]     DECIMAL (18)  NULL,
    [POUnitPrice]          DECIMAL (18)  NULL,
    [POMarkUpPercentValue] DECIMAL (18)  NULL,
    [POUnitPriceCostPlus]  DECIMAL (18)  NULL,
    [POPricePercentId]     BIGINT        NULL,
    [POQuotePercentId]     BIGINT        NULL);

