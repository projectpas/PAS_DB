CREATE TABLE [dbo].[SubWorkOrderTaskAudit] (
    [SubWorkOrderTaskAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderTaskId]      BIGINT        NOT NULL,
    [WorkOrderId]             BIGINT        NOT NULL,
    [SubWorkOrderId]          BIGINT        NOT NULL,
    [SubWOPartNoId]           BIGINT        NOT NULL,
    [TaskId]                  BIGINT        NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderTaskAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderTaskAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_SubWorkOrderTaskAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_SubWorkOrderTaskAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNumber]          INT           NULL,
    [OpenDate]                DATETIME2 (7) NULL,
    [OpenBy]                  VARCHAR (100) NULL,
    [IsIncludeInPrint]        BIT           NULL,
    [HasInstruction]          BIT           NULL,
    [TaskName]                VARCHAR (200) NULL,
    [IsFromWorkFlow]          BIT           NULL,
    CONSTRAINT [PK_SubWorkOrderTaskAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderTaskAuditId] ASC)
);

