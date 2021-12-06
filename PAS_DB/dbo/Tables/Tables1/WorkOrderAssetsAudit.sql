CREATE TABLE [dbo].[WorkOrderAssetsAudit] (
    [WorkOrderAssetAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderAssetId]      BIGINT        NOT NULL,
    [WorkOrderId]           BIGINT        NOT NULL,
    [WorkFlowWorkOrderId]   BIGINT        NOT NULL,
    [AssetRecordId]         BIGINT        NOT NULL,
    [Quantity]              INT           NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    [IsFromWorkFlow]        BIT           NULL,
    [WOPartNoId]            BIGINT        NOT NULL,
    [TaskId]                BIGINT        CONSTRAINT [DF__WorkOrder__TaskI__147B6C43] DEFAULT ((1)) NOT NULL,
    [ToolName]              VARCHAR (256) NOT NULL,
    [ToolId]                VARCHAR (256) NOT NULL,
    [ToolDescription]       VARCHAR (256) NULL,
    [ToolClass]             VARCHAR (256) NOT NULL,
    CONSTRAINT [PK_WorkOrderAssetsAudit] PRIMARY KEY CLUSTERED ([WorkOrderAssetAuditId] ASC)
);

