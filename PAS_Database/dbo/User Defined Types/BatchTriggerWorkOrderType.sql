CREATE TYPE [dbo].[BatchTriggerWorkOrderType] AS TABLE (
    [DistributionMasterId] BIGINT          NULL,
    [ReferenceId]          BIGINT          NULL,
    [ReferencePartId]      BIGINT          NULL,
    [ReferencePieceId]     BIGINT          NULL,
    [InvoiceId]            BIGINT          NULL,
    [StocklineId]          BIGINT          NULL,
    [Qty]                  DECIMAL (18, 6) NULL,
    [LaborType]            VARCHAR (200)   NULL,
    [Issued]               BIT             NULL,
    [Amount]               DECIMAL (18, 6) NULL,
    [ModuleName]           VARCHAR (200)   NULL,
    [MasterCompanyId]      INT             NULL,
    [UpdateBy]             VARCHAR (200)   NULL);

