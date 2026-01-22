CREATE TYPE [dbo].[BatchTriggerWorkOrderType] AS TABLE (
    [DistributionMasterId] BIGINT          NULL,
    [ReferenceId]          BIGINT          NULL,
    [ReferencePartId]      BIGINT          NULL,
    [ReferencePieceId]     BIGINT          NULL,
    [InvoiceId]            BIGINT          NULL,
    [StocklineId]          BIGINT          NULL,
    [Qty]                  INT             NULL,
    [LaborType]            VARCHAR (200)   NULL,
    [Issued]               BIT             NULL,
    [Amount]               DECIMAL (18, 2) NULL,
    [ModuleName]           VARCHAR (200)   NULL,
    [MasterCompanyId]      INT             NULL,
    [UpdateBy]             VARCHAR (200)   NULL);

