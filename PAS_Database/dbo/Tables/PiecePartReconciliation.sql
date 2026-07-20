CREATE TABLE [dbo].[PiecePartReconciliation] (
    [PiecePartReconciliationId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [RepairOrderPartRecordId]   BIGINT          NOT NULL,
    [SourceRepairOrderId]       BIGINT          NOT NULL,
    [ConsumedRepairOrderId]     BIGINT          NULL,
    [StockLineId]               BIGINT          NOT NULL,
    [QtyShipped]                DECIMAL (18, 6) CONSTRAINT [DF__PiecePart__QtySh__6B70C78E] DEFAULT ((0)) NOT NULL,
    [QtyConsumed]               DECIMAL (18, 6) CONSTRAINT [DF__PiecePart__QtyCo__6C64EBC7] DEFAULT ((0)) NOT NULL,
    [QtyReturned]               DECIMAL (18, 6) CONSTRAINT [DF__PiecePart__QtyRe__6D591000] DEFAULT ((0)) NOT NULL,
    [QtyRemaining]              DECIMAL (18, 6) CONSTRAINT [DF__PiecePart__QtyRe__6E4D3439] DEFAULT ((0)) NOT NULL,
    [ReconciliationStatus]      VARCHAR (50)    CONSTRAINT [DF__PiecePart__Recon__6F415872] DEFAULT ('Pending') NOT NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_PPR_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_PPR_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_PPR_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_PPR_IsDeleted] DEFAULT ((0)) NOT NULL,
    [QtyDamagedLost]            DECIMAL (18, 6) CONSTRAINT [DF__PiecePart__QtyDa__74060D8F] DEFAULT ((0)) NOT NULL,
    [ParentRepairOrderPartId]   BIGINT          NULL,
    CONSTRAINT [PK_PiecePartReconciliation] PRIMARY KEY CLUSTERED ([PiecePartReconciliationId] ASC),
    CONSTRAINT [FK_PPR_RepairOrderPart] FOREIGN KEY ([RepairOrderPartRecordId]) REFERENCES [dbo].[RepairOrderPart] ([RepairOrderPartRecordId]),
    CONSTRAINT [FK_PPR_SourceRO] FOREIGN KEY ([SourceRepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_PPR_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);



GO
CREATE NONCLUSTERED INDEX [IX_PPR_ConsumedRepairOrderId]
    ON [dbo].[PiecePartReconciliation]([ConsumedRepairOrderId] ASC) WHERE ([ConsumedRepairOrderId] IS NOT NULL);

GO
CREATE NONCLUSTERED INDEX [IX_PPR_SourceRepairOrderId]
    ON [dbo].[PiecePartReconciliation]([SourceRepairOrderId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_PPR_RepairOrderPartRecordId]
    ON [dbo].[PiecePartReconciliation]([RepairOrderPartRecordId] ASC);
