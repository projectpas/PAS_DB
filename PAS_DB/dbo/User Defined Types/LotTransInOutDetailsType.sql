CREATE TYPE [dbo].[LotTransInOutDetailsType] AS TABLE (
    [LotTransInOutId]      BIGINT          NULL,
    [StockLineId]          BIGINT          NULL,
    [LotId]                BIGINT          NULL,
    [QtyToTransIn]         INT             NULL,
    [QtyToTransOut]        INT             NULL,
    [LotTransInOutDetails] INT             NULL,
    [UnitCost]             DECIMAL (18, 2) NULL,
    [ExtCost]              DECIMAL (18, 2) NULL,
    [IsTransOut]           BIT             NULL,
    [TransInMemo]          VARCHAR (256)   NULL,
    [TransOutMemo]         VARCHAR (256)   NULL);

