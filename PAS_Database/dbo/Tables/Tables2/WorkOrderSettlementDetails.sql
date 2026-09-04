CREATE TABLE [dbo].[WorkOrderSettlementDetails] (
    [WorkOrderSettlementDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                 BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]         BIGINT         NOT NULL,
    [workOrderPartNoId]           BIGINT         NOT NULL,
    [WorkOrderSettlementId]       BIGINT         NOT NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_WorkOrderSettlementDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [WorkOrderSettlementDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [WorkOrderSettlementDetailst_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [WorkOrderSettlementDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsMastervalue]               BIT            NULL,
    [Isvalue_NA]                  BIT            NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [ConditionId]                 BIGINT         NULL,
    [UserId]                      BIGINT         NULL,
    [UserName]                    VARCHAR (500)  NULL,
    [sattlement_DateTime]         DATETIME       NULL,
    [conditionName]               VARCHAR (200)  NULL,
    [RevisedPartId]               BIGINT         NULL,
    CONSTRAINT [PK_WorkOrderSettlementDetails] PRIMARY KEY CLUSTERED ([WorkOrderSettlementDetailId] ASC),
    CONSTRAINT [FK_WorkOrderSettlementDetails_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderSettlementDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderSettlementDetails_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderSettlementDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




----------------------------------------------

Create TRIGGER [dbo].[Trg_WorkOrderSettlementDetailsAudit]

   ON  [dbo].[WorkOrderSettlementDetails]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderSettlementDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO

CREATE TRIGGER [dbo].[trg_History_WorkOrderSettlementDetails]
    ON [dbo].[WorkOrderSettlementDetails]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

    ;WITH
    d AS (SELECT [WorkOrderSettlementDetailId],[workOrderPartNoId],[WorkOrderSettlementId],[IsMastervalue],[Isvalue_NA],[conditionName],[RevisedPartId],[UpdatedBy] FROM deleted),
    i AS (SELECT [WorkOrderSettlementDetailId],[workOrderPartNoId],[WorkOrderSettlementId],[IsMastervalue],[Isvalue_NA],[conditionName],[RevisedPartId],[UpdatedBy] FROM inserted),
    paired AS (
        SELECT
            COALESCE(i.workOrderPartNoId, d.workOrderPartNoId) AS WorkOrderPartNoId,
            COALESCE(i.WorkOrderSettlementId, d.WorkOrderSettlementId) AS WorkOrderSettlementId,
            d.IsMastervalue AS OldIsMastervalue, i.IsMastervalue AS NewIsMastervalue,
            d.Isvalue_NA AS OldIsvalueNA, i.Isvalue_NA AS NewIsvalueNA,
            d.conditionName AS OldConditionName, i.conditionName AS NewConditionName,
            d.RevisedPartId AS OldRevisedPartId, i.RevisedPartId AS NewRevisedPartId,
            COALESCE(i.UpdatedBy, d.UpdatedBy) AS ChangedBy
        FROM d
        FULL OUTER JOIN i ON i.WorkOrderSettlementDetailId = d.WorkOrderSettlementDetailId
    ),
    tri AS (
        SELECT
            p.*,
            CASE WHEN p.OldIsvalueNA = 1 THEN N'NA' WHEN p.OldIsMastervalue = 1 THEN N'Yes' WHEN p.OldIsMastervalue = 0 THEN N'No' ELSE NULL END AS OldTri,
            CASE WHEN p.NewIsvalueNA = 1 THEN N'NA' WHEN p.NewIsMastervalue = 1 THEN N'Yes' WHEN p.NewIsMastervalue = 0 THEN N'No' ELSE NULL END AS NewTri,
            CASE p.WorkOrderSettlementId
                WHEN 6  THEN N'toolsChecked'
                WHEN 7  THEN N'releaseCerts'
                WHEN 8  THEN N'mpnLocation'
                WHEN 10 THEN N'unitShipped'
                WHEN 11 THEN N'woInvoiced'
                ELSE NULL
            END AS TriColumnKey
        FROM paired p
    )
    INSERT INTO dbo.WorkOrderSettlementFieldHistory (WorkOrderPartNoId, ColumnKey, OldValue, NewValue, ChangedBy, ChangedAt)
    SELECT WorkOrderPartNoId, TriColumnKey, OldTri, NewTri, ChangedBy, @Now
    FROM tri
    WHERE TriColumnKey IS NOT NULL
      AND ISNULL(OldTri, N'') <> ISNULL(NewTri, N'')

    UNION ALL

    SELECT t.WorkOrderPartNoId, N'revisedPart', RevOld.PartNumber, RevNew.PartNumber, t.ChangedBy, @Now
    FROM tri t
    LEFT JOIN dbo.ItemMaster RevOld WITH (NOLOCK) ON RevOld.ItemMasterId = t.OldRevisedPartId
    LEFT JOIN dbo.ItemMaster RevNew WITH (NOLOCK) ON RevNew.ItemMasterId = t.NewRevisedPartId
    WHERE t.WorkOrderSettlementId = 9
      AND ISNULL(t.OldRevisedPartId, 0) <> ISNULL(t.NewRevisedPartId, 0);
END
GO