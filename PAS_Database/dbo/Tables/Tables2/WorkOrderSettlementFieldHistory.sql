-- PN-14788: purpose-built settlement-grid history. Grid-mirroring design per explicit request - one row
-- per grid column key (materialIssued/laborConfirmed/toolsChecked/releaseCerts/mpnLocation/movedToFG/
-- unitShipped/woInvoiced/closeWO/disposition/revisedPart), OldValue/NewValue already display-ready text
-- (Yes/No/NA for tri-state checkboxes, resolved PartNumber for revisedPart), grouped/read by
-- usp_Get_WorkOrderSettlementGridHistory into one "diff row" per save event so the Angular grid can render
-- it directly under the matching PN row with the same column layout as the live Settlement tab. Populated
-- by trg_History_WorkOrderSettlementDetails (on WorkOrderSettlementDetails.sql) and
-- trg_History_WorkOrderPartNumber (on WorkOrderPartNumber.sql).
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
