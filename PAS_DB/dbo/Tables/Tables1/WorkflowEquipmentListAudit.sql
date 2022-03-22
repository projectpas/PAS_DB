CREATE TABLE [dbo].[WorkflowEquipmentListAudit] (
    [WorkflowEquipmentListAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkflowEquipmentListId]      BIGINT         NOT NULL,
    [WorkflowId]                   BIGINT         NOT NULL,
    [AssetId]                      BIGINT         NULL,
    [AssetTypeId]                  BIGINT         NULL,
    [AssetDescription]             VARCHAR (500)  NULL,
    [Quantity]                     SMALLINT       NOT NULL,
    [TaskId]                       BIGINT         NOT NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NULL,
    [UpdatedBy]                    VARCHAR (256)  NULL,
    [CreatedDate]                  DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  NOT NULL,
    [IsActive]                     BIT            NULL,
    [IsDeleted]                    BIT            NOT NULL,
    [PartNumber]                   VARCHAR (256)  NULL,
    [Order]                        INT            NULL,
    [Memo]                         VARCHAR (1000) NULL,
    [WFParentId]                   BIGINT         NULL,
    [IsVersionIncrease]            BIT            NULL,
    CONSTRAINT [PK_WorkflowEquipmentListAudit] PRIMARY KEY CLUSTERED ([WorkflowEquipmentListAuditId] ASC)
);

