CREATE TYPE [dbo].[CheckDuplicateCustomerPaymentInvoiceType] AS TABLE (
    [CustomerId]           BIGINT        NULL,
    [CustomerName]         VARCHAR (100) NULL,
    [SOBillingInvoicingId] BIGINT        NULL,
    [DocNum]               VARCHAR (100) NULL,
    [InvoiceType]          BIGINT        NULL);

