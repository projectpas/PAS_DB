CREATE TABLE [dbo].[BillingInvoicingDetails] (
    [BillingInvoicingDetailsId]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [BillingInvoicingId]                 BIGINT        NOT NULL,
    [SoldToCustomerId]                   BIGINT        NOT NULL,
    [SoldToSiteId]                       BIGINT        NOT NULL,
    [SoldToAttention]                    VARCHAR (256) NULL,
    [ShipToCustomerId]                   BIGINT        NOT NULL,
    [ShipToSiteId]                       BIGINT        NOT NULL,
    [ShipToAttention]                    VARCHAR (256) NULL,
    [CustomerDomensticShippingShipViaId] BIGINT        NULL,
    [WayBillRef]                         VARCHAR (100) NULL,
    [ShipAccountInfo]                    VARCHAR (200) NULL,
    CONSTRAINT [PK_BillingInvoicingDetails] PRIMARY KEY CLUSTERED ([BillingInvoicingDetailsId] ASC),
    CONSTRAINT [FK_BillingInvoicingDetails_BillingInvoicing] FOREIGN KEY ([BillingInvoicingId]) REFERENCES [dbo].[BillingInvoicing] ([BillingInvoicingId])
);

