CREATE TABLE [dbo].[ExchangeSalesOrderBillingInvoicingItemAudit] (
    [AuditExchangeSOBillingInvoicingItemId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSOBillingInvoicingItemId]      BIGINT          NOT NULL,
    [SOBillingInvoicingId]                  BIGINT          NOT NULL,
    [NoofPieces]                            INT             NOT NULL,
    [ExchangeSalesOrderPartId]              BIGINT          NOT NULL,
    [ItemMasterId]                          BIGINT          NOT NULL,
    [MasterCompanyId]                       INT             NOT NULL,
    [CreatedBy]                             VARCHAR (256)   NOT NULL,
    [UpdatedBy]                             VARCHAR (256)   NOT NULL,
    [CreatedDate]                           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                           DATETIME2 (7)   NOT NULL,
    [IsActive]                              BIT             NOT NULL,
    [IsDeleted]                             BIT             NOT NULL,
    [UnitPrice]                             DECIMAL (20, 2) NULL,
    [ExchangeSalesOrderShippingId]          BIGINT          NULL,
    [ExchangeSalesOrderScheduleBillingId]   BIGINT          NULL,
    [MiscCharges]                           DECIMAL (18, 2) NULL,
    [Freight]                               DECIMAL (18, 2) NULL,
    [SubTotal]                              DECIMAL (18, 2) NULL,
    [OtherTaxPercent]                       BIGINT          NULL,
    [SalesTaxPercent]                       BIGINT          NULL,
    [GrandTotal]                            DECIMAL (18, 2) NULL,
    [OtherTax]                              DECIMAL (18, 2) NULL,
    [SalesTax]                              DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderBillingInvoicingItemAudit] PRIMARY KEY CLUSTERED ([AuditExchangeSOBillingInvoicingItemId] ASC)
);



