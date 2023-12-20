CREATE TABLE [dbo].[SOQPartsMappingAudit] (
    [AuditSOQPartsMappingId] BIGINT IDENTITY (1, 1) NOT NULL,
    [SOQPartsMappingId]      BIGINT NOT NULL,
    [SalesOrderQuoteId]      BIGINT NOT NULL,
    [SalesOrderQuotePartId]  BIGINT NOT NULL,
    [ItemMasterId]           BIGINT NOT NULL,
    [StockLineId]            BIGINT NULL,
    [Quantity]               INT    NOT NULL,
    CONSTRAINT [PK_SOQPartsMappingAudit] PRIMARY KEY CLUSTERED ([AuditSOQPartsMappingId] ASC)
);

