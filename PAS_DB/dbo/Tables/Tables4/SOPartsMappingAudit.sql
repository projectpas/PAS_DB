CREATE TABLE [dbo].[SOPartsMappingAudit] (
    [AuditSOPartsMappingId] BIGINT IDENTITY (1, 1) NOT NULL,
    [SOPartsMappingId]      BIGINT NOT NULL,
    [SalesOrderQuoteId]     BIGINT NULL,
    [SalesOrderId]          BIGINT NOT NULL,
    [SalesOrderPartId]      BIGINT NOT NULL,
    [ItemMasterId]          BIGINT NOT NULL,
    [StockLineId]           BIGINT NULL,
    [Quantity]              INT    NOT NULL,
    CONSTRAINT [PK_SOPartsMappingAudit] PRIMARY KEY CLUSTERED ([AuditSOPartsMappingId] ASC)
);

