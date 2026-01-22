CREATE TABLE [dbo].[WorkOrderTypeAudit] (
    [WorkOrderTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Id]                   BIGINT        NOT NULL,
    [Description]          VARCHAR (50)  NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderTypeAudit] PRIMARY KEY CLUSTERED ([WorkOrderTypeAuditId] ASC)
);

