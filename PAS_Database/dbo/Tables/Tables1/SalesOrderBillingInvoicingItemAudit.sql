CREATE TABLE [dbo].[SalesOrderBillingInvoicingItemAudit] (
    [AuditSOBillingInvoicingItemId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SOBillingInvoicingItemId]      BIGINT          NOT NULL,
    [SOBillingInvoicingId]          BIGINT          NOT NULL,
    [NoofPieces]                    INT             NOT NULL,
    [SalesOrderPartId]              BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [UnitPrice]                     DECIMAL (20, 2) NULL,
    [SalesOrderShippingId]          BIGINT          NULL,
    [PDFPath]                       NVARCHAR (MAX)  NULL,
    [StockLineId]                   BIGINT          NULL,
    [VersionNo]                     VARCHAR (100)   NULL,
    [IsVersionIncrease]             BIT             NULL,
    [IsProforma]                    BIT             NULL,
    [IsBilling]                     BIT             NULL,
    CONSTRAINT [PK_SalesOrderBillingInvoicingItemAudit] PRIMARY KEY CLUSTERED ([AuditSOBillingInvoicingItemId] ASC),
    CONSTRAINT [FK_SalesOrderBillingInvoicingItemAudit_SalesOrderBillingInvoicingItem] FOREIGN KEY ([SOBillingInvoicingItemId]) REFERENCES [dbo].[SalesOrderBillingInvoicingItem] ([SOBillingInvoicingItemId])
);





