﻿CREATE TYPE [dbo].[BulkStockLineAdjustmentDetailsType] AS TABLE (
    [BulkStockLineAdjustmentDetailsId] BIGINT          NULL,
    [BulkStkLineAdjId]                 BIGINT          NOT NULL,
    [StockLineId]                      BIGINT          NULL,
    [Qty]                              INT             NOT NULL,
    [NewQty]                           INT             NULL,
    [QtyAdjustment]                    INT             NULL,
    [UnitCost]                         DECIMAL (18, 2) NULL,
    [NewUnitCost]                      DECIMAL (18, 2) NULL,
    [UnitCostAdjustment]               DECIMAL (18, 2) NULL,
    [AdjustmentAmount]                 DECIMAL (18, 2) NULL,
    [FreightAdjustment]                DECIMAL (18, 2) NULL,
    [TaxAdjustment]                    DECIMAL (18, 2) NULL,
    [StockLineAdjustmentTypeId]        INT             NOT NULL,
    [ManagementStructureId]            BIGINT          NULL,
    [FromManagementStructureId]        BIGINT          NULL,
    [ToManagementStructureId]          BIGINT          NULL,
    [LastMSLevel]                      VARCHAR (200)   NULL,
    [AllMSlevels]                      VARCHAR (MAX)   NULL,
    [IsDeleted]                        BIT             NOT NULL,
    [NewUnitCostTotransfer]            DECIMAL (18, 2) NULL,
    [QuantityOnHand]                   DECIMAL (18, 2) NULL,
    [UnitOfMeasure]                    VARCHAR (100)   NULL);



