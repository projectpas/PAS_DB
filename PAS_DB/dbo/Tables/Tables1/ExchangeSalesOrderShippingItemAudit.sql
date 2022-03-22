CREATE TABLE [dbo].[ExchangeSalesOrderShippingItemAudit] (
    [AuditExchangeSalesOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderShippingItemId]      BIGINT         NOT NULL,
    [ExchangeSalesOrderShippingId]          BIGINT         NOT NULL,
    [ExchangeSalesOrderPartId]              BIGINT         NOT NULL,
    [QtyShipped]                            INT            NULL,
    [SOPickTicketId]                        BIGINT         NOT NULL,
    [MasterCompanyId]                       INT            NOT NULL,
    [CreatedBy]                             VARCHAR (256)  NOT NULL,
    [UpdatedBy]                             VARCHAR (256)  NOT NULL,
    [CreatedDate]                           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                           DATETIME2 (7)  NOT NULL,
    [IsActive]                              BIT            NOT NULL,
    [IsDeleted]                             BIT            NOT NULL,
    [PDFPath]                               NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderShippingItemAudit] PRIMARY KEY CLUSTERED ([AuditExchangeSalesOrderShippingItemId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderShippingItemAudit_ExchangeSalesOrderShippingItem] FOREIGN KEY ([ExchangeSalesOrderShippingItemId]) REFERENCES [dbo].[ExchangeSalesOrderShippingItem] ([ExchangeSalesOrderShippingItemId])
);

