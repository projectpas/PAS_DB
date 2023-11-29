CREATE TABLE [dbo].[CustomerReceiptBatchDetails] (
    [CustomerReceiptBatchDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId]         BIGINT          NULL,
    [JournalBatchHeaderId]         BIGINT          NULL,
    [CustomerTypeId]               INT             NULL,
    [CustomerType]                 VARCHAR (50)    NULL,
    [CustomerId]                   BIGINT          NULL,
    [CustomerName]                 VARCHAR (100)   NULL,
    [ModuleId]                     INT             NULL,
    [ReferenceId]                  BIGINT          NULL,
    [ReferenceNumber]              VARCHAR (50)    NULL,
    [ReferenceInvId]               BIGINT          NULL,
    [ReferenceInvNumber]           VARCHAR (50)    NULL,
    [PaymentId]                    BIGINT          NULL,
    [DocumentId]                   BIGINT          NULL,
    [DocumentNumber]               VARCHAR (2000)  NULL,
    [ARControlNumber]              VARCHAR (50)    NULL,
    [CustomerRef]                  VARCHAR (MAX)   NULL,
    [InvoicePayment]               DECIMAL (18, 2) NULL,
    [CommonJournalBatchDetailId]   BIGINT          NULL,
    CONSTRAINT [PK_CustomerReceiptBatchDetails] PRIMARY KEY CLUSTERED ([CustomerReceiptBatchDetailId] ASC)
);

