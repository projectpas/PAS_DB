CREATE TABLE [dbo].[InvoicePaymentMapping] (
    [InvoicePaymentMappingId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]                BIGINT          NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [PaymentId]                BIGINT          NOT NULL,
    [PaymentMethodId]          BIGINT          NULL,
    [PaymentRef]               VARCHAR (200)   NULL,
    [ReferenceId]              BIGINT          NULL,
    [CustomerPaymentDetailsId] BIGINT          NULL,
    [Amount]                   DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_InvoicePaymentMapping] PRIMARY KEY CLUSTERED ([InvoicePaymentMappingId] ASC)
);

