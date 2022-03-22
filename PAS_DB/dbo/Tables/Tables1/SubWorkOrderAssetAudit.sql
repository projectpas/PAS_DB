CREATE TABLE [dbo].[SubWorkOrderAssetAudit] (
    [SubWorkOrderAssetAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderAssetId]      BIGINT        NOT NULL,
    [WorkOrderId]              BIGINT        NOT NULL,
    [SubWorkOrderId]           BIGINT        NOT NULL,
    [SubWOPartNoId]            BIGINT        NOT NULL,
    [AssetRecordId]            BIGINT        NOT NULL,
    [Quantity]                 INT           NOT NULL,
    [IsFromWorkFlow]           BIT           NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) NOT NULL,
    [IsActive]                 BIT           NOT NULL,
    [IsDeleted]                BIT           NOT NULL,
    [TaskId]                   BIGINT        NULL,
    CONSTRAINT [PK_SubWorkOrderAssetAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderAssetAuditId] ASC)
);

