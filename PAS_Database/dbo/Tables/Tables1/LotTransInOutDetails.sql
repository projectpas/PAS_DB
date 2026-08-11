CREATE TABLE [dbo].[LotTransInOutDetails] (
    [LotTransInOutId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [StockLineId]          BIGINT          NULL,
    [LotId]                BIGINT          NULL,
    [QtyToTransIn]         DECIMAL (18, 6) NULL,
    [QtyToTransOut]        DECIMAL (18, 6) NULL,
    [IsTransOut]           BIT             NULL,
    [TransInMemo]          VARCHAR (MAX)   NULL,
    [TransOutMemo]         VARCHAR (MAX)   NULL,
    [MasterCompanyId]      INT             CONSTRAINT [DF_LotTransInOutDetails_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NULL,
    [CreatedDate]          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   NULL,
    [IsActive]             BIT             CONSTRAINT [DF_LotTransInOutDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF_LotTransInOutDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LotTransInOutDetails] INT             NULL,
    [UnitCost]             DECIMAL (18, 6) NULL,
    [ExtCost]              DECIMAL (18, 6) NULL,
    [IsStockLineUnitCost]  BIT             NULL,
    [RemainingQty]         DECIMAL (18, 6) NULL,
    [QtyOnHand]            DECIMAL (18, 6) NULL,
    [QtyReserved]          DECIMAL (18, 6) NULL,
    [QtyIssued]            DECIMAL (18, 6) NULL,
    [QtyAvailable]         DECIMAL (18, 6) NULL,
    [ReferenceNumber]      VARCHAR (100)   NULL,
    [IsShipped]            BIT             DEFAULT ((0)) NULL,
    [ShippedQty]           DECIMAL (18, 6) CONSTRAINT [DF__LotTransI__Shipp__2E574124] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_LotTransInOutDetails] PRIMARY KEY CLUSTERED ([LotTransInOutId] ASC),
    CONSTRAINT [FK_LotTransInOutDetails_Lot] FOREIGN KEY ([LotId]) REFERENCES [dbo].[Lot] ([LotId]),
    CONSTRAINT [FK_LotTransInOutDetails_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO
-- Added to fix USP_Lot_GetAllLotViewsByLotId_Filter timeouts on high-volume lots: this table is filtered
-- by LotId (both to build #commonTemp and again per-branch) with no supporting index, forcing a full
-- clustered-index scan of the whole table on every call. This makes that filter a seek and covers the
-- StockLineId join plus the few other columns the SP selects directly from this table.
CREATE NONCLUSTERED INDEX [IX_LotTransInOutDetails_LotId]
    ON [dbo].[LotTransInOutDetails]([LotId] ASC)
    INCLUDE([StockLineId], [QtyToTransIn], [QtyToTransOut], [ReferenceNumber]);

