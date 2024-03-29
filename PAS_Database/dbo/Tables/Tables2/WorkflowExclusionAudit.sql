﻿CREATE TABLE [dbo].[WorkflowExclusionAudit] (
    [WorkflowExclusionAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowExclusionId]      BIGINT          NOT NULL,
    [WorkflowId]               BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [UnitCost]                 DECIMAL (18, 2) NULL,
    [Quantity]                 INT             NULL,
    [ExtendedCost]             DECIMAL (18, 2) NULL,
    [EstimtPercentOccurrance]  TINYINT         NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [TaskId]                   BIGINT          NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NULL,
    [UpdatedBy]                VARCHAR (256)   NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NULL,
    [IsActive]                 BIT             NULL,
    [IsDeleted]                BIT             NOT NULL,
    [PartNumber]               VARCHAR (256)   NULL,
    [PartDescription]          VARCHAR (256)   NULL,
    [Order]                    INT             NULL,
    [ConditionId]              BIGINT          NOT NULL,
    [ItemClassificationId]     BIGINT          NULL,
    [WFParentId]               BIGINT          NULL,
    [IsVersionIncrease]        BIT             NULL,
    CONSTRAINT [PK_WorkflowExclusionAudit] PRIMARY KEY CLUSTERED ([WorkflowExclusionAuditId] ASC)
);

