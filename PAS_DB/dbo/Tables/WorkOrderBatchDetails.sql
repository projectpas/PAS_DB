﻿CREATE TABLE [dbo].[WorkOrderBatchDetails] (
    [WorkOrderBatchId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId] BIGINT          NOT NULL,
    [JournalBatchHeaderId] BIGINT          NOT NULL,
    [ReferenceId]          BIGINT          NULL,
    [ReferenceName]        VARCHAR (200)   NULL,
    [MPNPartId]            BIGINT          NULL,
    [MPNName]              VARCHAR (200)   NULL,
    [PiecePNId]            BIGINT          NULL,
    [PiecePN]              VARCHAR (200)   NULL,
    [CustomerId]           BIGINT          NULL,
    [CustomerName]         VARCHAR (200)   NULL,
    [InvoiceId]            BIGINT          NULL,
    [InvoiceName]          VARCHAR (200)   NULL,
    [ARControlNum]         VARCHAR (200)   NULL,
    [CustRefNumber]        VARCHAR (200)   NULL,
    [Qty]                  INT             NULL,
    [UnitPrice]            DECIMAL (18, 2) NULL,
    [LaborHrs]             DECIMAL (18, 2) NULL,
    [DirectLaborCost]      DECIMAL (18, 2) NULL,
    [OverheadCost]         DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_WorkOrderBatchDetails] PRIMARY KEY CLUSTERED ([WorkOrderBatchId] ASC)
);

