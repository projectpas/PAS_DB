CREATE TYPE [dbo].[LotTransInOutDetailsType] AS TABLE (
    [LotTransInOutId]      BIGINT          NULL,
    [StockLineId]          BIGINT          NULL,
    [LotId]                BIGINT          NULL,
    [QtyToTransIn]         DECIMAL (18, 6) NULL,
    [QtyToTransOut]        DECIMAL (18, 6) NULL,
    [LotTransInOutDetails] DECIMAL (18, 6) NULL,
    [UnitCost]             DECIMAL (18, 6) NULL,
    [ExtCost]              DECIMAL (18, 6) NULL,
    [IsTransOut]           BIT             NULL,
    [TransInMemo]          VARCHAR (256)   NULL,
    [TransOutMemo]         VARCHAR (256)   NULL);

