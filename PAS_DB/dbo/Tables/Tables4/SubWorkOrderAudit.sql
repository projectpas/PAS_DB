CREATE TABLE [dbo].[SubWorkOrderAudit] (
    [SubWorkOrderAuditId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderId]        BIGINT        NOT NULL,
    [WorkOrderId]           BIGINT        NOT NULL,
    [SubWorkOrderNo]        VARCHAR (100) NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    [WorkOrderPartNumberId] BIGINT        NULL,
    [OpenDate]              DATETIME2 (7) NOT NULL,
    [WorkOrderMaterialsId]  BIGINT        NOT NULL,
    [StockLineId]           BIGINT        NOT NULL,
    [SubWorkOrderStatusId]  BIGINT        NULL,
    CONSTRAINT [PK_SubWorkOrderAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderAuditId] ASC)
);

