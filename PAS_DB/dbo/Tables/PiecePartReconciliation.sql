CREATE TABLE [dbo].[PiecePartReconciliation] (
    [PiecePartReconciliationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RepairOrderPartRecordId]   BIGINT         NOT NULL,
    [SourceRepairOrderId]       BIGINT         NOT NULL,
    [ConsumedRepairOrderId]     BIGINT         NULL,
    [StockLineId]               BIGINT         NOT NULL,
    [QtyShipped]                INT            DEFAULT ((0)) NOT NULL,
    [QtyConsumed]               INT            DEFAULT ((0)) NOT NULL,
    [QtyReturned]               INT            DEFAULT ((0)) NOT NULL,
    [QtyRemaining]              INT            DEFAULT ((0)) NOT NULL,
    [ReconciliationStatus]      NVARCHAR (50)  DEFAULT ('Pending') NOT NULL,
    [Memo]                      NVARCHAR (500) NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 NVARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME       CONSTRAINT [DF_PPR_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 NVARCHAR (256) NOT NULL,
    [UpdatedDate]               DATETIME       CONSTRAINT [DF_PPR_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [DF_PPR_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            CONSTRAINT [DF_PPR_IsDeleted] DEFAULT ((0)) NOT NULL,
    [QtyDamagedLost]            INT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PiecePartReconciliation] PRIMARY KEY CLUSTERED ([PiecePartReconciliationId] ASC),
    CONSTRAINT [FK_PPR_RepairOrderPart] FOREIGN KEY ([RepairOrderPartRecordId]) REFERENCES [dbo].[RepairOrderPart] ([RepairOrderPartRecordId]),
    CONSTRAINT [FK_PPR_SourceRO] FOREIGN KEY ([SourceRepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_PPR_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);




GO
CREATE NONCLUSTERED INDEX [IX_PPRA_ConsumedRepairOrderId]
    ON [dbo].[PiecePartReconciliation]([ConsumedRepairOrderId] ASC) WHERE ([ConsumedRepairOrderId] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IX_PPRA_SourceRepairOrderId]
    ON [dbo].[PiecePartReconciliation]([SourceRepairOrderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PPRA_RepairOrderPartRecordId]
    ON [dbo].[PiecePartReconciliation]([RepairOrderPartRecordId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PPR_ConsumedRepairOrderId]
    ON [dbo].[PiecePartReconciliation]([ConsumedRepairOrderId] ASC) WHERE ([ConsumedRepairOrderId] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IX_PPR_SourceRepairOrderId]
    ON [dbo].[PiecePartReconciliation]([SourceRepairOrderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PPR_RepairOrderPartRecordId]
    ON [dbo].[PiecePartReconciliation]([RepairOrderPartRecordId] ASC);

