CREATE TABLE [dbo].[CreditMemoPaymentBatchDetails] (
    [CreditMemoPaymentBatchDetilsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]           BIGINT        NOT NULL,
    [JournalBatchDetailId]           BIGINT        NOT NULL,
    [ReferenceId]                    BIGINT        NOT NULL,
    [ModuleId]                       INT           NOT NULL,
    [DocumentNo]                     VARCHAR (100) NULL,
    [CheckDate]                      DATETIME2 (7) NULL,
    [CommonJournalBatchDetailId]     BIGINT        NOT NULL,
    [InvoiceReferenceId]             BIGINT        NULL,
    [ManagementStructureId]          BIGINT        NULL,
    CONSTRAINT [PK_CreditMemoPaymentBatchDetails] PRIMARY KEY CLUSTERED ([CreditMemoPaymentBatchDetilsId] ASC)
);

