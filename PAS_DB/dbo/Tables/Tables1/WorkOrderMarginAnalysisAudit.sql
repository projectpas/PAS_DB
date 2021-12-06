CREATE TABLE [dbo].[WorkOrderMarginAnalysisAudit] (
    [WorkOrderMarginAnalysisAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderMarginAnalysisId]      BIGINT        NOT NULL,
    [WorkOrderId]                    BIGINT        NOT NULL,
    [Currency]                       VARCHAR (30)  NOT NULL,
    [PartsCost]                      VARCHAR (20)  NULL,
    [DirectLaborCost]                VARCHAR (20)  NULL,
    [OverheadApplied]                VARCHAR (20)  NULL,
    [RepairCost]                     VARCHAR (20)  NULL,
    [MiscCharges]                    VARCHAR (20)  NULL,
    [TotalCost]                      VARCHAR (20)  NULL,
    [EstimatedMargin]                VARCHAR (20)  NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) NOT NULL,
    [IsActive]                       BIT           NOT NULL
);

