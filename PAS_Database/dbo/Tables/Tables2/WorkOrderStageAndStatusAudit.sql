CREATE TABLE [dbo].[WorkOrderStageAndStatusAudit] (
    [WOStageStatusAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WOStageStatusId]      BIGINT        NOT NULL,
    [WOStageId]            BIGINT        NOT NULL,
    [WOStatusId]           BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderStageAndStatusAudit] PRIMARY KEY CLUSTERED ([WOStageStatusAuditId] ASC)
);

