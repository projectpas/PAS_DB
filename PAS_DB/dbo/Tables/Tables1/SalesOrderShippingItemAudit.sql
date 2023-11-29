CREATE TABLE [dbo].[SalesOrderShippingItemAudit] (
    [AuditSalesOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderShippingItemId]      BIGINT         NOT NULL,
    [SalesOrderShippingId]          BIGINT         NOT NULL,
    [SalesOrderPartId]              BIGINT         NOT NULL,
    [QtyShipped]                    INT            NULL,
    [SOPickTicketId]                BIGINT         NOT NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  NOT NULL,
    [IsActive]                      BIT            NOT NULL,
    [IsDeleted]                     BIT            NOT NULL,
    [PDFPath]                       NVARCHAR (MAX) NULL,
    [FedexPdfPath]                  VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_SalesOrderShippingItemAudit] PRIMARY KEY CLUSTERED ([AuditSalesOrderShippingItemId] ASC),
    CONSTRAINT [FK_SalesOrderShippingItemAudit_SalesOrderShippingItem] FOREIGN KEY ([SalesOrderShippingItemId]) REFERENCES [dbo].[SalesOrderShippingItem] ([SalesOrderShippingItemId])
);



