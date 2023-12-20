CREATE TABLE [dbo].[BulkStocklineAdjPaymentBatchDetails] (
    [BulkStocklineAdjPaymentBatchDetailsId] BIGINT IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]                  BIGINT NOT NULL,
    [JournalBatchDetailId]                  BIGINT NOT NULL,
    [ReferenceId]                           BIGINT NOT NULL,
    [ModuleId]                              INT    NOT NULL,
    [StockLineId]                           BIGINT NOT NULL,
    [CommonJournalBatchDetailId]            BIGINT NOT NULL,
    [ManagementStructureId]                 BIGINT NULL,
    [EmployeeId]                            BIGINT NULL,
    CONSTRAINT [PK_BulkStocklineAdjPaymentBatchDetails] PRIMARY KEY CLUSTERED ([BulkStocklineAdjPaymentBatchDetailsId] ASC)
);

