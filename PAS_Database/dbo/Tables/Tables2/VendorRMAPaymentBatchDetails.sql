CREATE TABLE [dbo].[VendorRMAPaymentBatchDetails] (
    [VendorRMAPaymentBatchDetilsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]          BIGINT        NOT NULL,
    [JournalBatchDetailId]          BIGINT        NOT NULL,
    [ReferenceId]                   BIGINT        NOT NULL,
    [VendorId]                      BIGINT        NOT NULL,
    [DocumentNo]                    VARCHAR (100) NULL,
    [CheckDate]                     DATETIME2 (7) NULL,
    [CommonJournalBatchDetailId]    BIGINT        NOT NULL,
    [StockLineId]                   BIGINT        NULL,
    CONSTRAINT [PK_VendorRMAPaymentBatchDetails] PRIMARY KEY CLUSTERED ([VendorRMAPaymentBatchDetilsId] ASC)
);

