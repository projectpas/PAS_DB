CREATE TABLE [dbo].[WorkOrderBillOfMaterialsAudit] (
    [WorkOrderBillOfMaterialsAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderBillOfMaterialsId]      BIGINT        NOT NULL,
    [WorkOrderId]                     INT           NOT NULL,
    [PartNumber]                      INT           NOT NULL,
    [Quantity]                        SMALLINT      NOT NULL,
    [Condition]                       VARCHAR (20)  NULL,
    [ProvisionId]                     TINYINT       NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) NOT NULL,
    [IsActive]                        BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderBillOfMaterialsAudit] PRIMARY KEY CLUSTERED ([WorkOrderBillOfMaterialsAuditId] ASC)
);

