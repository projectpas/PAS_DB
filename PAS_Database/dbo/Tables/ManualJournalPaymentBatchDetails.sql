CREATE TABLE [dbo].[ManualJournalPaymentBatchDetails] (
    [ManualJournalPaymentBatchDetilsId] BIGINT IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]              BIGINT NOT NULL,
    [JournalBatchDetailId]              BIGINT NOT NULL,
    [ManagementStructureId]             BIGINT NOT NULL,
    [ReferenceId]                       BIGINT NOT NULL,
    [ReferenceDetailId]                 BIGINT NOT NULL,
    [CommonJournalBatchDetailId]        BIGINT NOT NULL,
    CONSTRAINT [PK_ManualJournalPaymentBatchDetails] PRIMARY KEY CLUSTERED ([ManualJournalPaymentBatchDetilsId] ASC)
);

