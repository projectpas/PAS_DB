CREATE TYPE [dbo].[PostRRBatchType] AS TABLE (
    [StocklineId]                     BIGINT          NOT NULL,
    [InvoicedQty]                     INT             NOT NULL,
    [InvoicedUnitCost]                DECIMAL (18, 2) NULL,
    [JournalTypeName]                 VARCHAR (256)   NULL,
    [CreatedBy]                       VARCHAR (256)   NULL,
    [Module]                          VARCHAR (256)   NULL,
    [JournalBatchHeaderId]            BIGINT          NULL,
    [StockType]                       VARCHAR (256)   NULL,
    [Packagingid]                     INT             NULL,
    [EmployeeId]                      BIGINT          NOT NULL,
    [id]                              BIGINT          NOT NULL,
    [ReceivingReconciliationDetailId] BIGINT          NOT NULL);

