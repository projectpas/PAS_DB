﻿CREATE TYPE [dbo].[ReserveWOMaterialsStocklineType] AS TABLE (
    [WorkOrderId]           BIGINT         NULL,
    [WorkFlowWorkOrderId]   BIGINT         NULL,
    [WorkOrderMaterialsId]  BIGINT         NULL,
    [StockLineId]           BIGINT         NULL,
    [ItemMasterId]          BIGINT         NULL,
    [ConditionId]           BIGINT         NULL,
    [ProvisionId]           BIGINT         NULL,
    [TaskId]                BIGINT         NULL,
    [ReservedById]          BIGINT         NULL,
    [Condition]             VARCHAR (500)  NULL,
    [PartNumber]            VARCHAR (500)  NULL,
    [PartDescription]       VARCHAR (MAX)  NULL,
    [Quantity]              INT            NULL,
    [QtyToBeReserved]       INT            NULL,
    [QuantityActReserved]   INT            NULL,
    [QuantityActIssued]     INT            NULL,
    [QuantityActUnReserved] INT            NULL,
    [QuantityActUnIssued]   INT            NULL,
    [ControlNo]             NVARCHAR (500) NULL,
    [ControlId]             NVARCHAR (500) NULL,
    [StockLineNumber]       NVARCHAR (500) NULL,
    [SerialNumber]          NVARCHAR (500) NULL,
    [ReservedBy]            NVARCHAR (500) NULL,
    [IsStocklineAdded]      BIT            NULL);

