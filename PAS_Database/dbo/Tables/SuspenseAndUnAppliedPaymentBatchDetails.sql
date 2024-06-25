CREATE TABLE [dbo].[SuspenseAndUnAppliedPaymentBatchDetails] (
    [SuspenseAndUnAppliedPaymentBatchDetailsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]                      BIGINT        NULL,
    [JournalBatchDetailId]                      BIGINT        NULL,
    [CommonJournalBatchDetailId]                BIGINT        NULL,
    [VendorId]                                  BIGINT        NULL,
    [VendorName]                                VARCHAR (150) NULL,
    [ReferenceId]                               BIGINT        NULL,
    [ReferenceNumber]                           VARCHAR (150) NULL,
    [Memo]                                      VARCHAR (500) NULL,
    [CustomerId]                                BIGINT        NULL,
    [CustomerName]                              VARCHAR (100) NULL,
    CONSTRAINT [PK_SuspenseAndUnAppliedPaymentBatchDetails] PRIMARY KEY CLUSTERED ([SuspenseAndUnAppliedPaymentBatchDetailsId] ASC)
);



