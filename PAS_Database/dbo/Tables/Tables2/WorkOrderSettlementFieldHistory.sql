
CREATE TABLE [dbo].[WorkOrderSettlementFieldHistory] (
    [WorkOrderSettlementFieldHistoryId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderPartNoId]                 BIGINT        NOT NULL,
    [ColumnKey]                         VARCHAR (30)  NOT NULL,
    [OldValue]                          NVARCHAR (200) NULL,
    [NewValue]                          NVARCHAR (200) NULL,
    [ChangedBy]                         VARCHAR (256) NULL,
    [ChangedAt]                         DATETIME2 (3) CONSTRAINT [DF_WorkOrderSettlementFieldHistory_ChangedAt] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    CONSTRAINT [PK_WorkOrderSettlementFieldHistory] PRIMARY KEY CLUSTERED ([WorkOrderSettlementFieldHistoryId] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_WorkOrderSettlementFieldHistory_PartNoId_ChangedAt]
    ON [dbo].[WorkOrderSettlementFieldHistory] ([WorkOrderPartNoId], [ChangedAt]);
GO
